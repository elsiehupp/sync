/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>
//  #include <QFileDialog>
//  #include <QTimer>
//  #include <QStorageInfo>
//  #include <QMessageBox>
//  #include <QJsonObject>
//  #include <folderman.h>

//  #include <QWizard>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudAdvancedSetupPage class
@ingroup gui
***********************************************************/
class OwncloudAdvancedSetupPage : QWizardPage {

    /***********************************************************
    ***********************************************************/
    private Ui.Owncloude_advanced_setup_page ui;
    private bool checking = false;
    private bool created = false;
    private bool local_folder_valid = false;
    private QProgressIndicator progress_indicator;
    private string remote_folder;
    string[] selective_sync_blocklist { public get; private set; }
    private int64 r_size = -1;
    private int64 r_selected_size = -1;
    private OwncloudWizard oc_wizard;


    signal void create_local_and_remote_folders (string value1, string value2);


    /***********************************************************
    ***********************************************************/
    public OwncloudAdvancedSetupPage (OwncloudWizard wizard) {
        base ();
        this.progress_indicator = new QProgressIndicator (this);
        this.oc_wizard = wizard;
        this.ui.up_ui (this);

        set_up_resolution_widget ();

        register_field (QLatin1String ("OCSync_from_scratch"), this.ui.cb_sync_from_scratch);

        var size_policy = this.progress_indicator.size_policy ();
        size_policy.retain_size_when_hidden (true);
        this.progress_indicator.size_policy (size_policy);

        this.ui.result_layout.add_widget (this.progress_indicator);
        on_signal_stop_spinner ();
        set_up_customization ();

        connect (this.ui.pb_select_local_folder, QAbstractButton.clicked, this, OwncloudAdvancedSetupPage.on_signal_select_folder);
        button_text (QWizard.FinishButton, _("Connect"));

        if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
            this.ui.r_sync_everything.disabled (true);
            this.ui.r_selective_sync.disabled (true);
            this.ui.b_selective_sync.disabled (true);
        }

        connect (
            this.ui.r_sync_everything,
            QAbstractButton.clicked,
            this,
            OwncloudAdvancedSetupPage.on_signal_sync_everything_clicked
        );
        connect (
            this.ui.r_selective_sync,
            QAbstractButton.clicked,
            this,
            OwncloudAdvancedSetupPage.on_signal_selective_sync_clicked
        );
        connect (
            this.ui.r_virtual_file_sync,
            QAbstractButton.clicked,
            this,
            OwncloudAdvancedSetupPage.on_signal_virtual_file_sync_clicked
        );
        connect (
            this.ui.r_virtual_file_sync,
            QRadioButton.toggled,
            this,
            this.on_virtual_file_sync_toggled
        );
        connect (
            this.ui.b_selective_sync,
            QAbstractButton.clicked,
            this,
            OwncloudAdvancedSetupPage.on_signal_selective_sync_clicked
        );

        const var theme = Theme.instance ();
        const var app_icon = theme.application_icon ();
        const var app_icon_size = Theme.is_hidpi () ? 128 : 64;

        this.ui.l_server_icon.pixmap (app_icon.pixmap (app_icon_size));

        if (theme.wizard_hide_external_storage_confirmation_checkbox ()) {
            this.ui.conf_check_box_external.hide ();
        }
        if (theme.wizard_hide_folder_size_limit_checkbox ()) {
            this.ui.conf_check_box_size.hide ();
            this.ui.conf_spin_box.hide ();
            this.ui.conf_trailling_size_label.hide ();
        }

        this.ui.r_virtual_file_sync.on_signal_text (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
    }


    private void on_virtual_file_sync_toggled (bool checked) {
        if (checked) {
            this.ui.l_selective_sync_size_label.clear ();
            this.selective_sync_blocklist.clear ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete () {
        return !this.checking && this.local_folder_valid;
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        WizardCommon.init_error_label (this.ui.error_label);

        if (!Theme.instance ().show_virtual_files_option () || best_available_vfs_mode () == Vfs.Off) {
            // If the layout were wrapped in a widget, the var-grouping of the
            // radio buttons no longer works and there are surprising margins.
            // Just manually hide the button and remove the layout.
            this.ui.r_virtual_file_sync.hide ();
            this.ui.w_sync_strategy.layout ().remove_item (this.ui.l_virtual_file_sync);
        }

        this.checking = false;
        this.ui.l_selective_sync_size_label.clear ();
        this.ui.l_sync_everything_size_label.clear ();

        // Update the local folder - this is not guaranteed to find a good one
        string good_local_folder = FolderMan.instance ().find_good_path_for_new_sync_folder (local_folder (), server_url ());
        wizard ().property ("local_folder", good_local_folder);

        // call to on_signal_init label
        update_status ();

        // ensure "next" gets the focus, not ob_select_local_folder
        QTimer.single_shot (0, wizard ().button (QWizard.FinishButton), Gtk.Widget.focus);

        var acc = static_cast<OwncloudWizard> (wizard ()).account ();
        var quota_job = new PropfindJob (acc, this.remote_folder, this);
        quota_job.properties (new GLib.List<GLib.ByteArray> ("http://owncloud.org/ns:size"));

        connect (
            quota_job,
            PropfindJob.result,
            this,
            OwncloudAdvancedSetupPage.on_signal_quota_retrieved
        );
        quota_job.on_signal_start ();

        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            this.selective_sync_blocklist = {
                "/"
            };
            radio_checked (this.ui.r_selective_sync);
            QTimer.single_shot (0, this, OwncloudAdvancedSetupPage.on_signal_selective_sync_clicked);
        }

        ConfigFile config_file;
        var new_folder_limit = config_file.new_big_folder_size_limit ();
        this.ui.conf_check_box_size.checked (new_folder_limit.first);
        this.ui.conf_spin_box.value (new_folder_limit.second);
        this.ui.conf_check_box_external.checked (config_file.confirm_external_storage ());

        fetch_user_avatar ();
        user_information ();

        customize_style ();

        var next_button = qobject_cast<QPushButton> (this.oc_wizard.button (QWizard.NextButton));
        if (next_button) {
            next_button.default (true);
        }
    }


    /***********************************************************
    ***********************************************************/
    public int next_id () {
        // tells the caller that this is the last dialog page
        return -1;
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        if (use_virtual_file_sync ()) {
            const var availability = Vfs.check_availability (local_folder ());
            if (!availability) {
                var message = new QMessageBox (QMessageBox.Warning, _("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                message.attribute (Qt.WA_DeleteOnClose);
                message.open ();
                return false;
            }
        }

        if (!this.created) {
            on_signal_error_string ("");
            this.checking = true;
            on_signal_start_spinner ();
            /* emit */ complete_changed ();

            if (this.ui.r_sync_everything.is_checked ()) {
                ConfigFile config_file;
                config_file.new_big_folder_size_limit (this.ui.conf_check_box_size.is_checked (),
                    this.ui.conf_spin_box.value ());
                config_file.confirm_external_storage (this.ui.conf_check_box_external.is_checked ());
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
        return this.ui.r_virtual_file_sync.is_checked ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_confirm_big_folder_checked () {
        return this.ui.r_sync_everything.is_checked () && this.ui.conf_check_box_size.is_checked ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remote_folder (string remote_folder) {
        if (!remote_folder.is_empty ()) {
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
        if (error_string.is_empty ()) {
            this.ui.error_label.visible (false);
        } else {
            this.ui.error_label.visible (true);
            this.ui.error_label.on_signal_text (error_string);
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
        string directory = QFileDialog.get_existing_directory (null, _("Local Sync Folder"), QDir.home_path ());
        if (!directory.is_empty ()) {
            // TODO: remove when UX decision is made
            refresh_virtual_files_availibility (directory);

            local_folder_push_button_path (directory);
            wizard ().property ("local_folder", directory);
            update_status ();
        }

        int64 r_space = this.ui.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;
        string error_str = check_local_space (r_space);
        on_signal_error_string (error_str);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_everything_clicked () {
        this.ui.l_selective_sync_size_label.on_signal_text ("");
        radio_checked (this.ui.r_sync_everything);
        this.selective_sync_blocklist.clear ();

        string error_str = check_local_space (this.r_size);
        on_signal_error_string (error_str);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_selective_sync_clicked () {
        AccountPointer acc = ((OwncloudWizard) wizard ()).account ();
        var dialog = new SelectiveSyncDialog (acc, this.remote_folder, this.selective_sync_blocklist, this);
        dialog.attribute (Qt.WA_DeleteOnClose);

        connect (
            dialog,
            SelectiveSyncDialog.signal_finished,
            this,
            this.on_signal_selective_sync_finished
        );
    
        a.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_selective_sync_finished (SelectiveSyncDialog dialog) {
        const int result = dialog.result ();
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
            if (!this.selective_sync_blocklist.is_empty ()) {
                this.ui.r_selective_sync.block_signals (true);
                radio_checked (this.ui.r_selective_sync);
                this.ui.r_selective_sync.block_signals (false);
                var s = dialog.estimated_size ();
                if (s > 0) {
                    this.ui.l_selective_sync_size_label.on_signal_text (_(" (%1)").arg (Utility.octets_to_string (s)));
                } else {
                    this.ui.l_selective_sync_size_label.on_signal_text ("");
                }
            } else {
                radio_checked (this.ui.r_sync_everything);
                this.ui.l_selective_sync_size_label.on_signal_text ("");
            }
            wizard ().property ("blocklist", this.selective_sync_blocklist);
        }

        update_status ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_virtual_file_sync_clicked () {
        if (!this.ui.r_virtual_file_sync.is_checked ()) {
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
        radio_checked (this.ui.r_virtual_file_sync);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_quota_retrieved (QVariantMap result) {
        this.r_size = result["size"].to_double ();
        this.ui.l_sync_everything_size_label.on_signal_text (_(" (%1)").arg (Utility.octets_to_string (this.r_size)));

        update_status ();
    }


    /***********************************************************
    ***********************************************************/
    private void radio_checked (QRadioButton radio) {
        // We don't want clicking the radio buttons to immediately adjust the checked state
        // for selective sync and virtual file sync, so we keep them uncheckable until
        // they should be checked.
        radio.checkable (true);
        radio.checked (true);

        if (radio != this.ui.r_selective_sync) {
            this.ui.r_selective_sync.checkable (false);
        }
        if (radio != this.ui.r_virtual_file_sync) {
            this.ui.r_virtual_file_sync.checkable (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_customization () {
        // set defaults for the customize labels.
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();

        Theme theme = Theme.instance ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant.is_null ()) {
            WizardCommon.set_up_custom_media (variant, this.ui.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.ui.bottom_label);

        WizardCommon.customize_hint_label (this.ui.l_free_space);
        WizardCommon.customize_hint_label (this.ui.l_sync_everything_size_label);
        WizardCommon.customize_hint_label (this.ui.l_selective_sync_size_label);
        WizardCommon.customize_hint_label (this.ui.server_address_label);
    }


    /***********************************************************
    Called if the user changes the user- or url field. Adjust
    the texts and eventual warnings on the dialog.
    ***********************************************************/
    private void update_status () {
        const string loc_folder = local_folder ();

        // check if the local folder exists. If so, and if its not empty, show a warning.
        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (loc_folder, server_url ());
        this.local_folder_valid = error_str.is_empty ();

        string t;

        local_folder_push_button_path (loc_folder);

        if (on_signal_data_changed ()) {
            if (this.remote_folder.is_empty () || this.remote_folder == QLatin1String ("/")) {
                t = "";
            } else {
                t = Utility.escape (_(" (%1 folder \"%2\" is synced to local folder \"%3\")")
                                        .arg (
                                            Theme.instance ().app_name (),
                                            this.remote_folder,
                                            QDir.to_native_separators (loc_folder)
                                        )
                                    );
                this.ui.r_sync_everything.on_signal_text (_("Sync the folder \"%1\"").arg (this.remote_folder));
            }

            const bool dir_not_empty = new QDir (loc_folder).entry_list (QDir.AllEntries | QDir.NoDotAndDotDot).count () > 0;
            if (dir_not_empty) {
                t += _("Warning : The local folder is not empty. Pick a resolution!");
            }
            resolution_gui_visible (dir_not_empty);
        } else {
            resolution_gui_visible (false);
        }

        string lfree_space_str = Utility.octets_to_string (available_local_space ());
        this.ui.l_free_space.on_signal_text (string (_("%1 free space", "%1 gets replaced with the size and a matching unit. Example: 3 MB or 5 GB")).arg (lfree_space_str));

        this.ui.sync_mode_label.on_signal_text (t);
        this.ui.sync_mode_label.fixed_height (this.ui.sync_mode_label.size_hint ().height ());

        int64 r_space = this.ui.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;

        string space_error = check_local_space (r_space);
        if (!space_error.is_empty ()) {
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
        this.ui.result_layout.enabled (true);
        this.progress_indicator.visible (true);
        this.progress_indicator.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner () {
        this.ui.result_layout.enabled (false);
        this.progress_indicator.visible (false);
        this.progress_indicator.on_signal_stop_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Uri server_url () {
        const string url_string = static_cast<OwncloudWizard> (wizard ()).oc_url ();
        const string user = static_cast<OwncloudWizard> (wizard ()).get_credentials ().user ();

        GLib.Uri url = new GLib.Uri (url_string);
        url.user_name (user);
        return url;
    }


    /***********************************************************
    ***********************************************************/
    private int64 available_local_space () {
        string local_dir = local_folder ();
        string path = !QDir (local_dir).exists () && local_dir.contains (QDir.home_path ()) ?
                    QDir.home_path () : local_dir;
        QStorageInfo storage = new QStorageInfo (QDir.to_native_separators (path));

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
            const var is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                this.progress_indicator.on_signal_color (Qt.white);
            } else {
                this.progress_indicator.on_signal_color (Qt.block);
            }
        }

        style_sync_logo ();
        style_local_folder_label ();
    }


    /***********************************************************
    ***********************************************************/
    private void server_address_label_url (GLib.Uri url) {
        if (!url.is_valid ()) {
            return;
        }

        const var pretty_url = url.to_string ().mid (url.scheme ().size () + 3); // + 3 because we need to remove ://
        this.ui.server_address_label.on_signal_text (pretty_url);
    }


    /***********************************************************
    ***********************************************************/
    private void local_folder_push_button_path (string path) {
        const var home_dir = QDir.home_path ().ends_with ('/') ? QDir.home_path () : QDir.home_path () + '/';

        if (!path.starts_with (home_dir)) {
            this.ui.pb_select_local_folder.on_signal_text (QDir.to_native_separators (path));
            return;
        }

        var pretty_path = path;
        pretty_path.remove (0, home_dir.size ());

        this.ui.pb_select_local_folder.on_signal_text (QDir.to_native_separators (pretty_path));
    }


    /***********************************************************
    ***********************************************************/
    private void style_sync_logo () {
        const var sync_arrow_icon = Theme.create_color_aware_icon (QLatin1String (":/client/theme/sync-arrow.svg"), palette ());
        this.ui.sync_logo_label.pixmap (sync_arrow_icon.pixmap (QSize (50, 50)));
    }


    /***********************************************************
    ***********************************************************/
    private void style_local_folder_label () {
        const var background_color = palette ().window ().color ();
        const var folder_icon_filename = Theme.instance ().is_branded () ? Theme.hidpi_filename ("folder.png", background_color)
                                                                       : Theme.hidpi_filename (":/client/theme/colored/folder.png");
        this.ui.l_local.pixmap (folder_icon_filename);
    }


    /***********************************************************
    ***********************************************************/
    private void resolution_gui_visible (bool value) {
        this.ui.sync_mode_label.visible (value);
        this.ui.r_keep_local.visible (value);
        this.ui.cb_sync_from_scratch.visible (value);
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_resolution_widget () {
        for (int i = 0; i < this.ui.resolution_widget_layout.count (); ++i) {
            var widget = this.ui.resolution_widget_layout.item_at (i).widget ();
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
        const var app_icon = Theme.instance ().application_icon ();
        this.ui.l_server_icon.pixmap (app_icon.pixmap (48));
        // Fetch user avatar
        const var account = this.oc_wizard.account ();
        var avatar_size = 64;
        if (Theme.is_hidpi ()) {
            avatar_size *= 2;
        }
        const AvatarJob avatar_job = new AvatarJob (account, account.dav_user (), avatar_size, this);
        avatar_job.on_signal_timeout (20 * 1000);
        connect (
            avatar_job,
            AvatarJob.avatar_pixmap,
            this,
            this.on_avatar_job_avatar_pixmap
        );
        avatar_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_avatar_job_avatar_pixmap (Gtk.Image avatar_image) {
        if (avatar_image.is_null ()) {
            return;
        }
        const var avatar_pixmap = QPixmap.from_image (AvatarJob.make_circular_avatar (avatar_image));
        this.ui.l_server_icon.pixmap (avatar_pixmap);
    }


    /***********************************************************
    ***********************************************************/
    private void user_information () {
        const var account = this.oc_wizard.account ();
        const var server_url = account.url ().to_string ();
        server_address_label_url (server_url);
        const var user_name = account.dav_display_name ();
        this.ui.user_name_label.on_signal_text (user_name);
    }


    /***********************************************************
    TODO: remove when UX decision is made
    ***********************************************************/
    private void refresh_virtual_files_availibility (string path) {
        // TODO: remove when UX decision is made
        if (!this.ui.r_virtual_file_sync.is_visible ()) {
            return;
        }

        if (Utility.is_path_windows_drive_partition_root (path)) {
            this.ui.r_virtual_file_sync.on_signal_text (_("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            radio_checked (this.ui.r_sync_everything);
            this.ui.r_virtual_file_sync.enabled (false);
        } else {
            this.ui.r_virtual_file_sync.on_signal_text (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
            this.ui.r_virtual_file_sync.enabled (true);
        }
        //
    }

} // class OwncloudAdvancedSetupPage

} // namespace Ui
} // namespace Occ
    