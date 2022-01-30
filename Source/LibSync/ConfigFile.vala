/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

#ifndef TOKEN_AUTH_ONLY
// #include <Gtk.Widget>
// #include <QHeaderView>
#endif

// #include <QCoreApplication>
// #include <QDir>
// #include <GLib.File>
// #include <QFileInfo>
// #include <QLoggingCategory>
// #include <QSettings>
// #include <QNetworkProxy>
// #include <QStandardPaths>

const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

#if ! (QTLEGACY)
// #include <QOperatingSystemVersion>
#endif

const int DEFAULT_REMOTE_POLL_INTERVAL 30000 // default remote poll time in milliseconds
const int DEFAULT_MAX_LOG_LINES 20000


namespace chrono = std.chrono;


//static const char CA_CERTS_KEY_C[] = "CaCertificates"; only used from account
static const char remote_poll_interval_c[] = "remote_poll_interval";
static const char force_sync_interval_c[] = "force_sync_interval";
static const char full_local_discovery_interval_c[] = "full_local_discovery_interval";
static const char notification_refresh_interval_c[] = "notification_refresh_interval";
static const char mono_icons_c[] = "mono_icons";
static const char prompt_delete_c[] = "prompt_delete_all_files";
static const char crash_reporter_c[] = "crash_reporter";
static const char optional_server_notifications_c[] = "optional_server_notifications";
static const char show_in_explorer_navigation_pane_c[] = "show_in_explorer_navigation_pane";
static const char skip_update_check_c[] = "skip_update_check";
static const char auto_update_check_c[] = "auto_update_check";
static const char update_check_interval_c[] = "update_check_interval";
static const char update_segment_c[] = "update_segment";
static const char update_channel_c[] = "update_channel";
static const char geometry_c[] = "geometry";
static const char timeout_c[] = "timeout";
static const char chunk_size_c[] = "chunk_size";
static const char min_chunk_size_c[] = "min_chunk_size";
static const char max_chunk_size_c[] = "max_chunk_size";
static const char target_chunk_upload_duration_c[] = "target_chunk_upload_duration";
static const char automatic_log_dir_c[] = "log_to_temporary_log_dir";
static const char log_dir_c[] = "log_dir";
static const char log_debug_c[] = "log_debug";
static const char log_expire_c[] = "log_expire";
static const char log_flush_c[] = "log_flush";
static const char show_experimental_options_c[] = "show_experimental_options";
static const char client_version_c[] = "client_version";

static const char proxy_host_c[] = "Proxy/host";
static const char proxy_type_c[] = "Proxy/type";
static const char proxy_port_c[] = "Proxy/port";
static const char proxy_user_c[] = "Proxy/user";
static const char proxy_pass_c[] = "Proxy/pass";
static const char proxy_needs_auth_c[] = "Proxy/needs_auth";

static const char use_upload_limit_c[] = "BWLimit/use_upload_limit";
static const char use_download_limit_c[] = "BWLimit/use_download_limit";
static const char upload_limit_c[] = "BWLimit/upload_limit";
static const char download_limit_c[] = "BWLimit/download_limit";

static const char new_big_folder_size_limit_c[] = "new_big_folder_size_limit";
static const char use_new_big_folder_size_limit_c[] = "use_new_big_folder_size_limit";
static const char confirm_external_storage_c[] = "confirm_external_storage";
static const char move_to_trash_c[] = "move_to_trash";

const char cert_path[] = "http_certificate_path";
const char cert_passwd[] = "http_certificate_passwd";
string ConfigFile._conf_dir = "";
bool ConfigFile._asked_user = false;

namespace {
static constexpr char show_main_dialog_as_normal_window_c[] = "show_main_dialog_as_normal_window";
}

// #include <memory>

// #include <QSettings>
// #include <string>
// #include <QVariant>
// #include <chrono>


namespace Occ {


/***********************************************************
@brief The ConfigFile class
@ingroup libsync
***********************************************************/
class ConfigFile {

    /***********************************************************
    ***********************************************************/
    public ConfigFile ();

    /***********************************************************
    ***********************************************************/
    public enum Scope {
        UserScope,
        SystemScope
    };

    /***********************************************************
    ***********************************************************/
    public string config_path ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string exclude_file (Scope scope);


    public static string exclude_file_from_system (); // doesn't access config dir

    /***********************************************************
    Creates a backup of the file

    Returns the path of the new backup.
    ***********************************************************/
    public string backup ();

    /***********************************************************
    ***********************************************************/
    public bool exists ();

    /***********************************************************
    ***********************************************************/
    public string default_connection ();

    // the certs do not depend on a connection.
    public GLib.ByteArray ca_certs ();


    /***********************************************************
    ***********************************************************/
    public void set_ca_certs (GLib.ByteArray );

    /***********************************************************
    ***********************************************************/
    public bool password_storage_allowed (string connection = "");


    /***********************************************************
    Server poll interval in milliseconds
    ***********************************************************/

    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds remote_poll_interval (string connection = "");


    /***********************************************************
    Set poll interval. Value in milliseconds has to be larger than 5000
    ***********************************************************/
    public void set_remote_poll_interval (std.chrono.milliseconds interval, string connection = "");


    /***********************************************************
    Interval to check for new notifications
    ***********************************************************/
    public std.chrono.milliseconds notification_refresh_interval (string connection = "");


    /***********************************************************
    Force sync interval, in milliseconds
    ***********************************************************/
    public std.chrono.milliseconds force_sync_interval (string connection = "");


    /***********************************************************
    Interval in milliseconds within which full local discovery is required

    Use -1 to disable regular full local discoveries.
    ***********************************************************/
    public std.chrono.milliseconds full_local_discovery_interval ();

    /***********************************************************
    ***********************************************************/
    public bool mono_icons ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_prompt_delete_f

    /***********************************************************
    ***********************************************************/
    public bool crash_reporter ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_automatic_log_dir (bo

    /***********************************************************
    ***********************************************************/
    public string log_dir ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_log_debug 

    /***********************************************************
    ***********************************************************/
    public int log_expire ();


    public void set_log_expire (int hours);

    public bool log_flush ();


    public void set_log_flush (bool enabled);

    // Whether experimental UI options should be shown
    public bool show_experimental_options ();

    // proxy settings
    public void set_proxy_type (int proxy_type,
        const string host = "",
        int port = 0, bool needs_auth = false,
        const string user = "",
        const string pass = "");

    /***********************************************************
    ***********************************************************/
    public int proxy_type ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int proxy_port ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public string proxy_user ();


    public string proxy_password ();


    /***********************************************************
    0 : no limit, 1 : manual, >0 : automatic
    ***********************************************************/
    public int use_upload_limit ();


    /***********************************************************
    ***********************************************************/
    public int use_download_limit ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void set_use_download_limit (int);
    /***********************************************************
    in kbyte/s
    ***********************************************************/
    public int upload_limit ();


    /***********************************************************
    ***********************************************************/
    public int download_limit ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void set_download_limit (int kbytes);
    /***********************************************************
    [checked, size in MB]
    ***********************************************************/
    public QPair<bool, int64> new_big_folder_size_limit ();


    /***********************************************************
    ***********************************************************/
    public void set_new_big_folder_size_limit (bool is_checked, int64 mbytes);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool confirm_external_storage ();


    public void set_confirm_external_storage (bool);


    /***********************************************************
    If we should move the files deleted on the server in the trash
    ***********************************************************/
    public bool move_to_trash ();


    /***********************************************************
    ***********************************************************/
    public void set_move_to_trash (bool);

    /***********************************************************
    ***********************************************************/
    public bool show_main_dialog_as_normal_window ();

    /***********************************************************
    ***********************************************************/
    public static bool set_conf_dir (string value);

    /***********************************************************
    ***********************************************************/
    public bool optional_server_notifications ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_show_in

    /***********************************************************
    ***********************************************************/
    public int timeout ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int64 max_chunk_size ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public std.chrono.milliseconds target_chunk_upload_duration ();

    public void save_geometry (Gtk.Widget w);


    public void restore_geometry (Gtk.Widget w);

    // how often the check about new versions runs
    public std.chrono.milliseconds update_check_interval (string connection = "");

    // skip_update_check completely disables the updater and hides its UI
    public bool skip_update_check (string connection = "");


    /***********************************************************
    ***********************************************************/
    public void set_skip_update_check (bool, string );

    // auto_update_check allows the user to make the choice in the UI
    public bool auto_update_check (string connection = "");


    /***********************************************************
    ***********************************************************/
    public void set_auto_update_check (bool, string );


    /***********************************************************
    Query-parameter 'updatesegment' for the update check, value between 0 and 99.
    Used to throttle down desktop release rollout in order to keep the update servers alive at peak times.
    See: https://github.com/nextcloud/client_updater_server/pull/36
    ***********************************************************/
    public int update_segment ();

    /***********************************************************
    ***********************************************************/
    public string update_channel ();

    /***********************************************************
    ***********************************************************/
    public 

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
    public string certificate_path ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public string certificate_passwd ();


    public void set_certificate_passwd (string c_passwd);


    /***********************************************************
    The client version that last used this settings file.
    Updated by config_version_migration () at client startup.
    ***********************************************************/
    public string client_version_"";


    /***********************************************************
    ***********************************************************/
    public void set_client_version_string (string version);


    /***********************************************************
    Returns a new settings pre-set in a specific group.  The Settings will be created
    with the given parent. If no parent is specified, the caller must destroy the settings
    ***********************************************************/
    public static std.unique_ptr<QSettings> settings_with_group (string group, GLib.Object parent = new GLib.Object ());

    /// Add the system and user exclude file path to the ExcludedFiles instance.
    public static void setup_default_exclude_file_paths (ExcludedFiles &excluded_files);


    protected QVariant get_policy_setting (string policy, QVariant &default_value = QVariant ());
    protected void store_data (string group, string key, QVariant &value);
    protected QVariant retrieve_data (string group, string key);
    protected void remove_data (string group, string key);
    protected bool data_exists (string group, string key);


    /***********************************************************
    ***********************************************************/
    private QVariant get_value (string param, string group = "",
        const QVariant &default_value = QVariant ());
    private void set_value (string key, QVariant &value);

    /***********************************************************
    ***********************************************************/
    private string keychain_proxy_password_key ();

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private static bool _asked_user;
    private static string _o_c_version;
    private static string _conf_dir;
};

static chrono.milliseconds milliseconds_value (QSettings &setting, char key,
    chrono.milliseconds default_value) {
    return chrono.milliseconds (setting.value (QLatin1String (key), qlonglong (default_value.count ())).to_long_long ());
}

bool copy_dir_recursive (string from_dir, string to_dir) {
    QDir dir;
    dir.set_path (from_dir);

    from_dir += QDir.separator ();
    to_dir += QDir.separator ();

    foreach (string copy_file, dir.entry_list (QDir.Files)) {
        string from = from_dir + copy_file;
        string to = to_dir + copy_file;

        if (GLib.File.copy (from, to) == false) {
            return false;
        }
    }

    foreach (string copy_dir, dir.entry_list (QDir.Dirs | QDir.NoDotAndDotDot)) {
        string from = from_dir + copy_dir;
        string to = to_dir + copy_dir;

        if (dir.mkpath (to) == false) {
            return false;
        }

        if (copy_dir_recursive (from, to) == false) {
            return false;
        }
    }

    return true;
}

ConfigFile.ConfigFile () {
    // QDesktopServices uses the application name to create a config path
    q_app.set_application_name (Theme.instance ().app_name_gui ());

    QSettings.set_default_format (QSettings.IniFormat);

    const string config = config_file ();

    QSettings settings (config, QSettings.IniFormat);
    settings.begin_group (default_connection ());
}

bool ConfigFile.set_conf_dir (string value) {
    string dir_path = value;
    if (dir_path.is_empty ())
        return false;

    QFileInfo fi (dir_path);
    if (!fi.exists ()) {
        QDir ().mkpath (dir_path);
        fi.set_file (dir_path);
    }
    if (fi.exists () && fi.is_dir ()) {
        dir_path = fi.absolute_file_path ();
        q_c_info (lc_config_file) << "Using custom config dir " << dir_path;
        _conf_dir = dir_path;
        return true;
    }
    return false;
}

bool ConfigFile.optional_server_notifications () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (optional_server_notifications_c), true).to_bool ();
}

bool ConfigFile.show_in_explorer_navigation_pane () {
    const bool default_value = false;
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (show_in_explorer_navigation_pane_c), default_value).to_bool ();
}

void ConfigFile.set_show_in_explorer_navigation_pane (bool show) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (show_in_explorer_navigation_pane_c), show);
    settings.sync ();
}

int ConfigFile.timeout () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (timeout_c), 300).to_int (); // default to 5 min
}

int64 ConfigFile.chunk_size () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (chunk_size_c), 10 * 1000 * 1000).to_long_long (); // default to 10 MB
}

int64 ConfigFile.max_chunk_size () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (max_chunk_size_c), 1000 * 1000 * 1000).to_long_long (); // default to 1000 MB
}

int64 ConfigFile.min_chunk_size () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (min_chunk_size_c), 1000 * 1000).to_long_long (); // default to 1 MB
}

chrono.milliseconds ConfigFile.target_chunk_upload_duration () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return milliseconds_value (settings, target_chunk_upload_duration_c, chrono.minutes (1));
}

void ConfigFile.set_optional_server_notifications (bool show) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (optional_server_notifications_c), show);
    settings.sync ();
}

void ConfigFile.save_geometry (Gtk.Widget w) {
#ifndef TOKEN_AUTH_ONLY
    ASSERT (!w.object_name ().is_null ());
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (w.object_name ());
    settings.set_value (QLatin1String (geometry_c), w.save_geometry ());
    settings.sync ();
#endif
}

void ConfigFile.restore_geometry (Gtk.Widget w) {
#ifndef TOKEN_AUTH_ONLY
    w.restore_geometry (get_value (geometry_c, w.object_name ()).to_byte_array ());
#endif
}

void ConfigFile.save_geometry_header (QHeaderView header) {
#ifndef TOKEN_AUTH_ONLY
    if (!header)
        return;
    ASSERT (!header.object_name ().is_empty ());

    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (header.object_name ());
    settings.set_value (QLatin1String (geometry_c), header.save_state ());
    settings.sync ();
#endif
}

void ConfigFile.restore_geometry_header (QHeaderView header) {
#ifndef TOKEN_AUTH_ONLY
    if (!header)
        return;
    ASSERT (!header.object_name ().is_null ());

    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (header.object_name ());
    header.restore_state (settings.value (geometry_c).to_byte_array ());
#endif
}

QVariant ConfigFile.get_policy_setting (string setting, QVariant &default_value) {
    if (Utility.is_windows ()) {
        // check for policies first and return immediately if a value is found.
        QSettings user_policy (string.from_latin1 (R" (HKEY_CURRENT_USER\Software\Policies\%1\%2)")
                                 .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
            QSettings.NativeFormat);
        if (user_policy.contains (setting)) {
            return user_policy.value (setting);
        }

        QSettings machine_policy (string.from_latin1 (R" (HKEY_LOCAL_MACHINE\Software\Policies\%1\%2)")
                                    .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
            QSettings.NativeFormat);
        if (machine_policy.contains (setting)) {
            return machine_policy.value (setting);
        }
    }
    return default_value;
}

string ConfigFile.config_path () {
    if (_conf_dir.is_empty ()) {
        if (!Utility.is_windows ()) {
            // On Unix, use the AppConfigLocation for the settings, that's configurable with the XDG_CONFIG_HOME env variable.
            _conf_dir = QStandardPaths.writable_location (QStandardPaths.AppConfigLocation);
        } else {
            // On Windows, use AppDataLocation, that's where the roaming data is and where we should store the config file
             var new_location = QStandardPaths.writable_location (QStandardPaths.AppDataLocation);

             // Check if this is the first time loading the new location
             if (!QFileInfo (new_location).is_dir ()) {
                 // Migrate data to the new locations
                 var old_location = QStandardPaths.writable_location (QStandardPaths.AppConfigLocation);

                 // Only migrate if the old location exists.
                 if (QFileInfo (old_location).is_dir ()) {
                     QDir ().mkpath (new_location);
                     copy_dir_recursive (old_location, new_location);
                 }
             }
            _conf_dir = new_location;
        }
    }
    string dir = _conf_dir;

    if (!dir.ends_with ('/'))
        dir.append ('/');
    return dir;
}

static const QLatin1String excl_file ("sync-exclude.lst");

string ConfigFile.exclude_file (Scope scope) {
    // prefer sync-exclude.lst, but if it does not exist, check for
    // exclude.lst for compatibility reasons in the user writeable
    // directories.
    QFileInfo fi;

    switch (scope) {
    case UserScope:
        fi.set_file (config_path (), excl_file);

        if (!fi.is_readable ()) {
            fi.set_file (config_path (), QLatin1String ("exclude.lst"));
        }
        if (!fi.is_readable ()) {
            fi.set_file (config_path (), excl_file);
        }
        return fi.absolute_file_path ();
    case SystemScope:
        return ConfigFile.exclude_file_from_system ();
    }

    ASSERT (false);
    return "";
}

string ConfigFile.exclude_file_from_system () {
    QFileInfo fi;
    fi.set_file (string (SYSCONFDIR "/" + Theme.instance ().app_name ()), excl_file);
    if (!fi.exists ()) {
        // Prefer to return the preferred path! Only use the fallback location
        // if the other path does not exist and the fallback is valid.
        QFileInfo next_to_binary (QCoreApplication.application_dir_path (), excl_file);
        if (next_to_binary.exists ()) {
            fi = next_to_binary;
        } else {
            // For AppImage, the file might reside under a temporary mount path
            QDir d (QCoreApplication.application_dir_path ()); // supposed to be /tmp/mount.xyz/usr/bin
            d.cd_up (); // go out of bin
            d.cd_up (); // go out of usr
            if (!d.is_root ()) { // it is really a mountpoint
                if (d.cd ("etc") && d.cd (Theme.instance ().app_name ())) {
                    QFileInfo in_mount_dir (d, excl_file);
                    if (in_mount_dir.exists ()) {
                        fi = in_mount_dir;
                    }
                };
            }
        }
    }

    return fi.absolute_file_path ();
}

string ConfigFile.backup () {
    string base_file = config_file ();
    var version_string = client_version_"";
    if (!version_string.is_empty ())
        version_string.prepend ('_');
    string backup_file =
        string ("%1.backup_%2%3")
            .arg (base_file)
            .arg (QDateTime.current_date_time ().to_string ("yyyy_mMdd_HHmmss"))
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

string ConfigFile.config_file () {
    return config_path () + Theme.instance ().config_file_name ();
}

bool ConfigFile.exists () {
    GLib.File file = new GLib.File (config_file ());
    return file.exists ();
}

string ConfigFile.default_connection () {
    return Theme.instance ().app_name ();
}

void ConfigFile.store_data (string group, string key, QVariant &value) {
    const string con (group.is_empty () ? default_connection () : group);
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.begin_group (con);
    settings.set_value (key, value);
    settings.sync ();
}

QVariant ConfigFile.retrieve_data (string group, string key) {
    const string con (group.is_empty () ? default_connection () : group);
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.begin_group (con);
    return settings.value (key);
}

void ConfigFile.remove_data (string group, string key) {
    const string con (group.is_empty () ? default_connection () : group);
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.begin_group (con);
    settings.remove (key);
}

bool ConfigFile.data_exists (string group, string key) {
    const string con (group.is_empty () ? default_connection () : group);
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.begin_group (con);
    return settings.contains (key);
}

chrono.milliseconds ConfigFile.remote_poll_interval (string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    var default_poll_interval = chrono.milliseconds (DEFAULT_REMOTE_POLL_INTERVAL);
    var remote_interval = milliseconds_value (settings, remote_poll_interval_c, default_poll_interval);
    if (remote_interval < chrono.seconds (5)) {
        GLib.warn (lc_config_file) << "Remote Interval is less than 5 seconds, reverting to" << DEFAULT_REMOTE_POLL_INTERVAL;
        remote_interval = default_poll_interval;
    }
    return remote_interval;
}

void ConfigFile.set_remote_poll_interval (chrono.milliseconds interval, string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    if (interval < chrono.seconds (5)) {
        GLib.warn (lc_config_file) << "Remote Poll interval of " << interval.count () << " is below five seconds.";
        return;
    }
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);
    settings.set_value (QLatin1String (remote_poll_interval_c), qlonglong (interval.count ()));
    settings.sync ();
}

chrono.milliseconds ConfigFile.force_sync_interval (string connection) {
    var poll_interval = remote_poll_interval (connection);

    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    var default_interval = chrono.hours (2);
    var interval = milliseconds_value (settings, force_sync_interval_c, default_interval);
    if (interval < poll_interval) {
        GLib.warn (lc_config_file) << "Force sync interval is less than the remote poll inteval, reverting to" << poll_interval.count ();
        interval = poll_interval;
    }
    return interval;
}

chrono.milliseconds Occ.ConfigFile.full_local_discovery_interval () {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (default_connection ());
    return milliseconds_value (settings, full_local_discovery_interval_c, chrono.hours (1));
}

chrono.milliseconds ConfigFile.notification_refresh_interval (string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    var default_interval = chrono.minutes (5);
    var interval = milliseconds_value (settings, notification_refresh_interval_c, default_interval);
    if (interval < chrono.minutes (1)) {
        GLib.warn (lc_config_file) << "Notification refresh interval smaller than one minute, setting to one minute";
        interval = chrono.minutes (1);
    }
    return interval;
}

chrono.milliseconds ConfigFile.update_check_interval (string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    var default_interval = chrono.hours (10);
    var interval = milliseconds_value (settings, update_check_interval_c, default_interval);

    var min_interval = chrono.minutes (5);
    if (interval < min_interval) {
        GLib.warn (lc_config_file) << "Update check interval less than five minutes, resetting to 5 minutes";
        interval = min_interval;
    }
    return interval;
}

bool ConfigFile.skip_update_check (string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    QVariant fallback = get_value (QLatin1String (skip_update_check_c), con, false);
    fallback = get_value (QLatin1String (skip_update_check_c), "", fallback);

    QVariant value = get_policy_setting (QLatin1String (skip_update_check_c), fallback);
    return value.to_bool ();
}

void ConfigFile.set_skip_update_check (bool skip, string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    settings.set_value (QLatin1String (skip_update_check_c), QVariant (skip));
    settings.sync ();
}

bool ConfigFile.auto_update_check (string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    QVariant fallback = get_value (QLatin1String (auto_update_check_c), con, true);
    fallback = get_value (QLatin1String (auto_update_check_c), "", fallback);

    QVariant value = get_policy_setting (QLatin1String (auto_update_check_c), fallback);
    return value.to_bool ();
}

void ConfigFile.set_auto_update_check (bool auto_check, string connection) {
    string con (connection);
    if (connection.is_empty ())
        con = default_connection ();

    QSettings settings (config_file (), QSettings.IniFormat);
    settings.begin_group (con);

    settings.set_value (QLatin1String (auto_update_check_c), QVariant (auto_check));
    settings.sync ();
}

int ConfigFile.update_segment () {
    QSettings settings (config_file (), QSettings.IniFormat);
    int segment = settings.value (QLatin1String (update_segment_c), -1).to_int ();

    // Invalid? (Unset at the very first launch)
    if (segment < 0 || segment > 99) {
        // Save valid segment value, normally has to be done only once.
        segment = Utility.rand () % 99;
        settings.set_value (QLatin1String (update_segment_c), segment);
    }

    return segment;
}

string ConfigFile.update_channel () {
    string default_update_channel = QStringLiteral ("stable");
    string suffix = string.from_latin1 (MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX));
    if (suffix.starts_with ("daily")
        || suffix.starts_with ("nightly")
        || suffix.starts_with ("alpha")
        || suffix.starts_with ("rc")
        || suffix.starts_with ("beta")) {
        default_update_channel = QStringLiteral ("beta");
    }

    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (update_channel_c), default_update_channel).to_"";
}

void ConfigFile.set_update_channel (string channel) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (update_channel_c), channel);
}

void ConfigFile.set_proxy_type (int proxy_type,
    const string host,
    int port, bool needs_auth,
    const string user,
    const string pass) {
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.set_value (QLatin1String (proxy_type_c), proxy_type);

    if (proxy_type == QNetworkProxy.HttpProxy || proxy_type == QNetworkProxy.Socks5Proxy) {
        settings.set_value (QLatin1String (proxy_host_c), host);
        settings.set_value (QLatin1String (proxy_port_c), port);
        settings.set_value (QLatin1String (proxy_needs_auth_c), needs_auth);
        settings.set_value (QLatin1String (proxy_user_c), user);

        if (pass.is_empty ()) {
            // Security : Don't keep password in config file
            settings.remove (QLatin1String (proxy_pass_c));

            // Delete password from keychain
            var job = new KeychainChunk.DeleteJob (keychain_proxy_password_key ());
            job.exec ();
        } else {
            // Write password to keychain
            var job = new KeychainChunk.WriteJob (keychain_proxy_password_key (), pass.to_utf8 ());
            if (job.exec ()) {
                // Security : Don't keep password in config file
                settings.remove (QLatin1String (proxy_pass_c));
            }
        }
    }
    settings.sync ();
}

QVariant ConfigFile.get_value (string param, string group,
    const QVariant &default_value) {
    QVariant system_setting;
    if (Utility.is_mac ()) {
        QSettings system_settings (QLatin1String ("/Library/Preferences/" APPLICATION_REV_DOMAIN ".plist"), QSettings.NativeFormat);
        if (!group.is_empty ()) {
            system_settings.begin_group (group);
        }
        system_setting = system_settings.value (param, default_value);
    } else if (Utility.is_unix ()) {
        QSettings system_settings (string (SYSCONFDIR "/%1/%1.conf").arg (Theme.instance ().app_name ()), QSettings.NativeFormat);
        if (!group.is_empty ()) {
            system_settings.begin_group (group);
        }
        system_setting = system_settings.value (param, default_value);
    } else { // Windows
        QSettings system_settings (string.from_latin1 (R" (HKEY_LOCAL_MACHINE\Software\%1\%2)")
                                     .arg (APPLICATION_VENDOR, Theme.instance ().app_name_gui ()),
            QSettings.NativeFormat);
        if (!group.is_empty ()) {
            system_settings.begin_group (group);
        }
        system_setting = system_settings.value (param, default_value);
    }

    QSettings settings (config_file (), QSettings.IniFormat);
    if (!group.is_empty ())
        settings.begin_group (group);

    return settings.value (param, system_setting);
}

void ConfigFile.set_value (string key, QVariant &value) {
    QSettings settings (config_file (), QSettings.IniFormat);

    settings.set_value (key, value);
}

int ConfigFile.proxy_type () {
    if (Theme.instance ().force_system_network_proxy ()) {
        return QNetworkProxy.DefaultProxy;
    }
    return get_value (QLatin1String (proxy_type_c)).to_int ();
}

string ConfigFile.proxy_host_name () {
    return get_value (QLatin1String (proxy_host_c)).to_"";
}

int ConfigFile.proxy_port () {
    return get_value (QLatin1String (proxy_port_c)).to_int ();
}

bool ConfigFile.proxy_needs_auth () {
    return get_value (QLatin1String (proxy_needs_auth_c)).to_bool ();
}

string ConfigFile.proxy_user () {
    return get_value (QLatin1String (proxy_user_c)).to_"";
}

string ConfigFile.proxy_password () {
    GLib.ByteArray pass_encoded = get_value (proxy_pass_c).to_byte_array ();
    var pass = string.from_utf8 (GLib.ByteArray.from_base64 (pass_encoded));
    pass_encoded.clear ();

    const var key = keychain_proxy_password_key ();

    if (!pass.is_empty ()) {
        // Security : Migrate password from config file to keychain
        var job = new KeychainChunk.WriteJob (key, pass.to_utf8 ());
        if (job.exec ()) {
            QSettings settings (config_file (), QSettings.IniFormat);
            settings.remove (QLatin1String (proxy_pass_c));
            q_c_info (lc_config_file ()) << "Migrated proxy password to keychain";
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

string ConfigFile.keychain_proxy_password_key () {
    return string.from_latin1 ("proxy-password");
}

int ConfigFile.use_upload_limit () {
    return get_value (use_upload_limit_c, "", 0).to_int ();
}

int ConfigFile.use_download_limit () {
    return get_value (use_download_limit_c, "", 0).to_int ();
}

void ConfigFile.set_use_upload_limit (int val) {
    set_value (use_upload_limit_c, val);
}

void ConfigFile.set_use_download_limit (int val) {
    set_value (use_download_limit_c, val);
}

int ConfigFile.upload_limit () {
    return get_value (upload_limit_c, "", 10).to_int ();
}

int ConfigFile.download_limit () {
    return get_value (download_limit_c, "", 80).to_int ();
}

void ConfigFile.set_upload_limit (int kbytes) {
    set_value (upload_limit_c, kbytes);
}

void ConfigFile.set_download_limit (int kbytes) {
    set_value (download_limit_c, kbytes);
}

QPair<bool, int64> ConfigFile.new_big_folder_size_limit () {
    var default_value = Theme.instance ().new_big_folder_size_limit ();
    const var fallback = get_value (new_big_folder_size_limit_c, "", default_value).to_long_long ();
    const var value = get_policy_setting (QLatin1String (new_big_folder_size_limit_c), fallback).to_long_long ();
    const bool use = value >= 0 && use_new_big_folder_size_limit ();
    return q_make_pair (use, q_max<int64> (0, value));
}

void ConfigFile.set_new_big_folder_size_limit (bool is_checked, int64 mbytes) {
    set_value (new_big_folder_size_limit_c, mbytes);
    set_value (use_new_big_folder_size_limit_c, is_checked);
}

bool ConfigFile.confirm_external_storage () {
    const var fallback = get_value (confirm_external_storage_c, "", true);
    return get_policy_setting (QLatin1String (confirm_external_storage_c), fallback).to_bool ();
}

bool ConfigFile.use_new_big_folder_size_limit () {
    const var fallback = get_value (use_new_big_folder_size_limit_c, "", true);
    return get_policy_setting (QLatin1String (use_new_big_folder_size_limit_c), fallback).to_bool ();
}

void ConfigFile.set_confirm_external_storage (bool is_checked) {
    set_value (confirm_external_storage_c, is_checked);
}

bool ConfigFile.move_to_trash () {
    return get_value (move_to_trash_c, "", false).to_bool ();
}

void ConfigFile.set_move_to_trash (bool is_checked) {
    set_value (move_to_trash_c, is_checked);
}

bool ConfigFile.show_main_dialog_as_normal_window () {
    return get_value (show_main_dialog_as_normal_window_c, {}, false).to_bool ();
}

bool ConfigFile.prompt_delete_files () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (prompt_delete_c), false).to_bool ();
}

void ConfigFile.set_prompt_delete_files (bool prompt_delete_files) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (prompt_delete_c), prompt_delete_files);
}

bool ConfigFile.mono_icons () {
    QSettings settings (config_file (), QSettings.IniFormat);
    bool mono_default = false; // On Mac we want bw by default
    return settings.value (QLatin1String (mono_icons_c), mono_default).to_bool ();
}

void ConfigFile.set_mono_icons (bool use_mono_icons) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (mono_icons_c), use_mono_icons);
}

bool ConfigFile.crash_reporter () {
    QSettings settings (config_file (), QSettings.IniFormat);
    const var fallback = settings.value (QLatin1String (crash_reporter_c), true);
    return get_policy_setting (QLatin1String (crash_reporter_c), fallback).to_bool ();
}

void ConfigFile.set_crash_reporter (bool enabled) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (crash_reporter_c), enabled);
}

bool ConfigFile.automatic_log_dir () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (automatic_log_dir_c), false).to_bool ();
}

void ConfigFile.set_automatic_log_dir (bool enabled) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (automatic_log_dir_c), enabled);
}

string ConfigFile.log_dir () {
    const var default_log_dir = string (config_path () + QStringLiteral ("/logs"));
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (log_dir_c), default_log_dir).to_"";
}

void ConfigFile.set_log_dir (string dir) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (log_dir_c), dir);
}

bool ConfigFile.log_debug () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (log_debug_c), true).to_bool ();
}

void ConfigFile.set_log_debug (bool enabled) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (log_debug_c), enabled);
}

int ConfigFile.log_expire () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (log_expire_c), 24).to_int ();
}

void ConfigFile.set_log_expire (int hours) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (log_expire_c), hours);
}

bool ConfigFile.log_flush () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (log_flush_c), false).to_bool ();
}

void ConfigFile.set_log_flush (bool enabled) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (log_flush_c), enabled);
}

bool ConfigFile.show_experimental_options () {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (show_experimental_options_c), false).to_bool ();
}

string ConfigFile.certificate_path () {
    return retrieve_data ("", QLatin1String (cert_path)).to_"";
}

void ConfigFile.set_certificate_path (string c_path) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (cert_path), c_path);
    settings.sync ();
}

string ConfigFile.certificate_passwd () {
    return retrieve_data ("", QLatin1String (cert_passwd)).to_"";
}

void ConfigFile.set_certificate_passwd (string c_passwd) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (cert_passwd), c_passwd);
    settings.sync ();
}

string ConfigFile.client_version_"" {
    QSettings settings (config_file (), QSettings.IniFormat);
    return settings.value (QLatin1String (client_version_c), "").to_"";
}

void ConfigFile.set_client_version_string (string version) {
    QSettings settings (config_file (), QSettings.IniFormat);
    settings.set_value (QLatin1String (client_version_c), version);
}

Q_GLOBAL_STATIC (string, g_config_file_name)

std.unique_ptr<QSettings> ConfigFile.settings_with_group (string group, GLib.Object parent) {
    if (g_config_file_name ().is_empty ()) {
        // cache file name
        ConfigFile cfg;
        *g_config_file_name () = cfg.config_file ();
    }
    std.unique_ptr<QSettings> settings (new QSettings (*g_config_file_name (), QSettings.IniFormat, parent));
    settings.begin_group (group);
    return settings;
}

void ConfigFile.setup_default_exclude_file_paths (ExcludedFiles &excluded_files) {
    ConfigFile cfg;
    string system_list = cfg.exclude_file (ConfigFile.SystemScope);
    string user_list = cfg.exclude_file (ConfigFile.UserScope);

    if (!GLib.File.exists (user_list)) {
        q_c_info (lc_config_file) << "User defined ignore list does not exist:" << user_list;
        if (!GLib.File.copy (system_list, user_list)) {
            q_c_info (lc_config_file) << "Could not copy over default list to:" << user_list;
        }
    }

    if (!GLib.File.exists (user_list)) {
        q_c_info (lc_config_file) << "Adding system ignore list to csync:" << system_list;
        excluded_files.add_exclude_file_path (system_list);
    } else {
        q_c_info (lc_config_file) << "Adding user defined ignore list to csync:" << user_list;
        excluded_files.add_exclude_file_path (user_list);
    }
}
}
