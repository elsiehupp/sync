/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The Selective_sync_widget contains a folder tree with labels
@ingroup gui
***********************************************************/
class Selective_sync_widget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public Selective_sync_widget (AccountPointer account, Gtk.Widget parent = nullptr);

    /// Returns a list of blocklisted paths, each including the trailing /
    public string[] create_block_list (QTree_widget_item root = nullptr);


    /***********************************************************
    Returns the old_block_list passed into set_folder_info (), except that
    a "/" entry is expanded to all top-level folder names.
    ***********************************************************/
    public string[] old_block_list ();

    // Estimates the total size of checked items (recursively)
    public int64 estimated_size (QTree_widget_item root = nullptr);

    // old_block_list is a list of excluded paths, each including a trailing /
    public void set_folder_info (string folder_path, string root_name,
        const string[] old_block_list = string[] ());

    /***********************************************************
    ***********************************************************/
    public QSize size_hint () override;

    /***********************************************************
    ***********************************************************/
    private void on_update_directories (string[]);
    private void on_item_expanded (QTree_widget_item *);
    private void on_item_changed (QTree_widget_item *, int);
    private void on_lscol_finished_with_error (Soup.Reply *);
    private void on_gather_encrypted_paths (string , GLib.HashMap<string, string> &);


    /***********************************************************
    ***********************************************************/
    private void refresh_folders ();

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private string this.folder_path;
    private string this.root_name;
    private string[] this.old_block_list;

    /***********************************************************
    ***********************************************************/
    private bool this.inserting; // set to true when we are inserting new items on the list

    /***********************************************************
    ***********************************************************/
    private 
    private QTree_widget this.folder_tree;

    // During account setup we want to filter out excluded folders from the
    // view without having a Folder.SyncEngine.ExcludedFiles instance.
    private ExcludedFiles this.excluded_files;

    /***********************************************************
    ***********************************************************/
    private string[] this.encrypted_paths;
}





    Selective_sync_widget.Selective_sync_widget (AccountPointer account, Gtk.Widget parent)
        : Gtk.Widget (parent)
        , this.account (account)
        , this.inserting (false)
        , this.folder_tree (new QTree_widget (this)) {
        this.loading = new QLabel (_("Loading …"), this.folder_tree);

        var layout = new QVBoxLayout (this);
        layout.set_contents_margins (0, 0, 0, 0);

        var header = new QLabel (this);
        header.on_set_text (_("Deselect remote folders you do not wish to synchronize."));
        header.set_word_wrap (true);
        layout.add_widget (header);

        layout.add_widget (this.folder_tree);

        connect (this.folder_tree, &QTree_widget.item_expanded,
            this, &Selective_sync_widget.on_item_expanded);
        connect (this.folder_tree, &QTree_widget.item_changed,
            this, &Selective_sync_widget.on_item_changed);
        this.folder_tree.set_sorting_enabled (true);
        this.folder_tree.sort_by_column (0, Qt.Ascending_order);
        this.folder_tree.set_column_count (2);
        this.folder_tree.header ().set_section_resize_mode (0, QHeaderView.QHeaderView.Resize_to_contents);
        this.folder_tree.header ().set_section_resize_mode (1, QHeaderView.QHeaderView.Resize_to_contents);
        this.folder_tree.header ().set_stretch_last_section (true);
        this.folder_tree.header_item ().on_set_text (0, _("Name"));
        this.folder_tree.header_item ().on_set_text (1, _("Size"));

        ConfigFile.setup_default_exclude_file_paths (this.excluded_files);
        this.excluded_files.on_reload_exclude_files ();
    }

    QSize Selective_sync_widget.size_hint () {
        return Gtk.Widget.size_hint ().expanded_to (QSize (600, 600));
    }

    void Selective_sync_widget.refresh_folders () {
        this.encrypted_paths.clear ();

        var job = new LsColJob (this.account, this.folder_path, this);
        var props = GLib.List<GLib.ByteArray> () << "resourcetype"
                                         << "http://owncloud.org/ns:size";
        if (this.account.capabilities ().client_side_encryption_available ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
        job.set_properties (props);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Selective_sync_widget.on_update_directories);
        connect (job, &LsColJob.finished_with_error,
            this, &Selective_sync_widget.on_lscol_finished_with_error);
        connect (job, &LsColJob.directory_listing_iterated,
            this, &Selective_sync_widget.on_gather_encrypted_paths);
        job.on_start ();
        this.folder_tree.clear ();
        this.loading.show ();
        this.loading.move (10, this.folder_tree.header ().height () + 10);
    }

    void Selective_sync_widget.set_folder_info (string folder_path, string root_name, string[] old_block_list) {
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
    static QTree_widget_item find_first_child (QTree_widget_item parent, string text) {
        for (int i = 0; i < parent.child_count (); ++i) {
            QTree_widget_item child = parent.child (i);
            if (child.text (0) == text) {
                return child;
            }
        }
        return nullptr;
    }

    void Selective_sync_widget.recursive_insert (QTree_widget_item parent, string[] path_trail, string path, int64 size) {
        QFile_icon_provider prov;
        QIcon folder_icon = prov.icon (QFile_icon_provider.Folder);
        if (path_trail.size () == 0) {
            if (path.ends_with ('/')) {
                path.chop (1);
            }
            parent.set_tool_tip (0, path);
            parent.set_data (0, Qt.User_role, path);
        } else {
            var item = static_cast<Selective_sync_tree_view_item> (find_first_child (parent, path_trail.first ()));
            if (!item) {
                item = new Selective_sync_tree_view_item (parent);
                if (parent.check_state (0) == Qt.Checked
                    || parent.check_state (0) == Qt.Partially_checked) {
                    item.set_check_state (0, Qt.Checked);
                    foreach (string string_value, this.old_block_list) {
                        if (string_value == path || string_value == QLatin1String ("/")) {
                            item.set_check_state (0, Qt.Unchecked);
                            break;
                        } else if (string_value.starts_with (path)) {
                            item.set_check_state (0, Qt.Partially_checked);
                        }
                    }
                } else if (parent.check_state (0) == Qt.Unchecked) {
                    item.set_check_state (0, Qt.Unchecked);
                }
                item.set_icon (0, folder_icon);
                item.on_set_text (0, path_trail.first ());
                if (size >= 0) {
                    item.on_set_text (1, Utility.octets_to_string (size));
                    item.set_data (1, Qt.User_role, size);
                }
                //            item.set_data (0, Qt.User_role, path_trail.first ());
                item.set_child_indicator_policy (QTree_widget_item.Show_indicator);
            }

            path_trail.remove_first ();
            recursive_insert (item, path_trail, path, size);
        }
    }

    void Selective_sync_widget.on_update_directories (string[] list) {
        var job = qobject_cast<LsColJob> (sender ());
        QScoped_value_rollback<bool> is_inserting (this.inserting);
        this.inserting = true;

        var root = static_cast<Selective_sync_tree_view_item> (this.folder_tree.top_level_item (0));

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
            this.loading.on_set_text (_("No subfolders currently on the server."));
            this.loading.resize (this.loading.size_hint ()); // because it's not in a layout
            return;
        } else {
            this.loading.hide ();
        }

        if (!root) {
            root = new Selective_sync_tree_view_item (this.folder_tree);
            root.on_set_text (0, this.root_name);
            root.set_icon (0, Theme.instance ().application_icon ());
            root.set_data (0, Qt.User_role, "");
            root.set_check_state (0, Qt.Checked);
            int64 size = job ? job._folder_infos[path_to_remove].size : -1;
            if (size >= 0) {
                root.on_set_text (1, Utility.octets_to_string (size));
                root.set_data (1, Qt.User_role, size);
            }
        }

        Utility.sort_filenames (list);
        foreach (string path, list) {
            var size = job ? job._folder_infos[path].size : 0;
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
                root.set_check_state (0, Qt.Partially_checked);
                break;
            }
        }

        root.set_expanded (true);
    }

    void Selective_sync_widget.on_lscol_finished_with_error (Soup.Reply r) {
        if (r.error () == Soup.Reply.ContentNotFoundError) {
            this.loading.on_set_text (_("No subfolders currently on the server."));
        } else {
            this.loading.on_set_text (_("An error occurred while loading the list of sub folders."));
        }
        this.loading.resize (this.loading.size_hint ()); // because it's not in a layout
    }

    void Selective_sync_widget.on_gather_encrypted_paths (string path, GLib.HashMap<string, string> properties) {
        const var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }

        const var webdav_folder = GLib.Uri (this.account.dav_url ()).path ();
        Q_ASSERT (path.starts_with (webdav_folder));
        // This dialog use the postfix / convention for folder paths
        this.encrypted_paths << path.mid (webdav_folder.size ()) + '/';
    }

    void Selective_sync_widget.on_item_expanded (QTree_widget_item item) {
        string dir = item.data (0, Qt.User_role).to_string ();
        if (dir.is_empty ())
            return;
        string prefix;
        if (!this.folder_path.is_empty ()) {
            prefix = this.folder_path + '/';
        }
        var job = new LsColJob (this.account, prefix + dir, this);
        job.set_properties (GLib.List<GLib.ByteArray> () << "resourcetype"
                                               << "http://owncloud.org/ns:size");
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Selective_sync_widget.on_update_directories);
        job.on_start ();
    }

    void Selective_sync_widget.on_item_changed (QTree_widget_item item, int col) {
        if (col != 0 || this.inserting)
            return;

        if (item.check_state (0) == Qt.Checked) {
            // If we are checked, check that we may need to check the parent as well if
            // all the siblings are also checked
            QTree_widget_item parent = item.parent ();
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
            QTree_widget_item parent = item.parent ();
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
            QTree_widget_item parent = item.parent ();
            if (parent && parent.check_state (0) != Qt.Partially_checked) {
                parent.set_check_state (0, Qt.Partially_checked);
            }
        }
    }

    string[] Selective_sync_widget.create_block_list (QTree_widget_item root) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
        }
        if (!root)
            return string[] ();

        switch (root.check_state (0)) {
        case Qt.Unchecked:
            return string[] (root.data (0, Qt.User_role).to_string () + "/");
        case Qt.Checked:
            return string[] ();
        case Qt.Partially_checked:
            break;
        }

        string[] result;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                result += create_block_list (root.child (i));
            }
        } else {
            // We did not load from the server so we re-use the one from the old block list
            string path = root.data (0, Qt.User_role).to_string ();
            foreach (string it, this.old_block_list) {
                if (it.starts_with (path))
                    result += it;
            }
        }
        return result;
    }

    string[] Selective_sync_widget.old_block_list () {
        return this.old_block_list;
    }

    int64 Selective_sync_widget.estimated_size (QTree_widget_item root) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
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