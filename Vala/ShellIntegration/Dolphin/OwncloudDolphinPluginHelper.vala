/*************************************************************
  Copyright (C) 2014 by Olivier Goffart <ogoffart@woboq.com                *
                                                                           *
  This program is free software; you can redistribute it and/or modify     *
  it under the terms of the GNU General Public License as published by     *
  the Free Software Foundation; either version 2 of the License, or        *
  (at your option) any later version.                                      *
                                                                           *
  This program is distributed in the hope that it will be useful,          *
  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
  GNU General Public License for more details.                             *
                                                                           *
  You should have received a copy of the GNU General Public License        *
  along with this program; if not, write to the                            *
  Free Software Foundation, Inc.,                                          *
  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA               *
 ******************************************************************************/

//  #include <QBasicTimer>
//  #include <QLocalSocket>
//  #include <QRegularExpression>

class OWNCLOUDDOLPHINPLUGINHELPER_EXPORT OwncloudDolphinPluginHelper : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public static OwncloudDolphinPluginHelper instance ();

    /***********************************************************
    ***********************************************************/
    public bool isConnected ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public GLib.Vector<string> paths () { return this.paths; }


    public string contextMenuTitle () {
        return this.strings.value ("CONTEXT_MENU_TITLE", APPLICATION_NAME);
    }


    /***********************************************************
    ***********************************************************/
    public string shareActionTitle () {
    }


    /***********************************************************
    ***********************************************************/
    public string contextMenuIconName () {
        return this.strings.value ("CONTEXT_MENU_ICON", APPLICATION_ICON_NAME);
    }


    /***********************************************************
    ***********************************************************/
    public string copyPrivateLinkTitle () { return this.strings["COPY_PRIVATE_LINK_MENU_TITLE"]; }}


    public
    public GLib.ByteArray version () { return this.version; }

signals:
    void commandRecieved (GLib.ByteArray cmd);

    protected void timerEvent (QTimerEvent*) override;

    protected private OwncloudDolphinPluginHelper ();
    protected private void slotConnected ();
    protected private void slotReadyRead ();
    protected private void tryConnect ();
    protected private QLocalSocket this.socket;
    protected private GLib.ByteArray this.line;
    protected private GLib.Vector<string> this.paths;
    protected private QBasicTimer this.connectTimer;

    protected private GLib.HashMap<string, string> this.strings;
    protected private GLib.ByteArray this.version;
}












/*************************************************************
  Copyright (C) 2014 by Olivier Goffart <ogoffart@woboq.com                *
                                                                           *
  This program is free software; you can redistribute it and/or modify     *
  it under the terms of the GNU General Public License as published by     *
  the Free Software Foundation; either version 2 of the License, or        *
  (at your option) any later version.                                      *
                                                                           *
  This program is distributed in the hope that it will be useful,          *
  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
  GNU General Public License for more details.                             *
                                                                           *
  You should have received a copy of the GNU General Public License        *
  along with this program; if not, write to the                            *
  Free Software Foundation, Inc.,                                          *
  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA               *
 ******************************************************************************/

//  #include <QtNetwork/QLocalSocket>
//  #include <qcoreevent.h>
//  #include <QStandardPaths>

OwncloudDolphinPluginHelper* OwncloudDolphinPluginHelper.instance () {
    static OwncloudDolphinPluginHelper self;
    return self;
}

OwncloudDolphinPluginHelper.OwncloudDolphinPluginHelper () {
    connect (&this.socket, &QLocalSocket.connected, this, &OwncloudDolphinPluginHelper.slotConnected);
    connect (&this.socket, &QLocalSocket.readyRead, this, &OwncloudDolphinPluginHelper.slotReadyRead);
    this.connectTimer.on_signal_start (45 * 1000, Qt.VeryCoarseTimer, this);
    tryConnect ();
}

void OwncloudDolphinPluginHelper.timerEvent (QTimerEvent e) {
    if (e.timerId () == this.connectTimer.timerId ()) {
        tryConnect ();
        return;
    }
    GLib.Object.timerEvent (e);
}

bool OwncloudDolphinPluginHelper.isConnected () {
    return this.socket.state () == QLocalSocket.ConnectedState;
}

void OwncloudDolphinPluginHelper.sendCommand (char* data) {
    this.socket.write (data);
    this.socket.flush ();
}

void OwncloudDolphinPluginHelper.slotConnected () {
    sendCommand ("VERSION:\n");
    sendCommand ("GET_STRINGS:\n");
}

void OwncloudDolphinPluginHelper.tryConnect () {
    if (this.socket.state () != QLocalSocket.UnconnectedState) {
        return;
    }

    string socketPath = QStandardPaths.locate (QStandardPaths.RuntimeLocation,
                                                APPLICATION_SHORTNAME,
                                                QStandardPaths.LocateDirectory);
    if (socketPath.isEmpty ())
        return;

    this.socket.connectToServer (socketPath + "/socket");
}

void OwncloudDolphinPluginHelper.slotReadyRead () {
    while (this.socket.bytesAvailable ()) {
        this.line += this.socket.readLine ();
        if (!this.line.endsWith ("\n"))
            continue;
        GLib.ByteArray line;
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
                this.connectTimer.stop ();
                this.socket.disconnectFromServer ();
                return;
            }
        }
        /* emit */ commandRecieved (line);
    }
}
