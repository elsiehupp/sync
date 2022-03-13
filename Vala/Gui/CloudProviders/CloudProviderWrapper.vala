/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Julius Härtl <jus@bitgrid.net>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <cloudprovidersaccountexporter.h>
//  #include <cloudprovidersproviderexporter.h>
//  #include <account.h
//  #include <folder.h>
//  #include <accountstate.h>
//  #include <QDesktopServices>

namespace Occ {
namespace Ui {

class CloudProviderWrapper : GLib.Object {

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

    GSimpleActionGroup action_group = null;

    /***********************************************************
    ***********************************************************/
    private Folder folder;
    private CloudProvidersProviderExporter cloud_provider;
    private CloudProvidersAccountExporter cloud_provider_account;
    private GLib.List<QPair<string, string>> recently_changed;
    private bool paused;
    private GMenu main_menu = null;
    private GMenu recent_menu = null;

    /***********************************************************
    ***********************************************************/
    public CloudProviderWrapper (GLib.Object parent = new GLib.Object (), Folder folder = null, int folder_identifier = 0, CloudProvidersProviderExporter* cloudprovider = null) {
        base (parent);
        this.folder = folder;
        GMenuModel model;
        GActionGroup action_group;
        string account_name = string ("Folder/%1").arg (folder_identifier);

        this.cloud_provider = CLOUD_PROVIDERS_PROVIDER_EXPORTER (cloudprovider);
        this.cloud_provider_account = cloud_providers_account_exporter_new (this.cloud_provider, account_name.to_utf8 ().data ());

        cloud_providers_account_exporter_name (this.cloud_provider_account, folder.short_gui_local_path ().to_utf8 ().data ());
        cloud_providers_account_exporter_icon (this.cloud_provider_account, g_icon_new_for_string (APPLICATION_ICON_NAME, null));
        cloud_providers_account_exporter_path (this.cloud_provider_account, folder.clean_path ().to_utf8 ().data ());
        cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_IDLE);
        model = menu_model ();
        cloud_providers_account_exporter_menu_model (this.cloud_provider_account, model);
        action_group = action_group ();
        cloud_providers_account_exporter_action_group (this.cloud_provider_account, action_group);

        connect (
            ProgressDispatcher.instance (),
            signal_progress_info (string, ProgressInfo),
            this,
            on_signal_update_progress (string, ProgressInfo)
        );
        connect (
            this.folder,
            signal_sync_started (),
            this,
            on_signal_sync_started ()
        );
        connect (
            this.folder,
            signal_sync_finished (SyncResult),
            this,
            on_signal_sync_finished (SyncResult)
        );
        connect (
            this.folder,
            signal_sync_paused_changed (Folder, bool),
            this,
            on_signal_sync_paused_changed (Folder, bool)
        );

        this.paused = this.folder.sync_paused ();
        update_pause_status ();
        g_clear_object (model);
        g_clear_object (action_group);
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
    public Folder folder () {
        return this.folder;
    }


    /***********************************************************
    ***********************************************************/
    public GMenuModel menu_model () {

        GMenu section;
        GMenuItem item;
        string item_label;

        this.main_menu = g_menu_new ();

        section = g_menu_new ();
        item = menu_item_new (_("Open website"), "cloudprovider.openwebsite");
        g_menu_append_item (section, item);
        g_clear_object (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        g_clear_object (section);

        this.recent_menu = g_menu_new ();
        item = menu_item_new (_("No recently changed files"), null);
        g_menu_append_item (this.recent_menu, item);
        g_clear_object (item);

        section = g_menu_new ();
        item = menu_item_new_submenu (_("Recently changed"), G_MENU_MODEL (this.recent_menu));
        g_menu_append_item (section, item);
        g_clear_object (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        g_clear_object (section);

        section = g_menu_new ();
        item = menu_item_new (_("Pause synchronization"), "cloudprovider.pause");
        g_menu_append_item (section, item);
        g_clear_object (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        g_clear_object (section);

        section = g_menu_new ();
        item = menu_item_new (_("Help"), "cloudprovider.openhelp");
        g_menu_append_item (section, item);
        g_clear_object (item);
        item = menu_item_new (_("Settings"), "cloudprovider.opensettings");
        g_menu_append_item (section, item);
        g_clear_object (item);
        item = menu_item_new (_("Log out"), "cloudprovider.log_out");
        g_menu_append_item (section, item);
        g_clear_object (item);
        item = menu_item_new (_("Quit sync client"), "cloudprovider.quit");
        g_menu_append_item (section, item);
        g_clear_object (item);
        g_menu_append_section (this.main_menu, null, G_MENU_MODEL (section));
        g_clear_object (section);

        return G_MENU_MODEL (this.main_menu);
    }


    /***********************************************************
    ***********************************************************/
    public GActionGroup action_group () {
        g_clear_object (action_group);
        action_group = g_simple_action_group_new ();
        g_action_map_add_action_entries (G_ACTION_MAP (action_group), actions, G_N_ELEMENTS (actions), this);
        bool state = this.folder.sync_paused ();
        GAction pause = g_action_map_lookup_action (G_ACTION_MAP (action_group), "pause");
        g_simple_action_state (G_SIMPLE_ACTION (pause), g_variant_new_boolean (state));
        return G_ACTION_GROUP (g_object_ref (action_group));
    }


    /***********************************************************
    ***********************************************************/
    public void update_status_text (string status_text) {
        string status = string ("%1 - %2").arg (this.folder.account_state ().state_string (this.folder.account_state ().state ()), status_text);
        cloud_providers_account_exporter_status_details (this.cloud_provider_account, status.to_utf8 ().data ());
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
            update_status_text (result.status_string ());
            return;
        }
        cloud_providers_account_exporter_status (this.cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_ERROR);
        update_status_text (result.status_string ());
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_progress (string folder, ProgressInfo progress) {
        // Only update progress for the current folder
        Folder f = FolderMan.instance ().folder (folder);
        if (f != this.folder)
            return;

        // Build recently changed files list
        if (!progress.last_completed_item.is_empty () && should_show_in_recents_menu (progress.last_completed_item)) {
            string kind_str = Progress.as_result_string (progress.last_completed_item);
            string time_str = QTime.current_time ().to_string ("hh:mm");
            string action_text = _("%1 (%2, %3)").arg (progress.last_completed_item.file, kind_str, time_str);
            if (f) {
                string full_path = f.path () + '/' + progress.last_completed_item.file;
                if (GLib.File (full_path).exists ()) {
                    if (this.recently_changed.length () > 5)
                        this.recently_changed.remove_first ();
                    this.recently_changed.append (q_make_pair (action_text, full_path));
                } else {
                    this.recently_changed.append (q_make_pair (action_text, string ("")));
                }
            }

        }

        // Build status details text
        string message;
        if (!progress.current_discovered_remote_folder.is_empty ()) {
            message =  _("Checking for changes in \"%1\"").arg (progress.current_discovered_remote_folder);
        } else if (progress.total_size () == 0) {
            int64 current_file = progress.current_file ();
            int64 total_file_count = q_max (progress.total_files (), current_file);
            if (progress.trust_eta ()) {
                message = _("Syncing %1 of %2  (%3 left)")
                        .arg (current_file)
                        .arg (total_file_count)
                        .arg (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1 of %2")
                        .arg (current_file)
                        .arg (total_file_count);
            }
        } else {
            string total_size_str = Utility.octets_to_string (progress.total_size ());
            if (progress.trust_eta ()) {
                message = _("Syncing %1 (%2 left)")
                        .arg (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1")
                        .arg (total_size_str);
            }
        }
        update_status_text (message);

        if (!progress.last_completed_item.is_empty ()
                && should_show_in_recents_menu (progress.last_completed_item)) {
            GMenuItem* item;
            g_menu_remove_all (G_MENU (this.recent_menu));
            if (!this.recently_changed.is_empty ()) {
                foreach (var item in this.recently_changed) {
                    string label = item.first;
                    string full_path = item.second;
                    menu_item = menu_item_new (label, "cloudprovider.showfile");
                    g_menu_item_action_and_target_value (menu_item, "cloudprovider.showfile", g_variant_new_string (full_path.to_utf8 ().data ()));
                    g_menu_append_item (this.recent_menu, menu_item);
                    g_clear_object (menu_item);
                }
            } else {
                menu_item = menu_item_new (_("No recently changed files"), null);
                g_menu_append_item (this.recent_menu, menu_item);
                g_clear_object (menu_item);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_paused_changed (Folder folder, bool state) {
        //  Q_UNUSED (folder);
        this.paused = state;
        GAction pause = g_action_map_lookup_action (G_ACTION_MAP (action_group), "pause");
        g_simple_action_state (G_SIMPLE_ACTION (pause), g_variant_new_boolean (state));
        update_pause_status ();
    }


    /***********************************************************
    ***********************************************************/
    private static void activate_action_pause (
        GSimpleAction action,
        GVariant parameter,
        Gpointer user_data
    ) {
        //  Q_UNUSED (parameter);
        var self = (CloudProviderWrapper) user_data;
        GVariant old_state;
        GVariant new_state;

        old_state = g_action_get_state (G_ACTION (action));
        new_state = g_variant_new_boolean (! (bool)g_variant_get_boolean (old_state));
        self.folder ().sync_paused ( (bool)g_variant_get_boolean (new_state));
        g_simple_action_state (action, new_state);
        g_variant_unref (old_state);
    }


    /***********************************************************
    ***********************************************************/
    private static bool should_show_in_recents_menu (SyncFileItem item) {
        return !Progress.is_ignored_kind (item.status)
                && item.instruction != CSYNC_INSTRUCTION_EVAL
                && item.instruction != CSYNC_INSTRUCTION_NONE;
    }


    /***********************************************************
    ***********************************************************/
    private static GMenuItem menu_item_new (string label, gchar detailed_action) {
        return g_menu_item_new (label.to_utf8 ().data (), detailed_action);
    }


    /***********************************************************
    ***********************************************************/
    private static GMenuItem menu_item_new_submenu (string label, GMenuModel submenu) {
        return g_menu_item_new_submenu (label.to_utf8 ().data (), submenu);
    }


    /***********************************************************
    ***********************************************************/
    private static void activate_action_open (GSimpleAction action, GVariant parameter, gpointer user_data) {
        //  Q_UNUSED (parameter);
        const gchar name = g_action_get_name (G_ACTION (action));
        var self = static_cast<CloudProviderWrapper> (user_data);
        var gui = dynamic_cast<OwncloudGui> (self.parent ().parent ());

        if (g_str_equal (name, "openhelp")) {
            gui.on_signal_help ();
        }

        if (g_str_equal (name, "opensettings")) {
            gui.on_signal_show_settings ();
        }

        if (g_str_equal (name, "openwebsite")) {
            QDesktopServices.open_url (self.folder ().account_state ().account ().url ());
        }

        if (g_str_equal (name, "openfolder")) {
            show_in_file_manager (self.folder ().clean_path ());
        }

        if (g_str_equal (name, "showfile")) {
            const gchar path = g_variant_get_string (parameter, null);
            g_print ("showfile => %s\n", path);
            show_in_file_manager (string (path));
        }

        if (g_str_equal (name, "log_out")) {
            self.folder ().account_state ().sign_out_by_ui ();
        }

        if (g_str_equal (name, "quit")) {
            Gtk.Application.quit ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private static void activate_action_open_recent_file (GSimpleAction action, GVariant parameter, gpointer user_data) {
        //  Q_UNUSED (action);
        //  Q_UNUSED (parameter);
        var self = static_cast<CloudProviderWrapper> (user_data);
        QDesktopServices.open_url (self.folder ().account_state ().account ().url ());
    }

} // class CloudProviderWrapper

} // namespace Ui
} // namespace Occ
