/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief Windows AbstractUpdater Using NSIS
***********************************************************/
public class NSISUpdater : OCUpdater {

    /***********************************************************
    ***********************************************************/
    private QTemporaryFile file;
    private string target_file;

    /***********************************************************
    ***********************************************************/
    public NSISUpdater (GLib.Uri url) {
        base (url);
    }

    /***********************************************************
    ***********************************************************/
    public override bool handle_startup () {
        ConfigFile config;
        GLib.Settings settings = new GLib.Settings (config.config_file (), GLib.Settings.IniFormat);
        string update_filename = settings.value (update_available_c).to_string ();
        // has the previous run downloaded an update?
        if (!update_filename == "" && GLib.File (update_filename).exists ()) {
            GLib.info ("An updater file is available.");
            // did it try to execute the update?
            if (settings.value (auto_update_attempted_c, false).to_bool ()) {
                if (update_succeeded ()) {
                    // on_signal_success: clean up
                    GLib.info (
                        "The requested update attempt has succeeded: "
                        + Helper.current_version_to_int ());
                    wipe_update_data ();
                    return false;
                } else {
                    // var update failed. Ask user what to do
                    GLib.info (
                        "The requested update attempt has failed: "
                        + settings.value (update_target_version_c).to_string ());
                    show_update_error_dialog (settings.value (update_target_version_string_c).to_string ());
                    return false;
                }
            } else {
                GLib.info ("Triggering an update.");
                return perform_update ();
            }
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_seen_version () {
        ConfigFile config;
        GLib.Settings settings = new GLib.Settings (config.config_file (), GLib.Settings.IniFormat);
        settings.value (seen_version_c, update_info ().version);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_download_finished () {
        var reply = qobject_cast<GLib.InputStream> (sender ());
        reply.delete_later ();
        if (reply.error != GLib.InputStream.NoError) {
            download_state (DownloadState.DOWNLOAD_FAILED);
            return;
        }

        GLib.Uri url = new GLib.Uri (reply.url);
        this.file.close ();

        ConfigFile config;
        GLib.Settings settings = new GLib.Settings (config.config_file (), GLib.Settings.IniFormat);

        // remove previously downloaded but not used installer
        GLib.File old_target_file = new GLib.File (settings.value (update_available_c).to_string ());
        if (old_target_file.exists ()) {
            old_target_file.remove ();
        }

        GLib.File.copy (this.file.filename (), this.target_file);
        download_state (DownloadState.DOWNLOAD_COMPLETE);
        GLib.info ("Downloaded " + url.to_string () + "to" + this.target_file);
        settings.value (update_target_version_c, update_info ().version);
        settings.value (update_target_version_string_c, update_info ().version_string ());
        settings.value (update_available_c, this.target_file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_file () {
        var reply = qobject_cast<GLib.InputStream> (sender ());
        if (this.file.is_open) {
            this.file.write (reply.read_all ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void wipe_update_data () {
        ConfigFile config;
        GLib.Settings settings = new GLib.Settings (config.config_file (), GLib.Settings.IniFormat);
        string update_filename = settings.value (update_available_c).to_string ();
        if (!update_filename == "")
            GLib.File.remove (update_filename);
        settings.remove (update_available_c);
        settings.remove (update_target_version_c);
        settings.remove (update_target_version_string_c);
        settings.remove (auto_update_attempted_c);
    }


    /***********************************************************
    ***********************************************************/
    private void show_no_url_dialog (UpdateInfo info) {
        // if the version tag is set, there is a newer version.
        var message_box = new Gtk.Dialog ();
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.window_flags (message_box.window_flags () & ~Qt.WindowContextHelpButtonHint);

        Gtk.Icon info_icon = message_box.this.style.standard_icon (QStyle.SP_Message_box_information);
        int icon_size = message_box.this.style.pixel_metric (QStyle.PM_Message_box_icon_size);

        message_box.window_icon (info_icon);

        var layout = new QVBoxLayout (message_box);
        var hlayout = new QHBoxLayout ();
        layout.add_layout (hlayout);

        message_box.window_title (_("New Version Available"));

        var ico = new Gtk.Label ();
        ico.fixed_size (icon_size, icon_size);
        ico.pixmap (info_icon.pixmap (icon_size));
        var update_label = new Gtk.Label ();
        string txt = _("<p>A new version of the %1 Client is available.</p>"
                     + "<p><b>%2</b> is available for download. The installed version is %3.</p>")
                        .printf (
                            Utility.escape (Theme.app_name_gui),
                            Utility.escape (info.version_string ()), Utility.escape (client_version ())
                        );

        update_label.on_signal_text (txt);
        update_label.text_format (Qt.RichText);
        update_label.word_wrap (true);

        hlayout.add_widget (ico);
        hlayout.add_widget (update_label);

        var button_box = new QDialogButtonBox ();
        QPushButton skip_version_button = button_box.add_button (_("Skip this version"), QDialogButtonBox.Reset_role);
        QPushButton skip_once_button = button_box.add_button (_("Skip this time"), QDialogButtonBox.AcceptRole);
        QPushButton get_update_button = button_box.add_button (_("Get update"), QDialogButtonBox.AcceptRole);

        skip_version_button.clicked.connect (
            message_box.skip_once_button
        );
        skip_once_button.clicked.connect (
            message_box.reject
        );
        get_update_button.clicked.connect (
            message_box.accept
        );

        skip_version_button.clicked.connect (
            this.on_signal_seen_version
        );
        get_update_button.clicked.connect (
            this.on_signal_open_update_url
        );

        layout.add_widget (button_box);

        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void show_update_error_dialog (string target_version) {
        var message_box = new Gtk.Dialog ();
        message_box.attribute (Qt.WA_DeleteOnClose);
        message_box.window_flags (message_box.window_flags () & ~Qt.WindowContextHelpButtonHint);

        Gtk.Icon info_icon = message_box.this.style.standard_icon (QStyle.SP_Message_box_information);
        int icon_size = message_box.this.style.pixel_metric (QStyle.PM_Message_box_icon_size);

        message_box.window_icon (info_icon);

        var layout = new QVBoxLayout (message_box);
        var hlayout = new QHBoxLayout ();
        layout.add_layout (hlayout);

        message_box.window_title (_("Update Failed"));

        var ico = new Gtk.Label ();
        ico.fixed_size (icon_size, icon_size);
        ico.pixmap (info_icon.pixmap (icon_size));
        var update_label = new Gtk.Label ();
        string txt = _("<p>A new version of the %1 Client is available but the updating process failed.</p>"
                     + "<p><b>%2</b> has been downloaded. The installed version is %3. If you confirm restart and update, your computer may reboot to complete the installation.</p>")
                        .printf (
                            Utility.escape (Theme.app_name_gui),
                            Utility.escape (target_version), Utility.escape (client_version ())
                        );

        update_label.on_signal_text (txt);
        update_label.text_format (Qt.RichText);
        update_label.word_wrap (true);

        hlayout.add_widget (ico);
        hlayout.add_widget (update_label);

        var button_box = new QDialogButtonBox ();
        var skip_version_button = button_box.add_button (_("Skip this version"), QDialogButtonBox.Reset_role);
        var askagain = button_box.add_button (_("Ask again later"), QDialogButtonBox.Reset_role);
        var retry = button_box.add_button (_("Restart and update"), QDialogButtonBox.AcceptRole);
        var get_update_button = button_box.add_button (_("Update manually"), QDialogButtonBox.AcceptRole);

        skip_version_button.clicked.connect (
            message_box.reject
        );
        askagain.clicked.connect (
            message_box.reject
        );
        retry.clicked.connect (
            message_box.accept
        );
        get_update_button.clicked.connect (
            message_box.accept
        );
        skip_version_button.clicked.connect (
            this.on_skip_button_clicked
        );
        // askagain: do nothing
        retry.clicked.connect (
            this.on_retry_button_clicked
        );
        get_update_button.clicked.connect (
            this.on_get_update_button_clicked
        );

        layout.add_widget (button_box);

        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_skip_button_clicked () {
        wipe_update_data ();
        on_signal_seen_version ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_retry_button_clicked () {
        on_signal_start_installer ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_get_update_button_clicked () {
        on_signal_open_update_url ();
    }


    /***********************************************************
    ***********************************************************/
    private override void version_info_arrived (UpdateInfo info) {
        ConfigFile config;
        GLib.Settings settings = new GLib.Settings (config.config_file (), GLib.Settings.IniFormat);
        int64 info_version = Helper.string_version_to_int (info.version);
        var seen_string = settings.value (seen_version_c).to_string ();
        int64 seen_version = Helper.string_version_to_int (seen_string);
        int64 curr_version = Helper.current_version_to_int ();
        GLib.info ("Version info arrived:"
                + "Your version:" + curr_version
                + "Skipped version:" + seen_version + seen_string
                + "Available version:" + info_version + info.version
                + "Available version string:" + info.version_string ()
                + "Web url:" + info.web ()
                + "Download url:" + info.download_url ());
        if (info.version == "") {
            GLib.info ("No version information available at the moment.");
            download_state (DownloadState.UP_TO_DATE);
        } else if (info_version <= curr_version
                   || info_version <= seen_version) {
            GLib.info ("Client is on latest version!");
            download_state (DownloadState.UP_TO_DATE);
        } else {
            string url = info.download_url ();
            if (url == "") {
                show_no_url_dialog (info);
            } else {
                this.target_file = config.config_path + url.mid (url.last_index_of ('/')+1);
                if (GLib.File (this.target_file).exists ()) {
                    download_state (DownloadState.DOWNLOAD_COMPLETE);
                } else {
                    var request = Soup.Request (GLib.Uri (url));
                    request.attribute (Soup.Request.Redirect_policy_attribute, Soup.Request.No_less_safe_redirect_policy);
                    GLib.InputStream reply = soup_context ().get (request);
                    reply.ready_read.connect (
                        this.on_signal_write_file
                    );
                    reply.signal_finished.connect (
                        this.on_signal_download_finished
                    );
                    download_state (DownloadState.DOWNLOADING);
                    this.file.on_signal_reset (new QTemporaryFile ());
                    this.file.auto_remove (true);
                    this.file.open ();
                }
            }
        }
    }

} // class NSISUpdater

} // namespace Ui
} // namespace Occ
