/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@author Krzesimir Nowak <krzesimir@endocode.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>
//  #include <GLib.FileDialog>
//  #include <GLib.StorageInfo>
//  #include <Gtk.MessageBox>
//  #include <Json.Object>
//  #include <folderman.h>

//  #include <GLib.Wizard>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudAdvancedSetupPage class
@ingroup gui
***********************************************************/
public class OwncloudAdvancedSetupPage : GLib.WizardPage {

    /***********************************************************
    ***********************************************************/
    private Owncloude_advanced_setup_page instance;
    private bool checking = false;
    private bool created = false;
    private bool local_folder_valid = false;
    private GLib.ProgressIndicator progress_indicator;
    private string remote_folder;
    public GLib.List<string> selective_sync_blocklist { public get; private set; }
    private int64 r_size = -1;
    private int64 r_selected_size = -1;
    private OwncloudWizard oc_wizard;


    internal signal void create_local_and_remote_folders (string value1, string value2);


    /***********************************************************
    ***********************************************************/
    public OwncloudAdvancedSetupPage (OwncloudWizard wizard) {
        base ();
        this.progress_indicator = new GLib.ProgressIndicator (this);
        this.oc_wizard = wizard;
        this.instance.up_ui (this);

        set_up_resolution_widget ();

        register_field ("OCSync_from_scratch", this.instance.cb_sync_from_scratch);

        var size_policy = this.progress_indicator.size_policy ();
        size_policy.retain_size_when_hidden (true);
        this.progress_indicator.size_policy (size_policy);

        this.instance.result_layout.add_widget (this.progress_indicator);
        on_signal_stop_spinner ();
        set_up_customization ();

        this.instance.pb_select_local_folder.clicked.connect (
            this.on_signal_select_folder
        );
        button_text (GLib.Wizard.FinishButton, _("Connect"));

        if (Theme.enforce_virtual_files_sync_folder) {
            this.instance.r_sync_everything.disabled (true);
            this.instance.r_selective_sync.disabled (true);
            this.instance.b_selective_sync.disabled (true);
        }

        this.instance.r_sync_everything.clicked.connect (
            this.on_signal_sync_everything_clicked
        );
        this.instance.r_selective_sync.clicked.connect (
            this.on_signal_selective_sync_clicked
        );
        this.instance.r_virtual_file_sync.clicked.connect (
            this.on_signal_virtual_file_sync_clicked
        );
        this.instance.r_virtual_file_sync.toggled.connect (
            this.on_virtual_file_sync_toggled
        );
        this.instance.b_selective_sync.clicked.connect (
            this.on_signal_selective_sync_clicked
        );

        Theme theme = Theme.instance;
        Gtk.Icon app_icon = theme.application_icon;
        int app_icon_size = Theme.is_hidpi () ? 128 : 64;

        this.instance.l_server_icon.pixmap (app_icon.pixmap (app_icon_size));

        if (theme.wizard_hide_external_storage_confirmation_checkbox) {
            this.instance.conf_check_box_external.hide ();
        }
        if (theme.wizard_hide_folder_size_limit_checkbox) {
            this.instance.conf_check_box_size.hide ();
            this.instance.conf_spin_box.hide ();
            this.instance.conf_trailling_size_label.hide ();
        }

        this.instance.r_virtual_file_sync.on_signal_text (_("Use virtual files instead of downloading content immediately %1").printf (this.best_available_vfs_mode == AbstractVfs.WindowsCfApi ? "" : _(" (experimental)")));
    }


    private void on_virtual_file_sync_toggled (bool checked) {
        if (checked) {
            this.instance.l_selective_sync_size_label == "";
            this.selective_sync_blocklist == "";
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete {
        public get {
            return !this.checking && this.local_folder_valid;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        WizardCommon.init_error_label (this.instance.error_label);

        if (!Theme.show_virtual_files_option || this.best_available_vfs_mode == AbstractVfs.Off) {
            // If the layout were wrapped in a widget, the var-grouping of the
            // radio buttons no longer works and there are surprising margins.
            // Just manually hide the button and remove the layout.
            this.instance.r_virtual_file_sync.hide ();
            this.instance.w_sync_strategy.layout ().remove_item (this.instance.l_virtual_file_sync);
        }

        this.checking = false;
        this.instance.l_selective_sync_size_label == "";
        this.instance.l_sync_everything_size_label == "";

        // Update the local folder - this is not guaranteed to find a good one
        string good_local_folder = FolderManager.instance.find_good_path_for_new_sync_folder (local_folder (), server_url ());
        wizard ().property ("local_folder", good_local_folder);

        // call to on_signal_init label
        update_status ();

        // ensure "next" gets the focus, not ob_select_local_folder
        GLib.Timeout.single_shot (0, wizard ().button (GLib.Wizard.FinishButton), Gtk.Widget.focus);

        var acc = ((OwncloudWizard)wizard ()).account;
        var quota_job = new PropfindJob (acc, this.remote_folder, this);
        quota_job.properties (new GLib.List<string> ("http://owncloud.org/ns:size"));

        quota_job.signal_result.connect (
            this.on_signal_quota_retrieved
        );
        quota_job.on_signal_start ();

        if (Theme.wizard_selective_sync_default_nothing) {
            this.selective_sync_blocklist = {
                "/"
            };
            radio_checked (this.instance.r_selective_sync);
            GLib.Timeout.single_shot (0, this, OwncloudAdvancedSetupPage.on_signal_selective_sync_clicked);
        }

        ConfigFile config_file;
        var new_folder_limit = config_file.new_big_folder_size_limit;
        this.instance.conf_check_box_size.checked (new_folder_limit.first);
        this.instance.conf_spin_box.value (new_folder_limit.second);
        this.instance.conf_check_box_external.checked (config_file.confirm_external_storage ());

        fetch_user_avatar ();
        user_information ();

        customize_style ();

        var next_button = (GLib.PushButton)this.oc_wizard.button (GLib.Wizard.NextButton));
        if (next_button) {
            next_button.default (true);
        }
    }


    /***********************************************************
    Tells the caller that this is the last dialog page
    ***********************************************************/
    public int next_id {
        public get {
            return -1;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        if (use_virtual_file_sync ()) {
            var availability = AbstractVfs.check_availability (local_folder ());
            if (!availability) {
                var message = new Gtk.MessageBox (Gtk.MessageBox.Warning, _("Virtual files are not available for the selected folder"), availability.error, Gtk.MessageBox.Ok, this);
                message.attribute (GLib.WA_DeleteOnClose);
                message.open ();
                return false;
            }
        }

        if (!this.created) {
            on_signal_error_string ("");
            this.checking = true;
            on_signal_start_spinner ();
            /* emit */ complete_changed ();

            if (this.instance.r_sync_everything.is_checked ()) {
                ConfigFile config_file;
                config_file.new_big_folder_size_limit (this.instance.conf_check_box_size.is_checked (),
                    this.instance.conf_spin_box.value ());
                config_file.confirm_external_storage (this.instance.conf_check_box_external.is_checked ());
            }

            /* emit */ create_local_and_remote_folders (local_folder (), this.remote_folder);
            return false;
        } else {
            // connecting is running
            this.checking = false;
            /* emit */ complete_changed ();
            on_signal_stop_spinner ();
            return true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public string local_folder () {
        string folder = wizard ().property ("local_folder").to_string ();
        return folder;
    }


    /***********************************************************
    ***********************************************************/
    public bool use_virtual_file_sync () {
        return this.instance.r_virtual_file_sync.is_checked ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_confirm_big_folder_checked () {
        return this.instance.r_sync_everything.is_checked () && this.instance.conf_check_box_size.is_checked ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remote_folder (string remote_folder) {
        if (remote_folder != "") {
            this.remote_folder = remote_folder;
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public void multiple_folders_exist (bool exist);


    /***********************************************************
    ***********************************************************/
    public void directories_created () {
        this.checking = false;
        this.created = true;
        on_signal_stop_spinner ();
        /* emit */ complete_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string error_string) {
        if (error_string == "") {
            this.instance.error_label.visible (false);
        } else {
            this.instance.error_label.visible (true);
            this.instance.error_label.on_signal_text (error_string);
        }
        this.checking = false;
        /* emit */ complete_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_select_folder () {
        string directory = GLib.FileDialog.existing_directory (null, _("Local Sync FolderConnection"), GLib.Dir.home_path);
        if (!directory == "") {
            // TODO: remove when UX decision is made
            refresh_virtual_files_availibility (directory);

            local_folder_push_button_path (directory);
            wizard ().property ("local_folder", directory);
            update_status ();
        }

        int64 r_space = this.instance.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;
        string error_str = check_local_space (r_space);
        on_signal_error_string (error_str);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_everything_clicked () {
        this.instance.l_selective_sync_size_label.on_signal_text ("");
        radio_checked (this.instance.r_sync_everything);
        this.selective_sync_blocklist == "";

        string error_str = check_local_space (this.r_size);
        on_signal_error_string (error_str);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_selective_sync_clicked () {
        unowned Account acc = ((OwncloudWizard) wizard ()).account;
        var dialog = new SelectiveSyncDialog (acc, this.remote_folder, this.selective_sync_blocklist, this);
        dialog.attribute (GLib.WA_DeleteOnClose);

        dialog.signal_finished.connect (
            this.on_signal_selective_sync_finished
        );

        a.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_selective_sync_finished (SelectiveSyncDialog dialog) {
        int result = dialog.result ();
        bool update_blocklist = false;

        // We need to update the selective sync blocklist either when the dialog
        // was accepted in that
        // case the stub blocklist of / was expanded to the actual list of top
        // level folders by the selective sync dialog.
        if (result == Gtk.Dialog.Accepted) {
            this.selective_sync_blocklist = dialog.create_block_list ();
            update_blocklist = true;
        } else if (result == Gtk.Dialog.Rejected && this.selective_sync_blocklist == { "/" }) {
            this.selective_sync_blocklist = dialog.old_block_list ();
            update_blocklist = true;
        }

        if (update_blocklist) {
            if (!this.selective_sync_blocklist == "") {
                this.instance.r_selective_sync.block_signals (true);
                radio_checked (this.instance.r_selective_sync);
                this.instance.r_selective_sync.block_signals (false);
                var s = dialog.estimated_size ();
                if (s > 0) {
                    this.instance.l_selective_sync_size_label.on_signal_text (_(" (%1)").printf (Utility.octets_to_string (s)));
                } else {
                    this.instance.l_selective_sync_size_label.on_signal_text ("");
                }
            } else {
                radio_checked (this.instance.r_sync_everything);
                this.instance.l_selective_sync_size_label.on_signal_text ("");
            }
            wizard ().property ("blocklist", this.selective_sync_blocklist);
        }

        update_status ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_virtual_file_sync_clicked () {
        if (!this.instance.r_virtual_file_sync.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (
                this,
                this.on_ask_experimental_virtual_files_feature
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_ask_experimental_virtual_files_feature (bool enable) {
        if (!enable) {
            return;
        }
        radio_checked (this.instance.r_virtual_file_sync);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_quota_retrieved (GLib.VariantMap result) {
        this.r_size = result["size"].to_double ();
        this.instance.l_sync_everything_size_label.on_signal_text (_(" (%1)").printf (Utility.octets_to_string (this.r_size)));

        update_status ();
    }


    /***********************************************************
    ***********************************************************/
    private void radio_checked (GLib.RadioButton radio) {
        // We don't want clicking the radio buttons to immediately adjust the checked state
        // for selective sync and virtual file sync, so we keep them uncheckable until
        // they should be checked.
        radio.checkable (true);
        radio.checked (true);

        if (radio != this.instance.r_selective_sync) {
            this.instance.r_selective_sync.checkable (false);
        }
        if (radio != this.instance.r_virtual_file_sync) {
            this.instance.r_virtual_file_sync.checkable (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_customization () {
        // set defaults for the customize labels.
        this.instance.top_label.hide ();
        this.instance.bottom_label.hide ();

        Theme theme = Theme.instance;
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant == null) {
            WizardCommon.set_up_custom_media (variant, this.instance.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.instance.bottom_label);

        WizardCommon.customize_hint_label (this.instance.l_free_space);
        WizardCommon.customize_hint_label (this.instance.l_sync_everything_size_label);
        WizardCommon.customize_hint_label (this.instance.l_selective_sync_size_label);
        WizardCommon.customize_hint_label (this.instance.server_address_label);
    }


    /***********************************************************
    Called if the user changes the user- or url field. Adjust
    the texts and eventual warnings on the dialog.
    ***********************************************************/
    private void update_status () {
        string loc_folder = local_folder ();

        // check if the local folder exists. If so, and if its not empty, show a warning.
        string error_str = FolderManager.instance.check_path_validity_for_new_folder (loc_folder, server_url ());
        this.local_folder_valid = error_str == "";

        string status_string;

        local_folder_push_button_path (loc_folder);

        if (on_signal_data_changed ()) {
            if (this.remote_folder == "" || this.remote_folder == "/") {
                status_string = "";
            } else {
                status_string = Utility.escape (_(" (%1 folder \"%2\" is synced to local folder \"%3\")")
                                        .printf (
                                            Theme.app_name,
                                            this.remote_folder,
                                            GLib.Dir.to_native_separators (loc_folder)
                                        )
                                    );
                this.instance.r_sync_everything.on_signal_text (_("Sync the folder \"%1\"").printf (this.remote_folder));
            }

            bool dir_not_empty = new GLib.Dir (loc_folder).entry_list (GLib.Dir.AllEntries | GLib.Dir.NoDotAndDotDot).length > 0;
            if (dir_not_empty) {
                status_string += _("Warning : The local folder is not empty. Pick a resolution!");
            }
            resolution_gui_visible (dir_not_empty);
        } else {
            resolution_gui_visible (false);
        }

        string lfree_space_str = Utility.octets_to_string (available_local_space ());
        this.instance.l_free_space.text (_("%1 free space", "%1 gets replaced with the size and a matching unit. Example: 3 MB or 5 GB").printf (lfree_space_str));

        this.instance.sync_mode_label.text (status_string);
        this.instance.sync_mode_label.fixed_height (this.instance.sync_mode_label.size_hint ().height ());

        int64 r_space = this.instance.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;

        string space_error = check_local_space (r_space);
        if (!space_error == "") {
            error_str = space_error;
        }
        on_signal_error_string (error_str);

        /* emit */ complete_changed ();
    }


    /***********************************************************
    @deprecated obsolete
    ***********************************************************/
    private bool on_signal_data_changed () {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_spinner () {
        this.instance.result_layout.enabled (true);
        this.progress_indicator.visible (true);
        this.progress_indicator.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner () {
        this.instance.result_layout.enabled (false);
        this.progress_indicator.visible (false);
        this.progress_indicator.on_signal_stop_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Uri server_url () {
        string url_string = ((OwncloudWizard)wizard ()).oc_url ();
        string user = ((OwncloudWizard)wizard ()).credentials ().user ();

        GLib.Uri url = new GLib.Uri (url_string);
        url.user_name (user);
        return url;
    }


    /***********************************************************
    ***********************************************************/
    private int64 available_local_space () {
        string local_dir = local_folder ();
        string path = !GLib.Dir (local_dir).exists () && local_dir.contains (GLib.Dir.home_path) ?
                    GLib.Dir.home_path : local_dir;
        GLib.StorageInfo storage = new GLib.StorageInfo (GLib.Dir.to_native_separators (path));

        return storage.bytes_available ();
    }


    /***********************************************************
    ***********************************************************/
    private string check_local_space (int64 remote_size) {
        return (available_local_space ()>remote_size) ? "" : _("There isn't enough free space in the local folder!");
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        if (this.progress_indicator) {
            var is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                this.progress_indicator.on_signal_color (GLib.white);
            } else {
                this.progress_indicator.on_signal_color (GLib.block);
            }
        }

        style_sync_logo ();
        style_local_folder_label ();
    }


    /***********************************************************
    ***********************************************************/
    private void server_address_label_url (GLib.Uri url) {
        if (!url.is_valid) {
            return;
        }

        var pretty_url = url.to_string ().mid (url.scheme ().size () + 3); // + 3 because we need to remove ://
        this.instance.server_address_label.on_signal_text (pretty_url);
    }


    /***********************************************************
    ***********************************************************/
    private void local_folder_push_button_path (string path) {
        var home_dir = GLib.Dir.home_path.has_suffix ("/") ? GLib.Dir.home_path : GLib.Dir.home_path + "/";

        if (!path.has_prefix (home_dir)) {
            this.instance.pb_select_local_folder.on_signal_text (GLib.Dir.to_native_separators (path));
            return;
        }

        var pretty_path = path;
        pretty_path.remove (0, home_dir.size ());

        this.instance.pb_select_local_folder.on_signal_text (GLib.Dir.to_native_separators (pretty_path));
    }


    /***********************************************************
    ***********************************************************/
    private void style_sync_logo () {
        var sync_arrow_icon = Theme.create_color_aware_icon (":/client/theme/sync-arrow.svg", palette ());
        this.instance.sync_logo_label.pixmap (sync_arrow_icon.pixmap (Gdk.Rectangle (50, 50)));
    }


    /***********************************************************
    ***********************************************************/
    private void style_local_folder_label () {
        var background_color = palette ().window ().color ();
        var folder_icon_filename = Theme.is_branded ? Theme.hidpi_filename ("folder.png", background_color)
                                                                       : Theme.hidpi_filename (":/client/theme/colored/folder.png");
        this.instance.l_local.pixmap (folder_icon_filename);
    }


    /***********************************************************
    ***********************************************************/
    private void resolution_gui_visible (bool value) {
        this.instance.sync_mode_label.visible (value);
        this.instance.r_keep_local.visible (value);
        this.instance.cb_sync_from_scratch.visible (value);
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_resolution_widget () {
        for (int i = 0; i < this.instance.resolution_widget_layout.length; ++i) {
            var widget = this.instance.resolution_widget_layout.item_at (i).widget ();
            if (!widget) {
                continue;
            }

            var size_policy = widget.size_policy ();
            size_policy.retain_size_when_hidden (true);
            widget.size_policy (size_policy);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void fetch_user_avatar () {
        // Reset user avatar
        var app_icon = Theme.application_icon;
        this.instance.l_server_icon.pixmap (app_icon.pixmap (48));
        // Fetch user avatar
        var account = this.oc_wizard.account;
        var avatar_size = 64;
        if (Theme.is_hidpi ()) {
            avatar_size *= 2;
        }
        AvatarJob avatar_job = new AvatarJob (account, account.dav_user, avatar_size, this);
        avatar_job.on_signal_timeout (20 * 1000);
        avatar_job.signal_avatar_pixmap.connect (
            this.on_avatar_job_avatar_pixmap
        );
        avatar_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_avatar_job_avatar_pixmap (Gtk.Image avatar_image) {
        if (avatar_image == null) {
            return;
        }
        var avatar_pixmap = Gdk.Pixbuf.from_image (AvatarJob.make_circular_avatar (avatar_image));
        this.instance.l_server_icon.pixmap (avatar_pixmap);
    }


    /***********************************************************
    ***********************************************************/
    private void user_information () {
        var account = this.oc_wizard.account;
        var server_url = account.url.to_string ();
        server_address_label_url (server_url);
        var user_name = account.dav_display_name ();
        this.instance.user_name_label.on_signal_text (user_name);
    }


    /***********************************************************
    TODO: remove when UX decision is made
    ***********************************************************/
    private void refresh_virtual_files_availibility (string path) {
        // TODO: remove when UX decision is made
        if (!this.instance.r_virtual_file_sync.is_visible ()) {
            return;
        }

        if (Utility.is_path_windows_drive_partition_root (path)) {
            this.instance.r_virtual_file_sync.on_signal_text (_("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            radio_checked (this.instance.r_sync_everything);
            this.instance.r_virtual_file_sync.enabled (false);
        } else {
            this.instance.r_virtual_file_sync.on_signal_text (_("Use virtual files instead of downloading content immediately %1").printf (this.best_available_vfs_mode == AbstractVfs.WindowsCfApi ? "" : _(" (experimental)")));
            this.instance.r_virtual_file_sync.enabled (true);
        }
        //  
    }

} // class OwncloudAdvancedSetupPage

} // namespace Ui
} // namespace Occ
    