/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QAbstractListModel>
//  #include <QDesktopServices>
//  #include <Gtk.Widget>
//  #include <QJsonObject>
//  #include <QJsonDocument>
//  #include <qloggingcategory.h>
//  #include <QtCore>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ActivityListModel
@ingroup gui

Simple list model to provide the list view with data.
***********************************************************/
public class ActivityListModel : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public enum DataRole {
        ACTION_ICON = Qt.USER_ROLE + 1,
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
    private ActivityList activity_lists;
    private ActivityList sync_file_item_lists;
    private ActivityList notification_lists;
    private ActivityList list_of_ignored_files;
    private Activity notification_ignored_files;
    private ActivityList notification_errors_lists;
    private ActivityList final_list;
    private int current_item = 0;

    /***********************************************************
    ***********************************************************/
    private int total_activities_fetched = 0;
    private int max_activities = 100;
    private int max_activities_days = 30;
    private bool show_more_activities_available_entry = false;

    /***********************************************************
    ***********************************************************/
    private QPointer<ConflictDialog> current_conflict_dialog;

    /***********************************************************
    ***********************************************************/
    AccountState account_state { public get; protected set; }
    bool currently_fetching { protected get; protected set; }
    bool display_actions { private get; protected set; }
    bool done_fetching { private get; protected set; }
    bool hide_old_activities { private get; protected set; }


    signal void activity_job_status_code (int status_code);
    signal void send_notification_request (string account_name, string link, GLib.ByteArray verb, int row);


    /***********************************************************
    ***********************************************************/
    public ActivityListModel (
        AccountState account_state = null,
        GLib.Object parent) {
        base (parent);
        this.account_state = account_state;
        this.currently_fetching = false;
        this.display_actions = true;
        this.done_fetching = false;
        this.hide_old_activities = true;
    }


    /***********************************************************
    ***********************************************************/
    public override int row_count (QModelIndex parent = new QModelIndex ()) {
        return this.final_list.count ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool can_fetch_more (QModelIndex index) {
        // We need to be connected to be able to fetch more
        if (this.account_state && this.account_state.is_connected ()) {
            // If the fetching is reported to be done or we are currently fetching we can't fetch more
            if (!this.done_fetching && !this.currently_fetching) {
                return true;
            }
        }

        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_more (QModelIndex index) {
        if (can_fetch_activities ()) {
            start_fetch_job ();
        } else {
            this.done_fetching = true;
            combine_activity_lists ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public ActivityList activity_list () {
        return this.final_list;
    }


    /***********************************************************
    ***********************************************************/
    public ActivityList errors_list () {
        return;
    }


    /***********************************************************
    ***********************************************************/
    public void add_notification_to_activity_list (Activity activity) {
        GLib.info ("Notification successfully added to the notification list: " + activity.subject);
        this.notification_lists.prepend (activity);
        combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void clear_notifications () {
        GLib.info ("Clearing the notifications.");
        this.notification_lists.clear ();
        combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_error_to_activity_list (Activity activity) {
        GLib.info ("Error successfully added to the notification list: " + activity.subject);
        this.notification_errors_lists.prepend (activity);
        combine_activity_lists ();
    }



    /***********************************************************
    ***********************************************************/
    public void add_sync_file_item_to_activity_list (Activity activity) {
        GLib.info ("Successfully added to the activity list: " + activity.subject);
        this.sync_file_item_lists.prepend (activity);
        combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_ignored_file_to_list (Activity new_activity) {
        GLib.info ("First checking for duplicates then add file to the notification list of ignored files: " + new_activity.file);

        bool duplicate = false;
        if (this.list_of_ignored_files.size () == 0) {
            this.notification_ignored_files = new_activity;
            this.notification_ignored_files.subject = _("Files from the ignore list as well as symbolic links are not synced.");
            this.list_of_ignored_files.append (new_activity);
            return;
        }

        foreach (Activity activity in this.list_of_ignored_files) {
            if (activity.file == new_activity.file) {
                duplicate = true;
                break;
            }
        }

        if (!duplicate) {
            this.notification_ignored_files.message.append (", " + new_activity.file);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void remove_activity_from_activity_list_by_row (int row) {
        Activity activity = this.final_list.at (row);
        remove_activity_from_activity_list (activity);
        combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_activity_from_activity_list_by_reference (Activity activity) {
        GLib.info ("Activity/Notification/Error successfully dismissed: " + activity.subject);
        GLib.info ("Trying to remove Activity/Notification/Error from view... ");

        int index = -1;
        if (activity.type == Activity.Type.ACTIVITY) {
            index = this.activity_lists.index_of (activity);
            if (index != -1)
                this.activity_lists.remove_at (index);
        } else if (activity.type == Activity.Type.NOTIFICATION) {
            index = this.notification_lists.index_of (activity);
            if (index != -1)
                this.notification_lists.remove_at (index);
        } else {
            index = this.notification_errors_lists.index_of (activity);
            if (index != -1)
                this.notification_errors_lists.remove_at (index);
        }

        if (index != -1) {
            GLib.info ("Activity/Notification/Error successfully removed from the list.");
            GLib.info ("Updating Activity/Notification/Error view.");
            combine_activity_lists ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) {
        Activity a;

        if (!index.is_valid ())
            return GLib.Variant ();

        a = this.final_list.at (index.row ());
        unowned AccountState ast = AccountManager.instance ().account (a.acc_name);
        if (!ast && this.account_state != ast.data ())
            return GLib.Variant ();

        switch (role) {
        case DataRole.DISPLAY_PATH:
            if (!a.file.is_empty ()) {
                var folder = FolderMan.instance ().folder_by_alias (a.folder);
                string relative_path = a.file;
                if (folder) {
                    relative_path.prepend (folder.remote_path ());
                }
                const var local_files = FolderMan.instance ().find_file_in_local_folders (relative_path, ast.account ());
                if (local_files.count () > 0) {
                    if (relative_path.starts_with ('/') || relative_path.starts_with ('\\')) {
                        return relative_path.remove (0, 1);
                    } else {
                        return relative_path;
                    }
                }
            }
            return "";
        case DataRole.PATH:
            if (!a.file.is_empty ()) {
                const var folder = FolderMan.instance ().folder_by_alias (a.folder);

                string relative_path = a.file;
                if (folder) {
                    relative_path.prepend (folder.remote_path ());
                }

                // get relative path to the file so we can open it in the file manager
                const var local_files = FolderMan.instance ().find_file_in_local_folders (GLib.FileInfo (relative_path).path (), ast.account ());

                if (local_files.is_empty ()) {
                    return "";
                }

                // If this is an E2EE file or folder, pretend we got no path, this leads to
                // hiding the share button which is what we want
                if (folder) {
                    SyncJournalFileRecord record;
                    folder.journal_database ().file_record (a.file.mid (1), record);
                    if (record.is_valid () && (record.is_e2e_encrypted || !record.e2e_mangled_name.is_empty ())) {
                        return "";
                    }
                }

                return GLib.Uri.from_local_file (local_files.const_first ());
            }
            return "";
        case DataRole.ABSOLUTE_PATH: {
            const var folder = FolderMan.instance ().folder_by_alias (a.folder);
            string relative_path = a.file;
            if (!a.file.is_empty ()) {
                if (folder) {
                    relative_path.prepend (folder.remote_path ());
                }
                const var local_files = FolderMan.instance ().find_file_in_local_folders (relative_path, ast.account ());
                if (!local_files.empty ()) {
                    return local_files.const_first ();
                } else {
                    GLib.warning ("File not local folders while processing absolute path request.");
                    return "";
                }
            } else {
                GLib.warning ("Received an absolute path request for an activity without a file path.");
                return "";
            }
        }
        case DataRole.ACTION_LINKS: {
            GLib.List<GLib.Variant> custom_list;
            foreach (ActivityLink activity_link in a.links) {
                custom_list += GLib.Variant.from_value (activity_link);
            }
            return custom_list;
        }
        case DataRole.ACTION_ICON: {
            if (a.type == Activity.Type.NOTIFICATION) {
                return "qrc:///client/theme/black/bell.svg";
            } else if (a.type == Activity.Type.SYNC_RESULT) {
                return "qrc:///client/theme/black/state-error.svg";
            } else if (a.type == Activity.Type.SYNC_FILE_ITEM) {
                if (a.status == SyncFileItem.Status.NORMAL_ERROR
                    || a.status == SyncFileItem.Status.FATAL_ERROR
                    || a.status == SyncFileItem.Status.DETAIL_ERROR
                    || a.status == SyncFileItem.Status.BLOCKLISTED_ERROR) {
                    return "qrc:///client/theme/black/state-error.svg";
                } else if (a.status == SyncFileItem.Status.SOFT_ERROR
                    || a.status == SyncFileItem.Status.CONFLICT
                    || a.status == SyncFileItem.Status.RESTORATION
                    || a.status == SyncFileItem.Status.FILE_LOCKED
                    || a.status == SyncFileItem.Status.FILENAME_INVALID) {
                    return "qrc:///client/theme/black/state-warning.svg";
                } else if (a.status == SyncFileItem.Status.FILE_IGNORED) {
                    return "qrc:///client/theme/black/state-info.svg";
                } else {
                    // File sync successful
                    if (a.file_action == "file_created") {
                        return "qrc:///client/theme/colored/add.svg";
                    } else if (a.file_action == "file_deleted") {
                        return "qrc:///client/theme/colored/delete.svg";
                    } else {
                        return "qrc:///client/theme/change.svg";
                    }
                }
            } else {
                // We have an activity
                if (a.icon.is_empty ()) {
                    return "qrc:///client/theme/black/activity.svg";
                }

                return a.icon;
            }
        }
        case DataRole.OBJECT_TYPE:
            return a.object_type;
        case DataRole.ACTION: {
            switch (a.type) {
            case Activity.Type.ACTIVITY:
                return "Activity";
            case Activity.Type.NOTIFICATION:
                return "Notification";
            case Activity.Type.SYNC_FILE_ITEM:
                return "File";
            case Activity.Type.SYNC_RESULT:
                return "Sync";
            default:
                return GLib.Variant ();
            }
        }
        case DataRole.ACTION_TEXT:
            return a.subject;
        case DataRole.ACTION_TEXT_COLOR:
            return a.id == -1 ? QLatin1String ("#808080") : QLatin1String ("#222");   // FIXME: This is a temporary workaround for this.show_more_activities_available_entry
        case DataRole.MESSAGE:
            return a.message;
        case DataRole.LINK: {
            if (a.link.is_empty ()) {
                return "";
            } else {
                return a.link;
            }
        }
        case DataRole.ACCOUNT:
            return a.acc_name;
        case DataRole.POINT_IN_TIME:
            //return a.id == -1 ? "" : string ("%1 - %2").arg (Utility.time_ago_in_words (a.date_time.to_local_time ()), a.date_time.to_local_time ().to_string (Qt.Default_locale_short_date));
            return a.id == -1 ? "" : Utility.time_ago_in_words (a.date_time.to_local_time ());
        case DataRole.ACCOUNT_CONNECTED:
            return (ast && ast.is_connected ());
        case DataRole.DISPLAY_ACTIONS:
            return this.display_actions;
        case DataRole.SHAREABLE:
            return !data (index, DataRole.PATH).to_string ().is_empty () && this.display_actions && a.file_action != "file_deleted" && a.status != SyncFileItem.Status.FILE_IGNORED;
        default:
            return GLib.Variant ();
        }
        return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public void trigger_default_action (int activity_index) {
        if (activity_index < 0 || activity_index >= this.final_list.size ()) {
            GLib.warning ("Couldn't trigger default action at index " + activity_index + "/ final list size: " + this.final_list.size ());
            return;
        }

        const var model_index = index (activity_index);
        const var path = data (model_index, DataRole.PATH).to_url ();

        const var activity = this.final_list.at (activity_index);
        if (activity.status == SyncFileItem.Status.CONFLICT) {
            //  Q_ASSERT (!activity.file.is_empty ());
            //  Q_ASSERT (!activity.folder.is_empty ());
            //  Q_ASSERT (Utility.is_conflict_file (activity.file));

            const var folder = FolderMan.instance ().folder_by_alias (activity.folder);

            const var conflicted_relative_path = activity.file;
            const var base_relative_path = folder.journal_database ().conflict_file_base_name (conflicted_relative_path.to_utf8 ());

            const var directory = QDir (folder.path ());
            const var conflicted_path = directory.file_path (conflicted_relative_path);
            const var base_path = directory.file_path (base_relative_path);

            const var base_name = GLib.FileInfo (base_path).filename ();

            if (!this.current_conflict_dialog.is_null ()) {
                this.current_conflict_dialog.close ();
            }
            this.current_conflict_dialog = new ConflictDialog ();
            this.current_conflict_dialog.on_signal_base_filename (base_name);
            this.current_conflict_dialog.on_signal_local_version_filename (conflicted_path);
            this.current_conflict_dialog.on_signal_remote_version_filename (base_path);
            this.current_conflict_dialog.attribute (Qt.WA_DeleteOnClose);
            connect (
                this.current_conflict_dialog,
                ConflictDialog.accepted,
                folder,
                this.on_signal_current_conflict_dialog_accepted
            );
            this.current_conflict_dialog.open ();
            OwncloudGui.raise_dialog (this.current_conflict_dialog);
            return;
        } else if (activity.status == SyncFileItem.Status.FILENAME_INVALID) {
            if (!this.current_invalid_filename_dialog.is_null ()) {
                this.current_invalid_filename_dialog.close ();
            }

            var folder = FolderMan.instance ().folder_by_alias (activity.folder);
            const var folder_dir = QDir (folder.path ());
            this.current_invalid_filename_dialog = new InvalidFilenameDialog (this.account_state.account (), folder,
                folder_dir.file_path (activity.file));
            connect (
                this.current_invalid_filename_dialog,
                InvalidFilenameDialog.accepted,
                folder,
                this.on_signal_current_invalid_filename_dialog_accepted
            );
            this.current_invalid_filename_dialog.open ();
            OwncloudGui.raise_dialog (this.current_invalid_filename_dialog);
            return;
        }

        if (path.is_valid ()) {
            QDesktopServices.open_url (path);
        } else {
            const var link = data (model_index, DataRole.LINK).to_url ();
            Utility.open_browser (link);
        }
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_current_conflict_dialog_accepted (Folder folder) {
        folder.schedule_this_folder_soon ();
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_current_invalid_filename_dialog_accepted (Folder folder) {
        folder.schedule_this_folder_soon ();
    }


    /***********************************************************
    ***********************************************************/
    public void trigger_action (int activity_index, int action_index) {
        if (activity_index < 0 || activity_index >= this.final_list.size ()) {
            GLib.warning ("Couldn't trigger action on activity at index " + activity_index + "/ final list size: " + this.final_list.size ());
            return;
        }

        const var activity = this.final_list[activity_index];

        if (action_index < 0 || action_index >= activity.links.size ()) {
            GLib.warning ("Couldn't trigger action at index " + action_index + "/ actions list size: " + activity.links.size ());
            return;
        }

        const var action = activity.links[action_index];

        if (action.verb == "WEB") {
            Utility.open_browser (GLib.Uri (action.link));
            return;
        }

        /* emit */ send_notification_request (activity.acc_name, action.link, action.verb, activity_index);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_refresh_activity () {
        this.activity_lists.clear ();
        this.done_fetching = false;
        this.current_item = 0;
        this.total_activities_fetched = 0;
        this.show_more_activities_available_entry = false;

        if (can_fetch_activities ()) {
            start_fetch_job ();
        } else {
            this.done_fetching = true;
            combine_activity_lists ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remove_account () {
        this.final_list.clear ();
        this.activity_lists.clear ();
        this.currently_fetching = false;
        this.done_fetching = false;
        this.current_item = 0;
        this.total_activities_fetched = 0;
        this.show_more_activities_available_entry = false;
    }


    /***********************************************************
    ***********************************************************/
    protected void activities_received (QJsonDocument json, int status_code) {
        var activities = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        ActivityList list;
        var ast = this.account_state;
        if (!ast) {
            return;
        }

        if (activities.size () == 0) {
            this.done_fetching = true;
        }

        this.currently_fetching = false;

        GLib.DateTime oldest_date = GLib.DateTime.current_date_time ();
        oldest_date = oldest_date.add_days (this.max_activities_days * -1);

        foreach (var activ in activities) {
            var json = activ.to_object ();

            Activity a;
            a.type = Activity.Type.ACTIVITY;
            a.object_type = json.value ("object_type").to_string ();
            a.acc_name = ast.account ().display_name ();
            a.id = json.value ("activity_id").to_int ();
            a.file_action = json.value ("type").to_string ();
            a.subject = json.value ("subject").to_string ();
            a.message = json.value ("message").to_string ();
            a.file = json.value ("object_name").to_string ();
            a.link = GLib.Uri (json.value ("link").to_string ());
            a.date_time = GLib.DateTime.from_string (json.value ("datetime").to_string (), Qt.ISODate);
            a.icon = json.value ("icon").to_string ();

            list.append (a);
            this.current_item = list.last ().id;

            this.total_activities_fetched++;
            if (this.total_activities_fetched == this.max_activities
                || (this.hide_old_activities && a.date_time < oldest_date)) {
                this.show_more_activities_available_entry = true;
                this.done_fetching = true;
                break;
            }
        }

        this.activity_lists.append (list);

        /* emit */ activity_job_status_code (status_code);

        combine_activity_lists ();
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.HashMap<int, GLib.ByteArray> role_names () {
        GLib.HashMap<int, GLib.ByteArray> roles;
        roles[DataRole.DISPLAY_PATH] = "display_path";
        roles[DataRole.PATH] = "path";
        roles[DataRole.ABSOLUTE_PATH] = "absolute_path";
        roles[DataRole.LINK] = "link";
        roles[DataRole.MESSAGE] = "message";
        roles[DataRole.ACTION] = "type";
        roles[DataRole.ACTION_ICON] = "icon";
        roles[DataRole.ACTION_TEXT] = "subject";
        roles[DataRole.ACTION_LINKS] = "links";
        roles[DataRole.ACTION_TEXT_COLOR] = "activity_text_title_color";
        roles[DataRole.OBJECT_TYPE] = "object_type";
        roles[DataRole.POINT_IN_TIME] = "date_time";
        roles[DataRole.DISPLAY_ACTIONS] = "display_actions";
        roles[DataRole.SHAREABLE] = "is_shareable";
        return roles;
    }


    /***********************************************************
    ***********************************************************/
    protected void start_fetch_job () {
        if (!this.account_state.is_connected ()) {
            return;
        }
        var job = new JsonApiJob (this.account_state.account (), QLatin1String ("ocs/v2.php/apps/activity/api/v2/activity"), this);
        connect (job, JsonApiJob.json_received,
            this, ActivityListModel.activities_received);

        QUrlQuery parameters;
        parameters.add_query_item (QLatin1String ("since"), string.number (this.current_item));
        parameters.add_query_item (QLatin1String ("limit"), string.number (50));
        job.add_query_params (parameters);

        this.currently_fetching = true;
        GLib.info ("Start fetching activities for " + this.account_state.account ().display_name ());
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void combine_activity_lists () {
        ActivityList result_list;

        if (this.notification_errors_lists.count () > 0) {
            std.sort (this.notification_errors_lists.begin (), this.notification_errors_lists.end ());
            result_list.append (this.notification_errors_lists);
        }
        if (this.list_of_ignored_files.size () > 0)
            result_list.append (this.notification_ignored_files);

        if (this.notification_lists.count () > 0) {
            std.sort (this.notification_lists.begin (), this.notification_lists.end ());
            result_list.append (this.notification_lists);
        }

        if (this.sync_file_item_lists.count () > 0) {
            std.sort (this.sync_file_item_lists.begin (), this.sync_file_item_lists.end ());
            result_list.append (this.sync_file_item_lists);
        }

        if (this.activity_lists.count () > 0) {
            std.sort (this.activity_lists.begin (), this.activity_lists.end ());
            result_list.append (this.activity_lists);

            if (this.show_more_activities_available_entry) {
                Activity a;
                a.type = Activity.Type.ACTIVITY;
                a.acc_name = this.account_state.account ().display_name ();
                a.id = -1;
                a.subject = _("For more activities please open the Activity app.");
                a.date_time = GLib.DateTime.current_date_time ();

                AccountApp app = this.account_state.find_app (QLatin1String ("activity"));
                if (app) {
                    a.link = app.url ();
                }

                result_list.append (a);
            }
        }

        begin_reset_model ();
        this.final_list.clear ();
        end_reset_model ();

        if (result_list.count () > 0) {
            begin_insert_rows (QModelIndex (), 0, result_list.count () - 1);
            this.final_list = result_list;
            end_insert_rows ();
        }
    }

    private bool can_fetch_activities () {
        return this.account_state.is_connected () && this.account_state.account ().capabilities ().has_activities ();
    }

} // class ActivityListModel

} // namespace Ui
} // namespace Occ
