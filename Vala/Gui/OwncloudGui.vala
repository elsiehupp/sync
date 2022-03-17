/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifdef WITH_LIBCLOUDPROVIDERS
//  #endif

//  #include <QQmlApplicationEngine>
//  #include <QDesktopServices>
//  #include <GLib.Dir>
//  #include <Gtk.MessageBox>
//  #include <QSignal_mapper>
//  #include_LIBCLOUDPROVIDERS
//  #include <Qt_d_bus/QDBusConnection>
//  #include <Qt_d_bus/QDBusInterface>
//  #endif

//  #include <QQmlEngine>
//  #include <QQml_component>
//  #include <QQmlApplicationEngine>
//  #include <QQuickItem>
//  #include <QQml_context>
//  #include <QPointer
//  #include <QActio
//  #include <QMenu>
//  #include <QSize>
//  #include <QTimer>
//  #ifdef WITH_LIBCLOUDPROVIDERS
//  #include <QDBusConnection>
//  #endif

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudGui class
@ingroup gui
***********************************************************/
public class OwncloudGui : GLib.Object {

    private const string PROPERTY_ACCOUNT_C = "oc_account";

    enum ShareDialogStartPage {
        USERS_AND_GROUPS,
        PUBLIC_LINKS,
    }


    /***********************************************************
    ***********************************************************/
    private Systray tray;
    private SettingsDialog settings_dialog;
    private LogBrowser log_browser;

    private QDBusConnection bus;

    /***********************************************************
    ***********************************************************/
    private GLib.HashTable<string, ShareDialog> share_dialogs;

    /***********************************************************
    ***********************************************************/
    private QAction action_new_account_wizard;
    private QAction action_settings;
    private QAction action_estimate;

    /***********************************************************
    ***********************************************************/
    private GLib.List<QAction> recent_items_actions;
    private Application app;

    /***********************************************************
    ***********************************************************/
    internal signal void signal_setup_proxy ();

    /***********************************************************
    ***********************************************************/
    internal signal void signal_server_error (int code, string message);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_is_showing_settings_dialog ();

    /***********************************************************
    ***********************************************************/
    public OwncloudGui (Application parent = null) {
        base (parent);
        this.tray = null;
        this.settings_dialog = null;
        this.log_browser = null;
        this.bus = QDBusConnection.session_bus ();
        this.app = parent;
        this.tray = Systray.instance;
        this.tray.tray_engine = new QQmlApplicationEngine (this);
        // for the beginning, set the offline icon until the account was verified
        this.tray.icon = Theme.folder_offline_icon_for_tray;

        this.tray.show ();

        connect (
            this.tray,
            QSystemTrayIcon.activated,
            this,
            OwncloudGui.on_signal_tray_clicked
        );
        connect (
            this.tray,
            Systray.signal_open_help,
            this,
            OwncloudGui.on_signal_help
        );
        connect (
            this.tray,
            Systray.signal_open_account_wizard,
            this,
            OwncloudGui.on_signal_new_account_wizard
        );
        connect (
            this.tray,
            Systray.signal_open_main_dialog,
            this,
            OwncloudGui.on_signal_open_main_dialog
        );
        connect (
            this.tray,
            Systray.signal_open_settings,
            this,
            OwncloudGui.on_signal_show_settings
        );
        connect (
            this.tray,
            Systray.signal_shutdown,
            this,
            OwncloudGui.on_signal_shutdown
        );
        connect (
            this.tray,
            Systray.open_share_dialog,
            this,
            this.on_open_share_dialog
        );
        connect (
            ProgressDispatcher.instance,
            ProgressDispatcher.progress_info,
            this,
            OwncloudGui.on_signal_update_progress
        );
        connect (
            FolderMan.instance,
            FolderMan.signal_folder_sync_state_change,
            this,
            OwncloudGui.on_signal_sync_state_change
        );
        connect (
            Logger.instance,
            Logger.signal_gui_log,
            this,
            OwncloudGui.on_signal_show_tray_message
        );
        connect (
            Logger.instance,
            Logger.optional_gui_log,
            this,
            OwncloudGui.on_signal_show_optional_tray_message
        );
        connect (
            Logger.instance,
            Logger.gui_message,
            this,
            OwncloudGui.on_signal_show_gui_message
        );
    }


    private void on_open_share_dialog (string share_path, string local_path) {
        on_signal_show_share_dialog (share_path, local_path, ShareDialogStartPage.USERS_AND_GROUPS);
    }


    /***********************************************************
    ***********************************************************/
    //  public bool check_account_exists (bool signal_open_settings);


    /***********************************************************
    ***********************************************************/
    public static void raise_dialog (Gtk.Widget raise_widget) {
        if (raise_widget && !raise_widget.parent_widget ()) {
            // Qt has a bug which causes parent-less dialogs to pop-under.
            raise_widget.show_normal ();
            raise_widget.raise ();
            raise_widget.on_signal_activate_window ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public static QSize settings_dialog_size () {
        return {800, 500};
    }


    /***********************************************************
    ***********************************************************/
    //  public void setup_overlay_icons ();


    /***********************************************************
    ***********************************************************/
    public void setup_cloud_providers () {
        new CloudProviderManager (this);
    }


    /***********************************************************
    ***********************************************************/
    public bool cloud_provider_api_available ();
    bool OwncloudGui.cloud_provider_api_available () {
        if (!this.bus.is_connected ()) {
            return false;
        }
        QDBusInterface dbus_iface = new QDBusInterface (
            "org.freedesktop.CloudProviderManager",
            "/org/freedesktop/CloudProviderManager",
            "org.freedesktop.Cloud_provider.Manager1",
            this.bus
        );

        if (!dbus_iface.is_valid ()) {
            GLib.info ("DBus interface unavailable.");
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void create_tray () {
        this.tray.create ();
    }


    /***********************************************************
    ***********************************************************/
    public void hide_and_show_tray () {
        this.tray.hide ();
        this.tray.show ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_compute_overall_sync_status () {
        bool all_signed_out = true;
        bool all_paused = true;
        bool all_disconnected = true;
        GLib.List<unowned AccountState> problem_accounts;

        foreach (var account in AccountManager.instance.accounts ()) {
            if (!account.is_signed_out ()) {
                all_signed_out = false;
            }
            if (!account.is_connected ()) {
                problem_accounts.append (account);
            } else {
                all_disconnected = false;
            }
        }
        foreach (Folder folder in FolderMan.instance.map ()) {
            if (!folder.sync_paused ()) {
                all_paused = false;
            }
        }

        if (!problem_accounts.empty ()) {
            this.tray.icon (Theme.folder_offline_icon_for_tray);
            if (all_disconnected) {
                status_text (_("Disconnected"));
            } else {
                status_text (_("Disconnected from some accounts"));
            }
            string[] messages;
            messages.append (_("Disconnected from accounts:"));
            foreach (unowned AccountState account in problem_accounts) {
                string message = _("Account %1 : %2").printf (account.account.display_name (), account.state_string (account.state ()));
                if (!account.connection_errors ().empty ()) {
                    message += "\n";
                    message += account.connection_errors ().join ("\n");
                }
                messages.append (message);
            }
            this.tray.tool_tip (messages.join ("\n\n"));
    //  #endif
            return;
        }

        if (all_signed_out) {
            this.tray.icon (Theme.folder_offline_icon_for_tray);
            this.tray.tool_tip (_("Please sign in"));
            status_text (_("Signed out"));
            return;
        } else if (all_paused) {
            this.tray.icon (Theme.sync_state_icon (SyncResult.Status.PAUSED, true));
            this.tray.tool_tip (_("Account synchronization is disabled"));
            status_text (_("Synchronization is paused"));
            return;
        }

        // display the info of the least successful sync (eg. do not just display the result of the latest sync)
        string tray_message;
        FolderMan folder_man = FolderMan.instance;
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

        Gtk.Icon status_icon = Theme.sync_state_icon (icon_status, true);
        this.tray.icon (status_icon);

        // create the tray blob message, check if we have an defined state
        if (map.count () > 0) {
            string[] all_status_strings;
            foreach (Folder folder in map.values ()) {
                string folder_message = FolderMan.tray_tooltip_status_string (
                    folder.sync_result ().status (),
                    folder.sync_result ().has_unresolved_conflicts (),
                    folder.sync_paused ());
                all_status_strings += _("Folder %1: %2").printf (folder.short_gui_local_path (), folder_message);
            }
            tray_message = all_status_strings.join ("\n");
    //  #endif
            this.tray.tool_tip (tray_message);

            if (overall_status == SyncResult.Status.SUCCESS || overall_status == SyncResult.Status.PROBLEM) {
                if (has_unresolved_conflicts) {
                    status_text (_("Unresolved conflicts"));
                } else {
                    status_text (_("Up to date"));
                }
            } else if (overall_status == SyncResult.Status.PAUSED) {
                status_text (_("Synchronization is paused"));
            } else {
                status_text (_("Error during synchronization"));
            }
        } else {
            this.tray.tool_tip (_("There are no sync folders configured."));
            status_text (_("No sync folders configured"));
        }
    }


    /***********************************************************
    FIXME: So this doesn't do anything? Needs to be revisited
    ***********************************************************/
    private void status_text (string text) {
        //  Q_UNUSED (text)
        // Don't overwrite the status if we're currently syncing
        if (FolderMan.instance.is_any_sync_running ()) {
            return;
        }
        //this.action_status.on_signal_text (text);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_tray_message (string title, string message) {
        if (this.tray)
            this.tray.show_message (title, message);
        else
            GLib.warning ("Tray not ready: " + message);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_optional_tray_message (string title, string message) {
        on_signal_show_tray_message (title, message);
    }


    /***********************************************************
    open the folder with the given Alias
    ***********************************************************/
    private void OwncloudGui.on_signal_folder_open_action (string alias) {
        Folder folder = FolderMan.instance.folder_by_alias (alias);
        if (folder) {
            GLib.info ("opening local url " + folder.path ());
            GLib.Uri url = GLib.Uri.from_local_file (folder.path ());
            QDesktopServices.open_url (url);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_progress (string folder, ProgressInfo progress) {
        //  Q_UNUSED (folder);

        // FIXME: Lots of messages computed for nothing in this method, needs revisiting
        if (progress.status () == ProgressInfo.Status.DISCOVERY) {
    //  #if 0
            if (!progress.current_discovered_remote_folder == "") {
                this.action_status.on_signal_text (_("Checking for changes in remote \"%1\"")
                                        .printf (progress.current_discovered_remote_folder));
            } else if (!progress.current_discovered_local_folder == "") {
                this.action_status.on_signal_text (_("Checking for changes in local \"%1\"")
                                        .printf (progress.current_discovered_local_folder));
            }
    //  #endif
        } else if (progress.status () == ProgressInfo.Status.DONE) {
            QTimer.single_shot (2000, this, OwncloudGui.on_signal_compute_overall_sync_status);
        }
        if (progress.status () != ProgressInfo.Status.PROPAGATION) {
            return;
        }

        if (progress.total_size () == 0) {
            int64 current_file = progress.current_file ();
            int64 total_file_count = q_max (progress.total_files (), current_file);
            string message;
            if (progress.trust_eta ()) {
                message = _("Syncing %1 of %2 (%3 left)")
                        .printf (current_file)
                        .printf (total_file_count)
                        .printf (Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1 of %2")
                        .printf (current_file)
                        .printf (total_file_count);
            }
            //this.action_status.on_signal_text (message);
        } else {
            string total_size_str = Utility.octets_to_string (progress.total_size ());
            string message;
            if (progress.trust_eta ()) {
                message = _("Syncing %1 (%2 left)")
                        .printf (total_size_str, Utility.duration_to_descriptive_string2 (progress.total_progress ().estimated_eta));
            } else {
                message = _("Syncing %1")
                        .printf (total_size_str);
            }
            //this.action_status.on_signal_text (message);
        }

        if (!progress.last_completed_item == "") {

            string kind_str = Progress.as_result_string (progress.last_completed_item);
            string time_str = QTime.current_time ().to_string ("hh:mm");
            string action_text = _("%1 (%2, %3)").printf (progress.last_completed_item.file, kind_str, time_str);
            var action = new QAction (action_text, this);
            Folder folder = FolderMan.instance.folder_by_alias (folder);
            if (folder) {
                string full_path = folder.path () + '/' + progress.last_completed_item.file;
                if (GLib.File (full_path).exists ()) {
                    connect (
                        action,
                        QAction.triggered,
                        this,
                        this.on_progress_action_triggered
                    );
                } else {
                    action.enabled (false);
                }
            }
            if (this.recent_items_actions.length () > 5) {
                this.recent_items_actions.take_first ().delete_later ();
            }
            this.recent_items_actions.append (action);
        }
    }


    private void on_progress_action_triggered (string full_path) {
        this.on_signal_open_path (full_path);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_folders_changed () {
        on_signal_compute_overall_sync_status ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_sync_protocol () {
        on_signal_show_settings ();
        //  this.settings_dialog.show_activity_page ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_tray_clicked (QSystemTrayIcon.Activation_reason reason) {
        if (reason == QSystemTrayIcon.Trigger) {
            if (OwncloudSetupWizard.bring_wizard_to_front_if_visible ()) {
                // brought wizard to front
            } else if (this.share_dialogs.size () > 0) {
                // Share dialog (s) be hidden by other apps, bring them back
                foreach (ShareDialog share_dialog in this.share_dialogs) {
                    //  Q_ASSERT (share_dialog);
                    raise_dialog (share_dialog);
                }
            } else if (this.tray.is_open ()) {
                this.tray.hide_window ();
            } else {
                if (AccountManager.instance.accounts () == "") {
                    this.on_signal_open_settings_dialog ();
                } else {
                    this.tray.show_window ();
                }

            }
        }
        // FIXME: Also make sure that any var updater dialogue https://github.com/owncloud/client/issues/5613
        // or SSL error dialog also comes to front.
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_state_change (Folder folder) {
        on_signal_compute_overall_sync_status ();

        if (!folder) {
            return; // Valid, just a general GUI redraw was needed.
        }

        var result = folder.sync_result ();

        GLib.info ("Sync state changed for folder " + folder.remote_url ().to_string () + ": " + result.status_string ());

        if (result.status () == SyncResult.Status.SUCCESS
            || result.status () == SyncResult.Status.PROBLEM
            || result.status () == SyncResult.Status.SYNC_ABORT_REQUESTED
            || result.status () == SyncResult.Status.ERROR) {
            Logger.instance.on_signal_enter_next_log_file ();
        }
    }
        


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_gui_message (string title, string message) {
        var message_box = new Gtk.MessageBox ();
        message_box.window_flags (message_box.window_flags () | Qt.Window_stays_on_signal_top_hint);
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.on_signal_text (message);
        message_box.window_title (title);
        message_box.icon (Gtk.MessageBox.Information);
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_shutdown () {
        // explicitly close windows. This is somewhat of a hack to ensure
        // that saving the geometries happens ASAP during a OS signal_shutdown

        // those do delete on close
        if (!this.settings_dialog.is_null ())
            this.settings_dialog.close ();
        if (!this.log_browser.is_null ())
            this.log_browser.delete_later ();
        this.app.quit ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_toggle_log_browser () {
        if (this.log_browser.is_null ()) {
            // init the log browser.
            this.log_browser = new LogBrowser ();
            // ## TODO: allow new log name maybe?
        }

        if (this.log_browser.is_visible ()) {
            this.log_browser.hide ();
        } else {
            raise_dialog (this.log_browser);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_owncloud () {
        var account = (Account) sender ().property (PROPERTY_ACCOUNT_C);
        if (account) {
            OpenExtrernal.open_browser (account.url);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_settings () {
        if (this.settings_dialog.is_null ()) {
            this.settings_dialog = new SettingsDialog (this);
            this.settings_dialog.attribute (Qt.WA_DeleteOnClose, true);
            this.settings_dialog.show ();
        }
        raise_dialog (this.settings_dialog);
    }


    /***********************************************************
    This should rather be in application.... or rather in ConfigFile?
    ***********************************************************/
    public void on_signal_open_settings_dialog () {
        // if account is set up, on_signal_start the configuration wizard.
        if (!AccountManager.instance.accounts () == "") {
            if (this.settings_dialog.is_null () || Gtk.Application.active_window () != this.settings_dialog) {
                on_signal_show_settings ();
            } else {
                this.settings_dialog.close ();
            }
        } else {
            GLib.info ("No configured folders yet; starting setup wizard.");
            on_signal_new_account_wizard ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_main_dialog () {
        if (!this.tray.is_open ()) {
            this.tray.show_window ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_settings_dialog_activated () {
        /* emit */ signal_is_showing_settings_dialog ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_help () {
        QDesktopServices.open_url (GLib.Uri (Theme.help_url));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_path (string path) {
        show_in_file_manager (path);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_account_state_changed () {
        on_signal_compute_overall_sync_status ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_tray_message_if_server_unsupported (Account account) {
        if (account.server_version_unsupported ()) {
            on_signal_show_tray_message (
                _("Unsupported Server Version"),
                _("The server on account %1 runs an unsupported version %2. "
                + "Using this client with unsupported server versions is untested and "
                + "potentially dangerous. Proceed at your own risk.")
                    .printf (account.display_name (), account.server_version ()));
        }
    }


    /***********************************************************
    Open a share dialog for a file or folder.

    share_path is the full remote path to the item,
    local_path is the absolute local path to it (so not relative
    to the folder).
    ***********************************************************/
    private void on_signal_show_share_dialog (string share_path, string local_path, ShareDialogStartPage start_page) {
        const var folder = FolderMan.instance.folder_for_path (local_path);
        if (!folder) {
            GLib.warning ("Could not open share dialog for " + local_path +  "no responsible folder found.");
            return;
        }

        const var account_state = folder.account_state ();

        const string file = local_path.mid (folder.clean_path ().length () + 1);
        SyncJournalFileRecord file_record;

        bool resharing_allowed = true; // lets assume the good
        if (folder.journal_database ().file_record (file, file_record) && file_record.is_valid ()) {
            // check the permission : Is resharing allowed?
            if (!file_record.remote_perm.is_null () && !file_record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_RESHARE)) {
                resharing_allowed = false;
            }
        }

        var max_sharing_permissions = resharing_allowed? SharePermissions (account_state.account.capabilities ().share_default_permissions ()) : SharePermissions ({});

        ShareDialog share_dialog = null;
        if (this.share_dialogs.contains (local_path) && this.share_dialogs[local_path]) {
            GLib.info ("Raising share dialog " + share_path + local_path);
            share_dialog = this.share_dialogs[local_path];
        } else {
            GLib.info ("Opening share dialog " + share_path + local_path + max_sharing_permissions);
            share_dialog = new ShareDialog (account_state, share_path, local_path, max_sharing_permissions, file_record.numeric_file_id (), start_page);
            share_dialog.attribute (Qt.WA_DeleteOnClose, true);

            this.share_dialogs[local_path] = share_dialog;
            connect (
                share_dialog,
                GLib.Object.destroyed,
                this,
                OwncloudGui.on_signal_remove_destroyed_share_dialogs
            );
        }
        raise_dialog (share_dialog);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remove_destroyed_share_dialogs () {
        foreach (ShareDialog share_dialog in this.share_dialogs) {
            if (share_dialog == void || share_dialog = sender ()) {
                this.share_dialogs.remove (share_dialog);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_account_wizard () {
        OwncloudSetupWizard.run_wizard (
            Gtk.Application,
            on_signal_owncloud_wizard_done (int)
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_login () {
        var account = (AccountState) sender ().property (PROPERTY_ACCOUNT_C);
        if (account) {
            account.account.reset_rejected_certificates ();
            account.sign_in ();
        } else {
            foreach (var account in AccountManager.instance.accounts ()) {
                account.sign_in ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_logout () {
        var list = AccountManager.instance.accounts ();
        var account = (AccountState) sender ().property (PROPERTY_ACCOUNT_C);
        if (account) {
            list.clear ();
            list.append (account);
        }

        foreach (var ai in list) {
            ai.sign_out_by_ui ();
        }
    }

} // class OwncloudGui

} // namespace Ui
} // namespace Occ
