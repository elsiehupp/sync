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

        GLib.List<string> elements = new GLib.List<string> ();
        elements.append ("foo");
        elements.append ("foo/file");
        elements.append ("bar");
        elements.append ("moo");
        elements.append ("moo/file");
        elements.append ("foo%bar");
        elements.append ("foo bla bar/file");
        elements.append ("fo_");
        elements.append ("fo_/file");
        foreach (var elem in elements) {
            make_entry (elem);
        }

        this.database.delete_file_record ("moo", true);
        elements.remove_all ("moo");
        elements.remove_all ("moo/file");
        GLib.assert_true (check_elements (elements));

        this.database.delete_file_record ("fo_", true);
        elements.remove_all ("fo_");
        elements.remove_all ("fo_/file");
        GLib.assert_true (check_elements (elements));

        this.database.delete_file_record ("foo%bar", true);
        elements.remove_all ("foo%bar");
        GLib.assert_true (check_elements (elements));
    }


    private void make_entry (string path) {
        SyncJournalFileRecord record;
        record.path = path;
        record.remote_permissions = Common.RemotePermissions.from_database_value ("RW");
        this.database.set_file_record (record);
    }



    private bool check_elements (GLib.List<string> elements) {
        bool ok = true;
        foreach (var element in elements) {
            SyncJournalFileRecord record;
            this.database.get_file_record (element, record);
            if (!record.is_valid) {
                GLib.warning ("Missing record: " + element);
                ok = false;
            }
        }
        return ok;
    }

} // class TestRecursiveDelete

} // namespace Testing
} // namespace Occ
