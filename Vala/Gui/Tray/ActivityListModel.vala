/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QtCore>
//  #include <GLib.DesktopServices>
//  #include <Gtk.Widget>
//  #include <Json.Object>
//  #include <GLib.JsonDocument>
//  #include <qloggingcategory.h>
//  #include <QtCore>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ActivityListModel
@ingroup gui

Simple list model to provide the list view with data.
***********************************************************/
public class ActivityListModel { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum DataRole {
        ACTION_ICON, // GLib.USER_ROLE + 1,
        USER_ICON,
        ACCOUNT,
        OBJECT_TYPE,
        ACTION_LINKS,
        ACTION_TEXT,
        ACTION_TEXT_COLOR,
        ACTION,
        MESSAGE,
        DISPLAY_PATH,
        PATH,
        ABSOLUTE_PATH,
        LINK,
        POINT_IN_TIME,
        ACCOUNT_CONNECTED,
        SYNC_FILE_STATUS,
        DISPLAY_ACTIONS,
        SHAREABLE,
    }


    /***********************************************************
    ***********************************************************/
    private GLib.List<Activity> activity_lists;
    private GLib.List<Activity> sync_file_item_lists;
    private GLib.List<Activity> notification_lists;
    private GLib.List<Activity> list_of_ignored_files;
    private Activity notification_ignored_files;
    private GLib.List<Activity> notification_errors_lists;
    private GLib.List<Activity> final_list;
    private int current_item = 0;

    /***********************************************************
    ***********************************************************/
    private int total_activities_fetched = 0;
    private int max_activities = 100;
    private int max_activities_days = 30;
    private bool show_more_activities_available_entry = false;

    /***********************************************************
    ***********************************************************/
    private ConflictDialog current_conflict_dialog;

    /***********************************************************
    ***********************************************************/
    public AccountState account_state { public get; protected set; }
    protected bool currently_fetching { protected get; protected set; }
    protected bool display_actions { private get; protected set; }
    protected bool done_fetching { private get; protected set; }
    protected bool hide_old_activities { private get; protected set; }


    internal signal void signal_activity_job_status_code (int status_code);
    internal signal void signal_send_notification_request (string account_name, string link, string verb, int row);


    /***********************************************************
    ***********************************************************/
    public ActivityListModel (
        //  AccountState account_state = null
    ) {
        //  base ();
        //  this.account_state = account_state;
        //  this.currently_fetching = false;
        //  this.display_actions = true;
        //  this.done_fetching = false;
        //  this.hide_old_activities = true;
    }


    /***********************************************************
    ***********************************************************/
    public uint row_count () {
        //  return this.final_list.length ();
    }


    /***********************************************************
    ***********************************************************/
    public bool can_fetch_more (GLib.ModelIndex index) {
        //  // We need to be connected to be able to fetch more
        //  if (this.account_state != null && this.account_state.is_connected) {
        //      // If the fetching is reported to be done or we are currently fetching we can't fetch more
        //      if (!this.done_fetching && !this.currently_fetching) {
        //          return true;
        //      }
        //  }

        //  return false;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_more (GLib.ModelIndex index) {
        //  if (can_fetch_activities ()) {
        //      start_fetch_job ();
        //  } else {
        //      this.done_fetching = true;
        //      combine_activity_lists ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<Activity> activity_list () {
        //  return this.final_list;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<Activity> errors_list () {
        //  return null;
    }


    /***********************************************************
    ***********************************************************/
    public void add_notification_to_activity_list (Activity activity) {
        //  GLib.info ("Notification successfully added to the notification list: " + activity.subject);
        //  this.notification_lists.prepend (activity);
        //  combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void clear_notifications () {
        //  GLib.info ("Clearing the notifications.");
        //  this.notification_lists = null;
        //  combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_error_to_activity_list (Activity activity) {
        //  GLib.info ("Error successfully added to the notification list: " + activity.subject);
        //  this.notification_errors_lists.prepend (activity);
        //  combine_activity_lists ();
    }



    /***********************************************************
    ***********************************************************/
    public void add_sync_file_item_to_activity_list (Activity activity) {
        //  GLib.info ("Successfully added to the activity list: " + activity.subject);
        //  this.sync_file_item_lists.prepend (activity);
        //  combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_ignored_file_to_list (Activity new_activity) {
        //  GLib.info ("First checking for duplicates then add file to the notification list of ignored files: " + new_activity.file);

        //  bool duplicate = false;
        //  if (this.list_of_ignored_files.length () == 0) {
        //      this.notification_ignored_files = new_activity;
        //      this.notification_ignored_files.subject = _("Files from the ignore list as well as symbolic links are not synced.");
        //      this.list_of_ignored_files.append (new_activity);
        //      return;
        //  }

        //  foreach (Activity activity in this.list_of_ignored_files) {
        //      if (activity.file == new_activity.file) {
        //          duplicate = true;
        //          break;
        //      }
        //  }

        //  if (!duplicate) {
        //      this.notification_ignored_files.message.append (", " + new_activity.file);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void remove_activity_from_activity_list_by_row (int row) {
        //  Activity activity = this.final_list.at (row);
        //  remove_activity_from_activity_list (activity);
        //  combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_activity_from_activity_list_by_reference (Activity activity) {
        //  GLib.info ("Activity/Notification/Error successfully dismissed: " + activity.subject);
        //  GLib.info ("Trying to remove Activity/Notification/Error from view... ");

        //  int index = -1;
        //  if (activity.type == Activity.Type.ACTIVITY) {
        //      index = this.activity_lists.index_of (activity);
        //      if (index != -1)
        //          this.activity_lists.remove_at (index);
        //  } else if (activity.type == Activity.Type.NOTIFICATION) {
        //      index = this.notification_lists.index_of (activity);
        //      if (index != -1)
        //          this.notification_lists.remove_at (index);
        //  } else {
        //      index = this.notification_errors_lists.index_of (activity);
        //      if (index != -1)
        //          this.notification_errors_lists.remove_at (index);
        //  }

        //  if (index != -1) {
        //      GLib.info ("Activity/Notification/Error successfully removed from the list.");
        //      GLib.info ("Updating Activity/Notification/Error view.");
        //      combine_activity_lists ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (GLib.ModelIndex index, int role) {
        //  Activity activity;

        //  if (!index.is_valid)
        //      return GLib.Variant ();

        //  activity = this.final_list.at (index.row ());
        //  unowned AccountState new_account_state = AccountManager.instance.account (activity.acc_name);
        //  if (!new_account_state && this.account_state != new_account_state)
        //      return GLib.Variant ();

        //  switch (role) {
        //  case DataRole.DISPLAY_PATH:
        //      if (!activity.file == "") {
        //          var folder_connection = FolderManager.instance.folder_by_alias (activity.folder_connection);
        //          string relative_path = activity.file;
        //          if (folder_connection) {
        //              relative_path.prepend (folder_connection.remote_path);
        //          }
        //          var local_files = FolderManager.instance.find_file_in_local_folders (relative_path, new_account_state.account);
        //          if (local_files.length > 0) {
        //              if (relative_path.has_prefix ("/") || relative_path.has_prefix ('\\')) {
        //                  return relative_path.remove (0, 1);
        //              } else {
        //                  return relative_path;
        //              }
        //          }
        //      }
        //      return "";
        //  case DataRole.PATH:
        //      if (!activity.file == "") {
        //          var folder_connection = FolderManager.instance.folder_by_alias (activity.folder_connection);

        //          string relative_path = activity.file;
        //          if (folder_connection) {
        //              relative_path.prepend (folder_connection.remote_path);
        //          }

        //          // get relative path to the file so we can open it in the file manager
        //          var local_files = FolderManager.instance.find_file_in_local_folders (GLib.FileInfo (relative_path).path, new_account_state.account);

        //          if (local_files == "") {
        //              return "";
        //          }

        //          // If this is an E2EE file or folder_connection, pretend we got no path, this leads to
        //          // hiding the share button which is what we want
        //          if (folder_connection) {
        //              Common.SyncJournalFileRecord record;
        //              folder_connection.journal_database.file_record (activity.file.mid (1), record);
        //              if (record.is_valid && (record.is_e2e_encrypted || !record.e2e_mangled_name == "")) {
        //                  return "";
        //              }
        //          }

        //          return GLib.Uri.from_local_file (local_files.const_first ());
        //      }
        //      return "";
        //  case DataRole.ABSOLUTE_PATH: {
        //      var folder_connection = FolderManager.instance.folder_by_alias (activity.folder_connection);
        //      string relative_path = activity.file;
        //      if (!activity.file == "") {
        //          if (folder_connection) {
        //              relative_path.prepend (folder_connection.remote_path);
        //          }
        //          var local_files = FolderManager.instance.find_file_in_local_folders (relative_path, new_account_state.account);
        //          if (!local_files.empty ()) {
        //              return local_files.const_first ();
        //          } else {
        //              GLib.warning ("File not local folders while processing absolute path request.");
        //              return "";
        //          }
        //      } else {
        //          GLib.warning ("Received an absolute path request for an activity without a file path.");
        //          return "";
        //      }
        //  }
        //  case DataRole.ACTION_LINKS: {
        //      GLib.List<GLib.Variant> custom_list;
        //      foreach (ActivityLink activity_link in activity.links) {
        //          custom_list += GLib.Variant.from_value (activity_link);
        //      }
        //      return custom_list;
        //  }
        //  case DataRole.ACTION_ICON: {
        //      if (activity.type == Activity.Type.NOTIFICATION) {
        //          return "qrc:///client/theme/black/bell.svg";
        //      } else if (activity.type == Activity.Type.SYNC_RESULT) {
        //          return "qrc:///client/theme/black/state-error.svg";
        //      } else if (activity.type == Activity.Type.SYNC_FILE_ITEM) {
        //          if (activity.status == LibSync.SyncFileItem.Status.NORMAL_ERROR
        //              || activity.status == LibSync.SyncFileItem.Status.FATAL_ERROR
        //              || activity.status == LibSync.SyncFileItem.Status.DETAIL_ERROR
        //              || activity.status == LibSync.SyncFileItem.Status.BLOCKLISTED_ERROR) {
        //              return "qrc:///client/theme/black/state-error.svg";
        //          } else if (activity.status == LibSync.SyncFileItem.Status.SOFT_ERROR
        //              || activity.status == LibSync.SyncFileItem.Status.CONFLICT
        //              || activity.status == LibSync.SyncFileItem.Status.RESTORATION
        //              || activity.status == LibSync.SyncFileItem.Status.FILE_LOCKED
        //              || activity.status == LibSync.SyncFileItem.Status.FILENAME_INVALID) {
        //              return "qrc:///client/theme/black/state-warning.svg";
        //          } else if (activity.status == LibSync.SyncFileItem.Status.FILE_IGNORED) {
        //              return "qrc:///client/theme/black/state-info.svg";
        //          } else {
        //              // File sync successful
        //              if (activity.file_action == "file_created") {
        //                  return "qrc:///client/theme/colored/add.svg";
        //              } else if (activity.file_action == "file_deleted") {
        //                  return "qrc:///client/theme/colored/delete.svg";
        //              } else {
        //                  return "qrc:///client/theme/change.svg";
        //              }
        //          }
        //      } else {
        //          // We have an activity
        //          if (activity.icon == "") {
        //              return "qrc:///client/theme/black/activity.svg";
        //          }

        //          return activity.icon;
        //      }
        //  }
        //  case DataRole.OBJECT_TYPE:
        //      return activity.object_type;
        //  case DataRole.ACTION: {
        //      switch (activity.type) {
        //      case Activity.Type.ACTIVITY:
        //          return "Activity";
        //      case Activity.Type.NOTIFICATION:
        //          return "Notification";
        //      case Activity.Type.SYNC_FILE_ITEM:
        //          return "File";
        //      case Activity.Type.SYNC_RESULT:
        //          return "Sync";
        //      default:
        //          return GLib.Variant ();
        //      }
        //  }
        //  case DataRole.ACTION_TEXT:
        //      return activity.subject;
        //  case DataRole.ACTION_TEXT_COLOR:
        //      return activity.id == -1 ? "#808080" : "#222";   // FIXME: This is a temporary workaround for this.show_more_activities_available_entry
        //  case DataRole.MESSAGE:
        //      return activity.message;
        //  case DataRole.LINK: {
        //      if (activity.link == "") {
        //          return "";
        //      } else {
        //          return activity.link;
        //      }
        //  }
        //  case DataRole.ACCOUNT:
        //      return activity.acc_name;
        //  case DataRole.POINT_IN_TIME:
        //      //  return activity.id == -1 ? "" : "%1 - %2".printf (Utility.time_ago_in_words (activity.date_time.to_local_time ()), activity.date_time.to_local_time ().to_string (GLib.Default_locale_short_date));
        //      return activity.id == -1 ? "" : Utility.time_ago_in_words (activity.date_time.to_local_time ());
        //  case DataRole.ACCOUNT_CONNECTED:
        //      return (new_account_state && new_account_state.is_connected);
        //  case DataRole.DISPLAY_ACTIONS:
        //      return this.display_actions;
        //  case DataRole.SHAREABLE:
        //      return !data (index, DataRole.PATH).to_string () == "" && this.display_actions && activity.file_action != "file_deleted" && activity.status != LibSync.SyncFileItem.Status.FILE_IGNORED;
        //  default:
        //      return GLib.Variant ();
        //  }
        //  return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public void trigger_default_action (int activity_index) {
        //  if (activity_index < 0 || activity_index >= this.final_list.size ()) {
        //      GLib.warning ("Couldn't trigger default action at index " + activity_index + "/ final list size: " + this.final_list.size ());
        //      return;
        //  }

        //  var model_index = index (activity_index);
        //  var path = data (model_index, DataRole.PATH).to_url ();

        //  var activity = this.final_list.at (activity_index);
        //  if (activity.status == LibSync.SyncFileItem.Status.CONFLICT) {
        //      //  GLib.assert_true (!activity.file == "");
        //      //  GLib.assert_true (!activity.folder_connection == "");
        //      //  GLib.assert_true (Utility.is_conflict_file (activity.file));

        //      var folder_connection = FolderManager.instance.folder_by_alias (activity.folder_connection);

        //      var conflicted_relative_path = activity.file;
        //      var base_relative_path = folder_connection.journal_database.conflict_file_base_name (conflicted_relative_path.to_utf8 ());

        //      var directory = GLib.Dir (folder_connection.path);
        //      var conflicted_path = directory.file_path (conflicted_relative_path);
        //      var base_path = directory.file_path (base_relative_path);

        //      var base_name = GLib.FileInfo (base_path).filename ();

        //      if (this.current_conflict_dialog != null) {
        //          this.current_conflict_dialog.close ();
        //      }
        //      this.current_conflict_dialog = new ConflictDialog ();
        //      this.current_conflict_dialog.on_signal_base_filename (base_name);
        //      this.current_conflict_dialog.on_signal_local_version_filename (conflicted_path);
        //      this.current_conflict_dialog.on_signal_remote_version_filename (base_path);
        //      this.current_conflict_dialog.attribute (GLib.WA_DeleteOnClose);
        //      this.current_conflict_dialog.accepted.connect (
        //          folder_connection,
        //          this.on_signal_current_conflict_dialog_accepted
        //      );
        //      this.current_conflict_dialog.open ();
        //      OwncloudGui.raise_dialog (this.current_conflict_dialog);
        //      return;
        //  } else if (activity.status == LibSync.SyncFileItem.Status.FILENAME_INVALID) {
        //      if (!this.current_invalid_filename_dialog == null) {
        //          this.current_invalid_filename_dialog.close ();
        //      }

        //      var folder_connection = FolderManager.instance.folder_by_alias (activity.folder_connection);
        //      var folder_dir = GLib.Dir (folder_connection.path);
        //      this.current_invalid_filename_dialog = new InvalidFilenameDialog (
        //          this.account_state.account,
        //          folder_connection,
        //          folder_dir.file_path (activity.file)
        //      );
        //      this.current_invalid_filename_dialog.accepted.connect (
        //          folder_connection,
        //          this.on_signal_current_invalid_filename_dialog_accepted
        //      );
        //      this.current_invalid_filename_dialog.open ();
        //      OwncloudGui.raise_dialog (this.current_invalid_filename_dialog);
        //      return;
        //  }

        //  if (path.is_valid) {
        //      GLib.DesktopServices.open_url (path);
        //  } else {
        //      var link = data (model_index, DataRole.LINK).to_url ();
        //      OpenExternal.open_browser (link);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_current_conflict_dialog_accepted (FolderConnection folder_connection) {
        //  folder_connection.schedule_this_folder_soon ();
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_current_invalid_filename_dialog_accepted (FolderConnection folder_connection) {
        //  folder_connection.schedule_this_folder_soon ();
    }


    /***********************************************************
    ***********************************************************/
    public void trigger_action (int activity_index, int action_index) {
        //  if (activity_index < 0 || activity_index >= this.final_list.size ()) {
        //      GLib.warning ("Couldn't trigger action on activity at index " + activity_index + "/ final list size: " + this.final_list.size ());
        //      return;
        //  }

        //  var activity = this.final_list[activity_index];

        //  if (action_index < 0 || action_index >= activity.links.size ()) {
        //      GLib.warning ("Couldn't trigger action at index " + action_index + "/ actions list size: " + activity.links.size ());
        //      return;
        //  }

        //  var action = activity.links[action_index];

        //  if (action.verb == "WEB") {
        //      OpenExternal.open_browser (GLib.Uri (action.link));
        //      return;
        //  }

        //  signal_send_notification_request (activity.acc_name, action.link, action.verb, activity_index);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_activity () {
        //  this.activity_lists = null;
        //  this.done_fetching = false;
        //  this.current_item = 0;
        //  this.total_activities_fetched = 0;
        //  this.show_more_activities_available_entry = false;

        //  if (can_fetch_activities ()) {
        //      start_fetch_job ();
        //  } else {
        //      this.done_fetching = true;
        //      combine_activity_lists ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remove_account () {
        //  this.final_list = "";
        //  this.activity_lists = "";
        //  this.currently_fetching = false;
        //  this.done_fetching = false;
        //  this.current_item = 0;
        //  this.total_activities_fetched = 0;
        //  this.show_more_activities_available_entry = false;
    }


    /***********************************************************
    ***********************************************************/
    protected void activities_received (GLib.JsonDocument json, int status_code) {
        //  var activities = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        //  GLib.List<Activity> list;
        //  var this.account_state = this.account_state;
        //  if (this.account_state == null) {
        //      return;
        //  }

        //  if (activities.size () == 0) {
        //      this.done_fetching = true;
        //  }

        //  this.currently_fetching = false;

        //  GLib.DateTime oldest_date = GLib.DateTime.current_date_time ();
        //  oldest_date = oldest_date.add_days (this.max_activities_days * -1);

        //  foreach (var activ in activities) {
        //      var json = activ.to_object ();

        //      Activity activity;
        //      activity.type = Activity.Type.ACTIVITY;
        //      activity.object_type = json.value ("object_type").to_string ();
        //      activity.acc_name = this.account_state.account.display_name;
        //      activity.id = json.value ("activity_id").to_int ();
        //      activity.file_action = json.value ("type").to_string ();
        //      activity.subject = json.value ("subject").to_string ();
        //      activity.message = json.value ("message").to_string ();
        //      activity.file = json.value ("object_name").to_string ();
        //      activity.link = GLib.Uri (json.value ("link").to_string ());
        //      activity.date_time = GLib.DateTime.from_string (json.value ("datetime").to_string (), GLib.ISODate);
        //      activity.icon = json.value ("icon").to_string ();

        //      list.append (activity);
        //      this.current_item = list.last ().id;

        //      this.total_activities_fetched++;
        //      if (this.total_activities_fetched == this.max_activities
        //          || (this.hide_old_activities && activity.date_time < oldest_date)) {
        //          this.show_more_activities_available_entry = true;
        //          this.done_fetching = true;
        //          break;
        //      }
        //  }

        //  this.activity_lists.append (list);

        //  signal_activity_job_status_code (status_code);

        //  combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    protected void start_fetch_job () {
        //  if (!this.account_state.is_connected) {
        //      return;
        //  }
        //  var json_api_job = new LibSync.JsonApiJob (this.account_state.account, "ocs/v2.php/apps/activity/api/v2/activity", this);
        //  json_api_job.signal_json_received.connect (
        //      this.activities_received
        //  );

        //  GLib.UrlQuery parameters;
        //  parameters.add_query_item ("since", this.current_item.to_string ());
        //  parameters.add_query_item ("limit", 50.to_string ());
        //  json_api_job.add_query_params (parameters);

        //  this.currently_fetching = true;
        //  GLib.info ("Start fetching activities for " + this.account_state.account.display_name);
        //  json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void combine_activity_lists () {
        //  GLib.List<Activity> result_list;

        //  if (this.notification_errors_lists.length () > 0) {
        //      std.sort (this.notification_errors_lists.begin (), this.notification_errors_lists.end ());
        //      result_list.append (this.notification_errors_lists);
        //  }
        //  if (this.list_of_ignored_files.length () > 0)
        //      result_list.append (this.notification_ignored_files);

        //  if (this.notification_lists.length () > 0) {
        //      std.sort (this.notification_lists.begin (), this.notification_lists.end ());
        //      result_list.append (this.notification_lists);
        //  }

        //  if (this.sync_file_item_lists.length () > 0) {
        //      std.sort (this.sync_file_item_lists.begin (), this.sync_file_item_lists.end ());
        //      result_list.append (this.sync_file_item_lists);
        //  }

        //  if (this.activity_lists.length () > 0) {
        //      std.sort (this.activity_lists.begin (), this.activity_lists.end ());
        //      result_list.append (this.activity_lists);

        //      if (this.show_more_activities_available_entry) {
        //          Activity activity;
        //          activity.type = Activity.Type.ACTIVITY;
        //          activity.acc_name = this.account_state.account.display_name;
        //          activity.id = -1;
        //          activity.subject = _("For more activities please open the Activity app.");
        //          activity.date_time = GLib.DateTime.current_date_time ();

        //          AccountApp app = this.account_state.find_app ("activity");
        //          if (app) {
        //              activity.link = app.url;
        //          }

        //          result_list.append (activity);
        //      }
        //  }

        //  begin_reset_model ();
        //  this.final_list = null;
        //  end_reset_model ();

        //  if (result_list.length () > 0) {
        //      begin_insert_rows (GLib.ModelIndex (), 0, result_list.length - 1);
        //      this.final_list = result_list;
        //      end_insert_rows ();
        //  }
    }

    private bool can_fetch_activities () {
        //  return this.account_state.is_connected && this.account_state.account.capabilities.has_activities;
    }

} // class ActivityListModel

} // namespace Ui
} // namespace Occ
