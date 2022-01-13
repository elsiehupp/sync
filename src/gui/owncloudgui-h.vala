/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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


class ShareDialog;
class LogBrowser;

enum class ShareDialogStartPage {
    UsersAndGroups,
    PublicLinks,
};

/**
@brief The ownCloudGui class
@ingroup gui
*/
class ownCloudGui : GLib.Object {
public:
    ownCloudGui (Application *parent = nullptr);

    bool checkAccountExists (bool openSettings);

    static void raiseDialog (QWidget *raiseWidget);
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
    void serverError (int code, QString &message);
    void isShowingSettingsDialog ();

public slots:
    void slotComputeOverallSyncStatus ();
    void slotShowTrayMessage (QString &title, QString &msg);
    void slotShowOptionalTrayMessage (QString &title, QString &msg);
    void slotFolderOpenAction (QString &alias);
    void slotUpdateProgress (QString &folder, ProgressInfo &progress);
    void slotShowGuiMessage (QString &title, QString &message);
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
    void slotOpenPath (QString &path);
    void slotAccountStateChanged ();
    void slotTrayMessageIfServerUnsupported (Account *account);

    /**
     * Open a share dialog for a file or folder.
     *
     * sharePath is the full remote path to the item,
     * localPath is the absolute local path to it (so not relative
     * to the folder).
     */
    void slotShowShareDialog (QString &sharePath, QString &localPath, ShareDialogStartPage startPage);

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

    QMap<QString, QPointer<ShareDialog>> _shareDialogs;

    QAction *_actionNewAccountWizard;
    QAction *_actionSettings;
    QAction *_actionEstimate;

    QList<QAction> _recentItemsActions;
    Application *_app;
};

} // namespace Occ
