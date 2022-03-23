namespace Occ {
namespace Ui {

/***********************************************************
@class FolderWatcher

@brief Monitors a directory recursively for changes

@details FolderConnection Watcher monitors a directory and its
subdirectories for changes in the local file system.
through the signal_path_changed () signal.

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class FolderWatcher : GLib.Object {

    protected GLib.HashTable<string, int> pending_pathes;

    /***********************************************************
    ***********************************************************/
    private FolderWatcherPrivate d;
    private GLib.Timer timer;
    private GLib.List<string> last_paths;
    private FolderConnection folder_connection;

    /***********************************************************
    Returns false if the folder_connection watcher can't be trusted to capture all
    notifications.

    For example, this can happen on linux if the inotify user limit from
    /proc/sys/fs/inotify/max_user_watches is exceeded.
    ***********************************************************/
    public bool is_reliable { public get; private set; }

    /***********************************************************
    Path of the expected test notification
    ***********************************************************/
    private string test_notification_path;

    /***********************************************************
    ***********************************************************/
    //  private friend class FolderWatcherPrivate;

    /***********************************************************
    Emitted when one of the watched directories or one
    of the contained files is changed.
    ***********************************************************/
    internal signal void signal_path_changed (string path);

    /***********************************************************
    Emitted if some notifications were lost.

    Would happen, for example, if the number of pending notifications
    exceeded the allocated buffer size on Windows. Note that the fold
    watcher could still be able to capture all future notifications -
    i.e. is_reliable () is orthogonal to losing changes occasionally.
    ***********************************************************/
    internal signal void signal_lost_changes ();

    /***********************************************************
    Signals when the watcher became unreliable. The string is a translated
    message that can be shown to users.
    ***********************************************************/
    internal signal void signal_became_unreliable (string message);

    /***********************************************************
    Construct, connect signals, call init ()
    ***********************************************************/
    public FolderWatcher () {
        base ();
        this.is_reliable = true;
    }

    /***********************************************************
    Construct, connect signals, call init ()
    ***********************************************************/
    public FolderWatcher.with_connection (FolderConnection folder_connection) {
        base (folder_connection);
        this.folder_connection = folder_connection;
        this.is_reliable = true;
    }


    /***********************************************************
    @param root Path of the root of the folder_connection
    ***********************************************************/
    public void init (string root) {
        this.d.on_signal_reset (new FolderWatcherPrivate (this, root));
        this.timer.on_signal_start ();
    }


    /***********************************************************
    Check if the path is ignored.
    ***********************************************************/
    public bool path_is_ignored (string path) {
        if (path == "") {
            return true;
        }
        if (this.folder_connection == null) {
            return false;
        }

    //  #ifndef OWNCLOUD_TEST
        if (this.folder_connection.is_file_excluded_absolute (path) && !Utility.is_conflict_file (path)) {
            GLib.debug ("* Ignoring file " + path);
            return true;
        }
    //  #endif
        return false;
    }


    /***********************************************************
    Triggers a change in the path and verifies a notification arrives.

    If no notification is seen, the folderwatcher marks itself as unreliable.
    The path must be ignored by the watcher.
    ***********************************************************/
    public void start_notificaton_test (string path) {
        //  Q_ASSERT (this.test_notification_path == "");
        this.test_notification_path = path;

        // Don't do the local file modification immediately:
        // wait for Folder_watch_private.ready
        on_signal_start_notification_test_when_ready ();
    }


    /***********************************************************
    For testing linux behavior only
    ***********************************************************/
    public int test_linux_watch_count () {
        return this.d.test_watch_count ();
    }


    /***********************************************************
    Called from the implementations to indicate a change in path
    ***********************************************************/
    protected void on_signal_change_detected_for_single_path (string path) {
        GLib.FileInfo file_info = new GLib.FileInfo (path);
        GLib.List<string> paths = new GLib.List<string> ();
        paths.append (path);
        if (file_info.is_dir ()) {
            GLib.Dir directory = new GLib.Dir (path);
            append_sub_paths (directory, paths);
        }
        on_signal_change_detected_for_multiple_paths (paths);
    }


    /***********************************************************
    Called from the implementations to indicate a change in path
    ***********************************************************/
    protected void on_signal_change_detected_for_multiple_paths (GLib.List<string> paths) {
        // TODO: this shortcut doesn't look very reliable:
        //   - why is the timeout only 1 second?
        //   - what if there is more than one file being updated frequently?
        //   - why do we skip the file altogether instead of e.g. reducing the upload frequency?

        // Check if the same path was reported within the last second.
        GLib.List<string> paths_set = paths.to_set ();
        if (paths_set == this.last_paths && this.timer.elapsed () < 1000) {
            // the same path was reported within the last second. Skip.
            return;
        }
        this.last_paths = paths_set;
        this.timer.restart ();

        GLib.List<string> changed_paths;

        // ------- handle ignores:
        for (int i = 0; i < paths.size (); ++i) {
            string path = paths[i];
            if (this.test_notification_path != ""
                && Utility.filenames_equal (path, this.test_notification_path)) {
                this.test_notification_path = "";
            }
            if (path_is_ignored (path)) {
                continue;
            }

            changed_paths.insert (path);
        }
        if (changed_paths.length () == 0) {
            return;
        }

        GLib.info ("Detected changes in paths: " + changed_paths.to_string ());
        foreach (string path in changed_paths) {
            /* emit */ signal_path_changed (path);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_notification_test_when_ready () {
        if (!this.d.ready) {
            GLib.Timeout.single_shot (1000, this, FolderWatcher.on_signal_start_notification_test_when_ready);
            return;
        }

        var path = this.test_notification_path;
        if (GLib.File.exists (path)) {
            var mtime = FileSystem.mod_time (path);
            FileSystem.mod_time (path, mtime + 1);
        } else {
            GLib.File f = new GLib.File (path);
            f.open (QIODevice.WriteOnly | QIODevice.Append);
        }

        GLib.Timeout.single_shot (5000, this, on_timer);
    }


    /***********************************************************
    ***********************************************************/
    private void on_timer () {
        if (this.test_notification_path != "") {
            /* emit */ signal_became_unreliable (_("The watcher did not receive a test notification."));
        }
        this.test_notification_path == "";
    }


    /***********************************************************
    ***********************************************************/
    private void append_sub_paths (GLib.Dir directory, GLib.List<string> sub_paths) {
        GLib.List<string> new_sub_paths = directory.entry_list (GLib.Dir.NoDotAndDotDot | GLib.Dir.Dirs | GLib.Dir.Files);
        for (int i = 0; i < new_sub_paths.size (); i++) {
            string path = directory.path + "/" + new_sub_paths[i];
            GLib.FileInfo file_info = new GLib.FileInfo (path);
            sub_paths.append (path);
            if (file_info.is_dir ()) {
                GLib.Dir directory = new GLib.Dir (path);
                append_sub_paths (directory, sub_paths);
            }
        }
    }

} // class FolderWatcher

} // namespace Ui
} // namespace Occ
