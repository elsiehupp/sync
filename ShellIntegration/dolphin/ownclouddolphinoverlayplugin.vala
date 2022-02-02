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

// #include <KOverlayIconPlugin>
// #include <KPluginFactory>
// #include <QtNetwork/QLocalSocket>
// #include <KIOCore/kfileitem.h>
// #include <QDir>
// #include <QTimer>

class OwncloudDolphinPlugin : KOverlayIconPlugin {
    Q_PLUGIN_METADATA (IID "com.owncloud.ovarlayiconplugin" FILE "ownclouddolphinoverlayplugin.json")

    using StatusMap = GLib.HashMap<GLib.ByteArray, GLib.ByteArray>;
    StatusMap m_status;

    /***********************************************************
    ***********************************************************/
    public OwncloudDolphinPlugin () {
        var helper = OwncloudDolphinPluginHelper.instance ();
        GLib.Object.connect (helper, &OwncloudDolphinPluginHelper.commandRecieved,
                         this, &OwncloudDolphinPlugin.slotCommandRecieved);
    }


    /***********************************************************
    ***********************************************************/
    public string[] getOverlays (GLib.Uri& url) override {
        var helper = OwncloudDolphinPluginHelper.instance ();
        if (!helper.isConnected ())
            return string[] ();
        if (!url.isLocalFile ())
            return string[] ();
        QDir localPath (url.toLocalFile ());
        const GLib.ByteArray localFile = localPath.canonicalPath ().toUtf8 ();

        helper.sendCommand (GLib.ByteArray ("RETRIEVE_FILE_STATUS:" + localFile + "\n"));

        StatusMap.iterator it = m_status.find (localFile);
        if (it != m_status.constEnd ()) {
            return  overlaysForString (*it);
        }
        return string[] ();
    }


    /***********************************************************
    ***********************************************************/
    private string[] overlaysForString (GLib.ByteArray status) {
        string[] r;
        if (status.startsWith ("NOP"))
            return r;

        if (status.startsWith ("OK"))
            r << "vcs-normal";
        if (status.startsWith ("SYNC") || status.startsWith ("NEW"))
            r << "vcs-update-required";
        if (status.startsWith ("IGNORE") || status.startsWith ("WARN"))
            r << "vcs-locally-modified-unstaged";
        if (status.startsWith ("ERROR"))
            r << "vcs-conflicting";

        if (status.contains ("+SWM"))
            r << "document-share";

        return r;
    }


    /***********************************************************
    ***********************************************************/
    private void slotCommandRecieved (GLib.ByteArray line) {

        GLib.List<GLib.ByteArray> tokens = line.split (':');
        if (tokens.count () < 3)
            return;
        if (tokens[0] != "STATUS" && tokens[0] != "BROADCAST")
            return;
        if (tokens[2].isEmpty ())
            return;

        // We can't use tokens[2] because the filename might contain ':'
        int secondColon = line.indexOf (":", line.indexOf (":") + 1);
        const GLib.ByteArray name = line.mid (secondColon + 1);
        GLib.ByteArray status = m_status[name]; // reference to the item in the hash
        if (status == tokens[1])
            return;
        status = tokens[1];

        /* emit */ overlaysChanged (GLib.Uri.fromLocalFile (string.fromUtf8 (name)), overlaysForString (status));
    }
};
