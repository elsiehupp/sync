/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <sys/inotify.h>

// #include <cerrno>
// #include <QStringList>
// #include <GLib.Object>
// #include <QVarLengthArray>

// #include <GLib.Object>
// #include <string>
// #include <QSocket_notifier>
// #include <QHash>
// #include <QDir>


namespace Occ {

/***********************************************************
@brief Linux (inotify) API implementation of Folder_watcher
@ingroup gui
***********************************************************/
class Folder_watcher_private : GLib.Object {

    public Folder_watcher_private () = default;
    public Folder_watcher_private (Folder_watcher *p, string &path);
    public ~Folder_watcher_private () override;

    public int test_watch_count () {
        return _path_to_watch.size ();
    }

    /// On linux the watcher is ready when the ctor finished.
    public bool _ready = true;

protected slots:
    void slot_received_notification (int fd);
    void slot_add_folder_recursive (string &path);

protected:
    bool find_folders_below (QDir &dir, QStringList &full_list);
    void inotify_register_path (string &path);
    void remove_folders_below (string &path);

private:
    Folder_watcher *_parent;

    string _folder;
    QHash<int, string> _watch_to_path;
    QMap<string, int> _path_to_watch;
    QScopedPointer<QSocket_notifier> _socket;
    int _fd;
};


    Folder_watcher_private.Folder_watcher_private (Folder_watcher *p, string &path)
        : GLib.Object ()
        , _parent (p)
        , _folder (path) {
        _fd = inotify_init ();
        if (_fd != -1) {
            _socket.reset (new QSocket_notifier (_fd, QSocket_notifier.Read));
            connect (_socket.data (), &QSocket_notifier.activated, this, &Folder_watcher_private.slot_received_notification);
        } else {
            q_c_warning (lc_folder_watcher) << "notify_init () failed : " << strerror (errno);
        }

        QMetaObject.invoke_method (this, "slot_add_folder_recursive", Q_ARG (string, path));
    }

    Folder_watcher_private.~Folder_watcher_private () = default;

    // attention : result list passed by reference!
    bool Folder_watcher_private.find_folders_below (QDir &dir, QStringList &full_list) {
        bool ok = true;
        if (! (dir.exists () && dir.is_readable ())) {
            q_c_debug (lc_folder_watcher) << "Non existing path coming in : " << dir.absolute_path ();
            ok = false;
        } else {
            QStringList name_filter;
            name_filter << QLatin1String ("*");
            QDir.Filters filter = QDir.Dirs | QDir.NoDotAndDotDot | QDir.No_sym_links | QDir.Hidden;
            const QStringList pathes = dir.entry_list (name_filter, filter);

            QStringList.Const_iterator Const_iterator;
            for (Const_iterator = pathes.const_begin (); Const_iterator != pathes.const_end ();
                 ++Const_iterator) {
                const string full_path (dir.path () + QLatin1String ("/") + (*Const_iterator));
                full_list.append (full_path);
                ok = find_folders_below (QDir (full_path), full_list);
            }
        }

        return ok;
    }

    void Folder_watcher_private.inotify_register_path (string &path) {
        if (path.is_empty ())
            return;

        int wd = inotify_add_watch (_fd, path.to_utf8 ().const_data (),
            IN_CLOSE_WRITE | IN_ATTRIB | IN_MOVE | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF | IN_UNMOUNT | IN_ONLYDIR);
        if (wd > -1) {
            _watch_to_path.insert (wd, path);
            _path_to_watch.insert (path, wd);
        } else {
            // If we're running out of memory or inotify watches, become
            // unreliable.
            if (_parent._is_reliable && (errno == ENOMEM || errno == ENOSPC)) {
                _parent._is_reliable = false;
                emit _parent.became_unreliable (
                    tr ("This problem usually happens when the inotify watches are exhausted. "
                       "Check the FAQ for details."));
            }
        }
    }

    void Folder_watcher_private.slot_add_folder_recursive (string &path) {
        if (_path_to_watch.contains (path))
            return;

        int subdirs = 0;
        q_c_debug (lc_folder_watcher) << " (+) Watcher:" << path;

        QDir in_path (path);
        inotify_register_path (in_path.absolute_path ());

        QStringList all_subfolders;
        if (!find_folders_below (QDir (path), all_subfolders)) {
            q_c_warning (lc_folder_watcher) << "Could not traverse all sub folders";
        }
        QStringListIterator subfolders_it (all_subfolders);
        while (subfolders_it.has_next ()) {
            string subfolder = subfolders_it.next ();
            QDir folder (subfolder);
            if (folder.exists () && !_path_to_watch.contains (folder.absolute_path ())) {
                subdirs++;
                if (_parent.path_is_ignored (subfolder)) {
                    q_c_debug (lc_folder_watcher) << "* Not adding" << folder.path ();
                    continue;
                }
                inotify_register_path (folder.absolute_path ());
            } else {
                q_c_debug (lc_folder_watcher) << "    `. discarded:" << folder.path ();
            }
        }

        if (subdirs > 0) {
            q_c_debug (lc_folder_watcher) << "    `. and" << subdirs << "subdirectories";
        }
    }

    void Folder_watcher_private.slot_received_notification (int fd) {
        int len = 0;
        struct inotify_event *event = nullptr;
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
        unsigned int ulen = len;
        for (i = 0; i + sizeof (inotify_event) < ulen; i += sizeof (inotify_event) + (event ? event.len : 0)) {
            // cast an inotify_event
            event = (struct inotify_event *)&buffer[i];
            if (!event) {
                q_c_debug (lc_folder_watcher) << "NULL event";
                continue;
            }

            // Fire event for the path that was changed.
            if (event.len == 0 || event.wd <= -1)
                continue;
            QByteArray file_name (event.name);
            // Filter out journal changes - redundant with filtering in
            // Folder_watcher.path_is_ignored.
            if (file_name.starts_with ("._sync_")
                || file_name.starts_with (".csync_journal.db")
                || file_name.starts_with (".sync_")) {
                continue;
            }
            const string p = _watch_to_path[event.wd] + '/' + file_name;
            _parent.change_detected (p);

            if ( (event.mask & (IN_MOVED_TO | IN_CREATE))
                && QFileInfo (p).is_dir ()
                && !_parent.path_is_ignored (p)) {
                slot_add_folder_recursive (p);
            }
            if (event.mask & (IN_MOVED_FROM | IN_DELETE)) {
                remove_folders_below (p);
            }
        }
    }

    void Folder_watcher_private.remove_folders_below (string &path) {
        auto it = _path_to_watch.find (path);
        if (it == _path_to_watch.end ())
            return;

        string path_slash = path + '/';

        // Remove the entry and all subentries
        while (it != _path_to_watch.end ()) {
            auto it_path = it.key ();
            if (!it_path.starts_with (path))
                break;
            if (it_path != path && !it_path.starts_with (path_slash)) {
                // order is 'foo', 'foo bar', 'foo/bar'
                ++it;
                continue;
            }

            auto wid = it.value ();
            inotify_rm_watch (_fd, wid);
            _watch_to_path.remove (wid);
            it = _path_to_watch.erase (it);
            q_c_debug (lc_folder_watcher) << "Removed watch for" << it_path;
        }
    }

    } // ns mirall
    