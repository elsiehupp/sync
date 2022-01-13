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
// #include <QUrl>
// #include <QTemporaryFile>
// #include <QTimer>

class QNetworkReply;

namespace Occ {

/**
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
*/

class UpdaterScheduler : GLib.Object {
public:
    UpdaterScheduler (GLib.Object *parent);

signals:
    void updaterAnnouncement (QString &title, QString &msg);
    void requestRestart ();

private slots:
    void slotTimerFired ();

private:
    QTimer _updateCheckTimer; /** Timer for the regular update check. */
};

/**
@brief Class that uses an ownCloud proprietary XML format to fetch update information
@ingroup gui
*/
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

    QString statusString (UpdateStatusStringFormat format = PlainText) const;
    int downloadState ();
    void setDownloadState (DownloadState state);

signals:
    void downloadStateChanged ();
    void newUpdateAvailable (QString &header, QString &message);
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

/**
@brief Windows Updater Using NSIS
@ingroup gui
*/
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
    void showUpdateErrorDialog (QString &targetVersion);
    void versionInfoArrived (UpdateInfo &info) override;
    QScopedPointer<QTemporaryFile> _file;
    QString _targetFile;
};

/**
 @brief Updater that only implements notification for use in settings

 The implementation does not show popups

 @ingroup gui
*/
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

#endif // OC_UPDATER
