namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestFolderWatcher

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestFolderWatcher : GLib.Object {

    GLib.TemporaryDir root;
    string root_path;
    FolderWatcher watcher;
    GLib.SignalSpy path_changed_spy;


    /***********************************************************
    ***********************************************************/
    public AbstractTestFolderWatcher () {
        GLib.Dir root_directory = new GLib.Dir (this.root.path);
        this.root_path = root_directory.canonical_path;
        GLib.debug ("creating test directory tree in " + this.root_path);

        root_directory.mkpath ("a1/b1/c1");
        root_directory.mkpath ("a1/b1/c2");
        root_directory.mkpath ("a1/b2/c1");
        root_directory.mkpath ("a1/b3/c3");
        root_directory.mkpath ("a2/b3/c3");
        Utility.write_random_file (this.root_path + "/a1/random.bin");
        Utility.write_random_file (this.root_path + "/a1/b2/todelete.bin");
        Utility.write_random_file (this.root_path + "/a2/renamefile");
        Utility.write_random_file (this.root_path + "/a1/movefile");

        this.watcher.on_signal_reset (new FolderWatcher ());
        this.watcher.init (this.root_path);
        this.path_changed_spy.on_signal_reset (new GLib.SignalSpy (this.watcher, SIGNAL (path_changed (string))));
    }


    /***********************************************************
    ***********************************************************/
    ~AbstractTestFolderWatcher () {
        check_watch_count (count_folders (this.root_path) + 1);
    }


    protected bool wait_for_path_changed (string path) {
        GLib.Timer timer;
        timer.start ();
        while (timer.elapsed () < 5000) {
            // Check if it was already reported as changed by the watcher
            for (int i = 0; i < this.path_changed_spy.size (); ++i) {
                var args = this.path_changed_spy.at (i);
                if (args.first ().to_string () == path) {
                    return true;
                }
            }
            // Wait a bit and test again (don't bother checking if we timed out or not)
            this.path_changed_spy.wait (200);
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private static int count_folders (string path) {
        int n = 0;
        foreach (var sub in new GLib.Dir (path).entry_list (GLib.Dir.Dirs | GLib.Dir.NoDotAndDotDot)) {
            n += 1 + count_folders (path + "/" + sub);
        }
        return n;
    }


    /***********************************************************
    ***********************************************************/
    private void init () {
        this.path_changed_spy == "";
        check_watch_count (count_folders (this.root_path) + 1);
    }


    private int check_watch_count (int n) {
        GLib.assert_true (this.watcher.test_linux_watch_count () == (n));
    }


    protected static void touch (string file) {
        string command;
        command = "touch %1".printf (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    protected static void mkdir (string file) {
        string command = "mkdir %1".printf (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    protected static void rmdir (string file) {
        string command = "rmdir %1".printf (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    protected static void rm (string file) {
        string command = "rm %1".printf (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    protected static void mv (string file1, string file2) {
        string command = "mv %1 %2".printf (file1, file2);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }

} // class AbstractTestFolderWatcher

} // namespace Testing
} // namespace Occ
