/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <cmath>
//  #include <QDesktopServices>
//  #include <QDial
//  #include <QDir>
//  #include <QListWidgetT
//  #include <QMessage
//  #include <QAction>
//  #include <QVBoxLayou
//  #include <QTreeView>
//  #include <QKeySe
//  #include <QIcon>
//  #include <QJsonDocum
//  #include <QToolTip>
//  #include <Gtk.Widget>
//  #include <QPointer>
//  #include <QTimer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The AccountSettings class
@ingroup gui
***********************************************************/
class AccountSettings : Gtk.Widget {


    /***********************************************************
    Adjusts the mouse cursor based on the region it is on over the folder tree view.

    Used to show that one can click the red error list box by changing the cursor
    to the pointing hand.
    ***********************************************************/
    class MouseCursorChanger : GLib.Object {

        public QTreeView folder_list;
        public FolderStatusModel model;

        public MouseCursorChanger (GLib.Object parent)
            : GLib.Object (parent) {
        }


        protected bool event_filter (GLib.Object watched, QEvent event) override {
            if (event.type () == QEvent.HoverMove) {
                Qt.CursorShape shape = Qt.ArrowCursor;
                var position = folder_list.map_from_global (QCursor.position ());
                var index = folder_list.index_at (position);
                if (model.classify (index) == FolderStatusModel.ItemType.ROOT_FOLDER
                    && (FolderStatusDelegate.errors_list_rect (folder_list.visual_rect (index)).contains (position)
                        || FolderStatusDelegate.options_button_rect (folder_list.visual_rect (index),folder_list.layout_direction ()).contains (position))) {
                    shape = Qt.PointingHandCursor;
                }
                folder_list.cursor (shape);
            }
            return GLib.Object.event_filter (watched, event);
        }
    }


    const string PROPERTY_FOLDER = "folder";
    const string PROPERTY_PATH = "path";


    /***********************************************************
    ***********************************************************/
    const string PROGRESS_BAR_STYLE_C
        = "QProgressBar {"
        + "border : 1px solid grey;"
        + "border-radius : 5px;"
        + "text-align : center;"
        + "}"
        + "QProgressBar.chunk {"
        + "background-color : %1; width : 1px;"
        + "}";


    /***********************************************************
    ***********************************************************/
    private Ui.AccountSettings ui;

    /***********************************************************
    ***********************************************************/
    private FolderStatusModel model;
    private GLib.Uri OCUrl;
    private bool was_disabled_before;
    private AccountState account_state;
    private UserInfo user_info;
    private QAction toggle_sign_in_out_action;
    private QAction add_account_action;

    /***********************************************************
    ***********************************************************/
    private bool menu_shown;


    signal void folder_changed ();
    signal void open_folder_alias (string );
    signal void show_issues_list (AccountState account);
    signal void request_mnemonic ();
    signal void remove_account_folders (AccountState account);
    signal void style_changed ();

    /***********************************************************
    ***********************************************************/
    public AccountSettings (AccountState account_state, Gtk.Widget parent = null) {
        base (parent);
        this.ui = new Ui.AccountSettings ()
        this.was_disabled_before = false;
        this.account_state = account_state;
        this.user_info (account_state, false, true)
        this.menu_shown = false;
        this.ui.up_ui (this);

        this.model = new FolderStatusModel;
        this.model.account_state (this.account_state);
        this.model.parent (this);
        var delegate = new FolderStatusDelegate;
        delegate.parent (this);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &AccountSettings.style_changed, delegate, &FolderStatusDelegate.on_signal_style_changed);

        this.ui.folder_list.header ().hide ();
        this.ui.folder_list.item_delegate (delegate);
        this.ui.folder_list.model (this.model);
        this.ui.folder_list.minimum_width (300);
        new ToolTipUpdater (this.ui.folder_list);

        var mouse_cursor_changer = new MouseCursorChanger (this);
        mouse_cursor_changer.folder_list = this.ui.folder_list;
        mouse_cursor_changer.model = this.model;
        this.ui.folder_list.mouse_tracking (true);
        this.ui.folder_list.attribute (Qt.WA_Hover, true);
        this.ui.folder_list.install_event_filter (mouse_cursor_changer);

        connect (this, &AccountSettings.remove_account_folders,
                AccountManager.instance (), &AccountManager.remove_account_folders);
        connect (this.ui.folder_list, &Gtk.Widget.custom_context_menu_requested,
            this, &AccountSettings.on_signal_custom_context_menu_requested);
        connect (this.ui.folder_list, &QAbstractItemView.clicked,
            this, &AccountSettings.on_signal_folder_list_clicked);
        connect (this.ui.folder_list, &QTreeView.expanded, this, &AccountSettings.on_signal_refresh_selective_sync_status);
        connect (this.ui.folder_list, &QTreeView.collapsed, this, &AccountSettings.on_signal_refresh_selective_sync_status);
        connect (this.ui.selective_sync_notification, &Gtk.Label.link_activated,
            this, &AccountSettings.on_signal_link_activated);
        connect (this.model, &FolderStatusModel.suggest_expand, this.ui.folder_list, &QTreeView.expand);
        connect (this.model, &FolderStatusModel.dirty_changed, this, &AccountSettings.on_signal_refresh_selective_sync_status);
        on_signal_refresh_selective_sync_status ();
        connect (this.model, &QAbstractItemModel.rows_inserted,
            this, &AccountSettings.on_signal_refresh_selective_sync_status);

        var sync_now_action = new QAction (this);
        sync_now_action.shortcut (QKeySequence (Qt.Key_F6));
        connect (sync_now_action, &QAction.triggered, this, &AccountSettings.on_signal_schedule_current_folder);
        add_action (sync_now_action);

        var sync_now_with_remote_discovery = new QAction (this);
        sync_now_with_remote_discovery.shortcut (QKeySequence (Qt.CTRL + Qt.Key_F6));
        connect (sync_now_with_remote_discovery, &QAction.triggered, this, &AccountSettings.on_signal_schedule_current_folder_force_remote_discovery);
        add_action (sync_now_with_remote_discovery);

        on_signal_hide_selective_sync_widget ();
        this.ui.big_folder_ui.visible (false);
        connect (this.model, &QAbstractItemModel.on_signal_data_changed, this, &AccountSettings.on_signal_selective_sync_changed);
        connect (this.ui.selective_sync_apply, &QAbstractButton.clicked, this, &AccountSettings.on_signal_hide_selective_sync_widget);
        connect (this.ui.selective_sync_cancel, &QAbstractButton.clicked, this, &AccountSettings.on_signal_hide_selective_sync_widget);

        connect (this.ui.selective_sync_apply, &QAbstractButton.clicked, this.model, &FolderStatusModel.on_signal_apply_selective_sync);
        connect (this.ui.selective_sync_cancel, &QAbstractButton.clicked, this.model, &FolderStatusModel.on_signal_reset_folders);
        connect (this.ui.big_folder_apply, &QAbstractButton.clicked, this.model, &FolderStatusModel.on_signal_apply_selective_sync);
        connect (this.ui.big_folder_sync_all, &QAbstractButton.clicked, this.model, &FolderStatusModel.on_signal_sync_all_pending_big_folders);
        connect (this.ui.big_folder_sync_none, &QAbstractButton.clicked, this.model, &FolderStatusModel.on_signal_sync_no_pending_big_folders);

        connect (FolderMan.instance (), &FolderMan.signal_folder_list_changed, this.model, &FolderStatusModel.on_signal_reset_folders);
        connect (this, &AccountSettings.folder_changed, this.model, &FolderStatusModel.on_signal_reset_folders);

        // quota_progress_bar style now set in customize_style ()
        /*Gtk.Color color = palette ().highlight ().color ();
         this.ui.quota_progress_bar.style_sheet (string.from_latin1 (PROGRESS_BAR_STYLE_C).arg (color.name ()));*/

        // Connect E2E stuff
        connect (this, &AccountSettings.request_mnemonic, this.account_state.account ().e2e (), &ClientSideEncryption.on_signal_request_mnemonic);
        connect (this.account_state.account ().e2e (), &ClientSideEncryption.show_mnemonic, this, &AccountSettings.on_signal_show_mnemonic);

        connect (this.account_state.account ().e2e (), &ClientSideEncryption.mnemonic_generated, this, &AccountSettings.on_signal_new_mnemonic_generated);
        if (this.account_state.account ().e2e ().new_mnemonic_generated ()) {
            on_signal_new_mnemonic_generated ();
        } else {
            this.ui.encryption_message.on_signal_text (_("This account supports end-to-end encryption"));

            var mnemonic = new QAction (_("Display mnemonic"), this);
            connect (mnemonic, &QAction.triggered, this, &AccountSettings.request_mnemonic);
            this.ui.encryption_message.add_action (mnemonic);
            this.ui.encryption_message.hide ();
        }

        this.ui.connect_label.on_signal_text (_("No account configured."));

        connect (this.account_state, &AccountState.state_changed, this, &AccountSettings.on_signal_account_state_changed);
        on_signal_account_state_changed ();

        connect (&this.user_info, &UserInfo.quota_updated,
            this, &AccountSettings.on_signal_update_quota);

        customize_style ();
    }


    ~AccountSettings () {
        delete this.ui;
    }


    public QSize size_hint () override {
        return OwncloudGui.settings_dialog_size ();
    }


    /***********************************************************
    ***********************************************************/
    public bool can_encrypt_or_decrypt (FolderStatusModel.SubFolderInfo info) {
        if (info.folder.sync_result ().status () != SyncResult.Status.SUCCESS) {
            QMessageBox msg_box;
            msg_box.on_signal_text ("Please wait for the folder to sync before trying to encrypt it.");
            msg_box.exec ();
            return false;
        }

        // for some reason the actual folder in disk is info.folder.path + info.path.
        QDir folder_path (info.folder.path () + info.path);
        folder_path.filter ( QDir.AllEntries | QDir.NoDotAndDotDot );

        if (folder_path.count () != 0) {
            QMessageBox msg_box;
            msg_box.on_signal_text (_("You cannot encrypt a folder with contents, please remove the files.\n"
                           "Wait for the new sync, then encrypt it."));
            msg_box.exec ();
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_oc () {
        if (this.OCUrl.is_valid ()) {
            Utility.open_browser (this.OCUrl);
        }
    }

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_signal_update_quota (int64 total, int64 used) {
        if (total > 0) {
            this.ui.quota_progress_bar.visible (true);
            this.ui.quota_progress_bar.enabled (true);
            // workaround the label only accepting ints (which may be only 32 bit wide)
            const double percent = used / (double)total * 100;
            const int percent_int = q_min (q_round (percent), 100);
            this.ui.quota_progress_bar.value (percent_int);
            string used_str = Utility.octets_to_string (used);
            string total_str = Utility.octets_to_string (total);
            string percent_str = Utility.compact_format_double (percent, 1);
            string tool_tip = _("%1 (%3%) of %2 in use. Some folders, including network mounted or shared folders, might have different limits.").arg (used_str, total_str, percent_str);
            this.ui.quota_info_label.on_signal_text (_("%1 of %2 in use").arg (used_str, total_str));
            this.ui.quota_info_label.tool_tip (tool_tip);
            this.ui.quota_progress_bar.tool_tip (tool_tip);
        } else {
            this.ui.quota_progress_bar.visible (false);
            this.ui.quota_info_label.tool_tip ("");

            /* -1 means not computed; -2 means unknown; -3 means unlimited  (#owncloud/client/issues/3940)*/
            if (total == 0 || total == -1) {
                this.ui.quota_info_label.on_signal_text (_("Currently there is no storage usage information available."));
            } else {
                string used_str = Utility.octets_to_string (used);
                this.ui.quota_info_label.on_signal_text (_("%1 in use").arg (used_str));
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_account_state_changed () {
        const AccountState.State state = this.account_state ? this.account_state.state () : AccountState.State.DISCONNECTED;
        if (state != AccountState.State.DISCONNECTED) {
            this.ui.ssl_button.update_account_state (this.account_state);
            AccountPointer account = this.account_state.account ();
            GLib.Uri safe_url (account.url ());
            safe_url.password (""); // Remove the password from the URL to avoid showing it in the UI
            const var folders = FolderMan.instance ().map ().values ();
            for (Folder folder : folders) {
                this.model.on_signal_update_folder_state (folder);
            }

            const string server = string.from_latin1 ("<a href=\"%1\">%2</a>")
                                       .arg (Utility.escape (account.url ().to_string ()),
                                           Utility.escape (safe_url.to_string ()));
            string server_with_user = server;
            if (AbstractCredentials credentials = account.credentials ()) {
                string user = account.dav_display_name ();
                if (user.is_empty ()) {
                    user = credentials.user ();
                }
                server_with_user = _("%1 as %2").arg (server, Utility.escape (user));
            }

            switch (state) {
            case AccountState.State.CONNECTED: {
                string[] errors;
                if (account.server_version_unsupported ()) {
                    errors + _("The server version %1 is unsupported! Proceed at your own risk.").arg (account.server_version ());
                }
                show_connection_label (_("Connected to %1.").arg (server_with_user), errors);
                break;
            }
            case AccountState.State.SERVICE_UNAVAILABLE:
                show_connection_label (_("Server %1 is temporarily unavailable.").arg (server));
                break;
            case AccountState.State.MAINTENANCE_MODE:
                show_connection_label (_("Server %1 is currently in maintenance mode.").arg (server));
                break;
            case AccountState.State.SIGNED_OUT:
                show_connection_label (_("Signed out from %1.").arg (server_with_user));
                break;
            case AccountState.State.ASKING_CREDENTIALS: {
                GLib.Uri url;
                if (var credentials = qobject_cast<HttpCredentialsGui> (account.credentials ())) {
                    connect (credentials, &HttpCredentialsGui.authorisation_link_changed,
                        this, &AccountSettings.on_signal_account_state_changed, Qt.UniqueConnection);
                    url = credentials.authorisation_link ();
                }
                if (url.is_valid ()) {
                    show_connection_label (_("Obtaining authorization from the browser. "
                                           "<a href='%1'>Click here</a> to re-open the browser.")
                                            .arg (url.to_string (GLib.Uri.FullyEncoded)));
                } else {
                    show_connection_label (_("Connecting to %1 …").arg (server_with_user));
                }
                break;
            }
            case AccountState.State.NETWORK_ERROR:
                show_connection_label (_("No connection to %1 at %2.")
                                        .arg (Utility.escape (Theme.instance ().app_name_gui ()), server),
                    this.account_state.connection_errors ());
                break;
            case AccountState.State.CONFIGURATION_ERROR:
                show_connection_label (_("Server configuration error : %1 at %2.")
                                        .arg (Utility.escape (Theme.instance ().app_name_gui ()), server),
                    this.account_state.connection_errors ());
                break;
            case AccountState.State.DISCONNECTED:
                // we can't end up here as the whole block is ifdeffed
                Q_UNREACHABLE ();
                break;
            }
        } else {
            // own_cloud is not yet configured.
            show_connection_label (_("No %1 connection configured.")
                                    .arg (Utility.escape (Theme.instance ().app_name_gui ())));
        }

        /* Allow to expand the item if the account is connected. */
        this.ui.folder_list.items_expandable (state == AccountState.State.CONNECTED);

        if (state != AccountState.State.CONNECTED) {
            /* check if there are expanded root items, if so, close them */
            int i = 0;
            for (i = 0; i < this.model.row_count (); ++i) {
                if (this.ui.folder_list.is_expanded (this.model.index (i)))
                    this.ui.folder_list.expanded (this.model.index (i), false);
            }
        } else if (this.model.is_dirty ()) {
            // If we connect and have pending changes, show the list.
            on_signal_do_expand ();
        }

        // Disabling expansion of folders might require hiding the selective
        // sync user interface buttons.
        on_signal_refresh_selective_sync_status ();

        if (state == AccountState.State.Connected) {
            /* TODO : We should probably do something better here.
            Verify if the user has a private key already uploaded to the server,
            if it has, do not offer to create one.
             */
            GLib.info ("Account" + on_signal_accounts_state ().account ().display_name ()
                + "Client Side Encryption" + on_signal_accounts_state ().account ().capabilities ().client_side_encryption_available ();

            if (this.account_state.account ().capabilities ().client_side_encryption_available ()) {
                this.ui.encryption_message.show ();
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();

        // Notify the other widgets (Dark-/Light-Mode switching)
        /* emit */ style_changed ();
    }


    public AccountState on_signal_accounts_state () {
        return this.account_state;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_hide_selective_sync_widget () {
        this.ui.selective_sync_apply.enabled (false);
        this.ui.selective_sync_status.visible (false);
        this.ui.selective_sync_buttons.visible (false);
        this.ui.selective_sync_label.hide ();
    }


    protected void on_signal_add_folder () {
        FolderMan folder_man = FolderMan.instance ();
        folder_man.sync_enabled (false); // do not on_signal_start more syncs.

        var folder_wizard = new FolderWizard (this.account_state.account (), this);
        folder_wizard.attribute (Qt.WA_DeleteOnClose);

        connect (folder_wizard, &Gtk.Dialog.accepted, this, &AccountSettings.on_signal_folder_wizard_accepted);
        connect (folder_wizard, &Gtk.Dialog.rejected, this, &AccountSettings.on_signal_folder_wizard_rejected);
        folder_wizard.open ();
    }


    protected void on_signal_enable_current_folder (bool terminate = false) {
        var alias = selected_folder_alias ();

        if (!alias.is_empty ()) {
            FolderMan folder_man = FolderMan.instance ();

            GLib.info ("Application : enable folder with alias " + alias;
            bool currently_paused = false;

            // this sets the folder status to disabled but does not interrupt it.
            Folder f = folder_man.folder_by_alias (alias);
            if (!f) {
                return;
            }
            currently_paused = f.sync_paused ();
            if (!currently_paused && !terminate) {
                // check if a sync is still running and if so, ask if we should terminate.
                if (f.is_busy ()) { // its still running
                    var msgbox = new QMessageBox (QMessageBox.Question, _("Sync Running"),
                        _("The syncing operation is running.<br/>Do you want to terminate it?"),
                        QMessageBox.Yes | QMessageBox.No, this);
                    msgbox.attribute (Qt.WA_DeleteOnClose);
                    msgbox.default_button (QMessageBox.Yes);
                    connect (msgbox, &QMessageBox.accepted, this, [this]{
                        on_signal_enable_current_folder (true);
                    });
                    msgbox.open ();
                    return;
                }
            }

            // message box can return at any time while the thread keeps running,
            // so better check again after the user has responded.
            if (f.is_busy () && terminate) {
                f.on_signal_terminate_sync ();
            }
            f.sync_paused (!currently_paused);

            // keep state for the icon setting.
            if (currently_paused)
                this.was_disabled_before = true;

            this.model.on_signal_update_folder_state (f);
        }
    }


    protected void on_signal_schedule_current_folder () {
        FolderMan folder_man = FolderMan.instance ();
        if (var folder = folder_man.folder_by_alias (selected_folder_alias ())) {
            folder_man.schedule_folder (folder);
        }
    }


    protected void on_signal_schedule_current_folder_force_remote_discovery () {
        FolderMan folder_man = FolderMan.instance ();
        if (var folder = folder_man.folder_by_alias (selected_folder_alias ())) {
            folder.on_signal_wipe_error_blocklist ();
            folder.journal_database ().force_remote_discovery_next_sync ();
            folder_man.schedule_folder (folder);
        }
    }


    protected void on_signal_force_sync_current_folder () {
        FolderMan folder_man = FolderMan.instance ();
        if (var selected_folder = folder_man.folder_by_alias (selected_folder_alias ())) {
            // Terminate and reschedule any running sync
            for (var f : folder_man.map ()) {
                if (f.is_sync_running ()) {
                    f.on_signal_terminate_sync ();
                    folder_man.schedule_folder (f);
                }
            }

            selected_folder.on_signal_wipe_error_blocklist (); // issue #6757

            // Insert the selected folder at the front of the queue
            folder_man.schedule_folder_next (selected_folder);
        }
    }


    protected void on_signal_remove_current_folder () {
        var folder = FolderMan.instance ().folder_by_alias (selected_folder_alias ());
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (selected.is_valid () && folder) {
            int row = selected.row ();

            GLib.info ("Remove Folder alias " + folder.alias ();
            string short_gui_local_path = folder.short_gui_local_path ();

            var message_box = new QMessageBox (QMessageBox.Question,
                _("Confirm Folder Sync Connection Removal"),
                _("<p>Do you really want to stop syncing the folder <i>%1</i>?</p>"
                   "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                    .arg (short_gui_local_path),
                QMessageBox.NoButton,
                this);
            message_box.attribute (Qt.WA_DeleteOnClose);
            QPushButton yes_button =
                message_box.add_button (_("Remove Folder Sync Connection"), QMessageBox.YesRole);
            message_box.add_button (_("Cancel"), QMessageBox.NoRole);
            connect (message_box, &QMessageBox.on_signal_finished, this, [message_box, yes_button, folder, row, this]{
                if (message_box.clicked_button () == yes_button) {
                    Utility.remove_fav_link (folder.path ());
                    FolderMan.instance ().remove_folder (folder);
                    this.model.remove_row (row);

                    // single folder fix to show add-button and hide remove-button
                    /* emit */ folder_changed ();
                }
            });
            message_box.open ();
        }
    }


    // sync folder
    protected void on_signal_open_current_folder () {
        var alias = selected_folder_alias ();
        if (!alias.is_empty ()) {
            /* emit */ open_folder_alias (alias);
        }
    }


    // selected subfolder in sync folder
    protected void on_signal_open_current_local_sub_folder () {
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || this.model.classify (selected) != FolderStatusModel.ItemType.SUBFOLDER)
            return;
        string filename = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
        GLib.Uri url = GLib.Uri.from_local_file (filename);
        QDesktopServices.open_url (url);
    }


    protected void on_signal_edit_current_ignored_files () {
        Folder f = FolderMan.instance ().folder_by_alias (selected_folder_alias ());
        if (!f)
            return;
        open_ignored_files_dialog (f.path ());
    }


    protected void on_signal_open_make_folder_dialog () {
        const var selected = this.ui.folder_list.selection_model ().current_index ();

        if (!selected.is_valid ()) {
            GLib.warning ("Selection model current folder index is not valid.";
            return;
        }

        const var classification = this.model.classify (selected);

        if (classification != FolderStatusModel.ItemType.SUBFOLDER && classification != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return;
        }

        const string filename = [this, selected, classification] {
            string result;
            if (classification == FolderStatusModel.ItemType.ROOT_FOLDER) {
                const var alias = this.model.data (selected, DataRole.FOLDER_ALIAS_ROLE).to_string ();
                if (var folder = FolderMan.instance ().folder_by_alias (alias)) {
                    result = folder.path ();
                }
            } else {
                result = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
            }

            if (result.ends_with ('/')) {
                result.chop (1);
            }

            return result;
        } ();

        if (!filename.is_empty ()) {
            const var folder_creation_dialog = new FolderCreationDialog (filename, this);
            folder_creation_dialog.attribute (Qt.WA_DeleteOnClose);
            folder_creation_dialog.open ();
        }
    }


    protected void on_signal_edit_current_local_ignored_files () {
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || this.model.classify (selected) != FolderStatusModel.ItemType.SUBFOLDER)
            return;
        string filename = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
        open_ignored_files_dialog (filename);
    }


    protected void on_signal_enable_vfs_current_folder () {
        FolderMan folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder_by_alias (selected_folder_alias ());
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        OwncloudWizard.ask_experimental_virtual_files_feature (this, [folder, this] (bool enable) {
            if (!enable || !folder)
                return;

            // we might need to add or remove the panel entry as cfapi brings this feature out of the box
            FolderMan.instance ().navigation_pane_helper ().schedule_update_cloud_storage_registry ();

            // It is unsafe to switch on vfs while a sync is running - wait if necessary.
            var connection = std.make_shared<QMetaObject.Connection> ();
            var switch_vfs_on = [folder, connection, this] () {
                if (*connection)
                    GLib.Object.disconnect (*connection);

                GLib.info ("Enabling vfs support for folder" + folder.path ();

                // Wipe selective sync blocklist
                bool ok = false;
                const var old_blocklist = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
                folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {});

                // Change the folder vfs mode and load the plugin
                folder.virtual_files_enabled (true);
                folder.vfs_on_signal_off_switch_pending (false);

                // Setting to PinState.UNSPECIFIED retains existing data.
                // Selective sync excluded folders become VfsItemAvailability.ONLINE_ONLY.
                folder.root_pin_state (PinState.PinState.UNSPECIFIED);
                for (var entry : old_blocklist) {
                    folder.journal_database ().schedule_path_for_remote_discovery (entry);
                    if (!folder.vfs ().pin_state (entry, PinState.VfsItemAvailability.ONLINE_ONLY)) {
                        GLib.warning ("Could not set pin state of" + entry + "to online only";
                    }
                }
                folder.on_signal_next_sync_full_local_discovery ();

                FolderMan.instance ().schedule_folder (folder);

                this.ui.folder_list.do_items_layout ();
                this.ui.selective_sync_status.visible (false);
            }

            if (folder.is_sync_running ()) {
                *connection = connect (folder, &Folder.signal_sync_finished, this, switch_vfs_on);
                folder.vfs_on_signal_off_switch_pending (true);
                folder.on_signal_terminate_sync ();
                this.ui.folder_list.do_items_layout ();
            } else {
                switch_vfs_on ();
            }
        });
    }


    protected void on_signal_disable_vfs_current_folder () {
        FolderMan folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder_by_alias (selected_folder_alias ());
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        var msg_box = new QMessageBox (
            QMessageBox.Question,
            _("Disable virtual file support?"),
            _("This action will disable virtual file support. As a consequence contents of folders that "
               "are currently marked as \"available online only\" will be downloaded."
               "\n\n"
               "The only advantage of disabling virtual file support is that the selective sync feature "
               "will become available again."
               "\n\n"
               "This action will on_signal_abort any currently running synchronization."));
        var accept_button = msg_box.add_button (_("Disable support"), QMessageBox.AcceptRole);
        msg_box.add_button (_("Cancel"), QMessageBox.RejectRole);
        connect (msg_box, &QMessageBox.on_signal_finished, msg_box, [this, msg_box, folder, accept_button] {
            msg_box.delete_later ();
            if (msg_box.clicked_button () != accept_button|| !folder)
                return;

            // we might need to add or remove the panel entry as cfapi brings this feature out of the box
            FolderMan.instance ().navigation_pane_helper ().schedule_update_cloud_storage_registry ();

            // It is unsafe to switch off vfs while a sync is running - wait if necessary.
            var connection = std.make_shared<QMetaObject.Connection> ();
            var switch_vfs_off = [folder, connection, this] () {
                if (*connection)
                    GLib.Object.disconnect (*connection);

                GLib.info ("Disabling vfs support for folder" + folder.path ();

                // Also wipes virtual files, schedules remote discovery
                folder.virtual_files_enabled (false);
                folder.vfs_on_signal_off_switch_pending (false);

                // Wipe pin states and selective sync database
                folder.root_pin_state (PinState.PinState.ALWAYS_LOCAL);
                folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {});

                // Prevent issues with missing local files
                folder.on_signal_next_sync_full_local_discovery ();

                FolderMan.instance ().schedule_folder (folder);

                this.ui.folder_list.do_items_layout ();
            }

            if (folder.is_sync_running ()) {
                *connection = connect (folder, &Folder.signal_sync_finished, this, switch_vfs_off);
                folder.vfs_on_signal_off_switch_pending (true);
                folder.on_signal_terminate_sync ();
                this.ui.folder_list.do_items_layout ();
            } else {
                switch_vfs_off ();
            }
        });
        msg_box.open ();
    }


    protected void on_signal_current_folder_availability (PinState state) {
        //  ASSERT (state == PinState.VfsItemAvailability.ONLINE_ONLY || state == PinState.PinState.ALWAYS_LOCAL);

        FolderMan folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder_by_alias (selected_folder_alias ());
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        // similar to socket api : sets pin state recursively and sync
        folder.root_pin_state (state);
        folder.schedule_this_folder_soon ();
    }


    protected void on_signal_sub_folder_availability (Folder folder, string path, PinState state) {
        //  Q_ASSERT (folder && folder.virtual_files_enabled ());
        //  Q_ASSERT (!path.ends_with ('/'));

        // Update the pin state on all items
        if (!folder.vfs ().pin_state (path, state)) {
            GLib.warning ("Could not set pin state of" + path + "to" + state;
        }

        // Trigger sync
        folder.on_signal_schedule_path_for_local_discovery (path);
        folder.schedule_this_folder_soon ();
    }


    protected void on_signal_folder_wizard_accepted () {
        var folder_wizard = qobject_cast<FolderWizard> (sender ());
        FolderMan folder_man = FolderMan.instance ();

        GLib.info ("Folder wizard completed";

        FolderDefinition definition;
        definition.local_path = FolderDefinition.prepare_local_path (
            folder_wizard.field (QLatin1String ("source_folder")).to_string ());
        definition.target_path = FolderDefinition.prepare_target_path (
            folder_wizard.property ("target_path").to_string ());

        if (folder_wizard.property ("use_virtual_files").to_bool ()) {
            definition.virtual_files_mode = best_available_vfs_mode ();
        }
        {
            QDir directory (definition.local_path);
            if (!directory.exists ()) {
                GLib.info ("Creating folder" + definition.local_path;
                if (!directory.mkpath (".")) {
                    QMessageBox.warning (this, _("Folder creation failed"),
                        _("<p>Could not create local folder <i>%1</i>.</p>")
                            .arg (QDir.to_native_separators (definition.local_path)));
                    return;
                }
            }
            FileSystem.folder_minimum_permissions (definition.local_path);
            Utility.setup_fav_link (definition.local_path);
        }

        /***********************************************************
        take the value from the definition of already existing folders. All folders have
        the same setting so far.
        The default is to sync hidden files
        ***********************************************************/
        definition.ignore_hidden_files = folder_man.ignore_hidden_files ();

        if (folder_man.navigation_pane_helper ().show_in_explorer_navigation_pane ())
            definition.navigation_pane_clsid = QUuid.create_uuid ();

        var selective_sync_block_list = folder_wizard.property ("selective_sync_block_list").to_string_list ();

        folder_man.sync_enabled (true);

        Folder f = folder_man.add_folder (this.account_state, definition);
        if (f) {
            if (definition.virtual_files_mode != Vfs.Off && folder_wizard.property ("use_virtual_files").to_bool ())
                f.root_pin_state (PinState.VfsItemAvailability.ONLINE_ONLY);

            f.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, selective_sync_block_list);

            // The user already accepted the selective sync dialog. everything is in the allow list
            f.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
                string[] () + QLatin1String ("/"));
            folder_man.schedule_all_folders ();
            /* emit */ folder_changed ();
        }
    }


    protected void on_signal_folder_wizard_rejected () {
        GLib.info ("Folder wizard cancelled";
        FolderMan folder_man = FolderMan.instance ();
        folder_man.sync_enabled (true);
    }


    protected void on_signal_delete_account () {
        // Deleting the account potentially deletes 'this', so
        // the QMessageBox should be destroyed before that happens.
        var message_box = new QMessageBox (QMessageBox.Question,
            _("Confirm Account Removal"),
            _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
               "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                .arg (this.account_state.account ().display_name ()),
            QMessageBox.NoButton,
            this);
        var yes_button = message_box.add_button (_("Remove connection"), QMessageBox.YesRole);
        message_box.add_button (_("Cancel"), QMessageBox.NoRole);
        message_box.attribute (Qt.WA_DeleteOnClose);
        connect (message_box, &QMessageBox.on_signal_finished, this, [this, message_box, yes_button]{
            if (message_box.clicked_button () == yes_button) {
                // Else it might access during destruction. This should be better handled by it having a unowned
                this.model.account_state (null);

                var manager = AccountManager.instance ();
                manager.delete_account (this.account_state);
                manager.save ();
            }
        });
        message_box.open ();
    }


    protected void on_signal_toggle_sign_in_state () {
        if (this.account_state.is_signed_out ()) {
            this.account_state.account ().reset_rejected_certificates ();
            this.account_state.sign_in ();
        } else {
            this.account_state.sign_out_by_ui ();
        }
    }


    protected void on_signal_refresh_selective_sync_status () {
        string message;
        int count = 0;
        const var folders = FolderMan.instance ().map ().values ();
        this.ui.big_folder_ui.visible (false);
        for (Folder folder : folders) {
            if (folder.account_state () != this.account_state) {
                continue;
            }

            bool ok = false;
            const var undecided_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok);
            for (var it : undecided_list) {
                // FIXME : add the folder alias in a hoover hint.
                // folder.alias () + QLatin1String ("/")
                if (count++) {
                    message += QLatin1String (", ");
                }
                string my_folder = (it);
                if (my_folder.ends_with ('/')) {
                    my_folder.chop (1);
                }
                QModelIndex the_indx = this.model.index_for_path (folder, my_folder);
                if (the_indx.is_valid ()) {
                    message += string.from_latin1 ("<a href=\"%1?folder=%2\">%1</a>")
                               .arg (Utility.escape (my_folder), Utility.escape (folder.alias ()));
                } else {
                    message += my_folder; // no link because we do not know the index yet.
                }
            }
        }

        if (!message.is_empty ()) {
            ConfigFile config;
            string info = !config.confirm_external_storage ()
                    ? _("There are folders that were not synchronized because they are too big : ")
                    : !config.new_big_folder_size_limit ().first
                      ? _("There are folders that were not synchronized because they are external storages : ")
                      : _("There are folders that were not synchronized because they are too big or external storages : ");

            this.ui.selective_sync_notification.on_signal_text (info + message);
            this.ui.big_folder_ui.visible (true);
        }
    }


    protected void on_signal_mark_subfolder_encrypted (FolderStatusModel.SubFolderInfo folder_info) {
        if (!can_encrypt_or_decrypt (folder_info)) {
            return;
        }

        const var folder = folder_info.folder;
        //  Q_ASSERT (folder);

        const var folder_alias = folder.alias ();
        const var path = folder_info.path;
        const var file_id = folder_info.file_id;
        const var encrypt_folder = [this, file_id, path, folder_alias] {
            const var folder = FolderMan.instance ().folder_by_alias (folder_alias);
            if (!folder) {
                GLib.warning ("Could not encrypt folder because folder" + folder_alias + "does not exist anymore";
                QMessageBox.warning (null, _("Encryption failed"), _("Could not encrypt folder because the folder does not exist anymore"));
                return;
            }

            // Folder info have directory paths in Foo/Bar/ convention...
            //  Q_ASSERT (!path.starts_with ('/') && path.ends_with ('/'));
            // But EncryptFolderJob expects directory path Foo/Bar convention
            const var chopped_path = path.chopped (1);
            var job = new Occ.EncryptFolderJob (on_signal_accounts_state ().account (), folder.journal_database (), chopped_path, file_id, this);
            job.property (PROPERTY_FOLDER, GLib.Variant.from_value (folder));
            job.property (PROPERTY_PATH, GLib.Variant.from_value (path));
            connect (job, &Occ.EncryptFolderJob.on_signal_finished, this, &AccountSettings.on_signal_encrypt_folder_finished);
            job.on_signal_start ();
        }

        if (folder.virtual_files_enabled ()
            && folder.vfs ().mode () == Vfs.WindowsCfApi) {
            show_enable_e2ee_with_virtual_files_warning_dialog (encrypt_folder);
            return;
        }
        encrypt_folder ();
    }


    protected void on_signal_subfolder_context_menu_requested (QModelIndex index, QPoint position) {
        //  Q_UNUSED (position);

        QMenu menu;
        var ac = menu.add_action (_("Open folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_open_current_local_sub_folder);

        var filename = this.model.data (index, DataRole.FOLDER_PATH_ROLE).to_string ();
        if (!GLib.File.exists (filename)) {
            ac.enabled (false);
        }
        var info   = this.model.info_for_index (index);
        var acc = this.account_state.account ();

        if (acc.capabilities ().client_side_encryption_available ()) {
            // Verify if the folder is empty before attempting to encrypt.

            bool is_encrypted = info.is_encrypted;
            bool is_parent_encrypted = this.model.is_any_ancestor_encrypted (index);

            if (!is_encrypted && !is_parent_encrypted) {
                ac = menu.add_action (_("Encrypt"));
                connect (ac, &QAction.triggered, [this, info] {
                    on_signal_mark_subfolder_encrypted (info);
                });
            } else {
                // Ingore decrypting for now since it only works with an empty folder
                // connect (ac, &QAction.triggered, [this, info] {
                //    on_signal_mark_subfolder_decrypted (info);
                // });
            }
        }

        ac = menu.add_action (_("Edit Ignored Files"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_edit_current_local_ignored_files);

        ac = menu.add_action (_("Create new folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_open_make_folder_dialog);
        ac.enabled (GLib.File.exists (filename));

        const var folder = info.folder;
        if (folder && folder.virtual_files_enabled ()) {
            var availability_menu = menu.add_menu (_("Availability"));

            // Has '/' suffix convention for paths here but VFS and
            // sync engine expects no such suffix
            //  Q_ASSERT (info.path.ends_with ('/'));
            const var remote_path = info.path.chopped (1);

            // It might be an E2EE mangled path, so let's try to demangle it
            const var journal = folder.journal_database ();
            SyncJournalFileRecord record;
            journal.get_file_record_by_e2e_mangled_name (remote_path, record);

            const var path = record.is_valid () ? record.path : remote_path;

            ac = availability_menu.add_action (Utility.vfs_pin_action_text ());
            connect (ac, &QAction.triggered, this, [this, folder, path] {
                on_signal_sub_folder_availability (folder, path, PinState.PinState.ALWAYS_LOCAL);
            });

            ac = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            connect (ac, &QAction.triggered, this, [this, folder, path] {
                on_signal_sub_folder_availability (folder, path, PinState.VfsItemAvailability.ONLINE_ONLY);
            });
        }

        menu.exec (QCursor.position ());
    }


    protected void on_signal_custom_context_menu_requested (QPoint position) {
        QTreeView tv = this.ui.folder_list;
        QModelIndex index = tv.index_at (position);
        if (!index.is_valid ()) {
            return;
        }

        if (this.model.classify (index) == FolderStatusModel.ItemType.SUBFOLDER) {
            on_signal_subfolder_context_menu_requested (index, position);
            return;
        }

        if (this.model.classify (index) != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return;
        }

        tv.current_index (index);
        string alias = this.model.data (index, DataRole.FOLDER_ALIAS_ROLE).to_string ();
        bool folder_paused = this.model.data (index, DataRole.FOLDER_SYNC_PAUSED).to_bool ();
        bool folder_connected = this.model.data (index, DataRole.FOLDER_ACCOUNT_CONNECTED).to_bool ();
        var folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder_by_alias (alias);
        if (!folder)
            return;

        var menu = new QMenu (tv);

        menu.attribute (Qt.WA_DeleteOnClose);

        QAction ac = menu.add_action (_("Open folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_open_current_folder);

        ac = menu.add_action (_("Edit Ignored Files"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_edit_current_ignored_files);

        ac = menu.add_action (_("Create new folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_open_make_folder_dialog);
        ac.enabled (GLib.File.exists (folder.path ()));

        if (!this.ui.folder_list.is_expanded (index) && folder.supports_selective_sync ()) {
            ac = menu.add_action (_("Choose what to sync"));
            ac.enabled (folder_connected);
            connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_do_expand);
        }

        if (!folder_paused) {
            ac = menu.add_action (_("Force sync now"));
            if (folder && folder.is_sync_running ()) {
                ac.on_signal_text (_("Restart sync"));
            }
            ac.enabled (folder_connected);
            connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_force_sync_current_folder);
        }

        ac = menu.add_action (folder_paused ? _("Resume sync") : _("Pause sync"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_enable_current_folder);

        ac = menu.add_action (_("Remove folder sync connection"));
        connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_remove_current_folder);

        if (folder.virtual_files_enabled ()) {
            var availability_menu = menu.add_menu (_("Availability"));

            ac = availability_menu.add_action (Utility.vfs_pin_action_text ());
            connect (ac, &QAction.triggered, this, [this] () {
                on_signal_current_folder_availability (PinState.PinState.ALWAYS_LOCAL);
            });
            ac.disabled (Theme.instance ().enforce_virtual_files_sync_folder ());

            ac = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            connect (ac, &QAction.triggered, this, [this] () {
                on_signal_current_folder_availability (PinState.VfsItemAvailability.ONLINE_ONLY);
            });

            ac = menu.add_action (_("Disable virtual file support …"));
            connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_disable_vfs_current_folder);
            ac.disabled (Theme.instance ().enforce_virtual_files_sync_folder ());
        }

        if (Theme.instance ().show_virtual_files_option ()
            && !folder.virtual_files_enabled () && Vfs.check_availability (folder.path ())) {
            const var mode = best_available_vfs_mode ();
            if (mode == Vfs.WindowsCfApi || ConfigFile ().show_experimental_options ()) {
                ac = menu.add_action (_("Enable virtual file support %1 …").arg (mode == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
                // TODO : remove when UX decision is made
                ac.enabled (!Utility.is_path_windows_drive_partition_root (folder.path ()));
                //
                connect (ac, &QAction.triggered, this, &AccountSettings.on_signal_enable_vfs_current_folder);
            }
        }

        menu.popup (tv.map_to_global (position));
    }


    protected void on_signal_folder_list_clicked (QModelIndex index) {
        if (index.data (DataRole.ADD_BUTTON).to_bool ()) {
            // "Add Folder Sync Connection"
            QTreeView tv = this.ui.folder_list;
            var position = tv.map_from_global (QCursor.position ());
            QStyleOptionViewItem opt;
            opt.init_from (tv);
            var btn_rect = tv.visual_rect (index);
            var btn_size = tv.item_delegate (index).size_hint (opt, index);
            var actual = QStyle.visual_rect (opt.direction, btn_rect, QRect (btn_rect.top_left (), btn_size));
            if (!actual.contains (position))
                return;

            if (index.flags () & Qt.ItemIsEnabled) {
                on_signal_add_folder ();
            } else {
                QToolTip.show_text (
                    QCursor.position (),
                    this.model.data (index, Qt.ToolTipRole).to_string (),
                    this);
            }
            return;
        }
        if (this.model.classify (index) == FolderStatusModel.ItemType.ROOT_FOLDER) {
            // tries to find if we clicked on the '...' button.
            QTreeView tv = this.ui.folder_list;
            var position = tv.map_from_global (QCursor.position ());
            if (FolderStatusDelegate.options_button_rect (tv.visual_rect (index), layout_direction ()).contains (position)) {
                on_signal_custom_context_menu_requested (position);
                return;
            }
            if (FolderStatusDelegate.errors_list_rect (tv.visual_rect (index)).contains (position)) {
                /* emit */ show_issues_list (this.account_state);
                return;
            }

            // Expand root items on single click
            if (this.account_state && this.account_state.state () == AccountState.State.CONNECTED) {
                bool expanded = ! (this.ui.folder_list.is_expanded (index));
                this.ui.folder_list.expanded (index, expanded);
            }
        }
    }


    protected void on_signal_do_expand () {
        // Make sure at least the root items are expanded
        for (int i = 0; i < this.model.row_count (); ++i) {
            var index = this.model.index (i);
            if (!this.ui.folder_list.is_expanded (index))
                this.ui.folder_list.expanded (index, true);
        }
    }


    protected void on_signal_link_activated (string link) {
        // Parse folder alias and filename from the link, calculate the index
        // and select it if it exists.
        const string[] li = link.split (QLatin1String ("?folder="));
        if (li.count () > 1) {
            string my_folder = li[0];
            const string alias = li[1];
            if (my_folder.ends_with ('/'))
                my_folder.chop (1);

            // Make sure the folder itself is expanded
            Folder f = FolderMan.instance ().folder_by_alias (alias);
            QModelIndex folder_indx = this.model.index_for_path (f, "");
            if (!this.ui.folder_list.is_expanded (folder_indx)) {
                this.ui.folder_list.expanded (folder_indx, true);
            }

            QModelIndex index = this.model.index_for_path (f, my_folder);
            if (index.is_valid ()) {
                // make sure all the parents are expanded
                for (var i = index.parent (); i.is_valid (); i = i.parent ()) {
                    if (!this.ui.folder_list.is_expanded (i)) {
                        this.ui.folder_list.expanded (i, true);
                    }
                }
                this.ui.folder_list.selection_mode (QAbstractItemView.SingleSelection);
                this.ui.folder_list.current_index (index);
                this.ui.folder_list.scroll_to (index);
            } else {
                GLib.warning ("Unable to find a valid index for " + my_folder;
            }
        }
    }


    // Encryption Related Stuff.
    protected void on_signal_show_mnemonic (string mnemonic) {
        AccountManager.instance ().on_signal_display_mnemonic (mnemonic);
    }


    // Encryption Related Stuff.
    protected void on_signal_new_mnemonic_generated () {
        this.ui.encryption_message.on_signal_text (_("This account supports end-to-end encryption"));

        var mnemonic = new QAction (_("Enable encryption"), this);
        connect (mnemonic, &QAction.triggered, this, &AccountSettings.request_mnemonic);
        connect (mnemonic, &QAction.triggered, this.ui.encryption_message, &KMessageWidget.hide);

        this.ui.encryption_message.add_action (mnemonic);
        this.ui.encryption_message.show ();
    }


    // Encryption Related Stuff.
    protected void on_signal_encrypt_folder_finished (int status) {
        GLib.info ("Current folder encryption status code:" + status;
        var job = qobject_cast<EncryptFolderJob> (sender ());
        //  Q_ASSERT (job);
        if (!job.error_string ().is_empty ()) {
            QMessageBox.warning (null, _("Warning"), job.error_string ());
        }

        const var folder = job.property (PROPERTY_FOLDER).value<Folder> ();
        //  Q_ASSERT (folder);
        const var path = job.property (PROPERTY_PATH).value<string> ();
        const var index = this.model.index_for_path (folder, path);
        //  Q_ASSERT (index.is_valid ());
        this.model.reset_and_fetch (index.parent ());

        job.delete_later ();
    }


    protected void on_signal_selective_sync_changed (
        QModelIndex top_left, QModelIndex bottom_right,
        GLib.Vector<int> roles) {
        //  Q_UNUSED (bottom_right);
        if (!roles.contains (Qt.CheckStateRole)) {
            return;
        }

        const var info = this.model.info_for_index (top_left);
        if (!info) {
            return;
        }

        const bool show_warning = this.model.is_dirty () && this.account_state.is_connected () && info.checked == Qt.Unchecked;

        // FIXME : the model is not precise enough to handle extra cases
        // e.g. the user clicked on the same checkbox 2x without applying the change in between.
        // We don't know which checkbox changed to be able to toggle the selective_sync_label display.
        if (show_warning) {
            this.ui.selective_sync_label.show ();
        }

        const bool should_be_visible = this.model.is_dirty ();
        const bool was_visible = this.ui.selective_sync_status.is_visible ();
        if (should_be_visible) {
            this.ui.selective_sync_status.visible (true);
        }

        this.ui.selective_sync_apply.enabled (true);
        this.ui.selective_sync_buttons.visible (true);

        if (should_be_visible != was_visible) {
            const var hint = this.ui.selective_sync_status.size_hint ();

            if (should_be_visible) {
                this.ui.selective_sync_status.maximum_height (0);
            }

            const var anim = new QPropertyAnimation (this.ui.selective_sync_status, "maximum_height", this.ui.selective_sync_status);
            anim.end_value (this.model.is_dirty () ? hint.height () : 0);
            anim.on_signal_start (QAbstractAnimation.DeleteWhenStopped);
            connect (anim, &QPropertyAnimation.on_signal_finished, [this, should_be_visible] () {
                this.ui.selective_sync_status.maximum_height (QWIDGETSIZE_MAX);
                if (!should_be_visible) {
                    this.ui.selective_sync_status.hide ();
                }
            });
        }
    }


    /***********************************************************
    ***********************************************************/
    private void show_connection_label (string message,
        string[] errors = string[] ()) {
        const string err_style = QLatin1String ("color:#ffffff; background-color:#bb4d4d;padding:5px;"
                                                "border-width : 1px; border-style : solid; border-color : #aaaaaa;"
                                                "border-radius:5px;");
        if (errors.is_empty ()) {
            string message = message;
            Theme.replace_link_color_string_background_aware (message);
            this.ui.connect_label.on_signal_text (message);
            this.ui.connect_label.tool_tip ("");
            this.ui.connect_label.style_sheet ("");
        } else {
            errors.prepend (message);
            string message = errors.join (QLatin1String ("\n"));
            GLib.debug () + message;
            Theme.replace_link_color_string (message, Gtk.Color ("#c1c8e6"));
            this.ui.connect_label.on_signal_text (message);
            this.ui.connect_label.tool_tip ("");
            this.ui.connect_label.style_sheet (err_style);
        }
        this.ui.account_status.visible (!message.is_empty ());
    }


    /***********************************************************
    ***********************************************************/
    private bool event (QEvent e) {
        if (e.type () == QEvent.Hide || e.type () == QEvent.Show) {
            this.user_info.active (is_visible ());
        }
        if (e.type () == QEvent.Show) {
            // Expand the folder automatically only if there's only one, see #4283
            // The 2 is 1 folder + 1 'add folder' button
            if (this.model.row_count () <= 2) {
                this.ui.folder_list.expanded (this.model.index (0, 0), true);
            }
        }
        return Gtk.Widget.event (e);
    }


    /***********************************************************
    ***********************************************************/
    private void create_account_toolbox ();


    /***********************************************************
    ***********************************************************/
    private void open_ignored_files_dialog (string abs_folder_path) {
        //  Q_ASSERT (GLib.FileInfo (abs_folder_path).is_absolute ());

        const string ignore_file = abs_folder_path + ".sync-exclude.lst";
        var layout = new QVBoxLayout ();
        var ignore_list_widget = new IgnoreListTableWidget (this);
        ignore_list_widget.read_ignore_file (ignore_file);
        layout.add_widget (ignore_list_widget);

        var button_box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel);
        layout.add_widget (button_box);

        var dialog = new Gtk.Dialog ();
        dialog.layout (layout);

        connect (button_box, &QDialogButtonBox.clicked, [=] (QAbstractButton * button) {
            if (button_box.button_role (button) == QDialogButtonBox.AcceptRole)
                ignore_list_widget.on_signal_write_ignore_file (ignore_file);
            dialog.close ();
        });
        connect (button_box, &QDialogButtonBox.rejected,
                dialog,    &Gtk.Dialog.close);

        dialog.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        string message = this.ui.connect_label.text ();
        Theme.replace_link_color_string_background_aware (message);
        this.ui.connect_label.on_signal_text (message);

        Gtk.Color color = palette ().highlight ().color ();
        this.ui.quota_progress_bar.style_sheet (string.from_latin1 (PROGRESS_BAR_STYLE_C).arg (color.name ()));
    }


    /***********************************************************
    Returns the alias of the selected folder, empty string if none
    ***********************************************************/
    private string selected_folder_alias () {
        QModelIndex selected = this.ui.folder_list.selection_model ().current_index ();
        if (!selected.is_valid ())
            return "";
        return this.model.data (selected, DataRole.FOLDER_ALIAS_ROLE).to_string ();
    }


    private static void show_enable_e2ee_with_virtual_files_warning_dialog (std.function<void (void)> on_signal_accept) {
        const var message_box = new QMessageBox;
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.on_signal_text (AccountSettings._("End-to-End Encryption with Virtual Files"));
        message_box.informative_text (AccountSettings._("You seem to have the Virtual Files feature enabled on this folder. "
                                                           "At the moment, it is not possible to implicitly download virtual files that are "
                                                           "End-to-End encrypted. To get the best experience with Virtual Files and "
                                                           "End-to-End Encryption, make sure the encrypted folder is marked with "
                                                           "\"Make always available locally\"."));
        message_box.icon (QMessageBox.Warning);
        const var dont_encrypt_button = message_box.add_button (QMessageBox.StandardButton.Cancel);
        //  Q_ASSERT (dont_encrypt_button);
        dont_encrypt_button.on_signal_text (AccountSettings._("Don't encrypt folder"));
        const var encrypt_button = message_box.add_button (QMessageBox.StandardButton.Ok);
        //  Q_ASSERT (encrypt_button);
        encrypt_button.on_signal_text (AccountSettings._("Encrypt folder"));
        GLib.Object.connect (message_box, &QMessageBox.accepted, on_signal_accept);

        message_box.open ();
    }

} // class AccountSettingss

} // namespace Ui
} // namespace Occ
