/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
//  #include <Gtk.Widget>
//  #include <QHeaderView>
//  #endif

//  #include <QCoreApplication>
//  #include <QDir>
//  #include <GLib.FileInfo>
//  #include <QLoggingCategory>
//  #include <GLib.Settings>
//  #include <QNetworkProxy>
//  #include <QStandardPaths>

//  #if ! (QTLEGACY)
//  #include <QOperatingSystemVersion>
//  #endif


//  #include <memory>

//  #include <GLib.Settings>
//  #include <chrono>

namespace Occ {

/***********************************************************
@brief The ConfigFile class
@ingroup libsync
***********************************************************/
class ConfigFile {

    //  Q_GLOBAL_STATIC (string, g_config_filename)

    /***********************************************************
    ***********************************************************/
    public enum Scope {
        USER_SCOPE,
        SYSTEM_SCOPE
    }

    //  const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

    const int DEFAULT_REMOTE_POLL_INTERVAL = 30000 // default remote poll time in milliseconds
    const int DEFAULT_MAX_LOG_LINES = 20000
    
    
    //  namespace chrono = std.chrono;
    
    
    //  const string CA_CERTS_KEY_C = "CaCertificates"; only used from account
    const string REMOTE_POLL_INTERVAL_C = "remote_poll_interval";
    const string FORCE_SYNC_INTERVAL_C = "force_sync_interval";
    const string FULL_LOCAL_DISCOVERY_INTERVAL_C = "full_local_discovery_interval";
    const string NOTIFICATION_REFRESH_INTERVAL_C = "notification_refresh_interval";
    const string MONO_ICONS_C = "mono_icons";
    const string PROMPT_DELETE_C = "prompt_delete_all_files";
    const string CRASH_REPORTER_C = "crash_reporter";
    const string OPTIONAL_SERVER_NOTIFICATIONS_C = "optional_server_notifications";
    const string SHOW_IN_EXPLORER_NAVIGATION_PANE_C = "show_in_explorer_navigation_pane";
    const string SKIP_UPDATE_CHECK_C = "skip_update_check";
    const string AUTO_UPDATE_CHECK_C = "auto_update_check";
    const string UPDATE_CHECK_INTERVAL_C = "update_check_interval";
    const string UPDATE_SEGMENT_C = "update_segment";
    const string UPDATE_CHANNEL_C = "update_channel";
    const string GEOMETRY_C = "geometry";
    const string TIMEOUT_C = "timeout";
    const string CHUNK_SIZE_C = "chunk_size";
    const string MIN_CHUNK_SIZE_C = "min_chunk_size";
    const string MAX_CHUNK_SIZE_C = "max_chunk_size";
    const string TARGET_CHUNK_UPLOAD_DURATION_C = "target_chunk_upload_duration";
    const string AUTOMATIC_LOG_DIR_C = "log_to_temporary_log_dir";
    const string LOG_DIR_C = "log_dir";
    const string LOG_DEBUG_C = "log_debug";
    const string LOG_EXPIRE_C = "log_expire";
    const string LOG_FLUSH_C = "log_flush";
    const string SHOW_EXPERIMENTAL_OPTIONS_C = "show_experimental_options";
    const string CLIENT_VERSION_C = "client_version";
    
    const string PROXY_HOST_C = "Proxy/host";
    const string PROXY_TYPE_C = "Proxy/type";
    const string PROXY_PORT_C = "Proxy/port";
    const string PROXY_USER_C = "Proxy/user";
    const string PROXY_PASS_C = "Proxy/pass";
    const string PROXY_NEEDS_AUTH_C = "Proxy/needs_auth";
    
    const string USE_UPLOAD_LIMIT_C = "BWLimit/use_upload_limit";
    const string USE_DOWNLOAD_LIMIT_C = "BWLimit/use_download_limit";
    const string UPLOAD_LIMIT_C = "BWLimit/upload_limit";
    const string DOWNLOAD_LIMIT_C = "BWLimit/download_limit";
    
    const string NEW_BIG_FOLDER_SIZE_LIMIT_C = "new_big_folder_size_limit";
    const string USE_NEW_BIG_FOLDER_SIZE_LIMIT_C = "use_new_big_folder_size_limit";
    const string CONFIRM_EXTERNAL_STORAGE_C = "confirm_external_storage";
    const string MOVE_TO_TRASH_C = "move_to_trash";
    
    const string CERT_PATH = "http_certificate_path";
    const string CERT_PASSWORD = "http_certificate_password";

    const string SHOW_MAIN_DIALOG_AS_NORMAL_WINDOW_C = "show_main_dialog_as_normal_window";

    const string EXCL_FILE = "sync-exclude.lst";

    private const string KEYCHAIN_PROXY_PASSWORD_KEY = "proxy-password";

    /***********************************************************
    ***********************************************************/
    private static bool asked_user = false;
    private static string oc_version;

    /***********************************************************
    How do I initialize a static attribute?

    this.conf_dir = "";
    ***********************************************************/
    static string conf_dir {
        private get {
            return this.conf_dir;
        }
        public set {
            string dir_path = value;
            if (dir_path.is_empty ())
                return false;

            GLib.FileInfo file_info = new GLib.FileInfo (dir_path);
            if (!file_info.exists ()) {
                QDir ().mkpath (dir_path);
                file_info.file (dir_path);
            }
            if (file_info.exists () && file_info.is_dir ()) {
                dir_path = file_info.absolute_file_path ();
                GLib.info ("Using custom config directory " + dir_path;
                this.conf_dir = dir_path;
                return true;
            }
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public ConfigFile () {
        // QDesktopServices uses the application name to create a config path
        Gtk.Application.application_name (Theme.instance ().app_name_gui ());

        GLib.Settings.default_format (GLib.Settings.IniFormat);

        const string config = config_file ();

        GLib.Settings settings = new GLib.Settings (config, GLib.Settings.IniFormat);
        settings.begin_group (default_connection ());
    }


    /***********************************************************
    ***********************************************************/
    public string config_path () {
        if (this.conf_dir.is_empty ()) {
            if (!Utility.is_windows ()) {
                // On Unix, use the AppConfigLocation for the settings, that's configurable with the XDG_CONFIG_HOME env variable.
                this.conf_dir = QStandardPaths.writable_location (QStandardPaths.AppConfigLocation);
            } else {
                // On Windows, use AppDataLocation, that's where the roaming data is and where we should store the config file
                var new_location = QStandardPaths.writable_location (QStandardPaths.AppDataLocation);

                // Check if this is the first time loading the new location
                if (!GLib.FileInfo (new_location).is_dir ()) {
                    // Migrate data to the new locations
                    var old_location = QStandardPaths.writable_location (QStandardPaths.AppConfigLocation);

                    // Only migrate if the old location exists.
                    if (GLib.FileInfo (old_location).is_dir ()) {
                        QDir ().mkpath (new_location);
                        copy_dir_recursive (old_location, new_location);
                    }
                }
                this.conf_dir = new_location;
            }
        }
        string directory = this.conf_dir;

        if (!directory.has_suffix ('/'))
            directory.append ('/');
        return directory;
    }


    /***********************************************************
    ***********************************************************/
    public string config_file () {
        return config_path () + Theme.instance ().config_filename ();
    }


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    Prefer sync-exclude.lst, but if it does not exist, check for
    exclude.lst for compatibility reasons in the user writeable
    directories.
    ***********************************************************/
    public string exclude_file (Scope scope) {
        GLib.FileInfo file_info;

        switch (scope) {
        case USER_SCOPE:
            file_info.file (config_path (), EXCL_FILE);

            if (!file_info.is_readable ()) {
                file_info.file (config_path (), QLatin1String ("exclude.lst"));
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
        file_info.file (string (SYSCONFDIR "/" + Theme.instance ().app_name ()), EXCL_FILE);
        if (!file_info.exists ()) {
            // Prefer to return the preferred path! Only use the fallback location
            // if the other path does not exist and the fallback is valid.
            GLib.FileInfo next_to_binary (QCoreApplication.application_dir_path (), EXCL_FILE);
            if (next_to_binary.exists ()) {
                file_info = next_to_binary;
            } else {
                // For AppImage, the file might reside under a temporary mount path
                QDir d (QCoreApplication.application_dir_path ()); // supposed to be /tmp/mount.xyz/usr/bin
                d.cd_up (); // go out of bin
                d.cd_up (); // go out of usr
                if (!d.is_root ()) { // it is really a mountpoint
                    if (d.cd ("etc") && d.cd (Theme.instance ().app_name ())) {
                        GLib.FileInfo in_mount_dir (d, EXCL_FILE);
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
    public string backup () {
        string base_file = config_file ();
        var version_string = client_version_string ();
        if (!version_string.is_empty ())
            version_string.prepend ('_');
        string backup_file =
            string ("%1.backup_%2%3")
                .arg (base_file)
                .arg (GLib.DateTime.current_date_time ().to_string () + "yyyy_mMdd_HHmmss"))
                .arg (version_string);

        // If this exact file already exists it's most likely that a backup was
        // already done. (two backup calls directly after each other, potentially
        // even with source alterations in between!)
        if (!GLib.File.exists (backup_file)) {
            GLib.File f (base_file);
            f.copy (backup_file);
        }
        return backup_file;
    }


    /***********************************************************
    ***********************************************************/
    public bool exists () {
        GLib.File file = GLib.File.new_for_path (config_file ());
        return file.exists ();
    }


    /***********************************************************
    ***********************************************************/
    public string default_connection () {
        return Theme.instance ().app_name ();
    }


    /***********************************************************
    The certificates do not depend on a connection.
    ***********************************************************/
    GLib.ByteArray ca_certificates { public get; public set; }


    /***********************************************************
    ***********************************************************/
    public bool password_storage_allowed (string connection = "");


    /***********************************************************
    Server poll interval in milliseconds
    ***********************************************************/
    public std.chrono.milliseconds remote_poll_interval_for_connection (string connection = "") {
        string connection_string = connection;
        if (connection == "") {
            connection_string = default_connection ();
        }

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_poll_interval = chrono.milliseconds (DEFAULT_REMOTE_POLL_INTERVAL);
        var remote_interval = milliseconds_value (settings, REMOTE_POLL_INTERVAL_C, default_poll_interval);
        if (remote_interval < chrono.seconds (5)) {
            GLib.warning ("Remote Interval is less than 5 seconds, reverting to" + DEFAULT_REMOTE_POLL_INTERVAL;
            remote_interval = default_poll_interval;
        }
        return remote_interval;
    }



    /***********************************************************
    Set poll interval. Value in milliseconds has to be larger
    than 5000
    ***********************************************************/
    public void remote_poll_interval (std.chrono.milliseconds interval, string connection = "") {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();

        if (interval < chrono.seconds (5)) {
            GLib.warning ("Remote Poll interval of " + interval.count (" is below five seconds.";
            return;
        }
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);
        settings.value (QLatin1String (REMOTE_POLL_INTERVAL_C), int64 (interval.count ()));
        settings.sync ();
    }


    /***********************************************************
    Interval to check for new notifications
    ***********************************************************/
    public std.chrono.milliseconds notification_refresh_interval (string connection = "") {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.minutes (5);
        var interval = milliseconds_value (settings, NOTIFICATION_REFRESH_INTERVAL_C, default_interval);
        if (interval < chrono.minutes (1)) {
            GLib.warning ("Notification refresh interval smaller than one minute, setting to one minute";
            interval = chrono.minutes (1);
        }
        return interval;
    }


    /***********************************************************
    Force sync interval, in milliseconds
    ***********************************************************/
    public std.chrono.milliseconds force_sync_interval (string connection = "") {
        var poll_interval = remote_poll_interval (connection);

        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.hours (2);
        var interval = milliseconds_value (settings, FORCE_SYNC_INTERVAL_C, default_interval);
        if (interval < poll_interval) {
            GLib.warning ("Force sync interval is less than the remote poll inteval, reverting to" + poll_interval.count ();
            interval = poll_interval;
        }
        return interval;
    }


    /***********************************************************
    Interval in milliseconds within which full local discovery
    is required

    Use -1 to disable regular full local discoveries.
    ***********************************************************/
    public std.chrono.milliseconds full_local_discovery_interval () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (default_connection ());
        return milliseconds_value (settings, FULL_LOCAL_DISCOVERY_INTERVAL_C, chrono.hours (1));
    }


    bool mono_icons {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            bool mono_default = false; // On Mac we want bw by default
            return settings.value (QLatin1String (MONO_ICONS_C), mono_default).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (MONO_ICONS_C), use_mono_icons);
        }
    }


    bool crash_reporter {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            var fallback = settings.value (QLatin1String (CRASH_REPORTER_C), true);
            return get_policy_setting (QLatin1String (CRASH_REPORTER_C), fallback).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (CRASH_REPORTER_C), value);
        }
    }


    bool prompt_delete_files {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (PROMPT_DELETE_C), false).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (PROMPT_DELETE_C), value);
        }
    }


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public bool automatic_log_dir () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (AUTOMATIC_LOG_DIR_C), false).to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public void automatic_log_dir (bool enabled) {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.value (QLatin1String (AUTOMATIC_LOG_DIR_C), enabled);
    }


    string log_directory {
        public get {
            string default_log_dir = config_path () + "/logs";
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (LOG_DIR_C), default_log_dir).to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (LOG_DIR_C), value);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public 

    /***********************************************************
    ***********************************************************/
    bool log_debug {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (LOG_DEBUG_C), true).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (LOG_DEBUG_C), enabled);
        }
    }


    /***********************************************************
    ***********************************************************/
    int log_expire {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (LOG_EXPIRE_C), 24).to_int ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (LOG_EXPIRE_C), hours);
        }
    }


    /***********************************************************
    ***********************************************************/
    bool log_flush {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (LOG_FLUSH_C), false).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (LOG_FLUSH_C), value);
        }
    }


    /***********************************************************
    Whether experimental UI options should be shown
    ***********************************************************/
    public bool show_experimental_options () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (SHOW_EXPERIMENTAL_OPTIONS_C), false).to_bool ();
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
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.value (QLatin1String (PROXY_TYPE_C), proxy_type);

        if (proxy_type == QNetworkProxy.HttpProxy || proxy_type == QNetworkProxy.Socks5Proxy) {
            settings.value (QLatin1String (PROXY_HOST_C), host);
            settings.value (QLatin1String (PROXY_PORT_C), port);
            settings.value (QLatin1String (PROXY_NEEDS_AUTH_C), needs_auth);
            settings.value (QLatin1String (PROXY_USER_C), user);

            if (pass.is_empty ()) {
                // Security : Don't keep password in config file
                settings.remove (QLatin1String (PROXY_PASS_C));

                // Delete password from keychain
                var job = new KeychainChunk.DeleteJob (KEYCHAIN_PROXY_PASSWORD_KEY ());
                job.exec ();
            } else {
                // Write password to keychain
                var job = new KeychainChunk.WriteJob (KEYCHAIN_PROXY_PASSWORD_KEY (), pass.to_utf8 ());
                if (job.exec ()) {
                    // Security : Don't keep password in config file
                    settings.remove (QLatin1String (PROXY_PASS_C));
                }
            }
        }
        settings.sync ();
    }




    /***********************************************************
    ***********************************************************/
    public int proxy_type_from_instance () {
        if (Theme.instance ().force_system_network_proxy ()) {
            return QNetworkProxy.DefaultProxy;
        }
        return get_value (QLatin1String (PROXY_TYPE_C)).to_int ();
    }



    /***********************************************************
    ***********************************************************/
    public string proxy_host_name () {
        return get_value (QLatin1String (PROXY_HOST_C)).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int proxy_port ();
    int ConfigFile.proxy_port () {
        return get_value (QLatin1String (PROXY_PORT_C)).to_int ();
    }



    /***********************************************************
    ***********************************************************/
    public 
    bool ConfigFile.proxy_needs_auth () {
        return get_value (QLatin1String (PROXY_NEEDS_AUTH_C)).to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public string proxy_user ();
    string ConfigFile.proxy_user () {
        return get_value (QLatin1String (PROXY_USER_C)).to_string ();
    }



    /***********************************************************
    ***********************************************************/
    public string proxy_password ();
    string ConfigFile.proxy_password () {
        GLib.ByteArray pass_encoded = get_value (PROXY_PASS_C).to_byte_array ();
        var pass = string.from_utf8 (GLib.ByteArray.from_base64 (pass_encoded));
        pass_encoded.clear ();

        var key = KEYCHAIN_PROXY_PASSWORD_KEY ();

        if (!pass.is_empty ()) {
            // Security : Migrate password from config file to keychain
            var job = new KeychainChunk.WriteJob (key, pass.to_utf8 ());
            if (job.exec ()) {
                GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
                settings.remove (QLatin1String (PROXY_PASS_C));
                GLib.info ("Migrated proxy password to keychain";
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
    public int use_download_limit ();
    int ConfigFile.use_download_limit () {
        return get_value (USE_DOWNLOAD_LIMIT_C, "", 0).to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public 
    void ConfigFile.use_upload_limit (int val) {
        value (USE_UPLOAD_LIMIT_C, val);
    }


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public void use_download_limit (int);
    void ConfigFile.use_download_limit (int val) {
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
    public 
    void ConfigFile.upload_limit (int kbytes) {
        value (UPLOAD_LIMIT_C, kbytes);
    }


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public void download_limit (int kbytes);
    void ConfigFile.download_limit (int kbytes) {
        value (DOWNLOAD_LIMIT_C, kbytes);
    }


    public struct SizeLimit {
        bool is_checked;
        int64 mbytes;
    }

    /***********************************************************
    [checked, size in MB]
    ***********************************************************/
    SizeLimit new_big_folder_size_limit {
        public get {
            var default_value = Theme.instance ().new_big_folder_size_limit ();
            var fallback = get_value (NEW_BIG_FOLDER_SIZE_LIMIT_C, "", default_value).to_long_long ();
            var value = get_policy_setting (QLatin1String (NEW_BIG_FOLDER_SIZE_LIMIT_C), fallback).to_long_long ();
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
            return get_policy_setting (QLatin1String (CONFIRM_EXTERNAL_STORAGE_C), fallback).to_bool ();
        }
        public set {
            value (CONFIRM_EXTERNAL_STORAGE_C, value);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool use_new_big_folder_size_limit () {
        var fallback = get_value (USE_NEW_BIG_FOLDER_SIZE_LIMIT_C, "", true);
        return get_policy_setting (QLatin1String (USE_NEW_BIG_FOLDER_SIZE_LIMIT_C), fallback).to_bool ();
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
        return chrono.milliseconds (setting.value (QLatin1String (key), int64 (default_value.count ())).to_long_long ());
    }


    /***********************************************************
    ***********************************************************/
    bool copy_dir_recursive (string from_dir, string to_dir) {
        QDir directory;
        directory.path (from_dir);

        from_dir += QDir.separator ();
        to_dir += QDir.separator ();

        foreach (string copy_file in directory.entry_list (QDir.Files)) {
            string from = from_dir + copy_file;
            string to = to_dir + copy_file;

            if (GLib.File.copy (from, to) == false) {
                return false;
            }
        }

        foreach (string copy_dir in directory.entry_list (QDir.Dirs | QDir.NoDotAndDotDot)) {
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
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (OPTIONAL_SERVER_NOTIFICATIONS_C), true).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (OPTIONAL_SERVER_NOTIFICATIONS_C), value);
            settings.sync ();
        }
    }


    /***********************************************************
    ***********************************************************/
    bool show_in_explorer_navigation_pane {
        public get {
            const bool default_value = false;
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (SHOW_IN_EXPLORER_NAVIGATION_PANE_C), default_value).to_bool ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (SHOW_IN_EXPLORER_NAVIGATION_PANE_C), value);
            settings.sync ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public int timeout () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (TIMEOUT_C), 300).to_int (); // default to 5 min
    }


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    int64 ConfigFile.chunk_size () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (CHUNK_SIZE_C), 10 * 1000 * 1000).to_long_long (); // default to 10 MB
    }


    /***********************************************************
    ***********************************************************/
    public int64 max_chunk_size ();
    int64 ConfigFile.max_chunk_size () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (MAX_CHUNK_SIZE_C), 1000 * 1000 * 1000).to_long_long (); // default to 1000 MB
    }


    /***********************************************************
    ***********************************************************/
    public 
    int64 ConfigFile.min_chunk_size () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (MIN_CHUNK_SIZE_C), 1000 * 1000).to_long_long (); // default to 1 MB
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds target_chunk_upload_duration () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return milliseconds_value (settings, TARGET_CHUNK_UPLOAD_DURATION_C, chrono.minutes (1));
    }




    /***********************************************************
    ***********************************************************/
    public void save_geometry (Gtk.Widget w) {
    // #ifndef TOKEN_AUTH_ONLY
        //  ASSERT (!w.object_name ().is_null ());
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (w.object_name ());
        settings.value (QLatin1String (GEOMETRY_C), w.save_geometry ());
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
        //  ASSERT (!header.object_name ().is_empty ());

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (header.object_name ());
        settings.value (QLatin1String (GEOMETRY_C), header.save_state ());
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

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (header.object_name ());
        header.restore_state (settings.value (GEOMETRY_C).to_byte_array ());
    // #endif
    }


    /***********************************************************
    How often the check about new versions runs
    ***********************************************************/
    public std.chrono.milliseconds update_check_interval (string connection = "");
    chrono.milliseconds ConfigFile.update_check_interval (string connection) {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        var default_interval = chrono.hours (10);
        var interval = milliseconds_value (settings, UPDATE_CHECK_INTERVAL_C, default_interval);

        var min_interval = chrono.minutes (5);
        if (interval < min_interval) {
            GLib.warning ("Update check interval less than five minutes, resetting to 5 minutes";
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
        if (connection.is_empty ())
            connection_string = default_connection ();

        GLib.Variant fallback = get_value (QLatin1String (SKIP_UPDATE_CHECK_C), connection_string, false);
        fallback = get_value (QLatin1String (SKIP_UPDATE_CHECK_C), "", fallback);

        GLib.Variant value = get_policy_setting (QLatin1String (SKIP_UPDATE_CHECK_C), fallback);
        return value.to_bool ();
    }
    public void set_skip_update_check (bool skip, string connection) {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        settings.value (QLatin1String (SKIP_UPDATE_CHECK_C), GLib.Variant (skip));
        settings.sync ();
    }


    /***********************************************************
    auto_update_check allows the user to make the choice in the UI
    ***********************************************************/
    public bool auto_update_check (string connection = "") {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();

        GLib.Variant fallback = get_value (QLatin1String (AUTO_UPDATE_CHECK_C), connection_string, true);
        fallback = get_value (QLatin1String (AUTO_UPDATE_CHECK_C), "", fallback);

        GLib.Variant value = get_policy_setting (QLatin1String (AUTO_UPDATE_CHECK_C), fallback);
        return value.to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public void set_auto_update_check (bool auto_check, string connection) {
        string connection_string = connection;
        if (connection.is_empty ())
            connection_string = default_connection ();

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.begin_group (connection_string);

        settings.value (QLatin1String (AUTO_UPDATE_CHECK_C), GLib.Variant (auto_check));
        settings.sync ();
    }


    /***********************************************************
    Query-parameter 'updatesegment' for the update check, value between 0 and 99.
    Used to throttle down desktop release rollout in order to keep the update servers alive at peak times.
    See: https://github.com/nextcloud/client_updater_server/pull/36
    ***********************************************************/
    public int update_segment ();
    int ConfigFile.update_segment () {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        int segment = settings.value (QLatin1String (UPDATE_SEGMENT_C), -1).to_int ();

        // Invalid? (Unset at the very first launch)
        if (segment < 0 || segment > 99) {
            // Save valid segment value, normally has to be done only once.
            segment = Utility.rand () % 99;
            settings.value (QLatin1String (UPDATE_SEGMENT_C), segment);
        }

        return segment;
    }


    /***********************************************************
    ***********************************************************/
    public string update_channel ();
    string ConfigFile.update_channel () {
        string default_update_channel = "stable";
        string suffix = string.from_latin1 (MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX));
        if (suffix.starts_with ("daily")
            || suffix.starts_with ("nightly")
            || suffix.starts_with ("alpha")
            || suffix.starts_with ("rc")
            || suffix.starts_with ("beta")) {
            default_update_channel = "beta";
        }

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        return settings.value (QLatin1String (UPDATE_CHANNEL_C), default_update_channel).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public 
    void ConfigFile.update_channel (string channel) {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.value (QLatin1String (UPDATE_CHANNEL_C), channel);
    }


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void restore_geometry_header


    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public string certificate_path () {
        return retrieve_data ("", QLatin1String (CERT_PATH)).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public void certificate_path (string c_path) {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        settings.value (QLatin1String (CERT_PATH), c_path);
        settings.sync ();
    }


    /***********************************************************
    ***********************************************************/
    string certificate_password {
        public get {
            return retrieve_data ("", QLatin1String (CERT_PASSWORD)).to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (CERT_PASSWORD), value);
            settings.sync ();
        }
    }


    /***********************************************************
    The client version that last used this settings file.
    Updated by config_version_migration () at client startup.
    ***********************************************************/
    string client_version_string {
        public get {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            return settings.value (QLatin1String (CLIENT_VERSION_C), "").to_string ();
        }
        public set {
            GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
            settings.value (QLatin1String (CLIENT_VERSION_C), value);
        }
    }


    /***********************************************************
    Returns a new settings pre-set in a specific group.  The Settings will be created
    with the given parent. If no parent is specified, the caller must destroy the settings
    ***********************************************************/
    public static std.unique_ptr<GLib.Settings> settings_with_group (string group, GLib.Object parent = new GLib.Object ()) {
        if (g_config_filename ().is_empty ()) {
            // cache file name
            ConfigFile config;
            *g_config_filename () = config.config_file ();
        }
        std.unique_ptr<GLib.Settings> settings (new GLib.Settings (*g_config_filename (), GLib.Settings.IniFormat, parent));
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
            GLib.info ("User defined ignore list does not exist:" + user_list;
            if (!GLib.File.copy (system_list, user_list)) {
                GLib.info ("Could not copy over default list to:" + user_list;
            }
        }

        if (!GLib.File.exists (user_list)) {
            GLib.info ("Adding system ignore list to csync:" + system_list;
            excluded_files.add_exclude_file_path (system_list);
        } else {
            GLib.info ("Adding user defined ignore list to csync:" + user_list;
            excluded_files.add_exclude_file_path (user_list);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.Variant get_policy_setting (string policy, GLib.Variant default_value = GLib.Variant ()) {
        if (Utility.is_windows ()) {
            // check for policies first and return immediately if a value is found.
            GLib.Settings user_policy = new GLib.Settings(string.from_latin1 (R" (HKEY_CURRENT_USER\Software\Policies\%1\%2)")
                                    .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
                GLib.Settings.NativeFormat);
            if (user_policy.contains (setting)) {
                return user_policy.value (setting);
            }

            GLib.Settings machine_policy = new GLib.Settings (string.from_latin1 (R" (HKEY_LOCAL_MACHINE\Software\Policies\%1\%2)")
                                        .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
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
        string connection_string = group == "" ? default_connection () : group;
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        settings.value (key, value);
        settings.sync ();
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.Variant retrieve_data (string group, string key) {
        string connection_string = group == "" ? default_connection () : group;
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        return settings.value (key);
    }


    /***********************************************************
    ***********************************************************/
    protected void remove_data (string group, string key) {
        string connection_string = group == "" ? default_connection () : group;
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        settings.remove (key);
    }


    /***********************************************************
    ***********************************************************/
    protected bool data_exists (string group, string key) {
        string connection_string = group == "" ? default_connection () : group;
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.begin_group (connection_string);
        return settings.contains (key);
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Variant get_value (string param, string group = "",
        GLib.Variant default_value = new GLib.Variant ()) {
        GLib.Variant system_setting;
        if (Utility.is_mac ()) {
            GLib.Settings system_settings = new GLib.Settings ("/Library/Preferences/" + APPLICATION_REV_DOMAIN + ".plist", GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        } else if (Utility.is_unix ()) {
            GLib.Settings system_settings = new GLib.Settings (SYSCONFDIR + "/%1/%1.conf".arg (Theme.instance ().app_name ()), GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        } else { // Windows
            GLib.Settings system_settings = new GLib.Settings (" (HKEY_LOCAL_MACHINE\\Software\\%1\\%2)")
                .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
                GLib.Settings.NativeFormat);
            if (group != "") {
                system_settings.begin_group (group);
            }
            system_setting = system_settings.value (param, default_value);
        }

        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);
        if (group != "") {
            settings.begin_group (group);
        }

        return settings.value (param, system_setting);
    }


    /***********************************************************
    ***********************************************************/
    private void value (string key, GLib.Variant value) {
        GLib.Settings settings = new GLib.Settings (config_file (), GLib.Settings.IniFormat);

        settings.value (key, value);
    }

} // class ConfigFile

} // namespace Occ
