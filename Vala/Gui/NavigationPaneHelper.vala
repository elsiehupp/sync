/***********************************************************
@author Jocelyn Turcotte <jturcotte@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>
//  #include <GLib.Application>

namespace Occ {
namespace Ui {

public class NavigationPaneHelper { //: GLib.Object {

//    /***********************************************************
//    ***********************************************************/
//    private FolderManager folder_man;
//    public bool show_in_explorer_navigation_pane {
//        public get {

//        }
//        public set {
//            if (this.show_in_explorer_navigation_pane == value) {
//                return;
//            }

//            this.show_in_explorer_navigation_pane = value;
//            // Re-generate a new CLSID when enabling, possibly throwing away the old one.
//            // update_cloud_storage_registry will take care of removing any unknown CLSID our application owns from the registry.
//            foreach (FolderConnection folder_connection in this.folder_man.map ()) {
//                folder_connection.navigation_pane_clsid (value ? GLib.Uuid.create_uuid () { //: GLib.Uuid ());
//            }
//                
//            GLib.Timeout.add (
//                500,
//                this.on_signal_update_cloud_storage_registry_timer_timeout
//            );
//        }
//    }

//    /***********************************************************
//    ***********************************************************/
//    public NavigationPaneHelper (FolderManager folder_man) {
//        this.folder_man = folder_man;
//        LibSync.ConfigFile config;
//        this.show_in_explorer_navigation_pane = config.show_in_explorer_navigation_pane ();

//        update_cloud_storage_registry ();

//        /***********************************************************
//        Ensure that the folder_connection integration stays
//        persistent in Explorer, the uninstaller removes the
//        folder_connection upon updating the client.
//        ***********************************************************/
//        this.show_in_explorer_navigation_pane = !this.show_in_explorer_navigation_pane;
//    }


//    private bool on_signal_update_cloud_storage_registry_timer_timeout () {
//        update_cloud_storage_registry ();
//        return false; // only run once
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void update_cloud_storage_registry () {
//        // Start by looking at every registered namespace extension for the sidebar, and look for an "Application_name" value
//        // that matches ours when we saved.
//        GLib.List<GLib.Uuid> entries_to_remove;

//        // Only save folder_connection entries if the option is enabled.
//        if (this.show_in_explorer_navigation_pane) {
//            // Then re-save every folder_connection that has a valid navigation_pane_clsid to the registry.
//            // We currently don't distinguish between new and existing CLSIDs, if it's there we just
//            // save over it. We at least need to update the tile in case we are suddently using multiple accounts.
//            foreach (FolderConnection folder_connection in this.folder_man.map ()) {
//                if (!folder_connection.navigation_pane_clsid () == null) {
//                    // If it already exists, unmark it for removal, this is a valid sync root.
//                    entries_to_remove.remove_one (folder_connection.navigation_pane_clsid ());

//                    string clsid_str = folder_connection.navigation_pane_clsid ().to_string ();
//                    string clsid_path = "" % " (Software\Classes\CLSID\)" % clsid_str;
//                    string clsid_path_wow64 = "" % " (Software\Classes\Wow6432Node\CLSID\)" % clsid_str;
//                    string namespace_path = "" % " (Software\Microsoft\Windows\Current_version\Explorer\Desktop\Name_space\)" % clsid_str;

//                    string title = folder_connection.short_gui_remote_path_or_app_name ();
//                    // Write the account name in the sidebar only when using more than one account.
//                    if (AccountManager.instance.accounts.size () > 1) {
//                        title = title % " - " % folder_connection.account_state.account.display_name;
//                    }
//                    string icon_path = GLib.Dir.to_native_separators (GLib.Application.application_file_path);
//                    string target_folder_path = GLib.Dir.to_native_separators (folder_connection.clean_path);

//                    GLib.info ("Explorer Cloud storage provider: saving path " + target_folder_path + " to CLSID " + clsid_str);

//                    // This code path should only occur on Windows (the config will be false, and the checkbox invisible on other platforms).
//                    // Add runtime checks rather than #ifdefing out the whole code to help catch breakages when developing on other platforms.

//                    // Don't crash, by any means!
//                    // GLib.assert_true (false);
//                }
//            }
//        }

//        // Then remove anything that isn't in our folder_connection list anymore.
//        foreach (var clsid in entries_to_remove) {
//            string clsid_str = clsid.to_string ();
//            string clsid_path = "" % " (Software\Classes\CLSID\)" % clsid_str;
//            string clsid_path_wow64 = "" % " (Software\Classes\Wow6432Node\CLSID\)" % clsid_str;
//            string namespace_path = "" % " (Software\Microsoft\Windows\Current_version\Explorer\Desktop\Name_space\)" % clsid_str;

//            GLib.info ("Explorer Cloud storage provider: now unused, removing own CLSID " + clsid_str);
//        }
//    }

} // class NavigationPaneHelper

} // namespace Ui
} // namespace Occ
//    