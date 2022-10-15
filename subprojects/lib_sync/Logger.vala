namespace Occ {
namespace LibSync {

/***********************************************************
@class Logger

@brief The Logger class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class Logger { //: GLib.Object {

    const int CRASH_LOG_SIZE = 20;

    private GLib.File log_file_object;
    /***********************************************************
    ***********************************************************/
    string log_file {
        //  public get {
        //      return this.log_file_object.filename ();
        //  }
        //  public set {
        //      GLib.MutexLocker locker = new GLib.MutexLocker (this.mutex);
        //      if (this.logstream != null) {
        //          this.logstream.reset (null);
        //          this.log_file_object.close ();
        //      }

        //      if (value == "") {
        //          return;
        //      }

        //      bool open_succeeded = false;
        //      if (value == "-") {
        //          open_succeeded = this.log_file_object.open (stdout, GLib.IODevice.WriteOnly);
        //      } else {
        //          this.log_file_object.filename (value);
        //          open_succeeded = this.log_file_object.open (GLib.IODevice.WriteOnly);
        //      }

        //      if (!open_succeeded) {
        //          locker.unlock (); // Just in case post_gui_message has a GLib.debug ()
        //          post_gui_message (_("Error"),
        //              _("<nobr>File \"%1\"<br/>cannot be opened for writing.<br/><br/>"
        //              + "The log output <b>cannot</b> be saved!</nobr>")
        //                  .printf (value));
        //          return;
        //      }

        //      this.logstream.reset (new GLib.OutputStream (this.log_file));
        //      this.logstream.codec (GMime.Encoding.codec_for_name ("UTF-8"));
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public static bool log_debug {
        //  public get {
        //      return Logger.log_debug;
        //  }
        //  public set {
        //      GLib.List<string> rules = new GLib.List<string> ();
        //      if (value) {
        //          rules.append ("nextcloud.*.debug=true")
        //          add_log_rule (rules);
        //      } else {
        //          rules.append ("");
        //          remove_log_rule (rules);
        //      }
        //      Logger.log_debug = value;
        //  }
    }
    public static string log_directory;
    private static bool temporary_folder_log_directory;
    public static int log_expire { private get; public set; }
    public static bool log_flush { private get; public set; }

    private GLib.OutputStream logstream;
    private /*mutable*/ GLib.Mutex mutex;

    public static GLib.List<string> log_rules {
        //  private get {
        //      return this.log_rules;
        //  }
        //  public set {
        //      Logger.log_rules = value;
        //      string temporary;
        //      GLib.OutputStream output = new GLib.OutputStream (temporary);
        //      foreach (var p in value) {
        //          output += p + "\n";
        //      }
        //      GLib.debug (temporary);
        //      GLib.LoggingCategory.filter_rules (temporary);
        //  }
    }

    private GLib.List<string> crash_log;
    private int crash_log_index = 0;

    internal signal void signal_log_window_log (string value);
    internal signal void signal_gui_log (string value_1, string value_2);
    internal signal void signal_gui_message (string value_1, string value_2);
    internal signal void signal_optional_gui_log (string value_1, string value_2);


    /***********************************************************
    ***********************************************************/
    private Logger (GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
        //  q_message_pattern ("%{time yyyy-MM-dd hh:mm:ss:zzz} [ %{type} %{category} %{file}:%{line} "
        //                      + "]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}");
        //  this.crash_log.resize (CRASH_LOG_SIZE);
    // #ifndef NO_MSG_HANDLER
        //  q_install_message_handler (message_handler);
    // #endif
    }


    static construct {
        //  log_flush = false;
        //  log_debug = false;
        //  log_expire = 0;
        //  temporary_folder_log_directory = false;
    }


    private void message_handler (QtMsgType type, GLib.MessageLogContext context, string message) {
        //  Logger.do_log (type, context, message);
    }


    ~Logger () {
    // #ifndef NO_MSG_HANDLER
        //  q_install_message_handler (null);
    // #endif
    }

    static Logger log;

    /***********************************************************
    ***********************************************************/
    public static Logger instance {
        public get {
            return Logger.log;
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public static is_logging_to_file {
    //      public get {
    //          GLib.MutexLocker lock = new GLib.MutexLocker (this.mutex);
    //          return this.logstream;
    //      }
    //  }


    /***********************************************************
    ***********************************************************/
    public void do_log (
        QtMsgType type,
        GLib.MessageLogContext context,
        string message
    ) {
        //  string message = q_format_log_message (type, context, message);
        //  {
        //      GLib.MutexLocker lock = new GLib.MutexLocker (this.mutex);
        //      this.crash_log_index = (this.crash_log_index + 1) % CRASH_LOG_SIZE;
        //      this.crash_log[this.crash_log_index] = message;
        //      if (this.logstream != null) {
        //          (this.logstream) + message + GLib.endl;
        //          if (this.log_flush) {
        //              this.logstream.flush ();
        //          }
        //      }
        //      if (type == QtFatalMsg) {
        //          close ();
        //      }
        //  }
        //  signal_log_window_log (message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_gui_log (string title, string message) {
        //  signal_gui_log (title, message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_optional_gui_log (string title, string message) {
        //  signal_optional_gui_log (title, message);
    }


    /***********************************************************
    ***********************************************************/
    public void post_gui_message (string title, string message) {
        //  signal_gui_message (title, message);
    }


    /***********************************************************
    ***********************************************************/
    void close () {
        //  dump_crash_log ();
        //  if (this.logstream != null) {
        //      this.logstream.flush ();
        //      this.log_file_object.close ();
        //      this.logstream.reset ();
        //  }
    }


    /***********************************************************
    Returns where the automatic logdir would be
    ***********************************************************/
    public string temporary_folder_log_dir_path {
        //  return GLib.Dir.temp ().file_path (APPLICATION_SHORTNAME + "-logdir");
    }


    /***********************************************************
    Sets up default directory log setup.

    logdir: a temporary folder
    logexpire: 4 hours
    logdebug: true

    Used in conjunction with ConfigFile.automatic_log_dir
    ***********************************************************/
    public static void setup_temporary_folder_log_dir () {
        //  var directory = temporary_folder_log_dir_path;
        //  if (!new GLib.Dir ().mkpath (directory)) {
        //      return;
        //  }
        //  Logger.log_debug = true;
        //  Logger.log_expire = 4; /*hours*/
        //  Logger.log_directory = directory;
        //  Logger.temporary_folder_log_directory = true;
    }


    /***********************************************************
    For switching off via logwindow
    ***********************************************************/
    public void disable_temporary_folder_log_dir () {
        //  if (!this.temporary_folder_log_directory)
        //      return;

        //  on_signal_enter_next_log_file ();
        //  this.log_directory = "";
        //  this.log_debug = false;
        //  this.log_file = "";
        //  this.temporary_folder_log_directory = false;
    }


    /***********************************************************
    ***********************************************************/
    public void add_log_rule (GLib.List<string> rules) {
        //  this.log_rules = this.log_rules + rules;
    }


    /***********************************************************
    ***********************************************************/
    public void remove_log_rule (GLib.List<string> rules) { }


    /***********************************************************
    ***********************************************************/
    public void on_signal_enter_next_log_file () {
        //  if (this.log_directory != "") {

        //      GLib.Dir directory = new GLib.Dir (this.log_directory);
        //      if (!directory.exists ()) {
        //          directory.mkpath (".");
        //      }

        //      // Tentative new log name, will be adjusted if one like this already exists
        //      GLib.DateTime now = GLib.DateTime.current_date_time ();
        //      string new_log_name = now.to_string () + "yyyy_mMdd_HHmm" + "_owncloud.log";

        //      // Expire old log files and deal with conflicts
        //      GLib.List<string> files = directory.entry_list (GLib.List<string> ("*owncloud.log.*"),
        //          GLib.Dir.Files, GLib.Dir.Name);
        //      GLib.Regex regular_expression = new GLib.Regex (GLib.Regex.anchored_pattern (" (.*owncloud\.log\. (\d+).*)"));
        //      int max_number = -1;
        //      foreach (string s in files) {
        //          if (this.log_expire > 0) {
        //              GLib.FileInfo file_info = GLib.File.new_for_path (directory.absolute_file_path (s));
        //              if (file_info.last_modified ().add_secs (60 * 60 * this.log_expire) < now) {
        //                  directory.remove (s);
        //              }
        //          }
        //          var regular_expression_match = regular_expression.match (s);
        //          if (s.has_prefix (new_log_name) && regular_expression_match.has_match ()) {
        //              max_number = int.max (max_number, regular_expression_match.captured (1).to_int ());
        //          }
        //      }
        //      new_log_name.append ("." + string.number (max_number + 1));

        //      var previous_log = this.log_file_object.filename ();
        //      this.log_file = directory.file_path (new_log_name);

        //      // Compress the previous log file. On a restart this can be the most recent
        //      // log file.
        //      var log_to_compress = previous_log;
        //      if (log_to_compress == "" && files.size () > 0 && !files.last ().has_suffix (".gz"))
        //          log_to_compress = directory.absolute_file_path (files.last ());
        //      if (!log_to_compress == "") {
        //          string compressed_name = log_to_compress + ".gz";
        //          if (compress_log (log_to_compress, compressed_name)) {
        //              GLib.File.remove (log_to_compress);
        //          } else {
        //              GLib.File.remove (compressed_name);
        //          }
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private static bool compress_log (string original_name, string target_name) {
    // #ifdef ZLIB_FOUND
        //  GLib.File original = GLib.File.new_for_path (original_name);
        //  if (!original.open (GLib.IODevice.ReadOnly))
        //      return false;
        //  var compressed = gzopen (target_name.to_utf8 (), "wb");
        //  if (!compressed) {
        //      return false;
        //  }

        //  while (!original.at_end ()) {
        //      var data = original.read (1024 * 1024);
        //      var written = gzwrite (compressed, data, data.size ());
        //      if (written != data.size ()) {
        //          gzclose (compressed);
        //          return false;
        //      }
        //  }
        //  gzclose (compressed);
        //  return true;
    // #else
        //  return false;
    // #endif
    }


    /***********************************************************
    ***********************************************************/
    private void dump_crash_log () {
        //  GLib.File log_file = GLib.File.new_for_path (GLib.Dir.temp_path + "/" + Common.Config.APPLICATION_NAME + "-crash.log");
        //  if (log_file_object.open (GLib.File.WriteOnly)) {
        //      GLib.OutputStream output = new GLib.OutputStream (log_file);
        //      for (int i = 1; i <= CRASH_LOG_SIZE; ++i) {
        //          output += this.crash_log[ (this.crash_log_index + i) % CRASH_LOG_SIZE] + "\n";
        //      }
        //  }
    }

} // class Logger

} // namespace LibSync
} // namespace Occ
