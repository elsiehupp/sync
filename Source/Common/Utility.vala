/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QStandardPaths>
// #include <QtGlobal>

// Note: This file must compile without QtGui
// #include <QCoreApplication>
// #include <QSettings>
// #include <QTextStream>
// #include <QDir>
// #include <QFile>
// #include <QUrl>
// #include <QProcess>
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

// #include <string>
// #include <QDateTime>
// #include <QElapsedTimer>
// #include <QLoggingCategory>
// #include <QMap>
// #include <QUrl>
// #include <QUrlQuery>
// #include <functional>
// #include <memory>


namespace Occ {


Q_DECLARE_LOGGING_CATEGORY (lc_utility)

/***********************************************************
\addtogroup libsync
 @{
***********************************************************/
namespace Utility {

    OCSYNC_EXPORT int rand ();

    OCSYNC_EXPORT void sleep (int sec);

    OCSYNC_EXPORT void usleep (int usec);

    OCSYNC_EXPORT string format_fingerprint (GLib.ByteArray , bool colon_separated = true);

    OCSYNC_EXPORT void setup_fav_link (string folder);

    OCSYNC_EXPORT void remove_fav_link (string folder);

    OCSYNC_EXPORT bool write_random_file (string fname, int size = -1);

    OCSYNC_EXPORT string octets_to_string (int64 octets);

    OCSYNC_EXPORT GLib.ByteArray user_agent_string ();

    OCSYNC_EXPORT GLib.ByteArray friendly_user_agent_string ();
    /***********************************************************
    @brief Return whether launch on startup is enabled system wide.

    If this returns true, the checkbox
    on startup will be hidden.

    Currently only implemented on Windows.
    ***********************************************************/

    OCSYNC_EXPORT bool has_system_launch_on_startup (string app_name);

    OCSYNC_EXPORT bool has_launch_on_startup (string app_name);

    OCSYNC_EXPORT void set_launch_on_startup (string app_name, string gui_name, bool launch);

    OCSYNC_EXPORT uint32 convert_size_to_uint (size_t &convert_var);

    OCSYNC_EXPORT int convert_size_to_int (size_t &convert_var);


    /***********************************************************
    Return the amount of free space available.

    \a path must point to a directory
    ***********************************************************/

    OCSYNC_EXPORT int64 free_disk_space (string path);


    /***********************************************************
    @brief compact_format_double - formats a double value human readable.

    @param value the value to
    @param prec the precision.
    @param unit an optional unit that is appended if present.
    @return the formatted string.
    ***********************************************************/

    OCSYNC_EXPORT string compact_format_double (double value, int prec, string unit = string ());

    // porting methods

    OCSYNC_EXPORT string escape (string );

    // conversion function QDateTime <. time_t   (because the ones builtin work on only unsigned 32bit)

    OCSYNC_EXPORT QDateTime q_date_time_from_time_t (int64 t);

    OCSYNC_EXPORT int64 q_date_time_to_time_t (QDateTime &t);


    /***********************************************************
    @brief Convert milliseconds duration to human readable string.
    @param uint64 msecs the milliseconds to convert to string.
    @return an HMS representation of the milliseconds value.

    duration_to_descriptive_string1 describ
    unit, like "5 minutes" or "2 days".

    duration_to_descriptive_string2 uses two units where possible, so
    "5 minutes 43 seconds" or "1 month 3 days".
    ***********************************************************/

    OCSYNC_EXPORT string duration_to_descriptive_string1 (uint64 msecs);

    OCSYNC_EXPORT string duration_to_descriptive_string2 (uint64 msecs);


    /***********************************************************
    @brief has_dark_systray - determines whether the systray is dark or light.

    Use this to check if the OS has a dark or a light systray.

    The value might change during the execution of the program
    (e.g. on OS X 10.10).

    @return bool which is true for systems with dark systray.
    ***********************************************************/

    OCSYNC_EXPORT bool has_dark_systray ();

    // convenience OS detection methods
    inline bool is_windows ();
    inline bool is_mac ();
    inline bool is_unix ();
    inline bool is_linux (); // use with care
    inline bool is_b_sD (); // use with care, does not match OS X

    OCSYNC_EXPORT string platform_name ();

    OCSYNC_EXPORTer for --debug
    OCSYNC_EXPORT void crash ();

    // Case preserving file system underneath?
    // if this function returns true, the file system is case preserving,
    // that means "test" means the same as "TEST" for filenames.
    // if false, the two cases are two different files.

    OCSYNC_EXPORT bool fs_case_preserving ();

    // Check if two pathes that MUST exist are equal. This function
    // uses QDir.canonical_path () to judge and cares for the systems
    // case sensitivity.

    OCSYNC_EXPORT bool file_names_equal (string fn1, string fn2);

    // Call the given command with the switch --version and rerun the first line
    // of the output.
    // If command is empty, the function calls the running application which, on
    // Linux, might have changed while this one is running.
    // For Mac and Windows, it returns string ()

    OCSYNC_EXPORT GLib.ByteArray version_of_installed_binary (string command = string ());

    OCSYNC_EXPORT

    OCSYNC_EXPORT string file_name_for_gui_use (string f_name);

    OCSYNC_EXPORT GLib.ByteArray normalize_etag (GLib.ByteArray etag);


    /***********************************************************
    @brief time_ago_in_words - human readable time span

    Use this to get a string that describes the timespan between the f
    the second timestamp in a human readable and understandable form.

    If the second parameter is ommitted, the current time is used.
    ***********************************************************/

    OCSYNC_EXPORT string time_ago_in_words (QDateTime &dt, QDateTime &from = QDateTime ());

    class StopWatch {

        private QMap<string, uint64> _lap_times;
        private QDateTime _start_time;
        private QElapsedTimer _timer;


        public void on_start ();
        public uint64 stop ();
        public uint64 add_lap_time (string lap_name);
        public void on_reset ();

        // out helpers, return the measured times.
        public QDateTime start_time ();
        public QDateTime time_of_lap (string lap_name);
        public uint64 duration_of_lap (string lap_name);
    };


    /***********************************************************
    @brief Sort a string[] in a way that's appropriate for filenames
    ***********************************************************/

    OCSYNC_EXPORT void sort_filenames (string[] &file_names);


    /***********************************************************
    Appends concat_path and query_items to the url
    ***********************************************************/

    OCSYNC_EXPORT QUrl concat_url_path (
        const QUrl url, string concat_path,
        const QUrlQuery &query_items = {});


    /***********************************************************
    Returns a new settings pre-set in a specific group.  The Settings will be created
    with the given parent. If no parent is specified, the caller must destroy the settings
    ***********************************************************/

    OCSYNC_EXPORT std.unique_ptr<QSettings> settings_with_group (string group, GLib.Object parent = nullptr);


    /***********************************************************
    Sanitizes a string that shall become part of a filename.

    Filters out reserved characters like
    - unicode control and format characters
    - reserved characters : /, ?, <, >, \, :, *, |, and "

    Warning : This does not sanitize the
    - unix reserved filenames ('.
    - trailing periods and spaces
    - windows reserved filenames ('CON' etc)
    will pass unchanged.
    ***********************************************************/

    OCSYNC_EXPORT string sanitize_for_file_name (string name);


    /***********************************************************
    Returns a file name based on \a fn that's suitable for a conflict.
    ***********************************************************/

    OCSYNC_EXPORT string make_conflict_file_name (
        const string fn, QDateTime &dt, string user);


    /***********************************************************
    Returns whether a file name indicates a conflict file
    ***********************************************************/

    OCSYNC_EXPORT bool is_conflict_file (char name);

    OCSYNC_EXPORT bool is_conflict_file (string name);


    /***********************************************************
    Find the base name for a conflict file name, using name pattern only

    Will return an empty string if it's not a conflict file.

    Prefer to use the data from the conflicts table in the journal to determine
    a conflict's base file, see SyncJournal.conflict_file_base_name ()
    ***********************************************************/

    OCSYNC_EXPORT GLib.ByteArray conflict_file_base_name_from_pattern (GLib.ByteArray conflict_name);


    /***********************************************************
    @brief Check whether the path is a root of a Windows drive partition ([c:/, d:/, e:/, etc.)
    ***********************************************************/

    OCSYNC_EXPORT bool is_path_windows_drive_partition_root (string path);


    /***********************************************************
    @brief Retrieves current logged-in user name from the OS
    ***********************************************************/

    OCSYNC_EXPORT string get_current_user_name ();
}


inline bool Utility.is_windows () {
    return false;
}

inline bool Utility.is_mac () {
    return false;
}

inline bool Utility.is_unix () {
    return true;

}

inline bool Utility.is_linux () {
    return true;
}

inline bool Utility.is_b_sD () {
    return false;
}




bool Utility.write_random_file (string fname, int size) {
    int max_size = 10 * 10 * 1024;

    if (size == -1)
        size = rand () % max_size;

    string rand_string;
    for (int i = 0; i < size; i++) {
        int r = rand () % 128;
        rand_string.append (QChar (r));
    }

    QFile file = new QFile (fname);
    if (file.open (QIODevice.WriteOnly | QIODevice.Text)) {
        QTextStream out (&file);
        out << rand_string;
        // optional, as QFile destructor will already do it:
        file.close ();
        return true;
    }
    return false;
}

string Utility.format_fingerprint (GLib.ByteArray fmhash, bool colon_separated) {
    GLib.ByteArray hash;
    int steps = fmhash.length () / 2;
    for (int i = 0; i < steps; i++) {
        hash.append (fmhash[i * 2]);
        hash.append (fmhash[i * 2 + 1]);
        hash.append (' ');
    }

    string fp = string.from_latin1 (hash.trimmed ());
    if (colon_separated) {
        fp.replace (QLatin1Char (' '), QLatin1Char (':'));
    }

    return fp;
}

void Utility.setup_fav_link (string folder) {
    setup_fav_link_private (folder);
}

void Utility.remove_fav_link (string folder) {
    remove_fav_link_private (folder);
}

string Utility.octets_to_string (int64 octets) {
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
        return s.arg (q_round (value));

    return s.arg (value, 0, 'g', 2);
}

// Qtified version of get_platforms () in csync_owncloud.c
static QLatin1String platform () {
    return QSysInfo.product_type ();
}

GLib.ByteArray Utility.user_agent_string () {
    return QStringLiteral ("Mozilla/5.0 (%1) mirall/%2 (%3, %4-%5 ClientArchitecture : %6 OsArchitecture : %7)")
        .arg (platform (),
            QStringLiteral (MIRALL_VERSION_STRING),
            q_app.application_name (),
            QSysInfo.product_type (),
            QSysInfo.kernel_version (),
            QSysInfo.build_cpu_architecture (),
            QSysInfo.current_cpu_architecture ())
        .to_latin1 ();
}

GLib.ByteArray Utility.friendly_user_agent_string () {
    const var pattern = QStringLiteral ("%1 (Desktop Client - %2)");
    const var user_agent = pattern.arg (QSysInfo.machine_host_name (), platform ());
    return user_agent.to_utf8 ();
}

bool Utility.has_system_launch_on_startup (string app_name) {
    Q_UNUSED (app_name)
    return false;
}

bool Utility.has_launch_on_startup (string app_name) {
    return has_launch_on_startup_private (app_name);
}

void Utility.set_launch_on_startup (string app_name, string gui_name, bool enable) {
    set_launch_on_startup_private (app_name, gui_name, enable);
}

int64 Utility.free_disk_space (string path) {
#if defined (Q_OS_UNIX)
    struct statvfs64 stat;
    if (statvfs64 (path.to_local8Bit ().data (), &stat) == 0) {
        return (int64)stat.f_bavail * stat.f_frsize;
    }
#endif
    return -1;
}

string Utility.compact_format_double (double value, int prec, string unit) {
    QLocale locale = QLocale.system ();
    QChar dec_point = locale.decimal_point ();
    string str = locale.to_string (value, 'f', prec);
    while (str.ends_with (QLatin1Char ('0')) || str.ends_with (dec_point)) {
        if (str.ends_with (dec_point)) {
            str.chop (1);
            break;
        }
        str.chop (1);
    }
    if (!unit.is_empty ())
        str += (QLatin1Char (' ') + unit);
    return str;
}

string Utility.escape (string in) {
    return in.to_html_escaped ();
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
OCSYNC_EXPORT bool fs_case_preserving_override = [] () . bool {
    GLib.ByteArray env = qgetenv ("OWNCLOUD_TEST_CASE_PRESERVING");
    if (!env.is_empty ())
        return env.to_int ();
    return Utility.is_windows () || Utility.is_mac ();
} ();

bool Utility.fs_case_preserving () {
    return fs_case_preserving_override;
}

bool Utility.file_names_equal (string fn1, string fn2) {
    const QDir fd1 (fn1);
    const QDir fd2 (fn2);

    // Attention : If the path does not exist, canonical_path returns ""
    // ONLY use this function with existing pathes.
    const string a = fd1.canonical_path ();
    const string b = fd2.canonical_path ();
    bool re = !a.is_empty () && string.compare (a, b, fs_case_preserving () ? Qt.CaseInsensitive : Qt.CaseSensitive) == 0;
    return re;
}

QDateTime Utility.q_date_time_from_time_t (int64 t) {
    return QDateTime.from_m_secs_since_epoch (t * 1000);
}

int64 Utility.q_date_time_to_time_t (QDateTime &t) {
    return t.to_m_secs_since_epoch () / 1000;
}

namespace {
    struct Period {
        const char name;
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

string Utility.duration_to_descriptive_string2 (uint64 msecs) {
    int p = 0;
    while (periods[p + 1].name && msecs < periods[p].msec) {
        p++;
    }

    var first_part = periods[p].description (int (msecs / periods[p].msec));

    if (!periods[p + 1].name) {
        return first_part;
    }

    uint64 second_part_num = q_round (double (msecs % periods[p].msec) / periods[p + 1].msec);

    if (second_part_num == 0) {
        return first_part;
    }

    return QCoreApplication.translate ("Utility", "%1 %2").arg (first_part, periods[p + 1].description (second_part_num));
}

string Utility.duration_to_descriptive_string1 (uint64 msecs) {
    int p = 0;
    while (periods[p + 1].name && msecs < periods[p].msec) {
        p++;
    }

    uint64 amount = q_round (double (msecs) / periods[p].msec);
    return periods[p].description (amount);
}

string Utility.file_name_for_gui_use (string f_name) {
    if (is_mac ()) {
        string n (f_name);
        return n.replace (QLatin1Char (':'), QLatin1Char ('/'));
    }
    return f_name;
}

GLib.ByteArray Utility.normalize_etag (GLib.ByteArray etag) {
    // strip "XXXX-gzip"
    if (etag.starts_with ('"') && etag.ends_with ("-gzip\"")) {
        etag.chop (6);
        etag.remove (0, 1);
    }
    // strip trailing -gzip
    if (etag.ends_with ("-gzip")) {
        etag.chop (5);
    }
    // strip normal quotes
    if (etag.starts_with ('"') && etag.ends_with ('"')) {
        etag.chop (1);
        etag.remove (0, 1);
    }
    etag.squeeze ();
    return etag;
}

bool Utility.has_dark_systray () {
    return has_dark_systray_private ();
}

string Utility.platform_name () {
    return QSysInfo.pretty_product_name ();
}

void Utility.crash () {
    volatile int a = (int *)nullptr;
    *a = 1;
}

// Use this functions to retrieve uint32/int (often required by Qt and WIN32) from size_t
// without compiler warnings about possible truncation
uint32 Utility.convert_size_to_uint (size_t &convert_var) {
    if (convert_var > UINT_MAX) {
        //throw std.bad_cast ();
        convert_var = UINT_MAX; // intentionally default to wrong value here to not crash : exception handling TBD
    }
    return static_cast<uint32> (convert_var);
}

int Utility.convert_size_to_int (size_t &convert_var) {
    if (convert_var > INT_MAX) {
        //throw std.bad_cast ();
        convert_var = INT_MAX; // intentionally default to wrong value here to not crash : exception handling TBD
    }
    return static_cast<int> (convert_var);
}

// read the output of the owncloud --version command from the owncloud
// version that is on disk. This works for most versions of the client,
// because clients that do not yet know the --version flag return the
// version in the first line of the help output :-)
//
// This version only delivers output on linux, as Mac and Win get their
// restarting from the installer.
GLib.ByteArray Utility.version_of_installed_binary (string command) {
    GLib.ByteArray re;
    if (is_linux ()) {
        string binary (command);
        if (binary.is_empty ()) {
            binary = q_app.arguments ()[0];
        }
        string[] params;
        params << QStringLiteral ("--version");
        QProcess process;
        process.on_start (binary, params);
        process.wait_for_finished (); // sets current thread to sleep and waits for ping_process end
        re = process.read_all_standard_output ();
        int newline = re.index_of ('\n');
        if (newline > 0) {
            re.truncate (newline);
        }
    }
    return re;
}

string Utility.time_ago_in_words (QDateTime &dt, QDateTime &from) {
    QDateTime now = QDateTime.current_date_time_utc ();

    if (from.is_valid ()) {
        now = from;
    }

    if (dt.days_to (now) == 1) {
        return GLib.Object.tr ("%n day ago", "", dt.days_to (now));
    } else if (dt.days_to (now) > 1) {
        return GLib.Object.tr ("%n days ago", "", dt.days_to (now));
    } else {
        int64 secs = dt.secs_to (now);
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
            int minutes = q_round (secs / 60.0);

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









static const char STOPWATCH_END_TAG[] = "_STOPWATCH_END";

void Utility.StopWatch.on_start () {
    _start_time = QDateTime.current_date_time_utc ();
    _timer.on_start ();
}

uint64 Utility.StopWatch.stop () {
    add_lap_time (QLatin1String (STOPWATCH_END_TAG));
    uint64 duration = _timer.elapsed ();
    _timer.invalidate ();
    return duration;
}

void Utility.StopWatch.on_reset () {
    _timer.invalidate ();
    _start_time.set_m_secs_since_epoch (0);
    _lap_times.clear ();
}

uint64 Utility.StopWatch.add_lap_time (string lap_name) {
    if (!_timer.is_valid ()) {
        on_start ();
    }
    uint64 re = _timer.elapsed ();
    _lap_times[lap_name] = re;
    return re;
}

QDateTime Utility.StopWatch.start_time () {
    return _start_time;
}

QDateTime Utility.StopWatch.time_of_lap (string lap_name) {
    uint64 t = duration_of_lap (lap_name);
    if (t) {
        QDateTime re (_start_time);
        return re.add_m_secs (t);
    }

    return QDateTime ();
}

uint64 Utility.StopWatch.duration_of_lap (string lap_name) {
    return _lap_times.value (lap_name, 0);
}

void Utility.sort_filenames (string[] &file_names) {
    QCollator collator;
    collator.set_numeric_mode (true);
    collator.set_case_sensitivity (Qt.CaseInsensitive);
    std.sort (file_names.begin (), file_names.end (), collator);
}

QUrl Utility.concat_url_path (QUrl url, string concat_path,
    const QUrlQuery &query_items) {
    string path = url.path ();
    if (!concat_path.is_empty ()) {
        // avoid '//'
        if (path.ends_with (QLatin1Char ('/')) && concat_path.starts_with (QLatin1Char ('/'))) {
            path.chop (1);
        } // avoid missing '/'
        else if (!path.ends_with (QLatin1Char ('/')) && !concat_path.starts_with (QLatin1Char ('/'))) {
            path += QLatin1Char ('/');
        }
        path += concat_path; // put the complete path together
    }

    QUrl tmp_url = url;
    tmp_url.set_path (path);
    tmp_url.set_query (query_items);
    return tmp_url;
}

string Utility.make_conflict_file_name (
    const string fn, QDateTime &dt, string user) {
    string conflict_file_name (fn);
    // Add conflict tag before the extension.
    int dot_location = conflict_file_name.last_index_of (QLatin1Char ('.'));
    // If no extension, add it at the end  (take care of cases like foo/.hidden or foo.bar/file)
    if (dot_location <= conflict_file_name.last_index_of (QLatin1Char ('/')) + 1) {
        dot_location = conflict_file_name.size ();
    }

    string conflict_marker = QStringLiteral (" (conflicted copy ");
    if (!user.is_empty ()) {
        // Don't allow parens in the user name, to ensure
        // we can find the beginning and end of the conflict tag.
        const var user_name = sanitize_for_file_name (user).replace (QLatin1Char (' ('), QLatin1Char ('_')).replace (QLatin1Char (')'), QLatin1Char ('_'));;
        conflict_marker += user_name + QLatin1Char (' ');
    }
    conflict_marker += dt.to_string (QStringLiteral ("yyyy-MM-dd hhmmss")) + QLatin1Char (')');

    conflict_file_name.insert (dot_location, conflict_marker);
    return conflict_file_name;
}

bool Utility.is_conflict_file (char name) {
    const char bname = std.strrchr (name, '/');
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

bool Utility.is_conflict_file (string name) {
    var bname = name.mid_ref (name.last_index_of (QLatin1Char ('/')) + 1);

    if (bname.contains (QStringLiteral ("_conflict-")))
        return true;

    if (bname.contains (QStringLiteral (" (conflicted copy")))
        return true;

    return false;
}

GLib.ByteArray Utility.conflict_file_base_name_from_pattern (GLib.ByteArray conflict_name) {
    // This function must be able to deal with conflict files for conflict files.
    // To do this, we scan backwards, for the outermost conflict marker and
    // strip only that to generate the conflict file base name.
    var start_old = conflict_name.last_index_of ("_conflict-");

    // A single space before " (conflicted copy" is considered part of the tag
    var start_new = conflict_name.last_index_of (" (conflicted copy");
    if (start_new > 0 && conflict_name[start_new - 1] == ' ')
        start_new -= 1;

    // The rightmost tag is relevant
    var tag_start = q_max (start_old, start_new);
    if (tag_start == -1)
        return "";

    // Find the end of the tag
    var tag_end = conflict_name.size ();
    var dot = conflict_name.last_index_of ('.'); // dot could be part of user name for new tag!
    if (dot > tag_start)
        tag_end = dot;
    if (tag_start == start_new) {
        var paren = conflict_name.index_of (')', tag_start);
        if (paren != -1)
            tag_end = paren + 1;
    }
    return conflict_name.left (tag_start) + conflict_name.mid (tag_end);
}

bool Utility.is_path_windows_drive_partition_root (string path) {
    Q_UNUSED (path)
    return false;
}

string Utility.sanitize_for_file_name (string name) {
    const var invalid = QStringLiteral (R" (/?<>\:*|\")");
    string result;
    result.reserve (name.size ());
    for (var c : name) {
        if (!invalid.contains (c)
            && c.category () != QChar.Other_Control
            && c.category () != QChar.Other_Format) {
            result.append (c);
        }
    }
    return result;
}



    static void setup_fav_link_private (string folder) {
        // Nautilus : add to ~/.gtk-bookmarks
        QFile gtk_bookmarks (QDir.home_path () + QLatin1String ("/.config/gtk-3.0/bookmarks"));
        GLib.ByteArray folder_url = "file://" + folder.to_utf8 ();
        if (gtk_bookmarks.open (QFile.ReadWrite)) {
            GLib.ByteArray places = gtk_bookmarks.read_all ();
            if (!places.contains (folder_url)) {
                places += folder_url;
                gtk_bookmarks.on_reset ();
                gtk_bookmarks.write (places + '\n');
            }
        }
    }

    static void remove_fav_link_private (string folder) {
        Q_UNUSED (folder)
    }

    // returns the autostart directory the linux way
    // and respects the XDG_CONFIG_HOME env variable
    string get_user_autostart_dir_private () {
        string config = QStandardPaths.writable_location (QStandardPaths.ConfigLocation);
        config += QLatin1String ("/autostart/");
        return config;
    }

    bool has_launch_on_startup_private (string app_name) {
        Q_UNUSED (app_name)
        string desktop_file_location = get_user_autostart_dir_private ()
                                        + QLatin1String (LINUX_APPLICATION_ID)
                                        + QLatin1String (".desktop");
        return QFile.exists (desktop_file_location);
    }

    void set_launch_on_startup_private (string app_name, string gui_name, bool enable) {
        Q_UNUSED (app_name)
        string user_auto_start_path = get_user_autostart_dir_private ();
        string desktop_file_location = user_auto_start_path
                                        + QLatin1String (LINUX_APPLICATION_ID)
                                        + QLatin1String (".desktop");
        if (enable) {
            if (!QDir ().exists (user_auto_start_path) && !QDir ().mkpath (user_auto_start_path)) {
                q_c_warning (lc_utility) << "Could not create autostart folder" << user_auto_start_path;
                return;
            }
            QFile ini_file (desktop_file_location);
            if (!ini_file.open (QIODevice.WriteOnly)) {
                q_c_warning (lc_utility) << "Could not write var on_start entry" << desktop_file_location;
                return;
            }
            // When running inside an AppImage, we need to set the path to the
            // AppImage instead of the path to the executable
            const string app_image_path = q_environment_variable ("APPIMAGE");
            const bool running_inside_app_image = !app_image_path.is_null () && QFile.exists (app_image_path);
            const string executable_path = running_inside_app_image ? app_image_path : QCoreApplication.application_file_path ();

            QTextStream ts (&ini_file);
            ts.set_codec ("UTF-8");
            ts << QLatin1String ("[Desktop Entry]\n")
               << QLatin1String ("Name=") << gui_name << QLatin1Char ('\n')
               << QLatin1String ("GenericName=") << QLatin1String ("File Synchronizer\n")
               << QLatin1String ("Exec=\"") << executable_path << "\" --background\n"
               << QLatin1String ("Terminal=") << "false\n"
               << QLatin1String ("Icon=") << APPLICATION_ICON_NAME << QLatin1Char ('\n')
               << QLatin1String ("Categories=") << QLatin1String ("Network\n")
               << QLatin1String ("Type=") << QLatin1String ("Application\n")
               << QLatin1String ("StartupNotify=") << "false\n"
               << QLatin1String ("X-GNOME-Autostart-enabled=") << "true\n"
               << QLatin1String ("X-GNOME-Autostart-Delay=10") << Qt.endl;
        } else {
            if (!QFile.remove (desktop_file_location)) {
                q_c_warning (lc_utility) << "Could not remove autostart desktop file";
            }
        }
    }

    static inline bool has_dark_systray_private () {
        return true;
    }

    string Utility.get_current_user_name () {
        return {};
    }

    } // namespace Occ
    