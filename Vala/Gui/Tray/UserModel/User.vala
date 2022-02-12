
namespace Occ {
namespace Ui {

class User : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private AccountStatePtr account;
    private bool is_current_user;
    private ActivityListModel activity_model;
    private UnifiedSearchResultsListModel unified_search_results_model;
    private ActivityList blocklisted_notifications;

    /***********************************************************
    ***********************************************************/
    private QTimer expired_activities_check_timer;
    private QTimer notification_check_timer;
    private GLib.HashMap<AccountState, QElapsedTimer> time_since_last_check;

    /***********************************************************
    ***********************************************************/
    private QElapsedTimer gui_log_timer;
    private NotificationCache notification_cache;

    /***********************************************************
    Number of currently running notification requests. If non
    zero, no query for notifications is started.
    ***********************************************************/
    private int notification_requests_running;


    signal void signal_gui_log (string value1, string value2);
    signal void signal_name_changed ();
    signal void signal_has_local_folder_changed ();
    signal void signal_server_has_talk_changed ();
    signal void signal_avatar_changed ();
    signal void signal_account_state_changed ();
    signal void signal_status_changed ();
    signal void signal_desktop_notifications_allowed_changed ();


    /***********************************************************
    ***********************************************************/
    public User (AccountStatePtr account, bool is_current = false, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
        this.is_current_user = is_current;
        this.activity_model = new ActivityListModel (this.account.data (), this);
        this.unified_search_results_model = new UnifiedSearchResultsListModel (this.account.data (), this);
        this.notification_requests_running = 0;
        connect (ProgressDispatcher.instance (), &ProgressDispatcher.progress_info,
            this, &User.on_signal_progress_info);
        connect (ProgressDispatcher.instance (), &ProgressDispatcher.item_completed,
            this, &User.on_signal_item_completed);
        connect (ProgressDispatcher.instance (), &ProgressDispatcher.sync_error,
            this, &User.on_signal_add_error);
        connect (ProgressDispatcher.instance (), &ProgressDispatcher.add_error_to_gui,
            this, &User.on_signal_add_error_to_gui);

        connect (&this.notification_check_timer, &QTimer.timeout,
            this, &User.on_signal_refresh);

        connect (&this.expired_activities_check_timer, &QTimer.timeout,
            this, &User.on_signal_check_expired_activities);

        connect (this.account.data (), &AccountState.state_changed,
                [=] () {
                    if (is_connected ()) {
                        on_signal_refresh_immediately ();
                    }
                });
        connect (this.account.data (), &AccountState.state_changed, this, &User.signal_account_state_changed);
        connect (this.account.data (), &AccountState.has_fetched_navigation_apps,
            this, &User.on_signal_rebuild_navigation_app_list);
        connect (this.account.account ().data (), &Account.account_changed_display_name, this, &User.signal_name_changed);

        connect (FolderMan.instance (), &FolderMan.signal_folder_list_changed, this, &User.signal_has_local_folder_changed);

        connect (this, &User.signal_gui_log, Logger.instance (), &Logger.signal_gui_log);

        connect (this.account.account ().data (), &Account.account_changed_avatar, this, &User.signal_avatar_changed);
        connect (this.account.account ().data (), &Account.user_status_changed, this, &User.signal_status_changed);
        connect (this.account.data (), &AccountState.signal_desktop_notifications_allowed_changed, this, &User.signal_desktop_notifications_allowed_changed);

        connect (this.activity_model, &ActivityListModel.send_notification_request, this, &User.on_signal_send_notification_request);
    }


    /***********************************************************
    ***********************************************************/
    public AccountPointer account () {
        return this.account.account ();
    }


    /***********************************************************
    ***********************************************************/
    public AccountStatePtr account_state () {
        return this.account;
    }


    /***********************************************************
    ***********************************************************/
    public string server (bool shortened) {
        string server_url = this.account.account ().url ().to_string ();
        if (shortened) {
            server_url.replace (QLatin1String ("https://"), QLatin1String (""));
            server_url.replace (QLatin1String ("http://"), QLatin1String (""));
        }
        return server_url;
    }


    /***********************************************************
    ***********************************************************/
    public AccountAppList app_list () {
        return this.account.app_list ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_current_user () {
        return this.is_current_user;
    }


    /***********************************************************
    ***********************************************************/
    public void is_current_user (bool is_current_user) {
        this.is_current_user = is_current_user;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_connected () {
        return (this.account.connection_status () == AccountState.ConnectionStatus.Connected);
    }


    /***********************************************************
    ***********************************************************/
    public Folder get_folder () {
        foreach (Folder folder, FolderMan.instance ().map ()) {
            if (folder.account_state () == this.account.data ()) {
                return folder;
            }
        }

        return null;
    }


    /***********************************************************
    ***********************************************************/
    public ActivityListModel get_activity_model () {
        return this.activity_model;
    }


    /***********************************************************
    ***********************************************************/
    public UnifiedSearchResultsListModel get_unified_search_results_list_model () {
        return this.unified_search_results_model;
    }


    /***********************************************************
    If dav_display_name is empty (which can be several reasons,
    the simplest is missing login at startup), fall back to username
    ***********************************************************/
    public string name () {
        string name = this.account.account ().dav_display_name ();
        if (name == "") {
            name = this.account.account ().credentials ().user ();
        }
        return name;
    }


    /***********************************************************
    ***********************************************************/
    public bool check_push_notifications_are_ready () {
        const var push_notifications = this.account.account ().push_notifications ();

        const var push_activities_available = this.account.account ().capabilities ().available_push_notifications () & PushNotificationType.ACTIVITIES;
        const var push_notifications_available = this.account.account ().capabilities ().available_push_notifications () & PushNotificationType.NOTIFICATIONS;

        const var push_activities_and_notifications_available = push_activities_available && push_notifications_available;

        if (push_activities_and_notifications_available && push_notifications && push_notifications.is_ready ()) {
            connect_push_notifications ();
            return true;
        } else {
            connect (this.account.account ().data (), &Account.push_notifications_ready, this, &User.on_signal_push_notifications_ready, Qt.UniqueConnection);
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void open_local_folder () {
        const var folder = get_folder ();

        if (folder) {
            QDesktopServices.open_url (GLib.Uri.from_local_file (folder.path ()));
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool has_local_folder () {
        return get_folder () != null;
    }


    /***********************************************************
    ***********************************************************/
    public bool server_has_talk () {
        return talk_app () != null;
    }



    /***********************************************************
    ***********************************************************/
    public AccountApp talk_app () {
        return this.account.find_app (QStringLiteral ("spreed"));
    }


    /***********************************************************
    ***********************************************************/
    public bool has_activities () {
        return this.account.account ().capabilities ().has_activities ();
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image avatar () {
        return AvatarJob.make_circular_avatar (this.account.account ().avatar ());
    }


    /***********************************************************
    ***********************************************************/
    public void log_in () {
        this.account.account ().reset_rejected_certificates ();
        this.account.sign_in ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_out () {
        this.account.sign_out_by_ui ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_account () {
        AccountManager.instance ().delete_account (this.account.data ());
        AccountManager.instance ().save ();
    }


    /***********************************************************
    ***********************************************************/
    public string avatar_url () {
        if (avatar ().is_null ()) {
            return "";
        }

        return QStringLiteral ("image://avatars/") + this.account.account ().identifier ();
    }


    /***********************************************************
    ***********************************************************/
    public bool are_desktop_notifications_allowed () {
        return this.account.data ().are_desktop_notifications_allowed ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatus.OnlineStatus status () {
        return this.account.account ().user_status_connector ().user_status ().state ();
    }


    /***********************************************************
    ***********************************************************/
    public string status_message () {
        return this.account.account ().user_status_connector ().user_status ().message ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri status_icon () {
        return this.account.account ().user_status_connector ().user_status ().state_icon ();
    }


    /***********************************************************
    ***********************************************************/
    public string status_emoji () {
        return this.account.account ().user_status_connector ().user_status ().icon ();
    }


    /***********************************************************
    ***********************************************************/
    public bool server_has_user_status () {
        return this.account.account ().capabilities ().user_status ();
    }


    /***********************************************************
    ***********************************************************/
    public void process_completed_sync_item (Folder folder, SyncFileItemPtr item) {
        Activity activity;
        activity.type = Activity.Type.SYNC_FILE_ITEM; //client activity
        activity.status = item.status;
        activity.date_time = GLib.DateTime.current_date_time ();
        activity.message = item.original_file;
        activity.link = folder.account_state ().account ().url ();
        activity.acc_name = folder.account_state ().account ().display_name ();
        activity.file = item.file;
        activity.folder = folder.alias ();
        activity.file_action = "";

        if (item.instruction == CSYNC_INSTRUCTION_REMOVE) {
            activity.file_action = "file_deleted";
        } else if (item.instruction == CSYNC_INSTRUCTION_NEW) {
            activity.file_action = "file_created";
        } else if (item.instruction == CSYNC_INSTRUCTION_RENAME) {
            activity.file_action = "file_renamed";
        } else {
            activity.file_action = "file_changed";
        }

        if (item.status == SyncFileItem.Status.NO_STATUS || item.status == SyncFileItem.Status.SUCCESS) {
            GLib.warning ("Item " + item.file + " retrieved successfully.";

            if (item.direction != SyncFileItem.Direction.UP) {
                activity.message = _("Synced %1").arg (item.original_file);
            } else if (activity.file_action == "file_renamed") {
                activity.message = _("You renamed %1").arg (item.original_file);
            } else if (activity.file_action == "file_deleted") {
                activity.message = _("You deleted %1").arg (item.original_file);
            } else if (activity.file_action == "file_created") {
                activity.message = _("You created %1").arg (item.original_file);
            } else {
                activity.message = _("You changed %1").arg (item.original_file);
            }

            this.activity_model.add_sync_file_item_to_activity_list (activity);
        } else {
            GLib.warning ("Item " + item.file + " retrieved resulted in error " + item.error_string;
            activity.subject = item.error_string;

            if (item.status == SyncFileItem.Status.FileIgnored) {
                this.activity_model.add_ignored_file_to_list (activity);
            } else {
                // add 'protocol error' to activity list
                if (item.status == SyncFileItem.Status.FileNameInvalid) {
                    show_desktop_notification (item.file, activity.subject);
                }
                this.activity_model.add_error_to_activity_list (activity);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_item_completed (string folder, SyncFileItemPtr item) {
        var folder_instance = FolderMan.instance ().folder_by_alias (folder);

        if (!folder_instance || !is_activity_of_current_account (folder_instance) || is_unsolvable_conflict (item)) {
            return;
        }

        GLib.warning ("Item " + item.file + " retrieved resulted in " + item.error_string;
        process_completed_sync_item (folder_instance, item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_add_error (string folder_alias, string message, ErrorCategory category) {
        var folder_instance = FolderMan.instance ().folder_by_alias (folder_alias);
        if (!folder_instance)
            return;

        if (folder_instance.account_state () == this.account.data ()) {
            GLib.warning ("Item " + folder_instance.short_gui_local_path (" retrieved resulted in " + message;

            Activity activity;
            activity.type = Activity.Type.SYNC_RESULT;
            activity.status = SyncResult.Status.ERROR;
            activity.date_time = GLib.DateTime.from_string (GLib.DateTime.current_date_time ().to_string (), Qt.ISODate);
            activity.subject = message;
            activity.message = folder_instance.short_gui_local_path ();
            activity.link = folder_instance.short_gui_local_path ();
            activity.acc_name = folder_instance.account_state ().account ().display_name ();
            activity.folder = folder_alias;

            if (category == ErrorCategory.INSUFFICIENT_REMOTE_STORAGE) {
                ActivityLink link;
                link.label = _("Retry all uploads");
                link.link = folder_instance.path ();
                link.verb = "";
                link.primary = true;
                activity.links.append (link);
            }

            // add 'other errors' to activity list
            this.activity_model.add_error_to_activity_list (activity);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_add_error_to_gui (string folder_alias, SyncFileItem.Status status, string error_message, string subject) {
        const var folder_instance = FolderMan.instance ().folder_by_alias (folder_alias);
        if (!folder_instance) {
            return;
        }

        if (folder_instance.account_state () == this.account.data ()) {
            GLib.warning ("Item " + folder_instance.short_gui_local_path (" retrieved resulted in " + error_message;

            Activity activity;
            activity.type = Activity.Type.SYNC_FILE_ITEM;
            activity.status = status;
            const var current_date_time = GLib.DateTime.current_date_time ();
            activity.date_time = GLib.DateTime.from_string (current_date_time.to_string (), Qt.ISODate);
            activity.expire_at_msecs = current_date_time.add_m_secs (ACTIVITY_DEFAULT_EXPIRATION_TIME_MSECS).to_m_secs_since_epoch ();
            activity.subject = !subject.is_empty () ? subject : folder_instance.short_gui_local_path ();
            activity.message = error_message;
            activity.link = folder_instance.short_gui_local_path ();
            activity.acc_name = folder_instance.account_state ().account ().display_name ();
            activity.folder = folder_alias;

            // add 'other errors' to activity list
            this.activity_model.add_error_to_activity_list (activity);

            show_desktop_notification (activity.subject, activity.message);

            if (!this.expired_activities_check_timer.is_active ()) {
                this.expired_activities_check_timer.on_signal_start (EXPIRED_ACTIVITIES_CHECK_INTERVAL_MSEC);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notification_request_finished (int status_code) {
        int row = sender ().property ("activity_row").to_int ();

        // the ocs API returns stat code 100 or 200 inside the xml if it succeeded.
        if (status_code != OCS_SUCCESS_STATUS_CODE && status_code != OCS_SUCCESS_STATUS_CODE_V2) {
            GLib.warning ("Notification Request to Server failed, leave notification visible.";
        } else {
            // to do use the model to rebuild the list or remove the item
            GLib.warning ("Notification Request to Server successed, rebuilding list.";
            this.activity_model.remove_activity_from_activity_list (row);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_end_notification_request (int reply_code) {
        this.notification_requests_running--;
        on_signal_notification_request_finished (reply_code);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notify_network_error (Soup.Reply reply) {
        var job = qobject_cast<Notification_confirm_job> (sender ());
        if (!job) {
            return;
        }

        int result_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

        on_signal_end_notification_request (result_code);
        GLib.warning ("Server notify job failed with code " + result_code;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_progress_info (string folder, ProgressInfo progress) {
        if (progress.status () == ProgressInfo.Status.RECONCILE) {
            // Wipe all non-persistent entries - as well as the persistent ones
            // in cases where a local discovery was done.
            var f = FolderMan.instance ().folder_by_alias (folder);
            if (!f)
                return;
            const var engine = f.sync_engine ();
            const var style = engine.last_local_discovery_style ();
            foreach (Activity activity, this.activity_model.errors_list ()) {
                if (activity.expire_at_msecs != -1) {
                    // we process expired activities in a different slot
                    continue;
                }
                if (activity.folder != folder) {
                    continue;
                }

                if (style == LocalDiscoveryStyle.FILESYSTEM_ONLY) {
                    this.activity_model.remove_activity_from_activity_list (activity);
                    continue;
                }

                if (activity.status == SyncFileItem.Status.CONFLICT && !GLib.FileInfo (f.path () + activity.file).exists ()) {
                    this.activity_model.remove_activity_from_activity_list (activity);
                    continue;
                }

                if (activity.status == SyncFileItem.Status.FILE_LOCKED && !GLib.FileInfo (f.path () + activity.file).exists ()) {
                    this.activity_model.remove_activity_from_activity_list (activity);
                    continue;
                }

                if (activity.status == SyncFileItem.Status.FILE_IGNORED && !GLib.FileInfo (f.path () + activity.file).exists ()) {
                    this.activity_model.remove_activity_from_activity_list (activity);
                    continue;
                }

                if (!GLib.FileInfo (f.path () + activity.file).exists ()) {
                    this.activity_model.remove_activity_from_activity_list (activity);
                    continue;
                }

                var path = GLib.FileInfo (activity.file).dir ().path ().to_utf8 ();
                if (path == ".")
                    path.clear ();

                if (engine.should_discover_locally (path))
                    this.activity_model.remove_activity_from_activity_list (activity);
            }
        }

        if (progress.status () == ProgressInfo.Status.DONE) {
            // We keep track very well of pending conflicts.
            // Inform other components about them.
            string[] conflicts;
            foreach (Activity activity, this.activity_model.errors_list ()) {
                if (activity.folder == folder
                    && activity.status == SyncFileItem.Status.CONFLICT) {
                    conflicts.append (activity.file);
                }
            }

            /* emit */ ProgressDispatcher.instance ().folder_conflicts (folder, conflicts);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_send_notification_request (string account_name, string link, GLib.ByteArray verb, int row) {
        GLib.info ("Server Notification Request " + verb + link + "on account" + account_name;

        const string[] valid_verbs = new string[4] {"GET",
                                                    "PUT",
                                                    "POST",
                                                    "DELETE"
                                                   };

        if (valid_verbs.contains (verb)) {
            AccountStatePtr acc = AccountManager.instance ().account (account_name);
            if (acc) {
                var job = new Notification_confirm_job (acc.account ());
                GLib.Uri l (link);
                job.link_and_verb (l, verb);
                job.property ("activity_row", GLib.Variant.from_value (row));
                connect (job, &AbstractNetworkJob.network_error,
                    this, &User.on_signal_notify_network_error);
                connect (job, &Notification_confirm_job.job_finished,
                    this, &User.on_signal_notify_server_finished);
                job.on_signal_start ();

                // count the number of running notification requests. If this member var
                // is larger than zero, no new fetching of notifications is started
                this.notification_requests_running++;
            }
        } else {
            GLib.warning ("Notification Links: Invalid verb:" + verb);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notify_server_finished (string reply, int reply_code) {
        var job = qobject_cast<Notification_confirm_job> (sender ());
        if (!job) {
            return;
        }

        on_signal_end_notification_request (reply_code);
        GLib.info ("Server Notification reply code" + reply_code + reply;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_build_notification_display (ActivityList list) {
        this.activity_model.clear_notifications ();

        foreach (var activity in list) {
            if (this.blocklisted_notifications.contains (activity)) {
                GLib.info ("Activity in blocklist, skip";
                continue;
            }
            const var message = AccountManager.instance ().accounts ().count () == 1 ? "" : activity.acc_name;
            show_desktop_notification (activity.subject, message);
            this.activity_model.add_notification_to_activity_list (activity);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_notifications () {
        // on_signal_start a server notification handler if no notification requests
        // are running
        if (this.notification_requests_running == 0) {
            var snh = new ServerNotificationHandler (this.account.data ());
            connect (snh, &ServerNotificationHandler.signal_new_notification_list,
                this, &User.on_signal_build_notification_display);

            snh.on_signal_fetch_notifications ();
        } else {
            GLib.warning ("Notification request counter not zero.";
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_activities () {
        this.activity_model.on_signal_refresh_activity ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh () {
        on_signal_refresh_user_status ();

        if (check_push_notifications_are_ready ()) {
            // we are relying on Web_socket push notifications - ignore refresh attempts from UI
            this.time_since_last_check[this.account.data ()].invalidate ();
            return;
        }

        // QElapsedTimer isn't actually constructed as invalid.
        if (!this.time_since_last_check.contains (this.account.data ())) {
            this.time_since_last_check[this.account.data ()].invalidate ();
        }
        QElapsedTimer timer = this.time_since_last_check[this.account.data ()];

        // Fetch Activities only if visible and if last check is longer than 15 secs ago
        if (timer.is_valid () && timer.elapsed () < NOTIFICATION_REQUEST_FREE_PERIOD) {
            GLib.debug ("Do not check as last check is only secs ago : " + timer.elapsed () / 1000;
            return;
        }
        if (this.account.data () && this.account.data ().is_connected ()) {
            if (!timer.is_valid ()) {
                on_signal_refresh_activities ();
            }
            on_signal_refresh_notifications ();
            timer.on_signal_start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_user_status () {
        if (this.account.data () && this.account.data ().is_connected ()) {
            this.account.account ().user_status_connector ().fetch_user_status ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_immediately () {
        if (this.account.data () && this.account.data ().is_connected ()) {
            on_signal_refresh_activities ();
        }
        on_signal_refresh_notifications ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notification_refresh_interval (std.chrono.milliseconds interval) {
        if (!check_push_notifications_are_ready ()) {
            GLib.debug ("Starting Notification refresh timer with " + interval.count () / 1000 + " sec interval";
            this.notification_check_timer.on_signal_start (interval.count ());
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_rebuild_navigation_app_list () {
        /* emit */ signal_server_has_talk_changed ();
        // Rebuild App list
        UserAppsModel.instance ().build_app_list ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_push_notifications_ready () {
        GLib.info ("Push notifications are ready";

        if (this.notification_check_timer.is_active ()) {
            // as we are now able to use push notifications - let's stop the polling timer
            this.notification_check_timer.stop ();
        }

        connect_push_notifications ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_disconnect_push_notifications () {
        disconnect (this.account.account ().push_notifications (), &PushNotifications.notifications_changed, this, &User.on_signal_received_push_notification);
        disconnect (this.account.account ().push_notifications (), &PushNotifications.activities_changed, this, &User.on_signal_received_push_activity);

        disconnect (this.account.account ().data (), &Account.push_notifications_disabled, this, &User.on_signal_disconnect_push_notifications);

        // connection to Web_socket may have dropped or an error occured, so we need to bring back the polling until we have re-established the connection
        on_signal_notification_refresh_interval (ConfigFile ().notification_refresh_interval ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_received_push_notification (Account account) {
        if (account.identifier () == this.account.account ().identifier ()) {
            on_signal_refresh_notifications ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_received_push_activity (Account account) {
        if (account.identifier () == this.account.account ().identifier ()) {
            on_signal_refresh_activities ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_check_expired_activities () {
        for (Activity activity : this.activity_model.errors_list ()) {
            if (activity.expire_at_msecs > 0 && GLib.DateTime.current_date_time ().to_m_secs_since_epoch () >= activity.expire_at_msecs) {
                this.activity_model.remove_activity_from_activity_list (activity);
            }
        }

        if (this.activity_model.errors_list ().size () == 0) {
            this.expired_activities_check_timer.stop ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void connect_push_notifications () {
        connect (this.account.account ().data (), &Account.push_notifications_disabled, this, &User.on_signal_disconnect_push_notifications, Qt.UniqueConnection);

        connect (this.account.account ().push_notifications (), &PushNotifications.notifications_changed, this, &User.on_signal_received_push_notification, Qt.UniqueConnection);
        connect (this.account.account ().push_notifications (), &PushNotifications.activities_changed, this, &User.on_signal_received_push_activity, Qt.UniqueConnection);
    }


    /***********************************************************
    ***********************************************************/
    private bool is_activity_of_current_account (Folder folder) {
        return folder.account_state () == this.account.data ();
    }


    /***********************************************************
    We only care about conflict issues that we are able to
    resolve
    ***********************************************************/
    private static bool is_unsolvable_conflict (SyncFileItemPtr item) {
        return item.status == SyncFileItem.Status.CONFLICT && !Utility.is_conflict_file (item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void show_desktop_notification (string title, string message) {
        ConfigFile config;
        if (!config.optional_server_notifications () || !are_desktop_notifications_allowed ()) {
            return;
        }

        // after one hour, clear the gui log notification store
        constexpr int64 clear_gui_log_interval = 60 * 60 * 1000;
        if (this.gui_log_timer.elapsed () > clear_gui_log_interval) {
            this.notification_cache.clear ();
        }

        const NotificationCache.Notification notification {
            title,
            message
        }
        if (this.notification_cache.contains (notification)) {
            return;
        }

        this.notification_cache.insert (notification);
        /* emit */ signal_gui_log (notification.title, notification.message);
        // restart the gui log timer now that we show a new notification
        this.gui_log_timer.on_signal_start ();
    }

} // class User

} // namespace Ui
} // namespace Occ
