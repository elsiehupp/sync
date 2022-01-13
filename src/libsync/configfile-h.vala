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

// #include <memory>
// #include <QSharedPointer>
// #include <QSettings>
// #include <QString>
// #include <QVariant>
// #include <chrono>

class QHeaderView;

namespace Occ {


/**
@brief The ConfigFile class
@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT ConfigFile {
public:
    ConfigFile ();

    enum Scope { UserScope,
        SystemScope };

    QString configPath ();
    QString configFile ();
    QString excludeFile (Scope scope) const;
    static QString excludeFileFromSystem (); // doesn't access config dir

    /**
     * Creates a backup of the file
     *
     * Returns the path of the new backup.
     */
    QString backup ();

    bool exists ();

    QString defaultConnection ();

    // the certs do not depend on a connection.
    QByteArray caCerts ();
    void setCaCerts (QByteArray &);

    bool passwordStorageAllowed (QString &connection = QString ());

    /* Server poll interval in milliseconds */
    std.chrono.milliseconds remotePollInterval (QString &connection = QString ()) const;
    /* Set poll interval. Value in milliseconds has to be larger than 5000 */
    void setRemotePollInterval (std.chrono.milliseconds interval, QString &connection = QString ());

    /* Interval to check for new notifications */
    std.chrono.milliseconds notificationRefreshInterval (QString &connection = QString ()) const;

    /* Force sync interval, in milliseconds */
    std.chrono.milliseconds forceSyncInterval (QString &connection = QString ()) const;

    /**
     * Interval in milliseconds within which full local discovery is required
     *
     * Use -1 to disable regular full local discoveries.
     */
    std.chrono.milliseconds fullLocalDiscoveryInterval ();

    bool monoIcons ();
    void setMonoIcons (bool);

    bool promptDeleteFiles ();
    void setPromptDeleteFiles (bool promptDeleteFiles);

    bool crashReporter ();
    void setCrashReporter (bool enabled);

    bool automaticLogDir ();
    void setAutomaticLogDir (bool enabled);

    QString logDir ();
    void setLogDir (QString &dir);

    bool logDebug ();
    void setLogDebug (bool enabled);

    int logExpire ();
    void setLogExpire (int hours);

    bool logFlush ();
    void setLogFlush (bool enabled);

    // Whether experimental UI options should be shown
    bool showExperimentalOptions ();

    // proxy settings
    void setProxyType (int proxyType,
        const QString &host = QString (),
        int port = 0, bool needsAuth = false,
        const QString &user = QString (),
        const QString &pass = QString ());

    int proxyType ();
    QString proxyHostName ();
    int proxyPort ();
    bool proxyNeedsAuth ();
    QString proxyUser ();
    QString proxyPassword ();

    /** 0 : no limit, 1 : manual, >0 : automatic */
    int useUploadLimit ();
    int useDownloadLimit ();
    void setUseUploadLimit (int);
    void setUseDownloadLimit (int);
    /** in kbyte/s */
    int uploadLimit ();
    int downloadLimit ();
    void setUploadLimit (int kbytes);
    void setDownloadLimit (int kbytes);
    /** [checked, size in MB] **/
    QPair<bool, int64> newBigFolderSizeLimit ();
    void setNewBigFolderSizeLimit (bool isChecked, int64 mbytes);
    bool useNewBigFolderSizeLimit ();
    bool confirmExternalStorage ();
    void setConfirmExternalStorage (bool);

    /** If we should move the files deleted on the server in the trash  */
    bool moveToTrash ();
    void setMoveToTrash (bool);

    bool showMainDialogAsNormalWindow ();

    static bool setConfDir (QString &value);

    bool optionalServerNotifications ();
    void setOptionalServerNotifications (bool show);

    bool showInExplorerNavigationPane ();
    void setShowInExplorerNavigationPane (bool show);

    int timeout ();
    int64 chunkSize ();
    int64 maxChunkSize ();
    int64 minChunkSize ();
    std.chrono.milliseconds targetChunkUploadDuration ();

    void saveGeometry (QWidget *w);
    void restoreGeometry (QWidget *w);

    // how often the check about new versions runs
    std.chrono.milliseconds updateCheckInterval (QString &connection = QString ()) const;

    // skipUpdateCheck completely disables the updater and hides its UI
    bool skipUpdateCheck (QString &connection = QString ()) const;
    void setSkipUpdateCheck (bool, QString &);

    // autoUpdateCheck allows the user to make the choice in the UI
    bool autoUpdateCheck (QString &connection = QString ()) const;
    void setAutoUpdateCheck (bool, QString &);

    /** Query-parameter 'updatesegment' for the update check, value between 0 and 99.
        Used to throttle down desktop release rollout in order to keep the update servers alive at peak times.
        See : https://github.com/nextcloud/client_updater_server/pull/36 */
    int updateSegment ();

    QString updateChannel ();
    void setUpdateChannel (QString &channel);

    void saveGeometryHeader (QHeaderView *header);
    void restoreGeometryHeader (QHeaderView *header);

    QString certificatePath ();
    void setCertificatePath (QString &cPath);
    QString certificatePasswd ();
    void setCertificatePasswd (QString &cPasswd);

    /** The client version that last used this settings file.
        Updated by configVersionMigration () at client startup. */
    QString clientVersionString ();
    void setClientVersionString (QString &version);

    /**  Returns a new settings pre-set in a specific group.  The Settings will be created
         with the given parent. If no parent is specified, the caller must destroy the settings */
    static std.unique_ptr<QSettings> settingsWithGroup (QString &group, GLib.Object *parent = nullptr);

    /// Add the system and user exclude file path to the ExcludedFiles instance.
    static void setupDefaultExcludeFilePaths (ExcludedFiles &excludedFiles);

protected:
    QVariant getPolicySetting (QString &policy, QVariant &defaultValue = QVariant ()) const;
    void storeData (QString &group, QString &key, QVariant &value);
    QVariant retrieveData (QString &group, QString &key) const;
    void removeData (QString &group, QString &key);
    bool dataExists (QString &group, QString &key) const;

private:
    QVariant getValue (QString &param, QString &group = QString (),
        const QVariant &defaultValue = QVariant ()) const;
    void setValue (QString &key, QVariant &value);

    QString keychainProxyPasswordKey ();

private:
    using SharedCreds = QSharedPointer<AbstractCredentials>;

    static bool _askedUser;
    static QString _oCVersion;
    static QString _confDir;
};
}