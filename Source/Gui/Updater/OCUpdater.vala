/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QtCore>
// #include <QtNetwork>
// #include <QtGui>
// #include <QtWidgets>

// #include <cstdio>

// #include <GLib.Object>
// #include <QUrl>
// #include <QTemporaryFile>
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
the MacOSX SparkleUpdater directly uses the class Updater. On windows,
NSISUpdater starts the update if a new version of the client is available.
On MacOSX, the sparkle framework handles the installation of the new
version. On Linux, the update capabilit
are relied on, and thus the PassiveUpda
if there is a new version once at every start

Simple class diagram of the updater:

          +---------------------------+
    +-----+   UpdaterScheduler        +-----+
    |     +------------+--------------+     |
    v                  v                    v
+------------+ +-----------
|NSISUpdater | |PassiveUpdate
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
    void updaterAnnouncement (string &title, string &msg);
    void requestRestart ();

private slots:
    void slotTimerFired ();

private:
    QTimer _updateCheckTimer; /** Timer for the regular update check. */
};

/***********************************************************
@brief Class that uses an ownCloud proprietary XML format to fetch update information
@ingroup gui
***********************************************************/
class OCUpdater : Updater {
public:
    enum DownloadState { Unknown = 0,
        CheckingServer,
        UpToDate,
        Downloading,
        DownloadComplete,
        DownloadFailed,
        DownloadTimedOut,
        UpdateOnlyAvailableThroughSystem };

    enum UpdateStatusStringFormat {
        PlainText,
        Html,
    };
    OCUpdater (QUrl &url);

    void setUpdateUrl (QUrl &url);

    bool performUpdate ();

    void checkForUpdate () override;

    string statusString (UpdateStatusStringFormat format = PlainText) const;
    int downloadState ();
    void setDownloadState (DownloadState state);

signals:
    void downloadStateChanged ();
    void newUpdateAvailable (string &header, string &message);
    void requestRestart ();

public slots:
    // FIXME Maybe this should be in the NSISUpdater which should have been called WindowsUpdater
    void slotStartInstaller ();

protected slots:
    void backgroundCheckForUpdate () override;
    void slotOpenUpdateUrl ();

private slots:
    void slotVersionInfoArrived ();
    void slotTimedOut ();

protected:
    virtual void versionInfoArrived (UpdateInfo &info) = 0;
    bool updateSucceeded ();
    QNetworkAccessManager *qnam () { return _accessManager; }
    UpdateInfo updateInfo () { return _updateInfo; }

private:
    QUrl _updateUrl;
    int _state;
    QNetworkAccessManager *_accessManager;
    QTimer *_timeoutWatchdog; /** Timer to guard the timeout of an individual network request */
    UpdateInfo _updateInfo;
};

/***********************************************************
@brief Windows Updater Using NSIS
@ingroup gui
***********************************************************/
class NSISUpdater : OCUpdater {
public:
    NSISUpdater (QUrl &url);
    bool handleStartup () override;
private slots:
    void slotSetSeenVersion ();
    void slotDownloadFinished ();
    void slotWriteFile ();

private:
    void wipeUpdateData ();
    void showNoUrlDialog (UpdateInfo &info);
    void showUpdateErrorDialog (string &targetVersion);
    void versionInfoArrived (UpdateInfo &info) override;
    QScopedPointer<QTemporaryFile> _file;
    string _targetFile;
};

/***********************************************************
 @brief Updater that only implements notification for use in settings

 The implementation does not show popups

 @ingroup gui
***********************************************************/
class PassiveUpdateNotifier : OCUpdater {
public:
    PassiveUpdateNotifier (QUrl &url);
    bool handleStartup () override { return false; }
    void backgroundCheckForUpdate () override;

private:
    void versionInfoArrived (UpdateInfo &info) override;
    QByteArray _runningAppVersion;
};
}











namespace Occ {

    static const char updateAvailableC[] = "Updater/updateAvailable";
    static const char updateTargetVersionC[] = "Updater/updateTargetVersion";
    static const char updateTargetVersionStringC[] = "Updater/updateTargetVersionString";
    static const char seenVersionC[] = "Updater/seenVersion";
    static const char autoUpdateAttemptedC[] = "Updater/autoUpdateAttempted";
    
    UpdaterScheduler.UpdaterScheduler (GLib.Object *parent)
        : GLib.Object (parent) {
        connect (&_updateCheckTimer, &QTimer.timeout,
            this, &UpdaterScheduler.slotTimerFired);
    
        // Note : the sparkle-updater is not an OCUpdater
        if (auto *updater = qobject_cast<OCUpdater> (Updater.instance ())) {
            connect (updater, &OCUpdater.newUpdateAvailable,
                this, &UpdaterScheduler.updaterAnnouncement);
            connect (updater, &OCUpdater.requestRestart, this, &UpdaterScheduler.requestRestart);
        }
    
        // at startup, do a check in any case.
        QTimer.singleShot (3000, this, &UpdaterScheduler.slotTimerFired);
    
        ConfigFile cfg;
        auto checkInterval = cfg.updateCheckInterval ();
        _updateCheckTimer.start (std.chrono.milliseconds (checkInterval).count ());
    }
    
    void UpdaterScheduler.slotTimerFired () {
        ConfigFile cfg;
    
        // re-set the check interval if it changed in the config file meanwhile
        auto checkInterval = std.chrono.milliseconds (cfg.updateCheckInterval ()).count ();
        if (checkInterval != _updateCheckTimer.interval ()) {
            _updateCheckTimer.setInterval (checkInterval);
            qCInfo (lcUpdater) << "Setting new update check interval " << checkInterval;
        }
    
        // consider the skipUpdateCheck and !autoUpdateCheck flags in the config.
        if (cfg.skipUpdateCheck () || !cfg.autoUpdateCheck ()) {
            qCInfo (lcUpdater) << "Skipping update check because of config file";
            return;
        }
    
        Updater *updater = Updater.instance ();
        if (updater) {
            updater.backgroundCheckForUpdate ();
        }
    }
    
    /* ----------------------------------------------------------------- */
    
    OCUpdater.OCUpdater (QUrl &url)
        : Updater ()
        , _updateUrl (url)
        , _state (Unknown)
        , _accessManager (new AccessManager (this))
        , _timeoutWatchdog (new QTimer (this)) {
    }
    
    void OCUpdater.setUpdateUrl (QUrl &url) {
        _updateUrl = url;
    }
    
    bool OCUpdater.performUpdate () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        string updateFile = settings.value (updateAvailableC).toString ();
        if (!updateFile.isEmpty () && QFile (updateFile).exists ()
            && !updateSucceeded () /* Someone might have run the updater manually between restarts */) {
            const auto messageBoxStartInstaller = new QMessageBox (QMessageBox.Information,
                tr ("New %1 update ready").arg (Theme.instance ().appNameGUI ()),
                tr ("A new update for %1 is about to be installed. The updater may ask "
                   "for additional privileges during the process. Your computer may reboot to complete the installation.")
                    .arg (Theme.instance ().appNameGUI ()),
                QMessageBox.Ok,
                nullptr);
    
            messageBoxStartInstaller.setAttribute (Qt.WA_DeleteOnClose);
    
            connect (messageBoxStartInstaller, &QMessageBox.finished, this, [this] {
                slotStartInstaller ();
            });
            messageBoxStartInstaller.open ();
        }
        return false;
    }
    
    void OCUpdater.backgroundCheckForUpdate () {
        int dlState = downloadState ();
    
        // do the real update check depending on the internal state of updater.
        switch (dlState) {
        case Unknown:
        case UpToDate:
        case DownloadFailed:
        case DownloadTimedOut:
            qCInfo (lcUpdater) << "Checking for available update";
            checkForUpdate ();
            break;
        case DownloadComplete:
            qCInfo (lcUpdater) << "Update is downloaded, skip new check.";
            break;
        case UpdateOnlyAvailableThroughSystem:
            qCInfo (lcUpdater) << "Update is only available through system, skip check.";
            break;
        }
    }
    
    string OCUpdater.statusString (UpdateStatusStringFormat format) {
        string updateVersion = _updateInfo.versionString ();
    
        switch (downloadState ()) {
        case Downloading:
            return tr ("Downloading %1. Please wait …").arg (updateVersion);
        case DownloadComplete:
            return tr ("%1 available. Restart application to start the update.").arg (updateVersion);
        case DownloadFailed : {
            if (format == UpdateStatusStringFormat.Html) {
                return tr ("Could not download update. Please open <a href='%1'>%1</a> to download the update manually.").arg (_updateInfo.web ());
            }
            return tr ("Could not download update. Please open %1 to download the update manually.").arg (_updateInfo.web ());
        }
        case DownloadTimedOut:
            return tr ("Could not check for new updates.");
        case UpdateOnlyAvailableThroughSystem : {
            if (format == UpdateStatusStringFormat.Html) {
                return tr ("New %1 is available. Please open <a href='%2'>%2</a> to download the update.").arg (updateVersion, _updateInfo.web ());
            }
            return tr ("New %1 is available. Please open %2 to download the update.").arg (updateVersion, _updateInfo.web ());
        }
        case CheckingServer:
            return tr ("Checking update server …");
        case Unknown:
            return tr ("Update status is unknown : Did not check for new updates.");
        case UpToDate:
        // fall through
        default:
            return tr ("No updates available. Your installation is at the latest version.");
        }
    }
    
    int OCUpdater.downloadState () {
        return _state;
    }
    
    void OCUpdater.setDownloadState (DownloadState state) {
        auto oldState = _state;
        _state = state;
        emit downloadStateChanged ();
    
        // show the notification if the download is complete (on every check)
        // or once for system based updates.
        if (_state == OCUpdater.DownloadComplete || (oldState != OCUpdater.UpdateOnlyAvailableThroughSystem
                                                         && _state == OCUpdater.UpdateOnlyAvailableThroughSystem)) {
            emit newUpdateAvailable (tr ("Update Check"), statusString ());
        }
    }
    
    void OCUpdater.slotStartInstaller () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        string updateFile = settings.value (updateAvailableC).toString ();
        settings.setValue (autoUpdateAttemptedC, true);
        settings.sync ();
        qCInfo (lcUpdater) << "Running updater" << updateFile;
    
        if (updateFile.endsWith (".exe")) {
            QProcess.startDetached (updateFile, QStringList () << "/S"
                                                              << "/launch");
        } else if (updateFile.endsWith (".msi")) {
            // When MSIs are installed without gui they cannot launch applications
            // as they lack the user context. That is why we need to run the client
            // manually here. We wrap the msiexec and client invocation in a powershell
            // script because owncloud.exe will be shut down for installation.
            // | Out-Null forces powershell to wait for msiexec to finish.
            auto preparePathForPowershell = [] (string path) {
                path.replace ("'", "''");
    
                return QDir.toNativeSeparators (path);
            };
    
            string msiLogFile = cfg.configPath () + "msi.log";
            string command = string ("&{msiexec /promptrestart /passive /i '%1' /L*V '%2'| Out-Null ; &'%3'}")
                 .arg (preparePathForPowershell (updateFile))
                 .arg (preparePathForPowershell (msiLogFile))
                 .arg (preparePathForPowershell (QCoreApplication.applicationFilePath ()));
    
            QProcess.startDetached ("powershell.exe", QStringList{"-Command", command});
        }
        qApp.quit ();
    }
    
    void OCUpdater.checkForUpdate () {
        QNetworkReply *reply = _accessManager.get (QNetworkRequest (_updateUrl));
        connect (_timeoutWatchdog, &QTimer.timeout, this, &OCUpdater.slotTimedOut);
        _timeoutWatchdog.start (30 * 1000);
        connect (reply, &QNetworkReply.finished, this, &OCUpdater.slotVersionInfoArrived);
    
        setDownloadState (CheckingServer);
    }
    
    void OCUpdater.slotOpenUpdateUrl () {
        QDesktopServices.openUrl (_updateInfo.web ());
    }
    
    bool OCUpdater.updateSucceeded () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
    
        int64 targetVersionInt = Helper.stringVersionToInt (settings.value (updateTargetVersionC).toString ());
        int64 currentVersion = Helper.currentVersionToInt ();
        return currentVersion >= targetVersionInt;
    }
    
    void OCUpdater.slotVersionInfoArrived () {
        _timeoutWatchdog.stop ();
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        reply.deleteLater ();
        if (reply.error () != QNetworkReply.NoError) {
            qCWarning (lcUpdater) << "Failed to reach version check url : " << reply.errorString ();
            setDownloadState (DownloadTimedOut);
            return;
        }
    
        string xml = string.fromUtf8 (reply.readAll ());
    
        bool ok = false;
        _updateInfo = UpdateInfo.parseString (xml, &ok);
        if (ok) {
            versionInfoArrived (_updateInfo);
        } else {
            qCWarning (lcUpdater) << "Could not parse update information.";
            setDownloadState (DownloadTimedOut);
        }
    }
    
    void OCUpdater.slotTimedOut () {
        setDownloadState (DownloadTimedOut);
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    NSISUpdater.NSISUpdater (QUrl &url)
        : OCUpdater (url) {
    }
    
    void NSISUpdater.slotWriteFile () {
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        if (_file.isOpen ()) {
            _file.write (reply.readAll ());
        }
    }
    
    void NSISUpdater.wipeUpdateData () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        string updateFileName = settings.value (updateAvailableC).toString ();
        if (!updateFileName.isEmpty ())
            QFile.remove (updateFileName);
        settings.remove (updateAvailableC);
        settings.remove (updateTargetVersionC);
        settings.remove (updateTargetVersionStringC);
        settings.remove (autoUpdateAttemptedC);
    }
    
    void NSISUpdater.slotDownloadFinished () {
        auto *reply = qobject_cast<QNetworkReply> (sender ());
        reply.deleteLater ();
        if (reply.error () != QNetworkReply.NoError) {
            setDownloadState (DownloadFailed);
            return;
        }
    
        QUrl url (reply.url ());
        _file.close ();
    
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
    
        // remove previously downloaded but not used installer
        QFile oldTargetFile (settings.value (updateAvailableC).toString ());
        if (oldTargetFile.exists ()) {
            oldTargetFile.remove ();
        }
    
        QFile.copy (_file.fileName (), _targetFile);
        setDownloadState (DownloadComplete);
        qCInfo (lcUpdater) << "Downloaded" << url.toString () << "to" << _targetFile;
        settings.setValue (updateTargetVersionC, updateInfo ().version ());
        settings.setValue (updateTargetVersionStringC, updateInfo ().versionString ());
        settings.setValue (updateAvailableC, _targetFile);
    }
    
    void NSISUpdater.versionInfoArrived (UpdateInfo &info) {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        int64 infoVersion = Helper.stringVersionToInt (info.version ());
        auto seenString = settings.value (seenVersionC).toString ();
        int64 seenVersion = Helper.stringVersionToInt (seenString);
        int64 currVersion = Helper.currentVersionToInt ();
        qCInfo (lcUpdater) << "Version info arrived:"
                << "Your version:" << currVersion
                << "Skipped version:" << seenVersion << seenString
                << "Available version:" << infoVersion << info.version ()
                << "Available version string:" << info.versionString ()
                << "Web url:" << info.web ()
                << "Download url:" << info.downloadUrl ();
        if (info.version ().isEmpty ()) {
            qCInfo (lcUpdater) << "No version information available at the moment";
            setDownloadState (UpToDate);
        } else if (infoVersion <= currVersion
                   || infoVersion <= seenVersion) {
            qCInfo (lcUpdater) << "Client is on latest version!";
            setDownloadState (UpToDate);
        } else {
            string url = info.downloadUrl ();
            if (url.isEmpty ()) {
                showNoUrlDialog (info);
            } else {
                _targetFile = cfg.configPath () + url.mid (url.lastIndexOf ('/')+1);
                if (QFile (_targetFile).exists ()) {
                    setDownloadState (DownloadComplete);
                } else {
                    auto request = QNetworkRequest (QUrl (url));
                    request.setAttribute (QNetworkRequest.RedirectPolicyAttribute, QNetworkRequest.NoLessSafeRedirectPolicy);
                    QNetworkReply *reply = qnam ().get (request);
                    connect (reply, &QIODevice.readyRead, this, &NSISUpdater.slotWriteFile);
                    connect (reply, &QNetworkReply.finished, this, &NSISUpdater.slotDownloadFinished);
                    setDownloadState (Downloading);
                    _file.reset (new QTemporaryFile);
                    _file.setAutoRemove (true);
                    _file.open ();
                }
            }
        }
    }
    
    void NSISUpdater.showNoUrlDialog (UpdateInfo &info) {
        // if the version tag is set, there is a newer version.
        auto *msgBox = new Gtk.Dialog;
        msgBox.setAttribute (Qt.WA_DeleteOnClose);
        msgBox.setWindowFlags (msgBox.windowFlags () & ~Qt.WindowContextHelpButtonHint);
    
        QIcon infoIcon = msgBox.style ().standardIcon (QStyle.SP_MessageBoxInformation);
        int iconSize = msgBox.style ().pixelMetric (QStyle.PM_MessageBoxIconSize);
    
        msgBox.setWindowIcon (infoIcon);
    
        auto *layout = new QVBoxLayout (msgBox);
        auto *hlayout = new QHBoxLayout;
        layout.addLayout (hlayout);
    
        msgBox.setWindowTitle (tr ("New Version Available"));
    
        auto *ico = new QLabel;
        ico.setFixedSize (iconSize, iconSize);
        ico.setPixmap (infoIcon.pixmap (iconSize));
        auto *lbl = new QLabel;
        string txt = tr ("<p>A new version of the %1 Client is available.</p>"
                         "<p><b>%2</b> is available for download. The installed version is %3.</p>")
                          .arg (Utility.escape (Theme.instance ().appNameGUI ()),
                              Utility.escape (info.versionString ()), Utility.escape (clientVersion ()));
    
        lbl.setText (txt);
        lbl.setTextFormat (Qt.RichText);
        lbl.setWordWrap (true);
    
        hlayout.addWidget (ico);
        hlayout.addWidget (lbl);
    
        auto *bb = new QDialogButtonBox;
        QPushButton *skip = bb.addButton (tr ("Skip this version"), QDialogButtonBox.ResetRole);
        QPushButton *reject = bb.addButton (tr ("Skip this time"), QDialogButtonBox.AcceptRole);
        QPushButton *getupdate = bb.addButton (tr ("Get update"), QDialogButtonBox.AcceptRole);
    
        connect (skip, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.reject);
        connect (reject, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.reject);
        connect (getupdate, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.accept);
    
        connect (skip, &QAbstractButton.clicked, this, &NSISUpdater.slotSetSeenVersion);
        connect (getupdate, &QAbstractButton.clicked, this, &NSISUpdater.slotOpenUpdateUrl);
    
        layout.addWidget (bb);
    
        msgBox.open ();
    }
    
    void NSISUpdater.showUpdateErrorDialog (string &targetVersion) {
        auto msgBox = new Gtk.Dialog;
        msgBox.setAttribute (Qt.WA_DeleteOnClose);
        msgBox.setWindowFlags (msgBox.windowFlags () & ~Qt.WindowContextHelpButtonHint);
    
        QIcon infoIcon = msgBox.style ().standardIcon (QStyle.SP_MessageBoxInformation);
        int iconSize = msgBox.style ().pixelMetric (QStyle.PM_MessageBoxIconSize);
    
        msgBox.setWindowIcon (infoIcon);
    
        auto layout = new QVBoxLayout (msgBox);
        auto hlayout = new QHBoxLayout;
        layout.addLayout (hlayout);
    
        msgBox.setWindowTitle (tr ("Update Failed"));
    
        auto ico = new QLabel;
        ico.setFixedSize (iconSize, iconSize);
        ico.setPixmap (infoIcon.pixmap (iconSize));
        auto lbl = new QLabel;
        string txt = tr ("<p>A new version of the %1 Client is available but the updating process failed.</p>"
                         "<p><b>%2</b> has been downloaded. The installed version is %3. If you confirm restart and update, your computer may reboot to complete the installation.</p>")
                          .arg (Utility.escape (Theme.instance ().appNameGUI ()),
                              Utility.escape (targetVersion), Utility.escape (clientVersion ()));
    
        lbl.setText (txt);
        lbl.setTextFormat (Qt.RichText);
        lbl.setWordWrap (true);
    
        hlayout.addWidget (ico);
        hlayout.addWidget (lbl);
    
        auto bb = new QDialogButtonBox;
        auto skip = bb.addButton (tr ("Skip this version"), QDialogButtonBox.ResetRole);
        auto askagain = bb.addButton (tr ("Ask again later"), QDialogButtonBox.ResetRole);
        auto retry = bb.addButton (tr ("Restart and update"), QDialogButtonBox.AcceptRole);
        auto getupdate = bb.addButton (tr ("Update manually"), QDialogButtonBox.AcceptRole);
    
        connect (skip, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.reject);
        connect (askagain, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.reject);
        connect (retry, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.accept);
        connect (getupdate, &QAbstractButton.clicked, msgBox, &Gtk.Dialog.accept);
    
        connect (skip, &QAbstractButton.clicked, this, [this] () {
            wipeUpdateData ();
            slotSetSeenVersion ();
        });
        // askagain : do nothing
        connect (retry, &QAbstractButton.clicked, this, [this] () {
            slotStartInstaller ();
        });
        connect (getupdate, &QAbstractButton.clicked, this, [this] () {
            slotOpenUpdateUrl ();
        });
    
        layout.addWidget (bb);
    
        msgBox.open ();
    }
    
    bool NSISUpdater.handleStartup () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        string updateFileName = settings.value (updateAvailableC).toString ();
        // has the previous run downloaded an update?
        if (!updateFileName.isEmpty () && QFile (updateFileName).exists ()) {
            qCInfo (lcUpdater) << "An updater file is available";
            // did it try to execute the update?
            if (settings.value (autoUpdateAttemptedC, false).toBool ()) {
                if (updateSucceeded ()) {
                    // success : clean up
                    qCInfo (lcUpdater) << "The requested update attempt has succeeded"
                            << Helper.currentVersionToInt ();
                    wipeUpdateData ();
                    return false;
                } else {
                    // auto update failed. Ask user what to do
                    qCInfo (lcUpdater) << "The requested update attempt has failed"
                            << settings.value (updateTargetVersionC).toString ();
                    showUpdateErrorDialog (settings.value (updateTargetVersionStringC).toString ());
                    return false;
                }
            } else {
                qCInfo (lcUpdater) << "Triggering an update";
                return performUpdate ();
            }
        }
        return false;
    }
    
    void NSISUpdater.slotSetSeenVersion () {
        ConfigFile cfg;
        QSettings settings (cfg.configFile (), QSettings.IniFormat);
        settings.setValue (seenVersionC, updateInfo ().version ());
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    PassiveUpdateNotifier.PassiveUpdateNotifier (QUrl &url)
        : OCUpdater (url) {
        // remember the version of the currently running binary. On Linux it might happen that the
        // package management updates the package while the app is running. This is detected in the
        // updater slot : If the installed binary on the hd has a different version than the one
        // running, the running app is restarted. That happens in folderman.
        _runningAppVersion = Utility.versionOfInstalledBinary ();
    }
    
    void PassiveUpdateNotifier.backgroundCheckForUpdate () {
        if (Utility.isLinux ()) {
            // on linux, check if the installed binary is still the same version
            // as the one that is running. If not, restart if possible.
            const QByteArray fsVersion = Utility.versionOfInstalledBinary ();
            if (! (fsVersion.isEmpty () || _runningAppVersion.isEmpty ()) && fsVersion != _runningAppVersion) {
                emit requestRestart ();
            }
        }
    
        OCUpdater.backgroundCheckForUpdate ();
    }
    
    void PassiveUpdateNotifier.versionInfoArrived (UpdateInfo &info) {
        int64 currentVer = Helper.currentVersionToInt ();
        int64 remoteVer = Helper.stringVersionToInt (info.version ());
    
        if (info.version ().isEmpty () || currentVer >= remoteVer) {
            qCInfo (lcUpdater) << "Client is on latest version!";
            setDownloadState (UpToDate);
        } else {
            setDownloadState (UpdateOnlyAvailableThroughSystem);
        }
    }
    
    } // ns mirall
    