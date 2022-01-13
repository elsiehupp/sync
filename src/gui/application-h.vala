/*
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QApplication>
// #include <QPointer>
// #include <QQueue>
// #include <QTimer>
// #include <QElapsedTimer>
// #include <QNetworkConfigurationManager>

class QSystemTrayIcon;

namespace CrashReporter {
}

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcApplication)

class Folder;

/**
@brief The Application class
@ingroup gui
*/
class Application : SharedTools.QtSingleApplication {
public:
    Application (int &argc, char **argv);
    ~Application () override;

    bool giveHelp ();
    void showHelp ();
    void showHint (std.string errorHint);
    bool debugMode ();
    bool backgroundMode ();
    bool versionOnly (); // only display the version?
    void showVersion ();

    void showMainDialog ();

    ownCloudGui *gui ();

public slots:
    // TODO : this should not be public
    void slotownCloudWizardDone (int);
    void slotCrash ();
    /**
     * Will download a virtual file, and open the result.
     * The argument is the filename of the virtual file (including the extension)
     */
    void openVirtualFile (QString &filename);

    /// Attempt to show () the tray icon again. Used if no systray was available initially.
    void tryTrayAgain ();

protected:
    void parseOptions (QStringList &);
    void setupTranslations ();
    void setupLogging ();
    bool event (QEvent *event) override;

signals:
    void folderRemoved ();
    void folderStateChanged (Folder *);
    void isShowingSettingsDialog ();

protected slots:
    void slotParseMessage (QString &, GLib.Object *);
    void slotCheckConnection ();
    void slotUseMonoIconsChanged (bool);
    void slotCleanup ();
    void slotAccountStateAdded (AccountState *accountState);
    void slotAccountStateRemoved (AccountState *accountState);
    void slotSystemOnlineConfigurationChanged (QNetworkConfiguration);
    void slotGuiIsShowingSettings ();

private:
    void setHelp ();

    /**
     * Maybe a newer version of the client was used with this config file:
     * if so, backup, confirm with user and remove the config that can't be read.
     */
    bool configVersionMigration ();

    QPointer<ownCloudGui> _gui;

    Theme *_theme;

    bool _helpOnly;
    bool _versionOnly;

    QElapsedTimer _startedAt;

    // options from command line:
    bool _showLogWindow;
    bool _quitInstance = false;
    QString _logFile;
    QString _logDir;
    int _logExpire;
    bool _logFlush;
    bool _logDebug;
    bool _userTriggeredConnect;
    bool _debugMode;
    bool _backgroundMode;

    ClientProxy _proxy;

    QNetworkConfigurationManager _networkConfigurationManager;
    QTimer _checkConnectionTimer;

#if defined (WITH_CRASHREPORTER)
    QScopedPointer<CrashReporter.Handler> _crashHandler;
#endif
    QScopedPointer<FolderMan> _folderManager;
};

} // namespace Occ
