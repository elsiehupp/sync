#ifndef USERMODEL_H
const int USERMODEL_H

// #include <QAbstractListModel>
// #include <QImage>
// #include <QDateTime>
// #include <string[]>
// #include <QQuick_image_provider>
// #include <QHash>

// #include <chrono>
// #include <pushnotifications.h>

// #include <QDesktopServices>
// #include <QIcon>
// #include <QMessageBox>
// #include <QSvgRenderer>
// #include <QPainter>
// #include <QPushButton>

// time span in milliseconds which has to be between two
// refreshes of the notifications
const int NOTIFICATION_REQUEST_FREE_PERIOD 15000

namespace {
constexpr int64 expired_activities_check_interval_msecs = 1000 * 60;
constexpr int64 activity_default_expiration_time_msecs = 1000 * 60 * 10;
}

namespace Occ {

class User : GLib.Object {
    Q_PROPERTY (string name READ name NOTIFY name_changed)
    Q_PROPERTY (string server READ server CONSTANT)
    Q_PROPERTY (bool server_has_user_status READ server_has_user_status CONSTANT)
    Q_PROPERTY (GLib.Uri status_icon READ status_icon NOTIFY status_changed)
    Q_PROPERTY (string status_emoji READ status_emoji NOTIFY status_changed)
    Q_PROPERTY (string status_message READ status_message NOTIFY status_changed)
    Q_PROPERTY (bool desktop_notifications_allowed READ is_desktop_notifications_allowed NOTIFY desktop_notifications_allowed_changed)
    Q_PROPERTY (bool has_local_folder READ has_local_folder NOTIFY has_local_folder_changed)
    Q_PROPERTY (bool server_has_talk READ server_has_talk NOTIFY server_has_talk_changed)
    Q_PROPERTY (string avatar READ avatar_url NOTIFY avatar_changed)
    Q_PROPERTY (bool is_connected READ is_connected NOTIFY account_state_changed)
    Q_PROPERTY (Unified_search_results_list_model* unified_search_results_list_model READ get_unified_search_results_list_model CONSTANT)

    /***********************************************************
    ***********************************************************/
    public User (AccountStatePtr &account, bool &is_current = false, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public AccountPointer account ();

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
    public bool is_current_user ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Folder get_folder ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Unified_search_results_list_model get_u

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string name ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool has_local_folder ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool server_has_

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool has_activities ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public QImage avatar ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void logout ();


    public void remove_account ();


    public string avatar_url ();


    public bool is_desktop_notifications_allowed ();


    public UserStatus.OnlineStatus status ();


    public string status_message ();


    public GLib.Uri status_icon ();


    public string status_emoji ();


    public void process_completed_sync_item (Folder folder, SyncFileItemPtr &item);

signals:
    void gui_log (string , string );
    void name_changed ();
    void has_local_folder_changed ();
    void server_has_talk_changed ();
    void avatar_changed ();
    void account_state_changed ();
    void status_changed ();
    void desktop_notifications_allowed_changed ();


    /***********************************************************
    ***********************************************************/
    public void on_item_completed (string folder, SyncFileItemPtr &item);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_add_error (string folder_alias, string message, ErrorCategory category);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_notification_request_finished (int status_c

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_end_notification_request (int reply_code);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_send_notific

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_refresh_notifications ();

    /***********************************************************
    ***********************************************************/
    public 
    public void on_refresh_activities ();


    public void on_refresh ();


    public void on_refresh_user_status ();


    public void on_refresh_immediately ();


    public void on_set_notification_refresh_interval (std.chrono.milliseconds interval);


    public void on_rebuild_navigation_app_list ();


    /***********************************************************
    ***********************************************************/
    private void on_push_notifications_ready ();
    private void on_disconnect_push_notifications ();
    private void on_received_push_notification (Account account);
    private void on_received_push_activity (Account account);
    private void on_check_expired_activities ();

    /***********************************************************
    ***********************************************************/
    private void connect_push_notifications ();

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private bool is_unsolvable_conflict (SyncFileItemPtr &item);

    /***********************************************************
    ***********************************************************/
    private void show_desktop_notification (string title, string message);


    /***********************************************************
    ***********************************************************/
    private AccountStatePtr _account;
    private bool _is_current_user;
    private ActivityListModel _activity_model;
    private Unified_search_results_list_model _unified_search_results_model;
    private Activity_list _blocklisted_notifications;

    /***********************************************************
    ***********************************************************/
    private QTimer _expired_activities_check_timer;
    private QTimer _notification_check_timer;
    private QHash<AccountState *, QElapsedTimer> _time_since_last_check;

    /***********************************************************
    ***********************************************************/
    private QElapsedTimer _gui_log_timer;
    private Notification_cache _notification_cache;

    // number of currently running notification requests. If non zero,
    // no query for notifications is started.
    private int _notification_requests_running;
};

class User_model : QAbstractListModel {
    Q_PROPERTY (User* current_user READ current_user NOTIFY new_user_selected)
    Q_PROPERTY (int current_user_id READ current_user_id NOTIFY new_user_selected)

    /***********************************************************
    ***********************************************************/
    public static User_model instance ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int current_user_index ();

    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex &parent = QModelIndex ()) override;

    /***********************************************************
    ***********************************************************/
    public QVariant data (QModelIndex &in

    /***********************************************************
    ***********************************************************/
    public QImage avatar_by_id (

    /***********************************************************
    ***********************************************************/
    public User current_user ();

    /***********************************************************
    ***********************************************************/
    public int find_user_id_for_account (AccountS

    /***********************************************************
    ***********************************************************/
    public void fetch_current_activity_model ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void open_current_

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int num_users ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int current_user_id ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void switch_current_user (int &id);

    /***********************************************************
    ***********************************************************/
    public 
    public void login (int &id);


    public void logout (int &id);


    public void remove_account (int &id);

    public std.shared_ptr<Occ.UserStatusConnector> user_status_connector (int id);

    public ActivityListModel current_activity_model ();

    public enum User_roles {
        Name_role = Qt.User_role + 1,
        Server_role,
        Server_has_user_status_role,
        Status_icon_role,
        Status_emoji_role,
        Status_message_role,
        Desktop_notifications_allowed_role,
        Avatar_role,
        Is_current_user_role,
        Is_connected_role,
        Id_role
    };

    /***********************************************************
    ***********************************************************/
    public AccountAppList app_list ();

signals:
    Q_INVOKABLE void add_account ();
    Q_INVOKABLE void new_user_selected ();


    protected QHash<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private static User_model _instance;
    private User_model (GLib.Object parent = new GLib.Object ());
    private GLib.List<User> _users;
    private int _current_user_id = 0;
    private bool _init = true;

    /***********************************************************
    ***********************************************************/
    private void build_user_list ();
};

class Image_provider : QQuick_image_provider {

    /***********************************************************
    ***********************************************************/
    public Image_provider ();

    /***********************************************************
    ***********************************************************/
    public 
    public QImage request_image (string id, QSize size, QSize &requested_size) override;
};

class User_apps_model : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public static User_apps_model instance ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public enum User_apps_roles {
        Name_role = Qt.User_role + 1,
        Url_role,
        Icon_url_role
    };

    /***********************************************************
    ***********************************************************/
    public void build_app_list ();

    /***********************************************************
    ***********************************************************/
    public 
    public void on_open_app_url (GLib.Uri url);


    protected QHash<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private static User_apps_model _instance;

    /***********************************************************
    ***********************************************************/
    private 
    private AccountAppList _apps;
};

User.User (AccountStatePtr &account, bool &is_current, GLib.Object parent)
    : GLib.Object (parent)
    , _account (account)
    , _is_current_user (is_current)
    , _activity_model (new ActivityListModel (_account.data (), this))
    , _unified_search_results_model (new Unified_search_results_list_model (_account.data (), this))
    , _notification_requests_running (0) {
    connect (Progress_dispatcher.instance (), &Progress_dispatcher.progress_info,
        this, &User.on_progress_info);
    connect (Progress_dispatcher.instance (), &Progress_dispatcher.item_completed,
        this, &User.on_item_completed);
    connect (Progress_dispatcher.instance (), &Progress_dispatcher.sync_error,
        this, &User.on_add_error);
    connect (Progress_dispatcher.instance (), &Progress_dispatcher.add_error_to_gui,
        this, &User.on_add_error_to_gui);

    connect (&_notification_check_timer, &QTimer.timeout,
        this, &User.on_refresh);

    connect (&_expired_activities_check_timer, &QTimer.timeout,
        this, &User.on_check_expired_activities);

    connect (_account.data (), &AccountState.state_changed,
            [=] () {
                if (is_connected ()) {
                    on_refresh_immediately ();
                }
            });
    connect (_account.data (), &AccountState.state_changed, this, &User.account_state_changed);
    connect (_account.data (), &AccountState.has_fetched_navigation_apps,
        this, &User.on_rebuild_navigation_app_list);
    connect (_account.account ().data (), &Account.account_changed_display_name, this, &User.name_changed);

    connect (FolderMan.instance (), &FolderMan.folder_list_changed, this, &User.has_local_folder_changed);

    connect (this, &User.gui_log, Logger.instance (), &Logger.gui_log);

    connect (_account.account ().data (), &Account.account_changed_avatar, this, &User.avatar_changed);
    connect (_account.account ().data (), &Account.user_status_changed, this, &User.status_changed);
    connect (_account.data (), &AccountState.desktop_notifications_allowed_changed, this, &User.desktop_notifications_allowed_changed);

    connect (_activity_model, &ActivityListModel.send_notification_request, this, &User.on_send_notification_request);
}

void User.show_desktop_notification (string title, string message) {
    ConfigFile cfg;
    if (!cfg.optional_server_notifications () || !is_desktop_notifications_allowed ()) {
        return;
    }

    // after one hour, clear the gui log notification store
    constexpr int64 clear_gui_log_interval = 60 * 60 * 1000;
    if (_gui_log_timer.elapsed () > clear_gui_log_interval) {
        _notification_cache.clear ();
    }

    const Notification_cache.Notification notification {
        title,
        message
    };
    if (_notification_cache.contains (notification)) {
        return;
    }

    _notification_cache.insert (notification);
    emit gui_log (notification.title, notification.message);
    // restart the gui log timer now that we show a new notification
    _gui_log_timer.on_start ();
}

void User.on_build_notification_display (Activity_list &list) {
    _activity_model.clear_notifications ();

    foreach (var activity, list) {
        if (_blocklisted_notifications.contains (activity)) {
            q_c_info (lc_activity) << "Activity in blocklist, skip";
            continue;
        }
        const var message = AccountManager.instance ().accounts ().count () == 1 ? "" : activity._acc_name;
        show_desktop_notification (activity._subject, message);
        _activity_model.add_notification_to_activity_list (activity);
    }
}

void User.on_set_notification_refresh_interval (std.chrono.milliseconds interval) {
    if (!check_push_notifications_are_ready ()) {
        GLib.debug (lc_activity) << "Starting Notification refresh timer with " << interval.count () / 1000 << " sec interval";
        _notification_check_timer.on_start (interval.count ());
    }
}

void User.on_push_notifications_ready () {
    q_c_info (lc_activity) << "Push notifications are ready";

    if (_notification_check_timer.is_active ()) {
        // as we are now able to use push notifications - let's stop the polling timer
        _notification_check_timer.stop ();
    }

    connect_push_notifications ();
}

void User.on_disconnect_push_notifications () {
    disconnect (_account.account ().push_notifications (), &PushNotifications.notifications_changed, this, &User.on_received_push_notification);
    disconnect (_account.account ().push_notifications (), &PushNotifications.activities_changed, this, &User.on_received_push_activity);

    disconnect (_account.account ().data (), &Account.push_notifications_disabled, this, &User.on_disconnect_push_notifications);

    // connection to Web_socket may have dropped or an error occured, so we need to bring back the polling until we have re-established the connection
    on_set_notification_refresh_interval (ConfigFile ().notification_refresh_interval ());
}

void User.on_received_push_notification (Account account) {
    if (account.id () == _account.account ().id ()) {
        on_refresh_notifications ();
    }
}

void User.on_received_push_activity (Account account) {
    if (account.id () == _account.account ().id ()) {
        on_refresh_activities ();
    }
}

void User.on_check_expired_activities () {
    for (Activity &activity : _activity_model.errors_list ()) {
        if (activity._expire_at_msecs > 0 && QDateTime.current_date_time ().to_m_secs_since_epoch () >= activity._expire_at_msecs) {
            _activity_model.remove_activity_from_activity_list (activity);
        }
    }

    if (_activity_model.errors_list ().size () == 0) {
        _expired_activities_check_timer.stop ();
    }
}

void User.connect_push_notifications () {
    connect (_account.account ().data (), &Account.push_notifications_disabled, this, &User.on_disconnect_push_notifications, Qt.UniqueConnection);

    connect (_account.account ().push_notifications (), &PushNotifications.notifications_changed, this, &User.on_received_push_notification, Qt.UniqueConnection);
    connect (_account.account ().push_notifications (), &PushNotifications.activities_changed, this, &User.on_received_push_activity, Qt.UniqueConnection);
}

bool User.check_push_notifications_are_ready () {
    const var push_notifications = _account.account ().push_notifications ();

    const var push_activities_available = _account.account ().capabilities ().available_push_notifications () & PushNotificationType.Activities;
    const var push_notifications_available = _account.account ().capabilities ().available_push_notifications () & PushNotificationType.Notifications;

    const var push_activities_and_notifications_available = push_activities_available && push_notifications_available;

    if (push_activities_and_notifications_available && push_notifications && push_notifications.is_ready ()) {
        connect_push_notifications ();
        return true;
    } else {
        connect (_account.account ().data (), &Account.push_notifications_ready, this, &User.on_push_notifications_ready, Qt.UniqueConnection);
        return false;
    }
}

void User.on_refresh_immediately () {
    if (_account.data () && _account.data ().is_connected ()) {
        on_refresh_activities ();
    }
    on_refresh_notifications ();
}

void User.on_refresh () {
    on_refresh_user_status ();

    if (check_push_notifications_are_ready ()) {
        // we are relying on Web_socket push notifications - ignore refresh attempts from UI
        _time_since_last_check[_account.data ()].invalidate ();
        return;
    }

    // QElapsedTimer isn't actually constructed as invalid.
    if (!_time_since_last_check.contains (_account.data ())) {
        _time_since_last_check[_account.data ()].invalidate ();
    }
    QElapsedTimer &timer = _time_since_last_check[_account.data ()];

    // Fetch Activities only if visible and if last check is longer than 15 secs ago
    if (timer.is_valid () && timer.elapsed () < NOTIFICATION_REQUEST_FREE_PERIOD) {
        GLib.debug (lc_activity) << "Do not check as last check is only secs ago : " << timer.elapsed () / 1000;
        return;
    }
    if (_account.data () && _account.data ().is_connected ()) {
        if (!timer.is_valid ()) {
            on_refresh_activities ();
        }
        on_refresh_notifications ();
        timer.on_start ();
    }
}

void User.on_refresh_activities () {
    _activity_model.on_refresh_activity ();
}

void User.on_refresh_user_status () {
    if (_account.data () && _account.data ().is_connected ()) {
        _account.account ().user_status_connector ().fetch_user_status ();
    }
}

void User.on_refresh_notifications () {
    // on_start a server notification handler if no notification requests
    // are running
    if (_notification_requests_running == 0) {
        var snh = new Server_notification_handler (_account.data ());
        connect (snh, &Server_notification_handler.new_notification_list,
            this, &User.on_build_notification_display);

        snh.on_fetch_notifications ();
    } else {
        GLib.warn (lc_activity) << "Notification request counter not zero.";
    }
}

void User.on_rebuild_navigation_app_list () {
    emit server_has_talk_changed ();
    // Rebuild App list
    User_apps_model.instance ().build_app_list ();
}

void User.on_notification_request_finished (int status_code) {
    int row = sender ().property ("activity_row").to_int ();

    // the ocs API returns stat code 100 or 200 inside the xml if it succeeded.
    if (status_code != OCS_SUCCESS_STATUS_CODE && status_code != OCS_SUCCESS_STATUS_CODE_V2) {
        GLib.warn (lc_activity) << "Notification Request to Server failed, leave notification visible.";
    } else {
        // to do use the model to rebuild the list or remove the item
        GLib.warn (lc_activity) << "Notification Request to Server successed, rebuilding list.";
        _activity_model.remove_activity_from_activity_list (row);
    }
}

void User.on_end_notification_request (int reply_code) {
    _notification_requests_running--;
    on_notification_request_finished (reply_code);
}

void User.on_send_notification_request (string account_name, string link, GLib.ByteArray verb, int row) {
    q_c_info (lc_activity) << "Server Notification Request " << verb << link << "on account" << account_name;

    const string[] valid_verbs = string[] () << "GET"
                                                 << "PUT"
                                                 << "POST"
                                                 << "DELETE";

    if (valid_verbs.contains (verb)) {
        AccountStatePtr acc = AccountManager.instance ().account (account_name);
        if (acc) {
            var job = new Notification_confirm_job (acc.account ());
            GLib.Uri l (link);
            job.set_link_and_verb (l, verb);
            job.set_property ("activity_row", QVariant.from_value (row));
            connect (job, &AbstractNetworkJob.network_error,
                this, &User.on_notify_network_error);
            connect (job, &Notification_confirm_job.job_finished,
                this, &User.on_notify_server_finished);
            job.on_start ();

            // count the number of running notification requests. If this member var
            // is larger than zero, no new fetching of notifications is started
            _notification_requests_running++;
        }
    } else {
        GLib.warn (lc_activity) << "Notification Links : Invalid verb:" << verb;
    }
}

void User.on_notify_network_error (QNetworkReply reply) {
    var job = qobject_cast<Notification_confirm_job> (sender ());
    if (!job) {
        return;
    }

    int result_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    on_end_notification_request (result_code);
    GLib.warn (lc_activity) << "Server notify job failed with code " << result_code;
}

void User.on_notify_server_finished (string reply, int reply_code) {
    var job = qobject_cast<Notification_confirm_job> (sender ());
    if (!job) {
        return;
    }

    on_end_notification_request (reply_code);
    q_c_info (lc_activity) << "Server Notification reply code" << reply_code << reply;
}

void User.on_progress_info (string folder, ProgressInfo &progress) {
    if (progress.status () == ProgressInfo.Reconcile) {
        // Wipe all non-persistent entries - as well as the persistent ones
        // in cases where a local discovery was done.
        var f = FolderMan.instance ().folder (folder);
        if (!f)
            return;
        const var &engine = f.sync_engine ();
        const var style = engine.last_local_discovery_style ();
        foreach (Activity activity, _activity_model.errors_list ()) {
            if (activity._expire_at_msecs != -1) {
                // we process expired activities in a different slot
                continue;
            }
            if (activity._folder != folder) {
                continue;
            }

            if (style == LocalDiscoveryStyle.FilesystemOnly) {
                _activity_model.remove_activity_from_activity_list (activity);
                continue;
            }

            if (activity._status == SyncFileItem.Conflict && !QFileInfo (f.path () + activity._file).exists ()) {
                _activity_model.remove_activity_from_activity_list (activity);
                continue;
            }

            if (activity._status == SyncFileItem.FileLocked && !QFileInfo (f.path () + activity._file).exists ()) {
                _activity_model.remove_activity_from_activity_list (activity);
                continue;
            }

            if (activity._status == SyncFileItem.FileIgnored && !QFileInfo (f.path () + activity._file).exists ()) {
                _activity_model.remove_activity_from_activity_list (activity);
                continue;
            }

            if (!QFileInfo (f.path () + activity._file).exists ()) {
                _activity_model.remove_activity_from_activity_list (activity);
                continue;
            }

            var path = QFileInfo (activity._file).dir ().path ().to_utf8 ();
            if (path == ".")
                path.clear ();

            if (engine.should_discover_locally (path))
                _activity_model.remove_activity_from_activity_list (activity);
        }
    }

    if (progress.status () == ProgressInfo.Done) {
        // We keep track very well of pending conflicts.
        // Inform other components about them.
        string[] conflicts;
        foreach (Activity activity, _activity_model.errors_list ()) {
            if (activity._folder == folder
                && activity._status == SyncFileItem.Conflict) {
                conflicts.append (activity._file);
            }
        }

        emit Progress_dispatcher.instance ().folder_conflicts (folder, conflicts);
    }
}

void User.on_add_error (string folder_alias, string message, ErrorCategory category) {
    var folder_instance = FolderMan.instance ().folder (folder_alias);
    if (!folder_instance)
        return;

    if (folder_instance.account_state () == _account.data ()) {
        GLib.warn (lc_activity) << "Item " << folder_instance.short_gui_local_path () << " retrieved resulted in " << message;

        Activity activity;
        activity._type = Activity.Sync_result_type;
        activity._status = SyncResult.Error;
        activity._date_time = QDateTime.from_string (QDateTime.current_date_time ().to_"", Qt.ISODate);
        activity._subject = message;
        activity._message = folder_instance.short_gui_local_path ();
        activity._link = folder_instance.short_gui_local_path ();
        activity._acc_name = folder_instance.account_state ().account ().display_name ();
        activity._folder = folder_alias;

        if (category == ErrorCategory.InsufficientRemoteStorage) {
            Activity_link link;
            link._label = _("Retry all uploads");
            link._link = folder_instance.path ();
            link._verb = "";
            link._primary = true;
            activity._links.append (link);
        }

        // add 'other errors' to activity list
        _activity_model.add_error_to_activity_list (activity);
    }
}

void User.on_add_error_to_gui (string folder_alias, SyncFileItem.Status status, string error_message, string subject) {
    const var folder_instance = FolderMan.instance ().folder (folder_alias);
    if (!folder_instance) {
        return;
    }

    if (folder_instance.account_state () == _account.data ()) {
        GLib.warn (lc_activity) << "Item " << folder_instance.short_gui_local_path () << " retrieved resulted in " << error_message;

        Activity activity;
        activity._type = Activity.Sync_file_item_type;
        activity._status = status;
        const var current_date_time = QDateTime.current_date_time ();
        activity._date_time = QDateTime.from_string (current_date_time.to_"", Qt.ISODate);
        activity._expire_at_msecs = current_date_time.add_m_secs (activity_default_expiration_time_msecs).to_m_secs_since_epoch ();
        activity._subject = !subject.is_empty () ? subject : folder_instance.short_gui_local_path ();
        activity._message = error_message;
        activity._link = folder_instance.short_gui_local_path ();
        activity._acc_name = folder_instance.account_state ().account ().display_name ();
        activity._folder = folder_alias;

        // add 'other errors' to activity list
        _activity_model.add_error_to_activity_list (activity);

        show_desktop_notification (activity._subject, activity._message);

        if (!_expired_activities_check_timer.is_active ()) {
            _expired_activities_check_timer.on_start (expired_activities_check_interval_msecs);
        }
    }
}

bool User.is_activity_of_current_account (Folder folder) {
    return folder.account_state () == _account.data ();
}

bool User.is_unsolvable_conflict (SyncFileItemPtr &item) {
    // We just care about conflict issues that we are able to resolve
    return item._status == SyncFileItem.Conflict && !Utility.is_conflict_file (item._file);
}

void User.process_completed_sync_item (Folder folder, SyncFileItemPtr &item) {
    Activity activity;
    activity._type = Activity.Sync_file_item_type; //client activity
    activity._status = item._status;
    activity._date_time = QDateTime.current_date_time ();
    activity._message = item._original_file;
    activity._link = folder.account_state ().account ().url ();
    activity._acc_name = folder.account_state ().account ().display_name ();
    activity._file = item._file;
    activity._folder = folder.alias ();
    activity._file_action = "";

    if (item._instruction == CSYNC_INSTRUCTION_REMOVE) {
        activity._file_action = "file_deleted";
    } else if (item._instruction == CSYNC_INSTRUCTION_NEW) {
        activity._file_action = "file_created";
    } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
        activity._file_action = "file_renamed";
    } else {
        activity._file_action = "file_changed";
    }

    if (item._status == SyncFileItem.NoStatus || item._status == SyncFileItem.Success) {
        GLib.warn (lc_activity) << "Item " << item._file << " retrieved successfully.";

        if (item._direction != SyncFileItem.Up) {
            activity._message = _("Synced %1").arg (item._original_file);
        } else if (activity._file_action == "file_renamed") {
            activity._message = _("You renamed %1").arg (item._original_file);
        } else if (activity._file_action == "file_deleted") {
            activity._message = _("You deleted %1").arg (item._original_file);
        } else if (activity._file_action == "file_created") {
            activity._message = _("You created %1").arg (item._original_file);
        } else {
            activity._message = _("You changed %1").arg (item._original_file);
        }

        _activity_model.add_sync_file_item_to_activity_list (activity);
    } else {
        GLib.warn (lc_activity) << "Item " << item._file << " retrieved resulted in error " << item._error_string;
        activity._subject = item._error_string;

        if (item._status == SyncFileItem.Status.FileIgnored) {
            _activity_model.add_ignored_file_to_list (activity);
        } else {
            // add 'protocol error' to activity list
            if (item._status == SyncFileItem.Status.FileNameInvalid) {
                show_desktop_notification (item._file, activity._subject);
            }
            _activity_model.add_error_to_activity_list (activity);
        }
    }
}

void User.on_item_completed (string folder, SyncFileItemPtr &item) {
    var folder_instance = FolderMan.instance ().folder (folder);

    if (!folder_instance || !is_activity_of_current_account (folder_instance) || is_unsolvable_conflict (item)) {
        return;
    }

    GLib.warn (lc_activity) << "Item " << item._file << " retrieved resulted in " << item._error_string;
    process_completed_sync_item (folder_instance, item);
}

AccountPointer User.account () {
    return _account.account ();
}

AccountStatePtr User.account_state () {
    return _account;
}

void User.set_current_user (bool &is_current) {
    _is_current_user = is_current;
}

Folder *User.get_folder () {
    foreach (Folder folder, FolderMan.instance ().map ()) {
        if (folder.account_state () == _account.data ()) {
            return folder;
        }
    }

    return nullptr;
}

ActivityListModel *User.get_activity_model () {
    return _activity_model;
}

Unified_search_results_list_model *User.get_unified_search_results_list_model () {
    return _unified_search_results_model;
}

void User.open_local_folder () {
    const var folder = get_folder ();

    if (folder) {
        QDesktopServices.open_url (GLib.Uri.from_local_file (folder.path ()));
    }
}

void User.login () {
    _account.account ().reset_rejected_certificates ();
    _account.sign_in ();
}

void User.logout () {
    _account.sign_out_by_ui ();
}

string User.name () {
    // If dav_display_name is empty (can be several reasons, simplest is missing login at startup), fall back to username
    string name = _account.account ().dav_display_name ();
    if (name == "") {
        name = _account.account ().credentials ().user ();
    }
    return name;
}

string User.server (bool shortened) {
    string server_url = _account.account ().url ().to_"";
    if (shortened) {
        server_url.replace (QLatin1String ("https://"), QLatin1String (""));
        server_url.replace (QLatin1String ("http://"), QLatin1String (""));
    }
    return server_url;
}

UserStatus.OnlineStatus User.status () {
    return _account.account ().user_status_connector ().user_status ().state ();
}

string User.status_message () {
    return _account.account ().user_status_connector ().user_status ().message ();
}

GLib.Uri User.status_icon () {
    return _account.account ().user_status_connector ().user_status ().state_icon ();
}

string User.status_emoji () {
    return _account.account ().user_status_connector ().user_status ().icon ();
}

bool User.server_has_user_status () {
    return _account.account ().capabilities ().user_status ();
}

QImage User.avatar () {
    return AvatarJob.make_circular_avatar (_account.account ().avatar ());
}

string User.avatar_url () {
    if (avatar ().is_null ()) {
        return "";
    }

    return QStringLiteral ("image://avatars/") + _account.account ().id ();
}

bool User.has_local_folder () {
    return get_folder () != nullptr;
}

bool User.server_has_talk () {
    return talk_app () != nullptr;
}

AccountApp *User.talk_app () {
    return _account.find_app (QStringLiteral ("spreed"));
}

bool User.has_activities () {
    return _account.account ().capabilities ().has_activities ();
}

AccountAppList User.app_list () {
    return _account.app_list ();
}

bool User.is_current_user () {
    return _is_current_user;
}

bool User.is_connected () {
    return (_account.connection_status () == AccountState.ConnectionStatus.Connected);
}

bool User.is_desktop_notifications_allowed () {
    return _account.data ().is_desktop_notifications_allowed ();
}

void User.remove_account () {
    AccountManager.instance ().delete_account (_account.data ());
    AccountManager.instance ().save ();
}

/*-------------------------------------------------------------------------------------*/

User_model *User_model._instance = nullptr;

User_model *User_model.instance () {
    if (!_instance) {
        _instance = new User_model ();
    }
    return _instance;
}

User_model.User_model (GLib.Object parent)
    : QAbstractListModel (parent) {
    // TODO : Remember selected user from last quit via settings file
    if (AccountManager.instance ().accounts ().size () > 0) {
        build_user_list ();
    }

    connect (AccountManager.instance (), &AccountManager.on_account_added,
        this, &User_model.build_user_list);
}

void User_model.build_user_list () {
    for (int i = 0; i < AccountManager.instance ().accounts ().size (); i++) {
        var user = AccountManager.instance ().accounts ().at (i);
        add_user (user);
    }
    if (_init) {
        _users.first ().set_current_user (true);
        _init = false;
    }
}

Q_INVOKABLE int User_model.num_users () {
    return _users.size ();
}

Q_INVOKABLE int User_model.current_user_id () {
    return _current_user_id;
}

Q_INVOKABLE bool User_model.is_user_connected (int &id) {
    if (id < 0 || id >= _users.size ())
        return false;

    return _users[id].is_connected ();
}

QImage User_model.avatar_by_id (int &id) {
    if (id < 0 || id >= _users.size ())
        return {};

    return _users[id].avatar ();
}

Q_INVOKABLE string User_model.current_user_server () {
    if (_current_user_id < 0 || _current_user_id >= _users.size ())
        return {};

    return _users[_current_user_id].server ();
}

void User_model.add_user (AccountStatePtr &user, bool &is_current) {
    bool contains_user = false;
    for (var &u : q_as_const (_users)) {
        if (u.account () == user.account ()) {
            contains_user = true;
            continue;
        }
    }

    if (!contains_user) {
        int row = row_count ();
        begin_insert_rows (QModelIndex (), row, row);

        User u = new User (user, is_current);

        connect (u, &User.avatar_changed, this, [this, row] {
           emit data_changed (index (row, 0), index (row, 0), {User_model.Avatar_role});
        });

        connect (u, &User.status_changed, this, [this, row] {
            emit data_changed (index (row, 0), index (row, 0), {User_model.Status_icon_role,
			    				    User_model.Status_emoji_role,
                                                            User_model.Status_message_role});
        });

        connect (u, &User.desktop_notifications_allowed_changed, this, [this, row] {
            emit data_changed (index (row, 0), index (row, 0), {
                User_model.Desktop_notifications_allowed_role
            });
        });

        connect (u, &User.account_state_changed, this, [this, row] {
            emit data_changed (index (row, 0), index (row, 0), {
                User_model.Is_connected_role
            });
        });

        _users << u;
        if (is_current) {
            _current_user_id = _users.index_of (_users.last ());
        }

        end_insert_rows ();
        ConfigFile cfg;
        _users.last ().on_set_notification_refresh_interval (cfg.notification_refresh_interval ());
        emit new_user_selected ();
    }
}

int User_model.current_user_index () {
    return _current_user_id;
}

Q_INVOKABLE void User_model.open_current_account_local_folder () {
    if (_current_user_id < 0 || _current_user_id >= _users.size ())
        return;

    _users[_current_user_id].open_local_folder ();
}

Q_INVOKABLE void User_model.open_current_account_talk () {
    if (!current_user ())
        return;

    const var talk_app = current_user ().talk_app ();
    if (talk_app) {
        Utility.open_browser (talk_app.url ());
    } else {
        GLib.warn (lc_activity) << "The Talk app is not enabled on" << current_user ().server ();
    }
}

Q_INVOKABLE void User_model.open_current_account_server () {
    if (_current_user_id < 0 || _current_user_id >= _users.size ())
        return;

    string url = _users[_current_user_id].server (false);
    if (!url.starts_with ("http://") && !url.starts_with ("https://")) {
        url = "https://" + _users[_current_user_id].server (false);
    }

    QDesktopServices.open_url (url);
}

Q_INVOKABLE void User_model.switch_current_user (int &id) {
    if (_current_user_id < 0 || _current_user_id >= _users.size ())
        return;

    _users[_current_user_id].set_current_user (false);
    _users[id].set_current_user (true);
    _current_user_id = id;
    emit new_user_selected ();
}

Q_INVOKABLE void User_model.login (int &id) {
    if (id < 0 || id >= _users.size ())
        return;

    _users[id].login ();
}

Q_INVOKABLE void User_model.logout (int &id) {
    if (id < 0 || id >= _users.size ())
        return;

    _users[id].logout ();
}

Q_INVOKABLE void User_model.remove_account (int &id) {
    if (id < 0 || id >= _users.size ())
        return;

    QMessageBox message_box (QMessageBox.Question,
        _("Confirm Account Removal"),
        _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
           "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
            .arg (_users[id].name ()),
        QMessageBox.NoButton);
    QPushButton yes_button =
        message_box.add_button (_("Remove connection"), QMessageBox.YesRole);
    message_box.add_button (_("Cancel"), QMessageBox.NoRole);

    message_box.exec ();
    if (message_box.clicked_button () != yes_button) {
        return;
    }

    if (_users[id].is_current_user () && _users.count () > 1) {
        id == 0 ? switch_current_user (1) : switch_current_user (0);
    }

    _users[id].logout ();
    _users[id].remove_account ();

    begin_remove_rows (QModelIndex (), id, id);
    _users.remove_at (id);
    end_remove_rows ();
}

std.shared_ptr<Occ.UserStatusConnector> User_model.user_status_connector (int id) {
    if (id < 0 || id >= _users.size ()) {
        return nullptr;
    }

    return _users[id].account ().user_status_connector ();
}

int User_model.row_count (QModelIndex &parent) {
    Q_UNUSED (parent);
    return _users.count ();
}

QVariant User_model.data (QModelIndex &index, int role) {
    if (index.row () < 0 || index.row () >= _users.count ()) {
        return QVariant ();
    }

    if (role == Name_role) {
        return _users[index.row ()].name ();
    } else if (role == Server_role) {
        return _users[index.row ()].server ();
    } else if (role == Server_has_user_status_role) {
        return _users[index.row ()].server_has_user_status ();
    } else if (role == Status_icon_role) {
        return _users[index.row ()].status_icon ();
    } else if (role == Status_emoji_role) {
        return _users[index.row ()].status_emoji ();
    } else if (role == Status_message_role) {
        return _users[index.row ()].status_message ();
    } else if (role == Desktop_notifications_allowed_role) {
        return _users[index.row ()].is_desktop_notifications_allowed ();
    } else if (role == Avatar_role) {
        return _users[index.row ()].avatar_url ();
    } else if (role == Is_current_user_role) {
        return _users[index.row ()].is_current_user ();
    } else if (role == Is_connected_role) {
        return _users[index.row ()].is_connected ();
    } else if (role == Id_role) {
        return index.row ();
    }
    return QVariant ();
}

QHash<int, GLib.ByteArray> User_model.role_names () {
    QHash<int, GLib.ByteArray> roles;
    roles[Name_role] = "name";
    roles[Server_role] = "server";
    roles[Server_has_user_status_role] = "server_has_user_status";
    roles[Status_icon_role] = "status_icon";
    roles[Status_emoji_role] = "status_emoji";
    roles[Status_message_role] = "status_message";
    roles[Desktop_notifications_allowed_role] = "desktop_notifications_allowed";
    roles[Avatar_role] = "avatar";
    roles[Is_current_user_role] = "is_current_user";
    roles[Is_connected_role] = "is_connected";
    roles[Id_role] = "id";
    return roles;
}

ActivityListModel *User_model.current_activity_model () {
    if (current_user_index () < 0 || current_user_index () >= _users.size ())
        return nullptr;

    return _users[current_user_index ()].get_activity_model ();
}

void User_model.fetch_current_activity_model () {
    if (current_user_id () < 0 || current_user_id () >= _users.size ())
        return;

    _users[current_user_id ()].on_refresh ();
}

AccountAppList User_model.app_list () {
    if (_current_user_id < 0 || _current_user_id >= _users.size ())
        return {};

    return _users[_current_user_id].app_list ();
}

User *User_model.current_user () {
    if (current_user_id () < 0 || current_user_id () >= _users.size ())
        return nullptr;

    return _users[current_user_id ()];
}

int User_model.find_user_id_for_account (AccountState account) {
    const var it = std.find_if (std.cbegin (_users), std.cend (_users), [=] (User user) {
        return user.account ().id () == account.account ().id ();
    });

    if (it == std.cend (_users)) {
        return -1;
    }

    const var id = std.distance (std.cbegin (_users), it);
    return id;
}

/*-------------------------------------------------------------------------------------*/

Image_provider.Image_provider ()
    : QQuick_image_provider (QQuick_image_provider.Image) {
}

QImage Image_provider.request_image (string id, QSize size, QSize &requested_size) {
    Q_UNUSED (size)
    Q_UNUSED (requested_size)

    const var make_icon = [] (string path) {
        QImage image (128, 128, QImage.Format_ARGB32);
        image.fill (Qt.Global_color.transparent);
        QPainter painter (&image);
        QSvgRenderer renderer (path);
        renderer.render (&painter);
        return image;
    };

    if (id == QLatin1String ("fallback_white")) {
        return make_icon (QStringLiteral (":/client/theme/white/user.svg"));
    }

    if (id == QLatin1String ("fallback_black")) {
        return make_icon (QStringLiteral (":/client/theme/black/user.svg"));
    }

    const int uid = id.to_int ();
    return User_model.instance ().avatar_by_id (uid);
}

/*-------------------------------------------------------------------------------------*/

User_apps_model *User_apps_model._instance = nullptr;

User_apps_model *User_apps_model.instance () {
    if (!_instance) {
        _instance = new User_apps_model ();
    }
    return _instance;
}

User_apps_model.User_apps_model (GLib.Object parent)
    : QAbstractListModel (parent) {
}

void User_apps_model.build_app_list () {
    if (row_count () > 0) {
        begin_remove_rows (QModelIndex (), 0, row_count () - 1);
        _apps.clear ();
        end_remove_rows ();
    }

    if (User_model.instance ().app_list ().count () > 0) {
        const var talk_app = User_model.instance ().current_user ().talk_app ();
        foreach (AccountApp app, User_model.instance ().app_list ()) {
            // Filter out Talk because we have a dedicated button for it
            if (talk_app && app.id () == talk_app.id ())
                continue;

            begin_insert_rows (QModelIndex (), row_count (), row_count ());
            _apps << app;
            end_insert_rows ();
        }
    }
}

void User_apps_model.on_open_app_url (GLib.Uri url) {
    Utility.open_browser (url);
}

int User_apps_model.row_count (QModelIndex &parent) {
    Q_UNUSED (parent);
    return _apps.count ();
}

QVariant User_apps_model.data (QModelIndex &index, int role) {
    if (index.row () < 0 || index.row () >= _apps.count ()) {
        return QVariant ();
    }

    if (role == Name_role) {
        return _apps[index.row ()].name ();
    } else if (role == Url_role) {
        return _apps[index.row ()].url ();
    } else if (role == Icon_url_role) {
        return _apps[index.row ()].icon_url ().to_"";
    }
    return QVariant ();
}

QHash<int, GLib.ByteArray> User_apps_model.role_names () {
    QHash<int, GLib.ByteArray> roles;
    roles[Name_role] = "app_name";
    roles[Url_role] = "app_url";
    roles[Icon_url_role] = "app_icon_url";
    return roles;
}

}
