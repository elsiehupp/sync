/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Julius Härtl <jus@bitgrid.net>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <cloudprovidersaccountexporter.h>
// #include <cloudprovidersproviderexporter.h>

// #include <account.h>
// #include <folder.h>
// #include <accountstate.h>
// #include <QDesktopServices>

using namespace Occ;

GSimple_action_group action_group = nullptr;


/* Forward declaration required since gio header files interfere with GLib.Object headers */
struct _Cloud_providers_provider_exporter;
using CloudProvidersProviderExporter = _Cloud_providers_provider_exporter;
struct _Cloud_providers_account_exporter;
using Cloud_providers_account_exporter = _Cloud_providers_account_exporter;
struct _GMenu_model;
using GMenu_model = _GMenu_model;
struct _GMenu;
using GMenu = _GMenu;
struct _GAction_group;
using GAction_group = _GAction_group;
using gchar = char;
using gpointer = void*;

using namespace Occ;

class CloudProviderWrapper : GLib.Object {

    public CloudProviderWrapper (GLib.Object parent = nullptr, Folder folder = nullptr, int folder_id = 0, CloudProvidersProviderExporter* cloudprovider = nullptr);
    ~CloudProviderWrapper () override;
    public Cloud_providers_account_exporter* account_exporter ();


    public Folder* folder ();


    public GMenu_model* get_menu_model ();


    public GAction_group* get_action_group ();


    public void update_status_text (string status_text);


    public void update_pause_status ();


    public void on_sync_started ();


    public void on_sync_finished (SyncResult &);


    public void on_update_progress (string folder, ProgressInfo &progress);


    public void on_sync_paused_changed (Folder*, bool);


    private Folder _folder;
    private CloudProvidersProviderExporter _cloud_provider;
    private Cloud_providers_account_exporter _cloud_provider_account;
    private GLib.List<QPair<string, string>> _recently_changed;
    private bool _paused;
    private GMenu* _main_menu = nullptr;
    private GMenu* _recent_menu = nullptr;
};






CloudProviderWrapper.CloudProviderWrapper (GLib.Object parent, Folder folder, int folder_id, CloudProvidersProviderExporter* cloudprovider) : GLib.Object (parent)
  , _folder (folder) {
    GMenu_model model;
    GAction_group action_group;
    string account_name = string ("Folder/%1").arg (folder_id);

    _cloud_provider = CLOUD_PROVIDERS_PROVIDER_EXPORTER (cloudprovider);
    _cloud_provider_account = cloud_providers_account_exporter_new (_cloud_provider, account_name.to_utf8 ().data ());

    cloud_providers_account_exporter_set_name (_cloud_provider_account, folder.short_gui_local_path ().to_utf8 ().data ());
    cloud_providers_account_exporter_set_icon (_cloud_provider_account, g_icon_new_for_string (APPLICATION_ICON_NAME, nullptr));
    cloud_providers_account_exporter_set_path (_cloud_provider_account, folder.clean_path ().to_utf8 ().data ());
    cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_IDLE);
    model = get_menu_model ();
    cloud_providers_account_exporter_set_menu_model (_cloud_provider_account, model);
    action_group = get_action_group ();
    cloud_providers_account_exporter_set_action_group (_cloud_provider_account, action_group);

    connect (Progress_dispatcher.instance (), SIGNAL (progress_info (string, ProgressInfo)), this, SLOT (on_update_progress (string, ProgressInfo)));
    connect (_folder, SIGNAL (sync_started ()), this, SLOT (on_sync_started ()));
    connect (_folder, SIGNAL (sync_finished (SyncResult)), this, SLOT (on_sync_finished (SyncResult)));
    connect (_folder, SIGNAL (sync_paused_changed (Folder*,bool)), this, SLOT (on_sync_paused_changed (Folder*, bool)));

    _paused = _folder.sync_paused ();
    update_pause_status ();
    g_clear_object (&model);
    g_clear_object (&action_group);
}

CloudProviderWrapper.~CloudProviderWrapper () {
    g_object_unref (_cloud_provider_account);
    g_object_unref (_main_menu);
    g_object_unref (action_group);
    g_object_unref (_recent_menu);
}

Cloud_providers_account_exporter* CloudProviderWrapper.account_exporter () {
    return _cloud_provider_account;
}

static bool should_show_in_recents_menu (SyncFileItem &item) {
    return !Progress.is_ignored_kind (item._status)
            && item._instruction != CSYNC_INSTRUCTION_EVAL
            && item._instruction != CSYNC_INSTRUCTION_NONE;
}

static GMenu_item menu_item_new (string label, gchar detailed_action) {
    return g_menu_item_new (label.to_utf8 ().data (), detailed_action);
}

static GMenu_item menu_item_new_submenu (string label, GMenu_model submenu) {
    return g_menu_item_new_submenu (label.to_utf8 ().data (), submenu);
}

void CloudProviderWrapper.on_update_progress (string folder, ProgressInfo &progress) {
    // Only update progress for the current folder
    Folder f = FolderMan.instance ().folder (folder);
    if (f != _folder)
        return;

    // Build recently changed files list
    if (!progress._last_completed_item.is_empty () && should_show_in_recents_menu (progress._last_completed_item)) {
        string kind_str = Progress.as_result_string (progress._last_completed_item);
        string time_str = QTime.current_time ().to_string ("hh:mm");
        string action_text = tr ("%1 (%2, %3)").arg (progress._last_completed_item._file, kind_str, time_str);
        if (f) {
            string full_path = f.path () + '/' + progress._last_completed_item._file;
            if (QFile (full_path).exists ()) {
                if (_recently_changed.length () > 5)
                    _recently_changed.remove_first ();
                _recently_changed.append (q_make_pair (action_text, full_path));
            } else {
                _recently_changed.append (q_make_pair (action_text, string ("")));
            }
        }

    }

    // Build status details text
    string msg;
    if (!progress._current_discovered_remote_folder.is_empty ()) {
        msg =  tr ("Checking for changes in \"%1\"").arg (progress._current_discovered_remote_folder);
    } else if (progress.total_size () == 0) {
        int64 current_file = progress.current_file ();
        int64 total_file_count = q_max (progress.total_files (), current_file);
        if (progress.trust_eta ()) {
            msg = tr ("Syncing %1 of %2  (%3 left)")
                    .arg (current_file)
                    .arg (total_file_count)
                    .arg (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = tr ("Syncing %1 of %2")
                    .arg (current_file)
                    .arg (total_file_count);
        }
    } else {
        string total_size_str = Utility.octets_to_string (progress.total_size ());
        if (progress.trust_eta ()) {
            msg = tr ("Syncing %1 (%2 left)")
                    .arg (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = tr ("Syncing %1")
                    .arg (total_size_str);
        }
    }
    update_status_text (msg);

    if (!progress._last_completed_item.is_empty ()
            && should_show_in_recents_menu (progress._last_completed_item)) {
        GMenu_item* item;
        g_menu_remove_all (G_MENU (_recent_menu));
        if (!_recently_changed.is_empty ()) {
            GLib.List<QPair<string, string>>.iterator i;
            for (i = _recently_changed.begin (); i != _recently_changed.end (); i++) {
                string label = i.first;
                string full_path = i.second;
                item = menu_item_new (label, "cloudprovider.showfile");
                g_menu_item_set_action_and_target_value (item, "cloudprovider.showfile", g_variant_new_string (full_path.to_utf8 ().data ()));
                g_menu_append_item (_recent_menu, item);
                g_clear_object (&item);
            }
        } else {
            item = menu_item_new (tr ("No recently changed files"), nullptr);
            g_menu_append_item (_recent_menu, item);
            g_clear_object (&item);
        }
    }
}

void CloudProviderWrapper.update_status_text (string status_text) {
    string status = string ("%1 - %2").arg (_folder.account_state ().state_string (_folder.account_state ().state ()), status_text);
    cloud_providers_account_exporter_set_status_details (_cloud_provider_account, status.to_utf8 ().data ());
}

void CloudProviderWrapper.update_pause_status () {
    if (_paused) {
        update_status_text (tr ("Sync paused"));
        cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_ERROR);
    } else {
        update_status_text (tr ("Syncing"));
        cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_SYNCING);
    }
}

Folder* CloudProviderWrapper.folder () {
    return _folder;
}

void CloudProviderWrapper.on_sync_started () {
    cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_SYNCING);
}

void CloudProviderWrapper.on_sync_finished (SyncResult &result) {
    if (result.status () == result.Success || result.status () == result.Problem) {
        cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_IDLE);
        update_status_text (result.status_string ());
        return;
    }
    cloud_providers_account_exporter_set_status (_cloud_provider_account, CLOUD_PROVIDERS_ACCOUNT_STATUS_ERROR);
    update_status_text (result.status_string ());
}

GMenu_model* CloudProviderWrapper.get_menu_model () {

    GMenu* section;
    GMenu_item* item;
    string item_label;

    _main_menu = g_menu_new ();

    section = g_menu_new ();
    item = menu_item_new (tr ("Open website"), "cloudprovider.openwebsite");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    g_menu_append_section (_main_menu, nullptr, G_MENU_MODEL (section));
    g_clear_object (&section);

    _recent_menu = g_menu_new ();
    item = menu_item_new (tr ("No recently changed files"), nullptr);
    g_menu_append_item (_recent_menu, item);
    g_clear_object (&item);

    section = g_menu_new ();
    item = menu_item_new_submenu (tr ("Recently changed"), G_MENU_MODEL (_recent_menu));
    g_menu_append_item (section, item);
    g_clear_object (&item);
    g_menu_append_section (_main_menu, nullptr, G_MENU_MODEL (section));
    g_clear_object (&section);

    section = g_menu_new ();
    item = menu_item_new (tr ("Pause synchronization"), "cloudprovider.pause");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    g_menu_append_section (_main_menu, nullptr, G_MENU_MODEL (section));
    g_clear_object (&section);

    section = g_menu_new ();
    item = menu_item_new (tr ("Help"), "cloudprovider.openhelp");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    item = menu_item_new (tr ("Settings"), "cloudprovider.opensettings");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    item = menu_item_new (tr ("Log out"), "cloudprovider.logout");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    item = menu_item_new (tr ("Quit sync client"), "cloudprovider.quit");
    g_menu_append_item (section, item);
    g_clear_object (&item);
    g_menu_append_section (_main_menu, nullptr, G_MENU_MODEL (section));
    g_clear_object (&section);

    return G_MENU_MODEL (_main_menu);
}

static void
activate_action_open (GSimple_action action, GVariant parameter, gpointer user_data) {
    Q_UNUSED (parameter);
    const gchar name = g_action_get_name (G_ACTION (action));
    var self = static_cast<CloudProviderWrapper> (user_data);
    var gui = dynamic_cast<OwncloudGui> (self.parent ().parent ());

    if (g_str_equal (name, "openhelp")) {
        gui.on_help ();
    }

    if (g_str_equal (name, "opensettings")) {
        gui.on_show_settings ();
    }

    if (g_str_equal (name, "openwebsite")) {
        QDesktopServices.open_url (self.folder ().account_state ().account ().url ());
    }

    if (g_str_equal (name, "openfolder")) {
        show_in_file_manager (self.folder ().clean_path ());
    }

    if (g_str_equal (name, "showfile")) {
        const gchar path = g_variant_get_string (parameter, nullptr);
        g_print ("showfile => %s\n", path);
        show_in_file_manager (string (path));
    }

    if (g_str_equal (name, "logout")) {
        self.folder ().account_state ().sign_out_by_ui ();
    }

    if (g_str_equal (name, "quit")) {
        q_app.quit ();
    }
}

static void
activate_action_openrecentfile (GSimple_action action, GVariant parameter, gpointer user_data) {
    Q_UNUSED (action);
    Q_UNUSED (parameter);
    var self = static_cast<CloudProviderWrapper> (user_data);
    QDesktopServices.open_url (self.folder ().account_state ().account ().url ());
}

static void
activate_action_pause (GSimple_action action,
                       GVariant      *parameter,
                       gpointer       user_data) {
    Q_UNUSED (parameter);
    var self = static_cast<CloudProviderWrapper> (user_data);
    GVariant old_state, *new_state;

    old_state = g_action_get_state (G_ACTION (action));
    new_state = g_variant_new_boolean (! (bool)g_variant_get_boolean (old_state));
    self.folder ().set_sync_paused ( (bool)g_variant_get_boolean (new_state));
    g_simple_action_set_state (action, new_state);
    g_variant_unref (old_state);
}

static GAction_entry actions[] = {
    {
        "openwebsite",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "quit",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "logout",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "openfolder",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "showfile",
        activate_action_open,
        "s",
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "openhelp",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "opensettings",
        activate_action_open,
        nullptr,
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "openrecentfile",
        activate_action_openrecentfile,
        "s",
        nullptr,
        nullptr,
        {0,0,0}
    },
    {
        "pause",
        activate_action_pause,
        nullptr,
        "false",
        nullptr,
        {0,0,0}
    }
};

GAction_group* CloudProviderWrapper.get_action_group () {
    g_clear_object (&action_group);
    action_group = g_simple_action_group_new ();
    g_action_map_add_action_entries (G_ACTION_MAP (action_group), actions, G_N_ELEMENTS (actions), this);
    bool state = _folder.sync_paused ();
    GAction pause = g_action_map_lookup_action (G_ACTION_MAP (action_group), "pause");
    g_simple_action_set_state (G_SIMPLE_ACTION (pause), g_variant_new_boolean (state));
    return G_ACTION_GROUP (g_object_ref (action_group));
}

void CloudProviderWrapper.on_sync_paused_changed (Folder folder, bool state) {
    Q_UNUSED (folder);
    _paused = state;
    GAction pause = g_action_map_lookup_action (G_ACTION_MAP (action_group), "pause");
    g_simple_action_set_state (G_SIMPLE_ACTION (pause), g_variant_new_boolean (state));
    update_pause_status ();
}
