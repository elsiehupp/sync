
namespace Occ {
namespace Ui {

public class User { //: GLib.Object {

    /***********************************************************
    Time span in milliseconds which must elapse between
    sequential refreshes of the notifications
    ***********************************************************/
    const int NOTIFICATION_REQUEST_FREE_PERIOD = 15000;

    /***********************************************************
    Time span in milliseconds after which activities will
    expired by default
    ***********************************************************/
    const int64 ACTIVITY_DEFAULT_EXPIRATION_TIME_MSECS = 1000 * 60 * 10;

    /***********************************************************
    ***********************************************************/
    LibSync.Account account {
        public get {
            this.account_state.account;
        }
    }
    unowned AccountState account_state { public get; private set; }
    bool is_current_user { public get; public set; }

    ActivityListModel activity_model { public get; private set; }

    private UnifiedSearchResultsListModel unified_search_results_model;
    private GLib.List<Activity> blocklisted_notifications;

    /***********************************************************
    Time span in milliseconds which must elapse between
    sequential checks for expired activities
    ***********************************************************/
    const int64 EXPIRED_ACTIVITIES_CHECK_INTERVAL_MSEC = 1000 * 60;

    /***********************************************************
    ***********************************************************/
    private bool expired_activities_check_timer_active = false;
    private bool notification_check_timer_active = false;
    private GLib.HashTable<AccountState, GLib.Timer> time_since_last_check;

    /***********************************************************
    ***********************************************************/
    private GLib.Timer gui_log_timer;
    private NotificationCache notification_cache;

    /***********************************************************
    Number of currently running notification requests. If non
    zero, no query for notifications is started.
    ***********************************************************/
    internal int notification_requests_running;


    internal signal void signal_gui_log (string value1, string value2);
    internal signal void signal_name_changed ();
    internal signal void signal_has_local_folder_changed ();
    internal signal void signal_server_has_talk_changed ();
    internal signal void signal_avatar_changed ();
    internal signal void signal_account_state_changed ();
    internal signal void signal_status_changed ();
    internal signal void signal_desktop_notifications_allowed_changed ();


    /***********************************************************
    ***********************************************************/
    public User (unowned AccountState account, bool is_current = false) {
        //  base ();
        //  this.account_state = account;
        //  this.is_current_user = is_current;
        //  this.activity_model = new ActivityListModel (this.account_state, this);
        //  this.unified_search_results_model = new UnifiedSearchResultsListModel (this.account_state, this);
        //  this.notification_requests_running = 0;
        //  ProgressDispatcher.instance.progress_info.connect (
        //      this.on_signal_progress_info
        //  );
        //  ProgressDispatcher.instance.signal_item_completed.connect (
        //      this.on_signal_item_completed
        //  );
        //  ProgressDispatcher.instance.sync_error.connect (
        //      this.on_signal_add_error
        //  );
        //  ProgressDispatcher.instance.signal_add_error_to_gui.connect (
        //      this.on_signal_add_error_to_gui
        //  );
        //  this.account_state.signal_state_changed.connect (
        //      this.on_signal_account_state_changed
        //  );
        //  this.account_state.signal_state_changed.connect (
        //      this.on_signal_account_state_changed
        //  );
        //  this.account_state.signal_has_fetched_navigation_apps.connect (
        //      this.on_signal_rebuild_navigation_app_list
        //  );
        //  this.account_state.account.account_changed_display_name.connect (
        //      this.on_signal_name_changed
        //  );
        //  FolderManager.instance.signal_folder_list_changed.connect (
        //      this.on_signal_has_local_folder_changed
        //  );
        //  this.signal_gui_log.connect (
        //      LibSync.Logger.on_signal_gui_log
        //  );
        //  this.account_state.account.account_changed_avatar.connect (
        //      this.signal_avatar_changed
        //  );
        //  this.account_state.account.signal_user_status_changed.connect (
        //      this.signal_status_changed
        //  );
        //  this.account_state.signal_desktop_notifications_allowed_changed.connect (
        //      this.on_signal_desktop_notifications_allowed_changed
        //  );

        //  this.activity_model.signal_send_notification_request.connect (
        //      this.on_signal_send_notification_request
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_state_changed (AccountState account_state, AccountState.State state) {
        //  if (is_connected) {
        //      on_signal_refresh_immediately ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public string server {
        public get {
            return server_string (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private string server_string (bool shortened) {
        //  string server_url = this.account_state.account.url.to_string ();
        //  if (shortened) {
        //      server_url.replace ("https://", "");
        //      server_url.replace ("http://", "");
        //  }
        //  return server_url;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<AccountApp> app_list {
        public get {
            return this.account_state.app_list;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_connected {
        public get {
            return (this.account_state.connection_status == AccountState.ConnectionValidator.Status.Connected);
        }
    }


    /***********************************************************
    ***********************************************************/
    public FolderConnection folder_connection {
        public get {
            foreach (FolderConnection folder_connection in FolderManager.instance.map ()) {
                if (folder_connection.account_state == this.account_state) {
                    return folder_connection;
                }
            }

            return null;
        }
    }


    /***********************************************************
    ***********************************************************/
    public UnifiedSearchResultsListModel unified_search_results_list_model () {
        //  return this.unified_search_results_model;
    }


    /***********************************************************
    If dav_display_name is empty (which can be several reasons,
    the simplest is missing login at startup), fall back to username
    ***********************************************************/
    public string name {
        public get {
            string name = this.account_state.account.dav_display_name ();
            if (name == "") {
                name = this.account_state.account.credentials ().user ();
            }
            return name;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool check_push_notifications_are_ready () {
        //  var push_notifications = this.account_state.account.push_notifications ();

        //  var push_activities_available = this.account_state.account.capabilities.available_push_notifications () & PushNotificationType.ACTIVITIES;
        //  var push_notifications_available = this.account_state.account.capabilities.available_push_notifications () & PushNotificationType.NOTIFICATIONS;

        //  var push_activities_and_notifications_available = push_activities_available && push_notifications_available;

        //  if (push_activities_and_notifications_available && push_notifications && push_notifications.is_ready ()) {
        //      connect_push_notifications ();
        //      return true;
        //  } else {
        //      this.account_state.account.signal_push_notifications_ready.connect (
        //          this.on_signal_push_notifications_ready // GLib.UniqueConnection
        //      );
        //      return false;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void open_local_folder () {
        //  if (this.folder_connection != null) {
        //      GLib.DesktopServices.open_url (GLib.Uri.from_local_file (this.folder_connection.path));
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public bool has_local_folder () {
        //  return folder_connection != null;
    }


    /***********************************************************
    ***********************************************************/
    public bool server_has_talk () {
        //  return talk_app () != null;
    }



    /***********************************************************
    ***********************************************************/
    public AccountApp talk_app () {
        //  return this.account_state.find_app ("spreed");
    }


    /***********************************************************
    ***********************************************************/
    public bool has_activities {
        public get {
            return this.account_state.account.capabilities.has_activities;
        }
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image avatar () {
        //  return AvatarJob.make_circular_avatar (this.account_state.account.avatar ());
    }


    /***********************************************************
    ***********************************************************/
    public void log_in () {
        //  this.account_state.account.reset_rejected_certificates ();
        //  this.account_state.sign_in ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_out () {
        //  this.account_state.sign_out_by_ui ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_account () {
        //  AccountManager.instance.delete_account (this.account_state);
        //  AccountManager.instance.save ();
    }


    /***********************************************************
    ***********************************************************/
    public string avatar_url {
        public get {
            if (avatar () == null) {
                return "";
            }
            return "image://avatars/" + this.account_state.account.identifier;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool are_desktop_notifications_allowed {
        public get {
            return this.account_state.are_desktop_notifications_allowed;
        }
    }


    /***********************************************************
    ***********************************************************/
    public LibSync.UserStatus.OnlineStatus status {
        public get {
            return this.account_state.account.user_status_connector ().user_status ().state;
        }
    }


    /***********************************************************
    ***********************************************************/
    public string status_message {
        public get {
            return this.account_state.account.user_status_connector ().user_status ().message ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public string status_icon {
        public get {
            return this.account_state.account.user_status_connector ().user_status ().state_icon ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public string status_emoji {
        public get {
            return this.account_state.account.user_status_connector ().user_status ().icon ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool server_has_user_status {
        public get {
            return this.account_state.account.capabilities.user_status ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void process_completed_sync_item (FolderConnection folder_connection, LibSync.SyncFileItem sync_file_item) {
        //  Activity activity;
        //  activity.type = Activity.Type.SYNC_FILE_ITEM; //client activity
        //  activity.status = sync_file_item.status;
        //  activity.date_time = GLib.DateTime.current_date_time ();
        //  activity.message = sync_file_item.original_file;
        //  activity.link = folder_connection.account_state.account.url;
        //  activity.acc_name = folder_connection.account_state.account.display_name;
        //  activity.file = sync_file_item.file;
        //  activity.folder_connection = folder_connection.alias ();
        //  activity.file_action = "";

        //  if (sync_file_item.instruction == CSync.SyncInstructions.REMOVE) {
        //      activity.file_action = "file_deleted";
        //  } else if (sync_file_item.instruction == CSync.SyncInstructions.NEW) {
        //      activity.file_action = "file_created";
        //  } else if (sync_file_item.instruction == CSync.SyncInstructions.RENAME) {
        //      activity.file_action = "file_renamed";
        //  } else {
        //      activity.file_action = "file_changed";
        //  }

        //  if (sync_file_item.status == LibSync.SyncFileItem.Status.NO_STATUS || sync_file_item.status == LibSync.SyncFileItem.Status.SUCCESS) {
        //      GLib.warning ("Item " + sync_file_item.file + " retrieved successfully.");

        //      if (sync_file_item.direction != LibSync.SyncFileItem.Direction.UP) {
        //          activity.message = _("Synced %1").printf (sync_file_item.original_file);
        //      } else if (activity.file_action == "file_renamed") {
        //          activity.message = _("You renamed %1").printf (sync_file_item.original_file);
        //      } else if (activity.file_action == "file_deleted") {
        //          activity.message = _("You deleted %1").printf (sync_file_item.original_file);
        //      } else if (activity.file_action == "file_created") {
        //          activity.message = _("You created %1").printf (sync_file_item.original_file);
        //      } else {
        //          activity.message = _("You changed %1").printf (sync_file_item.original_file);
        //      }

        //      this.activity_model.add_sync_file_item_to_activity_list (activity);
        //  } else {
        //      GLib.warning ("Item " + sync_file_item.file + " retrieved resulted in error " + sync_file_item.error_string);
        //      activity.subject = sync_file_item.error_string;

        //      if (sync_file_item.status == LibSync.SyncFileItem.Status.FileIgnored) {
        //          this.activity_model.add_ignored_file_to_list (activity);
        //      } else {
        //          // add 'protocol error' to activity list
        //          if (sync_file_item.status == LibSync.SyncFileItem.Status.FileNameInvalid) {
        //              show_desktop_notification (sync_file_item.file, activity.subject);
        //          }
        //          this.activity_model.add_error_to_activity_list (activity);
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_item_completed (string folder_connection, LibSync.SyncFileItem sync_file_item) {
        //  try {
        //      var folder_connection = FolderManager.instance.folder_by_alias (folder_connection);

        //      if (!is_activity_of_current_account (folder_connection) || is_unsolvable_conflict (sync_file_item)) {
        //          return;
        //      }

        //      GLib.warning ("Item " + sync_file_item.file + " retrieved resulted in " + sync_file_item.error_string);
        //      process_completed_sync_item (folder_connection, sync_file_item);
        //  } catch (FolderManagerError error) {

        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_add_error (string folder_alias, string message, LibSync.ErrorCategory category) {
        //  try {
        //      var folder_connection = FolderManager.instance.folder_by_alias (folder_alias);

        //      if (folder_connection.account_state == this.account_state) {
        //          GLib.warning ("Item " + folder_connection.short_gui_local_path + " retrieved resulted in " + message);

        //          Activity activity;
        //          activity.type = Activity.Type.SYNC_RESULT;
        //          activity.status = SyncResult.Status.ERROR;
        //          activity.date_time = GLib.DateTime.from_string (GLib.DateTime.current_date_time ().to_string (), GLib.ISODate);
        //          activity.subject = message;
        //          activity.message = folder_connection.short_gui_local_path;
        //          activity.link = folder_connection.short_gui_local_path;
        //          activity.acc_name = folder_connection.account_state.account.display_name;
        //          activity.folder_connection = folder_alias;

        //          if (category == LibSync.ErrorCategory.INSUFFICIENT_REMOTE_STORAGE) {
        //              ActivityLink link;
        //              link.label = _("Retry all uploads");
        //              link.link = folder_connection.path;
        //              link.verb = "";
        //              link.primary = true;
        //              activity.links.append (link);
        //          }

        //          // add 'other errors' to activity list
        //          this.activity_model.add_error_to_activity_list (activity);
        //      }
        //  } catch (FolderManagerError error) {

        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_add_error_to_gui (string folder_alias, LibSync.SyncFileItem.Status status, string error_message, string subject) {
        //  try {
        //      var folder_connection = FolderManager.instance.folder_by_alias (folder_alias);


        //      if (folder_connection.account_state == this.account_state) {
        //          GLib.warning ("Item " + folder_connection.short_gui_local_path + " retrieved resulted in " + error_message);

        //          Activity activity;
        //          activity.type = Activity.Type.SYNC_FILE_ITEM;
        //          activity.status = status;
        //          var current_date_time = GLib.DateTime.current_date_time ();
        //          activity.date_time = GLib.DateTime.from_string (current_date_time.to_string (), GLib.ISODate);
        //          activity.expire_at_msecs = current_date_time.add_m_secs (ACTIVITY_DEFAULT_EXPIRATION_TIME_MSECS).to_m_secs_since_epoch ();
        //          activity.subject = !subject == "" ? subject : folder_connection.short_gui_local_path;
        //          activity.message = error_message;
        //          activity.link = folder_connection.short_gui_local_path;
        //          activity.acc_name = folder_connection.account_state.account.display_name;
        //          activity.folder_connection = folder_alias;

        //          // add 'other errors' to activity list
        //          this.activity_model.add_error_to_activity_list (activity);

        //          show_desktop_notification (activity.subject, activity.message);

        //          if (!this.expired_activities_check_timer_active) {
        //              this.expired_activities_check_timer_active = true;
        //              GLib.Timeout.add (
        //                  (uint)EXPIRED_ACTIVITIES_CHECK_INTERVAL_MSEC,
        //                  this.on_signal_check_expired_activities
        //              );
        //          }
        //      }
        //  } catch (FolderManagerError error) {

        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notification_request_finished (int status_code) {
        //  int row = sender ().property ("activity_row").to_int ();

        //  // the ocs API returns stat code 100 or 200 inside the xml if it succeeded.
        //  if (status_code != OCS_SUCCESS_STATUS_CODE && status_code != OCS_SUCCESS_STATUS_CODE_V2) {
        //      GLib.warning ("Notification Request to Server failed, leave notification visible.");
        //  } else {
        //      // to do use the model to rebuild the list or remove the item
        //      GLib.warning ("Notification Request to Server successed, rebuilding list.");
        //      this.activity_model.remove_activity_from_activity_list (row);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_end_notification_request (int reply_code) {
        //  this.notification_requests_running--;
        //  on_signal_notification_request_finished (reply_code);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notify_network_error (GLib.InputStream reply) {
        //  var notification_confirm_job = (NotificationConfirmJob)sender ();
        //  if (!notification_confirm_job) {
        //      return;
        //  }

        //  int result_code = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        //  on_signal_end_notification_request (result_code);
        //  GLib.warning ("Server notify job failed with code " + result_code);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_progress_info (string folder_connection_alias, LibSync.ProgressInfo progress) {
        //  if (progress.status () == LibSync.ProgressInfo.Status.RECONCILE) {
        //      try {
        //          // Wipe all non-persistent entries - as well as the persistent ones
        //          // in cases where a local discovery was done.
        //          var folder_connection = FolderManager.instance.folder_by_alias (folder_connection_alias);

        //          var engine = folder_connection.sync_engine;
        //          var style = engine.last_local_discovery_style ();
        //          foreach (Activity activity in this.activity_model.errors_list ()) {
        //              if (activity.expire_at_msecs != -1) {
        //                  // we process expired activities in a different slot
        //                  continue;
        //              }
        //              if (activity.folder_connection_alias != folder_connection_alias) {
        //                  continue;
        //              }

        //              if (style == LocalDiscoveryStyle.FILESYSTEM_ONLY) {
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //                  continue;
        //              }

        //              if (activity.status == LibSync.SyncFileItem.Status.CONFLICT && !GLib.FileInfo (folder_connection.path + activity.file).exists ()) {
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //                  continue;
        //              }

        //              if (activity.status == LibSync.SyncFileItem.Status.FILE_LOCKED && !GLib.FileInfo (folder_connection.path + activity.file).exists ()) {
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //                  continue;
        //              }

        //              if (activity.status == LibSync.SyncFileItem.Status.FILE_IGNORED && !GLib.FileInfo (folder_connection.path + activity.file).exists ()) {
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //                  continue;
        //              }

        //              if (!GLib.FileInfo (folder_connection.path + activity.file).exists ()) {
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //                  continue;
        //              }

        //              var path = GLib.FileInfo (activity.file).directory ().path.to_utf8 ();
        //              if (path == ".")
        //                  path = "";

        //              if (engine.should_discover_locally (path))
        //                  this.activity_model.remove_activity_from_activity_list (activity);
        //          }
        //      } catch (FolderManagerError error) {

        //      }
        //  }

        //  if (progress.status () == LibSync.ProgressInfo.Status.DONE) {
        //      // We keep track very well of pending conflicts.
        //      // Inform other components about them.
        //      GLib.List<string> conflicts;
        //      foreach (Activity activity in this.activity_model.errors_list ()) {
        //          if (activity.folder_connection_alias == folder_connection_alias
        //              && activity.status == LibSync.SyncFileItem.Status.CONFLICT) {
        //              conflicts.append (activity.file);
        //          }
        //      }

        //      ProgressDispatcher.instance.signal_folder_conflicts (folder_connection_alias, conflicts);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_send_notification_request (string account_name, string link, string verb, int row) {
        //  GLib.info ("Server Notification Request " + verb + link + " on account " + account_name);

        //  GLib.List<string> valid_verbs = new GLib.List<string> ();
        //  valid_verbs.append ("GET");
        //  valid_verbs.append ("PUT");
        //  valid_verbs.append ("POST");
        //  valid_verbs.append ("DELETE");

        //  if (valid_verbs.find (verb).length () > 0) {
        //      unowned AccountState acc = AccountManager.instance.account (account_name);
        //      if (acc != null) {
        //          NotificationConfirmJob notification_confirm_job = new NotificationConfirmJob (acc.account);
        //          GLib.Uri l_uri = new GLib.Uri (link);
        //          notification_confirm_job.link_and_verb (l_uri, verb);
        //          notification_confirm_job.property ("activity_row", GLib.Variant.from_value (row));
        //          notification_confirm_job.signal_network_error.connect (
        //              this.on_signal_notify_network_error
        //          );
        //          notification_confirm_job.signal_job_finished.connect (
        //              this.on_signal_notify_server_finished
        //          );
        //          notification_confirm_job.on_signal_start ();

        //          // count the number of running notification requests. If this member var
        //          // is larger than zero, no new fetching of notifications is started
        //          User.notification_requests_running++;
        //      }
        //  } else {
        //      GLib.warning ("Notification Links: Invalid verb: " + verb);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_notify_server_finished (string reply, int reply_code) {
        //  var notification_confirm_job = (NotificationConfirmJob)sender ();
        //  if (!notification_confirm_job) {
        //      return;
        //  }

        //  on_signal_end_notification_request (reply_code);
        //  GLib.info ("Server Notification reply code " + reply_code.to_string () + reply);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_build_notification_display (GLib.List<Activity> list) {
        //  this.activity_model.clear_notifications ();

        //  foreach (var activity in list) {
        //      if (this.blocklisted_notifications.find (activity).length () > 0) {
        //          GLib.info ("Activity in blocklist; skipping.");
        //          continue;
        //      }
        //      var message = AccountManager.instance.accounts.length () == 1 ? "" : activity.acc_name;
        //      show_desktop_notification (activity.subject, message);
        //      this.activity_model.add_notification_to_activity_list (activity);
        //  }
    }


    /***********************************************************
    Starts a server notification handler if no notification
    requests are running
    ***********************************************************/
    public void on_signal_refresh_notifications () {
        //  if (this.notification_requests_running == 0) {
        //      var server_notification_handler = new ServerNotificationHandler (this.account_state);
        //      server_notification_handler.signal_new_notification_list.connect (
        //          this.on_signal_build_notification_display
        //      );

        //      server_notification_handler.on_signal_fetch_notifications ();
        //  } else {
        //      GLib.warning ("Notification request counter not zero.");
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_activities () {
        //  this.activity_model.on_signal_refresh_activity ();
    }


    /***********************************************************
    I'm not sure if this should be repeating.
    ***********************************************************/
    public bool on_signal_refresh () {
        //  if (!this.notification_check_timer_active) {
        //      return true; // run repeatedly
        //  }
        //  on_signal_refresh_user_status ();

        //  if (check_push_notifications_are_ready ()) {
        //      // we are relying on Web_socket push notifications - ignore refresh attempts from UI
        //      this.time_since_last_check.get (this.account_state).invalidate ();
        //      return true; // run repeatedly
        //  }

        //  // GLib.Timer isn't actually constructed as invalid.
        //  if (!this.time_since_last_check.contains (this.account_state)) {
        //      this.time_since_last_check.get (this.account_state).invalidate ();
        //  }
        //  GLib.Timer timer = this.time_since_last_check.get (this.account_state);

        //  // Fetch Activities only if visible and if last check is longer than 15 secs ago
        //  if (timer.is_valid && timer.elapsed () < NOTIFICATION_REQUEST_FREE_PERIOD) {
        //      GLib.debug ("Do not check as last check is only secs ago: " + (timer.elapsed () / 1000).to_string ());
        //      return true; // run repeatedly
        //  }
        //  if (this.account_state != null && this.account_state.is_connected) {
        //      if (!timer.is_valid) {
        //          on_signal_refresh_activities ();
        //      }
        //      on_signal_refresh_notifications ();
        //      timer.on_signal_start ();
        //  }
        //  return true; // run repeatedly
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_user_status () {
        //  if (this.account_state != null && this.account_state.is_connected) {
        //      this.account_state.account.user_status_connector ().fetch_user_status ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_immediately () {
        //  if (this.account_state != null && this.account_state.is_connected) {
        //      on_signal_refresh_activities ();
        //  }
        //  on_signal_refresh_notifications ();
    }


    /***********************************************************
    FIXME: interval was previously in milliseconds, not microsecomnds!
    ***********************************************************/
    public void on_signal_notification_refresh_interval (GLib.TimeSpan interval_in_microseconds) {
        //  if (!check_push_notifications_are_ready ()) {
        //      GLib.debug ("Starting Notification refresh timer with " + interval_in_microseconds.to_string () / 1000 + " sec interval_in_microseconds");

        //      this.notification_check_timer_active = true;
        //      GLib.Timeout.add (
        //          (uint)interval_in_microseconds,
        //          this.on_signal_refresh
        //      );
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_rebuild_navigation_app_list () {
        //  signal_server_has_talk_changed ();
        //  // Rebuild App list
        //  UserAppsModel.instance.build_app_list ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_push_notifications_ready () {
        //  GLib.info ("Push notifications are ready.");

        //  if (this.notification_check_timer_active) {
        //      /***********************************************************
        //      As we are now able to use push notifications, let's stop the
        //      polling timer.
        //      ***********************************************************/
        //      this.notification_check_timer_active = false;
        //  }

        //  connect_push_notifications ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_disconnect_push_notifications () {
        //  disconnect (this.account_state.account.push_notifications (), PushNotificationManager.notifications_changed, this, User.on_signal_received_push_notification);
        //  disconnect (this.account_state.account.push_notifications (), PushNotificationManager.activities_changed, this, User.on_signal_received_push_activity);

        //  disconnect (this.account_state.account, LibSync.Account.push_notifications_disabled, this, User.on_signal_disconnect_push_notifications);

        //  // connection to Web_socket may have dropped or an error occured, so we need to bring back the polling until we have re-established the connection
        //  on_signal_notification_refresh_interval (LibSync.ConfigFile ().notification_refresh_interval ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_received_push_notification (LibSync.Account account) {
        //  if (account.identifier == this.account_state.account.identifier) {
        //      on_signal_refresh_notifications ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_received_push_activity (LibSync.Account account) {
        //  if (account.identifier == this.account_state.account.identifier) {
        //      on_signal_refresh_activities ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_check_expired_activities () {
        //  if (!this.expired_activities_check_timer_active) {
        //      return true; // run repeatedly
        //  }
        //  foreach (Activity activity in this.activity_model.errors_list ()) {
        //      if (activity.expire_at_msecs > 0 && GLib.DateTime.current_date_time ().to_m_secs_since_epoch () >= activity.expire_at_msecs) {
        //          this.activity_model.remove_activity_from_activity_list (activity);
        //      }
        //  }

        //  if (this.activity_model.errors_list ().length () == 0) {
        //      this.expired_activities_check_timer_active = false;
        //  }
        //  return true; // run repeatedly
    }


    /***********************************************************
    ***********************************************************/
    private void connect_push_notifications () {
        //  this.account_state.account.push_notifications_disabled.connect (
        //      this.on_signal_disconnect_push_notifications // GLib.UniqueConnection
        //  );

        //  this.account_state.account.push_notifications.notifications_changed.connect (
        //      this.on_signal_received_push_notification // GLib.UniqueConnection
        //  );
        //  this.account_state.account.push_notifications.activities_changed.connect (
        //      this.on_signal_received_push_activity // GLib.UniqueConnection
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private bool is_activity_of_current_account (FolderConnection folder_connection) {
        //  return folder_connection.account_state == this.account_state;
    }


    /***********************************************************
    We only care about conflict issues that we are able to
    resolve
    ***********************************************************/
    private static bool is_unsolvable_conflict (LibSync.SyncFileItem sync_file_item) {
        //  return sync_file_item.status == LibSync.SyncFileItem.Status.CONFLICT && !Utility.is_conflict_file (sync_file_item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void show_desktop_notification (string title, string message) {
        //  LibSync.ConfigFile config;
        //  if (!config.optional_server_notifications () || !are_desktop_notifications_allowed) {
        //      return;
        //  }

        //  // after one hour, clear the gui log notification store
        //  int64 clear_gui_log_interval = 60 * 60 * 1000;
        //  if (this.gui_log_timer.elapsed () > clear_gui_log_interval) {
        //      this.notification_cache = null;
        //  }

        //  NotificationCache.Notification notification = NotificationCache.Notification (
        //      title,
        //      message
        //  );
        //  if (this.notification_cache.contains (notification)) {
        //      return;
        //  }

        //  this.notification_cache.insert (notification);
        //  signal_gui_log (notification.title, notification.message);
        //  // restart the gui log timer now that we show a new notification
        //  this.gui_log_timer.on_signal_start ();
    }

} // class User

} // namespace Ui
} // namespace Occ
