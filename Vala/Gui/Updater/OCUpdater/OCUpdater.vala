/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <Qt_network>
//  #include <QtGui>
//  #include <Qt_widgets>
//  #include <cstdio>
//  #include <QTemporary_file>
//  #include <QTimer>


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
if there is a new version once at every on_start

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


/***********************************************************
@brief Class that uses an own_cloud proprietary XML format to fetch update information
@ingroup gui
***********************************************************/
class OCUpdater : Updater {

    /***********************************************************
    ***********************************************************/
    public enum Download_state {
        Unknown = 0,
        Checking_server,
        Up_to_date,
        Downloading,
        Download_complete,
        Download_failed,
        Download_timed_out,
        Update_only_available_through_system
    }

    /***********************************************************
    ***********************************************************/
    public enum Update_status_string_format {
        PlainText,
        Html,
    }
    public OCUpdater (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public void update_url (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public bool perform_update ();

    /***********************************************************
    ***********************************************************/
    public void check_for_update () override;

    /***********************************************************
    ***********************************************************/
    public string status_string (Update_status_string_format format = PlainText);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void download_state (Download_state state);

signals:
    void download_state_changed ();
    void new_update_available (string header, string message);
    void request_restart ();


    // FIXME Maybe this should be in the NSISUpdater which should have been called Windows_updater
    public void on_start_installer ();

protected slots:
    void background_check_for_update () override;
    void on_open_update_url ();


    /***********************************************************
    ***********************************************************/
    private void on_version_info_arrived ();
    private void on_timed_out ();


    protected virtual void version_info_arrived (Update_info info);
    protected bool update_succeeded ();
    protected QNetworkAccessManager qnam () {
        return this.access_manager;
    }
    protected Update_info update_info () {
        return this.update_info;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Uri this.update_url;
    private int this.state;
    private QNetworkAccessManager this.access_manager;
    private QTimer this.timeout_watchdog; /** Timer to guard the timeout of an individual network request */
    private Update_info this.update_info;
}




    /***********************************************************
    ***********************************************************/
    const string update_available_c = "Updater/update_available";
    const string update_target_version_c = "Updater/update_target_version";
    const string update_target_version_string_c = "Updater/update_target_version_string";
    const string seen_version_c = "Updater/seen_version";
    const string auto_update_attempted_c = "Updater/auto_update_attempted";


    OCUpdater.OCUpdater (GLib.Uri url)
        : Updater ()
        this.update_url (url)
        this.state (Unknown)
        this.access_manager (new AccessManager (this))
        this.timeout_watchdog (new QTimer (this)) {
    }

    void OCUpdater.update_url (GLib.Uri url) {
        this.update_url = url;
    }

    bool OCUpdater.perform_update () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        if (!update_file.is_empty () && GLib.File (update_file).exists ()
            && !update_succeeded () /* Someone might have run the updater manually between restarts */) {
            const var message_box_start_installer = new QMessageBox (QMessageBox.Information,
                _("New %1 update ready").arg (Theme.instance ().app_name_gui ()),
                _("A new update for %1 is about to be installed. The updater may ask "
                   "for additional privileges during the process. Your computer may reboot to complete the installation.")
                    .arg (Theme.instance ().app_name_gui ()),
                QMessageBox.Ok,
                null);

            message_box_start_installer.attribute (Qt.WA_DeleteOnClose);

            connect (message_box_start_installer, &QMessageBox.on_finished, this, [this] {
                on_start_installer ();
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
            GLib.info (lc_updater) << "Checking for available update";
            check_for_update ();
            break;
        case Download_complete:
            GLib.info (lc_updater) << "Update is downloaded, skip new check.";
            break;
        case Update_only_available_through_system:
            GLib.info (lc_updater) << "Update is only available through system, skip check.";
            break;
        }
    }

    string OCUpdater.status_string (Update_status_string_format format) {
        string update_version = this.update_info.version_"";

        switch (download_state ()) {
        case Downloading:
            return _("Downloading %1. Please wait …").arg (update_version);
        case Download_complete:
            return _("%1 available. Restart application to on_start the update.").arg (update_version);
        case Download_failed: {
            if (format == Update_status_string_format.Html) {
                return _("Could not download update. Please open <a href='%1'>%1</a> to download the update manually.").arg (this.update_info.web ());
            }
            return _("Could not download update. Please open %1 to download the update manually.").arg (this.update_info.web ());
        }
        case Download_timed_out:
            return _("Could not check for new updates.");
        case Update_only_available_through_system: {
            if (format == Update_status_string_format.Html) {
                return _("New %1 is available. Please open <a href='%2'>%2</a> to download the update.").arg (update_version, this.update_info.web ());
            }
            return _("New %1 is available. Please open %2 to download the update.").arg (update_version, this.update_info.web ());
        }
        case Checking_server:
            return _("Checking update server …");
        case Unknown:
            return _("Update status is unknown : Did not check for new updates.");
        case Up_to_date:
        // fall through
        default:
            return _("No updates available. Your installation is at the latest version.");
        }
    }

    int OCUpdater.download_state () {
        return this.state;
    }

    void OCUpdater.download_state (Download_state state) {
        var old_state = this.state;
        this.state = state;
        /* emit */ download_state_changed ();

        // show the notification if the download is complete (on every check)
        // or once for system based updates.
        if (this.state == OCUpdater.Download_complete || (old_state != OCUpdater.Update_only_available_through_system
                                                         && this.state == OCUpdater.Update_only_available_through_system)) {
            /* emit */ new_update_available (_("Update Check"), status_string ());
        }
    }

    void OCUpdater.on_start_installer () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        settings.value (auto_update_attempted_c, true);
        settings.sync ();
        GLib.info (lc_updater) << "Running updater" << update_file;

        if (update_file.ends_with (".exe")) {
            QProcess.start_detached (update_file, string[] () << "/S"
                                                              << "/launch");
        } else if (update_file.ends_with (".msi")) {
            // When MSIs are installed without gui they cannot launch applications
            // as they lack the user context. That is why we need to run the client
            // manually here. We wrap the msiexec and client invocation in a powershell
            // script because owncloud.exe will be shut down for installation.
            // | Out-Null forces powershell to wait for msiexec to finish.
            var prepare_path_for_powershell = [] (string path) {
                path.replace ("'", "''");

                return QDir.to_native_separators (path);
            }

            string msi_log_file = config.config_path () + "msi.log";
            string command = string ("&{msiexec /promptrestart /passive /i '%1' /L*V '%2'| Out-Null ; &'%3'}")
                 .arg (prepare_path_for_powershell (update_file))
                 .arg (prepare_path_for_powershell (msi_log_file))
                 .arg (prepare_path_for_powershell (QCoreApplication.application_file_path ()));

            QProcess.start_detached ("powershell.exe", string[]{"-Command", command});
        }
        Gtk.Application.quit ();
    }

    void OCUpdater.check_for_update () {
        Soup.Reply reply = this.access_manager.get (QNetworkRequest (this.update_url));
        connect (this.timeout_watchdog, &QTimer.timeout, this, &OCUpdater.on_timed_out);
        this.timeout_watchdog.on_start (30 * 1000);
        connect (reply, &Soup.Reply.on_finished, this, &OCUpdater.on_version_info_arrived);

        download_state (Checking_server);
    }

    void OCUpdater.on_open_update_url () {
        QDesktopServices.open_url (this.update_info.web ());
    }

    bool OCUpdater.update_succeeded () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);

        int64 target_version_int = Helper.string_version_to_int (settings.value (update_target_version_c).to_string ());
        int64 current_version = Helper.current_version_to_int ();
        return current_version >= target_version_int;
    }

    void OCUpdater.on_version_info_arrived () {
        this.timeout_watchdog.stop ();
        var reply = qobject_cast<Soup.Reply> (sender ());
        reply.delete_later ();
        if (reply.error () != Soup.Reply.NoError) {
            GLib.warn (lc_updater) << "Failed to reach version check url : " << reply.error_string ();
            download_state (Download_timed_out);
            return;
        }

        string xml = string.from_utf8 (reply.read_all ());

        bool ok = false;
        this.update_info = Update_info.parse_string (xml, ok);
        if (ok) {
            version_info_arrived (this.update_info);
        } else {
            GLib.warn (lc_updater) << "Could not parse update information.";
            download_state (Download_timed_out);
        }
    }

    void OCUpdater.on_timed_out () {
        download_state (Download_timed_out);
    }


} // namespace mirall
    