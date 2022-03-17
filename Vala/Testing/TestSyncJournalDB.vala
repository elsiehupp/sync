/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <sqlite3.h>

using Occ;

namespace Testing {

public class TestSyncJournalDB : GLib.Object {

    private SyncJournalDb database;
    private QTemporaryDir temporary_directory;

    /***********************************************************
    ***********************************************************/
    public TestSyncJournalDB () {
        this.database = this.temporary_directory.path () + "/sync.db";
        GLib.assert_true (this.temporary_directory.is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    public int64 drop_msecs (GLib.DateTime time) {
        return Utility.date_time_to_time_t (time);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        return;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        const string file = this.database.database_file_path ();
        GLib.File.remove (file);
    }


    /***********************************************************
    ***********************************************************/
    private void test_file_record () {
        SyncJournalFileRecord record;
        GLib.assert_true (this.database.get_file_record ("nonexistant", record));
        GLib.assert_true (!record.is_valid ());

        record.path = "foo";
        // Use a value that exceeds uint32 and isn't representable by the
        // signed int being cast to uint64 either (like uint64.max would be)
        record.inode = std.numeric_limits<uint32>.max () + 12ull;
        record.modtime = drop_msecs (GLib.DateTime.current_date_time ());
        record.type = ItemType.DIRECTORY;
        record.etag = "789789";
        record.file_identifier = "abcd";
        record.remote_perm = RemotePermissions.from_database_value ("RW");
        record.file_size = 213089055;
        record.checksum_header = "MD5:mychecksum";
        GLib.assert_true (this.database.set_file_record (record));

        SyncJournalFileRecord stored_record;
        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
        GLib.assert_true (stored_record == record);

        // Update checksum
        record.checksum_header = "Adler32:newchecksum";
        this.database.update_file_record_checksum ("foo", "newchecksum", "Adler32");
        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
        GLib.assert_true (stored_record == record);

        // Update metadata
        record.modtime = drop_msecs (GLib.DateTime.current_date_time ().add_days (1));
        // try a value that only fits uint64, not int64
        record.inode = std.numeric_limits<uint64>.max () - std.numeric_limits<uint32>.max () - 1;
        record.type = ItemType.FILE;
        record.etag = "789FFF";
        record.file_identifier = "efg";
        record.remote_perm = RemotePermissions.from_database_value ("NV");
        record.file_size = 289055;
        this.database.set_file_record (record);
        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
        GLib.assert_true (stored_record == record);

        GLib.assert_true (this.database.delete_file_record ("foo"));
        GLib.assert_true (this.database.get_file_record ("foo", record));
        GLib.assert_true (!record.is_valid ());
    }


    /***********************************************************
    Try with and without a checksum
    ***********************************************************/
    private void test_file_record_checksum () {
        SyncJournalFileRecord record;
        record.path = "foo-checksum";
        record.remote_perm = RemotePermissions.from_database_value (" ");
        record.checksum_header = "MD5:mychecksum";
        record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        GLib.assert_true (this.database.set_file_record (record));

        SyncJournalFileRecord stored_record;
        GLib.assert_true (this.database.get_file_record ("foo-checksum", stored_record));
        GLib.assert_true (stored_record.path == record.path);
        GLib.assert_true (stored_record.remote_perm == record.remote_perm);
        GLib.assert_true (stored_record.checksum_header == record.checksum_header);

        // GLib.debug ("OOOOO " + stored_record.modtime.to_time_t () + record.modtime.to_time_t ());

        // Attention: compare time_t types here, as GLib.DateTime seem to maintain
        // milliseconds internally, which disappear in sqlite. Go for full seconds here.
        GLib.assert_true (stored_record.modtime == record.modtime);
        GLib.assert_true (stored_record == record);

        SyncJournalFileRecord record;
        record.path = "foo-nochecksum";
        record.remote_perm = RemotePermissions.from_database_value ("RW");
        record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());

        GLib.assert_true (this.database.set_file_record (record));

        SyncJournalFileRecord stored_record;
        GLib.assert_true (this.database.get_file_record ("foo-nochecksum", stored_record));
        GLib.assert_true (stored_record == record);
    }


    /***********************************************************
    ***********************************************************/
    private void test_download_info () {
        SyncJournalDb.DownloadInfo record = this.database.get_download_info ("nonexistant");
        GLib.assert_true (!record.valid);

        record.error_count = 5;
        record.etag = "ABCDEF";
        record.valid = true;
        record.tmpfile = "/tmp/foo";
        this.database.set_download_info ("foo", record);

        SyncJournalDb.DownloadInfo stored_record = this.database.get_download_info ("foo");
        GLib.assert_true (stored_record == record);

        this.database.set_download_info ("foo", SyncJournalDb.DownloadInfo ());
        SyncJournalDb.DownloadInfo wiped_record = this.database.get_download_info ("foo");
        GLib.assert_true (!wiped_record.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void test_upload_info () {
        SyncJournalDb.UploadInfo record = this.database.get_upload_info ("nonexistant");
        GLib.assert_true (!record.valid);

        record.error_count = 5;
        record.chunk = 12;
        record.transferid = 812974891;
        record.size = 12894789147;
        record.modtime = drop_msecs (GLib.DateTime.current_date_time ());
        record.valid = true;
        this.database.set_upload_info ("foo", record);

        SyncJournalDb.UploadInfo stored_record = this.database.get_upload_info ("foo");
        GLib.assert_true (stored_record == record);

        this.database.set_upload_info ("foo", SyncJournalDb.UploadInfo ());
        SyncJournalDb.UploadInfo wiped_record = this.database.get_upload_info ("foo");
        GLib.assert_true (!wiped_record.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void test_numeric_id () {
        SyncJournalFileRecord record;

        // Typical 8-digit padded identifier
        record.file_identifier = "00000001abcd";
        GLib.assert_true (record.numeric_file_id () == "00000001");

        // When the numeric identifier overflows the 8-digit boundary
        record.file_identifier = "123456789ocidblaabcd";
        GLib.assert_true (record.numeric_file_id () == "123456789");
    }


    /***********************************************************
    ***********************************************************/
    private void test_conflict_record () {
        ConflictRecord record;
        record.path = "abc";
        record.base_file_id = "def";
        record.base_modtime = 1234;
        record.base_etag = "ghi";

        GLib.assert_true (!this.database.conflict_record (record.path).is_valid ());

        this.database.set_conflict_record (record);
        var new_record = this.database.conflict_record (record.path);
        GLib.assert_true (new_record.is_valid ());
        GLib.assert_true (new_record.path == record.path);
        GLib.assert_true (new_record.base_file_id == record.base_file_id);
        GLib.assert_true (new_record.base_modtime == record.base_modtime);
        GLib.assert_true (new_record.base_etag == record.base_etag);

        this.database.delete_conflict_record (record.path);
        GLib.assert_true (!this.database.conflict_record (record.path).is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_avoid_read_from_database_on_next_sync () {
        var invalid_etag = "this.invalid_";
        var initial_etag = "etag";

        make_entry ("foodir", ItemType.DIRECTORY);
        make_entry ("otherdir", ItemType.DIRECTORY);
        make_entry ("foo%", ItemType.DIRECTORY); // wildcards don't apply
        make_entry ("foodi_", ItemType.DIRECTORY); // wildcards don't apply
        make_entry ("foodir/file", ItemType.FILE);
        make_entry ("foodir/subdir", ItemType.DIRECTORY);
        make_entry ("foodir/subdir/file", ItemType.FILE);
        make_entry ("foodir/otherdir", ItemType.DIRECTORY);
        make_entry ("fo", ItemType.DIRECTORY); // prefix, but does not match
        make_entry ("foodir/sub", ItemType.DIRECTORY); // prefix, but does not match
        make_entry ("foodir/subdir/subsubdir", ItemType.DIRECTORY);
        make_entry ("foodir/subdir/subsubdir/file", ItemType.FILE);
        make_entry ("foodir/subdir/otherdir", ItemType.DIRECTORY);

        this.database.schedule_path_for_remote_discovery ("foodir/subdir");

        // Direct effects of parent directories being set to this.invalid_
        GLib.assert_true (get_etag ("foodir") == invalid_etag);
        GLib.assert_true (get_etag ("foodir/subdir") == invalid_etag);
        GLib.assert_true (get_etag ("foodir/subdir/subsubdir") == initial_etag);

        GLib.assert_true (get_etag ("foodir/file") == initial_etag);
        GLib.assert_true (get_etag ("foodir/subdir/file") == initial_etag);
        GLib.assert_true (get_etag ("foodir/subdir/subsubdir/file") == initial_etag);

        GLib.assert_true (get_etag ("fo") == initial_etag);
        GLib.assert_true (get_etag ("foo%") == initial_etag);
        GLib.assert_true (get_etag ("foodi_") == initial_etag);
        GLib.assert_true (get_etag ("otherdir") == initial_etag);
        GLib.assert_true (get_etag ("foodir/otherdir") == initial_etag);
        GLib.assert_true (get_etag ("foodir/sub") == initial_etag);
        GLib.assert_true (get_etag ("foodir/subdir/otherdir") == initial_etag);

        // Indirect effects : set_file_record () calls filter etags
        initial_etag = "etag2";

        make_entry ("foodir", ItemType.DIRECTORY);
        GLib.assert_true (get_etag ("foodir") == invalid_etag);
        make_entry ("foodir/subdir", ItemType.DIRECTORY);
        GLib.assert_true (get_etag ("foodir/subdir") == invalid_etag);
        make_entry ("foodir/subdir/subsubdir", ItemType.DIRECTORY);
        GLib.assert_true (get_etag ("foodir/subdir/subsubdir") == initial_etag);
        make_entry ("fo", ItemType.DIRECTORY);
        GLib.assert_true (get_etag ("fo") == initial_etag);
        make_entry ("foodir/sub", ItemType.DIRECTORY);
        GLib.assert_true (get_etag ("foodir/sub") == initial_etag);
    }


    private void make_entry (string path, ItemType type) {
        SyncJournalFileRecord record;
        record.path = path;
        record.type = type;
        record.etag = initial_etag;
        record.remote_perm = RemotePermissions.from_database_value ("RW");
        this.database.set_file_record (record);
    }


    private void get_etag (string path) {
        SyncJournalFileRecord record;
        this.database.get_file_record (path, record);
        return record.etag;
    }


    /***********************************************************
    ***********************************************************/
    private void test_recursive_delete () {

        string[] elements = {
            "foo",
            "foo/file",
            "bar",
            "moo",
            "moo/file",
            "foo%bar",
            "foo bla bar/file",
            "fo_",
            "fo_/file"
        };
        foreach (var elem in elements) {
            make_entry (elem);
        }

        this.database.delete_file_record ("moo", true);
        elements.remove_all ("moo");
        elements.remove_all ("moo/file");
        GLib.assert_true (check_elements ());

        this.database.delete_file_record ("fo_", true);
        elements.remove_all ("fo_");
        elements.remove_all ("fo_/file");
        GLib.assert_true (check_elements ());

        this.database.delete_file_record ("foo%bar", true);
        elements.remove_all ("foo%bar");
        GLib.assert_true (check_elements ());
    }


    private void make_entry (string path) {
        SyncJournalFileRecord record;
        record.path = path;
        record.remote_perm = RemotePermissions.from_database_value ("RW");
        this.database.set_file_record (record);
    }



    private void check_elements () {
        bool ok = true;
        foreach (var element in elements) {
            SyncJournalFileRecord record;
            this.database.get_file_record (element, record);
            if (!record.is_valid ()) {
                GLib.warning ("Missing record: " + element);
                ok = false;
            }
        }
        return ok;
    }


    /***********************************************************
    ***********************************************************/
    private void test_pin_state () {
        this.database.internal_pin_states ().wipe_for_path_and_below ("");
        var list = this.database.internal_pin_states ().raw_list ();
        GLib.assert_true (list.size () == 0);

        // Make a thrice-nested setup
        make ("", PinState.PinState.ALWAYS_LOCAL);
        make ("local", PinState.PinState.ALWAYS_LOCAL);
        make ("online", Vfs.ItemAvailability.ONLINE_ONLY);
        make ("inherit", PinState.PinState.INHERITED);
        foreach (string base_string_1 in {"local/", "online/", "inherit/"}) {
            make (base_string_1 + "inherit", PinState.PinState.INHERITED);
            make (base_string_1 + "local", PinState.PinState.ALWAYS_LOCAL);
            make (base_string_1 + "online", Vfs.ItemAvailability.ONLINE_ONLY);

            foreach (var base_string_2 in { "local/", "online/", "inherit/" }) {
                make (base_string_1 + base_string_2 + "inherit", PinState.PinState.INHERITED);
                make (base_string_1 + base_string_2 + "local", PinState.PinState.ALWAYS_LOCAL);
                make (base_string_1 + base_string_2 + "online", Vfs.ItemAvailability.ONLINE_ONLY);
            }
        }

        list = this.database.internal_pin_states ().raw_list ();
        GLib.assert_true (list.size () == 4 + 9 + 27);

        // Baseline direct checks (the fallback for unset root pinstate is PinState.ALWAYS_LOCAL)
        GLib.assert_true (get_pin_state ("") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("inherit/online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("inherit/nonexistant") == PinState.PinState.ALWAYS_LOCAL);

        // Inheriting checks, level 1
        GLib.assert_true (get_pin_state ("local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);

        // Inheriting checks, level 2
        GLib.assert_true (get_pin_state ("local/inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("local/online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/inherit/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/local/nonexistant") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("online/online/nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);

        // Spot check the recursive variant
        GLib.assert_true (get_recursive ("") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("inherit") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_recursive ("online/local/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("inherit/inherit/inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("inherit/online/inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_recursive ("inherit/online/local") == PinState.PinState.ALWAYS_LOCAL);
        make ("local/local/local/local", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("local/local/local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_recursive ("local/local/local/local") == PinState.PinState.ALWAYS_LOCAL);

        // Check changing the root pin state
        make ("", Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("nonexistant") == Vfs.ItemAvailability.ONLINE_ONLY);
        make ("", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (get_pin_state ("inherit") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_pin_state ("nonexistant") == PinState.PinState.ALWAYS_LOCAL);

        // Wiping
        GLib.assert_true (get_raw ("local/local") == PinState.PinState.ALWAYS_LOCAL);
        this.database.internal_pin_states ().wipe_for_path_and_below ("local/local");
        GLib.assert_true (get_raw ("local") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (get_raw ("local/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local/local/local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local/local/online") == PinState.PinState.INHERITED);
        list = this.database.internal_pin_states ().raw_list ();
        GLib.assert_true (list.size () == 4 + 9 + 27 - 4);

        // Wiping everything
        this.database.internal_pin_states ().wipe_for_path_and_below ("");
        GLib.assert_true (get_raw ("") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("local") == PinState.PinState.INHERITED);
        GLib.assert_true (get_raw ("online") == PinState.PinState.INHERITED);
        list = this.database.internal_pin_states ().raw_list ();
        GLib.assert_true (list.size () == 0);
    }



    private void make (string path, PinState state) {
        this.database.internal_pin_states ().set_for_path (path, state);
        var pin_state = this.database.internal_pin_states ().raw_for_path (path);
        GLib.assert_true (pin_state);
        GLib.assert_true (pin_state == state);
    }


    private PinState get_pin_state (string path)  {
        var state = this.database.internal_pin_states ().effective_for_path (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }


    private PinState get_recursive (string path) {
        var state = this.database.internal_pin_states ().effective_for_path_recursive (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }


    private PinState get_raw (string path) {
        var state = this.database.internal_pin_states ().raw_for_path (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }

} // public class TestSyncJournalDB
} // namespace Testing
