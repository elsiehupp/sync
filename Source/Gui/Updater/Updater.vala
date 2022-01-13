/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QUrl>
// #include <QUrlQuery>
// #include <QProcess>

// #include <QSysInfo>

// #include <QLoggingCategory>
// #include <GLib.Object>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcUpdater)

class Updater : GLib.Object {
public:
    struct Helper {
        static int64 stringVersionToInt (string &version);
        static int64 currentVersionToInt ();
        static int64 versionToInt (int64 major, int64 minor, int64 patch, int64 build);
    };

    static Updater *instance ();
    static QUrl updateUrl ();

    virtual void checkForUpdate () = 0;
    virtual void backgroundCheckForUpdate () = 0;
    virtual bool handleStartup () = 0;

protected:
    static string clientVersion ();
    Updater ()
        : GLib.Object (nullptr) {
    }

private:
    static string getSystemInfo ();
    static QUrlQuery getQueryParams ();
    static Updater *create ();
    static Updater *_instance;
};


    Updater *Updater._instance = nullptr;
    
    Updater *Updater.instance () {
        if (!_instance) {
            _instance = create ();
        }
        return _instance;
    }
    
    QUrl Updater.updateUrl () {
        QUrl updateBaseUrl (string.fromLocal8Bit (qgetenv ("OCC_UPDATE_URL")));
        if (updateBaseUrl.isEmpty ()) {
            updateBaseUrl = QUrl (QLatin1String (APPLICATION_UPDATE_URL));
        }
        if (!updateBaseUrl.isValid () || updateBaseUrl.host () == ".") {
            return QUrl ();
        }
    
        auto urlQuery = getQueryParams ();
    
        updateBaseUrl.setQuery (urlQuery);
    
        return updateBaseUrl;
    }
    
    QUrlQuery Updater.getQueryParams () {
        QUrlQuery query;
        Theme *theme = Theme.instance ();
        string platform = QStringLiteral ("stranger");
        if (Utility.isLinux ()) {
            platform = QStringLiteral ("linux");
        } else if (Utility.isBSD ()) {
            platform = QStringLiteral ("bsd");
        } else if (Utility.isWindows ()) {
            platform = QStringLiteral ("win32");
        } else if (Utility.isMac ()) {
            platform = QStringLiteral ("macos");
        }
    
        string sysInfo = getSystemInfo ();
        if (!sysInfo.isEmpty ()) {
            query.addQueryItem (QStringLiteral ("client"), sysInfo);
        }
        query.addQueryItem (QStringLiteral ("version"), clientVersion ());
        query.addQueryItem (QStringLiteral ("platform"), platform);
        query.addQueryItem (QStringLiteral ("osRelease"), QSysInfo.productType ());
        query.addQueryItem (QStringLiteral ("osVersion"), QSysInfo.productVersion ());
        query.addQueryItem (QStringLiteral ("kernelVersion"), QSysInfo.kernelVersion ());
        query.addQueryItem (QStringLiteral ("oem"), theme.appName ());
        query.addQueryItem (QStringLiteral ("buildArch"), QSysInfo.buildCpuArchitecture ());
        query.addQueryItem (QStringLiteral ("currentArch"), QSysInfo.currentCpuArchitecture ());
    
        string suffix = QStringLiteral (MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX));
        query.addQueryItem (QStringLiteral ("versionsuffix"), suffix);
    
        auto channel = ConfigFile ().updateChannel ();
        if (channel != QLatin1String ("stable")) {
            query.addQueryItem (QStringLiteral ("channel"), channel);
        }
    
        // updateSegment (see configfile.h)
        ConfigFile cfg;
        auto updateSegment = cfg.updateSegment ();
        query.addQueryItem (QLatin1String ("updatesegment"), string.number (updateSegment));
    
        return query;
    }
    
    string Updater.getSystemInfo () {
    #ifdef Q_OS_LINUX
        QProcess process;
        process.start (QLatin1String ("lsb_release"), { QStringLiteral ("-a") });
        process.waitForFinished ();
        QByteArray output = process.readAllStandardOutput ();
        qCDebug (lcUpdater) << "Sys Info size : " << output.length ();
        if (output.length () > 1024)
            output.clear (); // don't send too much.
    
        return string.fromLocal8Bit (output.toBase64 ());
    #else
        return string ();
    #endif
    }
    
    // To test, cmake with -DAPPLICATION_UPDATE_URL="http://127.0.0.1:8080/test.rss"
    Updater *Updater.create () {
        auto url = updateUrl ();
        qCDebug (lcUpdater) << url;
        if (url.isEmpty ()) {
            qCWarning (lcUpdater) << "Not a valid updater URL, will not do update check";
            return nullptr;
        }
        // the best we can do is notify about updates
        return new PassiveUpdateNotifier (url);
    }
    
    int64 Updater.Helper.versionToInt (int64 major, int64 minor, int64 patch, int64 build) {
        return major << 56 | minor << 48 | patch << 40 | build;
    }
    
    int64 Updater.Helper.currentVersionToInt () {
        return versionToInt (MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR,
            MIRALL_VERSION_PATCH, MIRALL_VERSION_BUILD);
    }
    
    int64 Updater.Helper.stringVersionToInt (string &version) {
        if (version.isEmpty ())
            return 0;
        QByteArray baVersion = version.toLatin1 ();
        int major = 0, minor = 0, patch = 0, build = 0;
        sscanf (baVersion, "%d.%d.%d.%d", &major, &minor, &patch, &build);
        return versionToInt (major, minor, patch, build);
    }
    
    string Updater.clientVersion () {
        return string.fromLatin1 (MIRALL_STRINGIFY (MIRALL_VERSION_FULL));
    }
    
    } // namespace Occ
    