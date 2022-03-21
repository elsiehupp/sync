namespace Occ {
namespace Testing {

/***********************************************************
@class TestMoveAFile

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestMoveAFile : AbstractTestFolderWatcher {

    /***********************************************************
    ***********************************************************/
    private TestMoveAFile () {
        base ();

        string old_file = this.root_path + "/a1/movefile";
        string new_file = this.root_path + "/a2/movefile.renamed";
        GLib.assert_true (GLib.File.exists (old_file));
        mv (old_file, new_file);
        GLib.assert_true (GLib.File.exists (new_file));

        GLib.assert_true (wait_for_path_changed (old_file));
        GLib.assert_true (wait_for_path_changed (new_file));

        delete (this);
    }

} // class TestMoveAFile

} // namespace Testing
} // namespace Occ
