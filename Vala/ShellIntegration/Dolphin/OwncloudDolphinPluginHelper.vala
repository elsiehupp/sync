/***********************************************************
@author 2014 by Olivier Goffart <ogoffart@woboq.com

<GPLv2-or-later-Boilerplate>
***********************************************************/

//  #include <QBasicTimer>
//  #include <QLocalSocket>
//  #include <QRegularExpression>
//  #include <QtNetwork/QLocalSocket>
//  #include <qcoreevent.h>
//  #include <QStandardPaths>

// OWNCLOUDDOLPHINPLUGINHELPER_EXPORT
public class OwncloudDolphinPluginHelper : GLib.Object {

    /***********************************************************
    ***********************************************************/
    protected QLocalSocket socket;
    protected string line;
    protected GLib.List<string> paths;
    protected QBasicTimer connect_timer;

    protected GLib.HashTable<string, string> strings;
    protected string version;

    static OwncloudDolphinPluginHelper self;


    internal signal void signal_command_received (string cmd);

    /***********************************************************
    ***********************************************************/
    public static OwncloudDolphinPluginHelper instance {
        return OwncloudDolphinPluginHelper.self;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_connected {
        public get {
            return this.socket.state == QLocalSocket.ConnectedState;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void send_command (char* data) {
        this.socket.write (data);
        this.socket.flush ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<string> paths () {
        return this.paths;
    }


    /***********************************************************
    ***********************************************************/
    public string context_menu_title () {
        return this.strings.value ("CONTEXT_MENU_TITLE", APPLICATION_NAME);
    }


    /***********************************************************
    ***********************************************************/
    public string share_action_title () { }


    /***********************************************************
    ***********************************************************/
    public string context_menu_icon_name () {
        return this.strings.value ("CONTEXT_MENU_ICON", APPLICATION_ICON_NAME);
    }


    /***********************************************************
    ***********************************************************/
    public string copy_private_link_title () {
        return this.strings["COPY_PRIVATE_LINK_MENU_TITLE"];
    }


    /***********************************************************
    ***********************************************************/
    public string version {
        return this.version;
    }


    /***********************************************************
    ***********************************************************/
    protected override void timer_event (QTimerEvent event) {
        if (event.timer_id () == this.connect_timer.timer_id ()) {
            try_to_connect ();
            return;
        }
        GLib.Object.timer_event (e);
    }


    /***********************************************************
    ***********************************************************/
    protected OwncloudDolphinPluginHelper () {
        this.socket.connected.connect (
            this.on_signal_socket_connected
        );
        this.socket.ready_read.connect (
            this.on_signal_ready_to_read
        );
        this.connect_timer.on_signal_start (45 * 1000, Qt.VeryCoarseTimer, this);
        try_to_connect ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_socket_connected () {
        send_command ("VERSION:\n");
        send_command ("GET_STRINGS:\n");
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_ready_to_read () {
        while (this.socket.bytes_available ()) {
            this.line += this.socket.readLine ();
            if (!this.line.endsWith ("\n"))
                continue;
            string line;
            qSwap (line, this.line);
            line.chop (1);
            if (line.isEmpty ())
                continue;

            if (line.startsWith ("REGISTER_PATH:")) {
                var col = line.indexOf (':');
                string file = string.fromUtf8 (line.constData () + col + 1, line.size () - col - 1);
                this.paths.append (file);
                continue;
            } else if (line.startsWith ("STRING:")) {
                var args = string.fromUtf8 (line).split (':');
                if (args.size () >= 3) {
                    this.strings[args[1]] = args.mid (2).join (':');
                }
                continue;
            } else if (line.startsWith ("VERSION:")) {
                var args = line.split (':');
                var version = args.value (2);
                this.version = version;
                if (!version.startsWith ("1.")) {
                    // Incompatible version, disconnect forever
                    this.connect_timer.stop ();
                    this.socket.disconnectFromServer ();
                    return;
                }
            }
            /* emit */ signal_command_received (line);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void try_to_connect () {
        if (this.socket.state != QLocalSocket.UnconnectedState) {
            return;
        }

        string socketPath = QStandardPaths.locate (QStandardPaths.RuntimeLocation,
                                                    APPLICATION_SHORTNAME,
                                                    QStandardPaths.LocateDirectory);
        if (socketPath.isEmpty ())
            return;

        this.socket.connectToServer (socketPath + "/socket");
    }

}
