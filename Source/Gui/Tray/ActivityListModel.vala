/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>
// #include <QAbstractListModel>
// #include <QDesktopServices>
// #include <Gtk.Widget>
// #include <QJsonObject>
// #include <QJsonDocument>
// #include <qloggingcategory.h>

// #include <QtCore>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_activity)


/***********************************************************
@brief The ActivityListModel
@ingroup gui

Simple list model to provide the list view with data.
***********************************************************/

class ActivityListModel : QAbstractListModel {

    Q_PROPERTY (AccountState account_state READ account_state CONSTANT)

    /***********************************************************
    ***********************************************************/
    public enum Data_role {
        Action_icon_role = Qt.User_role + 1,
        User_icon_role,
        Account_role,
        Object_type_role,
        Actions_links_role,
        Action_text_role,
        Action_text_color_role,
        Action_role,
        Message_role,
        Display_path_role,
        Path_role,
        Absolute_path_role,
        Link_role,
        Point_in_time_role,
        Account_connected_role,
        Sync_file_status_role,
        Display_actions,
        Shareable_role,
    };

    /***********************************************************
    ***********************************************************/
    public ActivityListModel (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public ActivityListModel (AccountState account_state,

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex &parent = QModelIndex ()) override;

    /***********************************************************
    ***********************************************************/
    public bool can_fetch_more (QModelIndex &) override;
    public void fetch_more (QModelIndex &) override;

    public Activity_list activity_list () {
        return _final_list;
    }


    /***********************************************************
    ***********************************************************/
    public Activity_list errors_list () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public void add_notification_to_activity_list (Activity activity);


    /***********************************************************
    ***********************************************************/
    public void clear_notifications ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void add_ignored_file_to_list (Activity new_activity);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void remove_activity_from_activity_list (int row);

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
    public Q_INVOKABLE void trigger_action (int activity_index, int action_index);

    public AccountState account_state ();


    public void on_refresh_activity ();


    public void on_remove_account ();

signals:
    void activity_job_status_code (int status_code);
    void send_notification_request (string account_name, string link, GLib.ByteArray verb, int row);


    protected void activities_received (QJsonDocument &json, int status_code);
    protected QHash<int, GLib.ByteArray> role_names () override;

    protected void set_account_state (AccountState state);
    protected void set_currently_fetching (bool value);
    protected bool currently_fetching ();
    protected void set_done_fetching (bool value);
    protected void set_hide_old_activities (bool value);
    protected void set_display_actions (bool value);

    protected virtual void start_fetch_job ();

    /***********************************************************
    ***********************************************************/
    private void combine_activity_lists ();

    /***********************************************************
    ***********************************************************/
    private 
    private Activity_list _activity_lists;
    private Activity_list _sync_file_item_lists;
    private Activity_list _notification_lists;
    private Activity_list _list_of_ignored_files;
    private Activity _notification_ignored_files;
    private Activity_list _notification_errors_lists;
    private Activity_list _final_list;
    private int _current_item = 0;

    /***********************************************************
    ***********************************************************/
    private bool _display_actions = true;

    /***********************************************************
    ***********************************************************/
    private int _total_activities_fetched = 0;
    private int _max_activities = 100;
    private int _max_activities_days = 30;
    private bool _show_more_activities_available_entry = false;

    /***********************************************************
    ***********************************************************/
    private QPointer<ConflictDialog> _current_conflict_dialog;

    /***********************************************************
    ***********************************************************/
    private 
    private AccountState _account_state = nullptr;
    private bool _currently_fetching = false;
    private bool _done_fetching = false;
    private bool _hide_old_activities = true;
};

    ActivityListModel.ActivityListModel (GLib.Object parent)
        : QAbstractListModel (parent) {
    }

    ActivityListModel.ActivityListModel (AccountState account_state,
        GLib.Object parent)
        : QAbstractListModel (parent)
        , _account_state (account_state) {
    }

    QHash<int, GLib.ByteArray> ActivityListModel.role_names () {
        QHash<int, GLib.ByteArray> roles;
        roles[Display_path_role] = "display_path";
        roles[Path_role] = "path";
        roles[Absolute_path_role] = "absolute_path";
        roles[Link_role] = "link";
        roles[Message_role] = "message";
        roles[Action_role] = "type";
        roles[Action_icon_role] = "icon";
        roles[Action_text_role] = "subject";
        roles[Actions_links_role] = "links";
        roles[Action_text_color_role] = "activity_text_title_color";
        roles[Object_type_role] = "object_type";
        roles[Point_in_time_role] = "date_time";
        roles[Display_actions] = "display_actions";
        roles[Shareable_role] = "is_shareable";
        return roles;
    }

    void ActivityListModel.set_account_state (AccountState state) {
        _account_state = state;
    }

    void ActivityListModel.set_currently_fetching (bool value) {
        _currently_fetching = value;
    }

    bool ActivityListModel.currently_fetching () {
        return _currently_fetching;
    }

    void ActivityListModel.set_done_fetching (bool value) {
        _done_fetching = value;
    }

    void ActivityListModel.set_hide_old_activities (bool value) {
        _hide_old_activities = value;
    }

    void ActivityListModel.set_display_actions (bool value) {
        _display_actions = value;
    }

    QVariant ActivityListModel.data (QModelIndex &index, int role) {
        Activity a;

        if (!index.is_valid ())
            return QVariant ();

        a = _final_list.at (index.row ());
        AccountStatePtr ast = AccountManager.instance ().account (a._acc_name);
        if (!ast && _account_state != ast.data ())
            return QVariant ();

        switch (role) {
        case Display_path_role:
            if (!a._file.is_empty ()) {
                var folder = FolderMan.instance ().folder (a._folder);
                string rel_path (a._file);
                if (folder) {
                    rel_path.prepend (folder.remote_path ());
                }
                const var local_files = FolderMan.instance ().find_file_in_local_folders (rel_path, ast.account ());
                if (local_files.count () > 0) {
                    if (rel_path.starts_with ('/') || rel_path.starts_with ('\\')) {
                        return rel_path.remove (0, 1);
                    } else {
                        return rel_path;
                    }
                }
            }
            return "";
        case Path_role:
            if (!a._file.is_empty ()) {
                const var folder = FolderMan.instance ().folder (a._folder);

                string rel_path (a._file);
                if (folder) {
                    rel_path.prepend (folder.remote_path ());
                }

                // get relative path to the file so we can open it in the file manager
                const var local_files = FolderMan.instance ().find_file_in_local_folders (QFileInfo (rel_path).path (), ast.account ());

                if (local_files.is_empty ()) {
                    return "";
                }

                // If this is an E2EE file or folder, pretend we got no path, this leads to
                // hiding the share button which is what we want
                if (folder) {
                    SyncJournalFileRecord record;
                    folder.journal_database ().get_file_record (a._file.mid (1), &record);
                    if (record.is_valid () && (record._is_e2e_encrypted || !record._e2e_mangled_name.is_empty ())) {
                        return "";
                    }
                }

                return GLib.Uri.from_local_file (local_files.const_first ());
            }
            return "";
        case Absolute_path_role: {
            const var folder = FolderMan.instance ().folder (a._folder);
            string rel_path (a._file);
            if (!a._file.is_empty ()) {
                if (folder) {
                    rel_path.prepend (folder.remote_path ());
                }
                const var local_files = FolderMan.instance ().find_file_in_local_folders (rel_path, ast.account ());
                if (!local_files.empty ()) {
                    return local_files.const_first ();
                } else {
                    q_warning ("File not local folders while processing absolute path request.");
                    return "";
                }
            } else {
                q_warning ("Received an absolute path request for an activity without a file path.");
                return "";
            }
        }
        case Actions_links_role: {
            GLib.List<QVariant> custom_list;
            foreach (Activity_link activity_link, a._links) {
                custom_list << QVariant.from_value (activity_link);
            }
            return custom_list;
        }
        case Action_icon_role: {
            if (a._type == Activity.Notification_type) {
                return "qrc:///client/theme/black/bell.svg";
            } else if (a._type == Activity.Sync_result_type) {
                return "qrc:///client/theme/black/state-error.svg";
            } else if (a._type == Activity.Sync_file_item_type) {
                if (a._status == SyncFileItem.NormalError
                    || a._status == SyncFileItem.FatalError
                    || a._status == SyncFileItem.DetailError
                    || a._status == SyncFileItem.BlocklistedError) {
                    return "qrc:///client/theme/black/state-error.svg";
                } else if (a._status == SyncFileItem.SoftError
                    || a._status == SyncFileItem.Conflict
                    || a._status == SyncFileItem.Restoration
                    || a._status == SyncFileItem.FileLocked
                    || a._status == SyncFileItem.FileNameInvalid) {
                    return "qrc:///client/theme/black/state-warning.svg";
                } else if (a._status == SyncFileItem.FileIgnored) {
                    return "qrc:///client/theme/black/state-info.svg";
                } else {
                    // File sync successful
                    if (a._file_action == "file_created") {
                        return "qrc:///client/theme/colored/add.svg";
                    } else if (a._file_action == "file_deleted") {
                        return "qrc:///client/theme/colored/delete.svg";
                    } else {
                        return "qrc:///client/theme/change.svg";
                    }
                }
            } else {
                // We have an activity
                if (a._icon.is_empty ()) {
                    return "qrc:///client/theme/black/activity.svg";
                }

                return a._icon;
            }
        }
        case Object_type_role:
            return a._object_type;
        case Action_role: {
            switch (a._type) {
            case Activity.Activity_type:
                return "Activity";
            case Activity.Notification_type:
                return "Notification";
            case Activity.Sync_file_item_type:
                return "File";
            case Activity.Sync_result_type:
                return "Sync";
            default:
                return QVariant ();
            }
        }
        case Action_text_role:
            return a._subject;
        case Action_text_color_role:
            return a._id == -1 ? QLatin1String ("#808080") : QLatin1String ("#222");   // FIXME : This is a temporary workaround for _show_more_activities_available_entry
        case Message_role:
            return a._message;
        case Link_role: {
            if (a._link.is_empty ()) {
                return "";
            } else {
                return a._link;
            }
        }
        case Account_role:
            return a._acc_name;
        case Point_in_time_role:
            //return a._id == -1 ? "" : string ("%1 - %2").arg (Utility.time_ago_in_words (a._date_time.to_local_time ()), a._date_time.to_local_time ().to_string (Qt.Default_locale_short_date));
            return a._id == -1 ? "" : Utility.time_ago_in_words (a._date_time.to_local_time ());
        case Account_connected_role:
            return (ast && ast.is_connected ());
        case Display_actions:
            return _display_actions;
        case Shareable_role:
            return !data (index, Path_role).to_"".is_empty () && _display_actions && a._file_action != "file_deleted" && a._status != SyncFileItem.FileIgnored;
        default:
            return QVariant ();
        }
        return QVariant ();
    }

    int ActivityListModel.row_count (QModelIndex &) {
        return _final_list.count ();
    }

    bool ActivityListModel.can_fetch_more (QModelIndex &) {
        // We need to be connected to be able to fetch more
        if (_account_state && _account_state.is_connected ()) {
            // If the fetching is reported to be done or we are currently fetching we can't fetch more
            if (!_done_fetching && !_currently_fetching) {
                return true;
            }
        }

        return false;
    }

    void ActivityListModel.start_fetch_job () {
        if (!_account_state.is_connected ()) {
            return;
        }
        var job = new JsonApiJob (_account_state.account (), QLatin1String ("ocs/v2.php/apps/activity/api/v2/activity"), this);
        GLib.Object.connect (job, &JsonApiJob.json_received,
            this, &ActivityListModel.activities_received);

        QUrlQuery parameters;
        parameters.add_query_item (QLatin1String ("since"), string.number (_current_item));
        parameters.add_query_item (QLatin1String ("limit"), string.number (50));
        job.add_query_params (parameters);

        _currently_fetching = true;
        q_c_info (lc_activity) << "Start fetching activities for " << _account_state.account ().display_name ();
        job.on_start ();
    }

    void ActivityListModel.activities_received (QJsonDocument &json, int status_code) {
        var activities = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        Activity_list list;
        var ast = _account_state;
        if (!ast) {
            return;
        }

        if (activities.size () == 0) {
            _done_fetching = true;
        }

        _currently_fetching = false;

        QDateTime oldest_date = QDateTime.current_date_time ();
        oldest_date = oldest_date.add_days (_max_activities_days * -1);

        foreach (var activ, activities) {
            var json = activ.to_object ();

            Activity a;
            a._type = Activity.Activity_type;
            a._object_type = json.value ("object_type").to_"";
            a._acc_name = ast.account ().display_name ();
            a._id = json.value ("activity_id").to_int ();
            a._file_action = json.value ("type").to_"";
            a._subject = json.value ("subject").to_"";
            a._message = json.value ("message").to_"";
            a._file = json.value ("object_name").to_"";
            a._link = GLib.Uri (json.value ("link").to_"");
            a._date_time = QDateTime.from_string (json.value ("datetime").to_"", Qt.ISODate);
            a._icon = json.value ("icon").to_"";

            list.append (a);
            _current_item = list.last ()._id;

            _total_activities_fetched++;
            if (_total_activities_fetched == _max_activities
                || (_hide_old_activities && a._date_time < oldest_date)) {
                _show_more_activities_available_entry = true;
                _done_fetching = true;
                break;
            }
        }

        _activity_lists.append (list);

        emit activity_job_status_code (status_code);

        combine_activity_lists ();
    }

    void ActivityListModel.add_error_to_activity_list (Activity activity) {
        q_c_info (lc_activity) << "Error successfully added to the notification list : " << activity._subject;
        _notification_errors_lists.prepend (activity);
        combine_activity_lists ();
    }

    void ActivityListModel.add_ignored_file_to_list (Activity new_activity) {
        q_c_info (lc_activity) << "First checking for duplicates then add file to the notification list of ignored files : " << new_activity._file;

        bool duplicate = false;
        if (_list_of_ignored_files.size () == 0) {
            _notification_ignored_files = new_activity;
            _notification_ignored_files._subject = _("Files from the ignore list as well as symbolic links are not synced.");
            _list_of_ignored_files.append (new_activity);
            return;
        }

        foreach (Activity activity, _list_of_ignored_files) {
            if (activity._file == new_activity._file) {
                duplicate = true;
                break;
            }
        }

        if (!duplicate) {
            _notification_ignored_files._message.append (", " + new_activity._file);
        }
    }

    void ActivityListModel.add_notification_to_activity_list (Activity activity) {
        q_c_info (lc_activity) << "Notification successfully added to the notification list : " << activity._subject;
        _notification_lists.prepend (activity);
        combine_activity_lists ();
    }

    void ActivityListModel.clear_notifications () {
        q_c_info (lc_activity) << "Clear the notifications";
        _notification_lists.clear ();
        combine_activity_lists ();
    }

    void ActivityListModel.remove_activity_from_activity_list (int row) {
        Activity activity = _final_list.at (row);
        remove_activity_from_activity_list (activity);
        combine_activity_lists ();
    }

    void ActivityListModel.add_sync_file_item_to_activity_list (Activity activity) {
        q_c_info (lc_activity) << "Successfully added to the activity list : " << activity._subject;
        _sync_file_item_lists.prepend (activity);
        combine_activity_lists ();
    }

    void ActivityListModel.remove_activity_from_activity_list (Activity activity) {
        q_c_info (lc_activity) << "Activity/Notification/Error successfully dismissed : " << activity._subject;
        q_c_info (lc_activity) << "Trying to remove Activity/Notification/Error from view... ";

        int index = -1;
        if (activity._type == Activity.Activity_type) {
            index = _activity_lists.index_of (activity);
            if (index != -1)
                _activity_lists.remove_at (index);
        } else if (activity._type == Activity.Notification_type) {
            index = _notification_lists.index_of (activity);
            if (index != -1)
                _notification_lists.remove_at (index);
        } else {
            index = _notification_errors_lists.index_of (activity);
            if (index != -1)
                _notification_errors_lists.remove_at (index);
        }

        if (index != -1) {
            q_c_info (lc_activity) << "Activity/Notification/Error successfully removed from the list.";
            q_c_info (lc_activity) << "Updating Activity/Notification/Error view.";
            combine_activity_lists ();
        }
    }

    void ActivityListModel.trigger_default_action (int activity_index) {
        if (activity_index < 0 || activity_index >= _final_list.size ()) {
            GLib.warn (lc_activity) << "Couldn't trigger default action at index" << activity_index << "/ final list size:" << _final_list.size ();
            return;
        }

        const var model_index = index (activity_index);
        const var path = data (model_index, Path_role).to_url ();

        const var activity = _final_list.at (activity_index);
        if (activity._status == SyncFileItem.Conflict) {
            Q_ASSERT (!activity._file.is_empty ());
            Q_ASSERT (!activity._folder.is_empty ());
            Q_ASSERT (Utility.is_conflict_file (activity._file));

            const var folder = FolderMan.instance ().folder (activity._folder);

            const var conflicted_relative_path = activity._file;
            const var base_relative_path = folder.journal_database ().conflict_file_base_name (conflicted_relative_path.to_utf8 ());

            const var dir = QDir (folder.path ());
            const var conflicted_path = dir.file_path (conflicted_relative_path);
            const var base_path = dir.file_path (base_relative_path);

            const var base_name = QFileInfo (base_path).file_name ();

            if (!_current_conflict_dialog.is_null ()) {
                _current_conflict_dialog.close ();
            }
            _current_conflict_dialog = new ConflictDialog;
            _current_conflict_dialog.on_set_base_filename (base_name);
            _current_conflict_dialog.on_set_local_version_filename (conflicted_path);
            _current_conflict_dialog.on_set_remote_version_filename (base_path);
            _current_conflict_dialog.set_attribute (Qt.WA_DeleteOnClose);
            connect (_current_conflict_dialog, &ConflictDialog.accepted, folder, [folder] () {
                folder.schedule_this_folder_soon ();
            });
            _current_conflict_dialog.open ();
            OwncloudGui.raise_dialog (_current_conflict_dialog);
            return;
        } else if (activity._status == SyncFileItem.FileNameInvalid) {
            if (!_current_invalid_filename_dialog.is_null ()) {
                _current_invalid_filename_dialog.close ();
            }

            var folder = FolderMan.instance ().folder (activity._folder);
            const var folder_dir = QDir (folder.path ());
            _current_invalid_filename_dialog = new Invalid_filename_dialog (_account_state.account (), folder,
                folder_dir.file_path (activity._file));
            connect (_current_invalid_filename_dialog, &Invalid_filename_dialog.accepted, folder, [folder] () {
                folder.schedule_this_folder_soon ();
            });
            _current_invalid_filename_dialog.open ();
            OwncloudGui.raise_dialog (_current_invalid_filename_dialog);
            return;
        }

        if (path.is_valid ()) {
            QDesktopServices.open_url (path);
        } else {
            const var link = data (model_index, Link_role).to_url ();
            Utility.open_browser (link);
        }
    }

    void ActivityListModel.trigger_action (int activity_index, int action_index) {
        if (activity_index < 0 || activity_index >= _final_list.size ()) {
            GLib.warn (lc_activity) << "Couldn't trigger action on activity at index" << activity_index << "/ final list size:" << _final_list.size ();
            return;
        }

        const var activity = _final_list[activity_index];

        if (action_index < 0 || action_index >= activity._links.size ()) {
            GLib.warn (lc_activity) << "Couldn't trigger action at index" << action_index << "/ actions list size:" << activity._links.size ();
            return;
        }

        const var action = activity._links[action_index];

        if (action._verb == "WEB") {
            Utility.open_browser (GLib.Uri (action._link));
            return;
        }

        emit send_notification_request (activity._acc_name, action._link, action._verb, activity_index);
    }

    AccountState *ActivityListModel.account_state () {
        return _account_state;
    }

    void ActivityListModel.combine_activity_lists () {
        Activity_list result_list;

        if (_notification_errors_lists.count () > 0) {
            std.sort (_notification_errors_lists.begin (), _notification_errors_lists.end ());
            result_list.append (_notification_errors_lists);
        }
        if (_list_of_ignored_files.size () > 0)
            result_list.append (_notification_ignored_files);

        if (_notification_lists.count () > 0) {
            std.sort (_notification_lists.begin (), _notification_lists.end ());
            result_list.append (_notification_lists);
        }

        if (_sync_file_item_lists.count () > 0) {
            std.sort (_sync_file_item_lists.begin (), _sync_file_item_lists.end ());
            result_list.append (_sync_file_item_lists);
        }

        if (_activity_lists.count () > 0) {
            std.sort (_activity_lists.begin (), _activity_lists.end ());
            result_list.append (_activity_lists);

            if (_show_more_activities_available_entry) {
                Activity a;
                a._type = Activity.Activity_type;
                a._acc_name = _account_state.account ().display_name ();
                a._id = -1;
                a._subject = _("For more activities please open the Activity app.");
                a._date_time = QDateTime.current_date_time ();

                AccountApp app = _account_state.find_app (QLatin1String ("activity"));
                if (app) {
                    a._link = app.url ();
                }

                result_list.append (a);
            }
        }

        begin_reset_model ();
        _final_list.clear ();
        end_reset_model ();

        if (result_list.count () > 0) {
            begin_insert_rows (QModelIndex (), 0, result_list.count () - 1);
            _final_list = result_list;
            end_insert_rows ();
        }
    }

    bool ActivityListModel.can_fetch_activities () {
        return _account_state.is_connected () && _account_state.account ().capabilities ().has_activities ();
    }

    void ActivityListModel.fetch_more (QModelIndex &) {
        if (can_fetch_activities ()) {
            start_fetch_job ();
        } else {
            _done_fetching = true;
            combine_activity_lists ();
        }
    }

    void ActivityListModel.on_refresh_activity () {
        _activity_lists.clear ();
        _done_fetching = false;
        _current_item = 0;
        _total_activities_fetched = 0;
        _show_more_activities_available_entry = false;

        if (can_fetch_activities ()) {
            start_fetch_job ();
        } else {
            _done_fetching = true;
            combine_activity_lists ();
        }
    }

    void ActivityListModel.on_remove_account () {
        _final_list.clear ();
        _activity_lists.clear ();
        _currently_fetching = false;
        _done_fetching = false;
        _current_item = 0;
        _total_activities_fetched = 0;
        _show_more_activities_available_entry = false;
    }
    }
    