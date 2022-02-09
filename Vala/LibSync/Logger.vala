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

    private GLib.File log_file_object;
    /***********************************************************
    ***********************************************************/
    string log_file {
        public get {
            return this.log_file_object.filename ();
        }
        public set {
            QMutexLocker locker = new QMutexLocker (&this.mutex);
            if (this.logstream) {
                this.logstream.on_signal_reset (null);
                this.log_file_object.close ();
            }
    
            if (value.is_empty ()) {
                return;
            }
    
            bool open_succeeded = false;
            if (value == QLatin1String ("-")) {
                open_succeeded = this.log_file_object.open (stdout, QIODevice.WriteOnly);
            } else {
                this.log_file_object.filename (value);
                open_succeeded = this.log_file_object.open (QIODevice.WriteOnly);
            }
    
            if (!open_succeeded) {
                locker.unlock (); // Just in case post_gui_message has a GLib.debug ()
                post_gui_message (_("Error"),
                    _("<nobr>File \"%1\"<br/>cannot be opened for writing.<br/><br/>"
                    + "The log output <b>cannot</b> be saved!</nobr>")
                        .arg (value));
                return;
            }
    
            this.logstream.on_signal_reset (new QTextStream (&this.log_file));
            this.logstream.codec (QTextCodec.codec_for_name ("UTF-8"));
        }
    }

    private bool do_file_flush = false;
    int log_expire { private get; public set; }
    bool log_debug {
        public get {
            return this.log_debug;
        }
        public set {
            const GLib.List<string> rules = {value ? QStringLiteral ("nextcloud.*.debug=true") : ""};
            if (value) {
                add_log_rule (rules);
            } else {
                remove_log_rule (rules);
            }
            this.log_debug = value;
        }
    }

    private QScopedPointer<QTextStream> logstream;
    private mutable QMutex mutex;
    public string log_directory;
    private bool temporary_folder_log_dir = false;

    GLib.List<string> log_rules {
        private get {
            return this.log_rules;
        }
        public set {
            this.log_rules = value;
            string tmp;
            QTextStream output (&tmp);
            foreach (var p in value) {
                output + p + '\n';
            }
            GLib.debug (tmp);
            QLoggingCategory.filter_rules (tmp);
        }
    }

    private GLib.Vector<string> crash_log;
    private int crash_log_index = 0;

    signal void log_window_log (string value);
    signal void signal_gui_log (string value_1, string value_2);
    signal void gui_message (string value_1, string value_2);
    signal void optional_gui_log (string value_1, string value_2);


    /***********************************************************
    ***********************************************************/
    private Logger (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.log_debug = false;
        this.log_expire = 0;
        q_message_pattern ("%{time yyyy-MM-dd hh:mm:ss:zzz} [ %{type} %{category} %{file}:%{line} "
                            + "]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}");
        this.crash_log.resize (CRASH_LOG_SIZE);
    // #ifndef NO_MSG_HANDLER
        q_install_message_handler ((QtMsgType type, QMessageLogContext context, string message) => {
            Logger.instance ().do_log (type, context, message);
        });
    // #endif
    }


    ~Logger () {
    // #ifndef NO_MSG_HANDLER
        q_install_message_handler (null);
    // #endif
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
                (*this.logstream) + message + Qt.endl;
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
        /* emit */ signal_gui_log (title, message);
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
        if (this.logstream != null) {
            this.logstream.flush ();
            this.log_file_object.close ();
            this.logstream.on_signal_reset ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void log_flush (bool flush) {
        this.do_file_flush = flush;
    }


    /***********************************************************
    Returns where the automatic logdir would be
    ***********************************************************/
    public string temporary_folder_log_dir_path () {
        return QDir.temp ().file_path (APPLICATION_SHORTNAME + "-logdir");
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
        if (!QDir ().mkpath (dir)) {
            return;
        }
        this.log_debug = true;
        this.log_expire = 4; /*hours*/
        this.log_directory = dir;
        this.temporary_folder_log_dir = true;
    }


    /***********************************************************
    For switching off via logwindow
    ***********************************************************/
    public void disable_temporary_folder_log_dir () {
        if (!this.temporary_folder_log_dir)
            return;

        on_signal_enter_next_log_file ();
        this.log_directory = "";
        this.log_debug = false;
        this.log_file = "";
        this.temporary_folder_log_dir = false;
    }


    /***********************************************************
    ***********************************************************/
    public void add_log_rule (GLib.List<string> rules) {
        this.log_rules = this.log_rules + rules;
    }


    /***********************************************************
    ***********************************************************/
    public void remove_log_rule (GLib.List<string> rules) { }


    /***********************************************************
    ***********************************************************/
    public void on_signal_enter_next_log_file () {
        if (!this.log_directory == "") {

            QDir dir = new QDir (this.log_directory);
            if (!dir.exists ()) {
                dir.mkpath (".");
            }

            // Tentative new log name, will be adjusted if one like this already exists
            GLib.DateTime now = GLib.DateTime.current_date_time ();
            string new_log_name = now.to_string () + "yyyy_mMdd_HHmm" + "_owncloud.log";

            // Expire old log files and deal with conflicts
            GLib.List<string> files = dir.entry_list (GLib.List<string> ("*owncloud.log.*"),
                QDir.Files, QDir.Name);
            const QRegularExpression regex = new QRegularExpression (QRegularExpression.anchored_pattern (R" (.*owncloud\.log\. (\d+).*)"));
            int max_number = -1;
            foreach (string s in files) {
                if (this.log_expire > 0) {
                    QFileInfo file_info = new QFileInfo (dir.absolute_file_path (s));
                    if (file_info.last_modified ().add_secs (60 * 60 * this.log_expire) < now) {
                        dir.remove (s);
                    }
                }
                var rx_match = regex.match (s);
                if (s.starts_with (new_log_name) && rx_match.has_match ()) {
                    max_number = q_max (max_number, rx_match.captured (1).to_int ());
                }
            }
            new_log_name.append ("." + string.number (max_number + 1));

            var previous_log = this.log_file_object.filename ();
            this.log_file = dir.file_path (new_log_name);

            // Compress the previous log file. On a restart this can be the most recent
            // log file.
            var log_to_compress = previous_log;
            if (log_to_compress.is_empty () && files.size () > 0 && !files.last ().has_suffix (".gz"))
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
    // #ifdef ZLIB_FOUND
        GLib.File original = new GLib.File (original_name);
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
    // #else
        return false;
    // #endif
    }


    /***********************************************************
    ***********************************************************/
    private void dump_crash_log () {
        GLib.File log_file = new GLib.File (QDir.temp_path () + "/" + APPLICATION_NAME + "-crash.log");
        if (log_file_object.open (GLib.File.WriteOnly)) {
            QTextStream output = new QTextStream (&log_file);
            for (int i = 1; i <= CRASH_LOG_SIZE; ++i) {
                output + this.crash_log[ (this.crash_log_index + i) % CRASH_LOG_SIZE] + '\n';
            }
        }
    }

} // class Logger

} // namespace Occ