namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestInotifyWatcher

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestInotifyWatcher : FolderWatcherPrivate {

//    /***********************************************************
//    ***********************************************************/
//    protected string root;

//    /***********************************************************
//    ***********************************************************/
//    protected AbstractTestInotifyWatcher () {
//        this.root = GLib.Dir.temporary_path + "/" + "test_" + string.number (Utility.rand ());
//        GLib.debug ("creating test directory tree in " + this.root);
//        GLib.Dir root_directory = new GLib.Dir (this.root);

//        root_directory.mkpath (this.root + "/a1/b1/c1");
//        root_directory.mkpath (this.root + "/a1/b1/c2");
//        root_directory.mkpath (this.root + "/a1/b2/c1");
//        root_directory.mkpath (this.root + "/a1/b3/c3");
//        root_directory.mkpath (this.root + "/a2/b3/c3");
//    }


//    /***********************************************************
//    ***********************************************************/
//    ~AbstractTestInotifyWatcher () {
//        if (this.root.has_prefix (GLib.Dir.temporary_path)) {
//           system ("rm -rf %1".printf (this.root).to_local_8_bit ());
//        }
//    }

} // class AbstractTestInotifyWatcher

} // namespace Testing
} // namespace Occ
