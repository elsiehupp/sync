/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QAbstractItemModel>
//  #include <QLoggingCategory>
//  #include <QElapsedTimer>
//  #include <QPointer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderStatusModel class
@ingroup gui
***********************************************************/
class FolderStatusModel : QAbstractItemModel {

    /***********************************************************
    ***********************************************************/
    public struct SubFolderInfo {

        struct Progress {

            string progress_string;
            string overall_sync_string;
            int warning_count = 0;
            int overall_percent = 0;

            bool is_null ()
            {
                return this.progress_string.is_empty () && this.warning_count == 0 && this.overall_sync_string.is_empty ();
            }
        }

        Progress progress;

        Folder folder = null;

        /***********************************************************
        Folder name to be displayed in the UI
        ***********************************************************/
        string name;


        /***********************************************************
        Sub-folder path that should always point to a local
        filesystem's folder
        ***********************************************************/
        string path;


        /***********************************************************
        Mangled name that needs to be used when making fetch
        requests and should not be used for displaying in the UI
        ***********************************************************/
        string e2e_mangled_name;


        /***********************************************************
        ***********************************************************/
        GLib.Vector<int> path_index;


        /***********************************************************
        ***********************************************************/
        GLib.Vector<SubFolderInfo> subs;


        /***********************************************************
        ***********************************************************/
        int64 size = 0;


        /***********************************************************
        ***********************************************************/
        bool is_external = false;


        /***********************************************************
        ***********************************************************/
        bool is_encrypted = false;


        /***********************************************************
        If we did the LSCOL for this folder already
        ***********************************************************/
        bool fetched = false;


        /***********************************************************
        Currently running LsColJob
        ***********************************************************/
        QPointer<LsColJob> fetching_job;


        /***********************************************************
        If the last fetching job ended in an error
        ***********************************************************/
        bool has_error = false;


        /***********************************************************
        ***********************************************************/
        string last_error_string;


        /***********************************************************
        Whether a 'fetching in progress' label is shown.
        ***********************************************************/
        bool fetching_label = false;


        /***********************************************************
        Undecided folders are the big folders that the user has not
        accepted yet
        ***********************************************************/
        bool is_undecided = false;


        /***********************************************************
        The file identifier for this folder on the server
        ***********************************************************/
        GLib.ByteArray file_id;


        /***********************************************************
        ***********************************************************/
        Qt.Check_state checked = Qt.Checked;


        /***********************************************************
        Whether this has a ItemType.FETCH_LABEL subrow
        ***********************************************************/
        bool has_label () {
            return this.has_error || this.fetching_label;
        }


        /***********************************************************
        Reset all subfolders and fetch status
        ***********************************************************/
        void reset_subs (FolderStatusModel model, QModelIndex index) {
            this.fetched = false;
            if (this.fetching_job) {
                disconnect (this.fetching_job, null, model, null);
                this.fetching_job.delete_later ();
                this.fetching_job.clear ();
            }
            if (has_label ()) {
                model.begin_remove_rows (index, 0, 0);
                this.fetching_label = false;
                this.has_error = false;
                model.end_remove_rows ();
            } else if (!this.subs.is_empty ()) {
                model.begin_remove_rows (index, 0, this.subs.count () - 1);
                this.subs.clear ();
                model.end_remove_rows ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public enum {
        FILE_ID_ROLE = Qt.USER_ROLE + 1
    }


    /***********************************************************
    ***********************************************************/
    public enum ItemType {
        ROOT_FOLDER,
        SUBFOLDER,
        ADD_BUTTON,
        FETCH_LABEL
    }


    const string PROPERTY_PARENT_INDEX_C = "oc_parent_index";
    const string PROPERTY_PERMISSION_MAP = "oc_permission_map";
    const string PROPERTY_ENCRYPTION_MAP = "nc_encryption_map";


    /***********************************************************
    ***********************************************************/
    public GLib.Vector<SubFolderInfo> folders;


    /***********************************************************
    ***********************************************************/
    private AccountState account_state = null;


    /***********************************************************
    If the selective sync checkboxes were changed
    ***********************************************************/
    private bool dirty = false;


    /***********************************************************
    Keeps track of items that are fetching data from the server.

    See on_signal_show_pending_fetch_progress ()
    ***********************************************************/
    private GLib.HashMap<QPersistent_model_index, QElapsedTimer> fetching_items;


    signal void dirty_changed ();


    /***********************************************************
    Tell the view that this item should be expanded because it
    has an undecided item
    ***********************************************************/
    signal void suggest_expand (QModelIndex &);

    friend struct SubFolderInfo;


    /***********************************************************
    ***********************************************************/
    public FolderStatusModel (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }



    ~FolderStatusModel () = default;


    /***********************************************************
    ***********************************************************/
    public void account_state (AccountState account_state) {
        begin_reset_model ();
        this.dirty = false;
        this.folders.clear ();
        this.account_state = account_state;

        connect (FolderMan.instance (), &FolderMan.folder_sync_state_change,
            this, &FolderStatusModel.on_signal_folder_sync_state_change, Qt.UniqueConnection);
        connect (FolderMan.instance (), &FolderMan.schedule_queue_changed,
            this, &FolderStatusModel.on_signal_folder_schedule_queue_changed, Qt.UniqueConnection);

        var folders = FolderMan.instance ().map ();
        foreach (var f, folders) {
            if (!account_state)
                break;
            if (f.account_state () != account_state)
                continue;
            SubFolderInfo info;
            info.name = f.alias ();
            info.path = "/";
            info.folder = f;
            info.checked = Qt.Partially_checked;
            this.folders + info;

            connect (f, &Folder.progress_info, this, &FolderStatusModel.on_signal_progress, Qt.UniqueConnection);
            connect (f, &Folder.new_big_folder_discovered, this, &FolderStatusModel.on_signal_new_big_folder, Qt.UniqueConnection);
        }

        // Sort by header text
        std.sort (this.folders.begin (), this.folders.end (), sort_by_folder_header);

        // Set the root this.path_index after the sorting
        for (int i = 0; i < this.folders.size (); ++i) {
            this.folders[i].path_index + i;
        }

        end_reset_model ();
        /* emit */ dirty_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public Qt.ItemFlags flags (QModelIndex index) {
        if (!this.account_state) {
            return {};
        }

        const var info = info_for_index (index);
        const var supports_selective_sync = info && info.folder && info.folder.supports_selective_sync ();

        switch (classify (index)) {
        case ItemType.ADD_BUTTON: {
            Qt.ItemFlags ret;
            ret = Qt.ItemNeverHasChildren;
            if (!this.account_state.is_connected ()) {
                return ret;
            }
            return Qt.ItemIsEnabled | ret;
        }
        case ItemType.FETCH_LABEL:
            return Qt.ItemIsEnabled | Qt.ItemNeverHasChildren;
        case ItemType.ROOT_FOLDER:
            return Qt.ItemIsEnabled;
        case ItemType.SUBFOLDER:
            if (supports_selective_sync) {
                return Qt.ItemIsEnabled | Qt.ItemIsUserCheckable | Qt.ItemIsSelectable;
            } else {
                return Qt.ItemIsEnabled | Qt.ItemIsSelectable;
            }
        }
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) {
        if (!index.is_valid ())
            return GLib.Variant ();

        if (role == Qt.EditRole)
            return GLib.Variant ();

        switch (classify (index)) {
        case ItemType.ADD_BUTTON: {
            if (role == DataRole.ADD_BUTTON) {
                return GLib.Variant (true);
            } else if (role == Qt.ToolTipRole) {
                if (!this.account_state.is_connected ()) {
                    return _("You need to be connected to add a folder");
                }
                return _("Click this button to add a folder to synchronize.");
            }
            return GLib.Variant ();
        }
        case ItemType.SUBFOLDER: {
            const var x = static_cast<SubFolderInfo> (index.internal_pointer ()).subs.at (index.row ());
            const var supports_selective_sync = x.folder && x.folder.supports_selective_sync ();

            switch (role) {
            case Qt.Display_role:
                // : Example text : "File.txt (23KB)"
                return x.size < 0 ? x.name : _("%1 (%2)").arg (x.name, Utility.octets_to_string (x.size));
            case Qt.ToolTipRole:
                return string ("<qt>" + Utility.escape (x.size < 0 ? x.name : _("%1 (%2)").arg (x.name, Utility.octets_to_string (x.size))) + QLatin1String ("</qt>"));
            case Qt.CheckStateRole:
                if (supports_selective_sync) {
                    return x.checked;
                } else {
                    return GLib.Variant ();
                }
            case Qt.Decoration_role: {
                if (x.is_encrypted) {
                    return new Gtk.Icon (":/client/theme/lock-https.svg");
                } else if (x.size > 0 && is_any_ancestor_encrypted (index)) {
                    return new Gtk.Icon (":/client/theme/lock-broken.svg");
                }
                return QFile_icon_provider ().icon (x.is_external ? QFile_icon_provider.Network : QFile_icon_provider.Folder);
            }
            case Qt.Foreground_role:
                if (x.is_undecided) {
                    return Gtk.Color (Qt.red);
                }
                break;
            case FILE_ID_ROLE:
                return x.file_id;
            case DataRole.FOLDER_PATH_ROLE: {
                var f = x.folder;
                if (!f)
                    return GLib.Variant ();
                return GLib.Variant (f.path () + x.path);
            }
            }
        }
            return GLib.Variant ();
        case ItemType.FETCH_LABEL: {
            const var x = static_cast<SubFolderInfo> (index.internal_pointer ());
            switch (role) {
            case Qt.Display_role:
                if (x.has_error) {
                    return GLib.Variant (_("Error while loading the list of folders from the server.")
                        + string ("\n") + x.last_error_string);
                } else {
                    return _("Fetching folder list from server …");
                }
                break;
            default:
                return GLib.Variant ();
            }
        }
        case ItemType.ROOT_FOLDER:
            break;
        }

        const SubFolderInfo folder_info = this.folders.at (index.row ());
        var f = folder_info.folder;
        if (!f)
            return GLib.Variant ();

        const SubFolderInfo.Progress progress = folder_info.progress;
        const bool account_connected = this.account_state.is_connected ();

        switch (role) {
        case DataRole.FOLDER_PATH_ROLE:
            return f.short_gui_local_path ();
        case DataRole.FOLDER_SECOND_PATH_ROLE:
            return f.remote_path ();
        case DataRole.FOLDER_CONFLICT_MESSAGE:
            return (f.sync_result ().has_unresolved_conflicts ())
                ? string[] (_("There are unresolved conflicts. Click for details."))
                : string[] ();
        case DataRole.FOLDER_ERROR_MESSAGE:
            return f.sync_result ().error_strings ();
        case DataRole.FOLDER_INFO_MESSAGE:
            return f.virtual_files_enabled () && f.vfs ().mode () != Vfs.Mode.WindowsCfApi
                ? string[] (_("Virtual file support is enabled."))
                : string[] ();
        case DataRole.SYNC_RUNNING:
            return f.sync_result ().status () == SyncResult.Status.SYNC_RUNNING;
        case DataRole.SYNC_DATE:
            return f.sync_result ().sync_time ();
        case DataRole.HEADER_ROLE:
            return f.short_gui_remote_path_or_app_name ();
        case DataRole.FOLDER_ALIAS_ROLE:
            return f.alias ();
        case DataRole.FOLDER_SYNC_PAUSED:
            return f.sync_paused ();
        case DataRole.FOLDER_ACCOUNT_CONNECTED:
            return account_connected;
        case Qt.ToolTipRole: {
            string tool_tip;
            if (!progress.is_null ()) {
                return progress.progress_string;
            }
            if (account_connected)
                tool_tip = Theme.instance ().status_header_text (f.sync_result ().status ());
            else
                tool_tip = _("Signed out");
            tool_tip += "\n";
            tool_tip += folder_info.folder.path ();
            return tool_tip;
        }
        case DataRole.FOLDER_STATUS_ICON_ROLE:
            if (account_connected) {
                var theme = Theme.instance ();
                var status = f.sync_result ().status ();
                if (f.sync_paused ()) {
                    return theme.folder_disabled_icon ();
                } else {
                    if (status == SyncResult.Status.SYNC_PREPARE || status == SyncResult.Status.UNDEFINED) {
                        return theme.sync_state_icon (SyncResult.Status.SYNC_RUNNING);
                    } else {
                        // The "Problem" *result* just means some files weren't
                        // synced, so we show "Success" in these cases. But we
                        // do use the "Problem" *icon* for unresolved conflicts.
                        if (status == SyncResult.Status.SUCCESS || status == SyncResult.Status.PROBLEM) {
                            if (f.sync_result ().has_unresolved_conflicts ()) {
                                return theme.sync_state_icon (SyncResult.Status.PROBLEM);
                            } else {
                                return theme.sync_state_icon (SyncResult.Status.SUCCESS);
                            }
                        } else {
                            return theme.sync_state_icon (status);
                        }
                    }
                }
            } else {
                return Theme.instance ().folder_offline_icon ();
            }
        case DataRole.SYNC_PROGRESS_ITEM_STRING:
            return progress.progress_string;
        case DataRole.WARNING_COUNT:
            return progress.warning_count;
        case DataRole.SYNC_PROGRESS_OVERALL_PERCENT:
            return progress.overall_percent;
        case DataRole.SYNC_PROGRESS_OVERALL_STRING:
            return progress.overall_sync_string;
        case DataRole.FOLDER_SYNC_TEXT:
            if (f.virtual_files_enabled ()) {
                return _("Synchronizing Virtual_files with local folder");
            } else {
                return _("Synchronizing with local folder");
            }
        }
        return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public bool data (QModelIndex index, GLib.Variant value, int role = Qt.EditRole) {
        if (role == Qt.CheckStateRole) {
            var info = info_for_index (index);
            //  Q_ASSERT (info.folder && info.folder.supports_selective_sync ());
            var checked = static_cast<Qt.Check_state> (value.to_int ());

            if (info && info.checked != checked) {
                info.checked = checked;
                if (checked == Qt.Checked) {
                    // If we are checked, check that we may need to check the parent as well if
                    // all the siblings are also checked
                    QModelIndex parent = index.parent ();
                    var parent_info = info_for_index (parent);
                    if (parent_info && parent_info.checked != Qt.Checked) {
                        bool has_unchecked = false;
                        foreach (var sub, parent_info.subs) {
                            if (sub.checked != Qt.Checked) {
                                has_unchecked = true;
                                break;
                            }
                        }
                        if (!has_unchecked) {
                            data (parent, Qt.Checked, Qt.CheckStateRole);
                        } else if (parent_info.checked == Qt.Unchecked) {
                            data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                        }
                    }
                    // also check all the children
                    for (int i = 0; i < info.subs.count (); ++i) {
                        if (info.subs.at (i).checked != Qt.Checked) {
                            data (this.index (i, 0, index), Qt.Checked, Qt.CheckStateRole);
                        }
                    }
                }

                if (checked == Qt.Unchecked) {
                    QModelIndex parent = index.parent ();
                    var parent_info = info_for_index (parent);
                    if (parent_info && parent_info.checked == Qt.Checked) {
                        data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                    }

                    // Uncheck all the children
                    for (int i = 0; i < info.subs.count (); ++i) {
                        if (info.subs.at (i).checked != Qt.Unchecked) {
                            data (this.index (i, 0, index), Qt.Unchecked, Qt.CheckStateRole);
                        }
                    }
                }

                if (checked == Qt.Partially_checked) {
                    QModelIndex parent = index.parent ();
                    var parent_info = info_for_index (parent);
                    if (parent_info && parent_info.checked != Qt.Partially_checked) {
                        data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                    }
                }
            }
            this.dirty = true;
            /* emit */ dirty_changed ();
            /* emit */ data_changed (index, index, GLib.Vector<int> () + role);
            return true;
        }
        return QAbstractItemModel.data (index, value, role);
    }


    /***********************************************************
    ***********************************************************/
    public int column_count (QModelIndex parent = QModelIndex ()) {
        return 1;
    }


    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex parent = QModelIndex ()) {
        if (!parent.is_valid ()) {
            if (Theme.instance ().single_sync_folder () && this.folders.count () != 0) {
                // "Add folder" button not visible in the single_sync_folder configuration.
                return this.folders.count ();
            }
            return this.folders.count () + 1; // +1 for the "add folder" button
        }
        var info = info_for_index (parent);
        if (!info)
            return 0;
        if (info.has_label ())
            return 1;
        return info.subs.count ();
    }


    /***********************************************************
    ***********************************************************/
    public QModelIndex index (int row, int column = 0, QModelIndex parent = QModelIndex ()) {
        if (!parent.is_valid ()) {
            return create_index (row, column /*, null*/);
        }
        switch (classify (parent)) {
        case ItemType.ADD_BUTTON:
        case ItemType.FETCH_LABEL:
            return {};
        case ItemType.ROOT_FOLDER:
            if (this.folders.count () <= parent.row ())
                return {}; // should not happen
            return create_index (row, column, const_cast<SubFolderInfo> (&this.folders[parent.row ()]));
        case ItemType.SUBFOLDER: {
            var pinfo = static_cast<SubFolderInfo> (parent.internal_pointer ());
            if (pinfo.subs.count () <= parent.row ())
                return {}; // should not happen
            var info = pinfo.subs[parent.row ()];
            if (!info.has_label ()
                && info.subs.count () <= row)
                return {}; // should not happen
            return create_index (row, column, info);
        }
        }
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public QModelIndex parent (QModelIndex child) {
        if (!child.is_valid ()) {
            return {};
        }
        switch (classify (child)) {
        case ItemType.ROOT_FOLDER:
        case ItemType.ADD_BUTTON:
            return {};
        case ItemType.SUBFOLDER:
        case ItemType.FETCH_LABEL:
            break;
        }
        var path_index = static_cast<SubFolderInfo> (child.internal_pointer ()).path_index;
        int i = 1;
        //  ASSERT (path_index.at (0) < this.folders.count ());
        if (path_index.count () == 1) {
            return create_index (path_index.at (0), 0 /*, null*/);
        }

        const SubFolderInfo info = this.folders[path_index.at (0)];
        while (i < path_index.count () - 1) {
            //  ASSERT (path_index.at (i) < info.subs.count ());
            info = info.subs.at (path_index.at (i));
            ++i;
        }
        return create_index (path_index.at (i), 0, const_cast<SubFolderInfo> (info));
    }


    /***********************************************************
    ***********************************************************/
    public bool can_fetch_more (QModelIndex parent) {
        if (!this.account_state) {
            return false;
        }
        if (this.account_state.state () != AccountState.State.CONNECTED) {
            return false;
        }
        var info = info_for_index (parent);
        if (!info || info.fetched || info.fetching_job)
            return false;
        if (info.has_error) {
            // Keep showing the error to the user, it will be hidden when the account reconnects
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_more (QModelIndex parent) {
        var info = info_for_index (parent);

        if (!info || info.fetched || info.fetching_job)
            return;
        info.reset_subs (this, parent);
        string path = info.folder.remote_path_trailing_slash ();

        // info.path always contains non-mangled name, so we need to use mangled when requesting nested folders for encrypted subfolders as required by LsColJob
        const string info_path = (info.is_encrypted && !info.e2e_mangled_name.is_empty ()) ? info.e2e_mangled_name : info.path;

        if (info_path != QLatin1String ("/")) {
            path += info_path;
        }

        var job = new LsColJob (this.account_state.account (), path, this);
        info.fetching_job = job;
        var props = GLib.List<GLib.ByteArray> ("resourcetype"
                                        + "http://owncloud.org/ns:size"
                                        + "http://owncloud.org/ns:permissions"
                                        + "http://owncloud.org/ns:fileid";
        if (this.account_state.account ().capabilities ().client_side_encryption_available ()) {
            props + "http://nextcloud.org/ns:is-encrypted";
        }
        job.properties (props);

        job.on_signal_timeout (60 * 1000);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &FolderStatusModel.on_signal_update_directories);
        connect (job, &LsColJob.finished_with_error,
            this, &FolderStatusModel.on_signal_lscol_finished_with_error);
        connect (job, &LsColJob.directory_listing_iterated,
            this, &FolderStatusModel.on_signal_gather_permissions);
        connect (job, &LsColJob.directory_listing_iterated,
                this, &FolderStatusModel.on_signal_gather_encryption_status);

        job.on_signal_start ();

        QPersistent_model_index persistent_index (parent);
        job.property (PROPERTY_PARENT_INDEX_C, GLib.Variant.from_value (persistent_index));

        // Show 'fetching data...' hint after a while.
        this.fetching_items[persistent_index].on_signal_start ();
        QTimer.single_shot (1000, this, &FolderStatusModel.on_signal_show_fetch_progress);
    }


    /***********************************************************
    ***********************************************************/
    public void reset_and_fetch (QModelIndex parent) {
        var info = info_for_index (parent);
        info.reset_subs (this, parent);
        fetch_more (parent);
    }


    /***********************************************************
    ***********************************************************/
    public bool has_children (QModelIndex parent = QModelIndex ()) {
        if (!parent.is_valid ())
            return true;

        var info = info_for_index (parent);
        if (!info)
            return false;

        if (!info.fetched)
            return true;

        if (info.subs.is_empty ())
            return false;

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public ItemType classify (QModelIndex index) {
        if (var sub = static_cast<SubFolderInfo> (index.internal_pointer ())) {
            if (sub.has_label ()) {
                return ItemType.FETCH_LABEL;
            } else {
                return ItemType.SUBFOLDER;
            }
        }
        if (index.row () < this.folders.count ()) {
            return ItemType.ROOT_FOLDER;
        }
        return ItemType.ADD_BUTTON;
    }


    /***********************************************************
    ***********************************************************/
    public SubFolderInfo info_for_index (QModelIndex index) {
        if (!index.is_valid ())
            return null;
        if (var parent_info = static_cast<SubFolderInfo> (index.internal_pointer ())) {
            if (parent_info.has_label ()) {
                return null;
            }
            if (index.row () >= parent_info.subs.size ()) {
                return null;
            }
            return parent_info.subs[index.row ()];
        } else {
            if (index.row () >= this.folders.count ()) {
                // ItemType.ADD_BUTTON
                return null;
            }
            return const_cast<SubFolderInfo> (&this.folders[index.row ()]);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_any_ancestor_encrypted (QModelIndex index) {
        var parent_index = parent (index);
        while (parent_index.is_valid ()) {
            const var info = info_for_index (parent_index);
            if (info.is_encrypted) {
                return true;
            }
            parent_index = parent (parent_index);
        }

        return false;
    }


    /***********************************************************
    If the selective sync check boxes were changed
    ***********************************************************/
    public bool is_dirty () {
        return this.dirty;
    }


    /***********************************************************
    Return a QModelIndex for the given path within the given
    folder. Note: this method returns an invalid index if the
    path was not fetched from the server before
    ***********************************************************/
    public QModelIndex index_for_path (Folder f, string path) {
        if (!f) {
            return {};
        }

        int slash_pos = path.last_index_of ('/');
        if (slash_pos == -1) {
            // first level folder
            for (int i = 0; i < this.folders.size (); ++i) {
                var info = this.folders.at (i);
                if (info.folder == f) {
                    if (path.is_empty ()) { // the folder object
                        return index (i, 0);
                    }
                    for (int j = 0; j < info.subs.size (); ++j) {
                        const string sub_name = info.subs.at (j).name;
                        if (sub_name == path) {
                            return index (j, 0, index (i));
                        }
                    }
                    return {};
                }
            }
            return {};
        }

        var parent = index_for_path (f, path.left (slash_pos));
        if (!parent.is_valid ())
            return parent;

        if (slash_pos == path.size () - 1) {
            // The slash is the last part, we found our index
            return parent;
        }

        var parent_info = info_for_index (parent);
        if (!parent_info) {
            return {};
        }
        for (int i = 0; i < parent_info.subs.size (); ++i) {
            if (parent_info.subs.at (i).name == path.mid (slash_pos + 1)) {
                return index (i, 0, parent);
            }
        }

        return {};
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_folder_state (Folder folder) {
        if (!folder)
            return;
        for (int i = 0; i < this.folders.count (); ++i) {
            if (this.folders.at (i).folder == folder) {
                /* emit */ data_changed (index (i), index (i));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_apply_selective_sync () {
        for (var folder_info : q_as_const (this.folders)) {
            if (!folder_info.fetched) {
                folder_info.folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, string[] ());
                continue;
            }
            const var folder = folder_info.folder;

            bool ok = false;
            var old_block_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
            if (!ok) {
                GLib.warn ("Could not read selective sync list from database.";
                continue;
            }
            string[] block_list = create_block_list (folder_info, old_block_list);
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);

            var block_list_set = block_list.to_set ();
            var old_block_list_set = old_block_list.to_set ();

            // The folders that were undecided or blocklisted and that are now checked should go on the allow list.
            // The user confirmed them already just now.
            string[] to_add_to_allow_list = ( (old_block_list_set + folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok).to_set ()) - block_list_set).values ();

            if (!to_add_to_allow_list.is_empty ()) {
                var allow_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok);
                if (ok) {
                    allow_list += to_add_to_allow_list;
                    folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, allow_list);
                }
            }
            // clear the undecided list
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, string[] ());

            // do the sync if there were changes
            var changes = (old_block_list_set - block_list_set) + (block_list_set - old_block_list_set);
            if (!changes.is_empty ()) {
                if (folder.is_busy ()) {
                    folder.on_signal_terminate_sync ();
                }
                //The part that changed should not be read from the DB on next sync because there might be new folders
                // (the ones that are no longer in the blocklist)
                foreach (var it, changes) {
                    folder.journal_database ().schedule_path_for_remote_discovery (it);
                    folder.on_signal_schedule_path_for_local_discovery (it);
                }
                FolderMan.instance ().schedule_folder (folder);
            }
        }

        on_signal_reset_folders ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_reset_folders () {
        account_state (this.account_state);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_all_pending_big_folders () {
        for (int i = 0; i < this.folders.count (); ++i) {
            if (!this.folders[i].fetched) {
                this.folders[i].folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, string[] ());
                continue;
            }
            var folder = this.folders.at (i).folder;

            bool ok = false;
            var undecided_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok);
            if (!ok) {
                GLib.warn ("Could not read selective sync list from database.";
                return;
            }

            // If this folder had no undecided entries, skip it.
            if (undecided_list.is_empty ()) {
                continue;
            }

            // Remove all undecided folders from the blocklist
            var block_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
            if (!ok) {
                GLib.warn ("Could not read selective sync list from database.";
                return;
            }
            foreach (var undecided_folder, undecided_list) {
                block_list.remove_all (undecided_folder);
            }
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);

            // Add all undecided folders to the allow list
            var allow_list = folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok);
            if (!ok) {
                GLib.warn ("Could not read selective sync list from database.";
                return;
            }
            allow_list += undecided_list;
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, allow_list);

            // Clear the undecided list
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, string[] ());

            // Trigger a sync
            if (folder.is_busy ()) {
                folder.on_signal_terminate_sync ();
            }
            // The part that changed should not be read from the DB on next sync because there might be new folders
            // (the ones that are no longer in the blocklist)
            foreach (var it, undecided_list) {
                folder.journal_database ().schedule_path_for_remote_discovery (it);
                folder.on_signal_schedule_path_for_local_discovery (it);
            }
            FolderMan.instance ().schedule_folder (folder);
        }

        on_signal_reset_folders ();
    }



    /***********************************************************
    ***********************************************************/
    public void on_signal_sync_no_pending_big_folders () {
        for (int i = 0; i < this.folders.count (); ++i) {
            var folder = this.folders.at (i).folder;

            // clear the undecided list
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, string[] ());
        }

        on_signal_reset_folders ();
    }



    /***********************************************************
    ***********************************************************/
    public void on_signal_progress (ProgressInfo progress) {
        var par = qobject_cast<Gtk.Widget> (GLib.Object.parent ());
        if (!par.is_visible ()) {
            return; // for https://github.com/owncloud/client/issues/2648#issuecomment-71377909
        }

        var f = qobject_cast<Folder> (sender ());
        if (!f) {
            return;
        }

        int folder_index = -1;
        for (int i = 0; i < this.folders.count (); ++i) {
            if (this.folders.at (i).folder == f) {
                folder_index = i;
                break;
            }
        }
        if (folder_index < 0) {
            return;
        }

        var pi = this.folders[folder_index].progress;

        GLib.Vector<int> roles;
        roles + DataRole.SYNC_PROGRESS_ITEM_STRING
            + DataRole.WARNING_COUNT
            + Qt.ToolTipRole;

        if (progress.status () == ProgressInfo.Status.DISCOVERY) {
            if (!progress.current_discovered_remote_folder.is_empty ()) {
                pi.overall_sync_string = _("Checking for changes in remote \"%1\"").arg (progress.current_discovered_remote_folder);
                /* emit */ data_changed (index (folder_index), index (folder_index), roles);
                return;
            } else if (!progress.current_discovered_local_folder.is_empty ()) {
                pi.overall_sync_string = _("Checking for changes in local \"%1\"").arg (progress.current_discovered_local_folder);
                /* emit */ data_changed (index (folder_index), index (folder_index), roles);
                return;
            }
        }

        if (progress.status () == ProgressInfo.Status.RECONCILE) {
            pi.overall_sync_string = _("Reconciling changes");
            /* emit */ data_changed (index (folder_index), index (folder_index), roles);
            return;
        }

        // Status is Starting, Propagation or Done

        if (!progress.last_completed_item.is_empty ()
            && Progress.is_warning_kind (progress.last_completed_item.status)) {
            pi.warning_count++;
        }

        // find the single item to display :  This is going to be the bigger item, or the last completed
        // item if no items are in progress.
        SyncFileItem cur_item = progress.last_completed_item;
        int64 cur_item_progress = -1; // -1 means on_signal_finished
        int64 bigger_item_size = 0;
        uint64 estimated_up_bw = 0;
        uint64 estimated_down_bw = 0;
        string all_filenames;
        foreach (ProgressInfo.ProgressItem citm, progress.current_items) {
            if (cur_item_progress == -1 || (ProgressInfo.is_size_dependent (citm.item)
                                            && bigger_item_size < citm.item.size)) {
                cur_item_progress = citm.progress.completed ();
                cur_item = citm.item;
                bigger_item_size = citm.item.size;
            }
            if (citm.item.direction != SyncFileItem.Direction.UP) {
                estimated_down_bw += progress.file_progress (citm.item).estimated_bandwidth;
            } else {
                estimated_up_bw += progress.file_progress (citm.item).estimated_bandwidth;
            }
            var filename = QFileInfo (citm.item.file).filename ();
            if (all_filenames.length () > 0) {
                // : Build a list of file names
                all_filenames.append (QStringLiteral (", \"%1\"").arg (filename));
            } else {
                // : Argument is a file name
                all_filenames.append (QStringLiteral ("\"%1\"").arg (filename));
            }
        }
        if (cur_item_progress == -1) {
            cur_item_progress = cur_item.size;
        }

        string item_filename = cur_item.file;
        string kind_string = Progress.as_action_string (cur_item);

        string file_progress_string;
        if (ProgressInfo.is_size_dependent (cur_item)) {
            string s1 = Utility.octets_to_string (cur_item_progress);
            string s2 = Utility.octets_to_string (cur_item.size);
            //uint64 estimated_bw = progress.file_progress (cur_item).estimated_bandwidth;
            if (estimated_up_bw || estimated_down_bw) {
                /***********************************************************
                // : Example text : "uploading foobar.png (1MB of 2MB) time left 2 minutes at a rate of 24Kb/s"
                file_progress_string = _("%1 %2 (%3 of %4) %5 left at a rate of %6/s")
                    .arg (kind_string, item_filename, s1, s2,
                        Utility.duration_to_descriptive_string (progress.file_progress (cur_item).estimated_eta),
                        Utility.octets_to_string (estimated_bw) );
                */
                // : Example text : "Syncing 'foo.txt', 'bar.txt'"
                file_progress_string = _("Syncing %1").arg (all_filenames);
                if (estimated_down_bw > 0) {
                    file_progress_string.append (_(", "));
                    // ifdefs : https://github.com/owncloud/client/issues/3095#issuecomment-128409294
                    file_progress_string.append (_("\u2193 %1/s")
                                                .arg (Utility.octets_to_string (estimated_down_bw)));
                }
                if (estimated_up_bw > 0) {
                    file_progress_string.append (_(", "));
                    file_progress_string.append (_("\u2191 %1/s")
                                                .arg (Utility.octets_to_string (estimated_up_bw)));
                }
            } else {
                // : Example text : "uploading foobar.png (2MB of 2MB)"
                file_progress_string = _("%1 %2 (%3 of %4)").arg (kind_string, item_filename, s1, s2);
            }
        } else if (!kind_string.is_empty ()) {
            // : Example text : "uploading foobar.png"
            file_progress_string = _("%1 %2").arg (kind_string, item_filename);
        }
        pi.progress_string = file_progress_string;

        // overall progress
        int64 completed_size = progress.completed_size ();
        int64 completed_file = progress.completed_files ();
        int64 current_file = progress.current_file ();
        int64 total_size = q_max (completed_size, progress.total_size ());
        int64 total_file_count = q_max (current_file, progress.total_files ());
        string overall_sync_string;
        if (total_size > 0) {
            string s1 = Utility.octets_to_string (completed_size);
            string s2 = Utility.octets_to_string (total_size);

            if (progress.trust_eta ()) {
                // : Example text : "5 minutes left, 12 MB of 345 MB, file 6 of 7"
                overall_sync_string = _("%5 left, %1 of %2, file %3 of %4")
                                        .arg (s1, s2)
                                        .arg (current_file)
                                        .arg (total_file_count)
                                        .arg (Utility.duration_to_descriptive_string1 (progress.total_progress ().estimated_eta));

            } else {
                // : Example text : "12 MB of 345 MB, file 6 of 7"
                overall_sync_string = _("%1 of %2, file %3 of %4")
                                        .arg (s1, s2)
                                        .arg (current_file)
                                        .arg (total_file_count);
            }
        } else if (total_file_count > 0) {
            // Don't attempt to estimate the time left if there is no kb to transfer.
            overall_sync_string = _("file %1 of %2").arg (current_file).arg (total_file_count);
        }

        pi.overall_sync_string = overall_sync_string;

        int overall_percent = 0;
        if (total_file_count > 0) {
            // Add one 'byte' for each file so the percentage is moving when deleting or renaming files
            overall_percent = q_round (double (completed_size + completed_file) / double (total_size + total_file_count) * 100.0);
        }
        pi.overall_percent = q_bound (0, overall_percent, 100);
        /* emit */ data_changed (index (folder_index), index (folder_index), roles);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_directories (string[] list) {
        var job = qobject_cast<LsColJob> (sender ());
        //  ASSERT (job);
        QModelIndex index = qvariant_cast<QPersistent_model_index> (job.property (PROPERTY_PARENT_INDEX_C));
        var parent_info = info_for_index (index);
        if (!parent_info) {
            return;
        }
        //  ASSERT (parent_info.fetching_job == job);
        //  ASSERT (parent_info.subs.is_empty ());

        if (parent_info.has_label ()) {
            begin_remove_rows (index, 0, 0);
            parent_info.has_error = false;
            parent_info.fetching_label = false;
            end_remove_rows ();
        }

        parent_info.last_error_string.clear ();
        parent_info.fetching_job = null;
        parent_info.fetched = true;

        GLib.Uri url = parent_info.folder.remote_url ();
        string path_to_remove = url.path ();
        if (!path_to_remove.ends_with ('/'))
            path_to_remove += '/';

        string[] selective_sync_block_list;
        bool ok1 = true;
        bool ok2 = true;
        if (parent_info.checked == Qt.Partially_checked) {
            selective_sync_block_list = parent_info.folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok1);
        }
        var selective_sync_undecided_list = parent_info.folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok2);

        if (! (ok1 && ok2)) {
            GLib.warn ("Could not retrieve selective sync info from journal";
            return;
        }

        GLib.Set<string> selective_sync_undecided_set; // not GLib.Set because it's not sorted
        foreach (string string_value, selective_sync_undecided_list) {
            if (string_value.starts_with (parent_info.path) || parent_info.path == QLatin1String ("/")) {
                selective_sync_undecided_set.insert (string_value);
            }
        }
        const var permission_map = job.property (PROPERTY_PERMISSION_MAP).to_map ();
        const var encryption_map = job.property (PROPERTY_ENCRYPTION_MAP).to_map ();

        string[] sorted_subfolders = list;
        if (!sorted_subfolders.is_empty ())
            sorted_subfolders.remove_first (); // skip the parent item (first in the list)
        Utility.sort_filenames (sorted_subfolders);

        QVarLengthArray<int, 10> undecided_indexes;

        GLib.Vector<SubFolderInfo> new_subs;
        new_subs.reserve (sorted_subfolders.size ());
        foreach (string path, sorted_subfolders) {
            var relative_path = path.mid (path_to_remove.size ());
            if (parent_info.folder.is_file_excluded_relative (relative_path)) {
                continue;
            }

            SubFolderInfo new_info;
            new_info.folder = parent_info.folder;
            new_info.path_index = parent_info.path_index;
            new_info.path_index + new_subs.size ();
            new_info.is_external = permission_map.value (remove_trailing_slash (path)).to_string ().contains ("M");
            new_info.is_encrypted = encryption_map.value (remove_trailing_slash (path)).to_string () == QStringLiteral ("1");
            new_info.path = relative_path;

            SyncJournalFileRecord record;
            parent_info.folder.journal_database ().get_file_record_by_e2e_mangled_name (remove_trailing_slash (relative_path), record);
            if (record.is_valid ()) {
                new_info.name = remove_trailing_slash (record.path).split ('/').last ();
                if (record.is_e2e_encrypted && !record.e2e_mangled_name.is_empty ()) {
                    // we must use local path for Settings Dialog's filesystem tree, otherwise open and create new folder actions won't work
                    // hence, we are storing this.e2e_mangled_name separately so it can be use later for LsColJob
                    new_info.e2e_mangled_name = relative_path;
                    new_info.path = record.path;
                }
                if (!new_info.path.ends_with ('/')) {
                    new_info.path += '/';
                }
            } else {
                new_info.name = remove_trailing_slash (relative_path).split ('/').last ();
            }

            const var& folder_info = job.folder_infos.value (path);
            new_info.size = folder_info.size;
            new_info.file_id = folder_info.file_id;
            if (relative_path.is_empty ())
                continue;

            if (parent_info.checked == Qt.Unchecked) {
                new_info.checked = Qt.Unchecked;
            } else if (parent_info.checked == Qt.Checked) {
                new_info.checked = Qt.Checked;
            } else {
                foreach (string string_value, selective_sync_block_list) {
                    if (string_value == relative_path || string_value == QLatin1String ("/")) {
                        new_info.checked = Qt.Unchecked;
                        break;
                    } else if (string_value.starts_with (relative_path)) {
                        new_info.checked = Qt.Partially_checked;
                    }
                }
            }

            var it = selective_sync_undecided_set.lower_bound (relative_path);
            if (it != selective_sync_undecided_set.end ()) {
                if (*it == relative_path) {
                    new_info.is_undecided = true;
                    selective_sync_undecided_set.erase (it);
                } else if ( (*it).starts_with (relative_path)) {
                    undecided_indexes.append (new_info.path_index.last ());

                    // Remove all the items from the selective_sync_undecided_set that starts with this path
                    string relative_path_next = relative_path;
                    relative_path_next[relative_path_next.length () - 1].unicode ()++;
                    var it2 = selective_sync_undecided_set.lower_bound (relative_path_next);
                    selective_sync_undecided_set.erase (it, it2);
                }
            }
            new_subs.append (new_info);
        }

        if (!new_subs.is_empty ()) {
            begin_insert_rows (index, 0, new_subs.size () - 1);
            parent_info.subs = std.move (new_subs);
            end_insert_rows ();
        }

        for (int undecided_index : q_as_const (undecided_indexes)) {
            suggest_expand (index (undecided_index, 0, index));
        }
        /* Try to remove the the undecided lists the items that are not on the server. */
        var it = std.remove_if (selective_sync_undecided_list.begin (), selective_sync_undecided_list.end (),
            [&] (string s) {
                return selective_sync_undecided_set.count (s);
            });
        if (it != selective_sync_undecided_list.end ()) {
            selective_sync_undecided_list.erase (it, selective_sync_undecided_list.end ());
            parent_info.folder.journal_database ().selective_sync_list (
                SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, selective_sync_undecided_list);
            /* emit */ dirty_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_gather_permissions (string href, GLib.HashMap<string, string> map) {
        var it = map.find ("permissions");
        if (it == map.end ())
            return;

        var job = sender ();
        var permission_map = job.property (PROPERTY_PERMISSION_MAP).to_map ();
        job.property (PROPERTY_PERMISSION_MAP, GLib.Variant ()); // avoid a detach of the map while it is modified
        //  ASSERT (!href.ends_with ('/'), "LsColXMLParser.parse should remove the trailing slash before calling us.");
        permission_map[href] = *it;
        job.property (PROPERTY_PERMISSION_MAP, permission_map);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_gather_encryption_status (string href, GLib.HashMap<string, string> properties) {
        var it = properties.find ("is-encrypted");
        if (it == properties.end ())
            return;

        var job = sender ();
        var encryption_map = job.property (PROPERTY_ENCRYPTION_MAP).to_map ();
        job.property (PROPERTY_ENCRYPTION_MAP, GLib.Variant ()); // avoid a detach of the map while it is modified
        //  ASSERT (!href.ends_with ('/'), "LsColXMLParser.parse should remove the trailing slash before calling us.");
        encryption_map[href] = *it;
        job.property (PROPERTY_ENCRYPTION_MAP, encryption_map);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_finished_with_error (Soup.Reply r) {
        var job = qobject_cast<LsColJob> (sender ());
        //  ASSERT (job);
        QModelIndex index = qvariant_cast<QPersistent_model_index> (job.property (PROPERTY_PARENT_INDEX_C));
        if (!index.is_valid ()) {
            return;
        }
        var parent_info = info_for_index (index);
        if (parent_info) {
            GLib.debug () + r.error_string ();
            parent_info.last_error_string = r.error_string ();
            var error = r.error ();

            parent_info.reset_subs (this, index);

            if (error == Soup.Reply.ContentNotFoundError) {
                parent_info.fetched = true;
            } else {
                //  ASSERT (!parent_info.has_label ());
                begin_insert_rows (index, 0, 0);
                parent_info.has_error = true;
                end_insert_rows ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_state_change (Folder f) {
        if (!f) {
            return;
        }

        int folder_index = -1;
        for (int i = 0; i < this.folders.count (); ++i) {
            if (this.folders.at (i).folder == f) {
                folder_index = i;
                break;
            }
        }
        if (folder_index < 0) {
            return;
        }

        var pi = this.folders[folder_index].progress;

        SyncResult.Status state = f.sync_result ().status ();
        if (!f.can_sync () || state == SyncResult.Status.PROBLEM || state == SyncResult.Status.SUCCESS || state == SyncResult.Status.ERROR) {
            // Reset progress info.
            pi = SubFolderInfo.Progress ();
        } else if (state == SyncResult.Status.NOT_YET_STARTED) {
            FolderMan folder_man = FolderMan.instance ();
            int position = folder_man.schedule_queue ().index_of (f);
            for (var other : folder_man.map ()) {
                if (other != f && other.is_sync_running ())
                    position += 1;
            }
            string message;
            if (position <= 0) {
                message = _("Waiting …");
            } else {
                message = _("Waiting for %n other folder (s) …", "", position);
            }
            pi = SubFolderInfo.Progress ();
            pi.overall_sync_string = message;
        } else if (state == SyncResult.Status.SYNC_PREPARE) {
            pi = SubFolderInfo.Progress ();
            pi.overall_sync_string = _("Preparing to sync …");
        }

        // update the icon etc. now
        on_signal_update_folder_state (f);

        if (f.sync_result ().folder_structure_was_changed ()
            && (state == SyncResult.Status.SUCCESS || state == SyncResult.Status.PROBLEM)) {
            // There is a new or a removed folder. reset all data
            reset_and_fetch (index (folder_index));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_schedule_queue_changed () {
        // Update messages on waiting folders.
        foreach (Folder f, FolderMan.instance ().map ()) {
            on_signal_folder_sync_state_change (f);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_big_folder () {
        var f = qobject_cast<Folder> (sender ());
        //  ASSERT (f);

        int folder_index = -1;
        for (int i = 0; i < this.folders.count (); ++i) {
            if (this.folders.at (i).folder == f) {
                folder_index = i;
                break;
            }
        }
        if (folder_index < 0) {
            return;
        }

        reset_and_fetch (index (folder_index));

        /* emit */ suggest_expand (index (folder_index));
        /* emit */ dirty_changed ();
    }


    /***********************************************************
    "In progress" labels for fetching data from the server are
    only added after some time to avoid popping.
    ***********************************************************/
    private void on_signal_show_fetch_progress () {
        QMutable_map_iterator<QPersistent_model_index, QElapsedTimer> it (this.fetching_items);
        while (it.has_next ()) {
            it.next ();
            if (it.value ().elapsed () > 800) {
                var index = it.key ();
                var info = info_for_index (index);
                if (info && info.fetching_job) {
                    bool add = !info.has_label ();
                    if (add) {
                        begin_insert_rows (index, 0, 0);
                    }
                    info.fetching_label = true;
                    if (add) {
                        end_insert_rows ();
                    }
                }
                it.remove ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private string[] create_block_list (Occ.FolderStatusModel.SubFolderInfo root,
        string[] old_block_list) {
        switch (root.checked) {
        case Qt.Unchecked:
            return string[] (root.path);
        case Qt.Checked:
            return string[] ();
        case Qt.Partially_checked:
            break;
        }

        string[] result;
        if (root.fetched) {
            for (int i = 0; i < root.subs.count (); ++i) {
                result += create_block_list (root.subs.at (i), old_block_list);
            }
        } else {
            // We did not load from the server so we re-use the one from the old block list
            const string path = root.path;
            foreach (string it, old_block_list) {
                if (it.starts_with (path))
                    result += it;
            }
        }
        return result;
    }


    private static string remove_trailing_slash (string s) {
        if (s.ends_with ('/')) {
            return s.left (s.size () - 1);
        }
        return s;
    }


    private static bool sort_by_folder_header (FolderStatusModel.SubFolderInfo lhs, FolderStatusModel.SubFolderInfo rhs) {
        return string.compare (lhs.folder.short_gui_remote_path_or_app_name (),
                rhs.folder.short_gui_remote_path_or_app_name (),
                Qt.CaseInsensitive)
            < 0;
    }

} // class FolderStatusModel

} // namespace Occ
