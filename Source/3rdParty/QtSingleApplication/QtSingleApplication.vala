/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <QApplication>

QT_FORWARD_DECLARE_CLASS (QShared_memory)

namespace SharedTools {


class QtSingleApplication : QApplication {

    public QtSingleApplication (string id, int &argc, char **argv);
    ~QtSingleApplication () override;

    public bool is_running (int64 pid = -1);

    public void set_activation_window (Gtk.Widget* aw, bool activate_on_message = true);


    public Gtk.Widget* activation_window ();


    public bool event (QEvent event) override;

    public string application_id ();


    public void set_block (bool value);


    public bool on_send_message (string message, int timeout = 5000, int64 pid = -1);


    public void on_activate_window ();

signals:
    void message_received (string message, GLib.Object socket);
    void file_open_request (string file);


    private string instances_file_name (string app_id);

    int64 first_peer;
    QShared_memory instances;
    QtLocalPeer pid_peer;
    Gtk.Widget act_win;
    string app_id;
    bool block;
};

} // namespace SharedTools










/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <qtlockedfile.h>

// #include <QDir>
// #include <QFile_open_event>
// #include <QShared_memory>
// #include <Gtk.Widget>

namespace SharedTools {

    static const int instances_size = 1024;

    static string instances_lock_filename (string app_session_id) {
        const char slash = '/';
        string res = QDir.temp_path ();
        if (!res.ends_with (slash))
            res += slash;
        return res + app_session_id + QLatin1String ("-instances");
    }

    QtSingleApplication.QtSingleApplication (string app_id, int &argc, char **argv)
        : QApplication (argc, argv),
          first_peer (-1),
          pid_peer (nullptr) {
        this.app_id = app_id;

        const string app_session_id = QtLocalPeer.app_session_id (app_id);

        // This shared memory holds a zero-terminated array of active (or crashed) instances
        instances = new QShared_memory (app_session_id, this);
        act_win = nullptr;
        block = false;

        // First instance creates the shared memory, later instances attach to it
        const bool created = instances.create (instances_size);
        if (!created) {
            if (!instances.attach ()) {
                q_warning () << "Failed to initialize instances shared memory : "
                           << instances.error_string ();
                delete instances;
                instances = nullptr;
                return;
            }
        }

        // QtLockedFile is used to workaround QTBUG-10364
        QtLockedFile lockfile (instances_lock_filename (app_session_id));

        lockfile.open (QtLockedFile.ReadWrite);
        lockfile.lock (QtLockedFile.LockMode.WRITE_LOCK);
        var pids = static_cast<int64> (instances.data ());
        if (!created) {
            // Find the first instance that it still running
            // The whole list needs to be iterated in order to append to it
            for (; *pids; ++pids) {
                if (first_peer == -1 && is_running (*pids))
                    first_peer = *pids;
            }
        }
        // Add current pid to list and terminate it
        *pids++ = QCoreApplication.application_pid ();
        *pids = 0;
        pid_peer = new QtLocalPeer (this, app_id + '-' +
                                  string.number (QCoreApplication.application_pid ()));
        connect (pid_peer, &QtLocalPeer.message_received, this, &QtSingleApplication.message_received);
        pid_peer.is_client ();
        lockfile.unlock ();
    }

    QtSingleApplication.~QtSingleApplication () {
        if (!instances)
            return;
        const int64 app_pid = QCoreApplication.application_pid ();
        QtLockedFile lockfile (instances_lock_filename (QtLocalPeer.app_session_id (app_id)));
        lockfile.open (QtLockedFile.ReadWrite);
        lockfile.lock (QtLockedFile.LockMode.WRITE_LOCK);
        // Rewrite array, removing current pid and previously crashed ones
        var pids = static_cast<int64> (instances.data ());
        int64 newpids = pids;
        for (; *pids; ++pids) {
            if (*pids != app_pid && is_running (*pids))
                *newpids++ = *pids;
        }
        *newpids = 0;
        lockfile.unlock ();
    }

    bool QtSingleApplication.event (QEvent event) {
        if (event.type () == QEvent.File_open) {
            var foe = static_cast<QFile_open_event> (event);
            emit file_open_request (foe.file ());
            return true;
        }
        return QApplication.event (event);
    }

    bool QtSingleApplication.is_running (int64 pid) {
        if (pid == -1) {
            pid = first_peer;
            if (pid == -1)
                return false;
        }

        QtLocalPeer peer (this, app_id + '-' + string.number (pid, 10));
        return peer.is_client ();
    }

    bool QtSingleApplication.on_send_message (string message, int timeout, int64 pid) {
        if (pid == -1) {
            pid = first_peer;
            if (pid == -1)
                return false;
        }

        QtLocalPeer peer (this, app_id + '-' + string.number (pid, 10));
        return peer.on_send_message (message, timeout, block);
    }

    string QtSingleApplication.application_id () {
        return app_id;
    }

    void QtSingleApplication.set_block (bool value) {
        block = value;
    }

    void QtSingleApplication.set_activation_window (Gtk.Widget aw, bool activate_on_message) {
        act_win = aw;
        if (!pid_peer)
            return;
        if (activate_on_message)
            connect (pid_peer, &QtLocalPeer.message_received, this, &QtSingleApplication.on_activate_window);
        else
            disconnect (pid_peer, &QtLocalPeer.message_received, this, &QtSingleApplication.on_activate_window);
    }

    Gtk.Widget* QtSingleApplication.activation_window () {
        return act_win;
    }

    void QtSingleApplication.on_activate_window () {
        if (act_win) {
            act_win.set_window_state (act_win.window_state () & ~Qt.Window_minimized);
            act_win.raise ();
            act_win.on_activate_window ();
        }
    }

    } // namespace SharedTools
    