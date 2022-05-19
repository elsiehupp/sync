/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@author Julius Härtl <jus@bitgrid.net>

@copyright GPLv3 or Later
***********************************************************/

//  #include <cloudprovidersaccountexporter.h>
//  #include <cloudprovidersproviderexporter.h>
//  #include <account.h
//  #include <folder_connection.h>
//  #include <accountstate.h>
//  #include <GLib.DesktopServices>

namespace Occ {
namespace Ui {

public class CloudProviderWrapper : GLib.Object {

    static GActionEntry actions[] = {
        {
            "openwebsite",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "quit",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "log_out",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "openfolder",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "showfile",
            activate_action_open,
            "s",
            null,
            null,
            {0,0,0}
        },
        {
            "openhelp",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "opensettings",
            activate_action_open,
            null,
            null,
            null,
            {0,0,0}
        },
        {
            "open_recent_file",
            activate_action_open_recent_file,
            "s",
            null,
            null,
            {0,0,0}
        },
        {
            "pause",
            activate_action_pause,
            null,
            "false",
            null,
            {0,0,0}
        }
    };

    GLib.SimpleActionGroup action_group {
        public get {
            action_group = new GLib.SimpleActionGroup ();
            action_group.add_action_entries (actions, this);
            bool state = this.folder_connection.sync_paused;
            GLib.Action pause = action_group.lookup_action ("pause");
            pause.set_state (GLib.Variant.boolean (state));
            return action_group;
        }
        private set {
            this.action_group = value;
        }
    }

    public FolderConnection folder_connection { public get; private set; }

    private CloudProvidersProviderExporter cloud_provider;
    private CloudProvidersAccountExporter cloud_provider_account;
    private GLib.List<GLib.Pair<string, string>> recently_changed;
    private bool paused;
    private GLib.Menu main_menu = null;
    private GLib.Menu recent_menu = null;

    /***********************************************************
    ***********************************************************/
    public CloudProviderWrapper (GLib.Object parent = new GLib.Object (), FolderConnection folder_connection = null, int folder_identifier = 0, CloudProvidersProviderExporter* cloudprovider = null) {
        base (parent);
        this.folder_connection = folder_connection;
        GMenuModel model;
        GActionGroup action_group;
        string account_name = "FolderConnection/%1".printf (folder_identifier);

        this.cloud_provider = CLOUD_PROVIDERS_PROVIDER_EXPORTER (cloudprovider);
        this.cloud_provider_account = cloud_providers_account_exporter_new (this.cloud_provider, account_name.to_utf8 ());

        cloud_providers_account_exporter_name (this.cloud_provider_account, folder_connection.short_gui_local_path.to_utf8 ());
        cloud_providers_account_exporter_icon (this.cloud_provider_account, g_icon_new_for_string (APPLICATION_ICON_NAME, null));
        cloud_providers_account_exporter_path (this.cloud_provider_account, folder_connection.clean_path.to_utf8 ());
        cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_IDLE);
        model = menu_model ();
        cloud_providers_account_exporter_menu_model (this.cloud_provider_account, model);
        action_group = this.action_group;
        cloud_providers_account_exporter_action_group (this.cloud_provider_account, action_group);

        ProgressDispatcher.instance.signal_progress_info.connect (
            this.on_signal_update_progress
        );
        this.folder_connection.signal_sync_started.connect (
            this.on_signal_sync_started
        );
        this.folder_connection.signal_sync_finished.connect (
            this.on_signal_sync_finished
        );
        this.folder_connection.signal_sync_paused_changed.connect (
            this.on_signal_sync_paused_changed
        );

        this.paused = this.folder_connection.sync_paused;
        update_pause_status ();
        GLib.Object.clear (model);
        GLib.Object.clear (action_group);
    }


    override ~CloudProviderWrapper () {
        g_object_unref (this.cloud_provider_account);
        g_object_unref (this.main_menu);
        g_object_unref (action_group);
        g_object_unref (this.recent_menu);
    }


    /***********************************************************
    ***********************************************************/
    public CloudProvidersAccountExporter account_exporter () {
        return this.cloud_provider_account;
    }


    /***********************************************************
    ***********************************************************/
    public GMenuModel menu_model () {

        GLib.Menu section;
        GLib.MenuItem item;
        string item_label;

        this.main_menu = g_menu_new ();

        section = g_menu_new ();
        item = menu_item_new (_("Open website"), "cloudprovider.openwebsite");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        GLib.Object.clear (section);

        this.recent_menu = g_menu_new ();
        item = menu_item_new (_("No recently changed files"), null);
        g_menu_append_item (this.recent_menu, item);
        GLib.Object.clear (item);

        section = g_menu_new ();
        item = menu_item_new_submenu (_("Recently changed"), G_MENU_MODEL (this.recent_menu));
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        GLib.Object.clear (section);

        section = g_menu_new ();
        item = menu_item_new (_("Pause synchronization"), "cloudprovider.pause");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        GLib.Object.clear (section);

        section = g_menu_new ();
        item = menu_item_new (_("Help"), "cloudprovider.openhelp");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        item = menu_item_new (_("Settings"), "cloudprovider.opensettings");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        item = menu_item_new (_("Log out"), "cloudprovider.log_out");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        item = menu_item_new (_("Quit sync client"), "cloudprovider.quit");
        g_menu_append_item (section, item);
        GLib.Object.clear (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        GLib.Object.clear (section);

        return G_MENU_MODEL (this.main_menu);
    }




    /***********************************************************
    ***********************************************************/
    public void update_status_text (string status_text) {
        string status = "%1 - %2".printf (AccountState.state_string (this.folder_connection.account_state.state), status_text);
        cloud_providers_account_exporter_status_details (this.cloud_provider_account, status.to_utf8 ());
    }


    /***********************************************************
    ***********************************************************/
    public void update_pause_status () {
        if (this.paused) {
            update_status_text (_("Sync paused"));
            cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_ERROR);
        } else {
            update_status_text (_("Syncing"));
            cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_SYNCING);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_started () {
        cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_SYNCING);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_finished (SyncResult result) {
        if (result.status () == result.Success || result.status () == result.Problem) {
            cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_IDLE);
            update_status_text (result.status_string);
            return;
        }
        cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_ERROR);
        update_status_text (result.status_string);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_progress (string folder_connection, LibSync.ProgressInfo progress) {
        // Only update progress for the current folder_connection
        FolderConnection f = FolderManager.instance.folder_connection (folder_connection);
        if (f != this.folder_connection) {
            return;
        }
        // Build recently changed files list
        if (!progress.last_completed_item == "" && should_show_in_recents_menu (progress.last_completed_item)) {
            string kind_str = Progress.as_result_string (progress.last_completed_item);
            string time_str = GLib.Time.current_time ().to_string ("hh:mm");
            string action_text = _("%1 (%2, %3)").printf (progress.last_completed_item.file, kind_str, time_str);
            if (f) {
                string full_path = f.path + "/" + progress.last_completed_item.file;
                if (new GLib.File (full_path).exists ()) {
                    if (this.recently_changed.length > 5) {
                        this.recently_changed.remove_first ();
                    }
                    this.recently_changed.append (q_make_pair (action_text, full_path));
                } else {
                    this.recently_changed.append (q_make_pair (action_text, ""));
                }
            }

        }

        // Build status details text
        string message;
        if (!progress.current_discovered_remote_folder == "") {
            message =  _("Checking for changes in \"%1\"").printf (progress.current_discovered_remote_folder);
        } else if (progress.total_size () == 0) {
            int64 current_file = progress.current_file ();
            int64 total_file_count = int64.max (progress.total_files (), current_file);
            if (progress.trust_eta ()) {
                message = _("Syncing %1 of %2  (%3 left)")
                        .printf (current_file)
                        .printf (total_file_count)
                        .printf (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1 of %2")
                        .printf (current_file)
                        .printf (total_file_count);
            }
        } else {
            string total_size_str = Utility.octets_to_string (progress.total_size ());
            if (progress.trust_eta ()) {
                message = _("Syncing %1 (%2 left)")
                        .printf (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1")
                        .printf (total_size_str);
            }
        }
        update_status_text (message);

        if (!progress.last_completed_item == ""
                && should_show_in_recents_menu (progress.last_completed_item)) {
            GLib.MenuItem item;
            g_menu_remove_all (G_MENU (this.recent_menu));
            if (this.recently_changed != null) {
                foreach (var item in this.recently_changed) {
                    string label = item.first;
                    string full_path = item.second;
                    menu_item = menu_item_new (label, "cloudprovider.showfile");
                    g_menu_item_action_and_target_value (menu_item, "cloudprovider.showfile", g_variant_new_string (full_path.to_utf8 ()));
                    g_menu_append_item (this.recent_menu, menu_item);
                    GLib.Object.clear (menu_item);
                }
            } else {
                menu_item = menu_item_new (_("No recently changed files"), null);
                g_menu_append_item (this.recent_menu, menu_item);
                GLib.Object.clear (menu_item);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_paused_changed (FolderConnection folder_connection, bool state) {
        //  Q_UNUSED (folder_connection);
        this.paused = state;
        GLib.Action pause = action_group.lookup_action ("pause");
        pause.set_state (GLib.Variant.boolean (state));
        update_pause_status ();
    }


    /***********************************************************
    ***********************************************************/
    private static void activate_action_pause (
        GLib.SimpleAction action,
        GLib.Variant parameter,
        GLib.Pointer user_data
    ) {
        //  Q_UNUSED (parameter);
        var self = (CloudProviderWrapper) user_data;
        GLib.Variant old_state;
        GLib.Variant new_state;

        old_state = action.get_state ();
        new_state = new GLib.Variant.boolean (! (bool)g_variant_get_boolean (old_state));
        self.folder_connection.sync_paused = (bool)g_variant_get_boolean (new_state);
        action.set_state (new_state);
        g_variant_unref (old_state);
    }


    /***********************************************************
    ***********************************************************/
    private static bool should_show_in_recents_menu (LibSync.SyncFileItem item) {
        return !Progress.is_ignored_kind (item.status)
                && item.instruction != CSync.SyncInstructions.EVAL
                && item.instruction != CSync.SyncInstructions.NONE;
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.MenuItem menu_item_new (string label, gchar detailed_action) {
        return g_menu_item_new (label.to_utf8 (), detailed_action);
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.MenuItem menu_item_new_submenu (string label, GMenuModel submenu) {
        return g_menu_item_new_submenu (label.to_utf8 (), submenu);
    }


    /***********************************************************
    ***********************************************************/
    private void activate_action_open (GLib.SimpleAction action, GLib.Variant parameter, gpointer user_data) {
        //  Q_UNUSED (parameter);
        string name = action.get_name ();
        var self = (CloudProviderWrapper)user_data;
        var gui = (OwncloudGui)self.parent ().parent ();

        if (name == "openhelp") {
            gui.on_signal_help ();
        }

        if (name == "opensettings") {
            gui.on_signal_show_settings ();
        }

        if (name == "openwebsite") {
            GLib.DesktopServices.open_url (self.folder_connection.account_state.account.url);
        }

        if (name == "openfolder") {
            show_in_file_manager (self.folder_connection.clean_path);
        }

        if (name == "showfile") {
            gchar path = g_variant_get_string (parameter, null);
            g_print ("showfile => %s\n", path);
            show_in_file_manager (path);
        }

        if (name == "log_out") {
            self.folder_connection.account_state.sign_out_by_ui ();
        }

        if (name == "quit") {
            this.quit ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private static void activate_action_open_recent_file (GLib.SimpleAction action, GLib.Variant parameter, gpointer user_data) {
        //  Q_UNUSED (action);
        //  Q_UNUSED (parameter);
        var self = (CloudProviderWrapper)user_data;
        GLib.DesktopServices.open_url (self.folder_connection.account_state.account.url);
    }

} // class CloudProviderWrapper

} // namespace Ui
} // namespace Occ
