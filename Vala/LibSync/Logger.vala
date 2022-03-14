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
namespace LibSync {

/***********************************************************
@brief The Logger class
@ingroup libsync
***********************************************************/
public class Logger : GLib.Object {

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
                this.logstream.reset (null);
                this.log_file_object.close ();
            }
    
            if (value == "") {
                return;
            }
    
            bool open_succeeded = false;
            if (value == "-") {
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
                        .printf (value));
                return;
            }
    
            this.logstream.reset (new QTextStream (&this.log_file));
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
            const GLib.List<string> rules = {value ? "nextcloud.*.debug=true": ""};
            if (value) {
                add_log_rule (rules);
            } else {
                remove_log_rule (rules);
            }
            this.log_debug = value;
        }
    }

    private QScopedPointer<QTextStream> logstream;
    private /*mutable*/ QMutex mutex;
    public string log_directory;
    private bool temporary_folder_log_dir = false;

    GLib.List<string> log_rules {
        private get {
            return this.log_rules;
        }
        public set {
            this.log_rules = value;
            string tmp;
            QTextStream output = new QTextStream (tmp);
            foreach (var p in value) {
                output += p + '\n';
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
        q_install_message_handler (message_handler);
    // #endif
    }


    private void message_handler (QtMsgType type, QMessageLogContext context, string message) {
        Logger.instance.do_log (type, context, message);
    }


    ~Logger () {
    // #ifndef NO_MSG_HANDLER
        q_install_message_handler (null);
    // #endif
    }

    static Logger log;

    /***********************************************************
    ***********************************************************/
    public static Logger instance {
        return Logger.log;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_logging_to_file () {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        return this.logstream;
    }


    /***********************************************************
    ***********************************************************/
    public void do_log (QtMsgType type, QMessageLogContext context, string message) {
        const string message = q_format_log_message (type, context, message);
        {
            QMutexLocker lock = new QMutexLocker (this.mutex);
            this.crash_log_index = (this.crash_log_index + 1) % CRASH_LOG_SIZE;
            this.crash_log[this.crash_log_index] = message;
            if (this.logstream) {
                (*this.logstream) + message + Qt.endl;
                if (this.do_file_flush) {
                    this.logstream.flush ();
                }
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
            this.logstream.reset ();
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
    Sets up default directory log setup.

    logdir: a temporary folder
    logexpire: 4 hours
    logdebug: true

    Used in conjunction with ConfigFile.automatic_log_dir
    ***********************************************************/
    public void setup_temporary_folder_log_dir () {
        var directory = temporary_folder_log_dir_path ();
        if (!QDir ().mkpath (directory)) {
            return;
        }
        this.log_debug = true;
        this.log_expire = 4; /*hours*/
        this.log_directory = directory;
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

            QDir directory = new QDir (this.log_directory);
            if (!directory.exists ()) {
                directory.mkpath (".");
            }

            // Tentative new log name, will be adjusted if one like this already exists
            GLib.DateTime now = GLib.DateTime.current_date_time ();
            string new_log_name = now.to_string () + "yyyy_mMdd_HHmm" + "_owncloud.log";

            // Expire old log files and deal with conflicts
            GLib.List<string> files = directory.entry_list (GLib.List<string> ("*owncloud.log.*"),
                QDir.Files, QDir.Name);
            const QRegularExpression regex = new QRegularExpression (QRegularExpression.anchored_pattern (" (.*owncloud\.log\. (\d+).*)"));
            int max_number = -1;
            foreach (string s in files) {
                if (this.log_expire > 0) {
                    GLib.FileInfo file_info = GLib.File.new_for_path (directory.absolute_file_path (s));
                    if (file_info.last_modified ().add_secs (60 * 60 * this.log_expire) < now) {
                        directory.remove (s);
                    }
                }
                var rx_match = regex.match (s);
                if (s.starts_with (new_log_name) && rx_match.has_match ()) {
                    max_number = q_max (max_number, rx_match.captured (1).to_int ());
                }
            }
            new_log_name.append ("." + string.number (max_number + 1));

            var previous_log = this.log_file_object.filename ();
            this.log_file = directory.file_path (new_log_name);

            // Compress the previous log file. On a restart this can be the most recent
            // log file.
            var log_to_compress = previous_log;
            if (log_to_compress == "" && files.size () > 0 && !files.last ().has_suffix (".gz"))
                log_to_compress = directory.absolute_file_path (files.last ());
            if (!log_to_compress == "") {
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
        GLib.File original = GLib.File.new_for_path (original_name);
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
        GLib.File log_file = GLib.File.new_for_path (QDir.temp_path () + "/" + APPLICATION_NAME + "-crash.log");
        if (log_file_object.open (GLib.File.WriteOnly)) {
            QTextStream output = new QTextStream (&log_file);
            for (int i = 1; i <= CRASH_LOG_SIZE; ++i) {
                output += this.crash_log[ (this.crash_log_index + i) % CRASH_LOG_SIZE] + '\n';
            }
        }
    }

} // class Logger

} // namespace LibSync
} // namespace Occ
