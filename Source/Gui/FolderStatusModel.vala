/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>
// #include <account.h>

// #include <QFile_icon_provider>
// #include <QVarLengthArray>
// #include <set>


// #include <accountfwd.h>
// #include <QAbstractItemModel>
// #include <QLoggingCategory>
// #include <QVector>
// #include <QElapsedTimer>
// #include <QPointer>


namespace Occ {


/***********************************************************
@brief The FolderStatusModel class
@ingroup gui
***********************************************************/
class FolderStatusModel : QAbstractItemModel {

    public enum {File_id_role = Qt.User_role+1};

    public FolderStatusModel (GLib.Object *parent = nullptr);
    public ~FolderStatusModel () override;
    public void set_account_state (AccountState *account_state);

    public Qt.Item_flags flags (QModelIndex &) const override;
    public QVariant data (QModelIndex &index, int role) const override;
    public bool set_data (QModelIndex &index, QVariant &value, int role = Qt.Edit_role) override;
    public int column_count (QModelIndex &parent = QModelIndex ()) const override;
    public int row_count (QModelIndex &parent = QModelIndex ()) const override;
    public QModelIndex index (int row, int column = 0, QModelIndex &parent = QModelIndex ()) const override;
    public QModelIndex parent (QModelIndex &child) const override;
    public bool can_fetch_more (QModelIndex &parent) const override;
    public void fetch_more (QModelIndex &parent) override;
    public void reset_and_fetch (QModelIndex &parent);
    public bool has_children (QModelIndex &parent = QModelIndex ()) const override;

    public struct SubFolderInfo {
        Folder *_folder = nullptr;
        string _name; // Folder name to be displayed in the UI
        string _path; // Sub-folder path that should always point to a local filesystem's folder
        string _e2e_mangled_name; // Mangled name that needs to be used when making fetch requests and should not be used for displaying in the UI
        QVector<int> _path_idx;
        QVector<SubFolderInfo> _subs;
        int64 _size = 0;
        bool _is_external = false;
        bool _is_encrypted = false;

        bool _fetched = false; // If we did the LSCOL for this folder already
        QPointer<Ls_col_job> _fetching_job; // Currently running Ls_col_job
        bool _has_error = false; // If the last fetching job ended in an error
        string _last_error_string;
        bool _fetching_label = false; // Whether a 'fetching in progress' label is shown.
        // undecided folders are the big folders that the user has not accepted yet
        bool _is_undecided = false;
        QByteArray _file_id; // the file id for this folder on the server.

        Qt.Check_state _checked = Qt.Checked;

        // Whether this has a Fetch_label subrow
        bool has_label ();

        // Reset all subfolders and fetch status
        void reset_subs (FolderStatusModel *model, QModelIndex index);

        struct Progress {
            bool is_null () const
            {
                return _progress_string.is_empty () && _warning_count == 0 && _overall_sync_string.is_empty ();
            }
            string _progress_string;
            string _overall_sync_string;
            int _warning_count = 0;
            int _overall_percent = 0;
        };
        Progress _progress;
    };

    public QVector<SubFolderInfo> _folders;

    public enum ItemType {
        RootFolder,
        SubFolder,
        AddButton,
        Fetch_label
    };
    public ItemType classify (QModelIndex &index) const;
    public SubFolderInfo *info_for_index (QModelIndex &index) const;
    public bool is_any_ancestor_encrypted (QModelIndex &index) const;
    // If the selective sync check boxes were changed
    public bool is_dirty () {
        return _dirty;
    }

    /***********************************************************
    return a QModelIndex for the given path within the given folder.
    Note : this method returns an invalid index if the path was not fetched from the server before
    ***********************************************************/
    public QModelIndex index_for_path (Folder *f, string &path) const;

public slots:
    void slot_update_folder_state (Folder *);
    void slot_apply_selective_sync ();
    void reset_folders ();
    void slot_sync_all_pending_big_folders ();
    void slot_sync_no_pending_big_folders ();
    void slot_set_progress (ProgressInfo &progress);

private slots:
    void slot_update_directories (QStringList &);
    void slot_gather_permissions (string &name, QMap<string, string> &properties);
    void slot_gather_encryption_status (string &href, QMap<string, string> &properties);
    void slot_lscol_finished_with_error (QNetworkReply *r);
    void slot_folder_sync_state_change (Folder *f);
    void slot_folder_schedule_queue_changed ();
    void slot_new_big_folder ();

    /***********************************************************
    "In progress" labels for fetching data from the server are only
    added after some time to avoid popping.
    ***********************************************************/
    void slot_show_fetch_progress ();

private:
    QStringList create_black_list (Occ.FolderStatusModel.SubFolderInfo &root,
        const QStringList &old_black_list) const;
    const AccountState *_account_state = nullptr;
    bool _dirty = false; // If the selective sync checkboxes were changed

    /***********************************************************
    Keeps track of items that are fetching data from the server.

    See slot_show_pending_fetch_progress ()
    ***********************************************************/
    QMap<QPersistent_model_index, QElapsedTimer> _fetching_items;

signals:
    void dirty_changed ();

    // Tell the view that this item should be expanded because it has an undecided item
    void suggest_expand (QModelIndex &);
    friend struct SubFolderInfo;
};


static const char property_parent_index_c[] = "oc_parent_index";
static const char property_permission_map[] = "oc_permission_map";
static const char property_encryption_map[] = "nc_encryption_map";

static string remove_trailing_slash (string &s) {
    if (s.ends_with ('/')) {
        return s.left (s.size () - 1);
    }
    return s;
}

FolderStatusModel.FolderStatusModel (GLib.Object *parent)
    : QAbstractItemModel (parent) {

}

FolderStatusModel.~FolderStatusModel () = default;

static bool sort_by_folder_header (FolderStatusModel.SubFolderInfo &lhs, FolderStatusModel.SubFolderInfo &rhs) {
    return string.compare (lhs._folder.short_gui_remote_path_or_app_name (),
               rhs._folder.short_gui_remote_path_or_app_name (),
               Qt.CaseInsensitive)
        < 0;
}

void FolderStatusModel.set_account_state (AccountState *account_state) {
    begin_reset_model ();
    _dirty = false;
    _folders.clear ();
    _account_state = account_state;

    connect (FolderMan.instance (), &FolderMan.folder_sync_state_change,
        this, &FolderStatusModel.slot_folder_sync_state_change, Qt.UniqueConnection);
    connect (FolderMan.instance (), &FolderMan.schedule_queue_changed,
        this, &FolderStatusModel.slot_folder_schedule_queue_changed, Qt.UniqueConnection);

    auto folders = FolderMan.instance ().map ();
    foreach (auto f, folders) {
        if (!account_state)
            break;
        if (f.account_state () != account_state)
            continue;
        SubFolderInfo info;
        info._name = f.alias ();
        info._path = "/";
        info._folder = f;
        info._checked = Qt.Partially_checked;
        _folders << info;

        connect (f, &Folder.progress_info, this, &FolderStatusModel.slot_set_progress, Qt.UniqueConnection);
        connect (f, &Folder.new_big_folder_discovered, this, &FolderStatusModel.slot_new_big_folder, Qt.UniqueConnection);
    }

    // Sort by header text
    std.sort (_folders.begin (), _folders.end (), sort_by_folder_header);

    // Set the root _path_idx after the sorting
    for (int i = 0; i < _folders.size (); ++i) {
        _folders[i]._path_idx << i;
    }

    end_reset_model ();
    emit dirty_changed ();
}

Qt.Item_flags FolderStatusModel.flags (QModelIndex &index) {
    if (!_account_state) {
        return {};
    }

    const auto info = info_for_index (index);
    const auto supports_selective_sync = info && info._folder && info._folder.supports_selective_sync ();

    switch (classify (index)) {
    case AddButton : {
        Qt.Item_flags ret;
        ret = Qt.Item_never_has_children;
        if (!_account_state.is_connected ()) {
            return ret;
        }
        return Qt.ItemIsEnabled | ret;
    }
    case Fetch_label:
        return Qt.ItemIsEnabled | Qt.Item_never_has_children;
    case RootFolder:
        return Qt.ItemIsEnabled;
    case SubFolder:
        if (supports_selective_sync) {
            return Qt.ItemIsEnabled | Qt.Item_is_user_checkable | Qt.Item_is_selectable;
        } else {
            return Qt.ItemIsEnabled | Qt.Item_is_selectable;
        }
    }
    return {};
}

QVariant FolderStatusModel.data (QModelIndex &index, int role) {
    if (!index.is_valid ())
        return QVariant ();

    if (role == Qt.Edit_role)
        return QVariant ();

    switch (classify (index)) {
    case AddButton : {
        if (role == FolderStatusDelegate.AddButton) {
            return QVariant (true);
        } else if (role == Qt.ToolTipRole) {
            if (!_account_state.is_connected ()) {
                return tr ("You need to be connected to add a folder");
            }
            return tr ("Click this button to add a folder to synchronize.");
        }
        return QVariant ();
    }
    case SubFolder : {
        const auto &x = static_cast<SubFolderInfo> (index.internal_pointer ())._subs.at (index.row ());
        const auto supports_selective_sync = x._folder && x._folder.supports_selective_sync ();

        switch (role) {
        case Qt.Display_role:
            // : Example text : "File.txt (23KB)"
            return x._size < 0 ? x._name : tr ("%1 (%2)").arg (x._name, Utility.octets_to_string (x._size));
        case Qt.ToolTipRole:
            return string (QLatin1String ("<qt>") + Utility.escape (x._size < 0 ? x._name : tr ("%1 (%2)").arg (x._name, Utility.octets_to_string (x._size))) + QLatin1String ("</qt>"));
        case Qt.CheckStateRole:
            if (supports_selective_sync) {
                return x._checked;
            } else {
                return QVariant ();
            }
        case Qt.Decoration_role : {
            if (x._is_encrypted) {
                return QIcon (QLatin1String (":/client/theme/lock-https.svg"));
            } else if (x._size > 0 && is_any_ancestor_encrypted (index)) {
                return QIcon (QLatin1String (":/client/theme/lock-broken.svg"));
            }
            return QFile_icon_provider ().icon (x._is_external ? QFile_icon_provider.Network : QFile_icon_provider.Folder);
        }
        case Qt.Foreground_role:
            if (x._is_undecided) {
                return QColor (Qt.red);
            }
            break;
        case File_id_role:
            return x._file_id;
        case FolderStatusDelegate.FolderPathRole : {
            auto f = x._folder;
            if (!f)
                return QVariant ();
            return QVariant (f.path () + x._path);
        }
        }
    }
        return QVariant ();
    case Fetch_label : {
        const auto x = static_cast<SubFolderInfo> (index.internal_pointer ());
        switch (role) {
        case Qt.Display_role:
            if (x._has_error) {
                return QVariant (tr ("Error while loading the list of folders from the server.")
                    + string ("\n") + x._last_error_string);
            } else {
                return tr ("Fetching folder list from server …");
            }
            break;
        default:
            return QVariant ();
        }
    }
    case RootFolder:
        break;
    }

    const SubFolderInfo &folder_info = _folders.at (index.row ());
    auto f = folder_info._folder;
    if (!f)
        return QVariant ();

    const SubFolderInfo.Progress &progress = folder_info._progress;
    const bool account_connected = _account_state.is_connected ();

    switch (role) {
    case FolderStatusDelegate.FolderPathRole:
        return f.short_gui_local_path ();
    case FolderStatusDelegate.Folder_second_path_role:
        return f.remote_path ();
    case FolderStatusDelegate.Folder_conflict_msg:
        return (f.sync_result ().has_unresolved_conflicts ())
            ? QStringList (tr ("There are unresolved conflicts. Click for details."))
            : QStringList ();
    case FolderStatusDelegate.Folder_error_msg:
        return f.sync_result ().error_strings ();
    case FolderStatusDelegate.Folder_info_msg:
        return f.virtual_files_enabled () && f.vfs ().mode () != Vfs.Mode.WindowsCfApi
            ? QStringList (tr ("Virtual file support is enabled."))
            : QStringList ();
    case FolderStatusDelegate.Sync_running:
        return f.sync_result ().status () == SyncResult.Sync_running;
    case FolderStatusDelegate.Sync_date:
        return f.sync_result ().sync_time ();
    case FolderStatusDelegate.Header_role:
        return f.short_gui_remote_path_or_app_name ();
    case FolderStatusDelegate.FolderAliasRole:
        return f.alias ();
    case FolderStatusDelegate.FolderSyncPaused:
        return f.sync_paused ();
    case FolderStatusDelegate.FolderAccountConnected:
        return account_connected;
    case Qt.ToolTipRole : {
        string tool_tip;
        if (!progress.is_null ()) {
            return progress._progress_string;
        }
        if (account_connected)
            tool_tip = Theme.instance ().status_header_text (f.sync_result ().status ());
        else
            tool_tip = tr ("Signed out");
        tool_tip += "\n";
        tool_tip += folder_info._folder.path ();
        return tool_tip;
    }
    case FolderStatusDelegate.Folder_status_icon_role:
        if (account_connected) {
            auto theme = Theme.instance ();
            auto status = f.sync_result ().status ();
            if (f.sync_paused ()) {
                return theme.folder_disabled_icon ();
            } else {
                if (status == SyncResult.Sync_prepare || status == SyncResult.Undefined) {
                    return theme.sync_state_icon (SyncResult.Sync_running);
                } else {
                    // The "Problem" *result* just means some files weren't
                    // synced, so we show "Success" in these cases. But we
                    // do use the "Problem" *icon* for unresolved conflicts.
                    if (status == SyncResult.Success || status == SyncResult.Problem) {
                        if (f.sync_result ().has_unresolved_conflicts ()) {
                            return theme.sync_state_icon (SyncResult.Problem);
                        } else {
                            return theme.sync_state_icon (SyncResult.Success);
                        }
                    } else {
                        return theme.sync_state_icon (status);
                    }
                }
            }
        } else {
            return Theme.instance ().folder_offline_icon ();
        }
    case FolderStatusDelegate.Sync_progress_item_string:
        return progress._progress_string;
    case FolderStatusDelegate.Warning_count:
        return progress._warning_count;
    case FolderStatusDelegate.Sync_progress_overall_percent:
        return progress._overall_percent;
    case FolderStatusDelegate.Sync_progress_overall_string:
        return progress._overall_sync_string;
    case FolderStatusDelegate.Folder_sync_text:
        if (f.virtual_files_enabled ()) {
            return tr ("Synchronizing Virtual_files with local folder");
        } else {
            return tr ("Synchronizing with local folder");
        }
    }
    return QVariant ();
}

bool FolderStatusModel.set_data (QModelIndex &index, QVariant &value, int role) {
    if (role == Qt.CheckStateRole) {
        auto info = info_for_index (index);
        Q_ASSERT (info._folder && info._folder.supports_selective_sync ());
        auto checked = static_cast<Qt.Check_state> (value.to_int ());

        if (info && info._checked != checked) {
            info._checked = checked;
            if (checked == Qt.Checked) {
                // If we are checked, check that we may need to check the parent as well if
                // all the siblings are also checked
                QModelIndex parent = index.parent ();
                auto parent_info = info_for_index (parent);
                if (parent_info && parent_info._checked != Qt.Checked) {
                    bool has_unchecked = false;
                    foreach (auto &sub, parent_info._subs) {
                        if (sub._checked != Qt.Checked) {
                            has_unchecked = true;
                            break;
                        }
                    }
                    if (!has_unchecked) {
                        set_data (parent, Qt.Checked, Qt.CheckStateRole);
                    } else if (parent_info._checked == Qt.Unchecked) {
                        set_data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                    }
                }
                // also check all the children
                for (int i = 0; i < info._subs.count (); ++i) {
                    if (info._subs.at (i)._checked != Qt.Checked) {
                        set_data (this.index (i, 0, index), Qt.Checked, Qt.CheckStateRole);
                    }
                }
            }

            if (checked == Qt.Unchecked) {
                QModelIndex parent = index.parent ();
                auto parent_info = info_for_index (parent);
                if (parent_info && parent_info._checked == Qt.Checked) {
                    set_data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                }

                // Uncheck all the children
                for (int i = 0; i < info._subs.count (); ++i) {
                    if (info._subs.at (i)._checked != Qt.Unchecked) {
                        set_data (this.index (i, 0, index), Qt.Unchecked, Qt.CheckStateRole);
                    }
                }
            }

            if (checked == Qt.Partially_checked) {
                QModelIndex parent = index.parent ();
                auto parent_info = info_for_index (parent);
                if (parent_info && parent_info._checked != Qt.Partially_checked) {
                    set_data (parent, Qt.Partially_checked, Qt.CheckStateRole);
                }
            }
        }
        _dirty = true;
        emit dirty_changed ();
        emit data_changed (index, index, QVector<int> () << role);
        return true;
    }
    return QAbstractItemModel.set_data (index, value, role);
}

int FolderStatusModel.column_count (QModelIndex &) {
    return 1;
}

int FolderStatusModel.row_count (QModelIndex &parent) {
    if (!parent.is_valid ()) {
        if (Theme.instance ().single_sync_folder () && _folders.count () != 0) {
            // "Add folder" button not visible in the single_sync_folder configuration.
            return _folders.count ();
        }
        return _folders.count () + 1; // +1 for the "add folder" button
    }
    auto info = info_for_index (parent);
    if (!info)
        return 0;
    if (info.has_label ())
        return 1;
    return info._subs.count ();
}

FolderStatusModel.ItemType FolderStatusModel.classify (QModelIndex &index) {
    if (auto sub = static_cast<SubFolderInfo> (index.internal_pointer ())) {
        if (sub.has_label ()) {
            return Fetch_label;
        } else {
            return SubFolder;
        }
    }
    if (index.row () < _folders.count ()) {
        return RootFolder;
    }
    return AddButton;
}

FolderStatusModel.SubFolderInfo *FolderStatusModel.info_for_index (QModelIndex &index) {
    if (!index.is_valid ())
        return nullptr;
    if (auto parent_info = static_cast<SubFolderInfo> (index.internal_pointer ())) {
        if (parent_info.has_label ()) {
            return nullptr;
        }
        if (index.row () >= parent_info._subs.size ()) {
            return nullptr;
        }
        return &parent_info._subs[index.row ()];
    } else {
        if (index.row () >= _folders.count ()) {
            // AddButton
            return nullptr;
        }
        return const_cast<SubFolderInfo> (&_folders[index.row ()]);
    }
}

bool FolderStatusModel.is_any_ancestor_encrypted (QModelIndex &index) {
    auto parent_index = parent (index);
    while (parent_index.is_valid ()) {
        const auto info = info_for_index (parent_index);
        if (info._is_encrypted) {
            return true;
        }
        parent_index = parent (parent_index);
    }

    return false;
}

QModelIndex FolderStatusModel.index_for_path (Folder *f, string &path) {
    if (!f) {
        return {};
    }

    int slash_pos = path.last_index_of ('/');
    if (slash_pos == -1) {
        // first level folder
        for (int i = 0; i < _folders.size (); ++i) {
            auto &info = _folders.at (i);
            if (info._folder == f) {
                if (path.is_empty ()) { // the folder object
                    return index (i, 0);
                }
                for (int j = 0; j < info._subs.size (); ++j) {
                    const string sub_name = info._subs.at (j)._name;
                    if (sub_name == path) {
                        return index (j, 0, index (i));
                    }
                }
                return {};
            }
        }
        return {};
    }

    auto parent = index_for_path (f, path.left (slash_pos));
    if (!parent.is_valid ())
        return parent;

    if (slash_pos == path.size () - 1) {
        // The slash is the last part, we found our index
        return parent;
    }

    auto parent_info = info_for_index (parent);
    if (!parent_info) {
        return {};
    }
    for (int i = 0; i < parent_info._subs.size (); ++i) {
        if (parent_info._subs.at (i)._name == path.mid (slash_pos + 1)) {
            return index (i, 0, parent);
        }
    }

    return {};
}

QModelIndex FolderStatusModel.index (int row, int column, QModelIndex &parent) {
    if (!parent.is_valid ()) {
        return create_index (row, column /*, nullptr*/);
    }
    switch (classify (parent)) {
    case AddButton:
    case Fetch_label:
        return {};
    case RootFolder:
        if (_folders.count () <= parent.row ())
            return {}; // should not happen
        return create_index (row, column, const_cast<SubFolderInfo> (&_folders[parent.row ()]));
    case SubFolder : {
        auto pinfo = static_cast<SubFolderInfo> (parent.internal_pointer ());
        if (pinfo._subs.count () <= parent.row ())
            return {}; // should not happen
        auto &info = pinfo._subs[parent.row ()];
        if (!info.has_label ()
            && info._subs.count () <= row)
            return {}; // should not happen
        return create_index (row, column, &info);
    }
    }
    return {};
}

QModelIndex FolderStatusModel.parent (QModelIndex &child) {
    if (!child.is_valid ()) {
        return {};
    }
    switch (classify (child)) {
    case RootFolder:
    case AddButton:
        return {};
    case SubFolder:
    case Fetch_label:
        break;
    }
    auto path_idx = static_cast<SubFolderInfo> (child.internal_pointer ())._path_idx;
    int i = 1;
    ASSERT (path_idx.at (0) < _folders.count ());
    if (path_idx.count () == 1) {
        return create_index (path_idx.at (0), 0 /*, nullptr*/);
    }

    const SubFolderInfo *info = &_folders[path_idx.at (0)];
    while (i < path_idx.count () - 1) {
        ASSERT (path_idx.at (i) < info._subs.count ());
        info = &info._subs.at (path_idx.at (i));
        ++i;
    }
    return create_index (path_idx.at (i), 0, const_cast<SubFolderInfo> (info));
}

bool FolderStatusModel.has_children (QModelIndex &parent) {
    if (!parent.is_valid ())
        return true;

    auto info = info_for_index (parent);
    if (!info)
        return false;

    if (!info._fetched)
        return true;

    if (info._subs.is_empty ())
        return false;

    return true;
}

bool FolderStatusModel.can_fetch_more (QModelIndex &parent) {
    if (!_account_state) {
        return false;
    }
    if (_account_state.state () != AccountState.Connected) {
        return false;
    }
    auto info = info_for_index (parent);
    if (!info || info._fetched || info._fetching_job)
        return false;
    if (info._has_error) {
        // Keep showing the error to the user, it will be hidden when the account reconnects
        return false;
    }
    return true;
}

void FolderStatusModel.fetch_more (QModelIndex &parent) {
    auto info = info_for_index (parent);

    if (!info || info._fetched || info._fetching_job)
        return;
    info.reset_subs (this, parent);
    string path = info._folder.remote_path_trailing_slash ();

    // info._path always contains non-mangled name, so we need to use mangled when requesting nested folders for encrypted subfolders as required by Ls_col_job
    const string info_path = (info._is_encrypted && !info._e2e_mangled_name.is_empty ()) ? info._e2e_mangled_name : info._path;

    if (info_path != QLatin1String ("/")) {
        path += info_path;
    }

    auto *job = new Ls_col_job (_account_state.account (), path, this);
    info._fetching_job = job;
    auto props = QList<QByteArray> () << "resourcetype"
                                     << "http://owncloud.org/ns:size"
                                     << "http://owncloud.org/ns:permissions"
                                     << "http://owncloud.org/ns:fileid";
    if (_account_state.account ().capabilities ().client_side_encryption_available ()) {
        props << "http://nextcloud.org/ns:is-encrypted";
    }
    job.set_properties (props);

    job.set_timeout (60 * 1000);
    connect (job, &Ls_col_job.directory_listing_subfolders,
        this, &FolderStatusModel.slot_update_directories);
    connect (job, &Ls_col_job.finished_with_error,
        this, &FolderStatusModel.slot_lscol_finished_with_error);
    connect (job, &Ls_col_job.directory_listing_iterated,
        this, &FolderStatusModel.slot_gather_permissions);
    connect (job, &Ls_col_job.directory_listing_iterated,
            this, &FolderStatusModel.slot_gather_encryption_status);

    job.start ();

    QPersistent_model_index persistent_index (parent);
    job.set_property (property_parent_index_c, QVariant.from_value (persistent_index));

    // Show 'fetching data...' hint after a while.
    _fetching_items[persistent_index].start ();
    QTimer.single_shot (1000, this, &FolderStatusModel.slot_show_fetch_progress);
}

void FolderStatusModel.reset_and_fetch (QModelIndex &parent) {
    auto info = info_for_index (parent);
    info.reset_subs (this, parent);
    fetch_more (parent);
}

void FolderStatusModel.slot_gather_permissions (string &href, QMap<string, string> &map) {
    auto it = map.find ("permissions");
    if (it == map.end ())
        return;

    auto job = sender ();
    auto permission_map = job.property (property_permission_map).to_map ();
    job.set_property (property_permission_map, QVariant ()); // avoid a detach of the map while it is modified
    ASSERT (!href.ends_with (QLatin1Char ('/')), "Ls_col_xMLParser.parse should remove the trailing slash before calling us.");
    permission_map[href] = *it;
    job.set_property (property_permission_map, permission_map);
}

void FolderStatusModel.slot_gather_encryption_status (string &href, QMap<string, string> &properties) {
    auto it = properties.find ("is-encrypted");
    if (it == properties.end ())
        return;

    auto job = sender ();
    auto encryption_map = job.property (property_encryption_map).to_map ();
    job.set_property (property_encryption_map, QVariant ()); // avoid a detach of the map while it is modified
    ASSERT (!href.ends_with (QLatin1Char ('/')), "Ls_col_xMLParser.parse should remove the trailing slash before calling us.");
    encryption_map[href] = *it;
    job.set_property (property_encryption_map, encryption_map);
}

void FolderStatusModel.slot_update_directories (QStringList &list) {
    auto job = qobject_cast<Ls_col_job> (sender ());
    ASSERT (job);
    QModelIndex idx = qvariant_cast<QPersistent_model_index> (job.property (property_parent_index_c));
    auto parent_info = info_for_index (idx);
    if (!parent_info) {
        return;
    }
    ASSERT (parent_info._fetching_job == job);
    ASSERT (parent_info._subs.is_empty ());

    if (parent_info.has_label ()) {
        begin_remove_rows (idx, 0, 0);
        parent_info._has_error = false;
        parent_info._fetching_label = false;
        end_remove_rows ();
    }

    parent_info._last_error_string.clear ();
    parent_info._fetching_job = nullptr;
    parent_info._fetched = true;

    QUrl url = parent_info._folder.remote_url ();
    string path_to_remove = url.path ();
    if (!path_to_remove.ends_with ('/'))
        path_to_remove += '/';

    QStringList selective_sync_black_list;
    bool ok1 = true;
    bool ok2 = true;
    if (parent_info._checked == Qt.Partially_checked) {
        selective_sync_black_list = parent_info._folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok1);
    }
    auto selective_sync_undecided_list = parent_info._folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, &ok2);

    if (! (ok1 && ok2)) {
        q_c_warning (lc_folder_status) << "Could not retrieve selective sync info from journal";
        return;
    }

    std.set<string> selective_sync_undecided_set; // not QSet because it's not sorted
    foreach (string &str, selective_sync_undecided_list) {
        if (str.starts_with (parent_info._path) || parent_info._path == QLatin1String ("/")) {
            selective_sync_undecided_set.insert (str);
        }
    }
    const auto permission_map = job.property (property_permission_map).to_map ();
    const auto encryption_map = job.property (property_encryption_map).to_map ();

    QStringList sorted_subfolders = list;
    if (!sorted_subfolders.is_empty ())
        sorted_subfolders.remove_first (); // skip the parent item (first in the list)
    Utility.sort_filenames (sorted_subfolders);

    QVarLengthArray<int, 10> undecided_indexes;

    QVector<SubFolderInfo> new_subs;
    new_subs.reserve (sorted_subfolders.size ());
    foreach (string &path, sorted_subfolders) {
        auto relative_path = path.mid (path_to_remove.size ());
        if (parent_info._folder.is_file_excluded_relative (relative_path)) {
            continue;
        }

        SubFolderInfo new_info;
        new_info._folder = parent_info._folder;
        new_info._path_idx = parent_info._path_idx;
        new_info._path_idx << new_subs.size ();
        new_info._is_external = permission_map.value (remove_trailing_slash (path)).to_string ().contains ("M");
        new_info._is_encrypted = encryption_map.value (remove_trailing_slash (path)).to_string () == QStringLiteral ("1");
        new_info._path = relative_path;

        SyncJournalFileRecord rec;
        parent_info._folder.journal_db ().get_file_record_by_e2e_mangled_name (remove_trailing_slash (relative_path), &rec);
        if (rec.is_valid ()) {
            new_info._name = remove_trailing_slash (rec._path).split ('/').last ();
            if (rec._is_e2e_encrypted && !rec._e2e_mangled_name.is_empty ()) {
                // we must use local path for Settings Dialog's filesystem tree, otherwise open and create new folder actions won't work
                // hence, we are storing _e2e_mangled_name separately so it can be use later for Ls_col_job
                new_info._e2e_mangled_name = relative_path;
                new_info._path = rec._path;
            }
            if (!new_info._path.ends_with ('/')) {
                new_info._path += '/';
            }
        } else {
            new_info._name = remove_trailing_slash (relative_path).split ('/').last ();
        }

        const auto& folder_info = job._folder_infos.value (path);
        new_info._size = folder_info.size;
        new_info._file_id = folder_info.file_id;
        if (relative_path.is_empty ())
            continue;

        if (parent_info._checked == Qt.Unchecked) {
            new_info._checked = Qt.Unchecked;
        } else if (parent_info._checked == Qt.Checked) {
            new_info._checked = Qt.Checked;
        } else {
            foreach (string &str, selective_sync_black_list) {
                if (str == relative_path || str == QLatin1String ("/")) {
                    new_info._checked = Qt.Unchecked;
                    break;
                } else if (str.starts_with (relative_path)) {
                    new_info._checked = Qt.Partially_checked;
                }
            }
        }

        auto it = selective_sync_undecided_set.lower_bound (relative_path);
        if (it != selective_sync_undecided_set.end ()) {
            if (*it == relative_path) {
                new_info._is_undecided = true;
                selective_sync_undecided_set.erase (it);
            } else if ( (*it).starts_with (relative_path)) {
                undecided_indexes.append (new_info._path_idx.last ());

                // Remove all the items from the selective_sync_undecided_set that starts with this path
                string relative_path_next = relative_path;
                relative_path_next[relative_path_next.length () - 1].unicode ()++;
                auto it2 = selective_sync_undecided_set.lower_bound (relative_path_next);
                selective_sync_undecided_set.erase (it, it2);
            }
        }
        new_subs.append (new_info);
    }

    if (!new_subs.is_empty ()) {
        begin_insert_rows (idx, 0, new_subs.size () - 1);
        parent_info._subs = std.move (new_subs);
        end_insert_rows ();
    }

    for (int undecided_index : q_as_const (undecided_indexes)) {
        suggest_expand (index (undecided_index, 0, idx));
    }
    /* Try to remove the the undecided lists the items that are not on the server. */
    auto it = std.remove_if (selective_sync_undecided_list.begin (), selective_sync_undecided_list.end (),
        [&] (string &s) {
            return selective_sync_undecided_set.count (s);
        });
    if (it != selective_sync_undecided_list.end ()) {
        selective_sync_undecided_list.erase (it, selective_sync_undecided_list.end ());
        parent_info._folder.journal_db ().set_selective_sync_list (
            SyncJournalDb.SelectiveSyncUndecidedList, selective_sync_undecided_list);
        emit dirty_changed ();
    }
}

void FolderStatusModel.slot_lscol_finished_with_error (QNetworkReply *r) {
    auto job = qobject_cast<Ls_col_job> (sender ());
    ASSERT (job);
    QModelIndex idx = qvariant_cast<QPersistent_model_index> (job.property (property_parent_index_c));
    if (!idx.is_valid ()) {
        return;
    }
    auto parent_info = info_for_index (idx);
    if (parent_info) {
        q_c_debug (lc_folder_status) << r.error_string ();
        parent_info._last_error_string = r.error_string ();
        auto error = r.error ();

        parent_info.reset_subs (this, idx);

        if (error == QNetworkReply.ContentNotFoundError) {
            parent_info._fetched = true;
        } else {
            ASSERT (!parent_info.has_label ());
            begin_insert_rows (idx, 0, 0);
            parent_info._has_error = true;
            end_insert_rows ();
        }
    }
}

QStringList FolderStatusModel.create_black_list (FolderStatusModel.SubFolderInfo &root,
    const QStringList &old_black_list) {
    switch (root._checked) {
    case Qt.Unchecked:
        return QStringList (root._path);
    case Qt.Checked:
        return QStringList ();
    case Qt.Partially_checked:
        break;
    }

    QStringList result;
    if (root._fetched) {
        for (int i = 0; i < root._subs.count (); ++i) {
            result += create_black_list (root._subs.at (i), old_black_list);
        }
    } else {
        // We did not load from the server so we re-use the one from the old black list
        const string path = root._path;
        foreach (string &it, old_black_list) {
            if (it.starts_with (path))
                result += it;
        }
    }
    return result;
}

void FolderStatusModel.slot_update_folder_state (Folder *folder) {
    if (!folder)
        return;
    for (int i = 0; i < _folders.count (); ++i) {
        if (_folders.at (i)._folder == folder) {
            emit data_changed (index (i), index (i));
        }
    }
}

void FolderStatusModel.slot_apply_selective_sync () {
    for (auto &folder_info : q_as_const (_folders)) {
        if (!folder_info._fetched) {
            folder_info._folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, QStringList ());
            continue;
        }
        const auto folder = folder_info._folder;

        bool ok = false;
        auto old_black_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (!ok) {
            q_c_warning (lc_folder_status) << "Could not read selective sync list from db.";
            continue;
        }
        QStringList black_list = create_black_list (folder_info, old_black_list);
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, black_list);

        auto black_list_set = black_list.to_set ();
        auto old_black_list_set = old_black_list.to_set ();

        // The folders that were undecided or blacklisted and that are now checked should go on the white list.
        // The user confirmed them already just now.
        QStringList to_add_to_white_list = ( (old_black_list_set + folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, &ok).to_set ()) - black_list_set).values ();

        if (!to_add_to_white_list.is_empty ()) {
            auto white_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, &ok);
            if (ok) {
                white_list += to_add_to_white_list;
                folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, white_list);
            }
        }
        // clear the undecided list
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, QStringList ());

        // do the sync if there were changes
        auto changes = (old_black_list_set - black_list_set) + (black_list_set - old_black_list_set);
        if (!changes.is_empty ()) {
            if (folder.is_busy ()) {
                folder.slot_terminate_sync ();
            }
            //The part that changed should not be read from the DB on next sync because there might be new folders
            // (the ones that are no longer in the blacklist)
            foreach (auto &it, changes) {
                folder.journal_db ().schedule_path_for_remote_discovery (it);
                folder.schedule_path_for_local_discovery (it);
            }
            FolderMan.instance ().schedule_folder (folder);
        }
    }

    reset_folders ();
}

void FolderStatusModel.slot_set_progress (ProgressInfo &progress) {
    auto par = qobject_cast<Gtk.Widget> (GLib.Object.parent ());
    if (!par.is_visible ()) {
        return; // for https://github.com/owncloud/client/issues/2648#issuecomment-71377909
    }

    auto *f = qobject_cast<Folder> (sender ());
    if (!f) {
        return;
    }

    int folder_index = -1;
    for (int i = 0; i < _folders.count (); ++i) {
        if (_folders.at (i)._folder == f) {
            folder_index = i;
            break;
        }
    }
    if (folder_index < 0) {
        return;
    }

    auto *pi = &_folders[folder_index]._progress;

    QVector<int> roles;
    roles << FolderStatusDelegate.Sync_progress_item_string
          << FolderStatusDelegate.Warning_count
          << Qt.ToolTipRole;

    if (progress.status () == ProgressInfo.Discovery) {
        if (!progress._current_discovered_remote_folder.is_empty ()) {
            pi._overall_sync_string = tr ("Checking for changes in remote \"%1\"").arg (progress._current_discovered_remote_folder);
            emit data_changed (index (folder_index), index (folder_index), roles);
            return;
        } else if (!progress._current_discovered_local_folder.is_empty ()) {
            pi._overall_sync_string = tr ("Checking for changes in local \"%1\"").arg (progress._current_discovered_local_folder);
            emit data_changed (index (folder_index), index (folder_index), roles);
            return;
        }
    }

    if (progress.status () == ProgressInfo.Reconcile) {
        pi._overall_sync_string = tr ("Reconciling changes");
        emit data_changed (index (folder_index), index (folder_index), roles);
        return;
    }

    // Status is Starting, Propagation or Done

    if (!progress._last_completed_item.is_empty ()
        && Progress.is_warning_kind (progress._last_completed_item._status)) {
        pi._warning_count++;
    }

    // find the single item to display :  This is going to be the bigger item, or the last completed
    // item if no items are in progress.
    SyncFileItem cur_item = progress._last_completed_item;
    int64 cur_item_progress = -1; // -1 means finished
    int64 bigger_item_size = 0;
    uint64 estimated_up_bw = 0;
    uint64 estimated_down_bw = 0;
    string all_filenames;
    foreach (ProgressInfo.Progress_item &citm, progress._current_items) {
        if (cur_item_progress == -1 || (ProgressInfo.is_size_dependent (citm._item)
                                         && bigger_item_size < citm._item._size)) {
            cur_item_progress = citm._progress.completed ();
            cur_item = citm._item;
            bigger_item_size = citm._item._size;
        }
        if (citm._item._direction != SyncFileItem.Up) {
            estimated_down_bw += progress.file_progress (citm._item).estimated_bandwidth;
        } else {
            estimated_up_bw += progress.file_progress (citm._item).estimated_bandwidth;
        }
        auto file_name = QFileInfo (citm._item._file).file_name ();
        if (all_filenames.length () > 0) {
            // : Build a list of file names
            all_filenames.append (QStringLiteral (", \"%1\"").arg (file_name));
        } else {
            // : Argument is a file name
            all_filenames.append (QStringLiteral ("\"%1\"").arg (file_name));
        }
    }
    if (cur_item_progress == -1) {
        cur_item_progress = cur_item._size;
    }

    string item_file_name = cur_item._file;
    string kind_string = Progress.as_action_string (cur_item);

    string file_progress_string;
    if (ProgressInfo.is_size_dependent (cur_item)) {
        string s1 = Utility.octets_to_string (cur_item_progress);
        string s2 = Utility.octets_to_string (cur_item._size);
        //uint64 estimated_bw = progress.file_progress (cur_item).estimated_bandwidth;
        if (estimated_up_bw || estimated_down_bw) {
            /***********************************************************
            // : Example text : "uploading foobar.png (1MB of 2MB) time left 2 minutes at a rate of 24Kb/s"
            file_progress_string = tr ("%1 %2 (%3 of %4) %5 left at a rate of %6/s")
                .arg (kind_string, item_file_name, s1, s2,
                    Utility.duration_to_descriptive_string (progress.file_progress (cur_item).estimated_eta),
                    Utility.octets_to_string (estimated_bw) );
            */
            // : Example text : "Syncing 'foo.txt', 'bar.txt'"
            file_progress_string = tr ("Syncing %1").arg (all_filenames);
            if (estimated_down_bw > 0) {
                file_progress_string.append (tr (", "));
// ifdefs : https://github.com/owncloud/client/issues/3095#issuecomment-128409294
                file_progress_string.append (tr ("\u2193 %1/s")
                                              .arg (Utility.octets_to_string (estimated_down_bw)));
            }
            if (estimated_up_bw > 0) {
                file_progress_string.append (tr (", "));
                file_progress_string.append (tr ("\u2191 %1/s")
                                              .arg (Utility.octets_to_string (estimated_up_bw)));
            }
        } else {
            // : Example text : "uploading foobar.png (2MB of 2MB)"
            file_progress_string = tr ("%1 %2 (%3 of %4)").arg (kind_string, item_file_name, s1, s2);
        }
    } else if (!kind_string.is_empty ()) {
        // : Example text : "uploading foobar.png"
        file_progress_string = tr ("%1 %2").arg (kind_string, item_file_name);
    }
    pi._progress_string = file_progress_string;

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
            overall_sync_string = tr ("%5 left, %1 of %2, file %3 of %4")
                                    .arg (s1, s2)
                                    .arg (current_file)
                                    .arg (total_file_count)
                                    .arg (Utility.duration_to_descriptive_string1 (progress.total_progress ().estimated_eta));

        } else {
            // : Example text : "12 MB of 345 MB, file 6 of 7"
            overall_sync_string = tr ("%1 of %2, file %3 of %4")
                                    .arg (s1, s2)
                                    .arg (current_file)
                                    .arg (total_file_count);
        }
    } else if (total_file_count > 0) {
        // Don't attempt to estimate the time left if there is no kb to transfer.
        overall_sync_string = tr ("file %1 of %2").arg (current_file).arg (total_file_count);
    }

    pi._overall_sync_string = overall_sync_string;

    int overall_percent = 0;
    if (total_file_count > 0) {
        // Add one 'byte' for each file so the percentage is moving when deleting or renaming files
        overall_percent = q_round (double (completed_size + completed_file) / double (total_size + total_file_count) * 100.0);
    }
    pi._overall_percent = q_bound (0, overall_percent, 100);
    emit data_changed (index (folder_index), index (folder_index), roles);
}

void FolderStatusModel.slot_folder_sync_state_change (Folder *f) {
    if (!f) {
        return;
    }

    int folder_index = -1;
    for (int i = 0; i < _folders.count (); ++i) {
        if (_folders.at (i)._folder == f) {
            folder_index = i;
            break;
        }
    }
    if (folder_index < 0) {
        return;
    }

    auto &pi = _folders[folder_index]._progress;

    SyncResult.Status state = f.sync_result ().status ();
    if (!f.can_sync () || state == SyncResult.Problem || state == SyncResult.Success || state == SyncResult.Error) {
        // Reset progress info.
        pi = SubFolderInfo.Progress ();
    } else if (state == SyncResult.Not_yet_started) {
        FolderMan *folder_man = FolderMan.instance ();
        int pos = folder_man.schedule_queue ().index_of (f);
        for (auto other : folder_man.map ()) {
            if (other != f && other.is_sync_running ())
                pos += 1;
        }
        string message;
        if (pos <= 0) {
            message = tr ("Waiting …");
        } else {
            message = tr ("Waiting for %n other folder (s) …", "", pos);
        }
        pi = SubFolderInfo.Progress ();
        pi._overall_sync_string = message;
    } else if (state == SyncResult.Sync_prepare) {
        pi = SubFolderInfo.Progress ();
        pi._overall_sync_string = tr ("Preparing to sync …");
    }

    // update the icon etc. now
    slot_update_folder_state (f);

    if (f.sync_result ().folder_structure_was_changed ()
        && (state == SyncResult.Success || state == SyncResult.Problem)) {
        // There is a new or a removed folder. reset all data
        reset_and_fetch (index (folder_index));
    }
}

void FolderStatusModel.slot_folder_schedule_queue_changed () {
    // Update messages on waiting folders.
    foreach (Folder *f, FolderMan.instance ().map ()) {
        slot_folder_sync_state_change (f);
    }
}

void FolderStatusModel.reset_folders () {
    set_account_state (_account_state);
}

void FolderStatusModel.slot_sync_all_pending_big_folders () {
    for (int i = 0; i < _folders.count (); ++i) {
        if (!_folders[i]._fetched) {
            _folders[i]._folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, QStringList ());
            continue;
        }
        auto folder = _folders.at (i)._folder;

        bool ok = false;
        auto undecided_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, &ok);
        if (!ok) {
            q_c_warning (lc_folder_status) << "Could not read selective sync list from db.";
            return;
        }

        // If this folder had no undecided entries, skip it.
        if (undecided_list.is_empty ()) {
            continue;
        }

        // Remove all undecided folders from the blacklist
        auto black_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (!ok) {
            q_c_warning (lc_folder_status) << "Could not read selective sync list from db.";
            return;
        }
        foreach (auto &undecided_folder, undecided_list) {
            black_list.remove_all (undecided_folder);
        }
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, black_list);

        // Add all undecided folders to the white list
        auto white_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, &ok);
        if (!ok) {
            q_c_warning (lc_folder_status) << "Could not read selective sync list from db.";
            return;
        }
        white_list += undecided_list;
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, white_list);

        // Clear the undecided list
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, QStringList ());

        // Trigger a sync
        if (folder.is_busy ()) {
            folder.slot_terminate_sync ();
        }
        // The part that changed should not be read from the DB on next sync because there might be new folders
        // (the ones that are no longer in the blacklist)
        foreach (auto &it, undecided_list) {
            folder.journal_db ().schedule_path_for_remote_discovery (it);
            folder.schedule_path_for_local_discovery (it);
        }
        FolderMan.instance ().schedule_folder (folder);
    }

    reset_folders ();
}

void FolderStatusModel.slot_sync_no_pending_big_folders () {
    for (int i = 0; i < _folders.count (); ++i) {
        auto folder = _folders.at (i)._folder;

        // clear the undecided list
        folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, QStringList ());
    }

    reset_folders ();
}

void FolderStatusModel.slot_new_big_folder () {
    auto f = qobject_cast<Folder> (sender ());
    ASSERT (f);

    int folder_index = -1;
    for (int i = 0; i < _folders.count (); ++i) {
        if (_folders.at (i)._folder == f) {
            folder_index = i;
            break;
        }
    }
    if (folder_index < 0) {
        return;
    }

    reset_and_fetch (index (folder_index));

    emit suggest_expand (index (folder_index));
    emit dirty_changed ();
}

void FolderStatusModel.slot_show_fetch_progress () {
    QMutable_map_iterator<QPersistent_model_index, QElapsedTimer> it (_fetching_items);
    while (it.has_next ()) {
        it.next ();
        if (it.value ().elapsed () > 800) {
            auto idx = it.key ();
            auto *info = info_for_index (idx);
            if (info && info._fetching_job) {
                bool add = !info.has_label ();
                if (add) {
                    begin_insert_rows (idx, 0, 0);
                }
                info._fetching_label = true;
                if (add) {
                    end_insert_rows ();
                }
            }
            it.remove ();
        }
    }
}

bool FolderStatusModel.SubFolderInfo.has_label () {
    return _has_error || _fetching_label;
}

void FolderStatusModel.SubFolderInfo.reset_subs (FolderStatusModel *model, QModelIndex index) {
    _fetched = false;
    if (_fetching_job) {
        disconnect (_fetching_job, nullptr, model, nullptr);
        _fetching_job.delete_later ();
        _fetching_job.clear ();
    }
    if (has_label ()) {
        model.begin_remove_rows (index, 0, 0);
        _fetching_label = false;
        _has_error = false;
        model.end_remove_rows ();
    } else if (!_subs.is_empty ()) {
        model.begin_remove_rows (index, 0, _subs.count () - 1);
        _subs.clear ();
        model.end_remove_rows ();
    }
}

} // namespace Occ
