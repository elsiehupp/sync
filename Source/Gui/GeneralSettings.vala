/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QMessageBox>
// #include <QNetworkProxy>
// #include <QDir>
// #include <QScoped_value_rollback>
// #include <QMessageBox>

// #include <private/qzipwriter_p.h>

const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

#if ! (QTLEGACY)
// #include <QOperating_system_version>
#endif

// #include <Gtk.Widget>
// #include <QPointer>

namespace Occ {

namespace Ui {
    class General_settings;
}

/***********************************************************
@brief The General_settings class
@ingroup gui
***********************************************************/
class General_settings : Gtk.Widget {

    public General_settings (Gtk.Widget *parent = nullptr);
    public ~General_settings () override;
    public QSize size_hint () const override;

public slots:
    void slot_style_changed ();

private slots:
    void save_misc_settings ();
    void slot_toggle_launch_on_startup (bool);
    void slot_toggle_optional_server_notifications (bool);
    void slot_show_in_explorer_navigation_pane (bool);
    void slot_ignore_files_editor ();
    void slot_create_debug_archive ();
    void load_misc_settings ();
    void slot_show_legal_notice ();
#if defined (BUILD_UPDATER)
    void slot_update_info ();
    void slot_update_channel_changed (string &channel);
    void slot_update_check_now ();
    void slot_toggle_auto_update_check ();
#endif

private:
    void customize_style ();

    Ui.General_settings *_ui;
    QPointer<Ignore_list_editor> _ignore_editor;
    bool _currently_loading = false;
};

} // namespace Occ







namespace {
struct Zip_entry {
    string local_filename;
    string zip_filename;
};

Zip_entry file_info_to_zip_entry (QFileInfo &info) {
    return {
        info.absolute_file_path (),
        info.file_name ()
    };
}

Zip_entry file_info_to_log_zip_entry (QFileInfo &info) {
    auto entry = file_info_to_zip_entry (info);
    entry.zip_filename.prepend (QStringLiteral ("logs/"));
    return entry;
}

Zip_entry sync_folder_to_zip_entry (Occ.Folder *f) {
    const auto journal_path = f.journal_db ().database_file_path ();
    const auto journal_info = QFileInfo (journal_path);
    return file_info_to_zip_entry (journal_info);
}

QVector<Zip_entry> create_file_list () {
    auto list = QVector<Zip_entry> ();
    Occ.ConfigFile cfg;

    list.append (file_info_to_zip_entry (QFileInfo (cfg.config_file ())));

    const auto logger = Occ.Logger.instance ();

    if (!logger.log_dir ().is_empty ()) {
        list.append ({string (), QStringLiteral ("logs")});

        QDir dir (logger.log_dir ());
        const auto info_list = dir.entry_info_list (QDir.Files);
        std.transform (std.cbegin (info_list), std.cend (info_list),
                       std.back_inserter (list),
                       file_info_to_log_zip_entry);
    } else if (!logger.log_file ().is_empty ()) {
        list.append (file_info_to_zip_entry (QFileInfo (logger.log_file ())));
    }

    const auto folders = Occ.FolderMan.instance ().map ().values ();
    std.transform (std.cbegin (folders), std.cend (folders),
                   std.back_inserter (list),
                   sync_folder_to_zip_entry);

    return list;
}

void create_debug_archive (string &filename) {
    const auto entries = create_file_list ();

    QZip_writer zip (filename);
    for (auto &entry : entries) {
        if (entry.local_filename.is_empty ()) {
            zip.add_directory (entry.zip_filename);
        } else {
            QFile file (entry.local_filename);
            if (!file.open (QFile.Read_only)) {
                continue;
            }
            zip.add_file (entry.zip_filename, &file);
        }
    }

    zip.add_file ("__nextcloud_client_parameters.txt", QCoreApplication.arguments ().join (' ').to_utf8 ());

    const auto build_info = string (Occ.Theme.instance ().about () + "\n\n" + Occ.Theme.instance ().about_details ());
    zip.add_file ("__nextcloud_client_buildinfo.txt", build_info.to_utf8 ());
}


General_settings.General_settings (Gtk.Widget *parent)
    : Gtk.Widget (parent)
    , _ui (new Ui.General_settings) {
    _ui.setup_ui (this);

    connect (_ui.server_notifications_check_box, &QAbstractButton.toggled,
        this, &General_settings.slot_toggle_optional_server_notifications);
    _ui.server_notifications_check_box.set_tool_tip (tr ("Server notifications that require attention."));

    connect (_ui.show_in_explorer_navigation_pane_check_box, &QAbstractButton.toggled, this, &General_settings.slot_show_in_explorer_navigation_pane);

    // Rename 'Explorer' appropriately on non-Windows

    if (Utility.has_system_launch_on_startup (Theme.instance ().app_name ())) {
        _ui.autostart_check_box.set_checked (true);
        _ui.autostart_check_box.set_disabled (true);
        _ui.autostart_check_box.set_tool_tip (tr ("You cannot disable autostart because system-wide autostart is enabled."));
    } else {
        const bool has_auto_start = Utility.has_launch_on_startup (Theme.instance ().app_name ());
        // make sure the binary location is correctly set
        slot_toggle_launch_on_startup (has_auto_start);
        _ui.autostart_check_box.set_checked (has_auto_start);
        connect (_ui.autostart_check_box, &QAbstractButton.toggled, this, &General_settings.slot_toggle_launch_on_startup);
    }

    // setup about section
    string about = Theme.instance ().about ();
    _ui.about_label.set_text_interaction_flags (Qt.Text_selectable_by_mouse | Qt.Text_browser_interaction);
    _ui.about_label.set_text (about);
    _ui.about_label.set_open_external_links (true);

    // About legal notice
    connect (_ui.legal_notice_button, &QPushButton.clicked, this, &General_settings.slot_show_legal_notice);

    load_misc_settings ();
    // updater info now set in : customize_style
    //slot_update_info ();

    // misc
    connect (_ui.mono_icons_check_box, &QAbstractButton.toggled, this, &General_settings.save_misc_settings);
    connect (_ui.crashreporter_check_box, &QAbstractButton.toggled, this, &General_settings.save_misc_settings);
    connect (_ui.new_folder_limit_check_box, &QAbstractButton.toggled, this, &General_settings.save_misc_settings);
    connect (_ui.new_folder_limit_spin_box, static_cast<void (QSpin_box.*) (int)> (&QSpin_box.value_changed), this, &General_settings.save_misc_settings);
    connect (_ui.new_external_storage, &QAbstractButton.toggled, this, &General_settings.save_misc_settings);

#ifndef WITH_CRASHREPORTER
    _ui.crashreporter_check_box.set_visible (false);
#endif

    // Hide on non-Windows
    _ui.show_in_explorer_navigation_pane_check_box.set_visible (false);

    /* Set the left contents margin of the layout to zero to make the checkboxes
    align properly vertically , fixes bug #3758
    ***********************************************************/
    int m0 = 0;
    int m1 = 0;
    int m2 = 0;
    int m3 = 0;
    _ui.horizontal_layout_3.get_contents_margins (&m0, &m1, &m2, &m3);
    _ui.horizontal_layout_3.set_contents_margins (0, m1, m2, m3);

    // OEM themes are not obliged to ship mono icons, so there
    // is no point in offering an option
    _ui.mono_icons_check_box.set_visible (Theme.instance ().mono_icons_available ());

    connect (_ui.ignored_files_button, &QAbstractButton.clicked, this, &General_settings.slot_ignore_files_editor);
    connect (_ui.debug_archive_button, &QAbstractButton.clicked, this, &General_settings.slot_create_debug_archive);

    // account_added means the wizard was finished and the wizard might change some options.
    connect (AccountManager.instance (), &AccountManager.account_added, this, &General_settings.load_misc_settings);

    customize_style ();
}

General_settings.~General_settings () {
    delete _ui;
}

QSize General_settings.size_hint () {
    return {
        OwncloudGui.settings_dialog_size ().width (),
        Gtk.Widget.size_hint ().height ()
    };
}

void General_settings.load_misc_settings () {
    QScoped_value_rollback<bool> scope (_currently_loading, true);
    ConfigFile cfg_file;
    _ui.mono_icons_check_box.set_checked (cfg_file.mono_icons ());
    _ui.server_notifications_check_box.set_checked (cfg_file.optional_server_notifications ());
    _ui.show_in_explorer_navigation_pane_check_box.set_checked (cfg_file.show_in_explorer_navigation_pane ());
    _ui.crashreporter_check_box.set_checked (cfg_file.crash_reporter ());
    auto new_folder_limit = cfg_file.new_big_folder_size_limit ();
    _ui.new_folder_limit_check_box.set_checked (new_folder_limit.first);
    _ui.new_folder_limit_spin_box.set_value (new_folder_limit.second);
    _ui.new_external_storage.set_checked (cfg_file.confirm_external_storage ());
    _ui.mono_icons_check_box.set_checked (cfg_file.mono_icons ());
}

#if defined (BUILD_UPDATER)
void General_settings.slot_update_info () {
    if (ConfigFile ().skip_update_check () || !Updater.instance ()) {
        // updater disabled on compile
        _ui.updates_group_box.set_visible (false);
        return;
    }

    // Note : the sparkle-updater is not an OCUpdater
    auto *ocupdater = qobject_cast<OCUpdater> (Updater.instance ());
    if (ocupdater) {
        connect (ocupdater, &OCUpdater.download_state_changed, this, &General_settings.slot_update_info, Qt.UniqueConnection);
        connect (_ui.restart_button, &QAbstractButton.clicked, ocupdater, &OCUpdater.slot_start_installer, Qt.UniqueConnection);
        connect (_ui.restart_button, &QAbstractButton.clicked, q_app, &QApplication.quit, Qt.UniqueConnection);
        connect (_ui.update_button, &QAbstractButton.clicked, this, &General_settings.slot_update_check_now, Qt.UniqueConnection);
        connect (_ui.auto_check_for_updates_check_box, &QAbstractButton.toggled, this, &General_settings.slot_toggle_auto_update_check);

        string status = ocupdater.status_string (OCUpdater.Update_status_string_format.Html);
        Theme.replace_link_color_string_background_aware (status);

        _ui.update_state_label.set_open_external_links (false);
        connect (_ui.update_state_label, &QLabel.link_activated, this, [] (string &link) {
            Utility.open_browser (QUrl (link));
        });
        _ui.update_state_label.set_text (status);

        _ui.restart_button.set_visible (ocupdater.download_state () == OCUpdater.Download_complete);

        _ui.update_button.set_enabled (ocupdater.download_state () != OCUpdater.Checking_server &&
                                      ocupdater.download_state () != OCUpdater.Downloading &&
                                      ocupdater.download_state () != OCUpdater.Download_complete);

        _ui.auto_check_for_updates_check_box.set_checked (ConfigFile ().auto_update_check ());
    }

    // Channel selection
    _ui.update_channel.set_current_index (ConfigFile ().update_channel () == "beta" ? 1 : 0);
    connect (_ui.update_channel, &QCombo_box.current_text_changed,
        this, &General_settings.slot_update_channel_changed, Qt.UniqueConnection);
}

void General_settings.slot_update_channel_changed (string &channel) {
    if (channel == ConfigFile ().update_channel ())
        return;

    auto msg_box = new QMessageBox (
        QMessageBox.Warning,
        tr ("Change update channel?"),
        tr ("The update channel determines which client updates will be offered "
           "for installation. The \"stable\" channel contains only upgrades that "
           "are considered reliable, while the versions in the \"beta\" channel "
           "may contain newer features and bugfixes, but have not yet been tested "
           "thoroughly."
           "\n\n"
           "Note that this selects only what pool upgrades are taken from, and that "
           "there are no downgrades : So going back from the beta channel to "
           "the stable channel usually cannot be done immediately and means waiting "
           "for a stable version that is newer than the currently installed beta "
           "version."),
        QMessageBox.NoButton,
        this);
    auto accept_button = msg_box.add_button (tr ("Change update channel"), QMessageBox.AcceptRole);
    msg_box.add_button (tr ("Cancel"), QMessageBox.RejectRole);
    connect (msg_box, &QMessageBox.finished, msg_box, [this, channel, msg_box, accept_button] {
        msg_box.delete_later ();
        if (msg_box.clicked_button () == accept_button) {
            ConfigFile ().set_update_channel (channel);
            if (auto updater = qobject_cast<OCUpdater> (Updater.instance ())) {
                updater.set_update_url (Updater.update_url ());
                updater.check_for_update ();
            }
        } else {
            _ui.update_channel.set_current_text (ConfigFile ().update_channel ());
        }
    });
    msg_box.open ();
}

void General_settings.slot_update_check_now () {
    auto *updater = qobject_cast<OCUpdater> (Updater.instance ());
    if (ConfigFile ().skip_update_check ()) {
        updater = nullptr; // don't show update info if updates are disabled
    }

    if (updater) {
        _ui.update_button.set_enabled (false);

        updater.check_for_update ();
    }
}

void General_settings.slot_toggle_auto_update_check () {
    ConfigFile cfg_file;
    bool is_checked = _ui.auto_check_for_updates_check_box.is_checked ();
    cfg_file.set_auto_update_check (is_checked, string ());
}
#endif // defined (BUILD_UPDATER)

void General_settings.save_misc_settings () {
    if (_currently_loading)
        return;
    ConfigFile cfg_file;
    bool is_checked = _ui.mono_icons_check_box.is_checked ();
    cfg_file.set_mono_icons (is_checked);
    Theme.instance ().set_systray_use_mono_icons (is_checked);
    cfg_file.set_crash_reporter (_ui.crashreporter_check_box.is_checked ());

    cfg_file.set_new_big_folder_size_limit (_ui.new_folder_limit_check_box.is_checked (),
        _ui.new_folder_limit_spin_box.value ());
    cfg_file.set_confirm_external_storage (_ui.new_external_storage.is_checked ());
}

void General_settings.slot_toggle_launch_on_startup (bool enable) {
    Theme *theme = Theme.instance ();
    Utility.set_launch_on_startup (theme.app_name (), theme.app_name_g_u_i (), enable);
}

void General_settings.slot_toggle_optional_server_notifications (bool enable) {
    ConfigFile cfg_file;
    cfg_file.set_optional_server_notifications (enable);
}

void General_settings.slot_show_in_explorer_navigation_pane (bool checked) {
    ConfigFile cfg_file;
    cfg_file.set_show_in_explorer_navigation_pane (checked);
    // Now update the registry with the change.
    FolderMan.instance ().navigation_pane_helper ().set_show_in_explorer_navigation_pane (checked);
}

void General_settings.slot_ignore_files_editor () {
    if (_ignore_editor.is_null ()) {
        ConfigFile cfg_file;
        _ignore_editor = new Ignore_list_editor (this);
        _ignore_editor.set_attribute (Qt.WA_DeleteOnClose, true);
        _ignore_editor.open ();
    } else {
        OwncloudGui.raise_dialog (_ignore_editor);
    }
}

void General_settings.slot_create_debug_archive () {
    const auto filename = QFileDialog.get_save_file_name (this, tr ("Create Debug Archive"), string (), tr ("Zip Archives") + " (*.zip)");
    if (filename.is_empty ()) {
        return;
    }

    create_debug_archive (filename);
    QMessageBox.information (this, tr ("Debug Archive Created"), tr ("Debug archive is created at %1").arg (filename));
}

void General_settings.slot_show_legal_notice () {
    auto notice = new Legal_notice ();
    notice.exec ();
    delete notice;
}

void General_settings.slot_style_changed () {
    customize_style ();
}

void General_settings.customize_style () {
    // setup about section
    string about = Theme.instance ().about ();
    Theme.replace_link_color_string_background_aware (about);
    _ui.about_label.set_text (about);

#if defined (BUILD_UPDATER)
    // updater info
    slot_update_info ();
#else
    _ui.updates_group_box.set_visible (false);
#endif
}

} // namespace Occ
