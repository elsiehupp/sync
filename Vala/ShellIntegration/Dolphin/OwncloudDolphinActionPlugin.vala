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

//  #include <KCoreAddons/KPluginFactory>
//  #include <KCoreAddons/KPluginLoader>
//  #include <KIOWidgets/kabstractfileitemactionplugin.h>
//  #include <QtNetwork/QLocalSocket>
//  #include <KIOCore/kfileitem.h>
//  #include <KIOCore/KFileItemListProperties>
//  #include <QtWidgets/QAction>
//  #include <QtWidgets/QMenu>
//  #include <QtCore/QDir>
//  #include <QtCore/QTimer>
//  #include <QtCore/QEventLoop>

public class OwncloudDolphinPluginAction : KAbstractFileItemActionPlugin {

    /***********************************************************
    ***********************************************************/
    public OwncloudDolphinPluginAction (GLib.Object parent, GLib.List<GLib.Variant>&)
        : KAbstractFileItemActionPlugin (parent) { }


    /***********************************************************
    ***********************************************************/
    public GLib.List<QAction> actions (KFileItemListProperties& fileItemInfos, Gtk.Widget* parentWidget) override {
        var helper = OwncloudDolphinPluginHelper.instance ();
        if (!helper.isConnected () || !fileItemInfos.isLocal ())
            return {};

        // If any of the url is outside of a sync folder, return an empty menu.
        const GLib.List<GLib.Uri> urls = fileItemInfos.urlList ();
        const var paths = helper.paths ();
        GLib.ByteArray files;
        for (var url : urls) {
            QDir local_path (url.toLocalFile ());
            var localFile = local_path.canonicalPath ();
            if (!std.any_of (paths.begin (), paths.end (), [&] (string s) {
                    return localFile.startsWith (s);
                }))
                return {};

            if (!files.isEmpty ())
                files += '\x1e'; // Record separator
            files += localFile.toUtf8 ();
        }

        if (helper.version () < "1.1") { // in this case, lexicographic order works
            return legacyActions (fileItemInfos, parentWidget);
        }

        var menu = new QMenu (parentWidget);
        QEventLoop loop;
        var con = connect (helper, &OwncloudDolphinPluginHelper.commandRecieved, this, [&] (GLib.ByteArray cmd) {
            if (cmd.startsWith ("GET_MENU_ITEMS:END")) {
                loop.quit ();
            } else if (cmd.startsWith ("MENU_ITEM:")) {
                var args = string.fromUtf8 (cmd).split (':');
                if (args.size () < 4) {
                    return;
                }
                var action = menu.addAction (args.mid (3).join (':'));
                if (args.value (2).contains ('d')) {
                    action.setDisabled (true);
                }
                var call = args.value (1).toLatin1 ();
                connect (action, &QAction.triggered, [helper, call, files] {
                    helper.sendCommand (GLib.ByteArray (call + ":" + files + "\n"));
                });
            }
        });
        QTimer.singleShot (100, loop, SLOT (quit ())); // add a timeout to be sure we don't freeze dolphin
        helper.sendCommand (GLib.ByteArray ("GET_MENU_ITEMS:" + files + "\n"));
        loop.exec (QEventLoop.ExcludeUserInputEvents);
        disconnect (con);
        if (menu.actions ().isEmpty ()) {
            delete menu;
            return {};
        }

        menu.setTitle (helper.contextMenuTitle ());
        menu.setIcon (Gtk.Icon.fromTheme (helper.contextMenuIconName ()));
        return { menu.menuAction ());
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<QAction> legacyActions (KFileItemListProperties fileItemInfos, Gtk.Widget parentWidget) {
        GLib.List<GLib.Uri> urls = fileItemInfos.urlList ();
        if (urls.count () != 1)
            return {};
        QDir local_path (urls.first ().toLocalFile ());
        var localFile = local_path.canonicalPath ();
        var helper = OwncloudDolphinPluginHelper.instance ();
        var menuaction = new QAction (parentWidget);
        menuaction.setText (helper.contextMenuTitle ());
        var menu = new QMenu (parentWidget);
        menuaction.setMenu (menu);

        var shareAction = menu.addAction (helper.shareActionTitle ());
        connect (shareAction, &QAction.triggered, this, [localFile, helper] {
            helper.sendCommand (GLib.ByteArray ("SHARE:" + localFile.toUtf8 () + "\n"));
        });

        if (!helper.copyPrivateLinkTitle ().isEmpty ()) {
            var copyPrivateLinkAction = menu.addAction (helper.copyPrivateLinkTitle ());
            connect (copyPrivateLinkAction, &QAction.triggered, this, [localFile, helper] {
                helper.sendCommand (GLib.ByteArray ("COPY_PRIVATE_LINK:" + localFile.toUtf8 () + "\n"));
            });
        }

        if (!helper.emailPrivateLinkTitle ().isEmpty ()) {
            var emailPrivateLinkAction = menu.addAction (helper.emailPrivateLinkTitle ());
            connect (emailPrivateLinkAction, &QAction.triggered, this, [localFile, helper] {
                helper.sendCommand (GLib.ByteArray ("EMAIL_PRIVATE_LINK:" + localFile.toUtf8 () + "\n"));
            });
        }
        return { menuaction };
    }

}

K_PLUGIN_FACTORY (OwncloudDolphinPluginActionFactory, registerPlugin<OwncloudDolphinPluginAction> ();)

#include "ownclouddolphinactionplugin.moc"
