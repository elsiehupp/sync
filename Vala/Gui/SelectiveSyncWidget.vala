/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SelectiveSyncWidget contains a folder tree with labels
@ingroup gui
***********************************************************/
class SelectiveSyncWidget : Gtk.Widget {
    /***********************************************************
    ***********************************************************/
    private string folder_path;
    private string root_name;
    private string[] old_block_list;

    /***********************************************************
    Set to true when we are inserting new items on the list
    ***********************************************************/
    private bool inserting;

    /***********************************************************
    ***********************************************************/
    private QTreeWidget folder_tree;

    /***********************************************************
    During account setup we want to filter out excluded folders
    from the view without having a
    Folder.SyncEngine.ExcludedFiles instance.
    ***********************************************************/
    private ExcludedFiles excluded_files;

    /***********************************************************
    ***********************************************************/
    private string[] encrypted_paths;

    /***********************************************************
    ***********************************************************/
    public SelectiveSyncWidget (unowned Account account, Gtk.Widget parent = null) {
        base (parent);
        this.account = account;
        this.inserting = false;
        this.folder_tree = new QTreeWidget (this);
        this.loading = new Gtk.Label (_("Loading …"), this.folder_tree);

        var layout = new QVBoxLayout (this);
        layout.contents_margins (0, 0, 0, 0);

        var header = new Gtk.Label (this);
        header.on_signal_text (_("Deselect remote folders you do not wish to synchronize."));
        header.word_wrap (true);
        layout.add_widget (header);

        layout.add_widget (this.folder_tree);

        connect (this.folder_tree, QTreeWidget.item_expanded,
            this, SelectiveSyncWidget.on_signal_item_expanded);
        connect (this.folder_tree, QTreeWidget.item_changed,
            this, SelectiveSyncWidget.on_signal_item_changed);
        this.folder_tree.sorting_enabled (true);
        this.folder_tree.sort_by_column (0, Qt.AscendingOrder);
        this.folder_tree.column_count (2);
        this.folder_tree.header ().section_resize_mode (0, QHeaderView.QHeaderView.ResizeToContents);
        this.folder_tree.header ().section_resize_mode (1, QHeaderView.QHeaderView.ResizeToContents);
        this.folder_tree.header ().stretch_last_section (true);
        this.folder_tree.header_item ().on_signal_text (0, _("Name"));
        this.folder_tree.header_item ().on_signal_text (1, _("Size"));

        ConfigFile.setup_default_exclude_file_paths (this.excluded_files);
        this.excluded_files.on_signal_reload_exclude_files ();
    }


    /***********************************************************
    Returns a list of blocklisted paths, each including the
    trailing '/'
    ***********************************************************/
    public string[] create_block_list (QTreeWidgetItem root = null) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
        }
        if (!root)
            return string[] ();

        switch (root.check_state (0)) {
        case Qt.Unchecked:
            return string[] (root.data (0, Qt.USER_ROLE).to_string () + "/");
        case Qt.Checked:
            return string[] ();
        case Qt.PartiallyChecked:
            break;
        }

        string[] result;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                result += create_block_list (root.child (i));
            }
        } else {
            // We did not load from the server so we re-use the one from the old block list
            string path = root.data (0, Qt.USER_ROLE).to_string ();
            foreach (string it, this.old_block_list) {
                if (it.starts_with (path))
                    result += it;
            }
        }
        return result;
    }


    /***********************************************************
    Returns the old_block_list passed into folder_info (), except that
    a "/" entry is expanded to all top-level folder names.
    ***********************************************************/
    public string[] old_block_list () {
        return this.old_block_list;
    }


    /***********************************************************
    Estimates the total size of checked items (recursively)
    ***********************************************************/
    public int64 estimated_size (QTreeWidgetItem root = null) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
        }
        if (!root)
            return -1;

        switch (root.check_state (0)) {
        case Qt.Unchecked:
            return 0;
        case Qt.Checked:
            return root.data (1, Qt.USER_ROLE).to_long_long ();
        case Qt.PartiallyChecked:
            break;
        }

        int64 result = 0;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                var r = estimated_size (root.child (i));
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


    /***********************************************************
    old_block_list is a list of excluded paths, each including
    a trailing '/'
    ***********************************************************/
    public void folder_info (
        string folder_path, string root_name,
        string[] old_block_list = string[] ()) {
        this.folder_path = folder_path;
        if (this.folder_path.starts_with ('/')) {
            // remove leading '/'
            this.folder_path = folder_path.mid (1);
        }
        this.root_name = root_name;
        this.old_block_list = old_block_list;
        refresh_folders ();
    }


    /***********************************************************
    ***********************************************************/
    public override QSize size_hint () {
        return Gtk.Widget.size_hint ().expanded_to (QSize (600, 600));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_directories (string[] list) {
        var job = qobject_cast<LsColJob> (sender ());
        QScopedValueRollback<bool> is_inserting (this.inserting);
        this.inserting = true;

        var root = static_cast<SelectiveSyncTreeViewItem> (this.folder_tree.top_level_item (0));

        GLib.Uri url = this.account.dav_url ();
        string path_to_remove = url.path ();
        if (!path_to_remove.ends_with ('/')) {
            path_to_remove.append ('/');
        }
        path_to_remove.append (this.folder_path);
        if (!this.folder_path.is_empty ())
            path_to_remove.append ('/');

        // Check for excludes.
        QMutableListIterator<string> it (list);
        while (it.has_next ()) {
            it.next ();
            if (this.excluded_files.is_excluded (it.value (), path_to_remove, FolderMan.instance ().ignore_hidden_files ()))
                it.remove ();
        }

        // Since / cannot be in the blocklist, expand it to the actual
        // list of top-level folders as soon as possible.
        if (this.old_block_list == string[] ("/")) {
            this.old_block_list.clear ();
            foreach (string path, list) {
                path.remove (path_to_remove);
                if (path.is_empty ()) {
                    continue;
                }
                this.old_block_list.append (path);
            }
        }

        if (!root && list.size () <= 1) {
            this.loading.on_signal_text (_("No subfolders currently on the server."));
            this.loading.resize (this.loading.size_hint ()); // because it's not in a layout
            return;
        } else {
            this.loading.hide ();
        }

        if (!root) {
            root = new SelectiveSyncTreeViewItem (this.folder_tree);
            root.on_signal_text (0, this.root_name);
            root.icon (0, Theme.instance ().application_icon ());
            root.data (0, Qt.USER_ROLE, "");
            root.check_state (0, Qt.Checked);
            int64 size = job ? job.folder_infos[path_to_remove].size : -1;
            if (size >= 0) {
                root.on_signal_text (1, Utility.octets_to_string (size));
                root.data (1, Qt.USER_ROLE, size);
            }
        }

        Utility.sort_filenames (list);
        foreach (string path, list) {
            var size = job ? job.folder_infos[path].size : 0;
            path.remove (path_to_remove);

            // Don't allow to select subfolders of encrypted subfolders
            const var is_any_ancestor_encrypted = std.any_of (std.cbegin (this.encrypted_paths), std.cend (this.encrypted_paths), [=] (string encrypted_path) {
                return path.size () > encrypted_path.size () && path.starts_with (encrypted_path);
            });
            if (is_any_ancestor_encrypted) {
                continue;
            }

            string[] paths = path.split ('/');
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
            const var child = root.child (i);
            if (child.check_state (0) != Qt.Checked) {
                root.check_state (0, Qt.PartiallyChecked);
                break;
            }
        }

        root.expanded (true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_expanded (QTreeWidgetItem item) {
        string directory = item.data (0, Qt.USER_ROLE).to_string ();
        if (directory.is_empty ())
            return;
        string prefix;
        if (!this.folder_path.is_empty ()) {
            prefix = this.folder_path + '/';
        }
        var job = new LsColJob (this.account, prefix + directory, this);
        job.properties (GLib.List<GLib.ByteArray> ("resourcetype"
                                               + "http://owncloud.org/ns:size");
        connect (job, LsColJob.directory_listing_subfolders,
            this, SelectiveSyncWidget.on_signal_update_directories);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_changed (QTreeWidgetItem item, int col) {
        if (col != 0 || this.inserting)
            return;

        if (item.check_state (0) == Qt.Checked) {
            // If we are checked, check that we may need to check the parent as well if
            // all the siblings are also checked
            QTreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) != Qt.Checked) {
                bool has_unchecked = false;
                for (int i = 0; i < parent.child_count (); ++i) {
                    if (parent.child (i).check_state (0) != Qt.Checked) {
                        has_unchecked = true;
                        break;
                    }
                }
                if (!has_unchecked) {
                    parent.check_state (0, Qt.Checked);
                } else if (parent.check_state (0) == Qt.Unchecked) {
                    parent.check_state (0, Qt.PartiallyChecked);
                }
            }
            // also check all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != Qt.Checked) {
                    item.child (i).check_state (0, Qt.Checked);
                }
            }
        }

        if (item.check_state (0) == Qt.Unchecked) {
            QTreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) == Qt.Checked) {
                parent.check_state (0, Qt.PartiallyChecked);
            }

            // Uncheck all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != Qt.Unchecked) {
                    item.child (i).check_state (0, Qt.Unchecked);
                }
            }

            // Can't uncheck the root.
            if (!parent) {
                item.check_state (0, Qt.PartiallyChecked);
            }
        }

        if (item.check_state (0) == Qt.PartiallyChecked) {
            QTreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) != Qt.PartiallyChecked) {
                parent.check_state (0, Qt.PartiallyChecked);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_finished_with_error (Soup.Reply r) {
        if (r.error () == Soup.Reply.ContentNotFoundError) {
            this.loading.on_signal_text (_("No subfolders currently on the server."));
        } else {
            this.loading.on_signal_text (_("An error occurred while loading the list of sub folders."));
        }
        this.loading.resize (this.loading.size_hint ()); // because it's not in a layout
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_gather_encrypted_paths (string path, GLib.HashMap<string, string> properties) {
        const var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != "1") {
            return;
        }

        const var webdav_folder = GLib.Uri (this.account.dav_url ()).path ();
        //  Q_ASSERT (path.starts_with (webdav_folder));
        // This dialog use the postfix / convention for folder paths
        this.encrypted_paths + path.mid (webdav_folder.size ()) + '/';
    }


    /***********************************************************
    ***********************************************************/
    private void refresh_folders () {
        this.encrypted_paths.clear ();

        var job = new LsColJob (this.account, this.folder_path, this);
        var props = GLib.List<GLib.ByteArray> ("resourcetype"
                                         + "http://owncloud.org/ns:size";
        if (this.account.capabilities ().client_side_encryption_available ()) {
            props + "http://nextcloud.org/ns:is-encrypted";
        }
        job.properties (props);
        connect (job, LsColJob.directory_listing_subfolders,
            this, SelectiveSyncWidget.on_signal_update_directories);
        connect (job, LsColJob.finished_with_error,
            this, SelectiveSyncWidget.on_signal_lscol_finished_with_error);
        connect (job, LsColJob.directory_listing_iterated,
            this, SelectiveSyncWidget.on_signal_gather_encrypted_paths);
        job.on_signal_start ();
        this.folder_tree.clear ();
        this.loading.show ();
        this.loading.move (10, this.folder_tree.header ().height () + 10);
    }


    /***********************************************************
    ***********************************************************/
    private static QTreeWidgetItem find_first_child (QTreeWidgetItem parent, string text) {
        for (int i = 0; i < parent.child_count (); ++i) {
            QTreeWidgetItem child = parent.child (i);
            if (child.text (0) == text) {
                return child;
            }
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private static void SelectiveSyncWidget.recursive_insert (QTreeWidgetItem parent, string[] path_trail, string path, int64 size) {
        QFileIconProvider prov;
        QIcon folder_icon = prov.icon (QFileIconProvider.Folder);
        if (path_trail.size () == 0) {
            if (path.ends_with ('/')) {
                path.chop (1);
            }
            parent.tool_tip (0, path);
            parent.data (0, Qt.USER_ROLE, path);
        } else {
            var item = static_cast<SelectiveSyncTreeViewItem> (find_first_child (parent, path_trail.first ()));
            if (!item) {
                item = new SelectiveSyncTreeViewItem (parent);
                if (parent.check_state (0) == Qt.Checked
                    || parent.check_state (0) == Qt.PartiallyChecked) {
                    item.check_state (0, Qt.Checked);
                    foreach (string string_value, this.old_block_list) {
                        if (string_value == path || string_value == "/") {
                            item.check_state (0, Qt.Unchecked);
                            break;
                        } else if (string_value.starts_with (path)) {
                            item.check_state (0, Qt.PartiallyChecked);
                        }
                    }
                } else if (parent.check_state (0) == Qt.Unchecked) {
                    item.check_state (0, Qt.Unchecked);
                }
                item.icon (0, folder_icon);
                item.on_signal_text (0, path_trail.first ());
                if (size >= 0) {
                    item.on_signal_text (1, Utility.octets_to_string (size));
                    item.data (1, Qt.USER_ROLE, size);
                }
                //            item.data (0, Qt.USER_ROLE, path_trail.first ());
                item.child_indicator_policy (QTreeWidgetItem.ShowIndicator);
            }

            path_trail.remove_first ();
            recursive_insert (item, path_trail, path, size);
        }
    }

} // class SelectiveSyncWidget

} // namespace Ui
} // namespace Occ
