/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDialogButtonBox>
// #include <QVBoxLayout>
// #include <QTree_widget>
// #include <qpushbutton.h>
// #include <QFile_icon_provider>
// #include <QHeader_view>
// #include <QSettings>
// #include <QScoped_value_rollback>
// #include <QTree_widget_item>
// #include <QLabel>
// #include <QVBoxLayout>

// #pragma once
// #include <Gtk.Dialog>
// #include <QTree_widget>

class QLabel;
namespace Occ {


/***********************************************************
@brief The Selective_sync_widget contains a folder tree with labels
@ingroup gui
***********************************************************/
class Selective_sync_widget : Gtk.Widget {
public:
    Selective_sync_widget (AccountPtr account, Gtk.Widget *parent = nullptr);

    /// Returns a list of blacklisted paths, each including the trailing /
    QStringList create_black_list (QTree_widget_item *root = nullptr) const;

    /***********************************************************
    Returns the old_black_list passed into set_folder_info (), except that
     a "/" entry is expanded to all top-level folder names.
    ***********************************************************/
    QStringList old_black_list ();

    // Estimates the total size of checked items (recursively)
    int64 estimated_size (QTree_widget_item *root = nullptr);

    // old_black_list is a list of excluded paths, each including a trailing /
    void set_folder_info (string &folder_path, string &root_name,
        const QStringList &old_black_list = QStringList ());

    QSize size_hint () const override;

private slots:
    void slot_update_directories (QStringList);
    void slot_item_expanded (QTree_widget_item *);
    void slot_item_changed (QTree_widget_item *, int);
    void slot_lscol_finished_with_error (QNetworkReply *);
    void slot_gather_encrypted_paths (string &, QMap<string, string> &);

private:
    void refresh_folders ();
    void recursive_insert (QTree_widget_item *parent, QStringList path_trail, string path, int64 size);

    AccountPtr _account;

    string _folder_path;
    string _root_name;
    QStringList _old_black_list;

    bool _inserting; // set to true when we are inserting new items on the list
    QLabel *_loading;

    QTree_widget *_folder_tree;

    // During account setup we want to filter out excluded folders from the
    // view without having a Folder.Sync_engine.Excluded_files instance.
    Excluded_files _excluded_files;

    QStringList _encrypted_paths;
};

/***********************************************************
@brief The Selective_sync_dialog class
@ingroup gui
***********************************************************/
class Selective_sync_dialog : Gtk.Dialog {
public:
    // Dialog for a specific folder (used from the account settings button)
    Selective_sync_dialog (AccountPtr account, Folder *folder, Gtk.Widget *parent = nullptr, Qt.Window_flags f = {});

    // Dialog for the whole account (Used from the wizard)
    Selective_sync_dialog (AccountPtr account, string &folder, QStringList &blacklist, Gtk.Widget *parent = nullptr, Qt.Window_flags f = {});

    void accept () override;

    QStringList create_black_list ();
    QStringList old_black_list ();

    // Estimate the size of the total of sync'ed files from the server
    int64 estimated_size ();

private:
    void init (AccountPtr &account);

    Selective_sync_widget *_selective_sync;

    Folder *_folder;
    QPushButton *_ok_button;
};

    class Selective_sync_tree_view_item : QTree_widget_item {
    public:
        Selective_sync_tree_view_item (int type = QTree_widget_item.Type)
            : QTree_widget_item (type) {
        }
        Selective_sync_tree_view_item (QStringList &strings, int type = QTree_widget_item.Type)
            : QTree_widget_item (strings, type) {
        }
        Selective_sync_tree_view_item (QTree_widget *view, int type = QTree_widget_item.Type)
            : QTree_widget_item (view, type) {
        }
        Selective_sync_tree_view_item (QTree_widget_item *parent, int type = QTree_widget_item.Type)
            : QTree_widget_item (parent, type) {
        }
    
    private:
        bool operator< (QTree_widget_item &other) const override {
            int column = tree_widget ().sort_column ();
            if (column == 1) {
                return data (1, Qt.User_role).to_long_long () < other.data (1, Qt.User_role).to_long_long ();
            }
            return QTree_widget_item.operator< (other);
        }
    };
    
    Selective_sync_widget.Selective_sync_widget (AccountPtr account, Gtk.Widget *parent)
        : Gtk.Widget (parent)
        , _account (account)
        , _inserting (false)
        , _folder_tree (new QTree_widget (this)) {
        _loading = new QLabel (tr ("Loading …"), _folder_tree);
    
        auto layout = new QVBoxLayout (this);
        layout.set_contents_margins (0, 0, 0, 0);
    
        auto header = new QLabel (this);
        header.set_text (tr ("Deselect remote folders you do not wish to synchronize."));
        header.set_word_wrap (true);
        layout.add_widget (header);
    
        layout.add_widget (_folder_tree);
    
        connect (_folder_tree, &QTree_widget.item_expanded,
            this, &Selective_sync_widget.slot_item_expanded);
        connect (_folder_tree, &QTree_widget.item_changed,
            this, &Selective_sync_widget.slot_item_changed);
        _folder_tree.set_sorting_enabled (true);
        _folder_tree.sort_by_column (0, Qt.Ascending_order);
        _folder_tree.set_column_count (2);
        _folder_tree.header ().set_section_resize_mode (0, QHeader_view.QHeader_view.Resize_to_contents);
        _folder_tree.header ().set_section_resize_mode (1, QHeader_view.QHeader_view.Resize_to_contents);
        _folder_tree.header ().set_stretch_last_section (true);
        _folder_tree.header_item ().set_text (0, tr ("Name"));
        _folder_tree.header_item ().set_text (1, tr ("Size"));
    
        ConfigFile.setup_default_exclude_file_paths (_excluded_files);
        _excluded_files.reload_exclude_files ();
    }
    
    QSize Selective_sync_widget.size_hint () {
        return Gtk.Widget.size_hint ().expanded_to (QSize (600, 600));
    }
    
    void Selective_sync_widget.refresh_folders () {
        _encrypted_paths.clear ();
    
        auto *job = new Ls_col_job (_account, _folder_path, this);
        auto props = QList<QByteArray> () << "resourcetype"
                                         << "http://owncloud.org/ns:size";
        if (_account.capabilities ().client_side_encryption_available ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
        job.set_properties (props);
        connect (job, &Ls_col_job.directory_listing_subfolders,
            this, &Selective_sync_widget.slot_update_directories);
        connect (job, &Ls_col_job.finished_with_error,
            this, &Selective_sync_widget.slot_lscol_finished_with_error);
        connect (job, &Ls_col_job.directory_listing_iterated,
            this, &Selective_sync_widget.slot_gather_encrypted_paths);
        job.start ();
        _folder_tree.clear ();
        _loading.show ();
        _loading.move (10, _folder_tree.header ().height () + 10);
    }
    
    void Selective_sync_widget.set_folder_info (string &folder_path, string &root_name, QStringList &old_black_list) {
        _folder_path = folder_path;
        if (_folder_path.starts_with (QLatin1Char ('/'))) {
            // remove leading '/'
            _folder_path = folder_path.mid (1);
        }
        _root_name = root_name;
        _old_black_list = old_black_list;
        refresh_folders ();
    }
    
    static QTree_widget_item *find_first_child (QTree_widget_item *parent, string &text) {
        for (int i = 0; i < parent.child_count (); ++i) {
            QTree_widget_item *child = parent.child (i);
            if (child.text (0) == text) {
                return child;
            }
        }
        return nullptr;
    }
    
    void Selective_sync_widget.recursive_insert (QTree_widget_item *parent, QStringList path_trail, string path, int64 size) {
        QFile_icon_provider prov;
        QIcon folder_icon = prov.icon (QFile_icon_provider.Folder);
        if (path_trail.size () == 0) {
            if (path.ends_with ('/')) {
                path.chop (1);
            }
            parent.set_tool_tip (0, path);
            parent.set_data (0, Qt.User_role, path);
        } else {
            auto *item = static_cast<Selective_sync_tree_view_item> (find_first_child (parent, path_trail.first ()));
            if (!item) {
                item = new Selective_sync_tree_view_item (parent);
                if (parent.check_state (0) == Qt.Checked
                    || parent.check_state (0) == Qt.Partially_checked) {
                    item.set_check_state (0, Qt.Checked);
                    foreach (string &str, _old_black_list) {
                        if (str == path || str == QLatin1String ("/")) {
                            item.set_check_state (0, Qt.Unchecked);
                            break;
                        } else if (str.starts_with (path)) {
                            item.set_check_state (0, Qt.Partially_checked);
                        }
                    }
                } else if (parent.check_state (0) == Qt.Unchecked) {
                    item.set_check_state (0, Qt.Unchecked);
                }
                item.set_icon (0, folder_icon);
                item.set_text (0, path_trail.first ());
                if (size >= 0) {
                    item.set_text (1, Utility.octets_to_string (size));
                    item.set_data (1, Qt.User_role, size);
                }
                //            item.set_data (0, Qt.User_role, path_trail.first ());
                item.set_child_indicator_policy (QTree_widget_item.Show_indicator);
            }
    
            path_trail.remove_first ();
            recursive_insert (item, path_trail, path, size);
        }
    }
    
    void Selective_sync_widget.slot_update_directories (QStringList list) {
        auto job = qobject_cast<Ls_col_job> (sender ());
        QScoped_value_rollback<bool> is_inserting (_inserting);
        _inserting = true;
    
        auto *root = static_cast<Selective_sync_tree_view_item> (_folder_tree.top_level_item (0));
    
        QUrl url = _account.dav_url ();
        string path_to_remove = url.path ();
        if (!path_to_remove.ends_with ('/')) {
            path_to_remove.append ('/');
        }
        path_to_remove.append (_folder_path);
        if (!_folder_path.is_empty ())
            path_to_remove.append ('/');
    
        // Check for excludes.
        QMutable_list_iterator<string> it (list);
        while (it.has_next ()) {
            it.next ();
            if (_excluded_files.is_excluded (it.value (), path_to_remove, FolderMan.instance ().ignore_hidden_files ()))
                it.remove ();
        }
    
        // Since / cannot be in the blacklist, expand it to the actual
        // list of top-level folders as soon as possible.
        if (_old_black_list == QStringList ("/")) {
            _old_black_list.clear ();
            foreach (string path, list) {
                path.remove (path_to_remove);
                if (path.is_empty ()) {
                    continue;
                }
                _old_black_list.append (path);
            }
        }
    
        if (!root && list.size () <= 1) {
            _loading.set_text (tr ("No subfolders currently on the server."));
            _loading.resize (_loading.size_hint ()); // because it's not in a layout
            return;
        } else {
            _loading.hide ();
        }
    
        if (!root) {
            root = new Selective_sync_tree_view_item (_folder_tree);
            root.set_text (0, _root_name);
            root.set_icon (0, Theme.instance ().application_icon ());
            root.set_data (0, Qt.User_role, string ());
            root.set_check_state (0, Qt.Checked);
            int64 size = job ? job._folder_infos[path_to_remove].size : -1;
            if (size >= 0) {
                root.set_text (1, Utility.octets_to_string (size));
                root.set_data (1, Qt.User_role, size);
            }
        }
    
        Utility.sort_filenames (list);
        foreach (string path, list) {
            auto size = job ? job._folder_infos[path].size : 0;
            path.remove (path_to_remove);
    
            // Don't allow to select subfolders of encrypted subfolders
            const auto is_any_ancestor_encrypted = std.any_of (std.cbegin (_encrypted_paths), std.cend (_encrypted_paths), [=] (string &encrypted_path) {
                return path.size () > encrypted_path.size () && path.starts_with (encrypted_path);
            });
            if (is_any_ancestor_encrypted) {
                continue;
            }
    
            QStringList paths = path.split ('/');
            if (paths.last ().is_empty ())
                paths.remove_last ();
            if (paths.is_empty ())
                continue;
            if (!path.ends_with ('/')) {
                path.append ('/');
            }
            recursive_insert (root, paths, path, size);
        }
    
        // Root is partially checked if any children are not checked
        for (int i = 0; i < root.child_count (); ++i) {
            const auto child = root.child (i);
            if (child.check_state (0) != Qt.Checked) {
                root.set_check_state (0, Qt.Partially_checked);
                break;
            }
        }
    
        root.set_expanded (true);
    }
    
    void Selective_sync_widget.slot_lscol_finished_with_error (QNetworkReply *r) {
        if (r.error () == QNetworkReply.ContentNotFoundError) {
            _loading.set_text (tr ("No subfolders currently on the server."));
        } else {
            _loading.set_text (tr ("An error occurred while loading the list of sub folders."));
        }
        _loading.resize (_loading.size_hint ()); // because it's not in a layout
    }
    
    void Selective_sync_widget.slot_gather_encrypted_paths (string &path, QMap<string, string> &properties) {
        const auto it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }
    
        const auto webdav_folder = QUrl (_account.dav_url ()).path ();
        Q_ASSERT (path.starts_with (webdav_folder));
        // This dialog use the postfix / convention for folder paths
        _encrypted_paths << path.mid (webdav_folder.size ()) + '/';
    }
    
    void Selective_sync_widget.slot_item_expanded (QTree_widget_item *item) {
        string dir = item.data (0, Qt.User_role).to_string ();
        if (dir.is_empty ())
            return;
        string prefix;
        if (!_folder_path.is_empty ()) {
            prefix = _folder_path + QLatin1Char ('/');
        }
        auto *job = new Ls_col_job (_account, prefix + dir, this);
        job.set_properties (QList<QByteArray> () << "resourcetype"
                                               << "http://owncloud.org/ns:size");
        connect (job, &Ls_col_job.directory_listing_subfolders,
            this, &Selective_sync_widget.slot_update_directories);
        job.start ();
    }
    
    void Selective_sync_widget.slot_item_changed (QTree_widget_item *item, int col) {
        if (col != 0 || _inserting)
            return;
    
        if (item.check_state (0) == Qt.Checked) {
            // If we are checked, check that we may need to check the parent as well if
            // all the siblings are also checked
            QTree_widget_item *parent = item.parent ();
            if (parent && parent.check_state (0) != Qt.Checked) {
                bool has_unchecked = false;
                for (int i = 0; i < parent.child_count (); ++i) {
                    if (parent.child (i).check_state (0) != Qt.Checked) {
                        has_unchecked = true;
                        break;
                    }
                }
                if (!has_unchecked) {
                    parent.set_check_state (0, Qt.Checked);
                } else if (parent.check_state (0) == Qt.Unchecked) {
                    parent.set_check_state (0, Qt.Partially_checked);
                }
            }
            // also check all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != Qt.Checked) {
                    item.child (i).set_check_state (0, Qt.Checked);
                }
            }
        }
    
        if (item.check_state (0) == Qt.Unchecked) {
            QTree_widget_item *parent = item.parent ();
            if (parent && parent.check_state (0) == Qt.Checked) {
                parent.set_check_state (0, Qt.Partially_checked);
            }
    
            // Uncheck all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != Qt.Unchecked) {
                    item.child (i).set_check_state (0, Qt.Unchecked);
                }
            }
    
            // Can't uncheck the root.
            if (!parent) {
                item.set_check_state (0, Qt.Partially_checked);
            }
        }
    
        if (item.check_state (0) == Qt.Partially_checked) {
            QTree_widget_item *parent = item.parent ();
            if (parent && parent.check_state (0) != Qt.Partially_checked) {
                parent.set_check_state (0, Qt.Partially_checked);
            }
        }
    }
    
    QStringList Selective_sync_widget.create_black_list (QTree_widget_item *root) {
        if (!root) {
            root = _folder_tree.top_level_item (0);
        }
        if (!root)
            return QStringList ();
    
        switch (root.check_state (0)) {
        case Qt.Unchecked:
            return QStringList (root.data (0, Qt.User_role).to_string () + "/");
        case Qt.Checked:
            return QStringList ();
        case Qt.Partially_checked:
            break;
        }
    
        QStringList result;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                result += create_black_list (root.child (i));
            }
        } else {
            // We did not load from the server so we re-use the one from the old black list
            string path = root.data (0, Qt.User_role).to_string ();
            foreach (string &it, _old_black_list) {
                if (it.starts_with (path))
                    result += it;
            }
        }
        return result;
    }
    
    QStringList Selective_sync_widget.old_black_list () {
        return _old_black_list;
    }
    
    int64 Selective_sync_widget.estimated_size (QTree_widget_item *root) {
        if (!root) {
            root = _folder_tree.top_level_item (0);
        }
        if (!root)
            return -1;
    
        switch (root.check_state (0)) {
        case Qt.Unchecked:
            return 0;
        case Qt.Checked:
            return root.data (1, Qt.User_role).to_long_long ();
        case Qt.Partially_checked:
            break;
        }
    
        int64 result = 0;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                auto r = estimated_size (root.child (i));
                if (r < 0)
                    return r;
                result += r;
            }
        } else {
            // We did not load from the server so we have no idea how much we will sync from this branch
            return -1;
        }
        return result;
    }
    
    Selective_sync_dialog.Selective_sync_dialog (AccountPtr account, Folder *folder, Gtk.Widget *parent, Qt.Window_flags f)
        : Gtk.Dialog (parent, f)
        , _folder (folder)
        , _ok_button (nullptr) // defined in init () {
        bool ok = false;
        init (account);
        QStringList selective_sync_list = _folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (ok) {
            _selective_sync.set_folder_info (_folder.remote_path (), _folder.alias (), selective_sync_list);
        } else {
            _ok_button.set_enabled (false);
        }
        // Make sure we don't get crashes if the folder is destroyed while we are still open
        connect (_folder, &GLib.Object.destroyed, this, &GLib.Object.delete_later);
    }
    
    Selective_sync_dialog.Selective_sync_dialog (AccountPtr account, string &folder,
        const QStringList &blacklist, Gtk.Widget *parent, Qt.Window_flags f)
        : Gtk.Dialog (parent, f)
        , _folder (nullptr) {
        init (account);
        _selective_sync.set_folder_info (folder, folder, blacklist);
    }
    
    void Selective_sync_dialog.init (AccountPtr &account) {
        set_window_title (tr ("Choose What to Sync"));
        auto *layout = new QVBoxLayout (this);
        _selective_sync = new Selective_sync_widget (account, this);
        layout.add_widget (_selective_sync);
        auto *button_box = new QDialogButtonBox (Qt.Horizontal);
        _ok_button = button_box.add_button (QDialogButtonBox.Ok);
        connect (_ok_button, &QPushButton.clicked, this, &Selective_sync_dialog.accept);
        QPushButton *button = nullptr;
        button = button_box.add_button (QDialogButtonBox.Cancel);
        connect (button, &QAbstractButton.clicked, this, &Gtk.Dialog.reject);
        layout.add_widget (button_box);
    }
    
    void Selective_sync_dialog.accept () {
        if (_folder) {
            bool ok = false;
            auto old_black_list_set = _folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok).to_set ();
            if (!ok) {
                return;
            }
            QStringList black_list = _selective_sync.create_black_list ();
            _folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, black_list);
    
            FolderMan *folder_man = FolderMan.instance ();
            if (_folder.is_busy ()) {
                _folder.slot_terminate_sync ();
            }
    
            //The part that changed should not be read from the DB on next sync because there might be new folders
            // (the ones that are no longer in the blacklist)
            auto black_list_set = black_list.to_set ();
            auto changes = (old_black_list_set - black_list_set) + (black_list_set - old_black_list_set);
            foreach (auto &it, changes) {
                _folder.journal_db ().schedule_path_for_remote_discovery (it);
                _folder.schedule_path_for_local_discovery (it);
            }
    
            folder_man.schedule_folder (_folder);
        }
        Gtk.Dialog.accept ();
    }
    
    QStringList Selective_sync_dialog.create_black_list () {
        return _selective_sync.create_black_list ();
    }
    
    QStringList Selective_sync_dialog.old_black_list () {
        return _selective_sync.old_black_list ();
    }
    
    int64 Selective_sync_dialog.estimated_size () {
        return _selective_sync.estimated_size ();
    }
    }
    