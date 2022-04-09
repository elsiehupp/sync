/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.FileDialog>
//  #include <Gtk.MessageBox>
//  #include <Soup.NetworkProxy>
//  #include <GLib.Dir>
//  #include <GLib.ScopedValueRollback>
//  #include <Gtk.MessageBox>
//  #include <private/qzipwriter_p.h>

//  const int GLib.TLEGACY (GLib.T_VERSION < GLib.T_VERSION_CHECK (5,9,0))

//  #if ! (GLib.TLEGACY)
//  #include <GLib.OperatingSystemVersion>
//  #endif

//  #include <Gtk.Widget>
//  #include <GLib.Pointer>


namespace Occ {
namespace Ui {

/***********************************************************
@brief The GeneralSettings class
@ingroup gui
***********************************************************/
public class GeneralSettings : Gtk.Widget {

    class ZipEntry {

        public string local_filename;
        public string zip_filename;

        public static ZipEntry file_info_to_zip_entry (GLib.FileInfo info) {
            return new ZipEntry (
                info.absolute_file_path,
                info.filename ()
            );
        }

        public static ZipEntry file_info_to_log_zip_entry (GLib.FileInfo info) {
            var entry = file_info_to_zip_entry (info);
            entry.zip_filename.prepend ("logs/");
            return entry;
        }

        public static ZipEntry sync_folder_to_zip_entry (FolderConnection f) {
            var journal_path = f.journal_database ().database_file_path;
            var journal_info = GLib.FileInfo (journal_path);
            return file_info_to_zip_entry (journal_info);
        }

        public static GLib.List<ZipEntry> create_file_list () {
            var list = new GLib.List<ZipEntry> ();
            ConfigFile config;

            list.append (file_info_to_zip_entry (new GLib.FileInfo (config.config_file ())));

            var logger = LibSync.Logger.instance;

            if (!logger.log_dir () == "") {
                list.append ({"", "logs"});

                GLib.Dir directory = new GLib.Dir (logger.log_dir ());
                var info_list = directory.entry_info_list (GLib.Dir.Files);
                std.transform (std.cbegin (info_list), std.cend (info_list),
                            std.back_inserter (list),
                            file_info_to_log_zip_entry);
            } else if (!logger.log_file () == "") {
                list.append (file_info_to_zip_entry (new GLib.FileInfo (logger.log_file ())));
            }

            var folders = FolderManager.instance.map ().values ();
            std.transform (std.cbegin (folders), std.cend (folders),
                        std.back_inserter (list),
                        sync_folder_to_zip_entry);

            return list;
        }

        public static void create_debug_archive (string filename) {
            var entries = create_file_list ();

            GLib.ZipWriter zip = new GLib.ZipWriter (filename);
            foreach (var entry in entries) {
                if (entry.local_filename == "") {
                    zip.add_directory (entry.zip_filename);
                } else {
                    GLib.File file = GLib.File.new_for_path (entry.local_filename);
                    if (!file.open (GLib.File.ReadOnly)) {
                        continue;
                    }
                    zip.add_file (entry.zip_filename, file);
                }
            }

            zip.add_file ("__nextcloud_client_parameters.txt", GLib.Application.arguments ().join (' ').to_utf8 ());

            string build_info = Theme.about + "\n\n" + Theme.about_details;
            zip.add_file ("__nextcloud_client_buildinfo.txt", build_info.to_utf8 ());
        }
    }

    /***********************************************************
    ***********************************************************/
    private GeneralSettings instance;
    private IgnoreListEditor ignore_editor;
    private bool currently_loading = false;

    /***********************************************************
    ***********************************************************/
    public GeneralSettings (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new GeneralSettings ();
        this.instance.up_ui (this);

        this.instance.server_notifications_check_box.toggled.connect (
            this.on_signal_toggle_optional_server_notifications
        );
        this.instance.server_notifications_check_box.tool_tip (_("Server notifications that require attention."));

        this.instance.show_in_explorer_navigation_pane_check_box.toggled.connect (
            this.on_signal_show_in_explorer_navigation_pane
        );

        // Rename 'Explorer' appropriately on non-Windows

        if (Utility.has_system_launch_on_signal_startup (Theme.app_name)) {
            this.instance.autostart_check_box.checked (true);
            this.instance.autostart_check_box.disabled (true);
            this.instance.autostart_check_box.tool_tip (_("You cannot disable autostart because system-wide autostart is enabled."));
        } else {
            bool has_auto_start = Utility.has_launch_on_signal_startup (Theme.app_name);
            // make sure the binary location is correctly set
            on_signal_toggle_launch_on_signal_startup (has_auto_start);
            this.instance.autostart_check_box.checked (has_auto_start);
            this.instance.autostart_check_box.toggled.connect (
                this.on_signal_toggle_launch_on_signal_startup
            );
        }

        // setup about section
        string about = Theme.about;
        this.instance.about_label.text_interaction_flags (GLib.Text_selectable_by_mouse | GLib.TextBrowserInteraction);
        this.instance.about_label.on_signal_text (about);
        this.instance.about_label.open_external_links (true);

        // About legal notice
        this.instance.legal_notice_button.clicked.connect (
            this.on_signal_legal_notice_button_clicked
        );

        load_misc_settings ();
        // updater info now set in : customize_style
        //update_info ();

        // misc
        this.instance.mono_icons_check_box.toggled.connect (
            this.on_signal_mono_icons_check_box_toggled
        );
        this.instance.crashreporter_check_box.toggled.connect (
            this.on_signal_crashreporter_check_box_toggled
        );
        this.instance.new_folder_limit_check_box.toggled.connect (
            this.on_signal_new_folder_limit_check_box_toggled
        );
        this.instance.new_folder_limit_spin_box.value_changed.connect (
            this.on_signal_new_folder_limit_spin_box_value_changed
        );
        this.instance.new_external_storage.toggled.connect (
            this.on_signal_new_external_storage_toggled
        );

    //  #ifndef WITH_CRASHREPORTER
        this.instance.crashreporter_check_box.visible (false);
    //  #endif

        // Hide on non-Windows
        this.instance.show_in_explorer_navigation_pane_check_box.visible (false);

        /* Set the left contents margin of the layout to zero to make the checkboxes
        align properly vertically , fixes bug #3758
        ***********************************************************/
        int m0 = 0;
        int m1 = 0;
        int m2 = 0;
        int m3 = 0;
        this.instance.horizontal_layout_3.contents_margins (m0, m1, m2, m3);
        this.instance.horizontal_layout_3.contents_margins (0, m1, m2, m3);

        // OEM themes are not obliged to ship mono icons, so there
        // is no point in offering an option
        this.instance.mono_icons_check_box.visible (
            Theme.mono_icons_available
        );

        this.instance.ignored_files_button.clicked.connect (
            this.on_signal_ignored_files_button_clicked
        );
        this.instance.debug_archive_button.clicked.connect (
            this.on_signal_debug_archive_button_clicked
        );

        // signal_account_added means the wizard was finished and the wizard might change some options.
        AccountManager.instance.signal_account_added.connect (
            this.on_signal_account_added
        );

        customize_style ();
    }


    private delegate void SpinBoxValueChanged (GLib.SpinBox spinbox, int value);


    override ~GeneralSettings () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public override Gdk.Rectangle size_hint () {
        return Gdk.Rectangle (
            OwncloudGui.settings_dialog_size ().width (),
            Gtk.Widget.size_hint ().height ()
        );
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    private void on_signal_mono_icons_check_box_toggled () {
        this.save_misc_settings ();
    }

    private void on_signal_crashreporter_check_box_toggled () {
        this.save_misc_settings ();
    }

    private void on_signal_new_folder_limit_check_box_toggled () {
        this.save_misc_settings ();
    }

    private void on_signal_new_folder_limit_spin_box_value_changed () {
        this.save_misc_settings ();
    }

    private void on_signal_new_external_storage_toggled () {
        this.save_misc_settings ();
    }


    /***********************************************************
    ***********************************************************/
    private void save_misc_settings () {
        if (this.currently_loading) {
            return;
        }
        ConfigFile config_file;
        bool is_checked = this.instance.mono_icons_check_box.is_checked ();
        config_file.mono_icons (is_checked);
        Theme.systray_use_mono_icons (is_checked);
        config_file.crash_reporter (this.instance.crashreporter_check_box.is_checked ());

        config_file.new_big_folder_size_limit (this.instance.new_folder_limit_check_box.is_checked (),
            this.instance.new_folder_limit_spin_box.value ());
        config_file.confirm_external_storage (this.instance.new_external_storage.is_checked ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_toggle_launch_on_signal_startup (bool enable) {
        Theme theme = Theme.instance;
        Utility.launch_on_signal_startup (theme.app_name, theme.app_name_gui, enable);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_toggle_optional_server_notifications (bool enable) {
        ConfigFile config_file;
        config_file.optional_server_notifications (enable);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_show_in_explorer_navigation_pane (bool checked) {
        ConfigFile config_file;
        config_file.show_in_explorer_navigation_pane (checked);
        // Now update the registry with the change.
        FolderManager.instance.navigation_pane_helper.show_in_explorer_navigation_pane = checked;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ignored_files_button_clicked () {
        if (this.ignore_editor == null) {
            ConfigFile config_file;
            this.ignore_editor = new IgnoreListEditor (this);
            this.ignore_editor.attribute (GLib.WA_DeleteOnClose, true);
            this.ignore_editor.open ();
        } else {
            OwncloudGui.raise_dialog (this.ignore_editor);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_debug_archive_button_clicked () {
        var filename = GLib.FileDialog.save_filename (this, _("Create Debug Archive"), "", _("Zip Archives") + " (*.zip)");
        if (filename == "") {
            return;
        }

        create_debug_archive (filename);
        Gtk.MessageBox.information (this, _("Debug Archive Created"), _("Debug archive is created at %1").printf (filename));
    }


    private void on_signal_account_added () {
        load_misc_settings ();
    }


    /***********************************************************
    ***********************************************************/
    private void load_misc_settings () {
        var scope = new GLib.ScopedValueRollback<bool> (this.currently_loading, true);
        ConfigFile config_file;
        this.instance.mono_icons_check_box.checked (config_file.mono_icons ());
        this.instance.server_notifications_check_box.checked (config_file.optional_server_notifications ());
        this.instance.show_in_explorer_navigation_pane_check_box.checked (config_file.show_in_explorer_navigation_pane ());
        this.instance.crashreporter_check_box.checked (config_file.crash_reporter ());
        var new_folder_limit = config_file.new_big_folder_size_limit;
        this.instance.new_folder_limit_check_box.checked (new_folder_limit.first);
        this.instance.new_folder_limit_spin_box.value (new_folder_limit.second);
        this.instance.new_external_storage.checked (config_file.confirm_external_storage ());
        this.instance.mono_icons_check_box.checked (config_file.mono_icons ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_legal_notice_button_clicked () {
        var notice = new LegalNotice ();
        notice.exec ();
        //  delete notice;
    }


    private void on_signal_updater_download_state_changed () {
        update_info ();
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void update_info () {
        if (ConfigFile ().skip_update_check () || AbstractUpdater.instance == null) {
            // updater disabled on compile
            this.instance.updates_group_box.visible (false);
            return;
        }

        // Note: the sparkle-updater is not an OCUpdater
        AbstractUpdater.instance.signal_download_state_changed.connect (
            this.on_signal_updater_download_state_changed // GLib.UniqueConnection
        );
        this.instance.restart_button.clicked.connect (
            this.on_signal_restart_button_clicked // GLib.UniqueConnection
        );
        this.instance.auto_check_for_updates_check_box.toggled.connect (
            this.on_signal_auto_check_for_updates_check_box_toggled
        );
        string status = AbstractUpdater.instance.status_string (
            OCUpdater.UpdateStatusStringFormat.HTML
        );
        Theme.replace_link_color_string_background_aware (status);

        this.instance.update_state_label.open_external_links (false);
        this.instance.update_state_label.link_activated.connect (
            this.on_signal_update_state_label_link_activated
        );
        this.instance.update_state_label.on_signal_text (status);

        this.instance.restart_button.visible (
            AbstractUpdater.instance.download_state == OCUpdater.DownloadState.DOWNLOAD_COMPLETE
        );

        this.instance.update_button.enabled (
            AbstractUpdater.instance.download_state != OCUpdater.DownloadState.CHECKING_SERVER &&
            AbstractUpdater.instance.download_state != OCUpdater.DownloadState.DOWNLOADING &&
            AbstractUpdater.instance.download_state != OCUpdater.DownloadState.DOWNLOAD_COMPLETE
        );

        this.instance.auto_check_for_updates_check_box.checked (
            ConfigFile ().auto_update_check ()
        );

        // Channel selection
        this.instance.update_channel.current_index (
            ConfigFile ().update_channel == "beta" ? 1 : 0
        );
        this.instance.update_channel.current_text_changed.connect (
            this.on_signal_update_channel_current_text_changed // GLib.UniqueConnection
        );
    }


    private void on_signal_restart_button_clicked () {
        this.AbstractUpdater.instance.start_installer ();
        GLib.Application.quit ();
        this.on_signal_update_check_now ();
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void on_signal_update_state_label_link_activated (string link) {
        OpenExternal.open_browser (new GLib.Uri (link));
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void on_signal_update_channel_current_text_changed (string channel) {
        if (channel == ConfigFile.update_channel) {
            return;
        }

        var change_update_channel_message_box = new Gtk.MessageBox (
            Gtk.MessageBox.Warning,
            _("Change update channel?"),
            _("The update channel determines which client updates will be offered "
            + "for installation. The \"stable\" channel contains only upgrades that "
            + "are considered reliable, while the versions in the \"beta\" channel "
            + "may contain newer features and bugfixes, but have not yet been tested "
            + "thoroughly."
            + "\n\n"
            + "Note that this selects only what pool upgrades are taken from, and that "
            + "there are no downgrades : So going back from the beta channel to "
            + "the stable channel usually cannot be done immediately and means waiting "
            + "for a stable version that is newer than the currently installed beta "
            + "version."),
            Gtk.MessageBox.NoButton,
            this);
        Gtk.Button accept_button = change_update_channel_message_box.add_button (_("Change update channel"), Gtk.MessageBox.AcceptRole);
        change_update_channel_message_box.add_button (_("Cancel"), Gtk.MessageBox.RejectRole);
        change_update_channel_message_box.signal_finished.connect (
            this.on_signal_change_update_channel_message_box_finished
        );
        change_update_channel_message_box.open ();
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void on_signal_change_update_channel_message_box_finished (string channel, Gtk.MessageBox change_update_channel_message_box, Gtk.Button accept_button) {
        change_update_channel_message_box.delete_later ();
        if (change_update_channel_message_box.clicked_button () == accept_button) {
            ConfigFile.update_channel = channel;
            AbstractUpdater.instance.update_url = AbstractUpdater.update_url;
            AbstractUpdater.instance.check_for_update ();
        } else {
            this.instance.update_channel.current_text (ConfigFile ().update_channel);
        }
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void on_signal_update_check_now () {
        // don't show update info if updates are disabled
        if (!ConfigFile.skip_update_check) {
            this.instance.update_button.enabled (false);
            AbstractUpdater.instance.check_for_update ();
        }
    }


    /***********************************************************
    #if defined (BUILD_UPDATER)
    ***********************************************************/
    private void on_signal_auto_check_for_updates_check_box_toggled () {
        ConfigFile.auto_update_check (
            this.instance.auto_check_for_updates_check_box.is_checked (),
            ""
        );
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        // setup about section
        Theme.replace_link_color_string_background_aware (Theme.about);
        this.instance.about_label.on_signal_text (Theme.about);

    //  #if defined (BUILD_UPDATER)
        // updater info
        update_info ();
    //  #else
        //  this.instance.updates_group_box.visible (false);
    //  #endif
    }

} // class GeneralSettings

} // namespace Ui
} // namespace Occ
