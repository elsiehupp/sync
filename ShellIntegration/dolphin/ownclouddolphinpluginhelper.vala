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

// #pragma once
// #include <QBasicTimer>
// #include <QLocalSocket>
// #include <QRegularExpression>

class OWNCLOUDDOLPHINPLUGINHELPER_EXPORT OwncloudDolphinPluginHelper : GLib.Object {

    public static OwncloudDolphinPluginHelper instance ();

    public bool isConnected ();


    public void sendCommand (char data);


    public QVector<string> paths () { return _paths; }


    public string contextMenuTitle () {
        return _strings.value ("CONTEXT_MENU_TITLE", APPLICATION_NAME);
    }
    public string shareActionTitle () {
        return _strings.value ("SHARE_MENU_TITLE", "Share …");
    }
    public string contextMenuIconName () {
        return _strings.value ("CONTEXT_MENU_ICON", APPLICATION_ICON_NAME);
    }


    public string copyPrivateLinkTitle () { return _strings["COPY_PRIVATE_LINK_MENU_TITLE"]; }}


    public
    public GLib.ByteArray version () { return _version; }

signals:
    void commandRecieved (GLib.ByteArray cmd);

    protected void timerEvent (QTimerEvent*) override;

    protected private OwncloudDolphinPluginHelper ();
    protected private void slotConnected ();
    protected private void slotReadyRead ();
    protected private void tryConnect ();
    protected private QLocalSocket _socket;
    protected private GLib.ByteArray _line;
    protected private QVector<string> _paths;
    protected private QBasicTimer _connectTimer;

    protected private QMap<string, string> _strings;
    protected private GLib.ByteArray _version;
};












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

// #include <QtNetwork/QLocalSocket>
// #include <qcoreevent.h>
// #include <QStandardPaths>
// #include <GLib.File>

OwncloudDolphinPluginHelper* OwncloudDolphinPluginHelper.instance () {
    static OwncloudDolphinPluginHelper self;
    return &self;
}

OwncloudDolphinPluginHelper.OwncloudDolphinPluginHelper () {
    connect (&_socket, &QLocalSocket.connected, this, &OwncloudDolphinPluginHelper.slotConnected);
    connect (&_socket, &QLocalSocket.readyRead, this, &OwncloudDolphinPluginHelper.slotReadyRead);
    _connectTimer.on_start (45 * 1000, Qt.VeryCoarseTimer, this);
    tryConnect ();
}

void OwncloudDolphinPluginHelper.timerEvent (QTimerEvent e) {
    if (e.timerId () == _connectTimer.timerId ()) {
        tryConnect ();
        return;
    }
    GLib.Object.timerEvent (e);
}

bool OwncloudDolphinPluginHelper.isConnected () {
    return _socket.state () == QLocalSocket.ConnectedState;
}

void OwncloudDolphinPluginHelper.sendCommand (char* data) {
    _socket.write (data);
    _socket.flush ();
}

void OwncloudDolphinPluginHelper.slotConnected () {
    sendCommand ("VERSION:\n");
    sendCommand ("GET_STRINGS:\n");
}

void OwncloudDolphinPluginHelper.tryConnect () {
    if (_socket.state () != QLocalSocket.UnconnectedState) {
        return;
    }

    string socketPath = QStandardPaths.locate (QStandardPaths.RuntimeLocation,
                                                APPLICATION_SHORTNAME,
                                                QStandardPaths.LocateDirectory);
    if (socketPath.isEmpty ())
        return;

    _socket.connectToServer (socketPath + "/socket");
}

void OwncloudDolphinPluginHelper.slotReadyRead () {
    while (_socket.bytesAvailable ()) {
        _line += _socket.readLine ();
        if (!_line.endsWith ("\n"))
            continue;
        GLib.ByteArray line;
        qSwap (line, _line);
        line.chop (1);
        if (line.isEmpty ())
            continue;

        if (line.startsWith ("REGISTER_PATH:")) {
            var col = line.indexOf (':');
            string file = string.fromUtf8 (line.constData () + col + 1, line.size () - col - 1);
            _paths.append (file);
            continue;
        } else if (line.startsWith ("STRING:")) {
            var args = string.fromUtf8 (line).split (':');
            if (args.size () >= 3) {
                _strings[args[1]] = args.mid (2).join (':');
            }
            continue;
        } else if (line.startsWith ("VERSION:")) {
            var args = line.split (':');
            var version = args.value (2);
            _version = version;
            if (!version.startsWith ("1.")) {
                // Incompatible version, disconnect forever
                _connectTimer.stop ();
                _socket.disconnectFromServer ();
                return;
            }
        }
        emit commandRecieved (line);
    }
}
