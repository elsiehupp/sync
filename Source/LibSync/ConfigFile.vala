/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

#ifndef TOKEN_AUTH_ONLY
// #include <Gtk.Widget>
// #include <QHeaderView>
#endif

// #include <QCoreApplication>
// #include <QDir>
// #include <QFile>
// #include <QFileInfo>
// #include <QLoggingCategory>
// #include <QSettings>
// #include <QNetworkProxy>
// #include <QStandardPaths>

const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

#if ! (QTLEGACY)
// #include <QOperatingSystemVersion>
#endif

const int DEFAULT_REMOTE_POLL_INTERVAL 30000 // default remote poll time in milliseconds
const int DEFAULT_MAX_LOG_LINES 20000


namespace chrono = std.chrono;


//static const char caCertsKeyC[] = "CaCertificates"; only used from account.cpp
static const char remotePollIntervalC[] = "remotePollInterval";
static const char forceSyncIntervalC[] = "forceSyncInterval";
static const char fullLocalDiscoveryIntervalC[] = "fullLocalDiscoveryInterval";
static const char notificationRefreshIntervalC[] = "notificationRefreshInterval";
static const char monoIconsC[] = "monoIcons";
static const char promptDeleteC[] = "promptDeleteAllFiles";
static const char crashReporterC[] = "crashReporter";
static const char optionalServerNotificationsC[] = "optionalServerNotifications";
static const char showInExplorerNavigationPaneC[] = "showInExplorerNavigationPane";
static const char skipUpdateCheckC[] = "skipUpdateCheck";
static const char autoUpdateCheckC[] = "autoUpdateCheck";
static const char updateCheckIntervalC[] = "updateCheckInterval";
static const char updateSegmentC[] = "updateSegment";
static const char updateChannelC[] = "updateChannel";
static const char geometryC[] = "geometry";
static const char timeoutC[] = "timeout";
static const char chunkSizeC[] = "chunkSize";
static const char minChunkSizeC[] = "minChunkSize";
static const char maxChunkSizeC[] = "maxChunkSize";
static const char targetChunkUploadDurationC[] = "targetChunkUploadDuration";
static const char automaticLogDirC[] = "logToTemporaryLogDir";
static const char logDirC[] = "logDir";
static const char logDebugC[] = "logDebug";
static const char logExpireC[] = "logExpire";
static const char logFlushC[] = "logFlush";
static const char showExperimentalOptionsC[] = "showExperimentalOptions";
static const char clientVersionC[] = "clientVersion";

static const char proxyHostC[] = "Proxy/host";
static const char proxyTypeC[] = "Proxy/type";
static const char proxyPortC[] = "Proxy/port";
static const char proxyUserC[] = "Proxy/user";
static const char proxyPassC[] = "Proxy/pass";
static const char proxyNeedsAuthC[] = "Proxy/needsAuth";

static const char useUploadLimitC[] = "BWLimit/useUploadLimit";
static const char useDownloadLimitC[] = "BWLimit/useDownloadLimit";
static const char uploadLimitC[] = "BWLimit/uploadLimit";
static const char downloadLimitC[] = "BWLimit/downloadLimit";

static const char newBigFolderSizeLimitC[] = "newBigFolderSizeLimit";
static const char useNewBigFolderSizeLimitC[] = "useNewBigFolderSizeLimit";
static const char confirmExternalStorageC[] = "confirmExternalStorage";
static const char moveToTrashC[] = "moveToTrash";

const char certPath[] = "http_certificatePath";
const char certPasswd[] = "http_certificatePasswd";
string ConfigFile._confDir = string ();
bool ConfigFile._askedUser = false;

namespace {
static constexpr char showMainDialogAsNormalWindowC[] = "showMainDialogAsNormalWindow";
}

// #include <memory>
// #include <QSharedPointer>
// #include <QSettings>
// #include <string>
// #include <QVariant>
// #include <chrono>


namespace Occ {


/***********************************************************
@brief The ConfigFile class
@ingroup libsync
***********************************************************/
class ConfigFile {
public:
    ConfigFile ();

    enum Scope { UserScope,
        SystemScope };

    string configPath ();
    string configFile ();
    string excludeFile (Scope scope) const;
    static string excludeFileFromSystem (); // doesn't access config dir

    /***********************************************************
    Creates a backup of the file
    
     * Returns the path of the new backup.
    ***********************************************************/
    string backup ();

    bool exists ();

    string defaultConnection ();

    // the certs do not depend on a connection.
    QByteArray caCerts ();
    void setCaCerts (QByteArray &);

    bool passwordStorageAllowed (string &connection = string ());

    /* Server poll interval in milliseconds */
    std.chrono.milliseconds remotePollInterval (string &connection = string ()) const;
    /* Set poll interval. Value in milliseconds has to be larger than 5000 */
    void setRemotePollInterval (std.chrono.milliseconds interval, string &connection = string ());

    /* Interval to check for new notifications */
    std.chrono.milliseconds notificationRefreshInterval (string &connection = string ()) const;

    /* Force sync interval, in milliseconds */
    std.chrono.milliseconds forceSyncInterval (string &connection = string ()) const;

    /***********************************************************
    Interval in milliseconds within which full local discovery is required
    
     * Use -1 to disable regular full local discoveries.
    ***********************************************************/
    std.chrono.milliseconds fullLocalDiscoveryInterval ();

    bool monoIcons ();
    void setMonoIcons (bool);

    bool promptDeleteFiles ();
    void setPromptDeleteFiles (bool promptDeleteFiles);

    bool crashReporter ();
    void setCrashReporter (bool enabled);

    bool automaticLogDir ();
    void setAutomaticLogDir (bool enabled);

    string logDir ();
    void setLogDir (string &dir);

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
        const string &host = string (),
        int port = 0, bool needsAuth = false,
        const string &user = string (),
        const string &pass = string ());

    int proxyType ();
    string proxyHostName ();
    int proxyPort ();
    bool proxyNeedsAuth ();
    string proxyUser ();
    string proxyPassword ();

    /***********************************************************
    0 : no limit, 1 : manual, >0 : automatic */
    int useUploadLimit ();
    int useDownloadLimit ();
    void setUseUploadLimit (int);
    void setUseDownloadLimit (int);
    /***********************************************************
    in kbyte/s */
    int uploadLimit ();
    int downloadLimit ();
    void setUploadLimit (int kbytes);
    void setDownloadLimit (int kbytes);
    /***********************************************************
    [checked, size in MB] **/
    QPair<bool, int64> newBigFolderSizeLimit ();
    void setNewBigFolderSizeLimit (bool isChecked, int64 mbytes);
    bool useNewBigFolderSizeLimit ();
    bool confirmExternalStorage ();
    void setConfirmExternalStorage (bool);

    /***********************************************************
    If we should move the files deleted on the server in the trash  */
    bool moveToTrash ();
    void setMoveToTrash (bool);

    bool showMainDialogAsNormalWindow ();

    static bool setConfDir (string &value);

    bool optionalServerNotifications ();
    void setOptionalServerNotifications (bool show);

    bool showInExplorerNavigationPane ();
    void setShowInExplorerNavigationPane (bool show);

    int timeout ();
    int64 chunkSize ();
    int64 maxChunkSize ();
    int64 minChunkSize ();
    std.chrono.milliseconds targetChunkUploadDuration ();

    void saveGeometry (Gtk.Widget *w);
    void restoreGeometry (Gtk.Widget *w);

    // how often the check about new versions runs
    std.chrono.milliseconds updateCheckInterval (string &connection = string ()) const;

    // skipUpdateCheck completely disables the updater and hides its UI
    bool skipUpdateCheck (string &connection = string ()) const;
    void setSkipUpdateCheck (bool, string &);

    // autoUpdateCheck allows the user to make the choice in the UI
    bool autoUpdateCheck (string &connection = string ()) const;
    void setAutoUpdateCheck (bool, string &);

    /***********************************************************
    Query-parameter 'updatesegment' for the update check, value between 0 and 99.
        Used to throttle down desktop release rollout in order to keep the update servers alive at peak times.
        See : https://github.com/nextcloud/client_updater_server/pull/36 */
    int updateSegment ();

    string updateChannel ();
    void setUpdateChannel (string &channel);

    void saveGeometryHeader (QHeaderView *header);
    void restoreGeometryHeader (QHeaderView *header);

    string certificatePath ();
    void setCertificatePath (string &cPath);
    string certificatePasswd ();
    void setCertificatePasswd (string &cPasswd);

    /***********************************************************
    The client version that last used this settings file.
        Updated by configVersionMigration () at client startup. */
    string clientVersionString ();
    void setClientVersionString (string &version);

    /***********************************************************
     Returns a new settings pre-set in a specific group.  The Settings will be created
         with the given parent. If no parent is specified, the caller must destroy the settings */
    static std.unique_ptr<QSettings> settingsWithGroup (string &group, GLib.Object *parent = nullptr);

    /// Add the system and user exclude file path to the ExcludedFiles instance.
    static void setupDefaultExcludeFilePaths (ExcludedFiles &excludedFiles);

protected:
    QVariant getPolicySetting (string &policy, QVariant &defaultValue = QVariant ()) const;
    void storeData (string &group, string &key, QVariant &value);
    QVariant retrieveData (string &group, string &key) const;
    void removeData (string &group, string &key);
    bool dataExists (string &group, string &key) const;

private:
    QVariant getValue (string &param, string &group = string (),
        const QVariant &defaultValue = QVariant ()) const;
    void setValue (string &key, QVariant &value);

    string keychainProxyPasswordKey ();

private:
    using SharedCreds = QSharedPointer<AbstractCredentials>;

    static bool _askedUser;
    static string _oCVersion;
    static string _confDir;
};

static chrono.milliseconds millisecondsValue (QSettings &setting, char *key,
    chrono.milliseconds defaultValue) {
    return chrono.milliseconds (setting.value (QLatin1String (key), qlonglong (defaultValue.count ())).toLongLong ());
}

bool copy_dir_recursive (string from_dir, string to_dir) {
    QDir dir;
    dir.setPath (from_dir);

    from_dir += QDir.separator ();
    to_dir += QDir.separator ();

    foreach (string copy_file, dir.entryList (QDir.Files)) {
        string from = from_dir + copy_file;
        string to = to_dir + copy_file;

        if (QFile.copy (from, to) == false) {
            return false;
        }
    }

    foreach (string copy_dir, dir.entryList (QDir.Dirs | QDir.NoDotAndDotDot)) {
        string from = from_dir + copy_dir;
        string to = to_dir + copy_dir;

        if (dir.mkpath (to) == false) {
            return false;
        }

        if (copy_dir_recursive (from, to) == false) {
            return false;
        }
    }

    return true;
}

ConfigFile.ConfigFile () {
    // QDesktopServices uses the application name to create a config path
    qApp.setApplicationName (Theme.instance ().appNameGUI ());

    QSettings.setDefaultFormat (QSettings.IniFormat);

    const string config = configFile ();

    QSettings settings (config, QSettings.IniFormat);
    settings.beginGroup (defaultConnection ());
}

bool ConfigFile.setConfDir (string &value) {
    string dirPath = value;
    if (dirPath.isEmpty ())
        return false;

    QFileInfo fi (dirPath);
    if (!fi.exists ()) {
        QDir ().mkpath (dirPath);
        fi.setFile (dirPath);
    }
    if (fi.exists () && fi.isDir ()) {
        dirPath = fi.absoluteFilePath ();
        qCInfo (lcConfigFile) << "Using custom config dir " << dirPath;
        _confDir = dirPath;
        return true;
    }
    return false;
}

bool ConfigFile.optionalServerNotifications () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (optionalServerNotificationsC), true).toBool ();
}

bool ConfigFile.showInExplorerNavigationPane () {
    const bool defaultValue = false;
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (showInExplorerNavigationPaneC), defaultValue).toBool ();
}

void ConfigFile.setShowInExplorerNavigationPane (bool show) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (showInExplorerNavigationPaneC), show);
    settings.sync ();
}

int ConfigFile.timeout () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (timeoutC), 300).toInt (); // default to 5 min
}

int64 ConfigFile.chunkSize () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (chunkSizeC), 10 * 1000 * 1000).toLongLong (); // default to 10 MB
}

int64 ConfigFile.maxChunkSize () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (maxChunkSizeC), 1000 * 1000 * 1000).toLongLong (); // default to 1000 MB
}

int64 ConfigFile.minChunkSize () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (minChunkSizeC), 1000 * 1000).toLongLong (); // default to 1 MB
}

chrono.milliseconds ConfigFile.targetChunkUploadDuration () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return millisecondsValue (settings, targetChunkUploadDurationC, chrono.minutes (1));
}

void ConfigFile.setOptionalServerNotifications (bool show) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (optionalServerNotificationsC), show);
    settings.sync ();
}

void ConfigFile.saveGeometry (Gtk.Widget *w) {
#ifndef TOKEN_AUTH_ONLY
    ASSERT (!w.objectName ().isNull ());
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (w.objectName ());
    settings.setValue (QLatin1String (geometryC), w.saveGeometry ());
    settings.sync ();
#endif
}

void ConfigFile.restoreGeometry (Gtk.Widget *w) {
#ifndef TOKEN_AUTH_ONLY
    w.restoreGeometry (getValue (geometryC, w.objectName ()).toByteArray ());
#endif
}

void ConfigFile.saveGeometryHeader (QHeaderView *header) {
#ifndef TOKEN_AUTH_ONLY
    if (!header)
        return;
    ASSERT (!header.objectName ().isEmpty ());

    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (header.objectName ());
    settings.setValue (QLatin1String (geometryC), header.saveState ());
    settings.sync ();
#endif
}

void ConfigFile.restoreGeometryHeader (QHeaderView *header) {
#ifndef TOKEN_AUTH_ONLY
    if (!header)
        return;
    ASSERT (!header.objectName ().isNull ());

    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (header.objectName ());
    header.restoreState (settings.value (geometryC).toByteArray ());
#endif
}

QVariant ConfigFile.getPolicySetting (string &setting, QVariant &defaultValue) {
    if (Utility.isWindows ()) {
        // check for policies first and return immediately if a value is found.
        QSettings userPolicy (string.fromLatin1 (R" (HKEY_CURRENT_USER\Software\Policies\%1\%2)")
                                 .arg (APPLICATION_VENDOR, Theme.instance ().appNameGUI ()),
            QSettings.NativeFormat);
        if (userPolicy.contains (setting)) {
            return userPolicy.value (setting);
        }

        QSettings machinePolicy (string.fromLatin1 (R" (HKEY_LOCAL_MACHINE\Software\Policies\%1\%2)")
                                    .arg (APPLICATION_VENDOR, Theme.instance ().appNameGUI ()),
            QSettings.NativeFormat);
        if (machinePolicy.contains (setting)) {
            return machinePolicy.value (setting);
        }
    }
    return defaultValue;
}

string ConfigFile.configPath () {
    if (_confDir.isEmpty ()) {
        if (!Utility.isWindows ()) {
            // On Unix, use the AppConfigLocation for the settings, that's configurable with the XDG_CONFIG_HOME env variable.
            _confDir = QStandardPaths.writableLocation (QStandardPaths.AppConfigLocation);
        } else {
            // On Windows, use AppDataLocation, that's where the roaming data is and where we should store the config file
             auto newLocation = QStandardPaths.writableLocation (QStandardPaths.AppDataLocation);

             // Check if this is the first time loading the new location
             if (!QFileInfo (newLocation).isDir ()) {
                 // Migrate data to the new locations
                 auto oldLocation = QStandardPaths.writableLocation (QStandardPaths.AppConfigLocation);

                 // Only migrate if the old location exists.
                 if (QFileInfo (oldLocation).isDir ()) {
                     QDir ().mkpath (newLocation);
                     copy_dir_recursive (oldLocation, newLocation);
                 }
             }
            _confDir = newLocation;
        }
    }
    string dir = _confDir;

    if (!dir.endsWith (QLatin1Char ('/')))
        dir.append (QLatin1Char ('/'));
    return dir;
}

static const QLatin1String exclFile ("sync-exclude.lst");

string ConfigFile.excludeFile (Scope scope) {
    // prefer sync-exclude.lst, but if it does not exist, check for
    // exclude.lst for compatibility reasons in the user writeable
    // directories.
    QFileInfo fi;

    switch (scope) {
    case UserScope:
        fi.setFile (configPath (), exclFile);

        if (!fi.isReadable ()) {
            fi.setFile (configPath (), QLatin1String ("exclude.lst"));
        }
        if (!fi.isReadable ()) {
            fi.setFile (configPath (), exclFile);
        }
        return fi.absoluteFilePath ();
    case SystemScope:
        return ConfigFile.excludeFileFromSystem ();
    }

    ASSERT (false);
    return string ();
}

string ConfigFile.excludeFileFromSystem () {
    QFileInfo fi;
    fi.setFile (string (SYSCONFDIR "/" + Theme.instance ().appName ()), exclFile);
    if (!fi.exists ()) {
        // Prefer to return the preferred path! Only use the fallback location
        // if the other path does not exist and the fallback is valid.
        QFileInfo nextToBinary (QCoreApplication.applicationDirPath (), exclFile);
        if (nextToBinary.exists ()) {
            fi = nextToBinary;
        } else {
            // For AppImage, the file might reside under a temporary mount path
            QDir d (QCoreApplication.applicationDirPath ()); // supposed to be /tmp/mount.xyz/usr/bin
            d.cdUp (); // go out of bin
            d.cdUp (); // go out of usr
            if (!d.isRoot ()) { // it is really a mountpoint
                if (d.cd ("etc") && d.cd (Theme.instance ().appName ())) {
                    QFileInfo inMountDir (d, exclFile);
                    if (inMountDir.exists ()) {
                        fi = inMountDir;
                    }
                };
            }
        }
    }

    return fi.absoluteFilePath ();
}

string ConfigFile.backup () {
    string baseFile = configFile ();
    auto versionString = clientVersionString ();
    if (!versionString.isEmpty ())
        versionString.prepend ('_');
    string backupFile =
        string ("%1.backup_%2%3")
            .arg (baseFile)
            .arg (QDateTime.currentDateTime ().toString ("yyyyMMdd_HHmmss"))
            .arg (versionString);

    // If this exact file already exists it's most likely that a backup was
    // already done. (two backup calls directly after each other, potentially
    // even with source alterations in between!)
    if (!QFile.exists (backupFile)) {
        QFile f (baseFile);
        f.copy (backupFile);
    }
    return backupFile;
}

string ConfigFile.configFile () {
    return configPath () + Theme.instance ().configFileName ();
}

bool ConfigFile.exists () {
    QFile file (configFile ());
    return file.exists ();
}

string ConfigFile.defaultConnection () {
    return Theme.instance ().appName ();
}

void ConfigFile.storeData (string &group, string &key, QVariant &value) {
    const string con (group.isEmpty () ? defaultConnection () : group);
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.beginGroup (con);
    settings.setValue (key, value);
    settings.sync ();
}

QVariant ConfigFile.retrieveData (string &group, string &key) {
    const string con (group.isEmpty () ? defaultConnection () : group);
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.beginGroup (con);
    return settings.value (key);
}

void ConfigFile.removeData (string &group, string &key) {
    const string con (group.isEmpty () ? defaultConnection () : group);
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.beginGroup (con);
    settings.remove (key);
}

bool ConfigFile.dataExists (string &group, string &key) {
    const string con (group.isEmpty () ? defaultConnection () : group);
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.beginGroup (con);
    return settings.contains (key);
}

chrono.milliseconds ConfigFile.remotePollInterval (string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    auto defaultPollInterval = chrono.milliseconds (DEFAULT_REMOTE_POLL_INTERVAL);
    auto remoteInterval = millisecondsValue (settings, remotePollIntervalC, defaultPollInterval);
    if (remoteInterval < chrono.seconds (5)) {
        qCWarning (lcConfigFile) << "Remote Interval is less than 5 seconds, reverting to" << DEFAULT_REMOTE_POLL_INTERVAL;
        remoteInterval = defaultPollInterval;
    }
    return remoteInterval;
}

void ConfigFile.setRemotePollInterval (chrono.milliseconds interval, string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    if (interval < chrono.seconds (5)) {
        qCWarning (lcConfigFile) << "Remote Poll interval of " << interval.count () << " is below five seconds.";
        return;
    }
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);
    settings.setValue (QLatin1String (remotePollIntervalC), qlonglong (interval.count ()));
    settings.sync ();
}

chrono.milliseconds ConfigFile.forceSyncInterval (string &connection) {
    auto pollInterval = remotePollInterval (connection);

    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    auto defaultInterval = chrono.hours (2);
    auto interval = millisecondsValue (settings, forceSyncIntervalC, defaultInterval);
    if (interval < pollInterval) {
        qCWarning (lcConfigFile) << "Force sync interval is less than the remote poll inteval, reverting to" << pollInterval.count ();
        interval = pollInterval;
    }
    return interval;
}

chrono.milliseconds Occ.ConfigFile.fullLocalDiscoveryInterval () {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (defaultConnection ());
    return millisecondsValue (settings, fullLocalDiscoveryIntervalC, chrono.hours (1));
}

chrono.milliseconds ConfigFile.notificationRefreshInterval (string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    auto defaultInterval = chrono.minutes (5);
    auto interval = millisecondsValue (settings, notificationRefreshIntervalC, defaultInterval);
    if (interval < chrono.minutes (1)) {
        qCWarning (lcConfigFile) << "Notification refresh interval smaller than one minute, setting to one minute";
        interval = chrono.minutes (1);
    }
    return interval;
}

chrono.milliseconds ConfigFile.updateCheckInterval (string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    auto defaultInterval = chrono.hours (10);
    auto interval = millisecondsValue (settings, updateCheckIntervalC, defaultInterval);

    auto minInterval = chrono.minutes (5);
    if (interval < minInterval) {
        qCWarning (lcConfigFile) << "Update check interval less than five minutes, resetting to 5 minutes";
        interval = minInterval;
    }
    return interval;
}

bool ConfigFile.skipUpdateCheck (string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    QVariant fallback = getValue (QLatin1String (skipUpdateCheckC), con, false);
    fallback = getValue (QLatin1String (skipUpdateCheckC), string (), fallback);

    QVariant value = getPolicySetting (QLatin1String (skipUpdateCheckC), fallback);
    return value.toBool ();
}

void ConfigFile.setSkipUpdateCheck (bool skip, string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    settings.setValue (QLatin1String (skipUpdateCheckC), QVariant (skip));
    settings.sync ();
}

bool ConfigFile.autoUpdateCheck (string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    QVariant fallback = getValue (QLatin1String (autoUpdateCheckC), con, true);
    fallback = getValue (QLatin1String (autoUpdateCheckC), string (), fallback);

    QVariant value = getPolicySetting (QLatin1String (autoUpdateCheckC), fallback);
    return value.toBool ();
}

void ConfigFile.setAutoUpdateCheck (bool autoCheck, string &connection) {
    string con (connection);
    if (connection.isEmpty ())
        con = defaultConnection ();

    QSettings settings (configFile (), QSettings.IniFormat);
    settings.beginGroup (con);

    settings.setValue (QLatin1String (autoUpdateCheckC), QVariant (autoCheck));
    settings.sync ();
}

int ConfigFile.updateSegment () {
    QSettings settings (configFile (), QSettings.IniFormat);
    int segment = settings.value (QLatin1String (updateSegmentC), -1).toInt ();

    // Invalid? (Unset at the very first launch)
    if (segment < 0 || segment > 99) {
        // Save valid segment value, normally has to be done only once.
        segment = Utility.rand () % 99;
        settings.setValue (QLatin1String (updateSegmentC), segment);
    }

    return segment;
}

string ConfigFile.updateChannel () {
    string defaultUpdateChannel = QStringLiteral ("stable");
    string suffix = string.fromLatin1 (MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX));
    if (suffix.startsWith ("daily")
        || suffix.startsWith ("nightly")
        || suffix.startsWith ("alpha")
        || suffix.startsWith ("rc")
        || suffix.startsWith ("beta")) {
        defaultUpdateChannel = QStringLiteral ("beta");
    }

    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (updateChannelC), defaultUpdateChannel).toString ();
}

void ConfigFile.setUpdateChannel (string &channel) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (updateChannelC), channel);
}

void ConfigFile.setProxyType (int proxyType,
    const string &host,
    int port, bool needsAuth,
    const string &user,
    const string &pass) {
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.setValue (QLatin1String (proxyTypeC), proxyType);

    if (proxyType == QNetworkProxy.HttpProxy || proxyType == QNetworkProxy.Socks5Proxy) {
        settings.setValue (QLatin1String (proxyHostC), host);
        settings.setValue (QLatin1String (proxyPortC), port);
        settings.setValue (QLatin1String (proxyNeedsAuthC), needsAuth);
        settings.setValue (QLatin1String (proxyUserC), user);

        if (pass.isEmpty ()) {
            // Security : Don't keep password in config file
            settings.remove (QLatin1String (proxyPassC));

            // Delete password from keychain
            auto job = new KeychainChunk.DeleteJob (keychainProxyPasswordKey ());
            job.exec ();
        } else {
            // Write password to keychain
            auto job = new KeychainChunk.WriteJob (keychainProxyPasswordKey (), pass.toUtf8 ());
            if (job.exec ()) {
                // Security : Don't keep password in config file
                settings.remove (QLatin1String (proxyPassC));
            }
        }
    }
    settings.sync ();
}

QVariant ConfigFile.getValue (string &param, string &group,
    const QVariant &defaultValue) {
    QVariant systemSetting;
    if (Utility.isMac ()) {
        QSettings systemSettings (QLatin1String ("/Library/Preferences/" APPLICATION_REV_DOMAIN ".plist"), QSettings.NativeFormat);
        if (!group.isEmpty ()) {
            systemSettings.beginGroup (group);
        }
        systemSetting = systemSettings.value (param, defaultValue);
    } else if (Utility.isUnix ()) {
        QSettings systemSettings (string (SYSCONFDIR "/%1/%1.conf").arg (Theme.instance ().appName ()), QSettings.NativeFormat);
        if (!group.isEmpty ()) {
            systemSettings.beginGroup (group);
        }
        systemSetting = systemSettings.value (param, defaultValue);
    } else { // Windows
        QSettings systemSettings (string.fromLatin1 (R" (HKEY_LOCAL_MACHINE\Software\%1\%2)")
                                     .arg (APPLICATION_VENDOR, Theme.instance ().appNameGUI ()),
            QSettings.NativeFormat);
        if (!group.isEmpty ()) {
            systemSettings.beginGroup (group);
        }
        systemSetting = systemSettings.value (param, defaultValue);
    }

    QSettings settings (configFile (), QSettings.IniFormat);
    if (!group.isEmpty ())
        settings.beginGroup (group);

    return settings.value (param, systemSetting);
}

void ConfigFile.setValue (string &key, QVariant &value) {
    QSettings settings (configFile (), QSettings.IniFormat);

    settings.setValue (key, value);
}

int ConfigFile.proxyType () {
    if (Theme.instance ().forceSystemNetworkProxy ()) {
        return QNetworkProxy.DefaultProxy;
    }
    return getValue (QLatin1String (proxyTypeC)).toInt ();
}

string ConfigFile.proxyHostName () {
    return getValue (QLatin1String (proxyHostC)).toString ();
}

int ConfigFile.proxyPort () {
    return getValue (QLatin1String (proxyPortC)).toInt ();
}

bool ConfigFile.proxyNeedsAuth () {
    return getValue (QLatin1String (proxyNeedsAuthC)).toBool ();
}

string ConfigFile.proxyUser () {
    return getValue (QLatin1String (proxyUserC)).toString ();
}

string ConfigFile.proxyPassword () {
    QByteArray passEncoded = getValue (proxyPassC).toByteArray ();
    auto pass = string.fromUtf8 (QByteArray.fromBase64 (passEncoded));
    passEncoded.clear ();

    const auto key = keychainProxyPasswordKey ();

    if (!pass.isEmpty ()) {
        // Security : Migrate password from config file to keychain
        auto job = new KeychainChunk.WriteJob (key, pass.toUtf8 ());
        if (job.exec ()) {
            QSettings settings (configFile (), QSettings.IniFormat);
            settings.remove (QLatin1String (proxyPassC));
            qCInfo (lcConfigFile ()) << "Migrated proxy password to keychain";
        }
    } else {
        // Read password from keychain
        auto job = new KeychainChunk.ReadJob (key);
        if (job.exec ()) {
            pass = job.textData ();
        }
    }

    return pass;
}

string ConfigFile.keychainProxyPasswordKey () {
    return string.fromLatin1 ("proxy-password");
}

int ConfigFile.useUploadLimit () {
    return getValue (useUploadLimitC, string (), 0).toInt ();
}

int ConfigFile.useDownloadLimit () {
    return getValue (useDownloadLimitC, string (), 0).toInt ();
}

void ConfigFile.setUseUploadLimit (int val) {
    setValue (useUploadLimitC, val);
}

void ConfigFile.setUseDownloadLimit (int val) {
    setValue (useDownloadLimitC, val);
}

int ConfigFile.uploadLimit () {
    return getValue (uploadLimitC, string (), 10).toInt ();
}

int ConfigFile.downloadLimit () {
    return getValue (downloadLimitC, string (), 80).toInt ();
}

void ConfigFile.setUploadLimit (int kbytes) {
    setValue (uploadLimitC, kbytes);
}

void ConfigFile.setDownloadLimit (int kbytes) {
    setValue (downloadLimitC, kbytes);
}

QPair<bool, int64> ConfigFile.newBigFolderSizeLimit () {
    auto defaultValue = Theme.instance ().newBigFolderSizeLimit ();
    const auto fallback = getValue (newBigFolderSizeLimitC, string (), defaultValue).toLongLong ();
    const auto value = getPolicySetting (QLatin1String (newBigFolderSizeLimitC), fallback).toLongLong ();
    const bool use = value >= 0 && useNewBigFolderSizeLimit ();
    return qMakePair (use, qMax<int64> (0, value));
}

void ConfigFile.setNewBigFolderSizeLimit (bool isChecked, int64 mbytes) {
    setValue (newBigFolderSizeLimitC, mbytes);
    setValue (useNewBigFolderSizeLimitC, isChecked);
}

bool ConfigFile.confirmExternalStorage () {
    const auto fallback = getValue (confirmExternalStorageC, string (), true);
    return getPolicySetting (QLatin1String (confirmExternalStorageC), fallback).toBool ();
}

bool ConfigFile.useNewBigFolderSizeLimit () {
    const auto fallback = getValue (useNewBigFolderSizeLimitC, string (), true);
    return getPolicySetting (QLatin1String (useNewBigFolderSizeLimitC), fallback).toBool ();
}

void ConfigFile.setConfirmExternalStorage (bool isChecked) {
    setValue (confirmExternalStorageC, isChecked);
}

bool ConfigFile.moveToTrash () {
    return getValue (moveToTrashC, string (), false).toBool ();
}

void ConfigFile.setMoveToTrash (bool isChecked) {
    setValue (moveToTrashC, isChecked);
}

bool ConfigFile.showMainDialogAsNormalWindow () {
    return getValue (showMainDialogAsNormalWindowC, {}, false).toBool ();
}

bool ConfigFile.promptDeleteFiles () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (promptDeleteC), false).toBool ();
}

void ConfigFile.setPromptDeleteFiles (bool promptDeleteFiles) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (promptDeleteC), promptDeleteFiles);
}

bool ConfigFile.monoIcons () {
    QSettings settings (configFile (), QSettings.IniFormat);
    bool monoDefault = false; // On Mac we want bw by default
    return settings.value (QLatin1String (monoIconsC), monoDefault).toBool ();
}

void ConfigFile.setMonoIcons (bool useMonoIcons) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (monoIconsC), useMonoIcons);
}

bool ConfigFile.crashReporter () {
    QSettings settings (configFile (), QSettings.IniFormat);
    const auto fallback = settings.value (QLatin1String (crashReporterC), true);
    return getPolicySetting (QLatin1String (crashReporterC), fallback).toBool ();
}

void ConfigFile.setCrashReporter (bool enabled) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (crashReporterC), enabled);
}

bool ConfigFile.automaticLogDir () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (automaticLogDirC), false).toBool ();
}

void ConfigFile.setAutomaticLogDir (bool enabled) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (automaticLogDirC), enabled);
}

string ConfigFile.logDir () {
    const auto defaultLogDir = string (configPath () + QStringLiteral ("/logs"));
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (logDirC), defaultLogDir).toString ();
}

void ConfigFile.setLogDir (string &dir) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (logDirC), dir);
}

bool ConfigFile.logDebug () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (logDebugC), true).toBool ();
}

void ConfigFile.setLogDebug (bool enabled) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (logDebugC), enabled);
}

int ConfigFile.logExpire () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (logExpireC), 24).toInt ();
}

void ConfigFile.setLogExpire (int hours) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (logExpireC), hours);
}

bool ConfigFile.logFlush () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (logFlushC), false).toBool ();
}

void ConfigFile.setLogFlush (bool enabled) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (logFlushC), enabled);
}

bool ConfigFile.showExperimentalOptions () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (showExperimentalOptionsC), false).toBool ();
}

string ConfigFile.certificatePath () {
    return retrieveData (string (), QLatin1String (certPath)).toString ();
}

void ConfigFile.setCertificatePath (string &cPath) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (certPath), cPath);
    settings.sync ();
}

string ConfigFile.certificatePasswd () {
    return retrieveData (string (), QLatin1String (certPasswd)).toString ();
}

void ConfigFile.setCertificatePasswd (string &cPasswd) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (certPasswd), cPasswd);
    settings.sync ();
}

string ConfigFile.clientVersionString () {
    QSettings settings (configFile (), QSettings.IniFormat);
    return settings.value (QLatin1String (clientVersionC), string ()).toString ();
}

void ConfigFile.setClientVersionString (string &version) {
    QSettings settings (configFile (), QSettings.IniFormat);
    settings.setValue (QLatin1String (clientVersionC), version);
}

Q_GLOBAL_STATIC (string, g_configFileName)

std.unique_ptr<QSettings> ConfigFile.settingsWithGroup (string &group, GLib.Object *parent) {
    if (g_configFileName ().isEmpty ()) {
        // cache file name
        ConfigFile cfg;
        *g_configFileName () = cfg.configFile ();
    }
    std.unique_ptr<QSettings> settings (new QSettings (*g_configFileName (), QSettings.IniFormat, parent));
    settings.beginGroup (group);
    return settings;
}

void ConfigFile.setupDefaultExcludeFilePaths (ExcludedFiles &excludedFiles) {
    ConfigFile cfg;
    string systemList = cfg.excludeFile (ConfigFile.SystemScope);
    string userList = cfg.excludeFile (ConfigFile.UserScope);

    if (!QFile.exists (userList)) {
        qCInfo (lcConfigFile) << "User defined ignore list does not exist:" << userList;
        if (!QFile.copy (systemList, userList)) {
            qCInfo (lcConfigFile) << "Could not copy over default list to:" << userList;
        }
    }

    if (!QFile.exists (userList)) {
        qCInfo (lcConfigFile) << "Adding system ignore list to csync:" << systemList;
        excludedFiles.addExcludeFilePath (systemList);
    } else {
        qCInfo (lcConfigFile) << "Adding user defined ignore list to csync:" << userList;
        excludedFiles.addExcludeFilePath (userList);
    }
}
}
