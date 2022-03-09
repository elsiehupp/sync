/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

namespace Testing {


using Occ;

class TestFolderWatcher : GLib.Object {

    QTemporaryDir root;
    string root_path;
    FolderWatcher watcher;
    QSignalSpy path_changed_spy;

    bool wait_for_path_changed (string path) {
        QElapsedTimer timer;
        timer.on_signal_start ();
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
    public TestFolderWatcher () {
        QDir root_directory = new QDir (this.root.path ());
        this.root_path = root_directory.canonicalPath ();
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
        this.path_changed_spy.on_signal_reset (new QSignalSpy (this.watcher.data (), SIGNAL (pathChanged (string))));
    }


    /***********************************************************
    ***********************************************************/
    public int count_folders (string path) {
        int n = 0;
        foreach (var sub in new QDir (path).entryList (QDir.Dirs | QDir.NoDotAndDotDot))
            n += 1 + count_folders (path + '/' + sub);
        return n;
    }


    /***********************************************************
    ***********************************************************/
    private void init () {
        this.path_changed_spy.clear ();
        check_watch_count (count_folders (this.root_path) + 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup () {
        check_watch_count (count_folders (this.root_path) + 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_a_create () { // create a new file
        string file = this.root_path + "/foo.txt";
        string command = "echo \"xyz\" > %1".arg (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());

        GLib.assert_true (wait_for_path_changed (file));
    }


    /***********************************************************
    ***********************************************************/
    private void testATouch () { // touch an existing file.
        string file = this.root_path + "/a1/random.bin";
        touch (file);
        GLib.assert_true (wait_for_path_changed (file));
    }


    /***********************************************************
    ***********************************************************/
    private void testMove3LevelDirWithFile () {
        string file = this.root_path + "/a0/b/c/empty.txt";
        mkdir (this.root_path + "/a0");
        mkdir (this.root_path + "/a0/b");
        mkdir (this.root_path + "/a0/b/c");
        touch (file);
        mv (this.root_path + "/a0", this.root_path + "/a");
        GLib.assert_true (wait_for_path_changed (this.root_path + "/a/b/c/empty.txt"));
    }


    /***********************************************************
    ***********************************************************/
    private void testCreateADir () {
        string file = this.root_path + "/a1/b1/new_dir";
        mkdir (file);
        GLib.assert_true (wait_for_path_changed (file));

        // Notifications from that new folder arrive too
        string file2 = this.root_path + "/a1/b1/new_dir/contained";
        touch (file2);
        GLib.assert_true (wait_for_path_changed (file2));
    }


    /***********************************************************
    ***********************************************************/
    private void testRemoveADir () {
        string file = this.root_path + "/a1/b3/c3";
        rmdir (file);
        GLib.assert_true (wait_for_path_changed (file));
    }


    /***********************************************************
    ***********************************************************/
    private void testRemoveAFile () {
        string file = this.root_path + "/a1/b2/todelete.bin";
        GLib.assert_true (GLib.File.exists (file));
        rm (file);
        GLib.assert_true (!GLib.File.exists (file));

        GLib.assert_true (wait_for_path_changed (file));
    }


    /***********************************************************
    ***********************************************************/
    private void testRenameAFile () {
        string file1 = this.root_path + "/a2/renamefile";
        string file2 = this.root_path + "/a2/renamefile.renamed";
        GLib.assert_true (GLib.File.exists (file1));
        mv (file1, file2);
        GLib.assert_true (GLib.File.exists (file2));

        GLib.assert_true (wait_for_path_changed (file1));
        GLib.assert_true (wait_for_path_changed (file2));
    }


    /***********************************************************
    ***********************************************************/
    private void testMoveAFile () {
        string old_file = this.root_path + "/a1/movefile";
        string new_file = this.root_path + "/a2/movefile.renamed";
        GLib.assert_true (GLib.File.exists (old_file));
        mv (old_file, new_file);
        GLib.assert_true (GLib.File.exists (new_file));

        GLib.assert_true (wait_for_path_changed (old_file));
        GLib.assert_true (wait_for_path_changed (new_file));
    }


    /***********************************************************
    ***********************************************************/
    private void testRenameDirectorySameBase () {
        string old_file = this.root_path + "/a1/b1";
        string new_file = this.root_path + "/a1/brename";
        GLib.assert_true (GLib.File.exists (old_file));
        mv (old_file, new_file);
        GLib.assert_true (GLib.File.exists (new_file));

        GLib.assert_true (wait_for_path_changed (old_file));
        GLib.assert_true (wait_for_path_changed (new_file));

        // Verify that further notifications end up with the correct paths

        string file = this.root_path + "/a1/brename/c1/random.bin";
        touch (file);
        GLib.assert_true (wait_for_path_changed (file));

        string directory = this.root_path + "/a1/brename/newfolder";
        mkdir (directory);
        GLib.assert_true (wait_for_path_changed (directory));
    }


    /***********************************************************
    ***********************************************************/
    private void test_rename_directory_different_base () {

        string old_file = this.root_path + "/a1/brename";
        string new_file = this.root_path + "/bren";
        GLib.assert_true (GLib.File.exists (old_file));
        mv (old_file, new_file);
        GLib.assert_true (GLib.File.exists (new_file));

        GLib.assert_true (wait_for_path_changed (old_file));
        GLib.assert_true (wait_for_path_changed (new_file));

        // Verify that further notifications end up with the correct paths

        string file = this.root_path + "/bren/c1/random.bin";
        touch (file);
        GLib.assert_true (wait_for_path_changed (file));

        string directory = this.root_path + "/bren/newfolder2";
        mkdir (directory);
        GLib.assert_true (wait_for_path_changed (directory));
    }


    int check_watch_count (int n) {
        GLib.assert_cmp (this.watcher.testLinuxWatchCount (), (n));
    }


    static void touch (string file) {
        string command;
        command = "touch %1".arg (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    static void mkdir (string file) {
        string command = "mkdir %1".arg (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    static void rmdir (string file) {
        string command = "rmdir %1".arg (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    static void rm (string file) {
        string command = "rm %1".arg (file);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }


    static void mv (string file1, string file2) {
        string command = "mv %1 %2".arg (file1, file2);
        GLib.debug ("Command: " + command);
        system (command.to_local_8_bit ());
    }

}
}
