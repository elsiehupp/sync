/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
//  #include <Gtk.Widget>
//  #include <QHeaderView>
//  #endif

//  #include <Gtk.Application>
//  #include <GLib.Dir>
//  #include <GLib.FileInfo>
//  #include <QLoggingCategory>
//  #include <GLib.Settings>
//  #include <Soup.ProxyResolverDefault>
//  #include <QStandardPaths>

//  #if ! (QTLEGACY)
//  #include <QOperatingSystemVersion>
//  #endif


//  #include <memory>

//  #include <GLib.Settings>
//  #include <chrono>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The ConfigFile class
@ingroup libsync
***********************************************************/
public class ConfigFile : GLib.Object {

    //  Q_GLOBAL_STATIC (string, g_config_filename)

    /***********************************************************
    ***********************************************************/
    public enum Scope {
        USER_SCOPE,
        SYSTEM_SCOPE
    }

    /***********************************************************
    Default remote poll time in milliseconds
    ***********************************************************/
    const int DEFAULT_REMOTE_POLL_INTERVAL = 30000;
    const int DEFAULT_MAX_LOG_LINES = 20000;

    //  const string CA_CERTS_KEY_C = "CaCertificates"; only used from account
    private const string REMOTE_POLL_INTERVAL_C = "remote_poll_interval";
    private const string FORCE_SYNC_INTERVAL_C = "force_sync_interval";
    private const string FULL_LOCAL_DISCOVERY_INTERVAL_C = "full_local_discovery_interval";
    private const string NOTIFICATION_REFRESH_INTERVAL_C = "notification_refresh_interval";
    private const string MONO_ICONS_C = "mono_icons";
    private const string PROMPT_DELETE_C = "prompt_delete_all_files";
    private const string CRASH_REPORTER_C = "crash_reporter";
    private const string OPTIONAL_SERVER_NOTIFICATIONS_C = "optional_server_notifications";
    private const string SHOW_IN_EXPLORER_NAVIGATION_PANE_C = "show_in_explorer_navigation_pane";
    private const string SKIP_UPDATE_CHECK_C = "skip_update_check";
    private const string AUTO_UPDATE_CHECK_C = "auto_update_check";
    private const string UPDATE_CHECK_INTERVAL_C = "update_check_interval";
    private const string UPDATE_SEGMENT_C = "update_segment";
    private const string UPDATE_CHANNEL_C = "update_channel";
    private const string GEOMETRY_C = "geometry";
    private const string TIMEOUT_C = "timeout";
    private const string CHUNK_SIZE_C = "chunk_size";
    private const string MIN_CHUNK_SIZE_C = "min_chunk_size";
    private const string MAX_CHUNK_SIZE_C = "max_chunk_size";
    private const string TARGET_CHUNK_UPLOAD_DURATION_C = "target_chunk_upload_duration";
    private const string AUTOMATIC_LOG_DIR_C = "log_to_temporary_log_dir";
    private const string LOG_DIR_C = "log_dir";
    private const string LOG_DEBUG_C = "log_debug";
    private const string LOG_EXPIRE_C = "log_expire";
    private const string LOG_FLUSH_C = "log_flush";
    private const string SHOW_EXPERIMENTAL_OPTIONS_C = "show_experimental_options";
    private const string CLIENT_VERSION_C = "client_version";
    
    private const string PROXY_HOST_C = "Proxy/host";
    private const string PROXY_TYPE_C = "Proxy/type";
    private const string PROXY_PORT_C = "Proxy/port";
    private const string PROXY_USER_C = "Proxy/user";
    private const string PROXY_PASS_C = "Proxy/pass";
    private const string PROXY_NEEDS_AUTH_C = "Proxy/needs_auth";
    
    private const string USE_UPLOAD_LIMIT_C = "BWLimit/use_upload_limit";
    private const string USE_DOWNLOAD_LIMIT_C = "BWLimit/use_download_limit";
    private const string UPLOAD_LIMIT_C = "BWLimit/upload_limit";
    private const string DOWNLOAD_LIMIT_C = "BWLimit/download_limit";
    
    private const string NEW_BIG_FOLDER_SIZE_LIMIT_C = "new_big_folder_size_limit";
    private const string USE_NEW_BIG_FOLDER_SIZE_LIMIT_C = "use_new_big_folder_size_limit";
    private const string CONFIRM_EXTERNAL_STORAGE_C = "confirm_external_storage";
    private const string MOVE_TO_TRASH_C = "move_to_trash";
    
    private const string CERT_PATH = "http_certificate_path";
    private const string CERT_PASSWORD = "http_certificate_password";

    private const string SHOW_MAIN_DIALOG_AS_NORMAL_WINDOW_C = "show_main_dialog_as_normal_window";

    private const string EXCL_FILE = "sync-exclude.lst";

    private const string KEYCHAIN_PROXY_PASSWORD_KEY = "proxy-password";

    /***********************************************************
    ***********************************************************/
    private static bool asked_user = false;
    private static string oc_version;

    /***********************************************************
    How do I initialize a static attribute?

    ConfigFile.conf_dir = "";
    ***********************************************************/
    private static string conf_dir {
        private get {
            return ConfigFile.conf_dir;
        }
        public set {
            string dir_path = value;
            if (dir_path == "") {
                return false;
            }

            GLib.FileInfo file_info = GLib.File.new_for_path (dir_path);
            if (!file_info.exists ()) {
                GLib.Dir ().mkpath (dir_path);
                file_info.file (dir_path);
            }
            if (file_info.exists () && file_info.query_info ().get_file_type () == FileType.DIRECTORY) {
                dir_path = file_info.absolute_file_path ();
                GLib.info ("Using custom config directory " + dir_path);
                ConfigFile.conf_dir = dir_path;
                return true;
            }
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public ConfigFile () {
        // QDesktopServices uses the application name to create a config path
        Gtk.Application.application_name (Theme.app_name_gui);

        GLib.Settings.default_format (GLib.Settings.IniFormat);

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (ConfigFile.default_connection);
    }


    /***********************************************************
    ***********************************************************/
    public static string config_path {
        public get {
            if (ConfigFile.conf_dir == "") {
                // On Unix, use the AppConfigLocation for the settings, that's configurable with the XDG_CONFIG_HOME env variable.
                ConfigFile.conf_dir = GLib.Environment.get_user_config_dir ();
            }
            string directory = ConfigFile.conf_dir;

            if (!directory.has_suffix ("/")) {
                directory.append ("/");
            }
            return directory;
        }
    }


    /***********************************************************
    ***********************************************************/
    public static string config_file {
        public get {
            return ConfigFile.config_path + Theme.config_filename;
        }
    }


    /***********************************************************
    Prefer sync-exclude.lst, but if it does not exist, check for
    exclude.lst for compatibility reasons in the user writeable
    directories.
    ***********************************************************/
    public static string exclude_file (Scope scope) {
        GLib.FileInfo file_info;

        switch (scope) {
        case USER_SCOPE:
            file_info.file (config_path (), EXCL_FILE);

            if (!file_info.is_readable ()) {
                file_info.file (config_path (), "exclude.lst");
            }
            if (!file_info.is_readable ()) {
                file_info.file (config_path (), EXCL_FILE);
            }
            return file_info.absolute_file_path ();
        case SYSTEM_SCOPE:
            return ConfigFile.exclude_file_from_system ();
        }

        //  ASSERT (false);
        return "";
    }



    /***********************************************************
    Doesn't access config directory
    ***********************************************************/
    public static string exclude_file_from_system () {
        GLib.FileInfo file_info;
        file_info.file (SYSCONFDIR + "/" + Theme.app_name, EXCL_FILE);
        if (!file_info.exists ()) {
            // Prefer to return the preferred path! Only use the fallback location
            // if the other path does not exist and the fallback is valid.
            GLib.FileInfo next_to_binary = GLib.File.new_for_path (Gtk.Application.application_dir_path (), EXCL_FILE);
            if (next_to_binary.exists ()) {
                file_info = next_to_binary;
            } else {
                // For AppImage, the file might reside under a temporary mount path
                GLib.Dir d = new GLib.Dir (Gtk.Application.application_dir_path ()); // supposed to be /tmp/mount.xyz/usr/bin
                d.cd_up (); // go out of bin
                d.cd_up (); // go out of usr
                if (!d.is_root ()) { // it is really a mountpoint
                    if (d.cd ("etc") && d.cd (Theme.app_name)) {
                        GLib.FileInfo in_mount_dir = GLib.File.new_for_path (d, EXCL_FILE);
                        if (in_mount_dir.exists ()) {
                            file_info = in_mount_dir;
                        }
                    }
                }
            }
        }

        return file_info.absolute_file_path ();
    }


    /***********************************************************
    Creates a backup of the file

    Returns the path of the new backup.
    ***********************************************************/
    public static string create_backup () {
        string base_file = ConfigFile.config_file;
        var version_string = ConfigFile.client_version_string;
        if (!version_string == "") {
            version_string.prepend ('_');
        }
        string backup_file =
            "%1.backup_%2%3"
                .printf (
                    base_file,
                    GLib.DateTime.current_date_time ().to_string () + "yyyyMMdd_HHmmss",
                    version_string
                );

        // If this exact file already exists it's most likely that a backup was
        // already done. (two backup calls directly after each other, potentially
        // even with source alterations in between!)
        if (!GLib.File.exists (backup_file)) {
            GLib.File file = new GLib.File (base_file);
            file.copy (backup_file);
        }
        return backup_file;
    }


    /***********************************************************
    ***********************************************************/
    public static bool exists {
        public get {
            GLib.File file = GLib.File.new_for_path (ConfigFile.config_file);
            return file.exists ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public string default_connection {
        public get {
            return Theme.app_name;
        }
    }


    /***********************************************************
    The certificates do not depend on a connection.
    ***********************************************************/
    public static string ca_certificates { public get; public set; }


    /***********************************************************
    ***********************************************************/
    //  public bool password_storage_allowed (string connection = "");


    /***********************************************************
    Server poll interval in milliseconds

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan remote_poll_interval_for_connection (string connection = "") {
        string connection_string = connection;
        if (connection == "") {
            connection_string = ConfigFile.default_connection;
        }

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_poll_interval = chrono.milliseconds (DEFAULT_REMOTE_POLL_INTERVAL);
        var remote_interval = milliseconds_value (settings, REMOTE_POLL_INTERVAL_C, default_poll_interval);
        if (remote_interval < chrono.seconds (5)) {
            GLib.warning ("Remote Interval is less than 5 seconds, reverting to " + DEFAULT_REMOTE_POLL_INTERVAL);
            remote_interval = default_poll_interval;
        }
        return remote_interval;
    }



    /***********************************************************
    Set poll interval. Value in milliseconds has to be larger
    than 5000

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public void remote_poll_interval (GLib.TimeSpan interval, string connection = "") {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;

        if (interval < chrono.seconds (5)) {
            GLib.warning ("Remote Poll interval of " + interval.count () + " is below five seconds.");
            return;
        }
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);
        settings.value (REMOTE_POLL_INTERVAL_C, int64 (interval.count ()));
        settings.sync ();
    }


    /***********************************************************
    Interval to check for new notifications

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan notification_refresh_interval (string connection = "") {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.minutes (5);
        var interval = milliseconds_value (settings, NOTIFICATION_REFRESH_INTERVAL_C, default_interval);
        if (interval < chrono.minutes (1)) {
            GLib.warning ("Notification refresh interval smaller than one minute; setting to one minute.");
            interval = chrono.minutes (1);
        }
        return interval;
    }


    /***********************************************************
    Force sync interval, in milliseconds

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan force_sync_interval (string connection = "") {
        var poll_interval = remote_poll_interval (connection);

        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.hours (2);
        var interval = milliseconds_value (settings, FORCE_SYNC_INTERVAL_C, default_interval);
        if (interval < poll_interval) {
            GLib.warning ("Force sync interval is less than the remote poll inteval; reverting to " + poll_interval.count ());
            interval = poll_interval;
        }
        return interval;
    }


    /***********************************************************
    Interval in milliseconds within which full local discovery
    is required

    Use -1 to disable regular full local discoveries.

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan full_local_discovery_interval () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (ConfigFile.default_connection);
        return milliseconds_value (settings, FULL_LOCAL_DISCOVERY_INTERVAL_C, chrono.hours (1));
    }


    bool mono_icons {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            bool mono_default = false; // On Mac we want bw by default
            return settings.value (MONO_ICONS_C, mono_default).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (MONO_ICONS_C, use_mono_icons);
        }
    }


    bool crash_reporter {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            var fallback = settings.value (CRASH_REPORTER_C, true);
            return get_policy_setting (CRASH_REPORTER_C, fallback).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (CRASH_REPORTER_C, value);
        }
    }


    bool prompt_delete_files {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (PROMPT_DELETE_C, false).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (PROMPT_DELETE_C, value);
        }
    }


    bool automatic_log_dir {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (AUTOMATIC_LOG_DIR_C, false).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (AUTOMATIC_LOG_DIR_C, value);
        }
    }

    string log_directory {
        public get {
            string default_log_dir = config_path () + "/logs";
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (LOG_DIR_C, default_log_dir).to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (LOG_DIR_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public 

    /***********************************************************
    ***********************************************************/
    bool log_debug {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (LOG_DEBUG_C, true).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (LOG_DEBUG_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    int log_expire {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (LOG_EXPIRE_C, 24).to_int ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (LOG_EXPIRE_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    bool log_flush {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (LOG_FLUSH_C, false).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (LOG_FLUSH_C, value);
        }
    }


    /***********************************************************
    Whether experimental UI options should be shown
    ***********************************************************/
    public bool show_experimental_options () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (SHOW_EXPERIMENTAL_OPTIONS_C, false).to_bool ();
    }


    /***********************************************************
    Proxy settings
    ***********************************************************/
    public void proxy_type (
        int proxy_type,
        string host = "",
        int port = 0,
        bool needs_auth = false,
        string user = "",
        string pass = "") {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.value (PROXY_TYPE_C, proxy_type);

        if (proxy_type == Soup.ProxyResolverDefault.HttpProxy || proxy_type == Soup.ProxyResolverDefault.Socks5Proxy) {
            settings.value (PROXY_HOST_C, host);
            settings.value (PROXY_PORT_C, port);
            settings.value (PROXY_NEEDS_AUTH_C, needs_auth);
            settings.value (PROXY_USER_C, user);

            if (pass == "") {
                // Security: Don't keep password in config file
                settings.remove (PROXY_PASS_C);

                // Delete password from keychain
                var job = new KeychainChunk.DeleteJob (KEYCHAIN_PROXY_PASSWORD_KEY ());
                job.exec ();
            } else {
                // Write password to keychain
                var job = new KeychainChunk.WriteJob (KEYCHAIN_PROXY_PASSWORD_KEY (), pass.to_utf8 ());
                if (job.exec ()) {
                    // Security: Don't keep password in config file
                    settings.remove (PROXY_PASS_C);
                }
            }
        }
        settings.sync ();
    }


    /***********************************************************
    ***********************************************************/
    public int proxy_type_from_instance () {
        if (Theme.force_system_network_proxy) {
            return Soup.ProxyResolverDefault.DefaultProxy;
        }
        return get_value (PROXY_TYPE_C).to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public string proxy_host_name () {
        return get_value (PROXY_HOST_C).to_string ();
    }

    /***********************************************************
    ***********************************************************/
    public int proxy_port () {
        return get_value (PROXY_PORT_C).to_int ();
    }



    /***********************************************************
    ***********************************************************/
    public bool proxy_needs_auth () {
        return get_value (PROXY_NEEDS_AUTH_C).to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public string proxy_user () {
        return get_value (PROXY_USER_C).to_string ();
    }



    /***********************************************************
    ***********************************************************/
    public string proxy_password ();
    string ConfigFile.proxy_password () {
        string pass_encoded = get_value (PROXY_PASS_C).to_byte_array ();
        var pass = string.from_utf8 (string.from_base64 (pass_encoded));
        pass_encoded.clear ();

        var key = KEYCHAIN_PROXY_PASSWORD_KEY ();

        if (!pass == "") {
            // Security : Migrate password from config file to keychain
            var job = new KeychainChunk.WriteJob (key, pass.to_utf8 ());
            if (job.exec ()) {
                GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
                settings.remove (PROXY_PASS_C);
                GLib.info ("Migrated proxy password to keychain.");
            }
        } else {
            // Read password from keychain
            var job = new KeychainChunk.ReadJob (key);
            if (job.exec ()) {
                pass = job.text_data ();
            }
        }

        return pass;
    }


    /***********************************************************
    0 : no limit, 1 : manual, >0 : automatic
    ***********************************************************/
    public int use_upload_limit ();
    int ConfigFile.use_upload_limit () {
        return get_value (USE_UPLOAD_LIMIT_C, "", 0).to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public int use_download_limit () {
        return get_value (USE_DOWNLOAD_LIMIT_C, "", 0).to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public void use_upload_limit_value (int val) {
        value (USE_UPLOAD_LIMIT_C, val);
    }


    /***********************************************************
    ***********************************************************/
    public void use_download_limit_vlaue (int val) {
        value (USE_DOWNLOAD_LIMIT_C, val);
    }



    /***********************************************************
    in kbyte/s
    ***********************************************************/
    public int upload_limit ();
    int ConfigFile.upload_limit () {
        return get_value (UPLOAD_LIMIT_C, "", 10).to_int ();
    }



    /***********************************************************
    ***********************************************************/
    public int download_limit ();
    int ConfigFile.download_limit () {
        return get_value (DOWNLOAD_LIMIT_C, "", 80).to_int ();
    }



    /***********************************************************
    ***********************************************************/
    public void upload_limit (int kbytes) {
        value (UPLOAD_LIMIT_C, kbytes);
    }


    /***********************************************************
    ***********************************************************/
    public void download_limit (int kbytes) {
        value (DOWNLOAD_LIMIT_C, kbytes);
    }


    /***********************************************************
    ***********************************************************/
    public struct SizeLimit {
        bool is_checked;
        int64 mbytes;
    }


    /***********************************************************
    [checked, size in MB]
    ***********************************************************/
    SizeLimit new_big_folder_size_limit {
        public get {
            var default_value = Theme.new_big_folder_size_limit;
            var fallback = get_value (NEW_BIG_FOLDER_SIZE_LIMIT_C, "", default_value).to_long_long ();
            var value = get_policy_setting (NEW_BIG_FOLDER_SIZE_LIMIT_C, fallback).to_long_long ();
            const bool use = value >= 0 && use_new_big_folder_size_limit ();
            return q_make_pair (use, q_max<int64> (0, value));
        }
        public set {
            value (NEW_BIG_FOLDER_SIZE_LIMIT_C, value.mbytes);
            value (USE_NEW_BIG_FOLDER_SIZE_LIMIT_C, value.is_checked);
        }
    }


    /***********************************************************
    ***********************************************************/
    bool confirm_external_storage {
        public get {
            var fallback = get_value (CONFIRM_EXTERNAL_STORAGE_C, "", true);
            return get_policy_setting (CONFIRM_EXTERNAL_STORAGE_C, fallback).to_bool ();
        }
        public set {
            value (CONFIRM_EXTERNAL_STORAGE_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool use_new_big_folder_size_limit () {
        var fallback = get_value (USE_NEW_BIG_FOLDER_SIZE_LIMIT_C, "", true);
        return get_policy_setting (USE_NEW_BIG_FOLDER_SIZE_LIMIT_C, fallback).to_bool ();
    }


    /***********************************************************
    If we should move the files deleted on the server in the
    trash
    ***********************************************************/
    bool move_to_trash  {
        public get {
            return get_value (MOVE_TO_TRASH_C, "", false).to_bool ();
        }
        public set {
            value (MOVE_TO_TRASH_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool show_main_dialog_as_normal_window () {
        return get_value (SHOW_MAIN_DIALOG_AS_NORMAL_WINDOW_C, {}, false).to_bool ();
    }




















    /***********************************************************
    ***********************************************************/
    private static chrono.milliseconds milliseconds_value (GLib.Settings setting, char key,
        chrono.milliseconds default_value) {
        return chrono.milliseconds (setting.value (key, int64 (default_value.count ())).to_long_long ());
    }


    /***********************************************************
    ***********************************************************/
    bool copy_dir_recursive (string from_dir, string to_dir) {
        GLib.Dir directory;
        directory.path (from_dir);

        from_dir += GLib.Dir.separator ();
        to_dir += GLib.Dir.separator ();

        foreach (string copy_file in directory.entry_list (GLib.Dir.Files)) {
            string from = from_dir + copy_file;
            string to = to_dir + copy_file;

            if (GLib.File.copy (from, to) == false) {
                return false;
            }
        }

        foreach (string copy_dir in directory.entry_list (GLib.Dir.Dirs | GLib.Dir.NoDotAndDotDot)) {
            string from = from_dir + copy_dir;
            string to = to_dir + copy_dir;

            if (directory.mkpath (to) == false) {
                return false;
            }

            if (copy_dir_recursive (from, to) == false) {
                return false;
            }
        }

        return true;
    }















    /***********************************************************
    ***********************************************************/
    bool optional_server_notifications {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (OPTIONAL_SERVER_NOTIFICATIONS_C, true).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (OPTIONAL_SERVER_NOTIFICATIONS_C, value);
            settings.sync ();
        }
    }


    /***********************************************************
    ***********************************************************/
    bool show_in_explorer_navigation_pane {
        public get {
            const bool default_value = false;
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (SHOW_IN_EXPLORER_NAVIGATION_PANE_C, default_value).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (SHOW_IN_EXPLORER_NAVIGATION_PANE_C, value);
            settings.sync ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public int timeout () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (TIMEOUT_C, 300).to_int (); // default to 5 min
    }


    /***********************************************************
    ***********************************************************/
    public int64 chunk_size () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (CHUNK_SIZE_C, 10 * 1000 * 1000).to_long_long (); // default to 10 MB
    }


    /***********************************************************
    ***********************************************************/
    public int64 max_chunk_size () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (MAX_CHUNK_SIZE_C, 1000 * 1000 * 1000).to_long_long (); // default to 1000 MB
    }


    /***********************************************************
    ***********************************************************/
    public int64 min_chunk_size () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (MIN_CHUNK_SIZE_C, 1000 * 1000).to_long_long (); // default to 1 MB
    }


    /***********************************************************
    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan target_chunk_upload_duration () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return milliseconds_value (settings, TARGET_CHUNK_UPLOAD_DURATION_C, chrono.minutes (1));
    }




    /***********************************************************
    ***********************************************************/
    public void save_geometry (Gtk.Widget w) {
    // #ifndef TOKEN_AUTH_ONLY
        //  ASSERT (!w.object_name ().is_null ());
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (w.object_name ());
        settings.value (GEOMETRY_C, w.save_geometry ());
        settings.sync ();
    // #endif
    }



    /***********************************************************
    ***********************************************************/
    public void restore_geometry (Gtk.Widget w) {
    // #ifndef TOKEN_AUTH_ONLY
        w.restore_geometry (get_value (GEOMETRY_C, w.object_name ()).to_byte_array ());
    // #endif
    }


    /***********************************************************
    ***********************************************************/
    void ConfigFile.save_geometry_header (QHeaderView header) {
    // #ifndef TOKEN_AUTH_ONLY
        if (!header)
            return;
        //  ASSERT (!header.object_name () == "");

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (header.object_name ());
        settings.value (GEOMETRY_C, header.save_state ());
        settings.sync ();
    // #endif
    }


    /***********************************************************
    ***********************************************************/
    void ConfigFile.restore_geometry_header (QHeaderView header) {
    // #ifndef TOKEN_AUTH_ONLY
        if (!header)
            return;
        //  ASSERT (!header.object_name ().is_null ());

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (header.object_name ());
        header.restore_state (settings.value (GEOMETRY_C).to_byte_array ());
    // #endif
    }


    /***********************************************************
    How often the check about new versions runs

    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan update_check_interval (string connection = "") {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.hours (10);
        var interval = milliseconds_value (settings, UPDATE_CHECK_INTERVAL_C, default_interval);

        var min_interval = chrono.minutes (5);
        if (interval < min_interval) {
            GLib.warning ("Update check interval less than five minutes; resetting to 5 minutes.");
            interval = min_interval;
        }
        return interval;
    }



    /***********************************************************
    skip_update_check completely disables the updater and hides its UI
    I need to figure out how to make this an attribte
    ***********************************************************/
    public bool skip_update_check (string connection = "") {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;

        GLib.Variant fallback = get_value (SKIP_UPDATE_CHECK_C, connection_string, false);
        fallback = get_value (SKIP_UPDATE_CHECK_C, "", fallback);

        GLib.Variant value = get_policy_setting (SKIP_UPDATE_CHECK_C, fallback);
        return value.to_bool ();
    }
    public void set_skip_update_check (bool skip, string connection) {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        settings.value (SKIP_UPDATE_CHECK_C, GLib.Variant (skip));
        settings.sync ();
    }


    /***********************************************************
    auto_update_check allows the user to make the choice in the UI
    ***********************************************************/
    public bool auto_update_check (string connection = "") {
        string connection_string = connection;
        if (connection == "") {
            connection_string = ConfigFile.default_connection;
        }

        GLib.Variant fallback = get_value (AUTO_UPDATE_CHECK_C, connection_string, true);
        fallback = get_value (AUTO_UPDATE_CHECK_C, "", fallback);

        GLib.Variant value = get_policy_setting (AUTO_UPDATE_CHECK_C, fallback);
        return value.to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public void set_auto_update_check (bool auto_check, string connection) {
        string connection_string = connection;
        if (connection == "")
            connection_string = ConfigFile.default_connection;

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        settings.value (AUTO_UPDATE_CHECK_C, GLib.Variant (auto_check));
        settings.sync ();
    }


    /***********************************************************
    Query-parameter 'updatesegment' for the update check, value between 0 and 99.
    Used to throttle down desktop release rollout in order to keep the update servers alive at peak times.
    See: https://github.com/nextcloud/client_updater_server/pull/36
    ***********************************************************/
    public int update_segment ();
    int ConfigFile.update_segment () {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        int segment = settings.value (UPDATE_SEGMENT_C, -1).to_int ();

        // Invalid? (Unset at the very first launch)
        if (segment < 0 || segment > 99) {
            // Save valid segment value, normally has to be done only once.
            segment = Utility.rand () % 99;
            settings.value (UPDATE_SEGMENT_C, segment);
        }

        return segment;
    }


    /***********************************************************
    ***********************************************************/
    public string update_channel;
    string ConfigFile.update_channel {
        string default_update_channel = "stable";
        string suffix = MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX);
        if (suffix.starts_with ("daily")
            || suffix.starts_with ("nightly")
            || suffix.starts_with ("alpha")
            || suffix.starts_with ("rc")
            || suffix.starts_with ("beta")) {
            default_update_channel = "beta";
        }

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        return settings.value (UPDATE_CHANNEL_C, default_update_channel).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public void update_channel (string channel) {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.value (UPDATE_CHANNEL_C, channel);
    }

    /***********************************************************
    ***********************************************************/
    //  public void restore_geometry_header


    /***********************************************************
    ***********************************************************/
    public string certificate_path () {
        return retrieve_data ("", CERT_PATH).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public void certificate_path_for_path (string c_path) {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        settings.value (CERT_PATH, c_path);
        settings.sync ();
    }


    /***********************************************************
    ***********************************************************/
    string certificate_password {
        public get {
            return retrieve_data ("", CERT_PASSWORD).to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (CERT_PASSWORD, value);
            settings.sync ();
        }
    }


    /***********************************************************
    The client version that last used this settings file.
    Updated by config_version_migration () at client startup.
    ***********************************************************/
    string client_version_string {
        public get {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            return settings.value (CLIENT_VERSION_C, "").to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
            settings.value (CLIENT_VERSION_C, value);
        }
    }


    /***********************************************************
    Returns a new settings pre-set in a specific group.  The Settings will be created
    with the given parent. If no parent is specified, the caller must destroy the settings
    ***********************************************************/
    public static GLib.Settings settings_with_group (string group, GLib.Object parent = new GLib.Object ()) {
        if (g_config_filename () == "") {
            // cache file name
            ConfigFile config;
            *g_config_filename () = config.ConfigFile.config_file;
        }
        GLib.Settings settings = new GLib.Settings (*g_config_filename (), GLib.Settings.IniFormat, parent);
        settings.begin_group (group);
        return settings;
    }


    /***********************************************************
    Add the system and user exclude file path to the ExcludedFiles instance.
    ***********************************************************/
    public static void setup_default_exclude_file_paths (ExcludedFiles excluded_files) {
        ConfigFile config;
        string system_list = config.exclude_file (ConfigFile.SYSTEM_SCOPE);
        string user_list = config.exclude_file (ConfigFile.USER_SCOPE);

        if (!GLib.File.exists (user_list)) {
            GLib.info ("User defined ignore list does not exist: " + user_list);
            if (!GLib.File.copy (system_list, user_list)) {
                GLib.info ("Could not copy over default list to: " + user_list);
            }
        }

        if (!GLib.File.exists (user_list)) {
            GLib.info ("Adding system ignore list to csync: " + system_list);
            excluded_files.add_exclude_file_path (system_list);
        } else {
            GLib.info ("Adding user defined ignore list to csync: " + user_list);
            excluded_files.add_exclude_file_path (user_list);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.Variant get_policy_setting (string policy, GLib.Variant default_value = GLib.Variant ()) {
        if (Utility.is_windows ()) {
            // check for policies first and return immediately if a value is found.
            GLib.Settings user_policy = new GLib.Settings(
                " (HKEY_CURRENT_USER\Software\Policies\%1\%2)"
                    .printf (APPLICATION_VENDOR, Theme.app_name_gui),
                GLib.Settings.NativeFormat);
            if (user_policy.contains (setting)) {
                return user_policy.value (setting);
            }

            GLib.Settings machine_policy = new GLib.Settings (
                " (HKEY_LOCAL_MACHINE\Software\Policies\%1\%2)"
                    .printf (APPLICATION_VENDOR, Theme.app_name_gui),
                GLib.Settings.NativeFormat);
            if (machine_policy.contains (setting)) {
                return machine_policy.value (setting);
            }
        }
        return default_value;
    }


    /***********************************************************
    ***********************************************************/
    protected void store_data (string group, string key, GLib.Variant value) {
        string connection_string = group == "" ? ConfigFile.default_connection : group;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        settings.value (key, value);
        settings.sync ();
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.Variant retrieve_data (string group, string key) {
        string connection_string = group == "" ? ConfigFile.default_connection : group;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        return settings.value (key);
    }


    /***********************************************************
    ***********************************************************/
    protected void remove_data (string group, string key) {
        string connection_string = group == "" ? ConfigFile.default_connection : group;
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        settings.remove (key);
    }


    protected bool data_exists (string key) {
        return data_exists_for_connection (key, ConfigFile.default_connection);
    }


    /***********************************************************
    ***********************************************************/
    protected bool data_exists_for_connection (string key, string group) {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.begin_group (group);
        return settings.contains (key);
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Variant get_value (string param, string group = "",
        GLib.Variant default_value = new GLib.Variant (param, group)) {
        GLib.Variant system_setting;
        if (Utility.is_mac ()) {
            GLib.Settings system_settings = new GLib.Settings ("/Library/Preferences/" + APPLICATION_REV_DOMAIN + ".plist", GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        } else if (Utility.is_unix ()) {
            GLib.Settings system_settings = new GLib.Settings (SYSCONFDIR + "/%1/%1.conf".printf (Theme.app_name), GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        } else { // Windows
            GLib.Settings system_settings = new GLib.Settings (
                " (HKEY_LOCAL_MACHINE\\Software\\%1\\%2)"
                    .printf (APPLICATION_VENDOR, Theme.app_name_gui),
                GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        }

        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);
        if (group != "") {
            settings.begin_group (group);
        }

        return settings.value (param, system_setting);
    }


    /***********************************************************
    ***********************************************************/
    private void value (string key, GLib.Variant value) {
        GLib.Settings settings = new GLib.Settings (ConfigFile.config_file, GLib.Settings.IniFormat);

        settings.value (key, value);
    }

} // class ConfigFile

} // namespace LibSync
} // namespace Occ
