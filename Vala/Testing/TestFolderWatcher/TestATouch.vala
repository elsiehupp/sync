namespace Occ {
namespace Testing {

/***********************************************************
@class TestATouch

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestATouch : AbstractTestFolderWatcher {

    /***********************************************************
    Touch an existing file.
    ***********************************************************/
    private TestATouch () {
        base ();

        string file = this.root_path + "/a1/random.bin";
        touch (file);
        GLib.assert_true (wait_for_path_changed (file));

        delete (this);
    }

} // class TestATouch

} // namespace Testing
} // namespace Occ
