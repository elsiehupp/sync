/*************************************************************
@author 2014 by Olivier Goffart <ogoffart@woboq.com

<GPLv2-or-later-Boilerplate>
******************************************************************************/

//  #include <KCoreAddons/KPluginFactory>
//  #include <KCoreAddons/KPluginLoader>
//  #include <KIOWidgets/kabstractfileitemactionplugin.h>
//  #include <QtNetwork/GLib.LocalSocket>
//  #include <KIOCore/kfileitem.h>
//  #include <KIOCore/KFileItemListProperties>
//  #include <QtWidgets/GLib.Action>
//  #include <QtWidgets/GLib.Menu>
//  #include <QtCore/GLib.Dir>
//  #include <QtCore/GLib.Timeout>
//  #include <QtCore/GLib.MainLoop>

public class OwncloudDolphinPluginAction : KAbstractFileItemActionPlugin {

    //  K_PLUGIN_FACTORY (OwncloudDolphinPluginActionFactory, registerPlugin<OwncloudDolphinPluginAction> ();)

    /***********************************************************
    ***********************************************************/
    public OwncloudDolphinPluginAction (
        GLib.List<GLib.Variant> list
    ) {
        //  base ();
    }


    /***********************************************************
    ***********************************************************/
    public override GLib.List<GLib.Action> actions (KFileItemListProperties file_item_infos, Gtk.Widget* parentWidget) {
        //  var helper = OwncloudDolphinPluginHelper.instance;
        //  if (!helper.is_connected || !file_item_infos.is_local ()) {
        //      return {};
        //  }

        //  // If any of the url is outside of a sync folder, return an empty menu.
        //  GLib.List<GLib.Uri> urls = file_item_infos.url_list ();
        //  var paths = helper.paths ();
        //  string files;
        //  foreach (var url in urls) {
        //      GLib.Dir local_path = new GLib.Dir (url.to_local_file ());
        //      var local_file = local_path.canonical_path;
        //      if (!std.any_of (paths.begin (), paths.end (), filter))
        //          return {};

        //      if (!files.isEmpty ())
        //          files += '\x1e'; // Record separator
        //      files += local_file.toUtf8 ();
        //  }

        //  if (helper.version < "1.1") { // in this case, lexicographic order works
        //      return legacyActions (file_item_infos, parentWidget);
        //  }

        //  var menu = new GLib.Menu (parentWidget);
        //  GLib.MainLoop loop;
        //  var con = connect (
        //      helper,
        //      OwncloudDolphinPluginHelper.signal_command_received,
        //      this,
        //      on_signal_helper_commad_received
        //  );
        //  GLib.Timeout.singleShot (100, loop, SLOT (quit ())); // add a timeout to be sure we don't freeze dolphin
        //  helper.send_command ("GET_MENU_ITEMS:" + files + "\n");
        //  loop.exec (GLib.MainLoop.ExcludeUserInputEvents);
        //  disconnect (con);
        //  if (menu.actions ().isEmpty ()) {
        //      delete menu;
        //      return {};
        //  }

        //  menu.setTitle (helper.context_menu_title ());
        //  menu.setIcon (Gtk.IconInfo.fromTheme (helper.context_menu_icon_name ()));
        //  return { menu.menu_action () };
    }


    private static bool filter (string local_file, string s) {
        //  return local_file.startsWith (s);
    }


    private void on_signal_helper_commad_received (string cmd) {
        //  if (cmd.startsWith ("GET_MENU_ITEMS:END")) {
        //      loop.quit ();
        //  } else if (cmd.startsWith ("MENU_ITEM:")) {
        //      var args = string.fromUtf8 (cmd).split (':');
        //      if (args.size () < 4) {
        //          return;
        //      }
        //      var action = menu.add_action (args.mid (3).join (':'));
        //      if (args.value (2).contains ('d')) {
        //          action.setDisabled (true);
        //      }
        //      var call = args.value (1).toLatin1 ();
        //      action.triggered.connect (
        //          this.on_signal_action_triggered
        //      );
        //  }
    }


    private static void on_signal_action_triggered (OwncloudDolphinPluginHelper helper, string call, string files) {
        //  helper.send_command (call + ":" + files + "\n");
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.Action> legacyActions (KFileItemListProperties file_item_infos, Gtk.Widget parentWidget) {
        //  GLib.List<GLib.Uri> urls = file_item_infos.url_list ();
        //  if (urls.length != 1)
        //      return {};
        //  GLib.Dir local_path = new GLib.Dir (urls.nth_data (0).to_local_file ());
        //  var local_file = local_path.canonical_path;
        //  var helper = OwncloudDolphinPluginHelper.instance;
        //  var menuaction = new GLib.Action (parentWidget);
        //  menuaction.setText (helper.context_menu_title ());
        //  var menu = new GLib.Menu (parentWidget);
        //  menuaction.setMenu (menu);

        //  var share_action = menu.add_action (helper.share_action_title ());
        //  share_action.triggered.connect (
        //      this.on_signal_share_action_triggered
        //  );

        //  if (!helper.copy_private_link_title ().isEmpty ()) {
        //      var copy_private_link_action = menu.add_action (helper.copy_private_link_title ());
        //      copy_private_link_action.triggered.connect (
        //          this.on_signal_copy_private_link_action_triggered
        //      );
        //  }

        //  if (!helper.emailPrivateLinkTitle ().isEmpty ()) {
        //      var email_private_link_action = menu.add_action (helper.emailPrivateLinkTitle ());
        //      email_private_link_action.triggered.connect (
        //          this.on_signal_email_private_link_action_triggered
        //      );
        //  }
        //  return { menuaction };
    }


    private static void on_signal_share_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        //  helper.send_command ("SHARE:" + local_file + "\n");
    }


    private static void on_signal_copy_private_link_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        //  helper.send_command ("COPY_PRIVATE_LINK:" + local_file.toUtf8 () + "\n");
    }


    private static void on_signal_email_private_link_action_triggered (string local_file, OwncloudDolphinPluginHelper helper) {
        //  helper.send_command ("EMAIL_PRIVATE_LINK:" + local_file + "\n");
    }

}

