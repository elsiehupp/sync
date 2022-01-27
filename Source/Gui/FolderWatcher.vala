/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// event masks

// #include <cstdint>

// #include <QFileInfo>
// #include <QFlags>
// #include <QDir>
// #include <QMutexLocker>
// #include <string[]>
// #include <QTimer>

// #include <GLib.List>
// #include <QLoggingCategory>
// #include <GLib.Object>
// #include <string>
// #include <string[]>
// #include <QElapsedTimer>
// #include <QHash>
// #include <QScopedPointer>
// #include <QSet>
// #include <QDir>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_folder_watcher)


/***********************************************************
@brief Monitors a directory recursively for changes

Folder Watcher monitors a directory and its sub directories
for changes in the local file system.
through the path_changed () signal.

@ingroup gui
***********************************************************/

class Folder_watcher : GLib.Object {

    // Construct, connect signals, call on_init ()
    public Folder_watcher (Folder *folder = nullptr);
    ~Folder_watcher () override;

    /***********************************************************
    @param root Path of the root of the folder
    ***********************************************************/
    public void on_init (string root);

    
    /***********************************************************
    Check if the path is ignored.
    ***********************************************************/
    public bool path_is_ignored (string path);

    /***********************************************************
    Returns false if the folder watcher can't be trusted to capture all
    notifications.

    For example, this can happen on linux if the inotify user limit from
    /proc/sys/fs/inotify/max_user_watches is exceeded.
    ***********************************************************/
    public bool is_reliable ();

    /***********************************************************
    Triggers a change in the path and verifies a notification arrives.

    If no notification is seen, the folderwatcher marks itself as unreliable.
    The path must be ignored by the watcher.
    ***********************************************************/
    public void start_notificaton_test (string path);

    /// For testing linux behavior only
    public int test_linux_watch_count ();

signals:
    /***********************************************************
    Emitted when one of the watched directories or one
    of the contained files is changed.
    ***********************************************************/
    void path_changed (string path);

    /***********************************************************
    Emitted if some notifications were lost.

    Would happen, for example, if the number of pending notifications
    exceeded the allocated buffer size on Windows. Note that the fold
    watcher could still be able to capture all future notifications -
    i.e. is_reliable () is orthogonal to losing changes occasionally.
    ***********************************************************/
    void lost_changes ();

    /***********************************************************
    Signals when the watcher became unreliable. The string is a translated
    message that can be shown to users.
    ***********************************************************/
    void became_unreliable (string message);

protected slots:
    // called from the implementations to indicate a change in path
    void change_detected (string path);
    void change_detected (string[] &paths);


    private void on_start_notification_test_when_ready ();


    protected QHash<string, int> _pending_pathes;


    private QScopedPointer<Folder_watcher_private> _d;
    private QElapsedTimer _timer;
    private QSet<string> _last_paths;
    private Folder _folder;
    private bool _is_reliable = true;

    private void append_sub_paths (QDir dir, string[]& sub_paths);

    /***********************************************************
    Path of the expected test notification
    ***********************************************************/
    private string _test_notification_path;

    private friend class Folder_watcher_private;
};

    Folder_watcher.Folder_watcher (Folder *folder)
        : GLib.Object (folder)
        , _folder (folder) {
    }

    Folder_watcher.~Folder_watcher () = default;

    void Folder_watcher.on_init (string root) {
        _d.on_reset (new Folder_watcher_private (this, root));
        _timer.on_start ();
    }

    bool Folder_watcher.path_is_ignored (string path) {
        if (path.is_empty ())
            return true;
        if (!_folder)
            return false;

    #ifndef OWNCLOUD_TEST
        if (_folder.is_file_excluded_absolute (path) && !Utility.is_conflict_file (path)) {
            q_c_debug (lc_folder_watcher) << "* Ignoring file" << path;
            return true;
        }
    #endif
        return false;
    }

    bool Folder_watcher.is_reliable () {
        return _is_reliable;
    }

    void Folder_watcher.append_sub_paths (QDir dir, string[]& sub_paths) {
        string[] new_sub_paths = dir.entry_list (QDir.NoDotAndDotDot | QDir.Dirs | QDir.Files);
        for (int i = 0; i < new_sub_paths.size (); i++) {
            string path = dir.path () + "/" + new_sub_paths[i];
            QFileInfo file_info (path);
            sub_paths.append (path);
            if (file_info.is_dir ()) {
                QDir dir (path);
                append_sub_paths (dir, sub_paths);
            }
        }
    }

    void Folder_watcher.start_notificaton_test (string path) {
        Q_ASSERT (_test_notification_path.is_empty ());
        _test_notification_path = path;

        // Don't do the local file modification immediately:
        // wait for Folder_watch_private._ready
        on_start_notification_test_when_ready ();
    }

    void Folder_watcher.on_start_notification_test_when_ready () {
        if (!_d._ready) {
            QTimer.single_shot (1000, this, &Folder_watcher.on_start_notification_test_when_ready);
            return;
        }

        auto path = _test_notification_path;
        if (QFile.exists (path)) {
            auto mtime = FileSystem.get_mod_time (path);
            FileSystem.set_mod_time (path, mtime + 1);
        } else {
            QFile f (path);
            f.open (QIODevice.WriteOnly | QIODevice.Append);
        }

        QTimer.single_shot (5000, this, [this] () {
            if (!_test_notification_path.is_empty ())
                emit became_unreliable (tr ("The watcher did not receive a test notification."));
            _test_notification_path.clear ();
        });
    }

    int Folder_watcher.test_linux_watch_count () {
    #ifdef Q_OS_LINUX
        return _d.test_watch_count ();
    #else
        return -1;
    #endif
    }

    void Folder_watcher.change_detected (string path) {
        QFileInfo file_info (path);
        string[] paths (path);
        if (file_info.is_dir ()) {
            QDir dir (path);
            append_sub_paths (dir, paths);
        }
        change_detected (paths);
    }

    void Folder_watcher.change_detected (string[] &paths) {
        // TODO : this shortcut doesn't look very reliable:
        //   - why is the timeout only 1 second?
        //   - what if there is more than one file being updated frequently?
        //   - why do we skip the file altogether instead of e.g. reducing the upload frequency?

        // Check if the same path was reported within the last second.
        QSet<string> paths_set = paths.to_set ();
        if (paths_set == _last_paths && _timer.elapsed () < 1000) {
            // the same path was reported within the last second. Skip.
            return;
        }
        _last_paths = paths_set;
        _timer.restart ();

        QSet<string> changed_paths;

        // ------- handle ignores:
        for (int i = 0; i < paths.size (); ++i) {
            string path = paths[i];
            if (!_test_notification_path.is_empty ()
                && Utility.file_names_equal (path, _test_notification_path)) {
                _test_notification_path.clear ();
            }
            if (path_is_ignored (path)) {
                continue;
            }

            changed_paths.insert (path);
        }
        if (changed_paths.is_empty ()) {
            return;
        }

        q_c_info (lc_folder_watcher) << "Detected changes in paths:" << changed_paths;
        foreach (string path, changed_paths) {
            emit path_changed (path);
        }
    }

    } // namespace Occ
    