/*************************************************************
Copyright (C) 2014 by Olivier Goffart <ogoffart@woboq.com

<GPLv2-or-later-Boilerplate>
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

    //  K_PLUGIN_FACTORY (OwncloudDolphinPluginActionFactory, registerPlugin<OwncloudDolphinPluginAction> ();)

    /***********************************************************
    ***********************************************************/
    public OwncloudDolphinPluginAction (GLib.Object parent, GLib.List<GLib.Variant> list) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public override GLib.List<QAction> actions (KFileItemListProperties file_item_infos, Gtk.Widget* parentWidget) {
        var helper = OwncloudDolphinPluginHelper.instance;
        if (!helper.is_connected () || !file_item_infos.is_local ()) {
            return {};
        }

        // If any of the url is outside of a sync folder, return an empty menu.
        const GLib.List<GLib.Uri> urls = file_item_infos.url_list ();
        const var paths = helper.paths ();
        string files;
        foreach (var url in urls) {
            QDir local_path = new QDir (url.to_local_file ());
            var local_file = local_path.canonical_path ();
            if (!std.any_of (paths.begin (), paths.end (), filter))
                return {};

            if (!files.isEmpty ())
                files += '\x1e'; // Record separator
            files += local_file.toUtf8 ();
        }

        if (helper.version () < "1.1") { // in this case, lexicographic order works
            return legacyActions (file_item_infos, parentWidget);
        }

        var menu = new QMenu (parentWidget);
        QEventLoop loop;
        var con = connect (
            helper,
            OwncloudDolphinPluginHelper.signal_command_received,
            this,
            on_signal_helper_commad_received
        );
        QTimer.singleShot (100, loop, SLOT (quit ())); // add a timeout to be sure we don't freeze dolphin
        helper.send_command (string ("GET_MENU_ITEMS:" + files + "\n"));
        loop.exec (QEventLoop.ExcludeUserInputEvents);
        disconnect (con);
        if (menu.actions ().isEmpty ()) {
            delete menu;
            return {};
        }

        menu.setTitle (helper.context_menu_title ());
        menu.setIcon (Gtk.Icon.fromTheme (helper.context_menu_icon_name ()));
        return { menu.menu_action () };
    }


    private static bool filter (string local_file, string s) {
        return local_file.startsWith (s);
    }


    private void on_signal_helper_commad_received (string cmd) {
        if (cmd.startsWith ("GET_MENU_ITEMS:END")) {
            loop.quit ();
        } else if (cmd.startsWith ("MENU_ITEM:")) {
            var args = string.fromUtf8 (cmd).split (':');
            if (args.size () < 4) {
                return;
            }
            var action = menu.add_action (args.mid (3).join (':'));
            if (args.value (2).contains ('d')) {
                action.setDisabled (true);
            }
            var call = args.value (1).toLatin1 ();
            connect (
                action,
                QAction.triggered,
                on_signal_action_triggered
            );
        }
    }


    private static void on_signal_action_triggered (OwncloudDolphinPluginHelper helper, string call, string files) {
        helper.send_command (call + ":" + files + "\n");
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<QAction> legacyActions (KFileItemListProperties file_item_infos, Gtk.Widget parentWidget) {
        GLib.List<GLib.Uri> urls = file_item_infos.url_list ();
        if (urls.count () != 1)
            return {};
        QDir local_path = new QDir (urls.first ().to_local_file ());
        var local_file = local_path.canonical_path ();
        var helper = OwncloudDolphinPluginHelper.instance;
        var menuaction = new QAction (parentWidget);
        menuaction.setText (helper.context_menu_title ());
        var menu = new QMenu (parentWidget);
        menuaction.setMenu (menu);

        var share_action = menu.add_action (helper.share_action_title ());
        connect (
            share_action,
            Action.triggered,
            this,
            on_signal_share_action_triggered
        );

        if (!helper.copy_private_link_title ().isEmpty ()) {
            var copy_private_link_action = menu.add_action (helper.copy_private_link_title ());
            connect (
                copy_private_link_action,
                QAction.triggered,
                this,
                on_signal_copy_private_link_action_triggered
            );
        }

        if (!helper.emailPrivateLinkTitle ().isEmpty ()) {
            var email_private_link_action = menu.add_action (helper.emailPrivateLinkTitle ());
            connect (
                email_private_link_action,
                QAction.triggered,
                this,
                on_signal_email_private_link_action_triggered
            );
        }
        return { menuaction };
    }


    private static void on_signal_share_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        helper.send_command ("SHARE:" + local_file + "\n");
    }


    private static void on_signal_copy_private_link_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        helper.send_command (string ("COPY_PRIVATE_LINK:" + local_file.toUtf8 () + "\n"));
    }


    private static void on_signal_email_private_link_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        helper.send_command ("EMAIL_PRIVATE_LINK:" + local_file + "\n");
    }

}

