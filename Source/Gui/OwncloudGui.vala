/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

#ifdef WITH_LIBCLOUDPROVIDERS
#endif

// #include <QQml_application_engine>
// #include <QDesktopServices>
// #include <QDir>
// #include <QMessageBox>
// #include <QSignal_mapper>
#ifdef WITH_LIBCLOUDPROVIDERS
// #include <Qt_d_bus/QDBus_connection>
// #include <Qt_d_bus/QDBus_interface>
#endif

// #include <QQmlEngine>
// #include <QQml_component>
// #include <QQml_application_engine>
// #include <QQuick_item>
// #include <QQml_context>

// #include <GLib.Object>
// #include <QPointer>
// #include <QAction>
// #include <QMenu>
// #include <QSize>
// #include <QTimer>
#ifdef WITH_LIBCLOUDPROVIDERS
// #include <QDBus_connection>
#endif

namespace Occ {


class Log_browser;

enum class Share_dialog_start_page {
    Users_and_groups,
    Public_links,
};

/***********************************************************
@brief The OwncloudGui class
@ingroup gui
***********************************************************/
class OwncloudGui : GLib.Object {

    public OwncloudGui (Application *parent = nullptr);

    public bool check_account_exists (bool open_settings);

    public static void raise_dialog (Gtk.Widget *raise_widget);
    public static QSize settings_dialog_size () {
        return {800, 500};
    }
    public void setup_overlay_icons ();
#ifdef WITH_LIBCLOUDPROVIDERS
    public void setup_cloud_providers ();
    public bool cloud_provider_api_available ();
#endif
    public void create_tray ();

    public void hide_and_show_tray ();

signals:
    void setup_proxy ();
    void on_server_error (int code, string message);
    void is_showing_settings_dialog ();


    public void on_compute_overall_sync_status ();
    public void on_show_tray_message (string title, string msg);
    public void on_show_optional_tray_message (string title, string msg);
    public void on_folder_open_action (string alias);
    public void on_update_progress (string folder, ProgressInfo &progress);
    public void on_show_gui_message (string title, string message);
    public void on_folders_changed ();
    public void on_show_settings ();
    public void on_show_sync_protocol ();
    public void on_shutdown ();
    public void on_sync_state_change (Folder *);
    public void on_tray_clicked (QSystemTrayIcon.Activation_reason reason);
    public void on_toggle_log_browser ();
    public void on_open_owncloud ();
    public void on_open_settings_dialog ();
    public void on_open_main_dialog ();
    public void on_settings_dialog_activated ();
    public void on_help ();
    public void on_open_path (string path);
    public void on_account_state_changed ();
    public void on_tray_message_if_server_unsupported (Account *account);

    /***********************************************************
    Open a share dialog for a file or folder.

    share_path is the full remote path to the item,
    local_path is the absolute local path to it (so not relative
    to the folder).
    ***********************************************************/
    void on_show_share_dialog (string share_path, string local_path, Share_dialog_start_page start_page);

    void on_remove_destroyed_share_dialogs ();

    void on_new_account_wizard ();


    private void on_login ();
    private void on_logout ();


    private QPointer<Systray> _tray;
    private QPointer<SettingsDialog> _settings_dialog;
    private QPointer<Log_browser> _log_browser;

#ifdef WITH_LIBCLOUDPROVIDERS
    private QDBus_connection _bus;
#endif

    private QMap<string, QPointer<Share_dialog>> _share_dialogs;

    private QAction _action_new_account_wizard;
    private QAction _action_settings;
    private QAction _action_estimate;

    private GLib.List<QAction> _recent_items_actions;
    private Application _app;
};



const char property_account_c[] = "oc_account";

OwncloudGui.OwncloudGui (Application *parent)
    : GLib.Object (parent)
    , _tray (nullptr)
    , _settings_dialog (nullptr)
    , _log_browser (nullptr)
#ifdef WITH_LIBCLOUDPROVIDERS
    , _bus (QDBus_connection.session_bus ())
#endif
    , _app (parent) {
    _tray = Systray.instance ();
    _tray.set_tray_engine (new QQml_application_engine (this));
    // for the beginning, set the offline icon until the account was verified
    _tray.set_icon (Theme.instance ().folder_offline_icon (/*systray?*/ true));

    _tray.show ();

    connect (_tray.data (), &QSystemTrayIcon.activated,
        this, &OwncloudGui.on_tray_clicked);

    connect (_tray.data (), &Systray.open_help,
        this, &OwncloudGui.on_help);

    connect (_tray.data (), &Systray.open_account_wizard,
        this, &OwncloudGui.on_new_account_wizard);

    connect (_tray.data (), &Systray.open_main_dialog,
        this, &OwncloudGui.on_open_main_dialog);

    connect (_tray.data (), &Systray.open_settings,
        this, &OwncloudGui.on_show_settings);

    connect (_tray.data (), &Systray.shutdown,
        this, &OwncloudGui.on_shutdown);

    connect (_tray.data (), &Systray.open_share_dialog,
        this, [=] (string share_path, string local_path) {
                on_show_share_dialog (share_path, local_path, Share_dialog_start_page.Users_and_groups);
            });

    Progress_dispatcher *pd = Progress_dispatcher.instance ();
    connect (pd, &Progress_dispatcher.progress_info, this,
        &OwncloudGui.on_update_progress);

    FolderMan *folder_man = FolderMan.instance ();
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
    _tray.create ();
}

#ifdef WITH_LIBCLOUDPROVIDERS
void OwncloudGui.setup_cloud_providers () {
    new CloudProviderManager (this);
}

bool OwncloudGui.cloud_provider_api_available () {
    if (!_bus.is_connected ()) {
        return false;
    }
    QDBus_interface dbus_iface ("org.freedesktop.CloudProviderManager", "/org/freedesktop/CloudProviderManager",
                              "org.freedesktop.Cloud_provider.Manager1", _bus);

    if (!dbus_iface.is_valid ()) {
        q_c_info (lc_application) << "DBus interface unavailable";
        return false;
    }
    return true;
}
#endif

// This should rather be in application.... or rather in ConfigFile?
void OwncloudGui.on_open_settings_dialog () {
    // if account is set up, on_start the configuration wizard.
    if (!AccountManager.instance ().accounts ().is_empty ()) {
        if (_settings_dialog.is_null () || QApplication.active_window () != _settings_dialog) {
            on_show_settings ();
        } else {
            _settings_dialog.close ();
        }
    } else {
        q_c_info (lc_application) << "No configured folders yet, starting setup wizard";
        on_new_account_wizard ();
    }
}

void OwncloudGui.on_open_main_dialog () {
    if (!_tray.is_open ()) {
        _tray.show_window ();
    }
}

void OwncloudGui.on_tray_clicked (QSystemTrayIcon.Activation_reason reason) {
    if (reason == QSystemTrayIcon.Trigger) {
        if (OwncloudSetupWizard.bring_wizard_to_front_if_visible ()) {
            // brought wizard to front
        } else if (_share_dialogs.size () > 0) {
            // Share dialog (s) be hidden by other apps, bring them back
            Q_FOREACH (QPointer<Share_dialog> &share_dialog, _share_dialogs) {
                Q_ASSERT (share_dialog.data ());
                raise_dialog (share_dialog);
            }
        } else if (_tray.is_open ()) {
            _tray.hide_window ();
        } else {
            if (AccountManager.instance ().accounts ().is_empty ()) {
                this.on_open_settings_dialog ();
            } else {
                _tray.show_window ();
            }

        }
    }
    // FIXME : Also make sure that any auto updater dialogue https://github.com/owncloud/client/issues/5613
    // or SSL error dialog also comes to front.
}

void OwncloudGui.on_sync_state_change (Folder *folder) {
    on_compute_overall_sync_status ();

    if (!folder) {
        return; // Valid, just a general GUI redraw was needed.
    }

    auto result = folder.sync_result ();

    q_c_info (lc_application) << "Sync state changed for folder " << folder.remote_url ().to_string () << " : " << result.status_string ();

    if (result.status () == SyncResult.Success
        || result.status () == SyncResult.Problem
        || result.status () == SyncResult.Sync_abort_requested
        || result.status () == SyncResult.Error) {
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

void OwncloudGui.on_tray_message_if_server_unsupported (Account *account) {
    if (account.server_version_unsupported ()) {
        on_show_tray_message (
            tr ("Unsupported Server Version"),
            tr ("The server on account %1 runs an unsupported version %2. "
               "Using this client with unsupported server versions is untested and "
               "potentially dangerous. Proceed at your own risk.")
                .arg (account.display_name (), account.server_version ()));
    }
}

void OwncloudGui.on_compute_overall_sync_status () {
    bool all_signed_out = true;
    bool all_paused = true;
    bool all_disconnected = true;
    QVector<AccountStatePtr> problem_accounts;
    auto set_status_text = [&] (string text) {
        // FIXME : So this doesn't do anything? Needs to be revisited
        Q_UNUSED (text)
        // Don't overwrite the status if we're currently syncing
        if (FolderMan.instance ().is_any_sync_running ())
            return;
        //_action_status.on_set_text (text);
    };

    foreach (auto a, AccountManager.instance ().accounts ()) {
        if (!a.is_signed_out ()) {
            all_signed_out = false;
        }
        if (!a.is_connected ()) {
            problem_accounts.append (a);
        } else {
            all_disconnected = false;
        }
    }
    foreach (Folder *f, FolderMan.instance ().map ()) {
        if (!f.sync_paused ()) {
            all_paused = false;
        }
    }

    if (!problem_accounts.empty ()) {
        _tray.set_icon (Theme.instance ().folder_offline_icon (true));
        if (all_disconnected) {
            set_status_text (tr ("Disconnected"));
        } else {
            set_status_text (tr ("Disconnected from some accounts"));
        }
        string[] messages;
        messages.append (tr ("Disconnected from accounts:"));
        foreach (AccountStatePtr a, problem_accounts) {
            string message = tr ("Account %1 : %2").arg (a.account ().display_name (), a.state_string (a.state ()));
            if (!a.connection_errors ().empty ()) {
                message += QLatin1String ("\n");
                message += a.connection_errors ().join (QLatin1String ("\n"));
            }
            messages.append (message);
        }
        _tray.set_tool_tip (messages.join (QLatin1String ("\n\n")));
#endif
        return;
    }

    if (all_signed_out) {
        _tray.set_icon (Theme.instance ().folder_offline_icon (true));
        _tray.set_tool_tip (tr ("Please sign in"));
        set_status_text (tr ("Signed out"));
        return;
    } else if (all_paused) {
        _tray.set_icon (Theme.instance ().sync_state_icon (SyncResult.Paused, true));
        _tray.set_tool_tip (tr ("Account synchronization is disabled"));
        set_status_text (tr ("Synchronization is paused"));
        return;
    }

    // display the info of the least successful sync (eg. do not just display the result of the latest sync)
    string tray_message;
    FolderMan *folder_man = FolderMan.instance ();
    Folder.Map map = folder_man.map ();

    SyncResult.Status overall_status = SyncResult.Undefined;
    bool has_unresolved_conflicts = false;
    FolderMan.tray_overall_status (map.values (), &overall_status, &has_unresolved_conflicts);

    // If the sync succeeded but there are unresolved conflicts,
    // show the problem icon!
    auto icon_status = overall_status;
    if (icon_status == SyncResult.Success && has_unresolved_conflicts) {
        icon_status = SyncResult.Problem;
    }

    // If we don't get a status for whatever reason, that's a Problem
    if (icon_status == SyncResult.Undefined) {
        icon_status = SyncResult.Problem;
    }

    QIcon status_icon = Theme.instance ().sync_state_icon (icon_status, true);
    _tray.set_icon (status_icon);

    // create the tray blob message, check if we have an defined state
    if (map.count () > 0) {
        string[] all_status_strings;
        foreach (Folder *folder, map.values ()) {
            string folder_message = FolderMan.tray_tooltip_status_string (
                folder.sync_result ().status (),
                folder.sync_result ().has_unresolved_conflicts (),
                folder.sync_paused ());
            all_status_strings += tr ("Folder %1 : %2").arg (folder.short_gui_local_path (), folder_message);
        }
        tray_message = all_status_strings.join (QLatin1String ("\n"));
#endif
        _tray.set_tool_tip (tray_message);

        if (overall_status == SyncResult.Success || overall_status == SyncResult.Problem) {
            if (has_unresolved_conflicts) {
                set_status_text (tr ("Unresolved conflicts"));
            } else {
                set_status_text (tr ("Up to date"));
            }
        } else if (overall_status == SyncResult.Paused) {
            set_status_text (tr ("Synchronization is paused"));
        } else {
            set_status_text (tr ("Error during synchronization"));
        }
    } else {
        _tray.set_tool_tip (tr ("There are no sync folders configured."));
        set_status_text (tr ("No sync folders configured"));
    }
}

void OwncloudGui.hide_and_show_tray () {
    _tray.hide ();
    _tray.show ();
}

void OwncloudGui.on_show_tray_message (string title, string msg) {
    if (_tray)
        _tray.show_message (title, msg);
    else
        q_c_warning (lc_application) << "Tray not ready : " << msg;
}

void OwncloudGui.on_show_optional_tray_message (string title, string msg) {
    on_show_tray_message (title, msg);
}

/***********************************************************
open the folder with the given Alias
***********************************************************/
void OwncloudGui.on_folder_open_action (string alias) {
    Folder *f = FolderMan.instance ().folder (alias);
    if (f) {
        q_c_info (lc_application) << "opening local url " << f.path ();
        QUrl url = QUrl.from_local_file (f.path ());
        QDesktopServices.open_url (url);
    }
}

void OwncloudGui.on_update_progress (string folder, ProgressInfo &progress) {
    Q_UNUSED (folder);

    // FIXME : Lots of messages computed for nothing in this method, needs revisiting
    if (progress.status () == ProgressInfo.Discovery) {
#if 0
        if (!progress._current_discovered_remote_folder.is_empty ()) {
            _action_status.on_set_text (tr ("Checking for changes in remote \"%1\"")
                                       .arg (progress._current_discovered_remote_folder));
        } else if (!progress._current_discovered_local_folder.is_empty ()) {
            _action_status.on_set_text (tr ("Checking for changes in local \"%1\"")
                                       .arg (progress._current_discovered_local_folder));
        }
#endif
    } else if (progress.status () == ProgressInfo.Done) {
        QTimer.single_shot (2000, this, &OwncloudGui.on_compute_overall_sync_status);
    }
    if (progress.status () != ProgressInfo.Propagation) {
        return;
    }

    if (progress.total_size () == 0) {
        int64 current_file = progress.current_file ();
        int64 total_file_count = q_max (progress.total_files (), current_file);
        string msg;
        if (progress.trust_eta ()) {
            msg = tr ("Syncing %1 of %2 (%3 left)")
                      .arg (current_file)
                      .arg (total_file_count)
                      .arg (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = tr ("Syncing %1 of %2")
                      .arg (current_file)
                      .arg (total_file_count);
        }
        //_action_status.on_set_text (msg);
    } else {
        string total_size_str = Utility.octets_to_string (progress.total_size ());
        string msg;
        if (progress.trust_eta ()) {
            msg = tr ("Syncing %1 (%2 left)")
                      .arg (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
        } else {
            msg = tr ("Syncing %1")
                      .arg (total_size_str);
        }
        //_action_status.on_set_text (msg);
    }

    if (!progress._last_completed_item.is_empty ()) {

        string kind_str = Progress.as_result_string (progress._last_completed_item);
        string time_str = QTime.current_time ().to_string ("hh:mm");
        string action_text = tr ("%1 (%2, %3)").arg (progress._last_completed_item._file, kind_str, time_str);
        auto *action = new QAction (action_text, this);
        Folder *f = FolderMan.instance ().folder (folder);
        if (f) {
            string full_path = f.path () + '/' + progress._last_completed_item._file;
            if (QFile (full_path).exists ()) {
                connect (action, &QAction.triggered, this, [this, full_path] {
                    this.on_open_path (full_path);
                });
            } else {
                action.set_enabled (false);
            }
        }
        if (_recent_items_actions.length () > 5) {
            _recent_items_actions.take_first ().delete_later ();
        }
        _recent_items_actions.append (action);
    }
}

void OwncloudGui.on_login () {
    if (auto account = qvariant_cast<AccountStatePtr> (sender ().property (property_account_c))) {
        account.account ().reset_rejected_certificates ();
        account.sign_in ();
    } else {
        auto list = AccountManager.instance ().accounts ();
        foreach (auto &a, list) {
            a.sign_in ();
        }
    }
}

void OwncloudGui.on_logout () {
    auto list = AccountManager.instance ().accounts ();
    if (auto account = qvariant_cast<AccountStatePtr> (sender ().property (property_account_c))) {
        list.clear ();
        list.append (account);
    }

    foreach (auto &ai, list) {
        ai.sign_out_by_ui ();
    }
}

void OwncloudGui.on_new_account_wizard () {
    OwncloudSetupWizard.run_wizard (q_app, SLOT (on_owncloud_wizard_done (int)));
}

void OwncloudGui.on_show_gui_message (string title, string message) {
    auto *msg_box = new QMessageBox;
    msg_box.set_window_flags (msg_box.window_flags () | Qt.Window_stays_on_top_hint);
    msg_box.set_attribute (Qt.WA_DeleteOnClose);
    msg_box.on_set_text (message);
    msg_box.set_window_title (title);
    msg_box.set_icon (QMessageBox.Information);
    msg_box.open ();
}

void OwncloudGui.on_show_settings () {
    if (_settings_dialog.is_null ()) {
        _settings_dialog = new SettingsDialog (this);
        _settings_dialog.set_attribute (Qt.WA_DeleteOnClose, true);
        _settings_dialog.show ();
    }
    raise_dialog (_settings_dialog.data ());
}

void OwncloudGui.on_settings_dialog_activated () {
    emit is_showing_settings_dialog ();
}

void OwncloudGui.on_show_sync_protocol () {
    on_show_settings ();
    //_settings_dialog.show_activity_page ();
}

void OwncloudGui.on_shutdown () {
    // explicitly close windows. This is somewhat of a hack to ensure
    // that saving the geometries happens ASAP during a OS shutdown

    // those do delete on close
    if (!_settings_dialog.is_null ())
        _settings_dialog.close ();
    if (!_log_browser.is_null ())
        _log_browser.delete_later ();
    _app.quit ();
}

void OwncloudGui.on_toggle_log_browser () {
    if (_log_browser.is_null ()) {
        // on_init the log browser.
        _log_browser = new Log_browser;
        // ## TODO : allow new log name maybe?
    }

    if (_log_browser.is_visible ()) {
        _log_browser.hide ();
    } else {
        raise_dialog (_log_browser);
    }
}

void OwncloudGui.on_open_owncloud () {
    if (auto account = qvariant_cast<AccountPtr> (sender ().property (property_account_c))) {
        Utility.open_browser (account.url ());
    }
}

void OwncloudGui.on_help () {
    QDesktopServices.open_url (QUrl (Theme.instance ().help_url ()));
}

void OwncloudGui.raise_dialog (Gtk.Widget *raise_widget) {
    if (raise_widget && !raise_widget.parent_widget ()) {
        // Qt has a bug which causes parent-less dialogs to pop-under.
        raise_widget.show_normal ();
        raise_widget.raise ();
        raise_widget.on_activate_window ();
    }
}

void OwncloudGui.on_show_share_dialog (string share_path, string local_path, Share_dialog_start_page start_page) {
    const auto folder = FolderMan.instance ().folder_for_path (local_path);
    if (!folder) {
        q_c_warning (lc_application) << "Could not open share dialog for" << local_path << "no responsible folder found";
        return;
    }

    const auto account_state = folder.account_state ();

    const string file = local_path.mid (folder.clean_path ().length () + 1);
    SyncJournalFileRecord file_record;

    bool resharing_allowed = true; // lets assume the good
    if (folder.journal_db ().get_file_record (file, &file_record) && file_record.is_valid ()) {
        // check the permission : Is resharing allowed?
        if (!file_record._remote_perm.is_null () && !file_record._remote_perm.has_permission (RemotePermissions.Can_reshare)) {
            resharing_allowed = false;
        }
    }

    auto max_sharing_permissions = resharing_allowed? Share_permissions (account_state.account ().capabilities ().share_default_permissions ()) : Share_permissions ({});

    Share_dialog *w = nullptr;
    if (_share_dialogs.contains (local_path) && _share_dialogs[local_path]) {
        q_c_info (lc_application) << "Raising share dialog" << share_path << local_path;
        w = _share_dialogs[local_path];
    } else {
        q_c_info (lc_application) << "Opening share dialog" << share_path << local_path << max_sharing_permissions;
        w = new Share_dialog (account_state, share_path, local_path, max_sharing_permissions, file_record.numeric_file_id (), start_page);
        w.set_attribute (Qt.WA_DeleteOnClose, true);

        _share_dialogs[local_path] = w;
        connect (w, &GLib.Object.destroyed, this, &OwncloudGui.on_remove_destroyed_share_dialogs);
    }
    raise_dialog (w);
}

void OwncloudGui.on_remove_destroyed_share_dialogs () {
    QMutable_map_iterator<string, QPointer<Share_dialog>> it (_share_dialogs);
    while (it.has_next ()) {
        it.next ();
        if (!it.value () || it.value () == sender ()) {
            it.remove ();
        }
    }
}

} // end namespace
