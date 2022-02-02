/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief Windows Updater Using NSIS
@ingroup gui
***********************************************************/
class NSISUpdater : OCUpdater {

    /***********************************************************
    ***********************************************************/
    public NSISUpdater (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public 
    public bool handle_startup () override;

    /***********************************************************
    ***********************************************************/
    private void on_set_seen_version ();
    private void on_download_finished ();
    private void on_write_file ();


    /***********************************************************
    ***********************************************************/
    private void wipe_update_data ();
    private void show_no_url_dialog (Update_info info);
    private void show_update_error_dialog (string target_version);
    private void version_info_arrived (Update_info info) override;
    private QScopedPointer<QTemporary_file> this.file;
    private string this.target_file;
}





    NSISUpdater.NSISUpdater (GLib.Uri url)
        : OCUpdater (url) {
    }

    void NSISUpdater.on_write_file () {
        var reply = qobject_cast<Soup.Reply> (sender ());
        if (this.file.is_open ()) {
            this.file.write (reply.read_all ());
        }
    }

    void NSISUpdater.wipe_update_data () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_filename = settings.value (update_available_c).to_string ();
        if (!update_filename.is_empty ())
            GLib.File.remove (update_filename);
        settings.remove (update_available_c);
        settings.remove (update_target_version_c);
        settings.remove (update_target_version_string_c);
        settings.remove (auto_update_attempted_c);
    }

    void NSISUpdater.on_download_finished () {
        var reply = qobject_cast<Soup.Reply> (sender ());
        reply.delete_later ();
        if (reply.error () != Soup.Reply.NoError) {
            set_download_state (Download_failed);
            return;
        }

        GLib.Uri url (reply.url ());
        this.file.close ();

        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);

        // remove previously downloaded but not used installer
        GLib.File old_target_file (settings.value (update_available_c).to_string ());
        if (old_target_file.exists ()) {
            old_target_file.remove ();
        }

        GLib.File.copy (this.file.filename (), this.target_file);
        set_download_state (Download_complete);
        q_c_info (lc_updater) << "Downloaded" << url.to_string () << "to" << this.target_file;
        settings.set_value (update_target_version_c, update_info ().version ());
        settings.set_value (update_target_version_string_c, update_info ().version_"");
        settings.set_value (update_available_c, this.target_file);
    }

    void NSISUpdater.version_info_arrived (Update_info info) {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        int64 info_version = Helper.string_version_to_int (info.version ());
        var seen_string = settings.value (seen_version_c).to_string ();
        int64 seen_version = Helper.string_version_to_int (seen_string);
        int64 curr_version = Helper.current_version_to_int ();
        q_c_info (lc_updater) << "Version info arrived:"
                << "Your version:" << curr_version
                << "Skipped version:" << seen_version << seen_string
                << "Available version:" << info_version << info.version ()
                << "Available version string:" << info.version_""
                << "Web url:" << info.web ()
                << "Download url:" << info.download_url ();
        if (info.version ().is_empty ()) {
            q_c_info (lc_updater) << "No version information available at the moment";
            set_download_state (Up_to_date);
        } else if (info_version <= curr_version
                   || info_version <= seen_version) {
            q_c_info (lc_updater) << "Client is on latest version!";
            set_download_state (Up_to_date);
        } else {
            string url = info.download_url ();
            if (url.is_empty ()) {
                show_no_url_dialog (info);
            } else {
                this.target_file = cfg.config_path () + url.mid (url.last_index_of ('/')+1);
                if (GLib.File (this.target_file).exists ()) {
                    set_download_state (Download_complete);
                } else {
                    var request = QNetworkRequest (GLib.Uri (url));
                    request.set_attribute (QNetworkRequest.Redirect_policy_attribute, QNetworkRequest.No_less_safe_redirect_policy);
                    Soup.Reply reply = qnam ().get (request);
                    connect (reply, &QIODevice.ready_read, this, &NSISUpdater.on_write_file);
                    connect (reply, &Soup.Reply.on_finished, this, &NSISUpdater.on_download_finished);
                    set_download_state (Downloading);
                    this.file.on_reset (new QTemporary_file);
                    this.file.set_auto_remove (true);
                    this.file.open ();
                }
            }
        }
    }

    void NSISUpdater.show_no_url_dialog (Update_info info) {
        // if the version tag is set, there is a newer version.
        var msg_box = new Gtk.Dialog;
        msg_box.set_attribute (Qt.WA_DeleteOnClose);
        msg_box.set_window_flags (msg_box.window_flags () & ~Qt.WindowContextHelpButtonHint);

        QIcon info_icon = msg_box.style ().standard_icon (QStyle.SP_Message_box_information);
        int icon_size = msg_box.style ().pixel_metric (QStyle.PM_Message_box_icon_size);

        msg_box.set_window_icon (info_icon);

        var layout = new QVBoxLayout (msg_box);
        var hlayout = new QHBox_layout;
        layout.add_layout (hlayout);

        msg_box.set_window_title (_("New Version Available"));

        var ico = new QLabel;
        ico.set_fixed_size (icon_size, icon_size);
        ico.set_pixmap (info_icon.pixmap (icon_size));
        var lbl = new QLabel;
        string txt = _("<p>A new version of the %1 Client is available.</p>"
                         "<p><b>%2</b> is available for download. The installed version is %3.</p>")
                          .arg (Utility.escape (Theme.instance ().app_name_gui ()),
                              Utility.escape (info.version_""), Utility.escape (client_version ()));

        lbl.on_set_text (txt);
        lbl.set_text_format (Qt.RichText);
        lbl.set_word_wrap (true);

        hlayout.add_widget (ico);
        hlayout.add_widget (lbl);

        var bb = new QDialogButtonBox;
        QPushButton skip = bb.add_button (_("Skip this version"), QDialogButtonBox.Reset_role);
        QPushButton reject = bb.add_button (_("Skip this time"), QDialogButtonBox.AcceptRole);
        QPushButton getupdate = bb.add_button (_("Get update"), QDialogButtonBox.AcceptRole);

        connect (skip, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (reject, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (getupdate, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);

        connect (skip, &QAbstractButton.clicked, this, &NSISUpdater.on_set_seen_version);
        connect (getupdate, &QAbstractButton.clicked, this, &NSISUpdater.on_open_update_url);

        layout.add_widget (bb);

        msg_box.open ();
    }

    void NSISUpdater.show_update_error_dialog (string target_version) {
        var msg_box = new Gtk.Dialog;
        msg_box.set_attribute (Qt.WA_DeleteOnClose);
        msg_box.set_window_flags (msg_box.window_flags () & ~Qt.WindowContextHelpButtonHint);

        QIcon info_icon = msg_box.style ().standard_icon (QStyle.SP_Message_box_information);
        int icon_size = msg_box.style ().pixel_metric (QStyle.PM_Message_box_icon_size);

        msg_box.set_window_icon (info_icon);

        var layout = new QVBoxLayout (msg_box);
        var hlayout = new QHBox_layout;
        layout.add_layout (hlayout);

        msg_box.set_window_title (_("Update Failed"));

        var ico = new QLabel;
        ico.set_fixed_size (icon_size, icon_size);
        ico.set_pixmap (info_icon.pixmap (icon_size));
        var lbl = new QLabel;
        string txt = _("<p>A new version of the %1 Client is available but the updating process failed.</p>"
                         "<p><b>%2</b> has been downloaded. The installed version is %3. If you confirm restart and update, your computer may reboot to complete the installation.</p>")
                          .arg (Utility.escape (Theme.instance ().app_name_gui ()),
                              Utility.escape (target_version), Utility.escape (client_version ()));

        lbl.on_set_text (txt);
        lbl.set_text_format (Qt.RichText);
        lbl.set_word_wrap (true);

        hlayout.add_widget (ico);
        hlayout.add_widget (lbl);

        var bb = new QDialogButtonBox;
        var skip = bb.add_button (_("Skip this version"), QDialogButtonBox.Reset_role);
        var askagain = bb.add_button (_("Ask again later"), QDialogButtonBox.Reset_role);
        var retry = bb.add_button (_("Restart and update"), QDialogButtonBox.AcceptRole);
        var getupdate = bb.add_button (_("Update manually"), QDialogButtonBox.AcceptRole);

        connect (skip, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (askagain, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (retry, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);
        connect (getupdate, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);

        connect (skip, &QAbstractButton.clicked, this, [this] () {
            wipe_update_data ();
            on_set_seen_version ();
        });
        // askagain : do nothing
        connect (retry, &QAbstractButton.clicked, this, [this] () {
            on_start_installer ();
        });
        connect (getupdate, &QAbstractButton.clicked, this, [this] () {
            on_open_update_url ();
        });

        layout.add_widget (bb);

        msg_box.open ();
    }

    bool NSISUpdater.handle_startup () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_filename = settings.value (update_available_c).to_string ();
        // has the previous run downloaded an update?
        if (!update_filename.is_empty () && GLib.File (update_filename).exists ()) {
            q_c_info (lc_updater) << "An updater file is available";
            // did it try to execute the update?
            if (settings.value (auto_update_attempted_c, false).to_bool ()) {
                if (update_succeeded ()) {
                    // on_success : clean up
                    q_c_info (lc_updater) << "The requested update attempt has succeeded"
                            << Helper.current_version_to_int ();
                    wipe_update_data ();
                    return false;
                } else {
                    // var update failed. Ask user what to do
                    q_c_info (lc_updater) << "The requested update attempt has failed"
                            << settings.value (update_target_version_c).to_string ();
                    show_update_error_dialog (settings.value (update_target_version_string_c).to_string ());
                    return false;
                }
            } else {
                q_c_info (lc_updater) << "Triggering an update";
                return perform_update ();
            }
        }
        return false;
    }

    void NSISUpdater.on_set_seen_version () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        settings.set_value (seen_version_c, update_info ().version ());
    }