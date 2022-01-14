/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QtCore>
// #include <Qt_network>
// #include <QtGui>
// #include <Qt_widgets>

// #include <cstdio>

// #include <GLib.Object>
// #include <QUrl>
// #include <QTemporary_file>
// #include <QTimer>


namespace Occ {

/***********************************************************
@brief Schedule update checks every couple of hours if the client runs.
@ingroup gui

This class schedules regular update ch
if update checks are wanted at all.

To reflect that all platforms have their own update scheme, a little
complex class design was set up:

For Windows and Linux, the updaters are inherited from OCUpdater, wh
the Mac_o_s_x Sparkle_updater directly uses the class Updater. On windows,
NSISUpdater starts the update if a new version of the client is available.
On Mac_o_s_x, the sparkle framework handles the installation of the new
version. On Linux, the update capabilit
are relied on, and thus the Passive_upda
if there is a new version once at every start

Simple class diagram of the updater:

          +---------------------------+
    +-----+   UpdaterScheduler        +-----+
    |     +------------+--------------+     |
    v                  v                    v
+------------+ +-----------
|NSISUpdater | |Passive_update
+-+----------+ +---+----------
  |                |
  |                v      +------------------+
  |   +---------------+   v
  +-.|   OCUpdater   +------+
      +--------+------+      |
               |   Updater   |
               +-------------+
***********************************************************/

class UpdaterScheduler : GLib.Object {
public:
    UpdaterScheduler (GLib.Object *parent);

signals:
    void updater_announcement (string &title, string &msg);
    void request_restart ();

private slots:
    void slot_timer_fired ();

private:
    QTimer _update_check_timer; /** Timer for the regular update check. */
};

/***********************************************************
@brief Class that uses an own_cloud proprietary XML format to fetch update information
@ingroup gui
***********************************************************/
class OCUpdater : Updater {
public:
    enum Download_state { Unknown = 0,
        Checking_server,
        Up_to_date,
        Downloading,
        Download_complete,
        Download_failed,
        Download_timed_out,
        Update_only_available_through_system };

    enum Update_status_string_format {
        PlainText,
        Html,
    };
    OCUpdater (QUrl &url);

    void set_update_url (QUrl &url);

    bool perform_update ();

    void check_for_update () override;

    string status_string (Update_status_string_format format = PlainText) const;
    int download_state ();
    void set_download_state (Download_state state);

signals:
    void download_state_changed ();
    void new_update_available (string &header, string &message);
    void request_restart ();

public slots:
    // FIXME Maybe this should be in the NSISUpdater which should have been called Windows_updater
    void slot_start_installer ();

protected slots:
    void background_check_for_update () override;
    void slot_open_update_url ();

private slots:
    void slot_version_info_arrived ();
    void slot_timed_out ();

protected:
    virtual void version_info_arrived (Update_info &info) = 0;
    bool update_succeeded ();
    QNetworkAccessManager *qnam () { return _access_manager; }
    Update_info update_info () { return _update_info; }

private:
    QUrl _update_url;
    int _state;
    QNetworkAccessManager *_access_manager;
    QTimer *_timeout_watchdog; /** Timer to guard the timeout of an individual network request */
    Update_info _update_info;
};

/***********************************************************
@brief Windows Updater Using NSIS
@ingroup gui
***********************************************************/
class NSISUpdater : OCUpdater {
public:
    NSISUpdater (QUrl &url);
    bool handle_startup () override;
private slots:
    void slot_set_seen_version ();
    void slot_download_finished ();
    void slot_write_file ();

private:
    void wipe_update_data ();
    void show_no_url_dialog (Update_info &info);
    void show_update_error_dialog (string &target_version);
    void version_info_arrived (Update_info &info) override;
    QScopedPointer<QTemporary_file> _file;
    string _target_file;
};

/***********************************************************
 @brief Updater that only implements notification for use in settings

 The implementation does not show popups

 @ingroup gui
***********************************************************/
class Passive_update_notifier : OCUpdater {
public:
    Passive_update_notifier (QUrl &url);
    bool handle_startup () override { return false; }
    void background_check_for_update () override;

private:
    void version_info_arrived (Update_info &info) override;
    QByteArray _running_app_version;
};


    static const char update_available_c[] = "Updater/update_available";
    static const char update_target_version_c[] = "Updater/update_target_version";
    static const char update_target_version_string_c[] = "Updater/update_target_version_string";
    static const char seen_version_c[] = "Updater/seen_version";
    static const char auto_update_attempted_c[] = "Updater/auto_update_attempted";
    
    UpdaterScheduler.UpdaterScheduler (GLib.Object *parent)
        : GLib.Object (parent) {
        connect (&_update_check_timer, &QTimer.timeout,
            this, &UpdaterScheduler.slot_timer_fired);
    
        // Note : the sparkle-updater is not an OCUpdater
        if (auto *updater = qobject_cast<OCUpdater> (Updater.instance ())) {
            connect (updater, &OCUpdater.new_update_available,
                this, &UpdaterScheduler.updater_announcement);
            connect (updater, &OCUpdater.request_restart, this, &UpdaterScheduler.request_restart);
        }
    
        // at startup, do a check in any case.
        QTimer.single_shot (3000, this, &UpdaterScheduler.slot_timer_fired);
    
        ConfigFile cfg;
        auto check_interval = cfg.update_check_interval ();
        _update_check_timer.start (std.chrono.milliseconds (check_interval).count ());
    }
    
    void UpdaterScheduler.slot_timer_fired () {
        ConfigFile cfg;
    
        // re-set the check interval if it changed in the config file meanwhile
        auto check_interval = std.chrono.milliseconds (cfg.update_check_interval ()).count ();
        if (check_interval != _update_check_timer.interval ()) {
            _update_check_timer.set_interval (check_interval);
            q_c_info (lc_updater) << "Setting new update check interval " << check_interval;
        }
    
        // consider the skip_update_check and !auto_update_check flags in the config.
        if (cfg.skip_update_check () || !cfg.auto_update_check ()) {
            q_c_info (lc_updater) << "Skipping update check because of config file";
            return;
        }
    
        Updater *updater = Updater.instance ();
        if (updater) {
            updater.background_check_for_update ();
        }
    }
    
    /* ----------------------------------------------------------------- */
    
    OCUpdater.OCUpdater (QUrl &url)
        : Updater ()
        , _update_url (url)
        , _state (Unknown)
        , _access_manager (new AccessManager (this))
        , _timeout_watchdog (new QTimer (this)) {
    }
    
    void OCUpdater.set_update_url (QUrl &url) {
        _update_url = url;
    }
    
    bool OCUpdater.perform_update () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        if (!update_file.is_empty () && QFile (update_file).exists ()
            && !update_succeeded () /* Someone might have run the updater manually between restarts */) {
            const auto message_box_start_installer = new QMessageBox (QMessageBox.Information,
                tr ("New %1 update ready").arg (Theme.instance ().app_name_g_u_i ()),
                tr ("A new update for %1 is about to be installed. The updater may ask "
                   "for additional privileges during the process. Your computer may reboot to complete the installation.")
                    .arg (Theme.instance ().app_name_g_u_i ()),
                QMessageBox.Ok,
                nullptr);
    
            message_box_start_installer.set_attribute (Qt.WA_DeleteOnClose);
    
            connect (message_box_start_installer, &QMessageBox.finished, this, [this] {
                slot_start_installer ();
            });
            message_box_start_installer.open ();
        }
        return false;
    }
    
    void OCUpdater.background_check_for_update () {
        int dl_state = download_state ();
    
        // do the real update check depending on the internal state of updater.
        switch (dl_state) {
        case Unknown:
        case Up_to_date:
        case Download_failed:
        case Download_timed_out:
            q_c_info (lc_updater) << "Checking for available update";
            check_for_update ();
            break;
        case Download_complete:
            q_c_info (lc_updater) << "Update is downloaded, skip new check.";
            break;
        case Update_only_available_through_system:
            q_c_info (lc_updater) << "Update is only available through system, skip check.";
            break;
        }
    }
    
    string OCUpdater.status_string (Update_status_string_format format) {
        string update_version = _update_info.version_string ();
    
        switch (download_state ()) {
        case Downloading:
            return tr ("Downloading %1. Please wait …").arg (update_version);
        case Download_complete:
            return tr ("%1 available. Restart application to start the update.").arg (update_version);
        case Download_failed : {
            if (format == Update_status_string_format.Html) {
                return tr ("Could not download update. Please open <a href='%1'>%1</a> to download the update manually.").arg (_update_info.web ());
            }
            return tr ("Could not download update. Please open %1 to download the update manually.").arg (_update_info.web ());
        }
        case Download_timed_out:
            return tr ("Could not check for new updates.");
        case Update_only_available_through_system : {
            if (format == Update_status_string_format.Html) {
                return tr ("New %1 is available. Please open <a href='%2'>%2</a> to download the update.").arg (update_version, _update_info.web ());
            }
            return tr ("New %1 is available. Please open %2 to download the update.").arg (update_version, _update_info.web ());
        }
        case Checking_server:
            return tr ("Checking update server …");
        case Unknown:
            return tr ("Update status is unknown : Did not check for new updates.");
        case Up_to_date:
        // fall through
        default:
            return tr ("No updates available. Your installation is at the latest version.");
        }
    }
    
    int OCUpdater.download_state () {
        return _state;
    }
    
    void OCUpdater.set_download_state (Download_state state) {
        auto old_state = _state;
        _state = state;
        emit download_state_changed ();
    
        // show the notification if the download is complete (on every check)
        // or once for system based updates.
        if (_state == OCUpdater.Download_complete || (old_state != OCUpdater.Update_only_available_through_system
                                                         && _state == OCUpdater.Update_only_available_through_system)) {
            emit new_update_available (tr ("Update Check"), status_string ());
        }
    }
    
    void OCUpdater.slot_start_installer () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        settings.set_value (auto_update_attempted_c, true);
        settings.sync ();
        q_c_info (lc_updater) << "Running updater" << update_file;
    
        if (update_file.ends_with (".exe")) {
            QProcess.start_detached (update_file, QStringList () << "/S"
                                                              << "/launch");
        } else if (update_file.ends_with (".msi")) {
            // When MSIs are installed without gui they cannot launch applications
            // as they lack the user context. That is why we need to run the client
            // manually here. We wrap the msiexec and client invocation in a powershell
            // script because owncloud.exe will be shut down for installation.
            // | Out-Null forces powershell to wait for msiexec to finish.
            auto prepare_path_for_powershell = [] (string path) {
                path.replace ("'", "''");
    
                return QDir.to_native_separators (path);
            };
    
            string msi_log_file = cfg.config_path () + "msi.log";
            string command = string ("&{msiexec /promptrestart /passive /i '%1' /L*V '%2'| Out-Null ; &'%3'}")
                 .arg (prepare_path_for_powershell (update_file))
                 .arg (prepare_path_for_powershell (msi_log_file))
                 .arg (prepare_path_for_powershell (QCoreApplication.application_file_path ()));
    
            QProcess.start_detached ("powershell.exe", QStringList{"-Command", command});
        }
        q_app.quit ();
    }
    
    void OCUpdater.check_for_update () {
        QNetworkReply *reply = _access_manager.get (QNetworkRequest (_update_url));
        connect (_timeout_watchdog, &QTimer.timeout, this, &OCUpdater.slot_timed_out);
        _timeout_watchdog.start (30 * 1000);
        connect (reply, &QNetworkReply.finished, this, &OCUpdater.slot_version_info_arrived);
    
        set_download_state (Checking_server);
    }
    
    void OCUpdater.slot_open_update_url () {
        QDesktopServices.open_url (_update_info.web ());
    }
    
    bool OCUpdater.update_succeeded () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
    
        int64 target_version_int = Helper.string_version_to_int (settings.value (update_target_version_c).to_string ());
        int64 current_version = Helper.current_version_to_int ();
        return current_version >= target_version_int;
    }
    
    void OCUpdater.slot_version_info_arrived () {
        _timeout_watchdog.stop ();
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        reply.delete_later ();
        if (reply.error () != QNetworkReply.NoError) {
            q_c_warning (lc_updater) << "Failed to reach version check url : " << reply.error_string ();
            set_download_state (Download_timed_out);
            return;
        }
    
        string xml = string.from_utf8 (reply.read_all ());
    
        bool ok = false;
        _update_info = Update_info.parse_string (xml, &ok);
        if (ok) {
            version_info_arrived (_update_info);
        } else {
            q_c_warning (lc_updater) << "Could not parse update information.";
            set_download_state (Download_timed_out);
        }
    }
    
    void OCUpdater.slot_timed_out () {
        set_download_state (Download_timed_out);
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    NSISUpdater.NSISUpdater (QUrl &url)
        : OCUpdater (url) {
    }
    
    void NSISUpdater.slot_write_file () {
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        if (_file.is_open ()) {
            _file.write (reply.read_all ());
        }
    }
    
    void NSISUpdater.wipe_update_data () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_file_name = settings.value (update_available_c).to_string ();
        if (!update_file_name.is_empty ())
            QFile.remove (update_file_name);
        settings.remove (update_available_c);
        settings.remove (update_target_version_c);
        settings.remove (update_target_version_string_c);
        settings.remove (auto_update_attempted_c);
    }
    
    void NSISUpdater.slot_download_finished () {
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        reply.delete_later ();
        if (reply.error () != QNetworkReply.NoError) {
            set_download_state (Download_failed);
            return;
        }
    
        QUrl url (reply.url ());
        _file.close ();
    
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
    
        // remove previously downloaded but not used installer
        QFile old_target_file (settings.value (update_available_c).to_string ());
        if (old_target_file.exists ()) {
            old_target_file.remove ();
        }
    
        QFile.copy (_file.file_name (), _target_file);
        set_download_state (Download_complete);
        q_c_info (lc_updater) << "Downloaded" << url.to_string () << "to" << _target_file;
        settings.set_value (update_target_version_c, update_info ().version ());
        settings.set_value (update_target_version_string_c, update_info ().version_string ());
        settings.set_value (update_available_c, _target_file);
    }
    
    void NSISUpdater.version_info_arrived (Update_info &info) {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        int64 info_version = Helper.string_version_to_int (info.version ());
        auto seen_string = settings.value (seen_version_c).to_string ();
        int64 seen_version = Helper.string_version_to_int (seen_string);
        int64 curr_version = Helper.current_version_to_int ();
        q_c_info (lc_updater) << "Version info arrived:"
                << "Your version:" << curr_version
                << "Skipped version:" << seen_version << seen_string
                << "Available version:" << info_version << info.version ()
                << "Available version string:" << info.version_string ()
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
                _target_file = cfg.config_path () + url.mid (url.last_index_of ('/')+1);
                if (QFile (_target_file).exists ()) {
                    set_download_state (Download_complete);
                } else {
                    auto request = QNetworkRequest (QUrl (url));
                    request.set_attribute (QNetworkRequest.Redirect_policy_attribute, QNetworkRequest.No_less_safe_redirect_policy);
                    QNetworkReply *reply = qnam ().get (request);
                    connect (reply, &QIODevice.ready_read, this, &NSISUpdater.slot_write_file);
                    connect (reply, &QNetworkReply.finished, this, &NSISUpdater.slot_download_finished);
                    set_download_state (Downloading);
                    _file.reset (new QTemporary_file);
                    _file.set_auto_remove (true);
                    _file.open ();
                }
            }
        }
    }
    
    void NSISUpdater.show_no_url_dialog (Update_info &info) {
        // if the version tag is set, there is a newer version.
        auto *msg_box = new Gtk.Dialog;
        msg_box.set_attribute (Qt.WA_DeleteOnClose);
        msg_box.set_window_flags (msg_box.window_flags () & ~Qt.WindowContextHelpButtonHint);
    
        QIcon info_icon = msg_box.style ().standard_icon (QStyle.SP_Message_box_information);
        int icon_size = msg_box.style ().pixel_metric (QStyle.PM_Message_box_icon_size);
    
        msg_box.set_window_icon (info_icon);
    
        auto *layout = new QVBoxLayout (msg_box);
        auto *hlayout = new QHBox_layout;
        layout.add_layout (hlayout);
    
        msg_box.set_window_title (tr ("New Version Available"));
    
        auto *ico = new QLabel;
        ico.set_fixed_size (icon_size, icon_size);
        ico.set_pixmap (info_icon.pixmap (icon_size));
        auto *lbl = new QLabel;
        string txt = tr ("<p>A new version of the %1 Client is available.</p>"
                         "<p><b>%2</b> is available for download. The installed version is %3.</p>")
                          .arg (Utility.escape (Theme.instance ().app_name_g_u_i ()),
                              Utility.escape (info.version_string ()), Utility.escape (client_version ()));
    
        lbl.set_text (txt);
        lbl.set_text_format (Qt.RichText);
        lbl.set_word_wrap (true);
    
        hlayout.add_widget (ico);
        hlayout.add_widget (lbl);
    
        auto *bb = new QDialogButtonBox;
        QPushButton *skip = bb.add_button (tr ("Skip this version"), QDialogButtonBox.Reset_role);
        QPushButton *reject = bb.add_button (tr ("Skip this time"), QDialogButtonBox.AcceptRole);
        QPushButton *getupdate = bb.add_button (tr ("Get update"), QDialogButtonBox.AcceptRole);
    
        connect (skip, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (reject, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (getupdate, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);
    
        connect (skip, &QAbstractButton.clicked, this, &NSISUpdater.slot_set_seen_version);
        connect (getupdate, &QAbstractButton.clicked, this, &NSISUpdater.slot_open_update_url);
    
        layout.add_widget (bb);
    
        msg_box.open ();
    }
    
    void NSISUpdater.show_update_error_dialog (string &target_version) {
        auto msg_box = new Gtk.Dialog;
        msg_box.set_attribute (Qt.WA_DeleteOnClose);
        msg_box.set_window_flags (msg_box.window_flags () & ~Qt.WindowContextHelpButtonHint);
    
        QIcon info_icon = msg_box.style ().standard_icon (QStyle.SP_Message_box_information);
        int icon_size = msg_box.style ().pixel_metric (QStyle.PM_Message_box_icon_size);
    
        msg_box.set_window_icon (info_icon);
    
        auto layout = new QVBoxLayout (msg_box);
        auto hlayout = new QHBox_layout;
        layout.add_layout (hlayout);
    
        msg_box.set_window_title (tr ("Update Failed"));
    
        auto ico = new QLabel;
        ico.set_fixed_size (icon_size, icon_size);
        ico.set_pixmap (info_icon.pixmap (icon_size));
        auto lbl = new QLabel;
        string txt = tr ("<p>A new version of the %1 Client is available but the updating process failed.</p>"
                         "<p><b>%2</b> has been downloaded. The installed version is %3. If you confirm restart and update, your computer may reboot to complete the installation.</p>")
                          .arg (Utility.escape (Theme.instance ().app_name_g_u_i ()),
                              Utility.escape (target_version), Utility.escape (client_version ()));
    
        lbl.set_text (txt);
        lbl.set_text_format (Qt.RichText);
        lbl.set_word_wrap (true);
    
        hlayout.add_widget (ico);
        hlayout.add_widget (lbl);
    
        auto bb = new QDialogButtonBox;
        auto skip = bb.add_button (tr ("Skip this version"), QDialogButtonBox.Reset_role);
        auto askagain = bb.add_button (tr ("Ask again later"), QDialogButtonBox.Reset_role);
        auto retry = bb.add_button (tr ("Restart and update"), QDialogButtonBox.AcceptRole);
        auto getupdate = bb.add_button (tr ("Update manually"), QDialogButtonBox.AcceptRole);
    
        connect (skip, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (askagain, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.reject);
        connect (retry, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);
        connect (getupdate, &QAbstractButton.clicked, msg_box, &Gtk.Dialog.accept);
    
        connect (skip, &QAbstractButton.clicked, this, [this] () {
            wipe_update_data ();
            slot_set_seen_version ();
        });
        // askagain : do nothing
        connect (retry, &QAbstractButton.clicked, this, [this] () {
            slot_start_installer ();
        });
        connect (getupdate, &QAbstractButton.clicked, this, [this] () {
            slot_open_update_url ();
        });
    
        layout.add_widget (bb);
    
        msg_box.open ();
    }
    
    bool NSISUpdater.handle_startup () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        string update_file_name = settings.value (update_available_c).to_string ();
        // has the previous run downloaded an update?
        if (!update_file_name.is_empty () && QFile (update_file_name).exists ()) {
            q_c_info (lc_updater) << "An updater file is available";
            // did it try to execute the update?
            if (settings.value (auto_update_attempted_c, false).to_bool ()) {
                if (update_succeeded ()) {
                    // success : clean up
                    q_c_info (lc_updater) << "The requested update attempt has succeeded"
                            << Helper.current_version_to_int ();
                    wipe_update_data ();
                    return false;
                } else {
                    // auto update failed. Ask user what to do
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
    
    void NSISUpdater.slot_set_seen_version () {
        ConfigFile cfg;
        QSettings settings (cfg.config_file (), QSettings.IniFormat);
        settings.set_value (seen_version_c, update_info ().version ());
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    Passive_update_notifier.Passive_update_notifier (QUrl &url)
        : OCUpdater (url) {
        // remember the version of the currently running binary. On Linux it might happen that the
        // package management updates the package while the app is running. This is detected in the
        // updater slot : If the installed binary on the hd has a different version than the one
        // running, the running app is restarted. That happens in folderman.
        _running_app_version = Utility.version_of_installed_binary ();
    }
    
    void Passive_update_notifier.background_check_for_update () {
        if (Utility.is_linux ()) {
            // on linux, check if the installed binary is still the same version
            // as the one that is running. If not, restart if possible.
            const QByteArray fs_version = Utility.version_of_installed_binary ();
            if (! (fs_version.is_empty () || _running_app_version.is_empty ()) && fs_version != _running_app_version) {
                emit request_restart ();
            }
        }
    
        OCUpdater.background_check_for_update ();
    }
    
    void Passive_update_notifier.version_info_arrived (Update_info &info) {
        int64 current_ver = Helper.current_version_to_int ();
        int64 remote_ver = Helper.string_version_to_int (info.version ());
    
        if (info.version ().is_empty () || current_ver >= remote_ver) {
            q_c_info (lc_updater) << "Client is on latest version!";
            set_download_state (Up_to_date);
        } else {
            set_download_state (Update_only_available_through_system);
        }
    }
    
    } // ns mirall
    