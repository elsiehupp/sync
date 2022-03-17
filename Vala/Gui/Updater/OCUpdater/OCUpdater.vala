/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtNetwork>
//  #include <QtGui>
//  #include <Qt_widgets>
//  #include <cstdio>
//  #include <QTemporaryFile>
//  #include <QTimer>

namespace Occ {
namespace Ui {

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
if there is a new version once at every on_signal_start

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
public class OCUpdater : Updater {

    /***********************************************************
    ***********************************************************/
    private const string update_available_c = "Updater/update_available";
    private const string update_target_version_c = "Updater/update_target_version";
    private const string update_target_version_string_c = "Updater/update_target_version_string";
    private const string seen_version_c = "Updater/seen_version";
    private const string auto_update_attempted_c = "Updater/auto_update_attempted";

    /***********************************************************
    ***********************************************************/
    public enum DownloadState {
        UNKOWN = 0,
        CHECKING_SERVER,
        UP_TO_DATE,
        DOWNLOADING,
        DOWNLOAD_COMPLETE,
        DOWNLOAD_FAILED,
        DOWNLOAD_TIMED_OUT,
        UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM
    }


    /***********************************************************
    ***********************************************************/
    public enum UpdateStatusStringFormat {
        PLAIN_TEXT,
        HTML
    }

    int download_state {
        public get {
            return this.state;
        }
        public set {
            var old_state = this.state;
            this.state = value;
            /* emit */ signal_download_state_changed ();
    
            // show the notification if the download is complete (on every check)
            // or once for system based updates.
            if (this.state == OCUpdater.DownloadState.DOWNLOAD_COMPLETE || (old_state != OCUpdater.DownloadState.UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM
                                                             && this.state == OCUpdater.DownloadState.UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM)) {
                /* emit */ signal_new_update_available (_("Update Check"), status_string ());
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    new GLib.Uri update_url { private get; public set; }

    private int state;
    private QNetworkAccessManager access_manager;

    /***********************************************************
    Timer to guard the timeout of an individual network request
    ***********************************************************/
    private QTimer timeout_watchdog;

    UpdateInfo update_info { protected get; private set; }


    internal signal void signal_download_state_changed ();
    internal signal void signal_new_update_available (string header, string message);
    internal signal void signal_request_restart ();


    /***********************************************************
    ***********************************************************/
    public OCUpdater (GLib.Uri url) {
        base ();
        this.update_url = url;
        this.state = Unknown;
        this.access_manager = new AccessManager (this);
        this.timeout_watchdog = new QTimer (this);
    }


    /***********************************************************
    ***********************************************************/
    public bool perform_update () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        if (!update_file == "" && GLib.File (update_file).exists ()
            && !update_succeeded () /* Someone might have run the updater manually between restarts */) {
            const var message_box_start_installer = new QMessageBox (QMessageBox.Information,
                _("New %1 update ready").printf (Theme.instance.app_name_gui ()),
                _("A new update for %1 is about to be installed. The updater may ask "
                + "for additional privileges during the process. Your computer may reboot to complete the installation.")
                    .printf (Theme.instance.app_name_gui ()),
                QMessageBox.Ok,
                null);

            message_box_start_installer.attribute (Qt.WA_DeleteOnClose);

            connect (
                message_box_start_installer,
                QMessageBox.on_signal_finished,
                this,
                this.on_signal_start_installer
            );
            message_box_start_installer.open ();
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override void check_for_update () {
        Soup.Reply reply = this.access_manager.get (Soup.Request (this.update_url));
        connect (this.timeout_watchdog, QTimer.timeout, this, OCUpdater.on_signal_timed_out);
        this.timeout_watchdog.on_signal_start (30 * 1000);
        connect (reply, Soup.Reply.on_signal_finished, this, OCUpdater.on_signal_version_info_arrived);

        download_state (DownloadState.CHECKING_SERVER);
    }


    /***********************************************************
    ***********************************************************/
    public string status_string (UpdateStatusStringFormat format = UpdateStatusStringFormat.PLAIN_TEXT) {
        string update_version = this.update_info.version_string ();

        switch (download_state ()) {
        case DownloadState.DOWNLOADING:
            return _("Downloading %1. Please wait …").printf (update_version);
        case DownloadState.DOWNLOAD_COMPLETE:
            return _("%1 available. Restart application to on_signal_start the update.").printf (update_version);
        case DownloadState.DOWNLOAD_FAILED: {
            if (format == UpdateStatusStringFormat.UpdateStatusStringFormat.HTML) {
                return _("Could not download update. Please open <a href='%1'>%1</a> to download the update manually.").printf (this.update_info.web ());
            }
            return _("Could not download update. Please open %1 to download the update manually.").printf (this.update_info.web ());
        }
        case DownloadState.DOWNLOAD_TIMED_OUT:
            return _("Could not check for new updates.");
        case DownloadState.UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM: {
            if (format == UpdateStatusStringFormat.UpdateStatusStringFormat.HTML) {
                return _("New %1 is available. Please open <a href='%2'>%2</a> to download the update.").printf (update_version, this.update_info.web ());
            }
            return _("New %1 is available. Please open %2 to download the update.").printf (update_version, this.update_info.web ());
        }
        case DownloadState.CHECKING_SERVER:
            return _("Checking update server …");
        case Unknown:
            return _("Update status is unknown : Did not check for new updates.");
        case DownloadState.UP_TO_DATE:
        // fall through
        default:
            return _("No updates available. Your installation is at the latest version.");
        }
    }


    /***********************************************************
    FIXME: Maybe this should be in the NSISUpdater which should
    have been called Windows_updater
    ***********************************************************/
    public void on_signal_start_installer () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);
        string update_file = settings.value (update_available_c).to_string ();
        settings.value (auto_update_attempted_c, true);
        settings.sync ();
        GLib.info ("Running updater " + update_file);

        if (update_file.ends_with (".exe")) {
            QProcess.start_detached (
                update_file,
                {
                    "/S",
                    "/launch"
                }
            );
        } else if (update_file.ends_with (".msi")) {
            // When MSIs are installed without gui they cannot launch applications
            // as they lack the user context. That is why we need to run the client
            // manually here. We wrap the msiexec and client invocation in a powershell
            // script because owncloud.exe will be shut down for installation.
            // | Out-Null forces powershell to wait for msiexec to finish.

            string msi_log_file = config.config_path () + "msi.log";
            string command = string ("&{msiexec /promptrestart /passive /i '%1' /L*V '%2'| Out-Null ; &'%3'}")
                 .printf (prepare_path_for_powershell (update_file))
                 .printf (prepare_path_for_powershell (msi_log_file))
                 .printf (prepare_path_for_powershell (QCoreApplication.application_file_path ()));

            QProcess.start_detached ("powershell.exe", {"-Command", command});
        }
        Gtk.Application.quit ();
    }


    /***********************************************************
    ***********************************************************/
    private static QDir prepare_path_for_powershell (string path) {
        path.replace ("'", "''");

        return QDir.to_native_separators (path);
    }


    /***********************************************************
    ***********************************************************/
    protected override void on_signal_background_check_for_update () {
        int dl_state = download_state ();

        // do the real update check depending on the internal state of updater.
        switch (dl_state) {
        case Unknown:
        case DownloadState.UP_TO_DATE:
        case DownloadState.DOWNLOAD_FAILED:
        case DownloadState.DOWNLOAD_TIMED_OUT:
            GLib.info ("Checking for available update.");
            check_for_update ();
            break;
        case DownloadState.DOWNLOAD_COMPLETE:
            GLib.info ("Update is downloaded, skip new check.");
            break;
        case DownloadState.UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM:
            GLib.info ("Update is only available through system, skip check.");
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_update_url () {
        QDesktopServices.open_url (this.update_info.web ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_version_info_arrived () {
        this.timeout_watchdog.stop ();
        var reply = (Soup.Reply) sender ();
        reply.delete_later ();
        if (reply.error () != Soup.Reply.NoError) {
            GLib.warning ("Failed to reach version check url: " + reply.error_string ());
            download_state (DownloadState.DOWNLOAD_TIMED_OUT);
            return;
        }

        string xml = string.from_utf8 (reply.read_all ());

        bool ok = false;
        this.update_info = UpdateInfo.parse_string (xml, ok);
        if (ok) {
            version_info_arrived (this.update_info);
        } else {
            GLib.warning ("Could not parse update information.");
            download_state (DownloadState.DOWNLOAD_TIMED_OUT);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_timed_out () {
        download_state (DownloadState.DOWNLOAD_TIMED_OUT);
    }


    /***********************************************************
    ***********************************************************/
    protected virtual void version_info_arrived (UpdateInfo info);


    /***********************************************************
    ***********************************************************/
    protected bool update_succeeded () {
        ConfigFile config;
        QSettings settings = new QSettings (config.config_file (), QSettings.IniFormat);

        int64 target_version_int = Helper.string_version_to_int (settings.value (update_target_version_c).to_string ());
        int64 current_version = Helper.current_version_to_int ();
        return current_version >= target_version_int;
    }


    /***********************************************************
    ***********************************************************/
    protected QNetworkAccessManager qnam () {
        return this.access_manager;
    }

} // class OCUpdater

} // namespace Ui
} // namespace Occ
    