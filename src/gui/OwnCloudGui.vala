/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QPointer>
// #include <QAction>
// #include <QMenu>
// #include <QSize>
// #include <QTimer>
#ifdef WITH_LIBCLOUDPROVIDERS
// #include <QDBusConnection>
#endif

namespace Occ {


class LogBrowser;

enum class ShareDialogStartPage {
    UsersAndGroups,
    PublicLinks,
};

/***********************************************************
@brief The OwnCloudGui class
@ingroup gui
***********************************************************/
class OwnCloudGui : GLib.Object {
public:
    OwnCloudGui (Application *parent = nullptr);

    bool checkAccountExists (bool openSettings);

    static void raiseDialog (Gtk.Widget *raiseWidget);
    static QSize settingsDialogSize () { return {800, 500}; }
    void setupOverlayIcons ();
#ifdef WITH_LIBCLOUDPROVIDERS
    void setupCloudProviders ();
    bool cloudProviderApiAvailable ();
#endif
    void createTray ();

    void hideAndShowTray ();

signals:
    void setupProxy ();
    void serverError (int code, string &message);
    void isShowingSettingsDialog ();

public slots:
    void slotComputeOverallSyncStatus ();
    void slotShowTrayMessage (string &title, string &msg);
    void slotShowOptionalTrayMessage (string &title, string &msg);
    void slotFolderOpenAction (string &alias);
    void slotUpdateProgress (string &folder, ProgressInfo &progress);
    void slotShowGuiMessage (string &title, string &message);
    void slotFoldersChanged ();
    void slotShowSettings ();
    void slotShowSyncProtocol ();
    void slotShutdown ();
    void slotSyncStateChange (Folder *);
    void slotTrayClicked (QSystemTrayIcon.ActivationReason reason);
    void slotToggleLogBrowser ();
    void slotOpenOwnCloud ();
    void slotOpenSettingsDialog ();
    void slotOpenMainDialog ();
    void slotSettingsDialogActivated ();
    void slotHelp ();
    void slotOpenPath (string &path);
    void slotAccountStateChanged ();
    void slotTrayMessageIfServerUnsupported (Account *account);

    /***********************************************************
     * Open a share dialog for a file or folder.
     *
     * sharePath is the full remote path to the item,
     * localPath is the absolute local path to it (so not relative
     * to the folder).
     */
    void slotShowShareDialog (string &sharePath, string &localPath, ShareDialogStartPage startPage);

    void slotRemoveDestroyedShareDialogs ();

    void slotNewAccountWizard ();

private slots:
    void slotLogin ();
    void slotLogout ();

private:
    QPointer<Systray> _tray;
    QPointer<SettingsDialog> _settingsDialog;
    QPointer<LogBrowser> _logBrowser;

#ifdef WITH_LIBCLOUDPROVIDERS
    QDBusConnection _bus;
#endif

    QMap<string, QPointer<ShareDialog>> _shareDialogs;

    QAction *_actionNewAccountWizard;
    QAction *_actionSettings;
    QAction *_actionEstimate;

    QList<QAction> _recentItemsActions;
    Application *_app;
};

} // namespace Occ






/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

#ifdef WITH_LIBCLOUDPROVIDERS
#endif

// #include <QQmlApplicationEngine>
// #include <QDesktopServices>
// #include <QDir>
// #include <QMessageBox>
// #include <QSignalMapper>
#ifdef WITH_LIBCLOUDPROVIDERS
// #include <QtDBus/QDBusConnection>
// #include <QtDBus/QDBusInterface>
#endif

// #include <QQmlEngine>
// #include <QQmlComponent>
// #include <QQmlApplicationEngine>
// #include <QQuickItem>
// #include <QQmlContext>

namespace Occ {

const char propertyAccountC[] = "oc_account";

OwnCloudGui.OwnCloudGui (Application *parent)
    : GLib.Object (parent)
    , _tray (nullptr)
    , _settingsDialog (nullptr)
    , _logBrowser (nullptr)
#ifdef WITH_LIBCLOUDPROVIDERS
    , _bus (QDBusConnection.sessionBus ())
#endif
    , _app (parent) {
    _tray = Systray.instance ();
    _tray.setTrayEngine (new QQmlApplicationEngine (this));
    // for the beginning, set the offline icon until the account was verified
    _tray.setIcon (Theme.instance ().folderOfflineIcon (/*systray?*/ true));

    _tray.show ();

    connect (_tray.data (), &QSystemTrayIcon.activated,
        this, &OwnCloudGui.slotTrayClicked);

    connect (_tray.data (), &Systray.openHelp,
        this, &OwnCloudGui.slotHelp);

    connect (_tray.data (), &Systray.openAccountWizard,
        this, &OwnCloudGui.slotNewAccountWizard);

    connect (_tray.data (), &Systray.openMainDialog,
        this, &OwnCloudGui.slotOpenMainDialog);

    connect (_tray.data (), &Systray.openSettings,
        this, &OwnCloudGui.slotShowSettings);

    connect (_tray.data (), &Systray.shutdown,
        this, &OwnCloudGui.slotShutdown);

    connect (_tray.data (), &Systray.openShareDialog,
        this, [=] (string &sharePath, string &localPath) {
                slotShowShareDialog (sharePath, localPath, ShareDialogStartPage.UsersAndGroups);
            });

    ProgressDispatcher *pd = ProgressDispatcher.instance ();
    connect (pd, &ProgressDispatcher.progressInfo, this,
        &OwnCloudGui.slotUpdateProgress);

    FolderMan *folderMan = FolderMan.instance ();
    connect (folderMan, &FolderMan.folderSyncStateChange,
        this, &OwnCloudGui.slotSyncStateChange);

    connect (Logger.instance (), &Logger.guiLog,
        this, &OwnCloudGui.slotShowTrayMessage);
    connect (Logger.instance (), &Logger.optionalGuiLog,
        this, &OwnCloudGui.slotShowOptionalTrayMessage);
    connect (Logger.instance (), &Logger.guiMessage,
        this, &OwnCloudGui.slotShowGuiMessage);
}

void OwnCloudGui.createTray () {
    _tray.create ();
}

#ifdef WITH_LIBCLOUDPROVIDERS
void OwnCloudGui.setupCloudProviders () {
    new CloudProviderManager (this);
}

bool OwnCloudGui.cloudProviderApiAvailable () {
    if (!_bus.isConnected ()) {
        return false;
    }
    QDBusInterface dbus_iface ("org.freedesktop.CloudProviderManager", "/org/freedesktop/CloudProviderManager",
                              "org.freedesktop.CloudProvider.Manager1", _bus);

    if (!dbus_iface.isValid ()) {
        qCInfo (lcApplication) << "DBus interface unavailable";
        return false;
    }
    return true;
}
#endif

// This should rather be in application.... or rather in ConfigFile?
void OwnCloudGui.slotOpenSettingsDialog () {
    // if account is set up, start the configuration wizard.
    if (!AccountManager.instance ().accounts ().isEmpty ()) {
        if (_settingsDialog.isNull () || QApplication.activeWindow () != _settingsDialog) {
            slotShowSettings ();
        } else {
            _settingsDialog.close ();
        }
    } else {
        qCInfo (lcApplication) << "No configured folders yet, starting setup wizard";
        slotNewAccountWizard ();
    }
}

void OwnCloudGui.slotOpenMainDialog () {
    if (!_tray.isOpen ()) {
        _tray.showWindow ();
    }
}

void OwnCloudGui.slotTrayClicked (QSystemTrayIcon.ActivationReason reason) {
    if (reason == QSystemTrayIcon.Trigger) {
        if (OwncloudSetupWizard.bringWizardToFrontIfVisible ()) {
            // brought wizard to front
        } else if (_shareDialogs.size () > 0) {
            // Share dialog (s) be hidden by other apps, bring them back
            Q_FOREACH (QPointer<ShareDialog> &shareDialog, _shareDialogs) {
                Q_ASSERT (shareDialog.data ());
                raiseDialog (shareDialog);
            }
        } else if (_tray.isOpen ()) {
            _tray.hideWindow ();
        } else {
            if (AccountManager.instance ().accounts ().isEmpty ()) {
                this.slotOpenSettingsDialog ();
            } else {
                _tray.showWindow ();
            }

        }
    }
    // FIXME : Also make sure that any auto updater dialogue https://github.com/owncloud/client/issues/5613
    // or SSL error dialog also comes to front.
}

void OwnCloudGui.slotSyncStateChange (Folder *folder) {
    slotComputeOverallSyncStatus ();

    if (!folder) {
        return; // Valid, just a general GUI redraw was needed.
    }

    auto result = folder.syncResult ();

    qCInfo (lcApplication) << "Sync state changed for folder " << folder.remoteUrl ().toString () << " : " << result.statusString ();

    if (result.status () == SyncResult.Success
        || result.status () == SyncResult.Problem
        || result.status () == SyncResult.SyncAbortRequested
        || result.status () == SyncResult.Error) {
        Logger.instance ().enterNextLogFile ();
    }
}

void OwnCloudGui.slotFoldersChanged () {
    slotComputeOverallSyncStatus ();
}

void OwnCloudGui.slotOpenPath (string &path) {
    showInFileManager (path);
}

void OwnCloudGui.slotAccountStateChanged () {
    slotComputeOverallSyncStatus ();
}

void OwnCloudGui.slotTrayMessageIfServerUnsupported (Account *account) {
    if (account.serverVersionUnsupported ()) {
        slotShowTrayMessage (
            tr ("Unsupported Server Version"),
            tr ("The server on account %1 runs an unsupported version %2. "
               "Using this client with unsupported server versions is untested and "
               "potentially dangerous. Proceed at your own risk.")
                .arg (account.displayName (), account.serverVersion ()));
    }
}

void OwnCloudGui.slotComputeOverallSyncStatus () {
    bool allSignedOut = true;
    bool allPaused = true;
    bool allDisconnected = true;
    QVector<AccountStatePtr> problemAccounts;
    auto setStatusText = [&] (string &text) {
        // FIXME : So this doesn't do anything? Needs to be revisited
        Q_UNUSED (text)
        // Don't overwrite the status if we're currently syncing
        if (FolderMan.instance ().isAnySyncRunning ())
            return;
        //_actionStatus.setText (text);
    };

    foreach (auto a, AccountManager.instance ().accounts ()) {
        if (!a.isSignedOut ()) {
            allSignedOut = false;
        }
        if (!a.isConnected ()) {
            problemAccounts.append (a);
        } else {
            allDisconnected = false;
        }
    }
    foreach (Folder *f, FolderMan.instance ().map ()) {
        if (!f.syncPaused ()) {
            allPaused = false;
        }
    }

    if (!problemAccounts.empty ()) {
        _tray.setIcon (Theme.instance ().folderOfflineIcon (true));
        if (allDisconnected) {
            setStatusText (tr ("Disconnected"));
        } else {
            setStatusText (tr ("Disconnected from some accounts"));
        }
        QStringList messages;
        messages.append (tr ("Disconnected from accounts:"));
        foreach (AccountStatePtr a, problemAccounts) {
            string message = tr ("Account %1 : %2").arg (a.account ().displayName (), a.stateString (a.state ()));
            if (!a.connectionErrors ().empty ()) {
                message += QLatin1String ("\n");
                message += a.connectionErrors ().join (QLatin1String ("\n"));
            }
            messages.append (message);
        }
        _tray.setToolTip (messages.join (QLatin1String ("\n\n")));
#endif
        return;
    }

    if (allSignedOut) {
        _tray.setIcon (Theme.instance ().folderOfflineIcon (true));
        _tray.setToolTip (tr ("Please sign in"));
        setStatusText (tr ("Signed out"));
        return;
    } else if (allPaused) {
        _tray.setIcon (Theme.instance ().syncStateIcon (SyncResult.Paused, true));
        _tray.setToolTip (tr ("Account synchronization is disabled"));
        setStatusText (tr ("Synchronization is paused"));
        return;
    }

    // display the info of the least successful sync (eg. do not just display the result of the latest sync)
    string trayMessage;
    FolderMan *folderMan = FolderMan.instance ();
    Folder.Map map = folderMan.map ();

    SyncResult.Status overallStatus = SyncResult.Undefined;
    bool hasUnresolvedConflicts = false;
    FolderMan.trayOverallStatus (map.values (), &overallStatus, &hasUnresolvedConflicts);

    // If the sync succeeded but there are unresolved conflicts,
    // show the problem icon!
    auto iconStatus = overallStatus;
    if (iconStatus == SyncResult.Success && hasUnresolvedConflicts) {
        iconStatus = SyncResult.Problem;
    }

    // If we don't get a status for whatever reason, that's a Problem
    if (iconStatus == SyncResult.Undefined) {
        iconStatus = SyncResult.Problem;
    }

    QIcon statusIcon = Theme.instance ().syncStateIcon (iconStatus, true);
    _tray.setIcon (statusIcon);

    // create the tray blob message, check if we have an defined state
    if (map.count () > 0) {
        QStringList allStatusStrings;
        foreach (Folder *folder, map.values ()) {
            string folderMessage = FolderMan.trayTooltipStatusString (
                folder.syncResult ().status (),
                folder.syncResult ().hasUnresolvedConflicts (),
                folder.syncPaused ());
            allStatusStrings += tr ("Folder %1 : %2").arg (folder.shortGuiLocalPath (), folderMessage);
        }
        trayMessage = allStatusStrings.join (QLatin1String ("\n"));
#endif
        _tray.setToolTip (trayMessage);

        if (overallStatus == SyncResult.Success || overallStatus == SyncResult.Problem) {
            if (hasUnresolvedConflicts) {
                setStatusText (tr ("Unresolved conflicts"));
            } else {
                setStatusText (tr ("Up to date"));
            }
        } else if (overallStatus == SyncResult.Paused) {
            setStatusText (tr ("Synchronization is paused"));
        } else {
            setStatusText (tr ("Error during synchronization"));
        }
    } else {
        _tray.setToolTip (tr ("There are no sync folders configured."));
        setStatusText (tr ("No sync folders configured"));
    }
}

void OwnCloudGui.hideAndShowTray () {
    _tray.hide ();
    _tray.show ();
}

void OwnCloudGui.slotShowTrayMessage (string &title, string &msg) {
    if (_tray)
        _tray.showMessage (title, msg);
    else
        qCWarning (lcApplication) << "Tray not ready : " << msg;
}

void OwnCloudGui.slotShowOptionalTrayMessage (string &title, string &msg) {
    slotShowTrayMessage (title, msg);
}

/***********************************************************
open the folder with the given Alias
***********************************************************/
void OwnCloudGui.slotFolderOpenAction (string &alias) {
    Folder *f = FolderMan.instance ().folder (alias);
    if (f) {
        qCInfo (lcApplication) << "opening local url " << f.path ();
        QUrl url = QUrl.fromLocalFile (f.path ());
        QDesktopServices.openUrl (url);
    }
}

void OwnCloudGui.slotUpdateProgress (string &folder, ProgressInfo &progress) {
    Q_UNUSED (folder);

    // FIXME : Lots of messages computed for nothing in this method, needs revisiting
    if (progress.status () == ProgressInfo.Discovery) {
#if 0
        if (!progress._currentDiscoveredRemoteFolder.isEmpty ()) {
            _actionStatus.setText (tr ("Checking for changes in remote \"%1\"")
                                       .arg (progress._currentDiscoveredRemoteFolder));
        } else if (!progress._currentDiscoveredLocalFolder.isEmpty ()) {
            _actionStatus.setText (tr ("Checking for changes in local \"%1\"")
                                       .arg (progress._currentDiscoveredLocalFolder));
        }
#endif
    } else if (progress.status () == ProgressInfo.Done) {
        QTimer.singleShot (2000, this, &OwnCloudGui.slotComputeOverallSyncStatus);
    }
    if (progress.status () != ProgressInfo.Propagation) {
        return;
    }

    if (progress.totalSize () == 0) {
        int64 currentFile = progress.currentFile ();
        int64 totalFileCount = qMax (progress.totalFiles (), currentFile);
        string msg;
        if (progress.trustEta ()) {
            msg = tr ("Syncing %1 of %2 (%3 left)")
                      .arg (currentFile)
                      .arg (totalFileCount)
                      .arg (Utility.durationToDescriptiveString2 (progress.totalProgress ().estimatedEta));
        } else {
            msg = tr ("Syncing %1 of %2")
                      .arg (currentFile)
                      .arg (totalFileCount);
        }
        //_actionStatus.setText (msg);
    } else {
        string totalSizeStr = Utility.octetsToString (progress.totalSize ());
        string msg;
        if (progress.trustEta ()) {
            msg = tr ("Syncing %1 (%2 left)")
                      .arg (totalSizeStr, Utility.durationToDescriptiveString2 (progress.totalProgress ().estimatedEta));
        } else {
            msg = tr ("Syncing %1")
                      .arg (totalSizeStr);
        }
        //_actionStatus.setText (msg);
    }

    if (!progress._lastCompletedItem.isEmpty ()) {

        string kindStr = Progress.asResultString (progress._lastCompletedItem);
        string timeStr = QTime.currentTime ().toString ("hh:mm");
        string actionText = tr ("%1 (%2, %3)").arg (progress._lastCompletedItem._file, kindStr, timeStr);
        auto *action = new QAction (actionText, this);
        Folder *f = FolderMan.instance ().folder (folder);
        if (f) {
            string fullPath = f.path () + '/' + progress._lastCompletedItem._file;
            if (QFile (fullPath).exists ()) {
                connect (action, &QAction.triggered, this, [this, fullPath] { this.slotOpenPath (fullPath); });
            } else {
                action.setEnabled (false);
            }
        }
        if (_recentItemsActions.length () > 5) {
            _recentItemsActions.takeFirst ().deleteLater ();
        }
        _recentItemsActions.append (action);
    }
}

void OwnCloudGui.slotLogin () {
    if (auto account = qvariant_cast<AccountStatePtr> (sender ().property (propertyAccountC))) {
        account.account ().resetRejectedCertificates ();
        account.signIn ();
    } else {
        auto list = AccountManager.instance ().accounts ();
        foreach (auto &a, list) {
            a.signIn ();
        }
    }
}

void OwnCloudGui.slotLogout () {
    auto list = AccountManager.instance ().accounts ();
    if (auto account = qvariant_cast<AccountStatePtr> (sender ().property (propertyAccountC))) {
        list.clear ();
        list.append (account);
    }

    foreach (auto &ai, list) {
        ai.signOutByUi ();
    }
}

void OwnCloudGui.slotNewAccountWizard () {
    OwncloudSetupWizard.runWizard (qApp, SLOT (slotownCloudWizardDone (int)));
}

void OwnCloudGui.slotShowGuiMessage (string &title, string &message) {
    auto *msgBox = new QMessageBox;
    msgBox.setWindowFlags (msgBox.windowFlags () | Qt.WindowStaysOnTopHint);
    msgBox.setAttribute (Qt.WA_DeleteOnClose);
    msgBox.setText (message);
    msgBox.setWindowTitle (title);
    msgBox.setIcon (QMessageBox.Information);
    msgBox.open ();
}

void OwnCloudGui.slotShowSettings () {
    if (_settingsDialog.isNull ()) {
        _settingsDialog = new SettingsDialog (this);
        _settingsDialog.setAttribute (Qt.WA_DeleteOnClose, true);
        _settingsDialog.show ();
    }
    raiseDialog (_settingsDialog.data ());
}

void OwnCloudGui.slotSettingsDialogActivated () {
    emit isShowingSettingsDialog ();
}

void OwnCloudGui.slotShowSyncProtocol () {
    slotShowSettings ();
    //_settingsDialog.showActivityPage ();
}

void OwnCloudGui.slotShutdown () {
    // explicitly close windows. This is somewhat of a hack to ensure
    // that saving the geometries happens ASAP during a OS shutdown

    // those do delete on close
    if (!_settingsDialog.isNull ())
        _settingsDialog.close ();
    if (!_logBrowser.isNull ())
        _logBrowser.deleteLater ();
    _app.quit ();
}

void OwnCloudGui.slotToggleLogBrowser () {
    if (_logBrowser.isNull ()) {
        // init the log browser.
        _logBrowser = new LogBrowser;
        // ## TODO : allow new log name maybe?
    }

    if (_logBrowser.isVisible ()) {
        _logBrowser.hide ();
    } else {
        raiseDialog (_logBrowser);
    }
}

void OwnCloudGui.slotOpenOwnCloud () {
    if (auto account = qvariant_cast<AccountPtr> (sender ().property (propertyAccountC))) {
        Utility.openBrowser (account.url ());
    }
}

void OwnCloudGui.slotHelp () {
    QDesktopServices.openUrl (QUrl (Theme.instance ().helpUrl ()));
}

void OwnCloudGui.raiseDialog (Gtk.Widget *raiseWidget) {
    if (raiseWidget && !raiseWidget.parentWidget ()) {
        // Qt has a bug which causes parent-less dialogs to pop-under.
        raiseWidget.showNormal ();
        raiseWidget.raise ();
        raiseWidget.activateWindow ();
    }
}

void OwnCloudGui.slotShowShareDialog (string &sharePath, string &localPath, ShareDialogStartPage startPage) {
    const auto folder = FolderMan.instance ().folderForPath (localPath);
    if (!folder) {
        qCWarning (lcApplication) << "Could not open share dialog for" << localPath << "no responsible folder found";
        return;
    }

    const auto accountState = folder.accountState ();

    const string file = localPath.mid (folder.cleanPath ().length () + 1);
    SyncJournalFileRecord fileRecord;

    bool resharingAllowed = true; // lets assume the good
    if (folder.journalDb ().getFileRecord (file, &fileRecord) && fileRecord.isValid ()) {
        // check the permission : Is resharing allowed?
        if (!fileRecord._remotePerm.isNull () && !fileRecord._remotePerm.hasPermission (RemotePermissions.CanReshare)) {
            resharingAllowed = false;
        }
    }

    auto maxSharingPermissions = resharingAllowed? SharePermissions (accountState.account ().capabilities ().shareDefaultPermissions ()) : SharePermissions ({});

    ShareDialog *w = nullptr;
    if (_shareDialogs.contains (localPath) && _shareDialogs[localPath]) {
        qCInfo (lcApplication) << "Raising share dialog" << sharePath << localPath;
        w = _shareDialogs[localPath];
    } else {
        qCInfo (lcApplication) << "Opening share dialog" << sharePath << localPath << maxSharingPermissions;
        w = new ShareDialog (accountState, sharePath, localPath, maxSharingPermissions, fileRecord.numericFileId (), startPage);
        w.setAttribute (Qt.WA_DeleteOnClose, true);

        _shareDialogs[localPath] = w;
        connect (w, &GLib.Object.destroyed, this, &OwnCloudGui.slotRemoveDestroyedShareDialogs);
    }
    raiseDialog (w);
}

void OwnCloudGui.slotRemoveDestroyedShareDialogs () {
    QMutableMapIterator<string, QPointer<ShareDialog>> it (_shareDialogs);
    while (it.hasNext ()) {
        it.next ();
        if (!it.value () || it.value () == sender ()) {
            it.remove ();
        }
    }
}

} // end namespace
