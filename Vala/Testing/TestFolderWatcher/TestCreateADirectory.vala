namespace Occ {
namespace Testing {

/***********************************************************
@class TestCreateADirectory

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCreateADirectory : AbstractTestFolderWatcher {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestCreateADirectory () {
    //      base ();

    //      string file = this.root_path + "/a1/b1/new_dir";
    //      mkdir (file);
    //      GLib.assert_true (wait_for_path_changed (file));

    //      // Notifications from that new folder arrive too
    //      string file2 = this.root_path + "/a1/b1/new_dir/contained";
    //      touch (file2);
    //      GLib.assert_true (wait_for_path_changed (file2));

    //      delete (this);
    //  }

} // class TestCreateADirectory

} // namespace Testing
} // namespace Occ
