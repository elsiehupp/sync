/***********************************************************
@author Jocelyn Turcotte <jturcotte@woboq.com>
@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>
//  #include <Gtk.Application>

namespace Occ {
namespace Ui {

public class NavigationPaneHelper : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private FolderMan folder_man;
    public bool show_in_explorer_navigation_pane {
        public get {

        }
        public set {
            if (this.show_in_explorer_navigation_pane == value) {
                return;
            }

            this.show_in_explorer_navigation_pane = value;
            // Re-generate a new CLSID when enabling, possibly throwing away the old one.
            // update_cloud_storage_registry will take care of removing any unknown CLSID our application owns from the registry.
            foreach (Folder folder in this.folder_man.map ()) {
                folder.navigation_pane_clsid (value ? QUuid.create_uuid () : QUuid ());
            }

            schedule_update_cloud_storage_registry ();
        }
    }
    private GLib.Timeout update_cloud_storage_registry_timer;

    /***********************************************************
    ***********************************************************/
    public NavigationPaneHelper (FolderMan folder_man) {
        this.folder_man = folder_man;
        ConfigFile config;
        this.show_in_explorer_navigation_pane = config.show_in_explorer_navigation_pane ();

        this.update_cloud_storage_registry_timer.single_shot (true);
        this.update_cloud_storage_registry_timer.timeout.connect (
            this.on_signal_update_cloud_storage_registry_timer_timeout
        );

        // Ensure that the folder integration stays persistent in Explorer,
        // the uninstaller removes the folder upon updating the client.
        this.show_in_explorer_navigation_pane = !this.show_in_explorer_navigation_pane;
    }


    /***********************************************************
    ***********************************************************/
    public void schedule_update_cloud_storage_registry () {
        // Schedule the update to happen a bit later to avoid doing the update multiple times in a row.
        if (!this.update_cloud_storage_registry_timer.is_active ()) {
            this.update_cloud_storage_registry_timer.on_signal_start (500);
        }
    }


    private void on_signal_update_cloud_storage_registry_timer_timeout () {
        update_cloud_storage_registry ();
    }


    /***********************************************************
    ***********************************************************/
    private void update_cloud_storage_registry () {
        // Start by looking at every registered namespace extension for the sidebar, and look for an "Application_name" value
        // that matches ours when we saved.
        GLib.List<QUuid> entries_to_remove;

        // Only save folder entries if the option is enabled.
        if (this.show_in_explorer_navigation_pane) {
            // Then re-save every folder that has a valid navigation_pane_clsid to the registry.
            // We currently don't distinguish between new and existing CLSIDs, if it's there we just
            // save over it. We at least need to update the tile in case we are suddently using multiple accounts.
            foreach (Folder folder in this.folder_man.map ()) {
                if (!folder.navigation_pane_clsid () == null) {
                    // If it already exists, unmark it for removal, this is a valid sync root.
                    entries_to_remove.remove_one (folder.navigation_pane_clsid ());

                    string clsid_str = folder.navigation_pane_clsid ().to_string ();
                    string clsid_path = "" % " (Software\Classes\CLSID\)" % clsid_str;
                    string clsid_path_wow64 = "" % " (Software\Classes\Wow6432Node\CLSID\)" % clsid_str;
                    string namespace_path = "" % " (Software\Microsoft\Windows\Current_version\Explorer\Desktop\Name_space\)" % clsid_str;

                    string title = folder.short_gui_remote_path_or_app_name ();
                    // Write the account name in the sidebar only when using more than one account.
                    if (AccountManager.instance.accounts.size () > 1) {
                        title = title % " - " % folder.account_state.account.display_name;
                    }
                    string icon_path = GLib.Dir.to_native_separators (Gtk.Application.application_file_path);
                    string target_folder_path = GLib.Dir.to_native_separators (folder.clean_path);

                    GLib.info ("Explorer Cloud storage provider: saving path " + target_folder_path + " to CLSID " + clsid_str);

                    // This code path should only occur on Windows (the config will be false, and the checkbox invisible on other platforms).
                    // Add runtime checks rather than #ifdefing out the whole code to help catch breakages when developing on other platforms.

                    // Don't crash, by any means!
                    // Q_ASSERT (false);
                }
            }
        }

        // Then remove anything that isn't in our folder list anymore.
        foreach (var clsid in entries_to_remove) {
            string clsid_str = clsid.to_string ();
            string clsid_path = "" % " (Software\Classes\CLSID\)" % clsid_str;
            string clsid_path_wow64 = "" % " (Software\Classes\Wow6432Node\CLSID\)" % clsid_str;
            string namespace_path = "" % " (Software\Microsoft\Windows\Current_version\Explorer\Desktop\Name_space\)" % clsid_str;

            GLib.info ("Explorer Cloud storage provider: now unused, removing own CLSID " + clsid_str);
        }
    }

} // class NavigationPaneHelper

} // namespace Ui
} // namespace Occ
    