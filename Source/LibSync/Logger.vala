/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QRegularExpression>
// #include <string[]>
// #include <QtGlobal>
// #include <QTextCodec>
// #include <qmetaobject.h>

// #include <iostream>

#ifdef ZLIB_FOUND
using ZLib
#endif

namespace {
constexpr int CrashLogSize = 20;
}

// #include <GLib.List>
// #include <QDateTime>
// #include <GLib.File>
// #include <QTextStream>
// #include <qmutex.h>

namespace Occ {

/***********************************************************
@brief The Logger class
@ingroup libsync
***********************************************************/
class Logger : GLib.Object {

    public bool is_logging_to_file ();

    public void do_log (QtMsgType type, QMessageLogContext &ctx, string message);

    public static Logger instance ();

    public void post_gui_log (string title, string message);


    public void post_optional_gui_log (string title, string message);


    public void post_gui_message (string title, string message);

    public string log_file ();


    public void set_log_file (string name);

    public void set_log_expire (int expire);

    public string log_dir ();


    public void set_log_dir (string dir);

    public void set_log_flush (bool flush);

    public bool log_debug () {
        return _log_debug;
    }
    public void set_log_debug (bool debug);


    /***********************************************************
    Returns where the automatic logdir would be
    ***********************************************************/
    public string temporary_folder_log_dir_path ();


    /***********************************************************
    Sets up default dir log setup.

    logdir: a temporary folder
    logexpire: 4 hours
    logdebug: true

    Used in conjunction with ConfigFile.automatic_log_dir
    ***********************************************************/
    public void setup_temporary_folder_log_dir ();


    /***********************************************************
    For switching off via logwindow
    ***********************************************************/
    public void disable_temporary_folder_log_dir ();

    public void add_log_rule (GLib.Set<string> &rules) {
        set_log_rules (_log_rules + rules);
    }
    public void remove_log_rule (GLib.Set<string> &rules) {
        set_log_rules (_log_rules - rules);
    }
    public void set_log_rules (GLib.Set<string> &rules);

signals:
    void log_window_log (string );

    void gui_log (string , string );
    void gui_message (string , string );
    void optional_gui_log (string , string );


    public void on_enter_next_log_file ();


    private Logger (GLib.Object parent = nullptr);
    ~Logger () override;

    private void close ();
    private void dump_crash_log ();

    private GLib.File _log_file;
    private bool _do_file_flush = false;
    private int _log_expire = 0;
    private bool _log_debug = false;
    private QScopedPointer<QTextStream> _logstream;
    private mutable QMutex _mutex;
    private string _log_directory;
    private bool _temporary_folder_log_dir = false;
    private GLib.Set<string> _log_rules;
    private QVector<string> _crash_log;
    private int _crash_log_index = 0;
};

Logger *Logger.instance () {
    static Logger log;
    return &log;
}

Logger.Logger (GLib.Object parent) {
    base (parent);
    q_set_message_pattern (QStringLiteral ("%{time yyyy-MM-dd hh:mm:ss:zzz} [ %{type} %{category} %{file}:%{line} "
                                      "]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}"));
    _crash_log.resize (CrashLogSize);
#ifndef NO_MSG_HANDLER
    q_install_message_handler ([] (QtMsgType type, QMessageLogContext &ctx, string message) {
            Logger.instance ().do_log (type, ctx, message);
        });
#endif
}

Logger.~Logger () {
#ifndef NO_MSG_HANDLER
    q_install_message_handler (nullptr);
#endif
}

void Logger.post_gui_log (string title, string message) {
    emit gui_log (title, message);
}

void Logger.post_optional_gui_log (string title, string message) {
    emit optional_gui_log (title, message);
}

void Logger.post_gui_message (string title, string message) {
    emit gui_message (title, message);
}

bool Logger.is_logging_to_file () {
    QMutexLocker lock (&_mutex);
    return _logstream;
}

void Logger.do_log (QtMsgType type, QMessageLogContext &ctx, string message) {
    const string msg = q_format_log_message (type, ctx, message);
    {
        QMutexLocker lock (&_mutex);
        _crash_log_index = (_crash_log_index + 1) % CrashLogSize;
        _crash_log[_crash_log_index] = msg;
        if (_logstream) {
            (*_logstream) << msg << Qt.endl;
            if (_do_file_flush)
                _logstream.flush ();
        }
        if (type == QtFatalMsg) {
            close ();
        }
    }
    emit log_window_log (msg);
}

void Logger.close () {
    dump_crash_log ();
    if (_logstream) {
        _logstream.flush ();
        _log_file.close ();
        _logstream.on_reset ();
    }
}

string Logger.log_file () {
    return _log_file.file_name ();
}

void Logger.set_log_file (string name) {
    QMutexLocker locker = new QMutexLocker (&_mutex);
    if (_logstream) {
        _logstream.on_reset (nullptr);
        _log_file.close ();
    }

    if (name.is_empty ()) {
        return;
    }

    bool open_succeeded = false;
    if (name == QLatin1String ("-")) {
        open_succeeded = _log_file.open (stdout, QIODevice.WriteOnly);
    } else {
        _log_file.set_file_name (name);
        open_succeeded = _log_file.open (QIODevice.WriteOnly);
    }

    if (!open_succeeded) {
        locker.unlock (); // Just in case post_gui_message has a q_debug ()
        post_gui_message (_("Error"),
            string (_("<nobr>File \"%1\"<br/>cannot be opened for writing.<br/><br/>"
                       "The log output <b>cannot</b> be saved!</nobr>"))
                .arg (name));
        return;
    }

    _logstream.on_reset (new QTextStream (&_log_file));
    _logstream.set_codec (QTextCodec.codec_for_name ("UTF-8"));
}

void Logger.set_log_expire (int expire) {
    _log_expire = expire;
}

string Logger.log_dir () {
    return _log_directory;
}

void Logger.set_log_dir (string dir) {
    _log_directory = dir;
}

void Logger.set_log_flush (bool flush) {
    _do_file_flush = flush;
}

void Logger.set_log_debug (bool debug) {
    const GLib.Set<string> rules = {debug ? QStringLiteral ("nextcloud.*.debug=true") : string ()};
    if (debug) {
        add_log_rule (rules);
    } else {
        remove_log_rule (rules);
    }
    _log_debug = debug;
}

string Logger.temporary_folder_log_dir_path () {
    return QDir.temp ().file_path (QStringLiteral (APPLICATION_SHORTNAME "-logdir"));
}

void Logger.setup_temporary_folder_log_dir () {
    var dir = temporary_folder_log_dir_path ();
    if (!QDir ().mkpath (dir))
        return;
    set_log_debug (true);
    set_log_expire (4 /*hours*/);
    set_log_dir (dir);
    _temporary_folder_log_dir = true;
}

void Logger.disable_temporary_folder_log_dir () {
    if (!_temporary_folder_log_dir)
        return;

    on_enter_next_log_file ();
    set_log_dir (string ());
    set_log_debug (false);
    set_log_file (string ());
    _temporary_folder_log_dir = false;
}

void Logger.set_log_rules (GLib.Set<string> &rules) {
    _log_rules = rules;
    string tmp;
    QTextStream out (&tmp);
    for (var &p : rules) {
        out << p << '\n';
    }
    q_debug () << tmp;
    QLoggingCategory.set_filter_rules (tmp);
}

void Logger.dump_crash_log () {
    GLib.File log_file (QDir.temp_path () + QStringLiteral ("/" APPLICATION_NAME "-crash.log"));
    if (log_file.open (GLib.File.WriteOnly)) {
        QTextStream out (&log_file);
        for (int i = 1; i <= CrashLogSize; ++i) {
            out << _crash_log[ (_crash_log_index + i) % CrashLogSize] << '\n';
        }
    }
}

static bool compress_log (string original_name, string target_name) {
#ifdef ZLIB_FOUND
    GLib.File original (original_name);
    if (!original.open (QIODevice.ReadOnly))
        return false;
    var compressed = gzopen (target_name.to_utf8 (), "wb");
    if (!compressed) {
        return false;
    }

    while (!original.at_end ()) {
        var data = original.read (1024 * 1024);
        var written = gzwrite (compressed, data.data (), data.size ());
        if (written != data.size ()) {
            gzclose (compressed);
            return false;
        }
    }
    gzclose (compressed);
    return true;
#else
    return false;
#endif
}

void Logger.on_enter_next_log_file () {
    if (!_log_directory.is_empty ()) {

        QDir dir (_log_directory);
        if (!dir.exists ()) {
            dir.mkpath (".");
        }

        // Tentative new log name, will be adjusted if one like this already exists
        QDateTime now = QDateTime.current_date_time ();
        string new_log_name = now.to_string ("yyyy_mMdd_HHmm") + "_owncloud.log";

        // Expire old log files and deal with conflicts
        string[] files = dir.entry_list (string[] ("*owncloud.log.*"),
            QDir.Files, QDir.Name);
        const QRegularExpression rx (QRegularExpression.anchored_pattern (R" (.*owncloud\.log\. (\d+).*)"));
        int max_number = -1;
        foreach (string s, files) {
            if (_log_expire > 0) {
                QFileInfo file_info (dir.absolute_file_path (s));
                if (file_info.last_modified ().add_secs (60 * 60 * _log_expire) < now) {
                    dir.remove (s);
                }
            }
            const var rx_match = rx.match (s);
            if (s.starts_with (new_log_name) && rx_match.has_match ()) {
                max_number = q_max (max_number, rx_match.captured (1).to_int ());
            }
        }
        new_log_name.append ("." + string.number (max_number + 1));

        var previous_log = _log_file.file_name ();
        set_log_file (dir.file_path (new_log_name));

        // Compress the previous log file. On a restart this can be the most recent
        // log file.
        var log_to_compress = previous_log;
        if (log_to_compress.is_empty () && files.size () > 0 && !files.last ().ends_with (".gz"))
            log_to_compress = dir.absolute_file_path (files.last ());
        if (!log_to_compress.is_empty ()) {
            string compressed_name = log_to_compress + ".gz";
            if (compress_log (log_to_compress, compressed_name)) {
                GLib.File.remove (log_to_compress);
            } else {
                GLib.File.remove (compressed_name);
            }
        }
    }
}

} // namespace Occ
