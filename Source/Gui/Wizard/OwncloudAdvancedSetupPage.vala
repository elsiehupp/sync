/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QFileDialog>
// #include <GLib.Uri>
// #include <QTimer>
// #include <QStorage_info>
// #include <QMessageBox>
// #include <QJsonObject>

// #include <folderman.h>

// #include <QWizard>


namespace Occ {


/***********************************************************
@brief The Owncloud_advanced_setup_page class
@ingroup gui
***********************************************************/
class Owncloud_advanced_setup_page : QWizard_page {

    /***********************************************************
    ***********************************************************/
    public Owncloud_advanced_setup_page (OwncloudWizard wizard);

    /***********************************************************
    ***********************************************************/
    public bool is_complete () override;
    public void initialize_page () override;
    public int next_id () override;
    public bool validate_page () override;
    public string local_folder ();


    /***********************************************************
    ***********************************************************/
    public string[] selective_sync_blocklist ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool is_confirm_big_folder_checked ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void set_multiple_folders_exist (bool exist);


    public void directories_created ();

signals:
    void create_local_and_remote_folders (string , string );


    /***********************************************************
    ***********************************************************/
    public void on_set_error_string (string );

    /***********************************************************
    ***********************************************************/
    public 
    public void on_style_changed ();


    /***********************************************************
    ***********************************************************/
    private void on_select_folder ();
    private void on_sync_everything_clicked ();
    private void on_selective_sync_clicked ();
    private void on_virtual_file_sync_clicked ();
    private void on_quota_retrieved (QVariantMap result);


    /***********************************************************
    ***********************************************************/
    private void set_radio_checked (QRadio_button radio);

    /***********************************************************
    ***********************************************************/
    private void setup_customization ();
    private void update_status ();
    private bool on_data_changed ();
    private void on_start_spinner ();
    private void on_stop_spinner ();
    private GLib.Uri server_url ();
    private int64 available_local_space ();
    private string check_local_space (int64 remote_size);
    private void customize_style ();
    private void set_server_address_label_url (GLib.Uri url);
    private void set_local_folder_push_button_path (string path);
    private void style_sync_logo ();
    private void style_local_folder_label ();
    private void set_resolution_gui_visible (bool value);
    private void setup_resoultion_widget ();
    private void fetch_user_avatar ();
    private void set_user_information ();

    // TODO : remove when UX decision is made
    private void refresh_virtual_files_availibility (string path);

    /***********************************************************
    ***********************************************************/
    private Ui_Owncloud_advanced_setup_page this.ui;
    private bool this.checking = false;
    private bool this.created = false;
    private bool this.local_folder_valid = false;
    private QProgress_indicator this.progress_indi;
    private string this.remote_folder;
    private string[] this.selective_sync_blocklist;
    private int64 this.r_size = -1;
    private int64 this.r_selected_size = -1;
    private OwncloudWizard this.oc_wizard;
};

    Owncloud_advanced_setup_page.Owncloud_advanced_setup_page (OwncloudWizard wizard)
        : QWizard_page ()
        , this.progress_indi (new QProgress_indicator (this))
        , this.oc_wizard (wizard) {
        this.ui.setup_ui (this);

        setup_resoultion_widget ();

        register_field (QLatin1String ("OCSync_from_scratch"), this.ui.cb_sync_from_scratch);

        var size_policy = this.progress_indi.size_policy ();
        size_policy.set_retain_size_when_hidden (true);
        this.progress_indi.set_size_policy (size_policy);

        this.ui.result_layout.add_widget (this.progress_indi);
        on_stop_spinner ();
        setup_customization ();

        connect (this.ui.pb_select_local_folder, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.on_select_folder);
        set_button_text (QWizard.Finish_button, _("Connect"));

        if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
            this.ui.r_sync_everything.set_disabled (true);
            this.ui.r_selective_sync.set_disabled (true);
            this.ui.b_selective_sync.set_disabled (true);
        }

        connect (this.ui.r_sync_everything, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.on_sync_everything_clicked);
        connect (this.ui.r_selective_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.on_selective_sync_clicked);
        connect (this.ui.r_virtual_file_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.on_virtual_file_sync_clicked);
        connect (this.ui.r_virtual_file_sync, &QRadio_button.toggled, this, [this] (bool checked) {
            if (checked) {
                this.ui.l_selective_sync_size_label.clear ();
                this.selective_sync_blocklist.clear ();
            }
        });
        connect (this.ui.b_selective_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.on_selective_sync_clicked);

        const var theme = Theme.instance ();
        const var app_icon = theme.application_icon ();
        const var app_icon_size = Theme.is_hidpi () ? 128 : 64;

        this.ui.l_server_icon.set_pixmap (app_icon.pixmap (app_icon_size));

        if (theme.wizard_hide_external_storage_confirmation_checkbox ()) {
            this.ui.conf_check_box_external.hide ();
        }
        if (theme.wizard_hide_folder_size_limit_checkbox ()) {
            this.ui.conf_check_box_size.hide ();
            this.ui.conf_spin_box.hide ();
            this.ui.conf_trailling_size_label.hide ();
        }

        this.ui.r_virtual_file_sync.on_set_text (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
    }

    void Owncloud_advanced_setup_page.setup_customization () {
        // set defaults for the customize labels.
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();

        Theme theme = Theme.instance ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant.is_null ()) {
            WizardCommon.setup_custom_media (variant, this.ui.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.setup_custom_media (variant, this.ui.bottom_label);

        WizardCommon.customize_hint_label (this.ui.l_free_space);
        WizardCommon.customize_hint_label (this.ui.l_sync_everything_size_label);
        WizardCommon.customize_hint_label (this.ui.l_selective_sync_size_label);
        WizardCommon.customize_hint_label (this.ui.server_address_label);
    }

    bool Owncloud_advanced_setup_page.is_complete () {
        return !this.checking && this.local_folder_valid;
    }

    void Owncloud_advanced_setup_page.initialize_page () {
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
        wizard ().set_property ("local_folder", good_local_folder);

        // call to on_init label
        update_status ();

        // ensure "next" gets the focus, not ob_select_local_folder
        QTimer.single_shot (0, wizard ().button (QWizard.Finish_button), q_overload<> (&Gtk.Widget.set_focus));

        var acc = static_cast<OwncloudWizard> (wizard ()).account ();
        var quota_job = new PropfindJob (acc, this.remote_folder, this);
        quota_job.set_properties (GLib.List<GLib.ByteArray> () << "http://owncloud.org/ns:size");

        connect (quota_job, &PropfindJob.result, this, &Owncloud_advanced_setup_page.on_quota_retrieved);
        quota_job.on_start ();

        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            this.selective_sync_blocklist = string[] ("/");
            set_radio_checked (this.ui.r_selective_sync);
            QTimer.single_shot (0, this, &Owncloud_advanced_setup_page.on_selective_sync_clicked);
        }

        ConfigFile cfg_file;
        var new_folder_limit = cfg_file.new_big_folder_size_limit ();
        this.ui.conf_check_box_size.set_checked (new_folder_limit.first);
        this.ui.conf_spin_box.set_value (new_folder_limit.second);
        this.ui.conf_check_box_external.set_checked (cfg_file.confirm_external_storage ());

        fetch_user_avatar ();
        set_user_information ();

        customize_style ();

        var next_button = qobject_cast<QPushButton> (this.oc_wizard.button (QWizard.Next_button));
        if (next_button) {
            next_button.set_default (true);
        }
    }

    void Owncloud_advanced_setup_page.fetch_user_avatar () {
        // Reset user avatar
        const var app_icon = Theme.instance ().application_icon ();
        this.ui.l_server_icon.set_pixmap (app_icon.pixmap (48));
        // Fetch user avatar
        const var account = this.oc_wizard.account ();
        var avatar_size = 64;
        if (Theme.is_hidpi ()) {
            avatar_size *= 2;
        }
        const var avatar_job = new AvatarJob (account, account.dav_user (), avatar_size, this);
        avatar_job.on_set_timeout (20 * 1000);
        GLib.Object.connect (avatar_job, &AvatarJob.avatar_pixmap, this, [this] (QImage avatar_image) {
            if (avatar_image.is_null ()) {
                return;
            }
            const var avatar_pixmap = QPixmap.from_image (AvatarJob.make_circular_avatar (avatar_image));
            this.ui.l_server_icon.set_pixmap (avatar_pixmap);
        });
        avatar_job.on_start ();
    }

    void Owncloud_advanced_setup_page.set_user_information () {
        const var account = this.oc_wizard.account ();
        const var server_url = account.url ().to_"";
        set_server_address_label_url (server_url);
        const var user_name = account.dav_display_name ();
        this.ui.user_name_label.on_set_text (user_name);
    }

    void Owncloud_advanced_setup_page.refresh_virtual_files_availibility (string path) {
        // TODO : remove when UX decision is made
        if (!this.ui.r_virtual_file_sync.is_visible ()) {
            return;
        }

        if (Utility.is_path_windows_drive_partition_root (path)) {
            this.ui.r_virtual_file_sync.on_set_text (_("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            set_radio_checked (this.ui.r_sync_everything);
            this.ui.r_virtual_file_sync.set_enabled (false);
        } else {
            this.ui.r_virtual_file_sync.on_set_text (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
            this.ui.r_virtual_file_sync.set_enabled (true);
        }
        //
    }

    void Owncloud_advanced_setup_page.set_server_address_label_url (GLib.Uri url) {
        if (!url.is_valid ()) {
            return;
        }

        const var pretty_url = url.to_"".mid (url.scheme ().size () + 3); // + 3 because we need to remove ://
        this.ui.server_address_label.on_set_text (pretty_url);
    }

    // Called if the user changes the user- or url field. Adjust the texts and
    // evtl. warnings on the dialog.
    void Owncloud_advanced_setup_page.update_status () {
        const string loc_folder = local_folder ();

        // check if the local folder exists. If so, and if its not empty, show a warning.
        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (loc_folder, server_url ());
        this.local_folder_valid = error_str.is_empty ();

        string t;

        set_local_folder_push_button_path (loc_folder);

        if (on_data_changed ()) {
            if (this.remote_folder.is_empty () || this.remote_folder == QLatin1String ("/")) {
                t = "";
            } else {
                t = Utility.escape (_(R" (%1 folder "%2" is synced to local folder "%3")")
                                        .arg (Theme.instance ().app_name (), this.remote_folder,
                                            QDir.to_native_separators (loc_folder)));
                this.ui.r_sync_everything.on_set_text (_("Sync the folder \"%1\"").arg (this.remote_folder));
            }

            const bool dir_not_empty (QDir (loc_folder).entry_list (QDir.AllEntries | QDir.NoDotAndDotDot).count () > 0);
            if (dir_not_empty) {
                t += _("Warning : The local folder is not empty. Pick a resolution!");
            }
            set_resolution_gui_visible (dir_not_empty);
        } else {
            set_resolution_gui_visible (false);
        }

        string lfree_space_str = Utility.octets_to_string (available_local_space ());
        this.ui.l_free_space.on_set_text (string (_("%1 free space", "%1 gets replaced with the size and a matching unit. Example: 3 MB or 5 GB")).arg (lfree_space_str));

        this.ui.sync_mode_label.on_set_text (t);
        this.ui.sync_mode_label.set_fixed_height (this.ui.sync_mode_label.size_hint ().height ());

        int64 r_space = this.ui.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;

        string space_error = check_local_space (r_space);
        if (!space_error.is_empty ()) {
            error_str = space_error;
        }
        on_set_error_string (error_str);

        /* emit */ complete_changed ();
    }

    void Owncloud_advanced_setup_page.set_resolution_gui_visible (bool value) {
        this.ui.sync_mode_label.set_visible (value);
        this.ui.r_keep_local.set_visible (value);
        this.ui.cb_sync_from_scratch.set_visible (value);
    }

    /* obsolete */
    bool Owncloud_advanced_setup_page.on_data_changed () {
        return true;
    }

    void Owncloud_advanced_setup_page.on_start_spinner () {
        this.ui.result_layout.set_enabled (true);
        this.progress_indi.set_visible (true);
        this.progress_indi.on_start_animation ();
    }

    void Owncloud_advanced_setup_page.on_stop_spinner () {
        this.ui.result_layout.set_enabled (false);
        this.progress_indi.set_visible (false);
        this.progress_indi.on_stop_animation ();
    }

    GLib.Uri Owncloud_advanced_setup_page.server_url () {
        const string url_string = static_cast<OwncloudWizard> (wizard ()).oc_url ();
        const string user = static_cast<OwncloudWizard> (wizard ()).get_credentials ().user ();

        GLib.Uri url (url_string);
        url.set_user_name (user);
        return url;
    }

    int Owncloud_advanced_setup_page.next_id () {
        // tells the caller that this is the last dialog page
        return -1;
    }

    string Owncloud_advanced_setup_page.local_folder () {
        string folder = wizard ().property ("local_folder").to_"";
        return folder;
    }

    string[] Owncloud_advanced_setup_page.selective_sync_blocklist () {
        return this.selective_sync_blocklist;
    }

    bool Owncloud_advanced_setup_page.use_virtual_file_sync () {
        return this.ui.r_virtual_file_sync.is_checked ();
    }

    bool Owncloud_advanced_setup_page.is_confirm_big_folder_checked () {
        return this.ui.r_sync_everything.is_checked () && this.ui.conf_check_box_size.is_checked ();
    }

    bool Owncloud_advanced_setup_page.validate_page () {
        if (use_virtual_file_sync ()) {
            const var availability = Vfs.check_availability (local_folder ());
            if (!availability) {
                var msg = new QMessageBox (QMessageBox.Warning, _("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                msg.set_attribute (Qt.WA_DeleteOnClose);
                msg.open ();
                return false;
            }
        }

        if (!this.created) {
            on_set_error_string ("");
            this.checking = true;
            on_start_spinner ();
            /* emit */ complete_changed ();

            if (this.ui.r_sync_everything.is_checked ()) {
                ConfigFile cfg_file;
                cfg_file.set_new_big_folder_size_limit (this.ui.conf_check_box_size.is_checked (),
                    this.ui.conf_spin_box.value ());
                cfg_file.set_confirm_external_storage (this.ui.conf_check_box_external.is_checked ());
            }

            /* emit */ create_local_and_remote_folders (local_folder (), this.remote_folder);
            return false;
        } else {
            // connecting is running
            this.checking = false;
            /* emit */ complete_changed ();
            on_stop_spinner ();
            return true;
        }
    }

    void Owncloud_advanced_setup_page.on_set_error_string (string err) {
        if (err.is_empty ()) {
            this.ui.error_label.set_visible (false);
        } else {
            this.ui.error_label.set_visible (true);
            this.ui.error_label.on_set_text (err);
        }
        this.checking = false;
        /* emit */ complete_changed ();
    }

    void Owncloud_advanced_setup_page.directories_created () {
        this.checking = false;
        this.created = true;
        on_stop_spinner ();
        /* emit */ complete_changed ();
    }

    void Owncloud_advanced_setup_page.on_set_remote_folder (string remote_folder) {
        if (!remote_folder.is_empty ()) {
            this.remote_folder = remote_folder;
        }
    }

    void Owncloud_advanced_setup_page.on_select_folder () {
        string dir = QFileDialog.get_existing_directory (nullptr, _("Local Sync Folder"), QDir.home_path ());
        if (!dir.is_empty ()) {
            // TODO : remove when UX decision is made
            refresh_virtual_files_availibility (dir);

            set_local_folder_push_button_path (dir);
            wizard ().set_property ("local_folder", dir);
            update_status ();
        }

        int64 r_space = this.ui.r_sync_everything.is_checked () ? this.r_size : this.r_selected_size;
        string error_str = check_local_space (r_space);
        on_set_error_string (error_str);
    }

    void Owncloud_advanced_setup_page.set_local_folder_push_button_path (string path) {
        const var home_dir = QDir.home_path ().ends_with ('/') ? QDir.home_path () : QDir.home_path () + '/';

        if (!path.starts_with (home_dir)) {
            this.ui.pb_select_local_folder.on_set_text (QDir.to_native_separators (path));
            return;
        }

        var pretty_path = path;
        pretty_path.remove (0, home_dir.size ());

        this.ui.pb_select_local_folder.on_set_text (QDir.to_native_separators (pretty_path));
    }

    void Owncloud_advanced_setup_page.on_selective_sync_clicked () {
        AccountPointer acc = static_cast<OwncloudWizard> (wizard ()).account ();
        var dlg = new Selective_sync_dialog (acc, this.remote_folder, this.selective_sync_blocklist, this);
        dlg.set_attribute (Qt.WA_DeleteOnClose);

        connect (dlg, &Selective_sync_dialog.on_finished, this, [this, dlg]{
            const int result = dlg.result ();
            bool update_blocklist = false;

            // We need to update the selective sync blocklist either when the dialog
            // was accepted in that
            // case the stub blocklist of / was expanded to the actual list of top
            // level folders by the selective sync dialog.
            if (result == Gtk.Dialog.Accepted) {
                this.selective_sync_blocklist = dlg.create_block_list ();
                update_blocklist = true;
            } else if (result == Gtk.Dialog.Rejected && this.selective_sync_blocklist == string[] ("/")) {
                this.selective_sync_blocklist = dlg.old_block_list ();
                update_blocklist = true;
            }

            if (update_blocklist) {
                if (!this.selective_sync_blocklist.is_empty ()) {
                    this.ui.r_selective_sync.block_signals (true);
                    set_radio_checked (this.ui.r_selective_sync);
                    this.ui.r_selective_sync.block_signals (false);
                    var s = dlg.estimated_size ();
                    if (s > 0) {
                        this.ui.l_selective_sync_size_label.on_set_text (_(" (%1)").arg (Utility.octets_to_string (s)));
                    } else {
                        this.ui.l_selective_sync_size_label.on_set_text ("");
                    }
                } else {
                    set_radio_checked (this.ui.r_sync_everything);
                    this.ui.l_selective_sync_size_label.on_set_text ("");
                }
                wizard ().set_property ("blocklist", this.selective_sync_blocklist);
            }

            update_status ();

        });
        dlg.open ();
    }

    void Owncloud_advanced_setup_page.on_virtual_file_sync_clicked () {
        if (!this.ui.r_virtual_file_sync.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (this, [this] (bool enable) {
                if (!enable)
                    return;
                set_radio_checked (this.ui.r_virtual_file_sync);
            });
        }
    }

    void Owncloud_advanced_setup_page.on_sync_everything_clicked () {
        this.ui.l_selective_sync_size_label.on_set_text ("");
        set_radio_checked (this.ui.r_sync_everything);
        this.selective_sync_blocklist.clear ();

        string error_str = check_local_space (this.r_size);
        on_set_error_string (error_str);
    }

    void Owncloud_advanced_setup_page.on_quota_retrieved (QVariantMap result) {
        this.r_size = result["size"].to_double ();
        this.ui.l_sync_everything_size_label.on_set_text (_(" (%1)").arg (Utility.octets_to_string (this.r_size)));

        update_status ();
    }

    int64 Owncloud_advanced_setup_page.available_local_space () {
        string local_dir = local_folder ();
        string path = !QDir (local_dir).exists () && local_dir.contains (QDir.home_path ()) ?
                    QDir.home_path () : local_dir;
        QStorage_info storage (QDir.to_native_separators (path));

        return storage.bytes_available ();
    }

    string Owncloud_advanced_setup_page.check_local_space (int64 remote_size) {
        return (available_local_space ()>remote_size) ? "" : _("There isn't enough free space in the local folder!");
    }

    void Owncloud_advanced_setup_page.on_style_changed () {
        customize_style ();
    }

    void Owncloud_advanced_setup_page.customize_style () {
        if (this.progress_indi) {
            const var is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                this.progress_indi.on_set_color (Qt.white);
            } else {
                this.progress_indi.on_set_color (Qt.block);
            }
        }

        style_sync_logo ();
        style_local_folder_label ();
    }

    void Owncloud_advanced_setup_page.style_local_folder_label () {
        const var background_color = palette ().window ().color ();
        const var folder_icon_filename = Theme.instance ().is_branded () ? Theme.hidpi_filename ("folder.png", background_color)
                                                                       : Theme.hidpi_filename (":/client/theme/colored/folder.png");
        this.ui.l_local.set_pixmap (folder_icon_filename);
    }

    void Owncloud_advanced_setup_page.set_radio_checked (QRadio_button radio) {
        // We don't want clicking the radio buttons to immediately adjust the checked state
        // for selective sync and virtual file sync, so we keep them uncheckable until
        // they should be checked.
        radio.set_checkable (true);
        radio.set_checked (true);

        if (radio != this.ui.r_selective_sync)
            this.ui.r_selective_sync.set_checkable (false);
        if (radio != this.ui.r_virtual_file_sync)
            this.ui.r_virtual_file_sync.set_checkable (false);
    }

    void Owncloud_advanced_setup_page.style_sync_logo () {
        const var sync_arrow_icon = Theme.create_color_aware_icon (QLatin1String (":/client/theme/sync-arrow.svg"), palette ());
        this.ui.sync_logo_label.set_pixmap (sync_arrow_icon.pixmap (QSize (50, 50)));
    }

    void Owncloud_advanced_setup_page.setup_resoultion_widget () {
        for (int i = 0; i < this.ui.resolution_widget_layout.count (); ++i) {
            var widget = this.ui.resolution_widget_layout.item_at (i).widget ();
            if (!widget) {
                continue;
            }

            var size_policy = widget.size_policy ();
            size_policy.set_retain_size_when_hidden (true);
            widget.set_size_policy (size_policy);
        }
    }

    } // namespace Occ
    