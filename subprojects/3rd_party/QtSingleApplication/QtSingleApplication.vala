namespace SharedTools {

/***********************************************************
@class SingleApplication

@author 2014 Digia Plc and/or its subsidiary (-ies).

This file is part of Qt Creator.

@copyright LGPLv2.1 or later
***********************************************************/
public class SingleApplication { //: GLib.Application {

//    /***********************************************************
//    ***********************************************************/
//    const int INSTANCES_SIZE = 1024;

//    private int64 first_peer;
//    private GLib.SharedMemory instances;
//    private QtLocalPeer pid_peer;
//    private Gtk.Widget act_win;
//    private string app_id;
//    private bool block;

//    internal signal void signal_message_received (string message, GLib.Object socket);
//    internal signal void signal_file_open_request (string file);

//    /***********************************************************
//    ***********************************************************/
//    public SingleApplication (string identifier, int argc, char **argv) {
//        base (argc, argv);
//        this.first_peer = -1;
//        this.pid_peer = null;
//        this.app_id = app_id;

//        string app_session_id = QtLocalPeer.app_session_id (app_id);

//        // This shared memory holds a zero-terminated array of active (or crashed) instances
//        instances = new GLib.Shared_memory (app_session_id, this);
//        act_win = null;
//        block = false;

//        // First instance creates the shared memory, later instances attach to it
//        bool created = instances.create (INSTANCES_SIZE);
//        if (!created) {
//            if (!instances.attach ()) {
//                GLib.warning () << "Failed to initialize instances shared memory: "
//                           << instances.error_string;
//                delete instances;
//                instances = null;
//                return;
//            }
//        }

//        var pids = (int64)instances;
//        if (!created) {
//            // Find the first instance that it still running
//            // The whole list needs to be iterated in order to append to it
//            for (; *pids; ++pids) {
//                if (first_peer == -1 && is_running (pids)) {
//                    first_peer = *pids;
//                }
//            }
//        }
//        // Add current pid to list and terminate it
//        *pids++ = GLib.Application.application_pid ();
//        *pids = 0;
//        pid_peer = new QtLocalPeer (
//            this,
//            app_id + '-' +
//            GLib.Application.application_pid ().to_string ()
//        );
//        pid_peer.signal_message_received.connect (
//            this.signal_message_received
//        );
//        pid_peer.is_client ();
//    }


//    ~SingleApplication () {
//        if (!instances) {
//            return;
//        }
//        int64 app_pid = GLib.Application.application_pid ();
//        // Rewrite array, removing current pid and previously crashed ones
//        var pids = (int64) instances;
//        int64 newpids = pids;
//        for (; *pids; ++pids) {
//            if (pids != app_pid && is_running (pids)) {
//                *newpids++ = *pids;
//            }
//        }
//        *newpids = 0;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public bool event (Gdk.Event event) {
//        if (event.type () == Gdk.Event.File_open) {
//            var foe = (GLib.File_open_event)event;
//            signal_file_open_request (foe.file ());
//            return true;
//        }
//        return GLib.Application.event (event);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public string application_id () {
//        return app_id;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public bool is_running (int64 pid) {
//        if (pid == -1) {
//            pid = first_peer;
//            if (pid == -1) {
//                return false;
//            }
//        }

//        QtLocalPeer peer = new QtLocalPeer (this, app_id + '-' + string.number (pid, 10));
//        return peer.is_client ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    public Gtk.Widget activation_window () {
//        return act_win;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void set_activation_window (Gtk.Widget aw, bool activate_on_message) {
//        act_win = aw;
//        if (!pid_peer) {
//            return;
//        }
//        if (activate_on_message) {
//            pid_peer.signal_message_received.connect (
//                this.on_signal_activate_window
//            );
//        }
//        else {
//            pid_peer.signal_message_received.disconnect (
//                this.on_signal_activate_window
//            );
//        }
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void set_block (bool value) {
//        block = value;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public bool on_send_message (string message, int timeout = 5000, int64 pid = -1) {
//        if (pid == -1) {
//            pid = first_peer;
//            if (pid == -1) {
//                return false;
//            }
//        }

//        QtLocalPeer peer = new QtLocalPeer (this, app_id + '-' + string.number (pid, 10));
//        return peer.on_send_message (message, timeout, block);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void on_signal_activate_window () {
//        if (act_win) {
//            act_win.set_window_state (act_win.window_state () & ~GLib.Window_minimized);
//            act_win.raise ();
//            act_win.on_signal_activate_window ();
//        }
//    }


//    /***********************************************************
//    ***********************************************************/
//    private string instances_filename (string app_id);

}

} // namespace SharedTools
//    