/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>
//  #include <QRegularExpression>
//  #include <QtGlobal>
//  #include <QTextCodec>
//  #include <qmetaobject.h>
//  #include <iostream>

//  #ifdef ZLIB_FOUND
//  using ZLib
//  #endif

//  #include <QTextStream>
//  #include <qmutex.h>

namespace Occ {

/***********************************************************
@brief The Logger class
@ingroup libsync
***********************************************************/
class Logger : GLib.Object {

    const int CRASH_LOG_SIZE = 20;

    /***********************************************************
    ***********************************************************/
    private GLib.File log_file;
    private bool do_file_flush = false;
    private int log_expire = 0;
    private bool log_debug = false;
    private QScopedPointer<QTextStream> logstream;
    private mutable QMutex mutex;
    private string log_directory;
    private bool temporary_folder_log_dir = false;
    private GLib.Set<string> log_rules;
    private GLib.Vector<string> crash_log;
    private int crash_log_index = 0;

    signal void log_window_log (string value);
    signal void gui_log (string value_1, string value_2);
    signal void gui_message (string value_1, string value_2);
    signal void optional_gui_log (string value_1, string value_2);


    /***********************************************************
    ***********************************************************/
    private Logger (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        q_set_message_pattern (QStringLiteral ("%{time yyyy-MM-dd hh:mm:ss:zzz} [ %{type} %{category} %{file}:%{line} "
                                        "]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}"));
        this.crash_log.resize (CRASH_LOG_SIZE);
    #ifndef NO_MSG_HANDLER
        q_install_message_handler ([] (QtMsgType type, QMessageLogContext context, string message) {
                Logger.instance ().do_log (type, context, message);
            });
    #endif
    }


    ~Logger () {
    #ifndef NO_MSG_HANDLER
        q_install_message_handler (null);
    #endif
    }


    /***********************************************************
    ***********************************************************/
    public static Logger instance () {
        static Logger log;
        return log;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_logging_to_file () {
        QMutexLocker lock (&this.mutex);
        return this.logstream;
    }


    /***********************************************************
    ***********************************************************/
    public void do_log (QtMsgType type, QMessageLogContext context, string message) {
        const string message = q_format_log_message (type, context, message);
        {
            QMutexLocker lock (&this.mutex);
            this.crash_log_index = (this.crash_log_index + 1) % CRASH_LOG_SIZE;
            this.crash_log[this.crash_log_index] = message;
            if (this.logstream) {
                (*this.logstream) << message << Qt.endl;
                if (this.do_file_flush)
                    this.logstream.flush ();
            }
            if (type == QtFatalMsg) {
                close ();
            }
        }
        /* emit */ log_window_log (message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_gui_log (string title, string message) {
        /* emit */ gui_log (title, message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_optional_gui_log (string title, string message) {
        /* emit */ optional_gui_log (title, message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_gui_message (string title, string message) {
        /* emit */ gui_message (title, message);
    }


    /***********************************************************
    ***********************************************************/
    void close () {
        dump_crash_log ();
        if (this.logstream) {
            this.logstream.flush ();
            this.log_file.close ();
            this.logstream.on_reset ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public string log_file () {
        return this.log_file.filename ();
    }


    /***********************************************************
    ***********************************************************/
    public void set_log_file (string name) {
        QMutexLocker locker = new QMutexLocker (&this.mutex);
        if (this.logstream) {
            this.logstream.on_reset (null);
            this.log_file.close ();
        }

        if (name.is_empty ()) {
            return;
        }

        bool open_succeeded = false;
        if (name == QLatin1String ("-")) {
            open_succeeded = this.log_file.open (stdout, QIODevice.WriteOnly);
        } else {
            this.log_file.set_filename (name);
            open_succeeded = this.log_file.open (QIODevice.WriteOnly);
        }

        if (!open_succeeded) {
            locker.unlock (); // Just in case post_gui_message has a GLib.debug ()
            post_gui_message (_("Error"),
                string (_("<nobr>File \"%1\"<br/>cannot be opened for writing.<br/><br/>"
                        "The log output <b>cannot</b> be saved!</nobr>"))
                    .arg (name));
            return;
        }

        this.logstream.on_reset (new QTextStream (&this.log_file));
        this.logstream.set_codec (QTextCodec.codec_for_name ("UTF-8"));
    }


    /***********************************************************
    ***********************************************************/
    public void set_log_expire (int expire) {
        this.log_expire = expire;
    }


    /***********************************************************
    ***********************************************************/
    public string log_dir () {
        return this.log_directory;
    }


    /***********************************************************
    ***********************************************************/
    public void set_log_dir (string dir) {
        this.log_directory = dir;
    }


    /***********************************************************
    ***********************************************************/
    public void set_log_flush (bool flush) {
        this.do_file_flush = flush;
    }


    /***********************************************************
    ***********************************************************/
    public bool log_debug () {
        return this.log_debug;
    }


    /***********************************************************
    ***********************************************************/
    public void set_log_debug (bool debug) {
        const GLib.Set<string> rules = {debug ? QStringLiteral ("nextcloud.*.debug=true") : ""};
        if (debug) {
            add_log_rule (rules);
        } else {
            remove_log_rule (rules);
        }
        this.log_debug = debug;
    }


    /***********************************************************
    Returns where the automatic logdir would be
    ***********************************************************/
    public string temporary_folder_log_dir_path () {
        return QDir.temp ().file_path (QStringLiteral (APPLICATION_SHORTNAME "-logdir"));
    }


    /***********************************************************
    Sets up default dir log setup.

    logdir: a temporary folder
    logexpire: 4 hours
    logdebug: true

    Used in conjunction with ConfigFile.automatic_log_dir
    ***********************************************************/
    public void setup_temporary_folder_log_dir () {
        var dir = temporary_folder_log_dir_path ();
        if (!QDir ().mkpath (dir))
            return;
        set_log_debug (true);
        set_log_expire (4 /*hours*/);
        set_log_dir (dir);
        this.temporary_folder_log_dir = true;
    }


    /***********************************************************
    For switching off via logwindow
    ***********************************************************/
    public void disable_temporary_folder_log_dir () {
        if (!this.temporary_folder_log_dir)
            return;

        on_enter_next_log_file ();
        set_log_dir ("");
        set_log_debug (false);
        set_log_file ("");
        this.temporary_folder_log_dir = false;
    }


    /***********************************************************
    ***********************************************************/
    public void add_log_rule (GLib.Set<string> rules) {
        set_log_rules (this.log_rules + rules);
    }


    /***********************************************************
    ***********************************************************/
    public void remove_log_rule (GLib.Set<string> rules) { }


    /***********************************************************
    ***********************************************************/
    public void set_log_rules (GLib.Set<string> rules) {
        this.log_rules = rules;
        string tmp;
        QTextStream out (&tmp);
        for (var p : rules) {
            out << p << '\n';
        }
        GLib.debug () << tmp;
        QLoggingCategory.set_filter_rules (tmp);
    }


    /***********************************************************
    ***********************************************************/
    public void on_enter_next_log_file () {
        if (!this.log_directory.is_empty ()) {

            QDir dir (this.log_directory);
            if (!dir.exists ()) {
                dir.mkpath (".");
            }

            // Tentative new log name, will be adjusted if one like this already exists
            GLib.DateTime now = GLib.DateTime.current_date_time ();
            string new_log_name = now.to_string ("yyyy_mMdd_HHmm") + "this.owncloud.log";

            // Expire old log files and deal with conflicts
            string[] files = dir.entry_list (string[] ("*owncloud.log.*"),
                QDir.Files, QDir.Name);
            const QRegularExpression rx (QRegularExpression.anchored_pattern (R" (.*owncloud\.log\. (\d+).*)"));
            int max_number = -1;
            foreach (string s, files) {
                if (this.log_expire > 0) {
                    QFileInfo file_info (dir.absolute_file_path (s));
                    if (file_info.last_modified ().add_secs (60 * 60 * this.log_expire) < now) {
                        dir.remove (s);
                    }
                }
                const var rx_match = rx.match (s);
                if (s.starts_with (new_log_name) && rx_match.has_match ()) {
                    max_number = q_max (max_number, rx_match.captured (1).to_int ());
                }
            }
            new_log_name.append ("." + string.number (max_number + 1));

            var previous_log = this.log_file.filename ();
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


    /***********************************************************
    ***********************************************************/
    private static bool compress_log (string original_name, string target_name) {
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


    /***********************************************************
    ***********************************************************/
    private void dump_crash_log () {
        GLib.File log_file (QDir.temp_path () + QStringLiteral ("/" APPLICATION_NAME "-crash.log"));
        if (log_file.open (GLib.File.WriteOnly)) {
            QTextStream out (&log_file);
            for (int i = 1; i <= CRASH_LOG_SIZE; ++i) {
                out << this.crash_log[ (this.crash_log_index + i) % CRASH_LOG_SIZE] << '\n';
            }
        }
    }

} // class Logger

} // namespace Occ
