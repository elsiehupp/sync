/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRecursiveDelete : AbstractTestSyncJournalDB {

    /***********************************************************
    ***********************************************************/
    private TestRecursiveDelete () {

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

} // class TestRecursiveDelete

} // namespace Testing
} // namespace Occ
