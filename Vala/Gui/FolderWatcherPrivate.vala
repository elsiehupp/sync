/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <sys/inotify.h>
//  #include <cerrno>
//  #include <QVarLengthArray>
//  #include <QSocket_notifier>
//  #include <QDir>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Linux (inotify) API implementation of Folder_watcher
@ingroup gui
***********************************************************/
class Folder_watcher_private : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Folder_watcher_private () = default;
    public Folder_watcher_private (Folder_watcher p, string path);
    ~Folder_watcher_private () override;

    /***********************************************************
    ***********************************************************/
    public int test_watch_count () {
        return this.path_to_watch.size ();
    }

    /// On linux the watcher is ready when the ctor on_signal_finished.
    public bool this.ready = true;

protected slots:
    void on_signal_received_notification (int fd);
    void on_signal_add_folder_recursive (string path);


    protected bool find_folders_below (QDir dir, string[] full_list);
    protected void inotify_register_path (string path);
    protected void remove_folders_below (string path);


    /***********************************************************
    ***********************************************************/
    private Folder_watcher this.parent;

    /***********************************************************
    ***********************************************************/
    private string this.folder;
    private GLib.HashMap<int, string> this.watch_to_path;
    private GLib.HashMap<string, int> this.path_to_watch;
    private QScopedPointer<QSocket_notifier> this.socket;
    private int this.fd;
}


    Folder_watcher_private.Folder_watcher_private (Folder_watcher p, string path)
        : GLib.Object ()
        this.parent (p)
        this.folder (path) {
        this.fd = inotify_init ();
        if (this.fd != -1) {
            this.socket.on_signal_reset (new QSocket_notifier (this.fd, QSocket_notifier.Read));
            connect (this.socket.data (), &QSocket_notifier.activated, this, &Folder_watcher_private.on_signal_received_notification);
        } else {
            GLib.warning ("notify_init () failed : " + strerror (errno);
        }

        QMetaObject.invoke_method (this, "on_signal_add_folder_recursive", Q_ARG (string, path));
    }

    Folder_watcher_private.~Folder_watcher_private () = default;

    // attention : result list passed by reference!
    bool Folder_watcher_private.find_folders_below (QDir dir, string[] full_list) {
        bool ok = true;
        if (! (dir.exists () && dir.is_readable ())) {
            GLib.debug ("Non existing path coming in : " + dir.absolute_path ();
            ok = false;
        } else {
            string[] name_filter;
            name_filter + QLatin1String ("*");
            QDir.Filters filter = QDir.Dirs | QDir.NoDotAndDotDot | QDir.No_sym_links | QDir.Hidden;
            const string[] pathes = dir.entry_list (name_filter, filter);

            string[].ConstIterator ConstIterator;
            for (ConstIterator = pathes.const_begin (); ConstIterator != pathes.const_end ();
                 ++ConstIterator) {
                const string full_path (dir.path () + QLatin1String ("/") + (*ConstIterator));
                full_list.append (full_path);
                ok = find_folders_below (QDir (full_path), full_list);
            }
        }

        return ok;
    }

    void Folder_watcher_private.inotify_register_path (string path) {
        if (path.is_empty ())
            return;

        int wd = inotify_add_watch (this.fd, path.to_utf8 ().const_data (),
            IN_CLOSE_WRITE | IN_ATTRIB | IN_MOVE | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF | IN_UNMOUNT | IN_ONLYDIR);
        if (wd > -1) {
            this.watch_to_path.insert (wd, path);
            this.path_to_watch.insert (path, wd);
        } else {
            // If we're running out of memory or inotify watches, become
            // unreliable.
            if (this.parent.is_reliable && (errno == ENOMEM || errno == ENOSPC)) {
                this.parent.is_reliable = false;
                /* emit */ this.parent.became_unreliable (
                    _("This problem usually happens when the inotify watches are exhausted. "
                       "Check the FAQ for details."));
            }
        }
    }

    void Folder_watcher_private.on_signal_add_folder_recursive (string path) {
        if (this.path_to_watch.contains (path))
            return;

        int subdirs = 0;
        GLib.debug (" (+) Watcher:" + path;

        QDir in_path (path);
        inotify_register_path (in_path.absolute_path ());

        string[] all_subfolders;
        if (!find_folders_below (QDir (path), all_subfolders)) {
            GLib.warning ("Could not traverse all sub folders";
        }
        QStringListIterator subfolders_it (all_subfolders);
        while (subfolders_it.has_next ()) {
            string subfolder = subfolders_it.next ();
            QDir folder (subfolder);
            if (folder.exists () && !this.path_to_watch.contains (folder.absolute_path ())) {
                subdirs++;
                if (this.parent.path_is_ignored (subfolder)) {
                    GLib.debug ("* Not adding" + folder.path ();
                    continue;
                }
                inotify_register_path (folder.absolute_path ());
            } else {
                GLib.debug ("    `. discarded:" + folder.path ();
            }
        }

        if (subdirs > 0) {
            GLib.debug ("    `. and" + subdirs + "subdirectories";
        }
    }

    void Folder_watcher_private.on_signal_received_notification (int fd) {
        int len = 0;
        struct inotify_event event = null;
        size_t i = 0;
        int error = 0;
        QVarLengthArray<char, 2048> buffer (2048);

        len = read (fd, buffer.data (), buffer.size ());
        error = errno;
        /***********************************************************
        From inotify documentation:
        The behavior when the buffer given to read (2) is too
        small to return information about the next event
        depends on the kernel version : in kernels  before 2.6.21,
        read (2) returns 0; since kernel 2.6.21, read (2) fails with
        the error EINVAL.
        */
        while (len < 0 && error == EINVAL) {
            // double the buffer size
            buffer.resize (buffer.size () * 2);

            /* and try again ... */
            len = read (fd, buffer.data (), buffer.size ());
            error = errno;
        }

        // iterate events in buffer
        uint32 ulen = len;
        for (i = 0; i + sizeof (inotify_event) < ulen; i += sizeof (inotify_event) + (event ? event.len : 0)) {
            // cast an inotify_event
            event = (struct inotify_event *)&buffer[i];
            if (!event) {
                GLib.debug ("NULL event";
                continue;
            }

            // Fire event for the path that was changed.
            if (event.len == 0 || event.wd <= -1)
                continue;
            GLib.ByteArray filename (event.name);
            // Filter out journal changes - redundant with filtering in
            // Folder_watcher.path_is_ignored.
            if (filename.starts_with (".sync_")
                || filename.starts_with (".csync_journal.db")
                || filename.starts_with (".sync_")) {
                continue;
            }
            const string p = this.watch_to_path[event.wd] + '/' + filename;
            this.parent.change_detected (p);

            if ( (event.mask & (IN_MOVED_TO | IN_CREATE))
                && GLib.FileInfo (p).is_dir ()
                && !this.parent.path_is_ignored (p)) {
                on_signal_add_folder_recursive (p);
            }
            if (event.mask & (IN_MOVED_FROM | IN_DELETE)) {
                remove_folders_below (p);
            }
        }
    }

    void Folder_watcher_private.remove_folders_below (string path) {
        var it = this.path_to_watch.find (path);
        if (it == this.path_to_watch.end ())
            return;

        string path_slash = path + '/';

        // Remove the entry and all subentries
        while (it != this.path_to_watch.end ()) {
            var it_path = it.key ();
            if (!it_path.starts_with (path))
                break;
            if (it_path != path && !it_path.starts_with (path_slash)) {
                // order is 'foo', 'foo bar', 'foo/bar'
                ++it;
                continue;
            }

            var wid = it.value ();
            inotify_rm_watch (this.fd, wid);
            this.watch_to_path.remove (wid);
            it = this.path_to_watch.erase (it);
            GLib.debug ("Removed watch for" + it_path;
        }
    }

    } // namespace mirall
    