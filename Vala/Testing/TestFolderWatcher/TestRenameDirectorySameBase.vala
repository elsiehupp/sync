namespace Occ {
namespace Testing {

/***********************************************************
@class TestRenameDirectorySameBase

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRenameDirectorySameBase : AbstractTestFolderWatcher {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestRenameDirectorySameBase () {
    //      base ();

    //      string old_file = this.root_path + "/a1/b1";
    //      string new_file = this.root_path + "/a1/brename";
    //      GLib.assert_true (GLib.File.exists (old_file));
    //      mv (old_file, new_file);
    //      GLib.assert_true (GLib.File.exists (new_file));

    //      GLib.assert_true (wait_for_path_changed (old_file));
    //      GLib.assert_true (wait_for_path_changed (new_file));

    //      // Verify that further notifications end up with the correct paths

    //      string file = this.root_path + "/a1/brename/c1/random.bin";
    //      touch (file);
    //      GLib.assert_true (wait_for_path_changed (file));

    //      string directory = this.root_path + "/a1/brename/newfolder";
    //      mkdir (directory);
    //      GLib.assert_true (wait_for_path_changed (directory));

    //      delete (this);
    //  }

} // class TestRenameDirectorySameBase

} // namespace Testing
} // namespace Occ
