/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>
//  #include <sqlite3.h>

using Occ;

namespace Testing {

class TestSyncJournalDB : GLib.Object {

    QTemporaryDir this.temporary_directory;


    /***********************************************************
    ***********************************************************/
    public TestSyncJournalDB ()
        : this.database ( (this.temporary_directory.path () + "/sync.db")) {
        GLib.assert_true (this.temporary_directory.is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    public int64 dropMsecs (GLib.DateTime time) {
        return Utility.date_time_to_time_t (time);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {}


    private
    private void on_signal_cleanup_test_case () {
        const string file = this.database.databaseFilePath ();
        GLib.File.remove (file);
    }


    /***********************************************************
    ***********************************************************/
    private void testFileRecord () {
        SyncJournalFileRecord record;
        GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("nonexistant"), record));
        GLib.assert_true (!record.is_valid ());

        record.path = "foo";
        // Use a value that exceeds uint32 and isn't representable by the
        // signed int being cast to uint64 either (like uint64.max would be)
        record.inode = std.numeric_limits<uint32>.max () + 12ull;
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ());
        record.type = ItemTypeDirectory;
        record.etag = "789789";
        record.file_identifier = "abcd";
        record.remote_perm = RemotePermissions.fromDbValue ("RW");
        record.file_size = 213089055;
        record.checksum_header = "MD5:mychecksum";
        GLib.assert_true (this.database.setFileRecord (record));

        SyncJournalFileRecord storedRecord;
        GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo"), storedRecord));
        GLib.assert_true (storedRecord == record);

        // Update checksum
        record.checksum_header = "Adler32:newchecksum";
        this.database.updateFileRecordChecksum ("foo", "newchecksum", "Adler32");
        GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo"), storedRecord));
        GLib.assert_true (storedRecord == record);

        // Update metadata
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ().add_days (1));
        // try a value that only fits uint64, not int64
        record.inode = std.numeric_limits<uint64>.max () - std.numeric_limits<uint32>.max () - 1;
        record.type = ItemTypeFile;
        record.etag = "789FFF";
        record.file_identifier = "efg";
        record.remote_perm = RemotePermissions.fromDbValue ("NV");
        record.file_size = 289055;
        this.database.setFileRecord (record);
        GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo"), storedRecord));
        GLib.assert_true (storedRecord == record);

        GLib.assert_true (this.database.deleteFileRecord ("foo"));
        GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo"), record));
        GLib.assert_true (!record.is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void testFileRecordChecksum () { {// Try with and without a checksum
        {
            SyncJournalFileRecord record;
            record.path = "foo-checksum";
            record.remote_perm = RemotePermissions.fromDbValue (" ");
            record.checksum_header = "MD5:mychecksum";
            record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
            GLib.assert_true (this.database.setFileRecord (record));

            SyncJournalFileRecord storedRecord;
            GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo-checksum"), storedRecord));
            GLib.assert_true (storedRecord.path == record.path);
            GLib.assert_true (storedRecord.remote_perm == record.remote_perm);
            GLib.assert_true (storedRecord.checksum_header == record.checksum_header);

            // GLib.debug ()<< "OOOOO " + storedRecord.modtime.toTime_t () + record.modtime.toTime_t ();

            // Attention : compare time_t types here, as GLib.DateTime seem to maintain
            // milliseconds internally, which disappear in sqlite. Go for full seconds here.
            GLib.assert_true (storedRecord.modtime == record.modtime);
            GLib.assert_true (storedRecord == record);
        } {
            SyncJournalFileRecord record;
            record.path = "foo-nochecksum";
            record.remote_perm = RemotePermissions.fromDbValue ("RW");
            record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());

            GLib.assert_true (this.database.setFileRecord (record));

            SyncJournalFileRecord storedRecord;
            GLib.assert_true (this.database.get_file_record (QByteArrayLiteral ("foo-nochecksum"), storedRecord));
            GLib.assert_true (storedRecord == record);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testDownloadInfo () {
        using Info = SyncJournalDb.DownloadInfo;
        Info record = this.database.getDownloadInfo ("nonexistant");
        GLib.assert_true (!record.valid);

        record.errorCount = 5;
        record.etag = "ABCDEF";
        record.valid = true;
        record.tmpfile = "/tmp/foo";
        this.database.setDownloadInfo ("foo", record);

        Info storedRecord = this.database.getDownloadInfo ("foo");
        GLib.assert_true (storedRecord == record);

        this.database.setDownloadInfo ("foo", Info ());
        Info wipedRecord = this.database.getDownloadInfo ("foo");
        GLib.assert_true (!wipedRecord.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void testUploadInfo () {
        using Info = SyncJournalDb.UploadInfo;
        Info record = this.database.getUploadInfo ("nonexistant");
        GLib.assert_true (!record.valid);

        record.errorCount = 5;
        record.chunk = 12;
        record.transferid = 812974891;
        record.size = 12894789147;
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ());
        record.valid = true;
        this.database.setUploadInfo ("foo", record);

        Info storedRecord = this.database.getUploadInfo ("foo");
        GLib.assert_true (storedRecord == record);

        this.database.setUploadInfo ("foo", Info ());
        Info wipedRecord = this.database.getUploadInfo ("foo");
        GLib.assert_true (!wipedRecord.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void testNumericId () {
        SyncJournalFileRecord record;

        // Typical 8-digit padded identifier
        record.file_identifier = "00000001abcd";
        GLib.assert_cmp (record.numericFileId (), GLib.ByteArray ("00000001"));

        // When the numeric identifier overflows the 8-digit boundary
        record.file_identifier = "123456789ocidblaabcd";
        GLib.assert_cmp (record.numericFileId (), GLib.ByteArray ("123456789"));
    }


    /***********************************************************
    ***********************************************************/
    private void testConflictRecord () {
        ConflictRecord record;
        record.path = "abc";
        record.baseFileId = "def";
        record.baseModtime = 1234;
        record.baseEtag = "ghi";

        GLib.assert_true (!this.database.conflictRecord (record.path).is_valid ());

        this.database.setConflictRecord (record);
        var newRecord = this.database.conflictRecord (record.path);
        GLib.assert_true (newRecord.is_valid ());
        GLib.assert_cmp (newRecord.path, record.path);
        GLib.assert_cmp (newRecord.baseFileId, record.baseFileId);
        GLib.assert_cmp (newRecord.baseModtime, record.baseModtime);
        GLib.assert_cmp (newRecord.baseEtag, record.baseEtag);

        this.database.deleteConflictRecord (record.path);
        GLib.assert_true (!this.database.conflictRecord (record.path).is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void testAvoidReadFromDbOnNextSync () {
        var invalidEtag = GLib.ByteArray ("this.invalid_");
        var initial_etag = GLib.ByteArray ("etag");
        var makeEntry = [&] (GLib.ByteArray path, ItemType type) {
            SyncJournalFileRecord record;
            record.path = path;
            record.type = type;
            record.etag = initial_etag;
            record.remote_perm = RemotePermissions.fromDbValue ("RW");
            this.database.setFileRecord (record);
        }
        var getEtag = [&] (GLib.ByteArray path) {
            SyncJournalFileRecord record;
            this.database.get_file_record (path, record);
            return record.etag;
        }

        makeEntry ("foodir", ItemTypeDirectory);
        makeEntry ("otherdir", ItemTypeDirectory);
        makeEntry ("foo%", ItemTypeDirectory); // wildcards don't apply
        makeEntry ("foodi_", ItemTypeDirectory); // wildcards don't apply
        makeEntry ("foodir/file", ItemTypeFile);
        makeEntry ("foodir/subdir", ItemTypeDirectory);
        makeEntry ("foodir/subdir/file", ItemTypeFile);
        makeEntry ("foodir/otherdir", ItemTypeDirectory);
        makeEntry ("fo", ItemTypeDirectory); // prefix, but does not match
        makeEntry ("foodir/sub", ItemTypeDirectory); // prefix, but does not match
        makeEntry ("foodir/subdir/subsubdir", ItemTypeDirectory);
        makeEntry ("foodir/subdir/subsubdir/file", ItemTypeFile);
        makeEntry ("foodir/subdir/otherdir", ItemTypeDirectory);

        this.database.schedulePathForRemoteDiscovery (GLib.ByteArray ("foodir/subdir"));

        // Direct effects of parent directories being set to this.invalid_
        GLib.assert_cmp (getEtag ("foodir"), invalidEtag);
        GLib.assert_cmp (getEtag ("foodir/subdir"), invalidEtag);
        GLib.assert_cmp (getEtag ("foodir/subdir/subsubdir"), initial_etag);

        GLib.assert_cmp (getEtag ("foodir/file"), initial_etag);
        GLib.assert_cmp (getEtag ("foodir/subdir/file"), initial_etag);
        GLib.assert_cmp (getEtag ("foodir/subdir/subsubdir/file"), initial_etag);

        GLib.assert_cmp (getEtag ("fo"), initial_etag);
        GLib.assert_cmp (getEtag ("foo%"), initial_etag);
        GLib.assert_cmp (getEtag ("foodi_"), initial_etag);
        GLib.assert_cmp (getEtag ("otherdir"), initial_etag);
        GLib.assert_cmp (getEtag ("foodir/otherdir"), initial_etag);
        GLib.assert_cmp (getEtag ("foodir/sub"), initial_etag);
        GLib.assert_cmp (getEtag ("foodir/subdir/otherdir"), initial_etag);

        // Indirect effects : setFileRecord () calls filter etags
        initial_etag = "etag2";

        makeEntry ("foodir", ItemTypeDirectory);
        GLib.assert_cmp (getEtag ("foodir"), invalidEtag);
        makeEntry ("foodir/subdir", ItemTypeDirectory);
        GLib.assert_cmp (getEtag ("foodir/subdir"), invalidEtag);
        makeEntry ("foodir/subdir/subsubdir", ItemTypeDirectory);
        GLib.assert_cmp (getEtag ("foodir/subdir/subsubdir"), initial_etag);
        makeEntry ("fo", ItemTypeDirectory);
        GLib.assert_cmp (getEtag ("fo"), initial_etag);
        makeEntry ("foodir/sub", ItemTypeDirectory);
        GLib.assert_cmp (getEtag ("foodir/sub"), initial_etag);
    }


    /***********************************************************
    ***********************************************************/
    private void testRecursiveDelete () {
        var makeEntry = [&] (GLib.ByteArray path) {
            SyncJournalFileRecord record;
            record.path = path;
            record.remote_perm = RemotePermissions.fromDbValue ("RW");
            this.database.setFileRecord (record);
        }

        QByteArrayList elements;
        elements
            + "foo"
            + "foo/file"
            + "bar"
            + "moo"
            + "moo/file"
            + "foo%bar"
            + "foo bla bar/file"
            + "fo_"
            + "fo_/file";
        for (var& elem : elements)
            makeEntry (elem);

        var checkElements = [&] () {
            bool ok = true;
            for (var& elem : elements) {
                SyncJournalFileRecord record;
                this.database.get_file_record (elem, record);
                if (!record.is_valid ()) {
                    GLib.warn ("Missing record: " + elem;
                    ok = false;
                }
            }
            return ok;
        }

        this.database.deleteFileRecord ("moo", true);
        elements.remove_all ("moo");
        elements.remove_all ("moo/file");
        GLib.assert_true (checkElements ());

        this.database.deleteFileRecord ("fo_", true);
        elements.remove_all ("fo_");
        elements.remove_all ("fo_/file");
        GLib.assert_true (checkElements ());

        this.database.deleteFileRecord ("foo%bar", true);
        elements.remove_all ("foo%bar");
        GLib.assert_true (checkElements ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPinState () {
        var make = [&] (GLib.ByteArray path, PinState state) {
            this.database.internalPinStates ().setForPath (path, state);
            var pinState = this.database.internalPinStates ().rawForPath (path);
            GLib.assert_true (pinState);
            GLib.assert_cmp (*pinState, state);
        }
        var get = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().effectiveForPath (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }
        var getRecursive = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().effectiveForPathRecursive (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }
        var getRaw = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().rawForPath (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }

        this.database.internalPinStates ().wipeForPathAndBelow ("");
        var list = this.database.internalPinStates ().rawList ();
        GLib.assert_cmp (list.size (), 0);

        // Make a thrice-nested setup
        make ("", PinState.PinState.ALWAYS_LOCAL);
        make ("local", PinState.PinState.ALWAYS_LOCAL);
        make ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        make ("inherit", PinState.PinState.INHERITED);
        for (var base: {"local/", "online/", "inherit/"}) {
            make (GLib.ByteArray (base) + "inherit", PinState.PinState.INHERITED);
            make (GLib.ByteArray (base) + "local", PinState.PinState.ALWAYS_LOCAL);
            make (GLib.ByteArray (base) + "online", PinState.VfsItemAvailability.ONLINE_ONLY);

            for (var base2: {"local/", "online/", "inherit/"}) {
                make (GLib.ByteArray (base) + base2 + "inherit", PinState.PinState.INHERITED);
                make (GLib.ByteArray (base) + base2 + "local", PinState.PinState.ALWAYS_LOCAL);
                make (GLib.ByteArray (base) + base2 + "online", PinState.VfsItemAvailability.ONLINE_ONLY);
            }
        }

        list = this.database.internalPinStates ().rawList ();
        GLib.assert_cmp (list.size (), 4 + 9 + 27);

        // Baseline direct checks (the fallback for unset root pinstate is PinState.ALWAYS_LOCAL)
        GLib.assert_cmp (get (""), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online/local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local/online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("inherit/local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("inherit/online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("inherit/nonexistant"), PinState.PinState.ALWAYS_LOCAL);

        // Inheriting checks, level 1
        GLib.assert_cmp (get ("local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);

        // Inheriting checks, level 2
        GLib.assert_cmp (get ("local/inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local/local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("local/online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("online/inherit/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("online/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online/local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("online/online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);

        // Spot check the recursive variant
        GLib.assert_cmp (getRecursive (""), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRecursive ("local"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRecursive ("online"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRecursive ("inherit"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRecursive ("online/local"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRecursive ("online/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (getRecursive ("inherit/inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (getRecursive ("inherit/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (getRecursive ("inherit/online/local"), PinState.PinState.ALWAYS_LOCAL);
        make ("local/local/local/local", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (getRecursive ("local/local/local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (getRecursive ("local/local/local/local"), PinState.PinState.ALWAYS_LOCAL);

        // Check changing the root pin state
        make ("", PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);
        make ("", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (get ("inherit"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (get ("nonexistant"), PinState.PinState.ALWAYS_LOCAL);

        // Wiping
        GLib.assert_cmp (getRaw ("local/local"), PinState.PinState.ALWAYS_LOCAL);
        this.database.internalPinStates ().wipeForPathAndBelow ("local/local");
        GLib.assert_cmp (getRaw ("local"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (getRaw ("local/local"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRaw ("local/local/local"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRaw ("local/local/online"), PinState.PinState.INHERITED);
        list = this.database.internalPinStates ().rawList ();
        GLib.assert_cmp (list.size (), 4 + 9 + 27 - 4);

        // Wiping everything
        this.database.internalPinStates ().wipeForPathAndBelow ("");
        GLib.assert_cmp (getRaw (""), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRaw ("local"), PinState.PinState.INHERITED);
        GLib.assert_cmp (getRaw ("online"), PinState.PinState.INHERITED);
        list = this.database.internalPinStates ().rawList ();
        GLib.assert_cmp (list.size (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private SyncJournalDb this.database;
}

QTEST_APPLESS_MAIN (TestSyncJournalDB)
