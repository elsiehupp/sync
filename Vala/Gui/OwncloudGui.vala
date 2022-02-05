/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

#ifdef WITH_LIBCLOUDPROVIDERS
#endif

//  #include <QQml_application_engine>
//  #include <QDesktopServices>
//  #include <QDir>
//  #include <QMessageBox>
//  #include <QSignal_mapper>
//  #include_LIBCLOUDPROVIDERS
//  #include <Qt_d_bus/QDBus_connection>
//  #include <Qt_d_bus/QDBus_interface>
#endif

//  #include <QQmlEngine>
//  #include <QQml_component>
//  #include <QQml_application_engine>
//  #include <QQuick_item>
//  #include <QQml_context>
//  #include
//  #include <QPointer
//  #include <QActio
//  #include <QMenu>
//  #include <QSize>
//  #include <QTimer>
#ifdef WITH_LIBCLOUDPROVIDERS
//  #include <QDBus_connection>
#endif

namespace Occ {

enum Share_dialog_start_page {
    Users_and_groups,
    Public_links,
}

/***********************************************************
@brief The OwncloudGui class
@ingroup gui
***********************************************************/
class OwncloudGui : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public OwncloudGui (Application parent = null);

    /***********************************************************
    ***********************************************************/
    public bool check_account_exists (bool open_settings);

    /***********************************************************
    ***********************************************************/
    public static void raise_dialog (Gtk.Widget raise_widget);

    /***********************************************************
    ***********************************************************/
    public static QSize settings_dialog_size () {
        return {800, 500};
    }


    /***********************************************************
    ***********************************************************/
    public void setup_overlay_icons ();
#ifdef WITH_LIBCLOUDPROVIDERS
    public void setup_cloud_providers ();


    /***********************************************************
    ***********************************************************/
    public bool cloud_provider_api_available ();
#endif
    public void create_tray ();

    /***********************************************************
    ***********************************************************/
    public void hide_and_show_tray ();

signals:
    void setup_proxy ();
    void on_server_error (int code, string message);
    void is_showing_settings_dialog ();


    /***********************************************************
    ***********************************************************/
    public void on_compute_overall_sync_status ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_show_optional_tray_message (string 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_update_progress (string_value

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_folders_chang

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_show_sync_protocol ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_sync_state_change (Fo

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_toggle_log_browser ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void on_open_settings_dialog ();


    public void on_open_main_dialog ();


    public void on_settings_dialog_activated ();


    public void on_help ();


    public void on_open_path (string path);


    public void on_account_state_changed ();


    public void on_tray_message_if_server_unsupported (Account account);


    /***********************************************************
    Open a share dialog for a file or folder.

    share_path is the full remote path to the item,
    local_path is the absolute local path to it (so not relative
    to the folder).
    ***********************************************************/
    void on_show_share_dialog (string share_path, string local_path, Share_dialog_start_page start_page);

    void on_remove_destroyed_share_dialogs ();

    void on_new_account_wizard ();


    /***********************************************************
    ***********************************************************/
    private void on_login ();
    private void on_logout ();


    /***********************************************************
    ***********************************************************/
    private QPointer<Systray> this.tray;
    private QPointer<SettingsDialog> this.settings_dialog;
    private QPointer<Log_browser> this.log_browser;

#ifdef WITH_LIBCLOUDPROVIDERS
    private QDBus_connection this.bus;
#endif

    /***********************************************************
    ***********************************************************/
    private GLib.HashMap<string, QPointer<Share_dialog>> this.share_dialogs;

    /***********************************************************
    ***********************************************************/
    private QAction this.action_new_account_wizard;
    private QAction this.action_settings;
    private QAction this.action_estimate;

    /***********************************************************
    ***********************************************************/
    private GLib.List<QAction> this.recent_items_actions;
    private Application this.app;
}



const char property_account_c[] = "oc_account";

OwncloudGui.OwncloudGui (Application parent)
    : GLib.Object (parent)
    this.tray (null)
    this.settings_dialog (null)
    this.log_browser (null)
#ifdef WITH_LIBCLOUDPROVIDERS
    this.bus (QDBus_connection.session_bus ())
#endif
    this.app (parent) {
    this.tray = Systray.instance ();
    this.tray.set_tray_engine (new QQml_application_engine (this));
    // for the beginning, set the offline icon until the account was verified
    this.tray.set_icon (Theme.instance ().folder_offline_icon (/*systray?*/ true));

    this.tray.show ();

    connect (this.tray.data (), &QSystemTrayIcon.activated,
        this, &OwncloudGui.on_tray_clicked);

    connect (this.tray.data (), &Systray.open_help,
        this, &OwncloudGui.on_help);

    connect (this.tray.data (), &Systray.open_account_wizard,
        this, &OwncloudGui.on_new_account_wizard);

    connect (this.tray.data (), &Systray.open_main_dialog,
        this, &OwncloudGui.on_open_main_dialog);

    connect (this.tray.data (), &Systray.open_settings,
        this, &OwncloudGui.on_show_settings);

    connect (this.tray.data (), &Systray.shutdown,
        this, &OwncloudGui.on_shutdown);

    connect (this.tray.data (), &Systray.open_share_dialog,
        this, [=] (string share_path, string local_path) {
                on_show_share_dialog (share_path, local_path, Share_dialog_start_page.Users_and_groups);
            });

    ProgressDispatcher pd = ProgressDispatcher.instance ();
    connect (pd, &ProgressDispatcher.progress_info, this,
        &OwncloudGui.on_update_progress);

    FolderMan folder_man = FolderMan.instance ();
    connect (folder_man, &FolderMan.folder_sync_state_change,
        this, &OwncloudGui.on_sync_state_change);

    connect (Logger.instance (), &Logger.gui_log,
        this, &OwncloudGui.on_show_tray_message);
    connect (Logger.instance (), &Logger.optional_gui_log,
        this, &OwncloudGui.on_show_optional_tray_message);
    connect (Logger.instance (), &Logger.gui_message,
        this, &OwncloudGui.on_show_gui_message);
}

void OwncloudGui.create_tray () {
    this.tray.create ();
}

#ifdef WITH_LIBCLOUDPROVIDERS
void OwncloudGui.setup_cloud_providers () {
    new CloudProviderManager (this);
}

bool OwncloudGui.cloud_provider_api_available () {
    if (!this.bus.is_connected ()) {
        return false;
    }
    QDBus_interface dbus_iface ("org.freedesktop.CloudProviderManager", "/org/freedesktop/CloudProviderManager",
                              "org.freedesktop.Cloud_provider.Manager1", this.bus);

    if (!dbus_iface.is_valid ()) {
        GLib.Info (lc_application) << "DBus interface unavailable";
        return false;
    }
    return true;
}
#endif

// This should rather be in application.... or rather in ConfigFile?
void OwncloudGui.on_open_settings_dialog () {
    // if account is set up, on_start the configuration wizard.
    if (!AccountManager.instance ().accounts ().is_empty ()) {
        if (this.settings_dialog.is_null () || QApplication.active_window () != this.settings_dialog) {
            on_show_settings ();
        } else {
            this.settings_dialog.close ();
        }
    } else {
        GLib.Info (lc_application) << "No configured folders yet, starting setup wizard";
        on_new_account_wizard ();
    }
}

void OwncloudGui.on_open_main_dialog () {
    if (!this.tray.is_open ()) {
        this.tray.show_window ();
    }
}

void OwncloudGui.on_tray_clicked (QSystemTrayIcon.Activation_reason reason) {
    if (reason == QSystemTrayIcon.Trigger) {
        if (OwncloudSetupWizard.bring_wizard_to_front_if_visible ()) {
            // brought wizard to front
        } else if (this.share_dialogs.size () > 0) {
            // Share dialog (s) be hidden by other apps, bring them back
            Q_FOREACH (QPointer<Share_dialog> share_dialog, this.share_dialogs) {
                //  Q_ASSERT (share_dialog.data ());
                raise_dialog (share_dialog);
            }
        } else if (this.tray.is_open ()) {
            this.tray.hide_window ();
        } else {
            if (AccountManager.instance ().accounts ().is_empty ()) {
                this.on_open_settings_dialog ();
            } else {
                this.tray.show_window ();
            }

        }
    }
    // FIXME : Also make sure that any var updater dialogue https://github.com/owncloud/client/issues/5613
    // or SSL error dialog also comes to front.
}

void OwncloudGui.on_sync_state_change (Folder folder) {
    on_compute_overall_sync_status ();

    if (!folder) {
        return; // Valid, just a general GUI redraw was needed.
    }

    var result = folder.sync_result ();

    GLib.Info (lc_application) << "Sync state changed for folder " << folder.remote_url ().to_string () << " : " << result.status_string ();

    if (result.status () == SyncResult.Status.SUCCESS
        || result.status () == SyncResult.Status.PROBLEM
        || result.status () == SyncResult.Status.SYNC_ABORT_REQUESTED
        || result.status () == SyncResult.Status.ERROR) {
        Logger.instance ().on_enter_next_log_file ();
    }
}

void OwncloudGui.on_folders_changed () {
    on_compute_overall_sync_status ();
}

void OwncloudGui.on_open_path (string path) {
    show_in_file_manager (path);
}

void OwncloudGui.on_account_state_changed () {
    on_compute_overall_sync_status ();
}

void OwncloudGui.on_tray_message_if_server_unsupported (Account account) {
    if (account.server_version_unsupported ()) {
        on_show_tray_message (
            _("Unsupported Server Version"),
            _("The server on account %1 runs an unsupported version %2. "
               "Using this client with unsupported server versions is untested and "
               "potentially dangerous. Proceed at your own risk.")
                .arg (account.display_name (), account.server_version ()));
    }
}

void OwncloudGui.on_compute_overall_sync_status () {
    bool all_signed_out = true;
    bool all_paused = true;
    bool all_disconnected = true;
    GLib.Vector<AccountStatePtr> problem_accounts;
    var set_status_text = [&] (string text) {
        // FIXME : So this doesn't do anything? Needs to be revisited
        //  Q_UNUSED (text)
        // Don't overwrite the status if we're currently syncing
        if (FolderMan.instance ().is_any_sync_running ())
            return;
        //this.action_status.on_set_text (text);
    };

    foreach (var a, AccountManager.instance ().accounts ()) {
        if (!a.is_signed_out ()) {
            all_signed_out = false;
        }
        if (!a.is_connected ()) {
            problem_accounts.append (a);
        } else {
            all_disconnected = false;
        }
    }
    foreach (Folder f, FolderMan.instance ().map ()) {
        if (!f.sync_paused ()) {
            all_paused = false;
        }
    }

    if (!problem_accounts.empty ()) {
        this.tray.set_icon (Theme.instance ().folder_offline_icon (true));
        if (all_disconnected) {
            set_status_text (_("Disconnected"));
        } else {
            set_status_text (_("Disconnected from some accounts"));
        }
        string[] messages;
        messages.append (_("Disconnected from accounts:"));
        foreach (AccountStatePtr a, problem_accounts) {
            string message = _("Account %1 : %2").arg (a.account ().display_name (), a.state_string (a.state ()));
            if (!a.connection_errors ().empty ()) {
                message += QLatin1String ("\n");
                message += a.connection_errors ().join (QLatin1String ("\n"));
            }
            messages.append (message);
        }
        this.tray.set_tool_tip (messages.join (QLatin1String ("\n\n")));
#endif
        return;
    }

    if (all_signed_out) {
        this.tray.set_icon (Theme.instance ().folder_offline_icon (true));
        this.tray.set_tool_tip (_("Please sign in"));
        set_status_text (_("Signed out"));
        return;
    } else if (all_paused) {
        this.tray.set_icon (Theme.instance ().sync_state_icon (SyncResult.Status.PAUSED, true));
        this.tray.set_tool_tip (_("Account synchronization is disabled"));
        set_status_text (_("Synchronization is paused"));
        return;
    }

    // display the info of the least successful sync (eg. do not just display the result of the latest sync)
    string tray_message;
    FolderMan folder_man = FolderMan.instance ();
    Folder.Map map = folder_man.map ();

    SyncResult.Status overall_status = SyncResult.Status.UNDEFINED;
    bool has_unresolved_conflicts = false;
    FolderMan.tray_overall_status (map.values (), overall_status, has_unresolved_conflicts);

    // If the sync succeeded but there are unresolved conflicts,
    // show the problem icon!
    var icon_status = overall_status;
    if (icon_status == SyncResult.Status.SUCCESS && has_unresolved_conflicts) {
        icon_status = SyncResult.Status.PROBLEM;
    }

    // If we don't get a status for whatever reason, that's a Problem
    if (icon_status == SyncResult.Status.UNDEFINED) {
        icon_status = SyncResult.Status.PROBLEM;
    }

    QIcon status_icon = Theme.instance ().sync_state_icon (icon_status, true);
    this.tray.set_icon (status_icon);

    // create the tray blob message, check if we have an defined state
    if (map.count () > 0) {
        string[] all_status_strings;
        foreach (Folder folder, map.values ()) {
            string folder_message = FolderMan.tray_tooltip_status_string (
                folder.sync_result ().status (),
                folder.sync_result ().has_unresolved_conflicts (),
                folder.sync_paused ());
            all_status_strings += _("Folder %1 : %2").arg (folder.short_gui_local_path (), folder_message);
        }
        tray_message = all_status_strings.join (QLatin1String ("\n"));
#endif
        this.tray.set_tool_tip (tray_message);

        if (overall_status == SyncResult.Status.SUCCESS || overall_status == SyncResult.Status.PROBLEM) {
            if (has_unresolved_conflicts) {
                set_status_text (_("Unresolved conflicts"));
            } else {
                set_status_text (_("Up to date"));
            }
        } else if (overall_status == SyncResult.Status.PAUSED) {
            set_status_text (_("Synchronization is paused"));
        } else {
            set_status_text (_("Error during synchronization"));
        }
    } else {
        this.tray.set_tool_tip (_("There are no sync folders configured."));
        set_status_text (_("No sync folders configured"));
    }
}

void OwncloudGui.hide_and_show_tray () {
    this.tray.hide ();
    this.tray.show ();
}

void OwncloudGui.on_show_tray_message (string title, string msg) {
    if (this.tray)
        this.tray.show_message (title, msg);
    else
        GLib.warn (lc_application) << "Tray not ready : " << msg;
}

void OwncloudGui.on_show_optional_tray_message (string title, string msg) {
    on_show_tray_message (title, msg);
}

/***********************************************************
open the folder with the given Alias
***********************************************************/
void OwncloudGui.on_folder_open_action (string alias) {
    Folder f = FolderMan.instance ().folder (alias);
    if (f) {
        GLib.Info (lc_application) << "opening local url " << f.path ();
        GLib.Uri url = GLib.Uri.from_local_file (f.path ());
        QDesktopServices.open_url (url);
    }
}

void OwncloudGui.on_update_progress (string folder, ProgressInfo progress) {
    //  Q_UNUSED (folder);

    // FIXME : Lots of messages computed for nothing in this method, needs revisiting
    if (progress.status () == ProgressInfo.Status.DISCOVERY) {
#if 0
        if (!progress.current_discovered_remote_folder.is_empty ()) {
            this.action_status.on_set_text (_("Checking for changes in remote \"%1\"")
                                       .arg (progress.current_discovered_remote_folder));
        } else if (!progress.current_discovered_local_folder.is_empty ()) {
            this.action_status.on_set_text (_("Checking for changes in local \"%1\"")
                                       .arg (progress.current_discovered_local_folder));
        }
#endif
    } else if (progress.status () == ProgressInfo.Status.DONE) {
        QTimer.single_shot (2000, this, &OwncloudGui.on_compute_overall_sync_status);
    }
    if (progress.status () != ProgressInfo.Status.PROPAGATION) {
        return;
    }

    if (progress.total_size () == 0) {
        int64 current_file = progress.current_file ();
        int64 total_file_count = q_max (progress.total_files (), current_file);
        string msg;
        if (progress.trust_eta ()) {
            msg = _("Syncing %1 of %2 (%3 left)")
                      .arg (current_file)
                      .arg (total_file_count)
                      .arg (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = _("Syncing %1 of %2")
                      .arg (current_file)
                      .arg (total_file_count);
        }
        //this.action_status.on_set_text (msg);
    } else {
        string total_size_str = Utility.octets_to_string (progress.total_size ());
        string msg;
        if (progress.trust_eta ()) {
            msg = _("Syncing %1 (%2 left)")
                      .arg (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = _("Syncing %1")
                      .arg (total_size_str);
        }
        //this.action_status.on_set_text (msg);
    }

    if (!progress.last_completed_item.is_empty ()) {

        string kind_str = Progress.as_result_string (progress.last_completed_item);
        string time_str = QTime.current_time ().to_string ("hh:mm");
        string action_text = _("%1 (%2, %3)").arg (progress.last_completed_item.file, kind_str, time_str);
        var action = new QAction (action_text, this);
        Folder f = FolderMan.instance ().folder (folder);
        if (f) {
            string full_path = f.path () + '/' + progress.last_completed_item.file;
            if (GLib.File (full_path).exists ()) {
                connect (action, &QAction.triggered, this, [this, full_path] {
                    this.on_open_path (full_path);
                });
            } else {
                action.set_enabled (false);
            }
        }
        if (this.recent_items_actions.length () > 5) {
            this.recent_items_actions.take_first ().delete_later ();
        }
        this.recent_items_actions.append (action);
    }
}

void OwncloudGui.on_login () {
    if (var account = qvariant_cast<AccountStatePtr> (sender ().property (property_account_c))) {
        account.account ().reset_rejected_certificates ();
        account.sign_in ();
    } else {
        var list = AccountManager.instance ().accounts ();
        foreach (var a, list) {
            a.sign_in ();
        }
    }
}

void OwncloudGui.on_logout () {
    var list = AccountManager.instance ().accounts ();
    if (var account = qvariant_cast<AccountStatePtr> (sender ().property (property_account_c))) {
        list.clear ();
        list.append (account);
    }

    foreach (var ai, list) {
        ai.sign_out_by_ui ();
    }
}

void OwncloudGui.on_new_account_wizard () {
    OwncloudSetupWizard.run_wizard (Gtk.Application, SLOT (on_owncloud_wizard_done (int)));
}

void OwncloudGui.on_show_gui_message (string title, string message) {
    var msg_box = new QMessageBox;
    msg_box.set_window_flags (msg_box.window_flags () | Qt.Window_stays_on_top_hint);
    msg_box.set_attribute (Qt.WA_DeleteOnClose);
    msg_box.on_set_text (message);
    msg_box.set_window_title (title);
    msg_box.set_icon (QMessageBox.Information);
    msg_box.open ();
}

void OwncloudGui.on_show_settings () {
    if (this.settings_dialog.is_null ()) {
        this.settings_dialog = new SettingsDialog (this);
        this.settings_dialog.set_attribute (Qt.WA_DeleteOnClose, true);
        this.settings_dialog.show ();
    }
    raise_dialog (this.settings_dialog.data ());
}

void OwncloudGui.on_settings_dialog_activated () {
    /* emit */ is_showing_settings_dialog ();
}

void OwncloudGui.on_show_sync_protocol () {
    on_show_settings ();
    //this.settings_dialog.show_activity_page ();
}

void OwncloudGui.on_shutdown () {
    // explicitly close windows. This is somewhat of a hack to ensure
    // that saving the geometries happens ASAP during a OS shutdown

    // those do delete on close
    if (!this.settings_dialog.is_null ())
        this.settings_dialog.close ();
    if (!this.log_browser.is_null ())
        this.log_browser.delete_later ();
    this.app.quit ();
}

void OwncloudGui.on_toggle_log_browser () {
    if (this.log_browser.is_null ()) {
        // on_init the log browser.
        this.log_browser = new Log_browser;
        // ## TODO : allow new log name maybe?
    }

    if (this.log_browser.is_visible ()) {
        this.log_browser.hide ();
    } else {
        raise_dialog (this.log_browser);
    }
}

void OwncloudGui.on_open_owncloud () {
    if (var account = qvariant_cast<AccountPointer> (sender ().property (property_account_c))) {
        Utility.open_browser (account.url ());
    }
}

void OwncloudGui.on_help () {
    QDesktopServices.open_url (GLib.Uri (Theme.instance ().help_url ()));
}

void OwncloudGui.raise_dialog (Gtk.Widget raise_widget) {
    if (raise_widget && !raise_widget.parent_widget ()) {
        // Qt has a bug which causes parent-less dialogs to pop-under.
        raise_widget.show_normal ();
        raise_widget.raise ();
        raise_widget.on_activate_window ();
    }
}

void OwncloudGui.on_show_share_dialog (string share_path, string local_path, Share_dialog_start_page start_page) {
    const var folder = FolderMan.instance ().folder_for_path (local_path);
    if (!folder) {
        GLib.warn (lc_application) << "Could not open share dialog for" << local_path << "no responsible folder found";
        return;
    }

    const var account_state = folder.account_state ();

    const string file = local_path.mid (folder.clean_path ().length () + 1);
    SyncJournalFileRecord file_record;

    bool resharing_allowed = true; // lets assume the good
    if (folder.journal_database ().get_file_record (file, file_record) && file_record.is_valid ()) {
        // check the permission : Is resharing allowed?
        if (!file_record.remote_perm.is_null () && !file_record.remote_perm.has_permission (RemotePermissions.Can_reshare)) {
            resharing_allowed = false;
        }
    }

    var max_sharing_permissions = resharing_allowed? Share_permissions (account_state.account ().capabilities ().share_default_permissions ()) : Share_permissions ({});

    Share_dialog w = null;
    if (this.share_dialogs.contains (local_path) && this.share_dialogs[local_path]) {
        GLib.Info (lc_application) << "Raising share dialog" << share_path << local_path;
        w = this.share_dialogs[local_path];
    } else {
        GLib.Info (lc_application) << "Opening share dialog" << share_path << local_path << max_sharing_permissions;
        w = new Share_dialog (account_state, share_path, local_path, max_sharing_permissions, file_record.numeric_file_id (), start_page);
        w.set_attribute (Qt.WA_DeleteOnClose, true);

        this.share_dialogs[local_path] = w;
        connect (w, &GLib.Object.destroyed, this, &OwncloudGui.on_remove_destroyed_share_dialogs);
    }
    raise_dialog (w);
}

void OwncloudGui.on_remove_destroyed_share_dialogs () {
    QMutable_map_iterator<string, QPointer<Share_dialog>> it (this.share_dialogs);
    while (it.has_next ()) {
        it.next ();
        if (!it.value () || it.value () == sender ()) {
            it.remove ();
        }
    }
}

} // end namespace
