/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QFileDialog>
// #include <QUrl>
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
public:
    Owncloud_advanced_setup_page (OwncloudWizard *wizard);

    bool is_complete () const override;
    void initialize_page () override;
    int next_id () const override;
    bool validate_page () override;
    string local_folder ();
    QStringList selective_sync_blacklist ();
    bool use_virtual_file_sync ();
    bool is_confirm_big_folder_checked ();
    void set_remote_folder (string &remote_folder);
    void set_multiple_folders_exist (bool exist);
    void directories_created ();

signals:
    void create_local_and_remote_folders (string &, string &);

public slots:
    void set_error_string (string &);
    void slot_style_changed ();

private slots:
    void slot_select_folder ();
    void slot_sync_everything_clicked ();
    void slot_selective_sync_clicked ();
    void slot_virtual_file_sync_clicked ();
    void slot_quota_retrieved (QVariantMap &result);

private:
    void set_radio_checked (QRadio_button *radio);

    void setup_customization ();
    void update_status ();
    bool data_changed ();
    void start_spinner ();
    void stop_spinner ();
    QUrl server_url ();
    int64 available_local_space ();
    string check_local_space (int64 remote_size) const;
    void customize_style ();
    void set_server_address_label_url (QUrl &url);
    void set_local_folder_push_button_path (string &path);
    void style_sync_logo ();
    void style_local_folder_label ();
    void set_resolution_gui_visible (bool value);
    void setup_resoultion_widget ();
    void fetch_user_avatar ();
    void set_user_information ();

    // TODO : remove when UX decision is made
    void refresh_virtual_files_availibility (string &path);

    Ui_Owncloud_advanced_setup_page _ui;
    bool _checking = false;
    bool _created = false;
    bool _local_folder_valid = false;
    QProgress_indicator *_progress_indi;
    string _remote_folder;
    QStringList _selective_sync_blacklist;
    int64 _r_size = -1;
    int64 _r_selected_size = -1;
    OwncloudWizard *_oc_wizard;
};

    Owncloud_advanced_setup_page.Owncloud_advanced_setup_page (OwncloudWizard *wizard)
        : QWizard_page ()
        , _progress_indi (new QProgress_indicator (this))
        , _oc_wizard (wizard) {
        _ui.setup_ui (this);

        setup_resoultion_widget ();

        register_field (QLatin1String ("OCSync_from_scratch"), _ui.cb_sync_from_scratch);

        auto size_policy = _progress_indi.size_policy ();
        size_policy.set_retain_size_when_hidden (true);
        _progress_indi.set_size_policy (size_policy);

        _ui.result_layout.add_widget (_progress_indi);
        stop_spinner ();
        setup_customization ();

        connect (_ui.pb_select_local_folder, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.slot_select_folder);
        set_button_text (QWizard.Finish_button, tr ("Connect"));

        if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
            _ui.r_sync_everything.set_disabled (true);
            _ui.r_selective_sync.set_disabled (true);
            _ui.b_selective_sync.set_disabled (true);
        }

        connect (_ui.r_sync_everything, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.slot_sync_everything_clicked);
        connect (_ui.r_selective_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.slot_selective_sync_clicked);
        connect (_ui.r_virtual_file_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.slot_virtual_file_sync_clicked);
        connect (_ui.r_virtual_file_sync, &QRadio_button.toggled, this, [this] (bool checked) {
            if (checked) {
                _ui.l_selective_sync_size_label.clear ();
                _selective_sync_blacklist.clear ();
            }
        });
        connect (_ui.b_selective_sync, &QAbstractButton.clicked, this, &Owncloud_advanced_setup_page.slot_selective_sync_clicked);

        const auto theme = Theme.instance ();
        const auto app_icon = theme.application_icon ();
        const auto app_icon_size = Theme.is_hidpi () ? 128 : 64;

        _ui.l_server_icon.set_pixmap (app_icon.pixmap (app_icon_size));

        if (theme.wizard_hide_external_storage_confirmation_checkbox ()) {
            _ui.conf_check_box_external.hide ();
        }
        if (theme.wizard_hide_folder_size_limit_checkbox ()) {
            _ui.conf_check_box_size.hide ();
            _ui.conf_spin_box.hide ();
            _ui.conf_trailling_size_label.hide ();
        }

        _ui.r_virtual_file_sync.set_text (tr ("Use &virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
    }

    void Owncloud_advanced_setup_page.setup_customization () {
        // set defaults for the customize labels.
        _ui.top_label.hide ();
        _ui.bottom_label.hide ();

        Theme *theme = Theme.instance ();
        QVariant variant = theme.custom_media (Theme.o_c_setup_top);
        if (!variant.is_null ()) {
            WizardCommon.setup_custom_media (variant, _ui.top_label);
        }

        variant = theme.custom_media (Theme.o_c_setup_bottom);
        WizardCommon.setup_custom_media (variant, _ui.bottom_label);

        WizardCommon.customize_hint_label (_ui.l_free_space);
        WizardCommon.customize_hint_label (_ui.l_sync_everything_size_label);
        WizardCommon.customize_hint_label (_ui.l_selective_sync_size_label);
        WizardCommon.customize_hint_label (_ui.server_address_label);
    }

    bool Owncloud_advanced_setup_page.is_complete () {
        return !_checking && _local_folder_valid;
    }

    void Owncloud_advanced_setup_page.initialize_page () {
        WizardCommon.init_error_label (_ui.error_label);

        if (!Theme.instance ().show_virtual_files_option () || best_available_vfs_mode () == Vfs.Off) {
            // If the layout were wrapped in a widget, the auto-grouping of the
            // radio buttons no longer works and there are surprising margins.
            // Just manually hide the button and remove the layout.
            _ui.r_virtual_file_sync.hide ();
            _ui.w_sync_strategy.layout ().remove_item (_ui.l_virtual_file_sync);
        }

        _checking = false;
        _ui.l_selective_sync_size_label.clear ();
        _ui.l_sync_everything_size_label.clear ();

        // Update the local folder - this is not guaranteed to find a good one
        string good_local_folder = FolderMan.instance ().find_good_path_for_new_sync_folder (local_folder (), server_url ());
        wizard ().set_property ("local_folder", good_local_folder);

        // call to init label
        update_status ();

        // ensure "next" gets the focus, not ob_select_local_folder
        QTimer.single_shot (0, wizard ().button (QWizard.Finish_button), q_overload<> (&Gtk.Widget.set_focus));

        auto acc = static_cast<OwncloudWizard> (wizard ()).account ();
        auto quota_job = new PropfindJob (acc, _remote_folder, this);
        quota_job.set_properties (QList<QByteArray> () << "http://owncloud.org/ns:size");

        connect (quota_job, &PropfindJob.result, this, &Owncloud_advanced_setup_page.slot_quota_retrieved);
        quota_job.start ();

        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            _selective_sync_blacklist = QStringList ("/");
            set_radio_checked (_ui.r_selective_sync);
            QTimer.single_shot (0, this, &Owncloud_advanced_setup_page.slot_selective_sync_clicked);
        }

        ConfigFile cfg_file;
        auto new_folder_limit = cfg_file.new_big_folder_size_limit ();
        _ui.conf_check_box_size.set_checked (new_folder_limit.first);
        _ui.conf_spin_box.set_value (new_folder_limit.second);
        _ui.conf_check_box_external.set_checked (cfg_file.confirm_external_storage ());

        fetch_user_avatar ();
        set_user_information ();

        customize_style ();

        auto next_button = qobject_cast<QPushButton> (_oc_wizard.button (QWizard.Next_button));
        if (next_button) {
            next_button.set_default (true);
        }
    }

    void Owncloud_advanced_setup_page.fetch_user_avatar () {
        // Reset user avatar
        const auto app_icon = Theme.instance ().application_icon ();
        _ui.l_server_icon.set_pixmap (app_icon.pixmap (48));
        // Fetch user avatar
        const auto account = _oc_wizard.account ();
        auto avatar_size = 64;
        if (Theme.is_hidpi ()) {
            avatar_size *= 2;
        }
        const auto avatar_job = new AvatarJob (account, account.dav_user (), avatar_size, this);
        avatar_job.set_timeout (20 * 1000);
        GLib.Object.connect (avatar_job, &AvatarJob.avatar_pixmap, this, [this] (QImage &avatar_image) {
            if (avatar_image.is_null ()) {
                return;
            }
            const auto avatar_pixmap = QPixmap.from_image (AvatarJob.make_circular_avatar (avatar_image));
            _ui.l_server_icon.set_pixmap (avatar_pixmap);
        });
        avatar_job.start ();
    }

    void Owncloud_advanced_setup_page.set_user_information () {
        const auto account = _oc_wizard.account ();
        const auto server_url = account.url ().to_string ();
        set_server_address_label_url (server_url);
        const auto user_name = account.dav_display_name ();
        _ui.user_name_label.set_text (user_name);
    }

    void Owncloud_advanced_setup_page.refresh_virtual_files_availibility (string &path) {
        // TODO : remove when UX decision is made
        if (!_ui.r_virtual_file_sync.is_visible ()) {
            return;
        }

        if (Utility.is_path_windows_drive_partition_root (path)) {
            _ui.r_virtual_file_sync.set_text (tr ("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            set_radio_checked (_ui.r_sync_everything);
            _ui.r_virtual_file_sync.set_enabled (false);
        } else {
            _ui.r_virtual_file_sync.set_text (tr ("Use &virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
            _ui.r_virtual_file_sync.set_enabled (true);
        }
        //
    }

    void Owncloud_advanced_setup_page.set_server_address_label_url (QUrl &url) {
        if (!url.is_valid ()) {
            return;
        }

        const auto pretty_url = url.to_string ().mid (url.scheme ().size () + 3); // + 3 because we need to remove ://
        _ui.server_address_label.set_text (pretty_url);
    }

    // Called if the user changes the user- or url field. Adjust the texts and
    // evtl. warnings on the dialog.
    void Owncloud_advanced_setup_page.update_status () {
        const string loc_folder = local_folder ();

        // check if the local folder exists. If so, and if its not empty, show a warning.
        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (loc_folder, server_url ());
        _local_folder_valid = error_str.is_empty ();

        string t;

        set_local_folder_push_button_path (loc_folder);

        if (data_changed ()) {
            if (_remote_folder.is_empty () || _remote_folder == QLatin1String ("/")) {
                t = "";
            } else {
                t = Utility.escape (tr (R" (%1 folder "%2" is synced to local folder "%3")")
                                        .arg (Theme.instance ().app_name (), _remote_folder,
                                            QDir.to_native_separators (loc_folder)));
                _ui.r_sync_everything.set_text (tr ("Sync the folder \"%1\"").arg (_remote_folder));
            }

            const bool dir_not_empty (QDir (loc_folder).entry_list (QDir.AllEntries | QDir.NoDotAndDotDot).count () > 0);
            if (dir_not_empty) {
                t += tr ("Warning : The local folder is not empty. Pick a resolution!");
            }
            set_resolution_gui_visible (dir_not_empty);
        } else {
            set_resolution_gui_visible (false);
        }

        string lfree_space_str = Utility.octets_to_string (available_local_space ());
        _ui.l_free_space.set_text (string (tr ("%1 free space", "%1 gets replaced with the size and a matching unit. Example : 3 MB or 5 GB")).arg (lfree_space_str));

        _ui.sync_mode_label.set_text (t);
        _ui.sync_mode_label.set_fixed_height (_ui.sync_mode_label.size_hint ().height ());

        int64 r_space = _ui.r_sync_everything.is_checked () ? _r_size : _r_selected_size;

        string space_error = check_local_space (r_space);
        if (!space_error.is_empty ()) {
            error_str = space_error;
        }
        set_error_string (error_str);

        emit complete_changed ();
    }

    void Owncloud_advanced_setup_page.set_resolution_gui_visible (bool value) {
        _ui.sync_mode_label.set_visible (value);
        _ui.r_keep_local.set_visible (value);
        _ui.cb_sync_from_scratch.set_visible (value);
    }

    /* obsolete */
    bool Owncloud_advanced_setup_page.data_changed () {
        return true;
    }

    void Owncloud_advanced_setup_page.start_spinner () {
        _ui.result_layout.set_enabled (true);
        _progress_indi.set_visible (true);
        _progress_indi.start_animation ();
    }

    void Owncloud_advanced_setup_page.stop_spinner () {
        _ui.result_layout.set_enabled (false);
        _progress_indi.set_visible (false);
        _progress_indi.stop_animation ();
    }

    QUrl Owncloud_advanced_setup_page.server_url () {
        const string url_string = static_cast<OwncloudWizard> (wizard ()).oc_url ();
        const string user = static_cast<OwncloudWizard> (wizard ()).get_credentials ().user ();

        QUrl url (url_string);
        url.set_user_name (user);
        return url;
    }

    int Owncloud_advanced_setup_page.next_id () {
        // tells the caller that this is the last dialog page
        return -1;
    }

    string Owncloud_advanced_setup_page.local_folder () {
        string folder = wizard ().property ("local_folder").to_string ();
        return folder;
    }

    QStringList Owncloud_advanced_setup_page.selective_sync_blacklist () {
        return _selective_sync_blacklist;
    }

    bool Owncloud_advanced_setup_page.use_virtual_file_sync () {
        return _ui.r_virtual_file_sync.is_checked ();
    }

    bool Owncloud_advanced_setup_page.is_confirm_big_folder_checked () {
        return _ui.r_sync_everything.is_checked () && _ui.conf_check_box_size.is_checked ();
    }

    bool Owncloud_advanced_setup_page.validate_page () {
        if (use_virtual_file_sync ()) {
            const auto availability = Vfs.check_availability (local_folder ());
            if (!availability) {
                auto msg = new QMessageBox (QMessageBox.Warning, tr ("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                msg.set_attribute (Qt.WA_DeleteOnClose);
                msg.open ();
                return false;
            }
        }

        if (!_created) {
            set_error_string (string ());
            _checking = true;
            start_spinner ();
            emit complete_changed ();

            if (_ui.r_sync_everything.is_checked ()) {
                ConfigFile cfg_file;
                cfg_file.set_new_big_folder_size_limit (_ui.conf_check_box_size.is_checked (),
                    _ui.conf_spin_box.value ());
                cfg_file.set_confirm_external_storage (_ui.conf_check_box_external.is_checked ());
            }

            emit create_local_and_remote_folders (local_folder (), _remote_folder);
            return false;
        } else {
            // connecting is running
            _checking = false;
            emit complete_changed ();
            stop_spinner ();
            return true;
        }
    }

    void Owncloud_advanced_setup_page.set_error_string (string &err) {
        if (err.is_empty ()) {
            _ui.error_label.set_visible (false);
        } else {
            _ui.error_label.set_visible (true);
            _ui.error_label.set_text (err);
        }
        _checking = false;
        emit complete_changed ();
    }

    void Owncloud_advanced_setup_page.directories_created () {
        _checking = false;
        _created = true;
        stop_spinner ();
        emit complete_changed ();
    }

    void Owncloud_advanced_setup_page.set_remote_folder (string &remote_folder) {
        if (!remote_folder.is_empty ()) {
            _remote_folder = remote_folder;
        }
    }

    void Owncloud_advanced_setup_page.slot_select_folder () {
        string dir = QFileDialog.get_existing_directory (nullptr, tr ("Local Sync Folder"), QDir.home_path ());
        if (!dir.is_empty ()) {
            // TODO : remove when UX decision is made
            refresh_virtual_files_availibility (dir);

            set_local_folder_push_button_path (dir);
            wizard ().set_property ("local_folder", dir);
            update_status ();
        }

        int64 r_space = _ui.r_sync_everything.is_checked () ? _r_size : _r_selected_size;
        string error_str = check_local_space (r_space);
        set_error_string (error_str);
    }

    void Owncloud_advanced_setup_page.set_local_folder_push_button_path (string &path) {
        const auto home_dir = QDir.home_path ().ends_with ('/') ? QDir.home_path () : QDir.home_path () + QLatin1Char ('/');

        if (!path.starts_with (home_dir)) {
            _ui.pb_select_local_folder.set_text (QDir.to_native_separators (path));
            return;
        }

        auto pretty_path = path;
        pretty_path.remove (0, home_dir.size ());

        _ui.pb_select_local_folder.set_text (QDir.to_native_separators (pretty_path));
    }

    void Owncloud_advanced_setup_page.slot_selective_sync_clicked () {
        AccountPtr acc = static_cast<OwncloudWizard> (wizard ()).account ();
        auto *dlg = new Selective_sync_dialog (acc, _remote_folder, _selective_sync_blacklist, this);
        dlg.set_attribute (Qt.WA_DeleteOnClose);

        connect (dlg, &Selective_sync_dialog.finished, this, [this, dlg]{
            const int result = dlg.result ();
            bool update_blacklist = false;

            // We need to update the selective sync blacklist either when the dialog
            // was accepted in that
            // case the stub blacklist of / was expanded to the actual list of top
            // level folders by the selective sync dialog.
            if (result == Gtk.Dialog.Accepted) {
                _selective_sync_blacklist = dlg.create_black_list ();
                update_blacklist = true;
            } else if (result == Gtk.Dialog.Rejected && _selective_sync_blacklist == QStringList ("/")) {
                _selective_sync_blacklist = dlg.old_black_list ();
                update_blacklist = true;
            }

            if (update_blacklist) {
                if (!_selective_sync_blacklist.is_empty ()) {
                    _ui.r_selective_sync.block_signals (true);
                    set_radio_checked (_ui.r_selective_sync);
                    _ui.r_selective_sync.block_signals (false);
                    auto s = dlg.estimated_size ();
                    if (s > 0) {
                        _ui.l_selective_sync_size_label.set_text (tr (" (%1)").arg (Utility.octets_to_string (s)));
                    } else {
                        _ui.l_selective_sync_size_label.set_text (string ());
                    }
                } else {
                    set_radio_checked (_ui.r_sync_everything);
                    _ui.l_selective_sync_size_label.set_text (string ());
                }
                wizard ().set_property ("blacklist", _selective_sync_blacklist);
            }

            update_status ();

        });
        dlg.open ();
    }

    void Owncloud_advanced_setup_page.slot_virtual_file_sync_clicked () {
        if (!_ui.r_virtual_file_sync.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (this, [this] (bool enable) {
                if (!enable)
                    return;
                set_radio_checked (_ui.r_virtual_file_sync);
            });
        }
    }

    void Owncloud_advanced_setup_page.slot_sync_everything_clicked () {
        _ui.l_selective_sync_size_label.set_text (string ());
        set_radio_checked (_ui.r_sync_everything);
        _selective_sync_blacklist.clear ();

        string error_str = check_local_space (_r_size);
        set_error_string (error_str);
    }

    void Owncloud_advanced_setup_page.slot_quota_retrieved (QVariantMap &result) {
        _r_size = result["size"].to_double ();
        _ui.l_sync_everything_size_label.set_text (tr (" (%1)").arg (Utility.octets_to_string (_r_size)));

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
        return (available_local_space ()>remote_size) ? string () : tr ("There isn't enough free space in the local folder!");
    }

    void Owncloud_advanced_setup_page.slot_style_changed () {
        customize_style ();
    }

    void Owncloud_advanced_setup_page.customize_style () {
        if (_progress_indi) {
            const auto is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                _progress_indi.set_color (Qt.white);
            } else {
                _progress_indi.set_color (Qt.black);
            }
        }

        style_sync_logo ();
        style_local_folder_label ();
    }

    void Owncloud_advanced_setup_page.style_local_folder_label () {
        const auto background_color = palette ().window ().color ();
        const auto folder_icon_file_name = Theme.instance ().is_branded () ? Theme.hidpi_file_name ("folder.png", background_color)
                                                                       : Theme.hidpi_file_name (":/client/theme/colored/folder.png");
        _ui.l_local.set_pixmap (folder_icon_file_name);
    }

    void Owncloud_advanced_setup_page.set_radio_checked (QRadio_button *radio) {
        // We don't want clicking the radio buttons to immediately adjust the checked state
        // for selective sync and virtual file sync, so we keep them uncheckable until
        // they should be checked.
        radio.set_checkable (true);
        radio.set_checked (true);

        if (radio != _ui.r_selective_sync)
            _ui.r_selective_sync.set_checkable (false);
        if (radio != _ui.r_virtual_file_sync)
            _ui.r_virtual_file_sync.set_checkable (false);
    }

    void Owncloud_advanced_setup_page.style_sync_logo () {
        const auto sync_arrow_icon = Theme.create_color_aware_icon (QLatin1String (":/client/theme/sync-arrow.svg"), palette ());
        _ui.sync_logo_label.set_pixmap (sync_arrow_icon.pixmap (QSize (50, 50)));
    }

    void Owncloud_advanced_setup_page.setup_resoultion_widget () {
        for (int i = 0; i < _ui.resolution_widget_layout.count (); ++i) {
            auto widget = _ui.resolution_widget_layout.item_at (i).widget ();
            if (!widget) {
                continue;
            }

            auto size_policy = widget.size_policy ();
            size_policy.set_retain_size_when_hidden (true);
            widget.set_size_policy (size_policy);
        }
    }

    } // namespace Occ
    