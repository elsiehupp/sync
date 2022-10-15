/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestAvoidReadFromDatabaseOnNextSync : AbstractTestSyncJournalDB {

    /***********************************************************
    ***********************************************************/
    private TestAvoidReadFromDatabaseOnNextSync () {
        //  var invalid_etag = "this.invalid_";
        //  var initial_etag = "etag";

        //  make_entry ("foodir", ItemType.DIRECTORY);
        //  make_entry ("otherdir", ItemType.DIRECTORY);
        //  make_entry ("foo%", ItemType.DIRECTORY); // wildcards don't apply
        //  make_entry ("foodi_", ItemType.DIRECTORY); // wildcards don't apply
        //  make_entry ("foodir/file", ItemType.FILE);
        //  make_entry ("foodir/subdir", ItemType.DIRECTORY);
        //  make_entry ("foodir/subdir/file", ItemType.FILE);
        //  make_entry ("foodir/otherdir", ItemType.DIRECTORY);
        //  make_entry ("fo", ItemType.DIRECTORY); // prefix, but does not match
        //  make_entry ("foodir/sub", ItemType.DIRECTORY); // prefix, but does not match
        //  make_entry ("foodir/subdir/subsubdir", ItemType.DIRECTORY);
        //  make_entry ("foodir/subdir/subsubdir/file", ItemType.FILE);
        //  make_entry ("foodir/subdir/otherdir", ItemType.DIRECTORY);

        //  this.database.schedule_path_for_remote_discovery ("foodir/subdir");

        //  // Direct effects of parent directories being set to this.invalid_
        //  GLib.assert_true (get_etag ("foodir") == invalid_etag);
        //  GLib.assert_true (get_etag ("foodir/subdir") == invalid_etag);
        //  GLib.assert_true (get_etag ("foodir/subdir/subsubdir") == initial_etag);

        //  GLib.assert_true (get_etag ("foodir/file") == initial_etag);
        //  GLib.assert_true (get_etag ("foodir/subdir/file") == initial_etag);
        //  GLib.assert_true (get_etag ("foodir/subdir/subsubdir/file") == initial_etag);

        //  GLib.assert_true (get_etag ("fo") == initial_etag);
        //  GLib.assert_true (get_etag ("foo%") == initial_etag);
        //  GLib.assert_true (get_etag ("foodi_") == initial_etag);
        //  GLib.assert_true (get_etag ("otherdir") == initial_etag);
        //  GLib.assert_true (get_etag ("foodir/otherdir") == initial_etag);
        //  GLib.assert_true (get_etag ("foodir/sub") == initial_etag);
        //  GLib.assert_true (get_etag ("foodir/subdir/otherdir") == initial_etag);

        //  // Indirect effects : set_file_record () calls filter etags
        //  initial_etag = "etag2";

        //  make_entry ("foodir", ItemType.DIRECTORY);
        //  GLib.assert_true (get_etag ("foodir") == invalid_etag);
        //  make_entry ("foodir/subdir", ItemType.DIRECTORY);
        //  GLib.assert_true (get_etag ("foodir/subdir") == invalid_etag);
        //  make_entry ("foodir/subdir/subsubdir", ItemType.DIRECTORY);
        //  GLib.assert_true (get_etag ("foodir/subdir/subsubdir") == initial_etag);
        //  make_entry ("fo", ItemType.DIRECTORY);
        //  GLib.assert_true (get_etag ("fo") == initial_etag);
        //  make_entry ("foodir/sub", ItemType.DIRECTORY);
        //  GLib.assert_true (get_etag ("foodir/sub") == initial_etag);
    }


    private void make_entry (string path, ItemType type) {
        //  Common.SyncJournalFileRecord record;
        //  record.path = path;
        //  record.type = type;
        //  record.etag = initial_etag;
        //  record.remote_permissions = Common.RemotePermissions.from_database_value ("RW");
        //  this.database.set_file_record (record);
    }


    private void get_etag (string path) {
        //  Common.SyncJournalFileRecord record;
        //  this.database.get_file_record (path, record);
        //  return record.etag;
    }

} // class TestAvoidReadFromDatabaseOnNextSync

} // namespace Testing
} // namespace Occ
