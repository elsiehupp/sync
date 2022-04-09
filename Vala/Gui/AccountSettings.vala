namespace Occ {
namespace Ui {

/***********************************************************
@class AccountSettings

@brief The AccountSettings class

@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class AccountSettings : Gtk.Widget {

    /***********************************************************
    @class MouseCursorChanger

    Adjusts the mouse cursor based on the region it is on over
    the folder_connection tree view.

    Used to show that one can click the red error list box by
    changing the cursor to the pointing hand.
    ***********************************************************/
    class MouseCursorChanger : GLib.Object {

        public GLib.TreeView folder_list;
        public FolderStatusModel model;

        public MouseCursorChanger (GLib.Object parent) {
            base (parent);
        }


        protected override bool event_filter (GLib.Object watched, GLib.Event event) {
            if (event.type () == GLib.Event.HoverMove) {
                Qt.CursorShape shape = Qt.ArrowCursor;
                var position = folder_list.map_from_global (GLib.Cursor.position ());
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


    private const string PROPERTY_FOLDER = "folder_connection";
    private const string PROPERTY_PATH = "path";


    /***********************************************************
    ***********************************************************/
    private const string PROGRESS_BAR_STYLE_C
        = "GLib.ProgressBar {"
        + "border : 1px solid grey;"
        + "border-radius : 5px;"
        + "text-align : center;"
        + "}"
        + "GLib.ProgressBar.chunk {"
        + "background-color : %1; width : 1px;"
        + "}";


    /***********************************************************
    ***********************************************************/
    private AccountSettings instance;

    /***********************************************************
    ***********************************************************/
    private FolderStatusModel model;
    private GLib.Uri ocs_server_url;
    private bool was_disabled_before;
    private AccountState account_state;
    private UserInfo user_info;
    private GLib.Action toggle_sign_in_out_action;
    private GLib.Action add_account_action;

    /***********************************************************
    ***********************************************************/
    private bool menu_shown;


    internal signal void signal_folder_changed ();
    internal signal void signal_open_folder_alias (string value);
    internal signal void signal_show_issues_list (AccountState account);
    internal signal void signal_request_mnemonic ();
    internal signal void signal_remove_account_folders (AccountState account);
    internal signal void signal_style_changed ();


    /***********************************************************
    ***********************************************************/
    public AccountSettings (AccountState account_state, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new AccountSettings ();
        this.was_disabled_before = false;
        this.account_state = account_state;
        this.user_info = new UserInfo (account_state, false, true);
        this.menu_shown = false;
        this.instance.up_ui (this);

        this.model = new FolderStatusModel ();
        this.model.account_state = this.account_state;
        this.model.parent (this);
        var status_delegate = new FolderStatusDelegate ();
        status_delegate.parent (this);

        // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            status_delegate.on_signal_style_changed
        );

        this.instance.folder_list.header ().hide ();
        this.instance.folder_list.item_delegate (status_delegate);
        this.instance.folder_list.model (this.model);
        this.instance.folder_list.minimum_width (300);
        new ToolTipUpdater (this.instance.folder_list);

        var mouse_cursor_changer = new MouseCursorChanger (this);
        mouse_cursor_changer.folder_list = this.instance.folder_list;
        mouse_cursor_changer.model = this.model;
        this.instance.folder_list.mouse_tracking (true);
        this.instance.folder_list.attribute (Qt.WA_Hover, true);
        this.instance.folder_list.install_event_filter (mouse_cursor_changer);

        this.signal_remove_account_folders.connect (
            AccountManager.instance.signal_remove_account_folders
        );
        this.instance.folder_list.custom_context_menu_requested.connect (
            this.on_signal_custom_context_menu_requested
        );
        this.instance.folder_list.clicked.connect (
            this.on_signal_folder_list_clicked
        );
        this.instance.folder_list.expanded.connect (
            this.on_signal_refresh_selective_sync_status
        );
        this.instance.folder_list.collapsed.connect (
            this.on_signal_refresh_selective_sync_status
        );
        this.instance.selective_sync_notification.link_activated.connect (
            this.on_signal_link_activated
        );
        this.model.suggest_expand.connect (
            this.instance.folder_list.expand
        );
        this.model.dirty_changed.connect (
            this.on_signal_refresh_selective_sync_status
        );
        on_signal_refresh_selective_sync_status ();
        this.model.rows_inserted.connect (
            this.on_signal_refresh_selective_sync_status
        );

        var sync_now_action = new GLib.Action (this);
        sync_now_action.shortcut (GLib.KeySequence (Qt.Key_F6));
        sync_now_action.triggered.connect (
            this.on_signal_schedule_current_folder
        );
        add_action (sync_now_action);

        var sync_now_with_remote_discovery = new GLib.Action (this);
        sync_now_with_remote_discovery.shortcut (GLib.KeySequence (Qt.CTRL + Qt.Key_F6));
        sync_now_with_remote_discovery.triggered.connect (
            this.on_signal_schedule_current_folder_force_remote_discovery
        );
        add_action (sync_now_with_remote_discovery);

        on_signal_hide_selective_sync_widget ();
        this.instance.big_folder_ui.visible (false);
        this.model.data_changed.connect (
            this.on_signal_selective_sync_changed
        );
        this.instance.selective_sync_apply.clicked.connect (
            this.on_signal_hide_selective_sync_widget
        );
        this.instance.selective_sync_cancel.clicked.connect (
            this.on_signal_hide_selective_sync_widget
        );
        this.instance.selective_sync_apply.clicked.connect (
            this.model.on_signal_apply_selective_sync
        );
        this.instance.selective_sync_cancel.clicked.connect (
            this.model.on_signal_reset_folders
        );
        this.instance.big_folder_apply.clicked.connect (
            this.model.on_signal_apply_selective_sync
        );
        this.instance.big_folder_sync_all.clicked.connect (
            this.model.on_signal_sync_all_pending_big_folders
        );
        this.instance.big_folder_sync_none.clicked.connect (
            this.model.on_signal_sync_no_pending_big_folders
        );

        FolderManager.instance.signal_folder_list_changed.connect (
            this.model.on_signal_reset_folders
        );
        this.signal_folder_changed.connect (
            this.model.on_signal_reset_folders
        );

        // quota_progress_bar style now set in customize_style ()
        /*Gdk.RGBA color = palette ().highlight ().color ();
         this.instance.quota_progress_bar.style_sheet (PROGRESS_BAR_STYLE_C.printf (color.name ()));*/

        // Connect E2E stuff
        this.signal_request_mnemonic.connect (
            this.account_state.account.e2e.on_signal_request_mnemonic
        );
        this.account_state.account.e2e.show_mnemonic.connect (
            this.on_signal_show_mnemonic
        );
        this.account_state.account.e2e.mnemonic_generated.connect (
            this.on_signal_new_mnemonic_generated
        );

        if (this.account_state.account.e2e.new_mnemonic_generated ()) {
            on_signal_new_mnemonic_generated ();
        } else {
            this.instance.encryption_message.text (_("This account supports end-to-end encryption"));

            var mnemonic = new GLib.Action (_("Display mnemonic"), this);
            mnemonic.triggered.connect (
                this.signal_request_mnemonic
            );
            this.instance.encryption_message.add_action (mnemonic);
            this.instance.encryption_message.hide ();
        }

        this.instance.connect_label.text (_("No account configured."));

        this.account_state.signal_state_changed.connect (
            this.on_signal_account_state_changed
        );
        on_signal_account_state_changed ();

        this.user_info.quota_updated.connect (
            this.on_signal_quota_updated
        );

        customize_style ();
    }


    ~AccountSettings () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public override Gdk.Rectangle size_hint () {
        return OwncloudGui.settings_dialog_size ();
    }


    /***********************************************************
    ***********************************************************/
    public bool can_encrypt_or_decrypt (FolderStatusModel.SubFolderInfo info) {
        if (info.folder_connection.sync_result.status () != SyncResult.Status.SUCCESS) {
            Gtk.MessageBox message_box;
            message_box.on_signal_text ("Please wait for the folder_connection to sync before trying to encrypt it.");
            message_box.exec ();
            return false;
        }

        // for some reason the actual folder_connection in disk is info.folder_connection.path + info.path.
        GLib.Dir folder_path = new GLib.Dir (info.folder_connection.path + info.path);
        folder_path.filter ( GLib.Dir.AllEntries | GLib.Dir.NoDotAndDotDot );

        if (folder_path.length != 0) {
            Gtk.MessageBox message_box;
            message_box.text (_("You cannot encrypt a folder_connection with contents, please remove the files.\n"
                                    + "Wait for the new sync, then encrypt it."));
            message_box.exec ();
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_oc () {
        if (GLib.Uri.is_valid (this.ocs_server_url)) {
            OpenExternal.open_browser (this.ocs_server_url);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_quota_updated (int64 total, int64 used) {
        if (total > 0) {
            this.instance.quota_progress_bar.visible (true);
            this.instance.quota_progress_bar.enabled (true);
            // workaround the label only accepting ints (which may be only 32 bit wide)
            double percent = used / (double)total * 100;
            int percent_int = q_min (q_round (percent), 100);
            this.instance.quota_progress_bar.value (percent_int);
            string used_str = Utility.octets_to_string (used);
            string total_str = Utility.octets_to_string (total);
            string percent_str = Utility.compact_format_double (percent, 1);
            string tool_tip = _("%1 (%3%) of %2 in use. Some folders, including network mounted or shared folders, might have different limits.").printf (used_str, total_str, percent_str);
            this.instance.quota_info_label.text (_("%1 of %2 in use").printf (used_str, total_str));
            this.instance.quota_info_label.tool_tip (tool_tip);
            this.instance.quota_progress_bar.tool_tip (tool_tip);
        } else {
            this.instance.quota_progress_bar.visible (false);
            this.instance.quota_info_label.tool_tip ("");

            /* -1 means not computed; -2 means unknown; -3 means unlimited  (#owncloud/client/issues/3940)*/
            if (total == 0 || total == -1) {
                this.instance.quota_info_label.text (_("Currently there is no storage usage information available."));
            } else {
                string used_str = Utility.octets_to_string (used);
                this.instance.quota_info_label.text (_("%1 in use").printf (used_str));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_account_state_changed () {
        AccountState.State state = this.account_state != null ? this.account_state.state : AccountState.State.DISCONNECTED;
        if (state != AccountState.State.DISCONNECTED) {
            this.instance.ssl_button.update_account_state (this.account_state);
            unowned Account account = this.account_state.account;
            GLib.Uri safe_url = new GLib.Uri (account.url);
            safe_url.password (""); // Remove the password from the URL to avoid showing it in the UI
            foreach (FolderConnection folder_connection in FolderManager.instance.map ().values ()) {
                this.model.on_signal_update_folder_state (folder_connection);
            }

            const string server = "<a href=\"%1\">%2</a>"
                                .printf (
                                    Utility.escape (account.url.to_string ()),
                                    Utility.escape (safe_url.to_string ())
                                );
            string server_with_user = server;
            if (account.credentials ()) {
                string user = account.dav_display_name ();
                if (user == "") {
                    user = account.credentials ().user ();
                }
                server_with_user = _("%1 as %2").printf (server, Utility.escape (user));
            }

            switch (state) {
            case AccountState.State.CONNECTED: {
                GLib.List<string> errors;
                if (account.server_version_unsupported) {
                    errors += _("The server version %1 is unsupported! Proceed at your own risk.").printf (account.server_version ());
                }
                show_connection_label (_("Connected to %1.").printf (server_with_user), errors);
                break;
            }
            case AccountState.State.SERVICE_UNAVAILABLE:
                show_connection_label (_("Server %1 is temporarily unavailable.").printf (server));
                break;
            case AccountState.State.MAINTENANCE_MODE:
                show_connection_label (_("Server %1 is currently in maintenance mode.").printf (server));
                break;
            case AccountState.State.SIGNED_OUT:
                show_connection_label (_("Signed out from %1.").printf (server_with_user));
                break;
            case AccountState.State.ASKING_CREDENTIALS: {
                GLib.Uri url;
                var credentials = (HttpCredentialsGui) account.credentials ();
                if (credentials) {
                    credentials.signal_authorisation_link_changed.connect (
                        this.on_signal_account_state_changed
                    ); // Qt.UniqueConnection
                    url = credentials.authorisation_link ();
                }
                if (url.is_valid) {
                    show_connection_label (_("Obtaining authorization from the browser. "
                                           + "<a href='%1'>Click here</a> to re-open the browser.")
                                            .printf (url.to_string (GLib.Uri.FullyEncoded)));
                } else {
                    show_connection_label (_("Connecting to %1 …").printf (server_with_user));
                }
                break;
            }
            case AccountState.State.NETWORK_ERROR:
                show_connection_label (_("No connection to %1 at %2.")
                                        .printf (Utility.escape (Theme.app_name_gui), server),
                    this.account_state.connection_errors ());
                break;
            case AccountState.State.CONFIGURATION_ERROR:
                show_connection_label (_("Server configuration error : %1 at %2.")
                                        .printf (Utility.escape (Theme.app_name_gui), server),
                    this.account_state.connection_errors ());
                break;
            case AccountState.State.DISCONNECTED:
                // we can't end up here as the whole block is ifdeffed
                GLib.assert_not_reached ();
                break;
            }
        } else {
            // own_cloud is not yet configured.
            show_connection_label (_("No %1 connection configured.")
                                    .printf (Utility.escape (Theme.app_name_gui)));
        }

        /* Allow to expand the item if the account is connected. */
        this.instance.folder_list.items_expandable (state == AccountState.State.CONNECTED);

        if (state != AccountState.State.CONNECTED) {
            /* check if there are expanded root items, if so, close them */
            int i = 0;
            for (i = 0; i < this.model.row_count (); ++i) {
                if (this.instance.folder_list.is_expanded (this.model.index (i)))
                    this.instance.folder_list.expanded (this.model.index (i), false);
            }
        } else if (this.model.is_dirty) {
            // If we connect and have pending changes, show the list.
            on_signal_do_expand ();
        }

        // Disabling expansion of folders might require hiding the selective
        // sync user interface buttons.
        on_signal_refresh_selective_sync_status ();

        if (state == AccountState.State.Connected) {
            /* TODO: We should probably do something better here.
            Verify if the user has a private key already uploaded to the server,
            if it has, do not offer to create one.
             */
            GLib.info ("Account " + on_signal_accounts_state ().account.display_name
                      + " Client Side Encryption " + on_signal_accounts_state ().account.capabilities.client_side_encryption_available ());

            if (this.account_state.account.capabilities.client_side_encryption_available ()) {
                this.instance.encryption_message.show ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();

        // Notify the other widgets (Dark-/Light-Mode switching)
        /* emit */ signal_style_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public AccountState on_signal_accounts_state () {
        return this.account_state;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_hide_selective_sync_widget () {
        this.instance.selective_sync_apply.enabled (false);
        this.instance.selective_sync_status.visible (false);
        this.instance.selective_sync_buttons.visible (false);
        this.instance.selective_sync_label.hide ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_add_folder () {
        FolderManager.instance.sync_enabled = false; // do not on_signal_start more syncs.

        var folder_wizard = new FolderWizard (this.account_state.account, this);
        folder_wizard.attribute (Qt.WA_DeleteOnClose);

        folder_wizard.accepted.connect (
            this.on_signal_folder_wizard_accepted
        );
        folder_wizard.rejected.connect (
            this.on_signal_folder_wizard_rejected
        );

        folder_wizard.open ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_enable_current_folder (bool terminate = false) {
        var alias = selected_folder_alias ();

        if (alias != "") {
            GLib.info ("Application: enable folder_connection with alias " + alias);
            bool currently_paused = false;

            // this sets the folder_connection status to disabled but does not interrupt it.
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (alias);
            if (folder_connection == null) {
                return;
            }
            currently_paused = folder_connection.sync_paused;
            if (!currently_paused && !terminate) {
                // check if a sync is still running and if so, ask if we should terminate.
                if (folder_connection.is_busy ()) { // its still running
                    var msgbox = new Gtk.MessageBox (Gtk.MessageBox.Question, _("Sync Running"),
                        _("The syncing operation is running.<br/>Do you want to terminate it?"),
                        Gtk.MessageBox.Yes | Gtk.MessageBox.No, this);
                    msgbox.attribute (Qt.WA_DeleteOnClose);
                    msgbox.default_button (Gtk.MessageBox.Yes);
                    msgbox.accepted.connect (
                        on_signal_enable_current_folder (true)
                    );
                    msgbox.open ();
                    return;
                }
            }

            // message box can return at any time while the thread keeps running,
            // so better check again after the user has responded.
            if (folder_connection.is_busy () && terminate) {
                folder_connection.on_signal_terminate_sync ();
            }
            folder_connection.sync_paused = !currently_paused;

            // keep state for the icon setting.
            if (currently_paused)
                this.was_disabled_before = true;

            this.model.on_signal_update_folder_state (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_schedule_current_folder () {
        try {
            FolderManager.instance.folder_by_alias (selected_folder_alias ());
            FolderManager.instance.schedule_folder (
                FolderManager.instance.folder_by_alias (selected_folder_alias ())
            );
        } catch (FolderManagerError error) {
            GLib.warning ("Folder alias " + selected_folder_alias () + " does not exist.");
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_schedule_current_folder_force_remote_discovery () {
        try {
            FolderManager.instance.folder_by_alias (selected_folder_alias ()).on_signal_wipe_error_blocklist ();
            FolderManager.instance.folder_by_alias (selected_folder_alias ()).journal_database ().force_remote_discovery_next_sync ();
            FolderManager.instance.schedule_folder (
                FolderManager.instance.folder_by_alias (selected_folder_alias ())
            );
        } catch (FolderManagerError error) {
            GLib.warning ("Folder alias " + selected_folder_alias () + " does not exist.");
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_force_sync_current_folder () {
        try {
            // Terminate and reschedule any running sync
            foreach (var folder_connection in FolderManager.instance.map ()) {
                if (folder_connection.is_sync_running ()) {
                    folder_connection.on_signal_terminate_sync ();
                    FolderManager.instance.schedule_folder (folder_connection);
                }
            }

            FolderManager.instance.folder_by_alias (selected_folder_alias ()).on_signal_wipe_error_blocklist (); // issue #6757

            // Insert the selected folder_connection at the front of the queue
            FolderManager.instance.schedule_folder_next (FolderManager.instance.folder_by_alias (selected_folder_alias ()));
        } catch (FolderManagerError error) {

        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_remove_current_folder () {
        var folder_connection = FolderManager.instance.folder_by_alias (selected_folder_alias ());
        GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
        if (selected.is_valid && folder_connection) {
            int row = selected.row ();

            GLib.info ("Remove FolderConnection alias " + folder_connection.alias ());
            string short_gui_local_path = folder_connection.short_gui_local_path;

            var message_box = new Gtk.MessageBox (Gtk.MessageBox.Question,
                _("Confirm FolderConnection Sync Connection Removal"),
                _("<p>Do you really want to stop syncing the folder_connection <i>%1</i>?</p>"
                + "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                    .printf (short_gui_local_path),
                Gtk.MessageBox.NoButton,
                this);
            message_box.attribute (Qt.WA_DeleteOnClose);
            GLib.PushButton yes_button =
                message_box.add_button (_("Remove FolderConnection Sync Connection"), Gtk.MessageBox.YesRole);
            message_box.add_button (_("Cancel"), Gtk.MessageBox.NoRole);
            message_box.finished.connect (
                this.on_signal_finished
            );
            message_box.open ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_finished (Gtk.MessageBox message_box, GLib.PushButton yes_button, FolderConnection folder_connection, int row) {
        if (message_box.clicked_button () == yes_button) {
            Utility.remove_fav_link (folder_connection.path);
            FolderManager.instance.remove_folder (folder_connection);
            this.model.remove_row (row);

            // single folder_connection fix to show add-button and hide remove-button
            /* emit */ signal_folder_changed ();
        }
    }


    /***********************************************************
    Sync folder_connection
    ***********************************************************/
    protected void on_signal_open_current_folder () {
        if (selected_folder_alias () != "") {
            /* emit */ signal_open_folder_alias (alias);
        }
    }


    /***********************************************************
    Selected subfolder in sync folder_connection
    ***********************************************************/
    protected void on_signal_open_current_local_sub_folder () {
        GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
        if (!selected.is_valid || this.model.classify (selected) != FolderStatusModel.ItemType.SUBFOLDER) {
            return;
        }
        string filename = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
        GLib.Uri url = GLib.Uri.from_local_file (filename);
        GLib.DesktopServices.open_url (url);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_edit_current_ignored_files () {
        try {
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (selected_folder_alias ());
            open_ignored_files_dialog (folder_connection.path);
        } catch {

        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_make_folder_dialog () {
        var selected = this.instance.folder_list.selection_model ().current_index ();

        if (!selected.is_valid) {
            GLib.warning ("Selection model current folder_connection index is not valid.");
            return;
        }

        var classification = this.model.classify (selected);

        if (classification != FolderStatusModel.ItemType.SUBFOLDER && classification != FolderStatusModel.ItemType.ROOT_FOLDER) {
            return;
        }

        if (this.filename != "") {
            var folder_creation_dialog = new FolderCreationDialog (this.filename, this);
            folder_creation_dialog.attribute (Qt.WA_DeleteOnClose);
            folder_creation_dialog.open ();
        }
    }


    private void filename (int selected, FolderStatusModel.ItemType classification) {
        string result;
        if (classification == FolderStatusModel.ItemType.ROOT_FOLDER) {
            var alias = this.model.data (selected, DataRole.FOLDER_ALIAS_ROLE).to_string ();
            if (FolderManager.instance.folder_by_alias (alias)) {
                result = FolderManager.instance.folder_by_alias (alias).path;
            }
        } else {
            result = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
        }

        if (result.has_suffix ("/")) {
            result.chop (1);
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_edit_current_local_ignored_files () {
        GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
        if (!selected.is_valid || this.model.classify (selected) != FolderStatusModel.ItemType.SUBFOLDER)
            return;
        string filename = this.model.data (selected, DataRole.FOLDER_PATH_ROLE).to_string ();
        open_ignored_files_dialog (filename);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_enable_vfs_current_folder () {
        try {
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (selected_folder_alias ());
            GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
            if (!selected.is_valid) {
                return;
            }
            OwncloudWizard.ask_experimental_virtual_files_feature (this, on_ask (folder_connection, enable));
        } catch {

        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_ask (FolderConnection folder_connection, bool enable) {
        if (!enable) {
            return;
        }

        // we might need to add or remove the panel entry as cfapi brings this feature out of the box
        FolderManager.instance.navigation_pane_helper.schedule_update_cloud_storage_registry ();

        // It is unsafe to switch on vfs while a sync is running - wait if necessary.
        var connection = std.make_shared<GLib.Object.Connection> ();

        if (folder_connection.is_sync_running ()) {
            connection = connect (
                folder_connection, FolderConnection.signal_sync_finished,
                this, switch_vfs_on
            );
            folder_connection.vfs_on_signal_off_switch_pending (true);
            folder_connection.on_signal_terminate_sync ();
            this.instance.folder_list.do_items_layout ();
        } else {
            switch_vfs_on ();
        }
    }



    /***********************************************************
    ***********************************************************/
    private void switch_vfs_on (FolderConnection folder_connection, GLib.Object connection) {
        if (connection != null) {
            this.disconnect (connection);
        }

        GLib.info ("Enabling vfs support for folder_connection " + folder_connection.path);

        // Wipe selective sync blocklist
        bool ok = false;
        var old_blocklist = folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {});

        // Change the folder_connection vfs mode and load the plugin
        folder_connection.virtual_files_enabled = true;
        folder_connection.vfs_on_signal_off_switch_pending (false);

        // Setting to PinState.UNSPECIFIED retains existing data.
        // Selective sync excluded folders become Common.ItemAvailability.ONLINE_ONLY.
        folder_connection.root_pin_state (PinState.PinState.UNSPECIFIED);
        foreach (var entry in old_blocklist) {
            folder_connection.journal_database ().schedule_path_for_remote_discovery (entry);
            if (!folder_connection.vfs ().pin_state (entry, Common.ItemAvailability.ONLINE_ONLY)) {
                GLib.warning ("Could not set pin state of " + entry + " to online only.");
            }
        }
        folder_connection.on_signal_next_sync_full_local_discovery ();

        FolderManager.instance.schedule_folder (folder_connection);

        this.instance.folder_list.do_items_layout ();
        this.instance.selective_sync_status.visible (false);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_disable_vfs_current_folder () {
        try {
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (selected_folder_alias ());
            GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
            if (!selected.is_valid) {
                return;
            }

            var message_box = new Gtk.MessageBox (
                Gtk.MessageBox.Question,
                _("Disable virtual file support?"),
                _("This action will disable virtual file support. As a consequence contents of folders that "
                + "are currently marked as \"available online only\" will be downloaded."
                + "\n\n"
                + "The only advantage of disabling virtual file support is that the selective sync feature "
                + "will become available again."
                + "\n\n"
                + "This action will on_signal_abort any currently running synchronization."));
            var accept_button = message_box.add_button (_("Disable support"), Gtk.MessageBox.AcceptRole);
            message_box.add_button (_("Cancel"), Gtk.MessageBox.RejectRole);
            message_box.signal_finished.connect (
                this.on_signal_finished_for_vfs
            );
            message_box.open ();
        } catch {

        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished_for_vfs (Gtk.MessageBox message_box, FolderConnection folder_connection, Gtk.Button accept_button) {
        message_box.delete_later ();
        if (message_box.clicked_button () != accept_button||) {
            return;
        }

        // we might need to add or remove the panel entry as cfapi brings this feature out of the box
        FolderManager.instance.navigation_pane_helper.schedule_update_cloud_storage_registry ();

        // It is unsafe to switch off vfs while a sync is running - wait if necessary.
        var connection = std.make_shared<GLib.Object.Connection> ();


        if (folder_connection.is_sync_running ()) {
            connection = connect (
                folder_connection, FolderConnection.signal_sync_finished,
                this, switch_vfs_off
            );
            folder_connection.vfs_on_signal_off_switch_pending (true);
            folder_connection.on_signal_terminate_sync ();
            this.instance.folder_list.do_items_layout ();
        } else {
            switch_vfs_off ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void switch_vfs_off (FolderConnection folder_connection, GLib.Object connection) {
        if (connection != null) {
            disconnect (connection);
        }

        GLib.info ("Disabling vfs support for folder_connection " + folder_connection.path);

        // Also wipes virtual files, schedules remote discovery
        folder_connection.virtual_files_enabled = false;
        folder_connection.vfs_on_signal_off_switch_pending (false);

        // Wipe pin states and selective sync database
        folder_connection.root_pin_state (PinState.PinState.ALWAYS_LOCAL);
        folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {});

        // Prevent issues with missing local files
        folder_connection.on_signal_next_sync_full_local_discovery ();

        FolderManager.instance.schedule_folder (folder_connection);

        this.instance.folder_list.do_items_layout ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_current_folder_availability (PinState state) {
        //  ASSERT (state == Common.ItemAvailability.ONLINE_ONLY || state == PinState.PinState.ALWAYS_LOCAL);

        try {
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (selected_folder_alias ());
            GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
            if (!selected.is_valid) {
                return;
            }

            // similar to socket api : sets pin state recursively and sync
            folder_connection.root_pin_state (state);
            folder_connection.schedule_this_folder_soon ();
        } catch {

        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_sub_folder_availability (FolderConnection folder_connection, string path, PinState state) {
        //  Q_ASSERT (folder_connection && folder_connection.virtual_files_enabled ());
        //  Q_ASSERT (!path.has_suffix ("/"));

        // Update the pin state on all items
        if (!folder_connection.vfs.pin_state (path, state)) {
            GLib.warning ("Could not set pin state of " + path + " to " + state.to_string ());
        }

        // Trigger sync
        folder_connection.on_signal_schedule_path_for_local_discovery (path);
        folder_connection.schedule_this_folder_soon ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_folder_wizard_accepted () {
        var folder_wizard = (FolderWizard) sender ();

        GLib.info ("FolderConnection wizard completed.");

        FolderDefinition definition;
        definition.local_path = FolderDefinition.prepare_local_path (
            folder_wizard.field ("source_folder").to_string ());
        definition.target_path = FolderDefinition.prepare_target_path (
            folder_wizard.property ("target_path").to_string ());

        if (folder_wizard.property ("use_virtual_files").to_bool ()) {
            definition.virtual_files_mode = this.best_available_vfs_mode;
        }
        {
            GLib.Dir directory = new GLib.Dir (definition.local_path);
            if (!directory.exists ()) {
                GLib.info ("Creating folder_connection " + definition.local_path);
                if (!directory.mkpath (".")) {
                    Gtk.MessageBox.warning (this, _("FolderConnection creation failed"),
                        _("<p>Could not create local folder_connection <i>%1</i>.</p>")
                            .printf (GLib.Dir.to_native_separators (definition.local_path)));
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
        definition.ignore_hidden_files = FolderManager.instance.ignore_hidden_files;

        if (FolderManager.instance.navigation_pane_helper.show_in_explorer_navigation_pane) {
            definition.navigation_pane_clsid = GLib.Uuid.create_uuid ();
        }

        var selective_sync_block_list = folder_wizard.property ("selective_sync_block_list").to_string_list ();

        FolderManager.instance.sync_enabled = true;

        FolderConnection folder_connection = FolderManager.instance.add_folder (this.account_state, definition);
        if (folder_connection) {
            if (definition.virtual_files_mode != AbstractVfs.Off && folder_wizard.property ("use_virtual_files").to_bool ())
                folder_connection.root_pin_state (Common.ItemAvailability.ONLINE_ONLY);

            folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, selective_sync_block_list);

            // The user already accepted the selective sync dialog. everything is in the allow list
            folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, "/");
            FolderManager.instance.schedule_all_folders ();
            /* emit */ signal_folder_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_folder_wizard_rejected () {
        GLib.info ("FolderConnection wizard cancelled.");
        FolderManager.instance.sync_enabled = true;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_delete_account () {
        // Deleting the account potentially deletes 'this', so
        // the Gtk.MessageBox should be destroyed before that happens.
        var message_box = new Gtk.MessageBox (Gtk.MessageBox.Question,
            _("Confirm Account Removal"),
            _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
            + "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                .printf (this.account_state.account.display_name),
            Gtk.MessageBox.NoButton,
            this);
        var yes_button = message_box.add_button (_("Remove connection"), Gtk.MessageBox.YesRole);
        message_box.add_button (_("Cancel"), Gtk.MessageBox.NoRole);
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.signal_finished.connect (
            this.signal_finished_for_delete_account
        );
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void signal_finished_for_delete_account(Gtk.MessageBox message_box, Gtk.Button yes_button) {
        if (message_box.clicked_button () == yes_button) {
            // Else it might access during destruction. This should be better handled by it having a unowned
            this.model.account_state = null;

            var manager = AccountManager.instance;
            manager.delete_account (this.account_state);
            manager.save ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_toggle_sign_in_state () {
        if (this.account_state.is_signed_out) {
            this.account_state.account.reset_rejected_certificates ();
            this.account_state.sign_in ();
        } else {
            this.account_state.sign_out_by_ui ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_refresh_selective_sync_status () {
        string message;
        int count = 0;
        this.instance.big_folder_ui.visible (false);
        foreach (FolderConnection folder_connection in FolderManager.instance.map ().values ()) {
            if (folder_connection.account_state != this.account_state) {
                continue;
            }

            bool ok = false;
            var undecided_list = folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok);
            foreach (var item in undecided_list) {
                // FIXME: add the folder_connection alias in a hoover hint.
                // folder_connection.alias () + "/"
                if (count++) {
                    message += ", ";
                }
                string my_folder = item.to_string ();
                if (my_folder.has_suffix ("/")) {
                    my_folder.chop (1);
                }
                if (this.model.index_for_path (folder_connection, my_folder).is_valid) {
                    message += "<a href=\"%1?folder_connection=%2\">%1</a>"
                               .printf (
                                   Utility.escape (my_folder),
                                   Utility.escape (folder_connection.alias ())
                                );
                } else {
                    message += my_folder; // no link because we do not know the index yet.
                }
            }
        }

        if (message != "") {
            ConfigFile config;
            string info = !config.confirm_external_storage ()
                ? _("There are folders that were not synchronized because they are too big: ")
                : !config.new_big_folder_size_limit.first
                    ? _("There are folders that were not synchronized because they are external storages: ")
                    : _("There are folders that were not synchronized because they are too big or external storages: ");

            this.instance.selective_sync_notification.on_signal_text (info + message);
            this.instance.big_folder_ui.visible (true);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_mark_subfolder_encrypted (FolderStatusModel.SubFolderInfo folder_info) {
        if (!can_encrypt_or_decrypt (folder_info)) {
            return;
        }

        const var folder_connection = folder_info.folder_connection;
        //  Q_ASSERT (folder_connection);

        const var folder_alias = folder_connection.alias ();
        const var path = folder_info.path;
        const var file_id = folder_info.file_id;

        if (folder_connection.virtual_files_enabled ()
            && folder_connection.vfs ().mode () == AbstractVfs.WindowsCfApi) {
            show_enable_e2ee_with_virtual_files_warning_dialog (encrypt_folder);
            return;
        }
        encrypt_folder ();
    }


    /***********************************************************
    ***********************************************************/
    private void encrypt_folder (int file_id, string path, string folder_alias) {
        try {

            // FolderConnection info have directory paths in Foo/Bar/ convention...
            //  Q_ASSERT (!path.has_prefix ("/") && path.has_suffix ("/"));
            // But EncryptFolderJob expects directory path Foo/Bar convention
            var encrypt_folder_job = new EncryptFolderJob (
                on_signal_accounts_state ().account,
                folder_connection.journal_database (),
                path.chopped (1),
                file_id,
                this
            );
            encrypt_folder_job.property (PROPERTY_FOLDER, GLib.Variant.from_value (folder_connection));
            encrypt_folder_job.property (PROPERTY_PATH, GLib.Variant.from_value (path));
            encrypt_folder_job.signal_finished.connect (
                this.on_signal_encrypt_folder_finished
            );
            encrypt_folder_job.on_signal_start ();
        } catch (FolderManagerError error) {
            GLib.warning ("Could not encrypt folder_connection because folder_connection " + folder_alias + " does not exist anymore.");
            Gtk.MessageBox.warning (null, _("Encryption failed"), _("Could not encrypt folder_connection because the folder_connection does not exist anymore"));
            return;
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_subfolder_context_menu_requested (GLib.ModelIndex index, GLib.Point position) {
        //  Q_UNUSED (position);

        GLib.Menu menu;
        var open_folder_action = menu.add_action (_("Open folder_connection"));
        open_folder_action.triggered.connect (
            this.on_signal_open_current_local_sub_folder
        );

        var filename = this.model.data (index, DataRole.FOLDER_PATH_ROLE).to_string ();
        if (!GLib.File.exists (filename)) {
            open_folder_action.enabled (false);
        }
        var info   = this.model.info_for_index (index);
        var acc = this.account_state.account;

        if (acc.capabilities.client_side_encryption_available ()) {
            // Verify if the folder_connection is empty before attempting to encrypt.

            bool is_encrypted = info.is_encrypted;
            bool is_parent_encrypted = this.model.is_any_ancestor_encrypted (index);

            if (!is_encrypted && !is_parent_encrypted) {
                encrypt_action = menu.add_action (_("Encrypt"));
                encrypt_action.triggered.connect (
                    on_signal_mark_subfolder_encrypted
                );
            } else {
                // Ingore decrypting for now since it only works with an empty folder_connection
                encrypt_action.triggered.connect (
                    () => {
                        on_signal_mark_subfolder_decrypted (info);
                    }
                );
            }
        }

        edit_ignored_files_action = menu.add_action (_("Edit Ignored Files"));
        edit_ignored_files_action.triggered.connect (
            this.on_signal_edit_current_local_ignored_files
        );

        create_new_folder_action = menu.add_action (_("Create new folder_connection"));
        create_new_folder_action.triggered.connect (
            this.on_signal_open_make_folder_dialog
        );
        create_new_folder_action.enabled (GLib.File.exists (filename));

        if (info.folder_connection && folder_connection.virtual_files_enabled ()) {
            var availability_menu = menu.add_menu (_("Availability"));

            // Has "/" suffix convention for paths here but VFS and
            // sync engine expects no such suffix
            //  Q_ASSERT (info.path.has_suffix ("/"));
            const var remote_path = info.path.chopped (1);

            // It might be an E2EE mangled path, so let's try to demangle it
            const var journal = info.folder_connection.journal_database ();
            SyncJournalFileRecord record;
            journal.file_record_by_e2e_mangled_name (remote_path, record);

            const string path = record.is_valid ? record.path : remote_path;

            vfs_pin_action = availability_menu.add_action (Utility.vfs_pin_action_text ());
            vfs_pin_action.triggered.connect (
                this.on_signal_sub_folder_availability (info.folder_connection, path, PinState.PinState.ALWAYS_LOCAL)
            );

            vfs_free_space_action = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            vfs_free_space_action.triggered.connect (
                this.on_signal_sub_folder_availability (info.folder_connection, path, Common.ItemAvailability.ONLINE_ONLY)
            );
        }

        menu.exec (GLib.Cursor.position ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_custom_context_menu_requested (GLib.Point position) {
        GLib.TreeView tv = this.instance.folder_list;
        GLib.ModelIndex index = tv.index_at (position);
        if (!index.is_valid) {
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
        if (!FolderManager.instance.folder_by_alias (alias))
            return;

        var menu = new GLib.Menu (tv);

        menu.attribute (Qt.WA_DeleteOnClose);

        GLib.Action open_folder_action = menu.add_action (_("Open folder_connection"));
        open_folder_action.triggered.connect (
            this.on_signal_open_current_folder
        );

        edit_ignored_files_action = menu.add_action (_("Edit Ignored Files"));
        edit_ignored_files_action.triggered.connect (
            this.on_signal_edit_current_ignored_files
        );

        create_new_folder_action = menu.add_action (_("Create new folder_connection"));
        create_new_folder_action.triggered.connect (
            this.on_signal_open_make_folder_dialog
        );
        create_new_folder_action.enabled (GLib.File.exists (FolderManager.instance.folder_by_alias (alias).path));

        if (!this.instance.folder_list.is_expanded (index) && FolderManager.instance.folder_by_alias (alias).supports_selective_sync) {
            choose_what_to_sync_action = menu.add_action (_("Choose what to sync"));
            choose_what_to_sync_action.enabled (folder_connected);
            choose_what_to_sync_action.triggered.connect (
                this.on_signal_do_expand
            );
        }

        if (!folder_paused) {
            force_sync_now_action = menu.add_action (_("Force sync now"));
            if (FolderManager.instance.folder_by_alias (alias) && FolderManager.instance.folder_by_alias (alias).is_sync_running ()) {
                force_sync_now_action.text (_("Restart sync"));
            }
            force_sync_now_action.enabled (folder_connected);
            force_sync_now_action.triggered.connect (
                this.on_signal_force_sync_current_folder
            );
        }

        pause_resume_sync_action = menu.add_action (folder_paused ? _("Resume sync") : _("Pause sync"));
        pause_resume_sync_action.triggered.connect (
            this.on_signal_enable_current_folder
        );

        remove_folder_sync_connection_action = menu.add_action (_("Remove folder_connection sync connection"));
        remove_folder_sync_connection_action.triggered.connect (
            this.on_signal_remove_current_folder
        );

        if (FolderManager.instance.folder_by_alias (alias).virtual_files_enabled ()) {
            var availability_menu = menu.add_menu (_("Availability"));

            vfs_pin_action = availability_menu.add_action (Utility.vfs_pin_action_text ());
            vfs_pin_action.triggered.connect (
                this.on_signal_current_folder_availability (PinState.PinState.ALWAYS_LOCAL)
            );
            vfs_pin_action.disabled (Theme.enforce_virtual_files_sync_folder);

            vfs_free_space_action = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            vfs_free_space_action.triggered.connect (
                this.on_signal_current_folder_availability (Common.ItemAvailability.ONLINE_ONLY)
            );

            disable_vfs_action = menu.add_action (_("Disable virtual file support …"));
            disable_vfs_action.triggered.connect (
                this.on_signal_disable_vfs_current_folder
            );
            disable_vfs_action.disabled (Theme.enforce_virtual_files_sync_folder);
        }

        if (Theme.show_virtual_files_option
            && !FolderManager.instance.folder_by_alias (alias).virtual_files_enabled () && AbstractVfs.check_availability (FolderManager.instance.folder_by_alias (alias).path)) {
            var mode = this.best_available_vfs_mode;
            if (mode == AbstractVfs.WindowsCfApi || ConfigFile ().show_experimental_options ()) {
                ensable_vfs_action = menu.add_action (_("Enable virtual file support %1 …").printf (mode == AbstractVfs.WindowsCfApi ? "" : _(" (experimental)")));
                // TODO: remove when UX decision is made
                ensable_vfs_action.enabled (!Utility.is_path_windows_drive_partition_root (FolderManager.instance.folder_by_alias (alias).path));
                //
                ensable_vfs_action.triggered.connect (
                    this.on_signal_enable_vfs_current_folder
                );
            }
        }

        menu.popup (tv.map_to_global (position));
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_folder_list_clicked (GLib.ModelIndex index) {
        if (index.data (DataRole.ADD_BUTTON).to_bool ()) {
            // "Add FolderConnection Sync Connection"
            GLib.TreeView tv = this.instance.folder_list;
            var position = tv.map_from_global (GLib.Cursor.position ());
            GLib.StyleOptionViewItem opt;
            opt.init_from (tv);
            var btn_rect = tv.visual_rect (index);
            var btn_size = tv.item_delegate (index).size_hint (opt, index);
            var actual = GLib.Style.visual_rect (opt.direction, btn_rect, GLib.Rect (btn_rect.top_left (), btn_size));
            if (!actual.contains (position))
                return;

            if (index.flags () & Qt.ItemIsEnabled) {
                on_signal_add_folder ();
            } else {
                GLib.ToolTip.show_text (
                    GLib.Cursor.position (),
                    this.model.data (index, Qt.ToolTipRole).to_string (),
                    this);
            }
            return;
        }
        if (this.model.classify (index) == FolderStatusModel.ItemType.ROOT_FOLDER) {
            // tries to find if we clicked on the '...' button.
            GLib.TreeView tv = this.instance.folder_list;
            var position = tv.map_from_global (GLib.Cursor.position ());
            if (FolderStatusDelegate.options_button_rect (tv.visual_rect (index), layout_direction ()).contains (position)) {
                on_signal_custom_context_menu_requested (position);
                return;
            }
            if (FolderStatusDelegate.errors_list_rect (tv.visual_rect (index)).contains (position)) {
                /* emit */ on_signal_show_issues_list (this.account_state);
                return;
            }

            // Expand root items on single click
            if (this.account_state != null && this.account_state.state == AccountState.State.CONNECTED) {
                bool expanded = ! (this.instance.folder_list.is_expanded (index));
                this.instance.folder_list.expanded (index, expanded);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_do_expand () {
        // Make sure at least the root items are expanded
        for (int i = 0; i < this.model.row_count (); ++i) {
            var index = this.model.index (i);
            if (!this.instance.folder_list.is_expanded (index))
                this.instance.folder_list.expanded (index, true);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_link_activated (string link) {
        // Parse folder_connection alias and filename from the link, calculate the index
        // and select it if it exists.
        GLib.List<string> link_split = link.split ("?folder_connection=");
        if (link_split.length > 1) {
            string my_folder = link_split[0];
            string alias = link_split[1];
            if (my_folder.has_suffix ("/"))
                my_folder.chop (1);

            // Make sure the folder_connection itself is expanded
            FolderConnection folder_connection = FolderManager.instance.folder_by_alias (alias);
            GLib.ModelIndex folder_indx = this.model.index_for_path (folder_connection, "");
            if (!this.instance.folder_list.is_expanded (folder_indx)) {
                this.instance.folder_list.expanded (folder_indx, true);
            }

            GLib.ModelIndex index = this.model.index_for_path (folder_connection, my_folder);
            if (index.is_valid) {
                // make sure all the parents are expanded
                for (var i = index.parent (); i.is_valid; i = i.parent ()) {
                    if (!this.instance.folder_list.is_expanded (i)) {
                        this.instance.folder_list.expanded (i, true);
                    }
                }
                this.instance.folder_list.selection_mode (GLib.AbstractItemView.SingleSelection);
                this.instance.folder_list.current_index (index);
                this.instance.folder_list.scroll_to (index);
            } else {
                GLib.warning ("Unable to find a valid index for " + my_folder);
            }
        }
    }


    /***********************************************************
    Encryption Related Stuff
    ***********************************************************/
    protected void on_signal_show_mnemonic (string mnemonic) {
        AccountManager.instance.on_signal_display_mnemonic (mnemonic);
    }


    /***********************************************************
    Encryption Related Stuff
    ***********************************************************/
    protected void on_signal_new_mnemonic_generated () {
        this.instance.encryption_message.text (_("This account supports end-to-end encryption"));

        var mnemonic = new GLib.Action (_("Enable encryption"), this);
        mnemonic.triggered.connect (
            this.signal_request_mnemonic
        );
        mnemonic.triggered.connect (
            this.instance.encryption_message.hide
        );

        this.instance.encryption_message.add_action (mnemonic);
        this.instance.encryption_message.show ();
    }


    /***********************************************************
    Encryption Related Stuff
    ***********************************************************/
    protected void on_signal_encrypt_folder_finished (int status) {
        GLib.info ("Current folder_connection encryption status code: " + status.to_string ());
        var encrypt_folder_job = (EncryptFolderJob) sender ();
        //  Q_ASSERT (encrypt_folder_job);
        if (!encrypt_folder_job.error_string == "") {
            Gtk.MessageBox.warning (null, _("Warning"), encrypt_folder_job.error_string);
        }

        var folder_connection = encrypt_folder_job.property (PROPERTY_FOLDER).value<FolderConnection> ();
        //  Q_ASSERT (folder_connection);
        const int index = this.model.index_for_path (folder_connection, encrypt_folder_job.property (PROPERTY_PATH).value<string> ());
        //  Q_ASSERT (index.is_valid);
        this.model.reset_and_fetch (index.parent ());

        encrypt_folder_job.delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_selective_sync_changed (
        GLib.ModelIndex top_left,
        GLib.ModelIndex bottom_right,
        GLib.List<int> roles) {
        //  Q_UNUSED (bottom_right);
        if (!roles.contains (Qt.CheckStateRole)) {
            return;
        }

        var info = this.model.info_for_index (top_left);
        if (!info) {
            return;
        }

        // FIXME: the model is not precise enough to handle extra cases
        // e.g. the user clicked on the same checkbox 2x without applying the change in between.
        // We don't know which checkbox changed to be able to toggle the selective_sync_label display.
        if (this.model.is_dirty && this.account_state.is_connected && info.checked == Qt.Unchecked) {
            this.instance.selective_sync_label.show ();
        }

        bool should_be_visible = this.model.is_dirty;
        if (should_be_visible) {
            this.instance.selective_sync_status.visible (true);
        }

        this.instance.selective_sync_apply.enabled (true);
        this.instance.selective_sync_buttons.visible (true);

        if (should_be_visible != this.instance.selective_sync_status.is_visible ()) {

            if (should_be_visible) {
                this.instance.selective_sync_status.maximum_height (0);
            }

            const GLib.PropertyAnimation selective_sync_status_property_animation = new GLib.PropertyAnimation (this.instance.selective_sync_status, "maximum_height", this.instance.selective_sync_status);
            selective_sync_status_property_animation.end_value (this.model.is_dirty ? this.instance.selective_sync_status.size_hint ().height () : 0);
            selective_sync_status_property_animation.on_signal_start (GLib.AbstractAnimation.DeleteWhenStopped);
            selective_sync_status_property_animation.signal_finished.connect (
                this.on_signal_animation_finished
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_animation_finished (bool should_be_visible) {
        this.instance.selective_sync_status.maximum_height (GLib.WIDGETSIZE_MAX);
        if (!should_be_visible) {
            this.instance.selective_sync_status.hide ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void show_connection_label (
        string message,
        GLib.List<string> errors = new GLib.List<string> ()
    ) {
        const string err_style = "color: #ffffff; background-color: #bb4d4d; padding: 5px;"
                               + "border-width: 1px; border-style: solid; border-color: #aaaaaa;"
                               + "border-radius: 5px;";
        if (errors.length () == 0) {
            string message = message;
            Theme.replace_link_color_string_background_aware (message);
            this.instance.connect_label.on_signal_text (message);
            this.instance.connect_label.tool_tip ("");
            this.instance.connect_label.style_sheet ("");
        } else {
            errors.prepend (message);
            string message = errors.join ("\n");
            GLib.debug (message);
            Theme.replace_link_color_string (message, Gdk.RGBA ("#c1c8e6"));
            this.instance.connect_label.on_signal_text (message);
            this.instance.connect_label.tool_tip ("");
            this.instance.connect_label.style_sheet (err_style);
        }
        this.instance.account_status.visible (!message == "");
    }


    /***********************************************************
    ***********************************************************/
    private bool event (GLib.Event e) {
        if (e.type () == GLib.Event.Hide || e.type () == GLib.Event.Show) {
            this.user_info.active = is_visible ();
        }
        if (e.type () == GLib.Event.Show) {
            // Expand the folder_connection automatically only if there's only one, see #4283
            // The 2 is 1 folder_connection + 1 'add folder_connection' button
            if (this.model.row_count () <= 2) {
                this.instance.folder_list.expanded (this.model.index (0, 0), true);
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

        string ignore_file = abs_folder_path + ".sync-exclude.lst";
        var layout = new GLib.VBoxLayout ();
        var ignore_list_widget = new IgnoreListTableWidget (this);
        ignore_list_widget.read_ignore_file (ignore_file);
        layout.add_widget (ignore_list_widget);

        var button_box = new GLib.DialogButtonBox (GLib.DialogButtonBox.Ok | GLib.DialogButtonBox.Cancel);
        layout.add_widget (button_box);

        var dialog = new Gtk.Dialog ();
        dialog.layout (layout);

        button_box.clicked.connect (
            on_clicked
        );
        button_box.rejected.connect (
            dialog.close
        );

        dialog.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_clicked (GLib.AbstractButton button) {
        if (button_box.button_role (button) == GLib.DialogButtonBox.AcceptRole) {
            ignore_list_widget.on_signal_write_ignore_file (ignore_file);
        }
        dialog.close ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        string message = this.instance.connect_label.text ();
        Theme.replace_link_color_string_background_aware (message);
        this.instance.connect_label.on_signal_text (message);

        Gdk.RGBA color = palette ().highlight ().color ();
        this.instance.quota_progress_bar.style_sheet (PROGRESS_BAR_STYLE_C.printf (color.name ()));
    }


    /***********************************************************
    Returns the alias of the selected folder_connection, empty string if none
    ***********************************************************/
    private string selected_folder_alias () {
        GLib.ModelIndex selected = this.instance.folder_list.selection_model ().current_index ();
        if (!selected.is_valid)
            return "";
        return this.model.data (selected, DataRole.FOLDER_ALIAS_ROLE).to_string ();
    }


    private delegate void OnSignalAccept ();


    /***********************************************************
    ***********************************************************/
    private static void show_enable_e2ee_with_virtual_files_warning_dialog (OnSignalAccept on_signal_accept) {
        const var message_box = new Gtk.MessageBox ();
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.text (_("End-to-End Encryption with Virtual Files"));
        message_box.informative_text (_("You seem to have the Virtual Files feature enabled on this folder_connection. "
                                                      + "At the moment, it is not possible to implicitly download virtual files that are "
                                                      + "End-to-End encrypted. To get the best experience with Virtual Files and "
                                                      + "End-to-End Encryption, make sure the encrypted folder_connection is marked with "
                                                      + "\"Make always available locally\"."));
        message_box.icon (Gtk.MessageBox.Warning);
        const Gtk.Button dont_encrypt_button = message_box.add_button (Gtk.MessageBox.StandardButton.Cancel);
        //  Q_ASSERT (dont_encrypt_button);
        dont_encrypt_button.text (_("Don't encrypt folder_connection"));
        const Gtk.Button encrypt_button = message_box.add_button (Gtk.MessageBox.StandardButton.Ok);
        //  Q_ASSERT (encrypt_button);
        encrypt_button.text (_("Encrypt folder_connection"));
        message_box.accepted.connect (
            this.on_signal_accept
        );

        message_box.open ();
    }

} // class AccountSettingss

} // namespace Ui
} // namespace Occ
