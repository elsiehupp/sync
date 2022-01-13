/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <string>
// #include <QByteArray>
// #include <QDateTime>
// #include <QElapsedTimer>
// #include <QLoggingCategory>
// #include <QMap>
// #include <QUrl>
// #include <QUrlQuery>
// #include <functional>
// #include <memory>


namespace Occ {


Q_DECLARE_LOGGING_CATEGORY (lcUtility)

/** \addtogroup libsync
 @{
***********************************************************/
namespace Utility {
    OCSYNC_EXPORT int rand ();
    OCSYNC_EXPORT void sleep (int sec);
    OCSYNC_EXPORT void usleep (int usec);
    OCSYNC_EXPORT string formatFingerprint (QByteArray &, bool colonSeparated = true);
    OCSYNC_EXPORT void setupFavLink (string &folder);
    OCSYNC_EXPORT void removeFavLink (string &folder);
    OCSYNC_EXPORT bool writeRandomFile (string &fname, int size = -1);
    OCSYNC_EXPORT string octetsToString (int64 octets);
    OCSYNC_EXPORT QByteArray userAgentString ();
    OCSYNC_EXPORT QByteArray friendlyUserAgentString ();
    /***********************************************************
      * @brief Return whether launch on startup is enabled system wide.
      *
      * If this returns true, the checkbox for user specific launch
      * on startup will be hidden.
      *
      * Currently only implemented on Windows.
      */
    OCSYNC_EXPORT bool hasSystemLaunchOnStartup (string &appName);
    OCSYNC_EXPORT bool hasLaunchOnStartup (string &appName);
    OCSYNC_EXPORT void setLaunchOnStartup (string &appName, string &guiName, bool launch);
    OCSYNC_EXPORT uint convertSizeToUint (size_t &convertVar);
    OCSYNC_EXPORT int convertSizeToInt (size_t &convertVar);

    /***********************************************************
     * Return the amount of free space available.
     *
     * \a path must point to a directory
     */
    OCSYNC_EXPORT int64 freeDiskSpace (string &path);

    /***********************************************************
     * @brief compactFormatDouble - formats a double value human readable.
     *
     * @param value the value to format.
     * @param prec the precision.
     * @param unit an optional unit that is appended if present.
     * @return the formatted string.
     */
    OCSYNC_EXPORT string compactFormatDouble (double value, int prec, string &unit = string ());

    // porting methods
    OCSYNC_EXPORT string escape (string &);

    // conversion function QDateTime <. time_t   (because the ones builtin work on only unsigned 32bit)
    OCSYNC_EXPORT QDateTime qDateTimeFromTime_t (int64 t);
    OCSYNC_EXPORT int64 qDateTimeToTime_t (QDateTime &t);

    /***********************************************************
     * @brief Convert milliseconds duration to human readable string.
     * @param uint64 msecs the milliseconds to convert to string.
     * @return an HMS representation of the milliseconds value.
     *
     * durationToDescriptiveString1 describes the duration in a single
     * unit, like "5 minutes" or "2 days".
     *
     * durationToDescriptiveString2 uses two units where possible, so
     * "5 minutes 43 seconds" or "1 month 3 days".
     */
    OCSYNC_EXPORT string durationToDescriptiveString1 (uint64 msecs);
    OCSYNC_EXPORT string durationToDescriptiveString2 (uint64 msecs);

    /***********************************************************
     * @brief hasDarkSystray - determines whether the systray is dark or light.
     *
     * Use this to check if the OS has a dark or a light systray.
     *
     * The value might change during the execution of the program
     * (e.g. on OS X 10.10).
     *
     * @return bool which is true for systems with dark systray.
     */
    OCSYNC_EXPORT bool hasDarkSystray ();

    // convenience OS detection methods
    inline bool isWindows ();
    inline bool isMac ();
    inline bool isUnix ();
    inline bool isLinux (); // use with care
    inline bool isBSD (); // use with care, does not match OS X

    OCSYNC_EXPORT string platformName ();
    // crash helper for --debug
    OCSYNC_EXPORT void crash ();

    // Case preserving file system underneath?
    // if this function returns true, the file system is case preserving,
    // that means "test" means the same as "TEST" for filenames.
    // if false, the two cases are two different files.
    OCSYNC_EXPORT bool fsCasePreserving ();

    // Check if two pathes that MUST exist are equal. This function
    // uses QDir.canonicalPath () to judge and cares for the systems
    // case sensitivity.
    OCSYNC_EXPORT bool fileNamesEqual (string &fn1, string &fn2);

    // Call the given command with the switch --version and rerun the first line
    // of the output.
    // If command is empty, the function calls the running application which, on
    // Linux, might have changed while this one is running.
    // For Mac and Windows, it returns string ()
    OCSYNC_EXPORT QByteArray versionOfInstalledBinary (string &command = string ());

    OCSYNC_EXPORT string fileNameForGuiUse (string &fName);

    OCSYNC_EXPORT QByteArray normalizeEtag (QByteArray etag);

    /***********************************************************
     * @brief timeAgoInWords - human readable time span
     *
     * Use this to get a string that describes the timespan between the first and
     * the second timestamp in a human readable and understandable form.
     *
     * If the second parameter is ommitted, the current time is used.
     */
    OCSYNC_EXPORT string timeAgoInWords (QDateTime &dt, QDateTime &from = QDateTime ());

    class StopWatch {
    private:
        QMap<string, uint64> _lapTimes;
        QDateTime _startTime;
        QElapsedTimer _timer;

    public:
        void start ();
        uint64 stop ();
        uint64 addLapTime (string &lapName);
        void reset ();

        // out helpers, return the measured times.
        QDateTime startTime ();
        QDateTime timeOfLap (string &lapName) const;
        uint64 durationOfLap (string &lapName) const;
    };

    /***********************************************************
     * @brief Sort a QStringList in a way that's appropriate for filenames
     */
    OCSYNC_EXPORT void sortFilenames (QStringList &fileNames);

    /** Appends concatPath and queryItems to the url */
    OCSYNC_EXPORT QUrl concatUrlPath (
        const QUrl &url, string &concatPath,
        const QUrlQuery &queryItems = {});

    /**  Returns a new settings pre-set in a specific group.  The Settings will be created
         with the given parent. If no parent is specified, the caller must destroy the settings */
    OCSYNC_EXPORT std.unique_ptr<QSettings> settingsWithGroup (string &group, GLib.Object *parent = nullptr);

    /** Sanitizes a string that shall become part of a filename.
     *
     * Filters out reserved characters like
     * - unicode control and format characters
     * - reserved characters : /, ?, <, >, \, :, *, |, and "
     *
     * Warning : This does not sanitize the whole resulting string, so
     * - unix reserved filenames ('.', '..')
     * - trailing periods and spaces
     * - windows reserved filenames ('CON' etc)
     * will pass unchanged.
     */
    OCSYNC_EXPORT string sanitizeForFileName (string &name);

    /** Returns a file name based on \a fn that's suitable for a conflict.
     */
    OCSYNC_EXPORT string makeConflictFileName (
        const string &fn, QDateTime &dt, string &user);

    /** Returns whether a file name indicates a conflict file
     */
    OCSYNC_EXPORT bool isConflictFile (char *name);
    OCSYNC_EXPORT bool isConflictFile (string &name);

    /** Find the base name for a conflict file name, using name pattern only
     *
     * Will return an empty string if it's not a conflict file.
     *
     * Prefer to use the data from the conflicts table in the journal to determine
     * a conflict's base file, see SyncJournal.conflictFileBaseName ()
     */
    OCSYNC_EXPORT QByteArray conflictFileBaseNameFromPattern (QByteArray &conflictName);

    /***********************************************************
     * @brief Check whether the path is a root of a Windows drive partition ([c:/, d:/, e:/, etc.)
     */
    OCSYNC_EXPORT bool isPathWindowsDrivePartitionRoot (string &path);

    /***********************************************************
     * @brief Retrieves current logged-in user name from the OS
     */
    OCSYNC_EXPORT string getCurrentUserName ();
}
/** @} */ // \addtogroup

inline bool Utility.isWindows () {
    return false;
}

inline bool Utility.isMac () {
    return false;
}

inline bool Utility.isUnix () {
#ifdef Q_OS_UNIX
    return true;
#else
    return false;
#endif
}

inline bool Utility.isLinux () {
#if defined (Q_OS_LINUX)
    return true;
#else
    return false;
#endif
}

inline bool Utility.isBSD () {
#if defined (Q_OS_FREEBSD) || defined (Q_OS_NETBSD) || defined (Q_OS_OPENBSD)
    return true;
#else
    return false;
#endif
}

}




/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// Note :  This file must compile without QtGui
// #include <QCoreApplication>
// #include <QSettings>
// #include <QTextStream>
// #include <QDir>
// #include <QFile>
// #include <QUrl>
// #include <QProcess>
// #include <GLib.Object>
// #include <QThread>
// #include <QDateTime>
// #include <QSysInfo>
// #include <QStandardPaths>
// #include <QCollator>
// #include <QSysInfo>
// #include <qrandom.h>

#ifdef Q_OS_UNIX
// #include <sys/statvfs.h>
// #include <sys/types.h>
// #include <unistd.h>
#endif

// #include <cmath>
// #include <cstdarg>
// #include <cstring>

#include "utility_unix.cpp"

namespace Occ {

Q_LOGGING_CATEGORY (lcUtility, "nextcloud.sync.utility", QtInfoMsg)

bool Utility.writeRandomFile (string &fname, int size) {
    int maxSize = 10 * 10 * 1024;

    if (size == -1)
        size = rand () % maxSize;

    string randString;
    for (int i = 0; i < size; i++) {
        int r = rand () % 128;
        randString.append (QChar (r));
    }

    QFile file (fname);
    if (file.open (QIODevice.WriteOnly | QIODevice.Text)) {
        QTextStream out (&file);
        out << randString;
        // optional, as QFile destructor will already do it:
        file.close ();
        return true;
    }
    return false;
}

string Utility.formatFingerprint (QByteArray &fmhash, bool colonSeparated) {
    QByteArray hash;
    int steps = fmhash.length () / 2;
    for (int i = 0; i < steps; i++) {
        hash.append (fmhash[i * 2]);
        hash.append (fmhash[i * 2 + 1]);
        hash.append (' ');
    }

    string fp = string.fromLatin1 (hash.trimmed ());
    if (colonSeparated) {
        fp.replace (QLatin1Char (' '), QLatin1Char (':'));
    }

    return fp;
}

void Utility.setupFavLink (string &folder) {
    setupFavLink_private (folder);
}

void Utility.removeFavLink (string &folder) {
    removeFavLink_private (folder);
}

string Utility.octetsToString (int64 octets) {
const int THE_FACTOR 1024
    static const int64 kb = THE_FACTOR;
    static const int64 mb = THE_FACTOR * kb;
    static const int64 gb = THE_FACTOR * mb;

    string s;
    qreal value = octets;

    // Whether we care about decimals : only for GB/MB and only
    // if it's less than 10 units.
    bool round = true;

    // do not display terra byte with the current units, as when
    // the MB, GB and KB units were made, there was no TB,
    // see the JEDEC standard
    // https://en.wikipedia.org/wiki/JEDEC_memory_standards
    if (octets >= gb) {
        s = QCoreApplication.translate ("Utility", "%L1 GB");
        value /= gb;
        round = false;
    } else if (octets >= mb) {
        s = QCoreApplication.translate ("Utility", "%L1 MB");
        value /= mb;
        round = false;
    } else if (octets >= kb) {
        s = QCoreApplication.translate ("Utility", "%L1 KB");
        value /= kb;
    } else {
        s = QCoreApplication.translate ("Utility", "%L1 B");
    }

    if (value > 9.95)
        round = true;

    if (round)
        return s.arg (qRound (value));

    return s.arg (value, 0, 'g', 2);
}

// Qtified version of get_platforms () in csync_owncloud.c
static QLatin1String platform () {
    return QSysInfo.productType ();
}

QByteArray Utility.userAgentString () {
    return QStringLiteral ("Mozilla/5.0 (%1) mirall/%2 (%3, %4-%5 ClientArchitecture : %6 OsArchitecture : %7)")
        .arg (platform (),
            QStringLiteral (MIRALL_VERSION_STRING),
            qApp.applicationName (),
            QSysInfo.productType (),
            QSysInfo.kernelVersion (),
            QSysInfo.buildCpuArchitecture (),
            QSysInfo.currentCpuArchitecture ())
        .toLatin1 ();
}

QByteArray Utility.friendlyUserAgentString () {
    const auto pattern = QStringLiteral ("%1 (Desktop Client - %2)");
    const auto userAgent = pattern.arg (QSysInfo.machineHostName (), platform ());
    return userAgent.toUtf8 ();
}

bool Utility.hasSystemLaunchOnStartup (string &appName) {
    Q_UNUSED (appName)
    return false;
}

bool Utility.hasLaunchOnStartup (string &appName) {
    return hasLaunchOnStartup_private (appName);
}

void Utility.setLaunchOnStartup (string &appName, string &guiName, bool enable) {
    setLaunchOnStartup_private (appName, guiName, enable);
}

int64 Utility.freeDiskSpace (string &path) {
#if defined (Q_OS_UNIX)
    struct statvfs64 stat;
    if (statvfs64 (path.toLocal8Bit ().data (), &stat) == 0) {
        return (int64)stat.f_bavail * stat.f_frsize;
    }
#endif
    return -1;
}

string Utility.compactFormatDouble (double value, int prec, string &unit) {
    QLocale locale = QLocale.system ();
    QChar decPoint = locale.decimalPoint ();
    string str = locale.toString (value, 'f', prec);
    while (str.endsWith (QLatin1Char ('0')) || str.endsWith (decPoint)) {
        if (str.endsWith (decPoint)) {
            str.chop (1);
            break;
        }
        str.chop (1);
    }
    if (!unit.isEmpty ())
        str += (QLatin1Char (' ') + unit);
    return str;
}

string Utility.escape (string &in) {
    return in.toHtmlEscaped ();
}

int Utility.rand () {
    return QRandomGenerator.global ().bounded (0, RAND_MAX);
}

void Utility.sleep (int sec) {
    QThread.sleep (sec);
}

void Utility.usleep (int usec) {
    QThread.usleep (usec);
}

// This can be overriden from the tests
OCSYNC_EXPORT bool fsCasePreserving_override = [] () . bool {
    QByteArray env = qgetenv ("OWNCLOUD_TEST_CASE_PRESERVING");
    if (!env.isEmpty ())
        return env.toInt ();
    return Utility.isWindows () || Utility.isMac ();
} ();

bool Utility.fsCasePreserving () {
    return fsCasePreserving_override;
}

bool Utility.fileNamesEqual (string &fn1, string &fn2) {
    const QDir fd1 (fn1);
    const QDir fd2 (fn2);

    // Attention : If the path does not exist, canonicalPath returns ""
    // ONLY use this function with existing pathes.
    const string a = fd1.canonicalPath ();
    const string b = fd2.canonicalPath ();
    bool re = !a.isEmpty () && string.compare (a, b, fsCasePreserving () ? Qt.CaseInsensitive : Qt.CaseSensitive) == 0;
    return re;
}

QDateTime Utility.qDateTimeFromTime_t (int64 t) {
    return QDateTime.fromMSecsSinceEpoch (t * 1000);
}

int64 Utility.qDateTimeToTime_t (QDateTime &t) {
    return t.toMSecsSinceEpoch () / 1000;
}

namespace {
    struct Period {
        const char *name;
        uint64 msec;

        string description (uint64 value) {
            return QCoreApplication.translate ("Utility", name, nullptr, value);
        }
    };
// QTBUG-3945 and issue #4855 : QT_TRANSLATE_NOOP does not work with plural form because lupdate
// limitation unless we fake more arguments
// (it must be in the form ("context", "source", "comment", n)
#undef QT_TRANSLATE_NOOP
const int QT_TRANSLATE_NOOP (ctx, str, ...) str
    Q_DECL_CONSTEXPR Period periods[] = { { QT_TRANSLATE_NOOP ("Utility", "%n year (s)", 0, _), 365 * 24 * 3600 * 1000LL }, { QT_TRANSLATE_NOOP ("Utility", "%n month (s)", 0, _), 30 * 24 * 3600 * 1000LL }, { QT_TRANSLATE_NOOP ("Utility", "%n day (s)", 0, _), 24 * 3600 * 1000LL }, { QT_TRANSLATE_NOOP ("Utility", "%n hour (s)", 0, _), 3600 * 1000LL }, { QT_TRANSLATE_NOOP ("Utility", "%n minute (s)", 0, _), 60 * 1000LL }, { QT_TRANSLATE_NOOP ("Utility", "%n second (s)", 0, _), 1000LL }, { nullptr, 0 }
    };
} // anonymous namespace

string Utility.durationToDescriptiveString2 (uint64 msecs) {
    int p = 0;
    while (periods[p + 1].name && msecs < periods[p].msec) {
        p++;
    }

    auto firstPart = periods[p].description (int (msecs / periods[p].msec));

    if (!periods[p + 1].name) {
        return firstPart;
    }

    uint64 secondPartNum = qRound (double (msecs % periods[p].msec) / periods[p + 1].msec);

    if (secondPartNum == 0) {
        return firstPart;
    }

    return QCoreApplication.translate ("Utility", "%1 %2").arg (firstPart, periods[p + 1].description (secondPartNum));
}

string Utility.durationToDescriptiveString1 (uint64 msecs) {
    int p = 0;
    while (periods[p + 1].name && msecs < periods[p].msec) {
        p++;
    }

    uint64 amount = qRound (double (msecs) / periods[p].msec);
    return periods[p].description (amount);
}

string Utility.fileNameForGuiUse (string &fName) {
    if (isMac ()) {
        string n (fName);
        return n.replace (QLatin1Char (':'), QLatin1Char ('/'));
    }
    return fName;
}

QByteArray Utility.normalizeEtag (QByteArray etag) {
    /* strip "XXXX-gzip" */
    if (etag.startsWith ('"') && etag.endsWith ("-gzip\"")) {
        etag.chop (6);
        etag.remove (0, 1);
    }
    /* strip trailing -gzip */
    if (etag.endsWith ("-gzip")) {
        etag.chop (5);
    }
    /* strip normal quotes */
    if (etag.startsWith ('"') && etag.endsWith ('"')) {
        etag.chop (1);
        etag.remove (0, 1);
    }
    etag.squeeze ();
    return etag;
}

bool Utility.hasDarkSystray () {
    return hasDarkSystray_private ();
}

string Utility.platformName () {
    return QSysInfo.prettyProductName ();
}

void Utility.crash () {
    volatile int *a = (int *)nullptr;
    *a = 1;
}

// Use this functions to retrieve uint/int (often required by Qt and WIN32) from size_t
// without compiler warnings about possible truncation
uint Utility.convertSizeToUint (size_t &convertVar) {
    if (convertVar > UINT_MAX) {
        //throw std.bad_cast ();
        convertVar = UINT_MAX; // intentionally default to wrong value here to not crash : exception handling TBD
    }
    return static_cast<uint> (convertVar);
}

int Utility.convertSizeToInt (size_t &convertVar) {
    if (convertVar > INT_MAX) {
        //throw std.bad_cast ();
        convertVar = INT_MAX; // intentionally default to wrong value here to not crash : exception handling TBD
    }
    return static_cast<int> (convertVar);
}

// read the output of the owncloud --version command from the owncloud
// version that is on disk. This works for most versions of the client,
// because clients that do not yet know the --version flag return the
// version in the first line of the help output :-)
//
// This version only delivers output on linux, as Mac and Win get their
// restarting from the installer.
QByteArray Utility.versionOfInstalledBinary (string &command) {
    QByteArray re;
    if (isLinux ()) {
        string binary (command);
        if (binary.isEmpty ()) {
            binary = qApp.arguments ()[0];
        }
        QStringList params;
        params << QStringLiteral ("--version");
        QProcess process;
        process.start (binary, params);
        process.waitForFinished (); // sets current thread to sleep and waits for pingProcess end
        re = process.readAllStandardOutput ();
        int newline = re.indexOf ('\n');
        if (newline > 0) {
            re.truncate (newline);
        }
    }
    return re;
}

string Utility.timeAgoInWords (QDateTime &dt, QDateTime &from) {
    QDateTime now = QDateTime.currentDateTimeUtc ();

    if (from.isValid ()) {
        now = from;
    }

    if (dt.daysTo (now) == 1) {
        return GLib.Object.tr ("%n day ago", "", dt.daysTo (now));
    } else if (dt.daysTo (now) > 1) {
        return GLib.Object.tr ("%n days ago", "", dt.daysTo (now));
    } else {
        int64 secs = dt.secsTo (now);
        if (secs < 0) {
            return GLib.Object.tr ("in the future");
        }

        if (floor (secs / 3600.0) > 0) {
            int hours = floor (secs / 3600.0);
            if (hours == 1) {
                return (GLib.Object.tr ("%n hour ago", "", hours));
            } else {
                return (GLib.Object.tr ("%n hours ago", "", hours));
            }
        } else {
            int minutes = qRound (secs / 60.0);

            if (minutes == 0) {
                if (secs < 5) {
                    return GLib.Object.tr ("now");
                } else {
                    return GLib.Object.tr ("Less than a minute ago");
                }

            } else if (minutes == 1) {
                return (GLib.Object.tr ("%n minute ago", "", minutes));
            } else {
                return (GLib.Object.tr ("%n minutes ago", "", minutes));
            }
        }
    }
    return GLib.Object.tr ("Some time ago");
}

/* --------------------------------------------------------------------------- */

static const char STOPWATCH_END_TAG[] = "_STOPWATCH_END";

void Utility.StopWatch.start () {
    _startTime = QDateTime.currentDateTimeUtc ();
    _timer.start ();
}

uint64 Utility.StopWatch.stop () {
    addLapTime (QLatin1String (STOPWATCH_END_TAG));
    uint64 duration = _timer.elapsed ();
    _timer.invalidate ();
    return duration;
}

void Utility.StopWatch.reset () {
    _timer.invalidate ();
    _startTime.setMSecsSinceEpoch (0);
    _lapTimes.clear ();
}

uint64 Utility.StopWatch.addLapTime (string &lapName) {
    if (!_timer.isValid ()) {
        start ();
    }
    uint64 re = _timer.elapsed ();
    _lapTimes[lapName] = re;
    return re;
}

QDateTime Utility.StopWatch.startTime () {
    return _startTime;
}

QDateTime Utility.StopWatch.timeOfLap (string &lapName) {
    uint64 t = durationOfLap (lapName);
    if (t) {
        QDateTime re (_startTime);
        return re.addMSecs (t);
    }

    return QDateTime ();
}

uint64 Utility.StopWatch.durationOfLap (string &lapName) {
    return _lapTimes.value (lapName, 0);
}

void Utility.sortFilenames (QStringList &fileNames) {
    QCollator collator;
    collator.setNumericMode (true);
    collator.setCaseSensitivity (Qt.CaseInsensitive);
    std.sort (fileNames.begin (), fileNames.end (), collator);
}

QUrl Utility.concatUrlPath (QUrl &url, string &concatPath,
    const QUrlQuery &queryItems) {
    string path = url.path ();
    if (!concatPath.isEmpty ()) {
        // avoid '//'
        if (path.endsWith (QLatin1Char ('/')) && concatPath.startsWith (QLatin1Char ('/'))) {
            path.chop (1);
        } // avoid missing '/'
        else if (!path.endsWith (QLatin1Char ('/')) && !concatPath.startsWith (QLatin1Char ('/'))) {
            path += QLatin1Char ('/');
        }
        path += concatPath; // put the complete path together
    }

    QUrl tmpUrl = url;
    tmpUrl.setPath (path);
    tmpUrl.setQuery (queryItems);
    return tmpUrl;
}

string Utility.makeConflictFileName (
    const string &fn, QDateTime &dt, string &user) {
    string conflictFileName (fn);
    // Add conflict tag before the extension.
    int dotLocation = conflictFileName.lastIndexOf (QLatin1Char ('.'));
    // If no extension, add it at the end  (take care of cases like foo/.hidden or foo.bar/file)
    if (dotLocation <= conflictFileName.lastIndexOf (QLatin1Char ('/')) + 1) {
        dotLocation = conflictFileName.size ();
    }

    string conflictMarker = QStringLiteral (" (conflicted copy ");
    if (!user.isEmpty ()) {
        // Don't allow parens in the user name, to ensure
        // we can find the beginning and end of the conflict tag.
        const auto userName = sanitizeForFileName (user).replace (QLatin1Char (' ('), QLatin1Char ('_')).replace (QLatin1Char (')'), QLatin1Char ('_'));;
        conflictMarker += userName + QLatin1Char (' ');
    }
    conflictMarker += dt.toString (QStringLiteral ("yyyy-MM-dd hhmmss")) + QLatin1Char (')');

    conflictFileName.insert (dotLocation, conflictMarker);
    return conflictFileName;
}

bool Utility.isConflictFile (char *name) {
    const char *bname = std.strrchr (name, '/');
    if (bname) {
        bname += 1;
    } else {
        bname = name;
    }

    // Old pattern
    if (std.strstr (bname, "_conflict-"))
        return true;

    // New pattern
    if (std.strstr (bname, " (conflicted copy"))
        return true;

    return false;
}

bool Utility.isConflictFile (string &name) {
    auto bname = name.midRef (name.lastIndexOf (QLatin1Char ('/')) + 1);

    if (bname.contains (QStringLiteral ("_conflict-")))
        return true;

    if (bname.contains (QStringLiteral (" (conflicted copy")))
        return true;

    return false;
}

QByteArray Utility.conflictFileBaseNameFromPattern (QByteArray &conflictName) {
    // This function must be able to deal with conflict files for conflict files.
    // To do this, we scan backwards, for the outermost conflict marker and
    // strip only that to generate the conflict file base name.
    auto startOld = conflictName.lastIndexOf ("_conflict-");

    // A single space before " (conflicted copy" is considered part of the tag
    auto startNew = conflictName.lastIndexOf (" (conflicted copy");
    if (startNew > 0 && conflictName[startNew - 1] == ' ')
        startNew -= 1;

    // The rightmost tag is relevant
    auto tagStart = qMax (startOld, startNew);
    if (tagStart == -1)
        return "";

    // Find the end of the tag
    auto tagEnd = conflictName.size ();
    auto dot = conflictName.lastIndexOf ('.'); // dot could be part of user name for new tag!
    if (dot > tagStart)
        tagEnd = dot;
    if (tagStart == startNew) {
        auto paren = conflictName.indexOf (')', tagStart);
        if (paren != -1)
            tagEnd = paren + 1;
    }
    return conflictName.left (tagStart) + conflictName.mid (tagEnd);
}

bool Utility.isPathWindowsDrivePartitionRoot (string &path) {
    Q_UNUSED (path)
    return false;
}

string Utility.sanitizeForFileName (string &name) {
    const auto invalid = QStringLiteral (R" (/?<>\:*|\")");
    string result;
    result.reserve (name.size ());
    for (auto c : name) {
        if (!invalid.contains (c)
            && c.category () != QChar.Other_Control
            && c.category () != QChar.Other_Format) {
            result.append (c);
        }
    }
    return result;
}

} // namespace Occ






/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QStandardPaths>
// #include <QtGlobal>

namespace Occ {

    static void setupFavLink_private (string &folder) {
        // Nautilus : add to ~/.gtk-bookmarks
        QFile gtkBookmarks (QDir.homePath () + QLatin1String ("/.config/gtk-3.0/bookmarks"));
        QByteArray folderUrl = "file://" + folder.toUtf8 ();
        if (gtkBookmarks.open (QFile.ReadWrite)) {
            QByteArray places = gtkBookmarks.readAll ();
            if (!places.contains (folderUrl)) {
                places += folderUrl;
                gtkBookmarks.reset ();
                gtkBookmarks.write (places + '\n');
            }
        }
    }
    
    static void removeFavLink_private (string &folder) {
        Q_UNUSED (folder)
    }
    
    // returns the autostart directory the linux way
    // and respects the XDG_CONFIG_HOME env variable
    string getUserAutostartDir_private () {
        string config = QStandardPaths.writableLocation (QStandardPaths.ConfigLocation);
        config += QLatin1String ("/autostart/");
        return config;
    }
    
    bool hasLaunchOnStartup_private (string &appName) {
        Q_UNUSED (appName)
        string desktopFileLocation = getUserAutostartDir_private ()
                                        + QLatin1String (LINUX_APPLICATION_ID)
                                        + QLatin1String (".desktop");
        return QFile.exists (desktopFileLocation);
    }
    
    void setLaunchOnStartup_private (string &appName, string &guiName, bool enable) {
        Q_UNUSED (appName)
        string userAutoStartPath = getUserAutostartDir_private ();
        string desktopFileLocation = userAutoStartPath
                                        + QLatin1String (LINUX_APPLICATION_ID)
                                        + QLatin1String (".desktop");
        if (enable) {
            if (!QDir ().exists (userAutoStartPath) && !QDir ().mkpath (userAutoStartPath)) {
                qCWarning (lcUtility) << "Could not create autostart folder" << userAutoStartPath;
                return;
            }
            QFile iniFile (desktopFileLocation);
            if (!iniFile.open (QIODevice.WriteOnly)) {
                qCWarning (lcUtility) << "Could not write auto start entry" << desktopFileLocation;
                return;
            }
            // When running inside an AppImage, we need to set the path to the
            // AppImage instead of the path to the executable
            const string appImagePath = qEnvironmentVariable ("APPIMAGE");
            const bool runningInsideAppImage = !appImagePath.isNull () && QFile.exists (appImagePath);
            const string executablePath = runningInsideAppImage ? appImagePath : QCoreApplication.applicationFilePath ();
    
            QTextStream ts (&iniFile);
            ts.setCodec ("UTF-8");
            ts << QLatin1String ("[Desktop Entry]\n")
               << QLatin1String ("Name=") << guiName << QLatin1Char ('\n')
               << QLatin1String ("GenericName=") << QLatin1String ("File Synchronizer\n")
               << QLatin1String ("Exec=\"") << executablePath << "\" --background\n"
               << QLatin1String ("Terminal=") << "false\n"
               << QLatin1String ("Icon=") << APPLICATION_ICON_NAME << QLatin1Char ('\n')
               << QLatin1String ("Categories=") << QLatin1String ("Network\n")
               << QLatin1String ("Type=") << QLatin1String ("Application\n")
               << QLatin1String ("StartupNotify=") << "false\n"
               << QLatin1String ("X-GNOME-Autostart-enabled=") << "true\n"
               << QLatin1String ("X-GNOME-Autostart-Delay=10") << Qt.endl;
        } else {
            if (!QFile.remove (desktopFileLocation)) {
                qCWarning (lcUtility) << "Could not remove autostart desktop file";
            }
        }
    }
    
    static inline bool hasDarkSystray_private () {
        return true;
    }
    
    string Utility.getCurrentUserName () {
        return {};
    }
    
    } // namespace Occ
    