namespace Occ {
namespace Common {

/***********************************************************
@class Utility

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class Utility : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public static int rand () {
        return GLib.RandomGenerator.global ().bounded (0, RAND_MAX);
    }


    /***********************************************************
    ***********************************************************/
    public static void sleep (int sec) {
        GLib.Thread.sleep (sec);
    }


    /***********************************************************
    ***********************************************************/
    public static void usleep (int usec) {
        GLib.Thread.usleep (usec);
    }


    /***********************************************************
    ***********************************************************/
    public static string format_fingerprint (string fmhash, bool colon_separated = true) {
        string hash;
        int steps = fmhash.length / 2;
        for (int i = 0; i < steps; i++) {
            hash += fmhash[i * 2];
            hash += fmhash[i * 2 + 1];
            hash += " ";
        }

        string fp = hash.trimmed ();
        if (colon_separated) {
            fp.replace (" ", ":");
        }

        return fp;
    }


    /***********************************************************
    ***********************************************************/
    public static void setup_fav_link (string folder) {
        setup_fav_link_private (folder);
    }


    /***********************************************************
    ***********************************************************/
    static void setup_fav_link_private (string folder) {
        /***********************************************************
        Nautilus : add to ~/.gtk-bookmarks
        ***********************************************************/
        GLib.File gtk_bookmarks = GLib.File.new_for_path (GLib.Dir.home_path + "/.config/gtk-3.0/bookmarks");
        string folder_url = "file://" + folder;
        if (gtk_bookmarks.open (GLib.File.ReadWrite)) {
            string places = gtk_bookmarks.read_all ();
            if (!places.contains (folder_url)) {
                places += folder_url;
                gtk_bookmarks.reset ();
                gtk_bookmarks.write (places + "\n");
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public static void remove_fav_link (string folder) {
        remove_fav_link_private (folder);
    }


    /***********************************************************
    ***********************************************************/
    static void remove_fav_link_private (string folder) { }


    /***********************************************************
    ***********************************************************/
    public static bool write_random_file (string fname, int size = -1) {
        int max_size = 10 * 10 * 1024;

        if (size == -1) {
            size = rand () % max_size;
        }

        string rand_string;
        for (int i = 0; i < size; i++) {
            int r = rand () % 128;
            rand_string += (string)(char)r;
        }

        GLib.File file = GLib.File.new_for_path (fname);
        if (file.open (GLib.IODevice.WriteOnly | GLib.IODevice.Text)) {
            string outfile;
            /***********************************************************
            outfile = new GLib.OutputStream (file);
            ***********************************************************/
            outfile = rand_string;
            /***********************************************************
            Optional, as GLib.File destructor will already do it:
            ***********************************************************/
            file.close ();
            return true;
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public static string octets_to_string (int64 octets) {
        int THE_FACTOR = 1024;
        int64 KB = THE_FACTOR;
        int64 MB = THE_FACTOR * KB;
        int64 GB = THE_FACTOR * MB;

        string s;
        double value = octets;

        /***********************************************************
        Whether we care about decimals : only for GB/MB and only if
        it's less than 10 units.
        ***********************************************************/
        bool round = true;

        /***********************************************************
        do not display terra byte with the current units, as when
        the MB, GB and KB units were made, there was no TB,
        see the JEDEC standard
        https://en.wikipedia.org/wiki/JEDEC_memory_standards
        ***********************************************************/
        if (octets >= GB) {
            s = _("%L1 GB");
            value /= GB;
            round = false;
        } else if (octets >= MB) {
            s = _("%L1 MB");
            value /= MB;
            round = false;
        } else if (octets >= KB) {
            s = _("%L1 KB");
            value /= KB;
        } else {
            s = _("%L1 B");
        }
        if (value > 9.95) {
            round = true;
        }
        if (round) {
            return s.printf (q_round (value));
        }
        return s.printf (value, 0, "g", 2);
    }

    /***********************************************************
    ***********************************************************/
    public static string user_agent_string () {
        return "Mozilla/5.0 (%1) mirall/%2 (%3, %4-%5 ClientArchitecture : %6 OsArchitecture : %7)"
            .printf (
                platform (),
                Common.NextcloudVersion.MIRALL_VERSION_STRING,
                GLib.Application.application_name (),
                GLib.SysInfo.product_type (),
                GLib.SysInfo.kernel_version (),
                GLib.SysInfo.build_cpu_architecture (),
                GLib.SysInfo.current_cpu_architecture ())
            .to_latin1 ();
    }


    /***********************************************************
    ***********************************************************/
    public static string friendly_user_agent_string () {
        var pattern = "%1 (Desktop Client - %2)";
        var user_agent = pattern.printf (GLib.SysInfo.machine_host_name (), platform ());
        return user_agent.to_utf8 ();
    }


    /***********************************************************
    Qtified version of get_platforms () in csync_owncloud.c
    ***********************************************************/
    public static string platform () {
        return GLib.SysInfo.product_type ();
    }


    /***********************************************************
    @brief Return whether launch on startup is enabled system wide.

    If this returns true, the checkbox
    on startup will be hidden.

    Currently only implemented on Windows.

    @param app_name is unused
    ***********************************************************/
    public static bool has_system_launch_on_signal_startup (string app_name) {
        return false;
    }


    /***********************************************************
    returns the autostart directory the linux way
    and respects the XDG_CONFIG_HOME env variable
    ***********************************************************/
    static string get_user_autostart_dir_private () {
        string config = GLib.StandardPaths.writable_location (GLib.StandardPaths.ConfigLocation);
        config += "/autostart/";
        return config;
    }


    /***********************************************************
    ***********************************************************/
    public static bool has_launch_on_signal_startup (string app_name) {
        return has_launch_on_signal_startup_private (app_name);
    }


    /***********************************************************
    @param app_name is unused
    ***********************************************************/
    static bool has_launch_on_signal_startup_private (string app_name) {
        string desktop_file_location = get_user_autostart_dir_private ()
                                        + Common.Config.LINUX_APPLICATION_ID
                                        + ".desktop";
        return GLib.File.exists (desktop_file_location);
    }


    /***********************************************************
    ***********************************************************/
    public static void launch_on_signal_startup (string app_name, string gui_name, bool enable) {
        launch_on_signal_startup_private (app_name, gui_name, enable);
    }


    /***********************************************************
    @param app_name is unused
    ***********************************************************/
    static void launch_on_signal_startup_private (string app_name, string gui_name, bool enable) {
        string user_auto_start_path = get_user_autostart_dir_private ();
        string desktop_file_location = user_auto_start_path
                                        + Common.Config.LINUX_APPLICATION_ID
                                        + ".desktop";
        if (enable) {
            if (!new GLib.Dir ().exists (user_auto_start_path) && !new GLib.Dir ().mkpath (user_auto_start_path)) {
                GLib.warning ("Could not create autostart folder" + user_auto_start_path);
                return;
            }
            GLib.File ini_file = GLib.File.new_for_path (desktop_file_location);
            if (!ini_file.open (GLib.IODevice.WriteOnly)) {
                GLib.warning ("Could not write var on_signal_start entry" + desktop_file_location);
                return;
            }
            /***********************************************************
            When running inside an AppImage, we need to set the path to
            the AppImage instead of the path to the executable.
            ***********************************************************/
            string app_image_path = q_environment_variable ("APPIMAGE");
            bool running_inside_app_image = !app_image_path == null && GLib.File.exists (app_image_path);
            string executable_path = running_inside_app_image ? app_image_path : GLib.Application.application_file_path;

            string ts;
            /***********************************************************
            ts = new GLib.OutputStream (ini_file);
            ts.codec ("UTF-8");
            ***********************************************************/
            ts = "[Desktop Entry]\n"
               + "Name=" + gui_name + "\n"
               + "GenericName=" + "File Synchronizer\n"
               + "Exec=\"" + executable_path + "\" --background\n"
               + "Terminal=" + "false\n"
               + "Icon=" + Common.Config.APPLICATION_ICON_NAME + "\n"
               + "Categories=" + "Network\n"
               + "Type=" + "Application\n"
               + "StartupNotify=" + "false\n"
               + "X-GNOME-Autostart-enabled=" + "true\n"
               + "X-GNOME-Autostart-Delay=10";
        } else {
            if (!GLib.File.remove (desktop_file_location)) {
                GLib.warning ("Could not remove autostart desktop file");
            }
        }
    }

    /***********************************************************
    Use this functions to retrieve uint32/int (often required by
    Qt and WIN32) from size_t without compiler warnings about
    possible truncation
    ***********************************************************/
    public static uint32 convert_size_to_uint (size_t convert_var) {
        if (convert_var > uint.MAX) {
            /***********************************************************
            throw std.bad_cast ();
            ***********************************************************/
            /***********************************************************
            Intentionally default to wrong value here to not crash:
            exception handling TBD.
            ***********************************************************/
            convert_var = uint.MAX;
        }
        return (uint32)convert_var;
    }


    /***********************************************************
    ***********************************************************/
    public static int convert_size_to_int (size_t convert_var) {
        if (convert_var > int.MAX) {
            /***********************************************************
            throw std.bad_cast ();
            ***********************************************************/
            /***********************************************************
            Intentionally default to wrong value here to not crash:
            exception handling TBD.
            ***********************************************************/
            convert_var = int.MAX;
        }
        return (int)convert_var;
    }


    /***********************************************************
    Return the amount of free space available.

    \a path must point to a directory
    ***********************************************************/
    public static int64 free_disk_space (string path) {
        struct StatVfs64;
        StatVfs64 stat;
        if (statvfs64 (path.to_local8Bit (), stat) == 0) {
            return (int64)stat.f_bavail * stat.f_frsize;
        }
        return -1;
    }


    /***********************************************************
    @brief compact_format_double - formats a double value human readable.

    @param value the value to
    @param prec the precision.
    @param unit an optional unit that is appended if present.
    @return the formatted string.
    ***********************************************************/
    public static string compact_format_double (double value, int prec, string unit = "") {
        GLib.Locale locale = GLib.Locale.system ();
        char dec_point = locale.decimal_point ();
        string string_value = locale.to_string (value, "f", prec);
        while (string_value.has_suffix ("0") || string_value.has_suffix (dec_point)) {
            if (string_value.has_suffix (dec_point)) {
                string_value.chop (1);
                break;
            }
            string_value.chop (1);
        }
        if (unit != "") {
            string_value += (" " + unit);
        }
        return string_value;
    }

    /***********************************************************
    Porting Methods
    ***********************************************************/

    /***********************************************************
    ***********************************************************/
    public static string escape (string input) {
        return input.to_html_escaped ();
    }

    /***********************************************************
    conversion function GLib.DateTime from time_t
    (because the ones built in work on only unsigned 32bit)
    ***********************************************************/
    public static GLib.DateTime q_date_time_from_time_t (int64 t) {
        return GLib.DateTime.from_m_secs_since_epoch (t * 1000);
    }


    /***********************************************************
    ***********************************************************/
    public static int64 q_date_time_to_time_t (GLib.DateTime t) {
        return t.to_m_secs_since_epoch () / 1000;
    }


    /***********************************************************
    @brief Convert milliseconds duration to human readable string.
    @param uint64 msecs the milliseconds to convert to string.
    @return an HMS representation of the milliseconds value.

    duration_to_descriptive_string1 describ
    unit, like "5 minutes" or "2 days".
    ***********************************************************/
    public static string duration_to_descriptive_string1 (uint64 msecs) {
        int p = 0;
        while (periods[p + 1].name && msecs < periods[p].msec) {
            p++;
        }

        uint64 amount = q_round (double (msecs) / periods[p].msec);
        return periods[p].description (amount);
    }

    /***********************************************************
    @brief Convert milliseconds duration to human readable string.
    @param uint64 msecs the milliseconds to convert to string.
    @return an HMS representation of the milliseconds value.

    duration_to_descriptive_string2 uses two units where possible, so
    "5 minutes 43 seconds" or "1 month 3 days".
    ***********************************************************/
    public static string duration_to_descriptive_string2 (uint64 msecs) {
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

        return _("%1 %2").printf (first_part, periods[p + 1].description (second_part_num));
    }



    /***********************************************************
    @brief has_dark_systray - determines whether the systray is dark or light.

    Use this to check if the OS has a dark or a light systray.

    The value might change during the execution of the program
    (e.g. on OS X 10.10).

    @return bool which is true for systems with dark systray.
    ***********************************************************/
    public static bool has_dark_systray () {
        return has_dark_systray_private ();
    }


    /***********************************************************
    ***********************************************************/
    public static bool has_dark_systray_private () {
        return true;
    }


    /***********************************************************
    Convenience OS detection method
    ***********************************************************/
    public static bool is_windows () {
        return false;
    }


    /***********************************************************
    Convenience OS detection method
    ***********************************************************/
    public static bool is_mac () {
        return false;
    }


    /***********************************************************
    Convenience OS detection method
    ***********************************************************/
    public static bool is_unix () {
        return true;
    }


    /***********************************************************
    Convenience OS detection method
    Use with care
    ***********************************************************/
    public static bool is_linux () {
        return true;
    }


    /***********************************************************
    Convenience OS detection method
    Use with care, does not match OS X
    ***********************************************************/
    public static bool is_bsd () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public static string platform_name () {
        return GLib.SysInfo.pretty_product_name ();
    }


    /***********************************************************
    er for --debug
    ***********************************************************/
    /***********************************************************
    public static void crash () {
        volatile int a = (int *)null;
        *a = 1;
    }
    ***********************************************************/

    /***********************************************************
    This can be overriden from the tests
    ***********************************************************/
    public static bool fs_case_preserving_override {
        public get {
            string env = qgetenv ("OWNCLOUD_TEST_CASE_PRESERVING");
            if (!env == "") {
                return env.to_int ();
            }
            return Utility.is_windows () || Utility.is_mac ();
        }
    }


    /***********************************************************
    Case preserving file system underneath? If this function
    returns true, the file system is case preserving, that means
    "test" means the same as "TEST" for filenames.
    if false, the two cases are two different files.
    ***********************************************************/
    public static bool fs_case_preserving {
        public get {
            return fs_case_preserving_override;
        }
    }


    /***********************************************************
    Check if two pathes that MUST exist are equal. This function
    uses GLib.Dir.canonical_path to judge and cares for the
    system's case sensitivity.
    ***********************************************************/
    public static bool filenames_equal (string fn1, string fn2) {
        GLib.Dir fd1 = new GLib.Dir (fn1);
        GLib.Dir fd2 = new GLib.Dir (fn2);

        /***********************************************************
        Attention: If the path does not exist, canonical_path
        returns "". ONLY use this function with existing paths.
        ***********************************************************/
        string a = fd1.canonical_path;
        string b = fd2.canonical_path;

        if (fs_case_preserving) {
            return a != "" && a.down () == b.down ();
        } else {
            return a != "" && a == b;
        }
    }


    /***********************************************************
    Call the given command with the switch --version and rerun the first line
    of the output.
    If command is empty, the function calls the running application which, on
    Linux, might have changed while this one is running.
    For Mac and Windows, it returns ""

    read the output of the owncloud --version command from the owncloud
    version that is on disk. This works for most versions of the client,
    because clients that do not yet know the --version flag return the
    version in the first line of the help output :-)

    This version only delivers output on linux, as Mac and Win get their
    restarting from the installer.
    ***********************************************************/
    public static string version_of_installed_binary (string command = "") {
        string re;
        if (is_linux ()) {
            string binary = command;
            if (binary == "") {
                binary = GLib.Application.arguments ()[0];
            }
            GLib.List<string> parameters = new GLib.List<string> ();
            parameters.append ("--version");
            GLib.Process process;
            process.on_signal_start (binary, parameters);
            process.wait_for_finished (); // sets current thread to sleep and waits for ping_process end
            re = process.read_all_standard_output ();
            int newline = re.index_of ("\n");
            if (newline > 0) {
                re.truncate (newline);
            }
        }
        return re;
    }


    /***********************************************************
    ***********************************************************/
    public static string filename_for_gui_use (string f_name) {
        if (is_mac ()) {
            string n = f_name;
            return n.replace (":", "/");
        }
        return f_name;
    }


    /***********************************************************
    ***********************************************************/
    public static string normalize_etag (string etag) {
        /***********************************************************
        Strip "XXXX-gzip".
        ***********************************************************/
        if (etag.has_prefix ("\"") && etag.has_suffix ("-gzip\"")) {
            etag.chop (6);
            etag.remove (0, 1);
        }
        /***********************************************************
        Strip trailing "-gzip".
        ***********************************************************/
        if (etag.has_suffix ("-gzip")) {
            etag.chop (5);
        }
        /***********************************************************
        Strip normal quotes.
        ***********************************************************/
        if (etag.has_prefix ("\"") && etag.has_suffix ("\"") {
            etag.chop (1);
            etag.remove (0, 1);
        }
        etag.squeeze ();
        return etag;
    }


    /***********************************************************
    @brief time_ago_in_words - human readable time span

    Use this to get a string that describes the timespan between the f
    the second timestamp in a human readable and understandable form.

    If the second parameter is ommitted, the current time is used.
    ***********************************************************/
    public static string time_ago_in_words (GLib.DateTime dt, GLib.DateTime from = new GLib.DateTime ()) {
        GLib.DateTime now = GLib.DateTime.current_date_time_utc ();

        if (from.is_valid) {
            now = from;
        }

        if (dt.days_to (now) == 1) {
            return _("%n day ago", "", dt.days_to (now));
        } else if (dt.days_to (now) > 1) {
            return _("%n days ago", "", dt.days_to (now));
        } else {
            int64 secs = dt.secs_to (now);
            if (secs < 0) {
                return _("in the future");
            }

            if (floor (secs / 3600.0) > 0) {
                int hours = floor (secs / 3600.0);
                if (hours == 1) {
                    return (_("%n hour ago", "", hours));
                } else {
                    return (_("%n hours ago", "", hours));
                }
            } else {
                int minutes = q_round (secs / 60.0);

                if (minutes == 0) {
                    if (secs < 5) {
                        return _("now");
                    } else {
                        return _("Less than a minute ago");
                    }

                } else if (minutes == 1) {
                    return (_("%n minute ago", "", minutes));
                } else {
                    return (_("%n minutes ago", "", minutes));
                }
            }
        }
        return _("Some time ago");
    }

    class StopWatch {

        string STOPWATCH_END_TAG = "_STOPWATCH_END";

        private GLib.HashTable<string, uint64?> lap_times;
        GLib.DateTime start_time { public get; private set; }
        private GLib.Timer timer;


        public void start () {
            this.start_time = GLib.DateTime.current_date_time_utc ();
            this.timer.on_signal_start ();
        }


        public uint64 stop () {
            add_lap_time (STOPWATCH_END_TAG);
            uint64 duration = this.timer.elapsed ();
            this.timer.invalidate ();
            return duration;
        }


        public uint64 add_lap_time (string lap_name) {
            if (!this.timer.is_valid) {
                on_signal_start ();
            }
            uint64 re = this.timer.elapsed ();
            this.lap_times[lap_name] = re;
            return re;
        }


        public void reset () {
            this.timer.invalidate ();
            this.start_time.m_secs_since_epoch (0);
            this.lap_times = new GLib.HashTable<string, uint64?> ();
        }


        /***********************************************************
        Out helpers, return the measured times.
        ***********************************************************/
        public GLib.DateTime time_of_lap (string lap_name) {
            uint64 t = duration_of_lap (lap_name);
            if (t == 0) {
                GLib.DateTime re = new GLib.DateTime (this.start_time);
                return re.add_m_secs (t);
            }

            return new GLib.DateTime ();
        }


        /***********************************************************
        Out helpers, return the measured times.
        ***********************************************************/
        public uint64 duration_of_lap (string lap_name) {
            return this.lap_times.value (lap_name, 0);
        }
    }


    /***********************************************************
    @brief Sort a GLib.List<string> in a way that's appropriate for filenames
    ***********************************************************/
    public static void sort_filenames (GLib.List<string> filenames) {
        GLib.Collator collator;
        collator.numeric_mode (true);
        collator.case_sensitivity (GLib.CaseInsensitive);
        std.sort (filenames.begin (), filenames.end (), collator);
    }


    /***********************************************************
    Appends concat_path and query_items to the url
    ***********************************************************/
    public static GLib.Uri concat_url_path (
        GLib.Uri url, string concat_path,
        GLib.UrlQuery query_items = {}) {
        string path = url.path;
        if (concat_path != "") {
            /***********************************************************
            Avoid "//"
            ***********************************************************/
            if (path.has_suffix ("/") && concat_path.has_prefix ("/")) {
                path.chop (1);
            }
            /***********************************************************
            Avoid missing "/""
            ***********************************************************/
            else if (!path.has_suffix ("/") && !concat_path.has_prefix ("/")) {
                path += "/";
            }
            /***********************************************************
            ***********************************************************/
            path += concat_path; // put the complete path together
        }

        GLib.Uri temporary_url = url;
        temporary_url.path (path);
        temporary_url.query (query_items);
        return temporary_url;
    }


    /***********************************************************
    Returns a new settings pre-set in a specific group.  The Settings will be created
    with the given parent. If no parent is specified, the caller must destroy the settings
    ***********************************************************/
    /***********************************************************
    public static GLib.Settings settings_with_group (string group, GLib.Object parent = new GLib.Object ());
    ***********************************************************/


    /***********************************************************
    Sanitizes a string that shall become part of a filename.

    Filters out reserved characters like
    - unicode control and format characters
    - reserved characters : /, ?, <, >, \, :, *, |, and "

    Warning : This does not sanitize the
    - unix reserved filenames (".
    - trailing periods and spaces
    - windows reserved filenames ("CON" etc)
    will pass unchanged.
    ***********************************************************/
    public static string sanitize_for_filename (string name) {
        string invalid = " (/?<>:*|\")";
        string result;
        result.reserve (name.length);
        foreach (var c in name) {
            if (!invalid.contains (c)
                && c.category () != char.Other_Control
                && c.category () != char.Other_Format) {
                result.append (c);
            }
        }
        return result;
    }


    /***********************************************************
    Returns a file name based on \a filename that's suitable for a
    conflict.
    ***********************************************************/
    public static string make_conflict_filename (
        string filename, GLib.DateTime dt, string user) {
        string conflict_filename = filename;
        /***********************************************************
        Add conflict tag before the extension.
        ***********************************************************/
        int dot_location = conflict_filename.last_index_of (".");
        /***********************************************************
        If no extension, add it at the end (take care of cases like
        foo/.hidden or foo.bar/file).
        ***********************************************************/
        if (dot_location <= conflict_filename.last_index_of ("/") + 1) {
            dot_location = conflict_filename.length;
        }

        string conflict_marker = " (conflicted copy ";
        if (user != "") {
            /***********************************************************
            Don't allow parentheses in the user name, to ensure we can
            find the beginning and end of the conflict tag.
            ***********************************************************/
            string user_name = sanitize_for_filename (user).replace ("(", "_").replace (")", "_");
            conflict_marker += user_name + " ";
        }
        conflict_marker += dt.to_string ("yyyy-MM-dd hhmmss") + ")";

        conflict_filename.insert (dot_location, conflict_marker);
        return conflict_filename;
    }


    /***********************************************************
    Returns whether a file name indicates a conflict file
    ***********************************************************/
    /***********************************************************
    public static bool is_conflict_file (char name) {
        const string bname = std.strrchr (name, "/");
        if (bname) {
            bname += 1;
        } else {
            bname = name;
        }

        /***********************************************************
        Old pattern
        ***********************************************************
        if (std.strstr (bname, "this.conflict-")) {
            return true;
        }

        /***********************************************************
        New pattern
        ***********************************************************
        if (std.strstr (bname, " (conflicted copy")) {
            return true;
        }

        return false;
    }
    ***********************************************************/


    /***********************************************************
    ***********************************************************/
    public static bool is_conflict_file (string name) {
        var bname = name.mid_ref (name.last_index_of ("/") + 1);

        if (bname.contains ("this.conflict-")) {
            return true;
        }

        if (bname.contains (" (conflicted copy")) {
            return true;
        }

        return false;
    }


    /***********************************************************
    Find the base name for a conflict file name, using name
    pattern only

    Will return an empty string if it's not a conflict file.

    Prefer to use the data from the conflicts table in the
    journal to determine a conflict's base file, see
    SyncJournal.conflict_file_base_name ()
    ***********************************************************/
    public static string conflict_file_base_name_from_pattern (string conflict_name) {
        /***********************************************************
        This function must be able to deal with conflict files for
        conflict files. To do this, we scan backwards, for the
        outermost conflict marker and strip only that to generate
        the conflict file base name.
        ***********************************************************/
        var start_old = conflict_name.last_index_of ("this.conflict-");

        /***********************************************************
        A single space before " (conflicted copy" is considered part
        of the tag.
        ***********************************************************/
        var start_new = conflict_name.last_index_of (" (conflicted copy");
        if (start_new > 0 && conflict_name[start_new - 1] == ' ') {
            start_new -= 1;
        }

        /***********************************************************
        The rightmost tag is relevant
        ***********************************************************/
        var tag_start = int.max (start_old, start_new);
        if (tag_start == -1) {
            return "";
        }

        /***********************************************************
        Find the end of the tag
        ***********************************************************/
        var tag_end = conflict_name.length;
        /***********************************************************
        Dot could be part of user name for new tag!
        ***********************************************************/
        var dot = conflict_name.last_index_of (".");
        if (dot > tag_start) {
            tag_end = dot;
        }
        if (tag_start == start_new) {
            var paren = conflict_name.index_of (")", tag_start);
            if (paren != -1) {
                tag_end = paren + 1;
            }
        }
        return conflict_name.left (tag_start) + conflict_name.mid (tag_end);
    }


    /***********************************************************
    @brief Check whether the path is a root of a Windows drive
    partition ([c:/, d:/, e:/, etc.)

    @param path is unused
    ***********************************************************/
    public static bool is_path_windows_drive_partition_root (string path) {
        return false;
    }


    /***********************************************************
    @brief Retrieves current logged-in user name from the OS
    ***********************************************************/
    public string get_current_user_name {
        public get {
            return "";
        }
    }


    struct Period {
        string name;
        uint64 msec;

        string description (uint64 value) {
            return _(name, null, value);
        }
    }


    /***********************************************************
    GLib.TBUG-3945 and issue #4855: GLib.T_TRANSLATE_NOOP does
    not work with plural form because lupdate limitation unless
    we fake more arguments (it must be in the form ("context",
    "source", "comment", n).

    #undef GLib.T_TRANSLATE_NOOP
    const int GLib.T_TRANSLATE_NOOP (context, string_value, ...) string_value
        Q_DECL_CONSTEXPR Period periods[] = { { GLib.T_TRANSLATE_NOOP ("%n year (s)", 0, this.), 365 * 24 * 3600 * 1000LL }, { GLib.T_TRANSLATE_NOOP ("%n month (s)", 0, this.), 30 * 24 * 3600 * 1000LL }, { GLib.T_TRANSLATE_NOOP ("%n day (s)", 0, this.), 24 * 3600 * 1000LL }, { GLib.T_TRANSLATE_NOOP ("%n hour (s)", 0, this.), 3600 * 1000LL }, { GLib.T_TRANSLATE_NOOP ("%n minute (s)", 0, this.), 60 * 1000LL }, { GLib.T_TRANSLATE_NOOP ("%n second (s)", 0, this.), 1000LL }, { null, 0 }
    };
    ***********************************************************/

} // class Utility

} // namespace Common
} // namespace Occ
