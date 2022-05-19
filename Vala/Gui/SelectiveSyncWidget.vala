/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SelectiveSyncWidget contains a folder tree with labels
@ingroup gui
***********************************************************/
public class SelectiveSyncWidget : Gtk.Widget {
    /***********************************************************
    ***********************************************************/
    private string folder_path;
    private string root_name;
    private GLib.List<string> old_block_list;

    /***********************************************************
    Set to true when we are inserting new items on the list
    ***********************************************************/
    private bool inserting;

    /***********************************************************
    ***********************************************************/
    private GLib.TreeWidget folder_tree;

    /***********************************************************
    During account setup we want to filter out excluded folders
    from the view without having a
    FolderConnection.LibSync.SyncEngine.CSync.ExcludedFiles instance.
    ***********************************************************/
    private CSync.ExcludedFiles excluded_files;

    /***********************************************************
    ***********************************************************/
    private GLib.List<string> encrypted_paths;

    /***********************************************************
    ***********************************************************/
    public SelectiveSyncWidget (LibSync.Account account, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.account = account;
        this.inserting = false;
        this.folder_tree = new GLib.TreeWidget (this);
        this.loading = new Gtk.Label (_("Loading …"), this.folder_tree);

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL);
        layout.contents_margins (0, 0, 0, 0);

        var header = new Gtk.Label (this);
        header.on_signal_text (_("Deselect remote folders you do not wish to synchronize."));
        header.word_wrap (true);
        layout.add_widget (header);

        layout.add_widget (this.folder_tree);

        this.folder_tree.item_expanded.connect (
            this.on_signal_item_expanded
        );
        this.folder_tree.item_changed.connect (
            this.on_signal_item_changed
        );
        this.folder_tree.sorting_enabled (true);
        this.folder_tree.sort_by_column (0, GLib.AscendingOrder);
        this.folder_tree.column_count (2);
        this.folder_tree.header ().section_resize_mode (0, GLib.HeaderView.GLib.HeaderView.ResizeToContents);
        this.folder_tree.header ().section_resize_mode (1, GLib.HeaderView.GLib.HeaderView.ResizeToContents);
        this.folder_tree.header ().stretch_last_section (true);
        this.folder_tree.header_item ().on_signal_text (0, _("Name"));
        this.folder_tree.header_item ().on_signal_text (1, _("Size"));

        LibSync.ConfigFile.set_up_default_exclude_file_paths (this.excluded_files);
        this.excluded_files.on_signal_reload_exclude_files ();
    }


    /***********************************************************
    Returns a list of blocklisted paths, each including the
    trailing "/"
    ***********************************************************/
    public GLib.List<string> create_block_list (GLib.TreeWidgetItem root = null) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
        }
        if (!root) {
            return GLib.List<string> ();
        }
        switch (root.check_state (0)) {
        case GLib.Unchecked:
            return GLib.List<string> (root.data (0, GLib.USER_ROLE).to_string () + "/");
        case GLib.Checked:
            return GLib.List<string> ();
        case GLib.PartiallyChecked:
            break;
        }

        GLib.List<string> result;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                result += create_block_list (root.child (i));
            }
        } else {
            // We did not load from the server so we re-use the one from the old block list
            string path = root.data (0, GLib.USER_ROLE).to_string ();
            foreach (string it in this.old_block_list) {
                if (it.has_prefix (path)) {
                    result += it;
                }
            }
        }
        return result;
    }


    /***********************************************************
    Returns the old_block_list passed into folder_info (), except that
    a "/" entry is expanded to all top-level folder names.
    ***********************************************************/
    public GLib.List<string> old_block_list () {
        return this.old_block_list;
    }


    /***********************************************************
    Estimates the total size of checked items (recursively)
    ***********************************************************/
    public int64 estimated_size (GLib.TreeWidgetItem root = null) {
        if (!root) {
            root = this.folder_tree.top_level_item (0);
        }
        if (!root) {
            return -1;
        }
        switch (root.check_state (0)) {
        case GLib.Unchecked:
            return 0;
        case GLib.Checked:
            return root.data (1, GLib.USER_ROLE).to_long_long ();
        case GLib.PartiallyChecked:
            break;
        }

        int64 result = 0;
        if (root.child_count ()) {
            for (int i = 0; i < root.child_count (); ++i) {
                var r = estimated_size (root.child (i));
                if (r < 0) {
                    return r;
                }
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
    a trailing "/"
    ***********************************************************/
    public void folder_info (
        string folder_path, string root_name,
        GLib.List<string> old_block_list = new GLib.List<string> ()) {
        this.folder_path = folder_path;
        if (this.folder_path.has_prefix ("/")) {
            // remove leading "/"
            this.folder_path = folder_path.mid (1);
        }
        this.root_name = root_name;
        this.old_block_list = old_block_list;
        refresh_folders ();
    }


    /***********************************************************
    ***********************************************************/
    public override Gdk.Rectangle size_hint () {
        return Gtk.Widget.size_hint ().expanded_to (Gdk.Rectangle (600, 600));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_directories (LibSync.LscolJob lscol_job, GLib.List<string> list) {
        var lscol_job = (LibSync.LscolJob)sender ();
        GLib.ScopedValueRollback<bool> is_inserting (this.inserting);
        this.inserting = true;

        var root = (SelectiveSyncTreeViewItem)this.folder_tree.top_level_item (0);

        GLib.Uri url = this.account.dav_url ();
        string path_to_remove = url.path;
        if (!path_to_remove.has_suffix ("/")) {
            path_to_remove.append ("/");
        }
        path_to_remove.append (this.folder_path);
        if (!this.folder_path == "") {
            path_to_remove.append ("/");
        }
        // Check for excludes.
        GLib.MutableListIterator<string> it (list);
        while (it.has_next ()) {
            it.next ();
            if (this.excluded_files.is_excluded (it.value (), path_to_remove, FolderManager.instance.ignore_hidden_files)) {
                it.remove ();
            }
        }

        // Since / cannot be in the blocklist, expand it to the actual
        // list of top-level folders as soon as possible.
        if (this.old_block_list == new GLib.List<string> ("/")) {
            this.old_block_list = "";
            foreach (string path, list) {
                path.remove (path_to_remove);
                if (path == "") {
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
            root.icon (0, LibSync.Theme.application_icon);
            root.data (0, GLib.USER_ROLE, "");
            root.check_state (0, GLib.Checked);
            int64 size = lscol_job ? lscol_job.folder_infos[path_to_remove].size : -1;
            if (size >= 0) {
                root.on_signal_text (1, Utility.octets_to_string (size));
                root.data (1, GLib.USER_ROLE, size);
            }
        }

        Utility.sort_filenames (list);
        foreach (string path, list) {
            var size = lscol_job ? lscol_job.folder_infos[path].size : 0;
            path.remove (path_to_remove);

            // Don't allow to select subfolders of encrypted subfolders
            var is_any_ancestor_encrypted = std.any_of (std.cbegin (this.encrypted_paths), std.cend (this.encrypted_paths), [=] (string encrypted_path) {
                return path.size () > encrypted_path.size () && path.has_prefix (encrypted_path);
            });
            if (is_any_ancestor_encrypted) {
                continue;
            }

            GLib.List<string> paths = path.split ("/");
            if (paths.last () == "") {
                paths.remove_last ();
            }
            if (paths == "") {
                continue;
            }
            if (!path.has_suffix ("/")) {
                path.append ("/");
            }
            recursive_insert (root, paths, path, size);
        }

        // Root is partially checked if any children are not checked
        for (int i = 0; i < root.child_count (); ++i) {
            var child = root.child (i);
            if (child.check_state (0) != GLib.Checked) {
                root.check_state (0, GLib.PartiallyChecked);
                break;
            }
        }

        root.expanded (true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_expanded (GLib.TreeWidgetItem item) {
        string directory = item.data (0, GLib.USER_ROLE).to_string ();
        if (directory == "") {
            return;
        }
        string prefix;
        if (!this.folder_path == "") {
            prefix = this.folder_path + "/";
        }
        var lscol_job = new LibSync.LscolJob (this.account, prefix + directory, this);
        lscol_job.properties (
            {
                "resourcetype",
                "http://owncloud.org/ns:size"
            }
        );
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_update_directories
        );
        lscol_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_changed (GLib.TreeWidgetItem item, int col) {
        if (col != 0 || this.inserting) {
            return;
        }
        if (item.check_state (0) == GLib.Checked) {
            // If we are checked, check that we may need to check the parent as well if
            // all the siblings are also checked
            GLib.TreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) != GLib.Checked) {
                bool has_unchecked = false;
                for (int i = 0; i < parent.child_count (); ++i) {
                    if (parent.child (i).check_state (0) != GLib.Checked) {
                        has_unchecked = true;
                        break;
                    }
                }
                if (!has_unchecked) {
                    parent.check_state (0, GLib.Checked);
                } else if (parent.check_state (0) == GLib.Unchecked) {
                    parent.check_state (0, GLib.PartiallyChecked);
                }
            }
            // also check all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != GLib.Checked) {
                    item.child (i).check_state (0, GLib.Checked);
                }
            }
        }

        if (item.check_state (0) == GLib.Unchecked) {
            GLib.TreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) == GLib.Checked) {
                parent.check_state (0, GLib.PartiallyChecked);
            }

            // Uncheck all the children
            for (int i = 0; i < item.child_count (); ++i) {
                if (item.child (i).check_state (0) != GLib.Unchecked) {
                    item.child (i).check_state (0, GLib.Unchecked);
                }
            }

            // Can't uncheck the root.
            if (!parent) {
                item.check_state (0, GLib.PartiallyChecked);
            }
        }

        if (item.check_state (0) == GLib.PartiallyChecked) {
            GLib.TreeWidgetItem parent = item.parent ();
            if (parent && parent.check_state (0) != GLib.PartiallyChecked) {
                parent.check_state (0, GLib.PartiallyChecked);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_finished_with_error (GLib.InputStream r) {
        if (r.error == GLib.InputStream.ContentNotFoundError) {
            this.loading.on_signal_text (_("No subfolders currently on the server."));
        } else {
            this.loading.on_signal_text (_("An error occurred while loading the list of sub folders."));
        }
        this.loading.resize (this.loading.size_hint ()); // because it's not in a layout
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_gather_encrypted_paths (string path, GLib.HashTable<string, string> properties) {
        var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != "1") {
            return;
        }

        var webdav_folder = GLib.Uri (this.account.dav_url ()).path;
        //  GLib.assert_true (path.has_prefix (webdav_folder));
        // This dialog use the postfix / convention for folder paths
        this.encrypted_paths + path.mid (webdav_folder.size ()) + "/";
    }


    /***********************************************************
    ***********************************************************/
    private void refresh_folders () {
        this.encrypted_paths = "";

        var lscol_job = new LibSync.LscolJob (this.account, this.folder_path, this);
        var props = new GLib.List<string> ();
        props.append ("resourcetype");
        props.append ("http://owncloud.org/ns:size");
        if (this.account.capabilities.client_side_encryption_available) {
            props + "http://nextcloud.org/ns:is-encrypted";
        }
        lscol_job.properties (props);
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_update_directories
        );
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_lscol_finished_with_error
        );
        lscol_job.signal_directory_listing_iterated.connect (
            this.on_signal_gather_encrypted_paths
        );
        lscol_job.on_signal_start ();
        this.folder_tree = "";
        this.loading.show ();
        this.loading.move (10, this.folder_tree.header ().height () + 10);
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.TreeWidgetItem find_first_child (GLib.TreeWidgetItem parent, string text) {
        for (int i = 0; i < parent.child_count (); ++i) {
            GLib.TreeWidgetItem child = parent.child (i);
            if (child.text (0) == text) {
                return child;
            }
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private static void SelectiveSyncWidget.recursive_insert (GLib.TreeWidgetItem parent, GLib.List<string> path_trail, string path, int64 size) {
        GLib.FileIconProvider prov;
        Gtk.IconInfo folder_icon = prov.icon (GLib.FileIconProvider.FolderConnection);
        if (path_trail.size () == 0) {
            if (path.has_suffix ("/")) {
                path.chop (1);
            }
            parent.tool_tip (0, path);
            parent.data (0, GLib.USER_ROLE, path);
        } else {
            var item = (SelectiveSyncTreeViewItem)find_first_child (parent, path_trail.nth_data (0));
            if (!item) {
                item = new SelectiveSyncTreeViewItem (parent);
                if (parent.check_state (0) == GLib.Checked
                    || parent.check_state (0) == GLib.PartiallyChecked) {
                    item.check_state (0, GLib.Checked);
                    foreach (string string_value, this.old_block_list) {
                        if (string_value == path || string_value == "/") {
                            item.check_state (0, GLib.Unchecked);
                            break;
                        } else if (string_value.has_prefix (path)) {
                            item.check_state (0, GLib.PartiallyChecked);
                        }
                    }
                } else if (parent.check_state (0) == GLib.Unchecked) {
                    item.check_state (0, GLib.Unchecked);
                }
                item.icon (0, folder_icon);
                item.on_signal_text (0, path_trail.nth_data (0));
                if (size >= 0) {
                    item.on_signal_text (1, Utility.octets_to_string (size));
                    item.data (1, GLib.USER_ROLE, size);
                }
                //            item.data (0, GLib.USER_ROLE, path_trail.nth_data (0));
                item.child_indicator_policy (GLib.TreeWidgetItem.ShowIndicator);
            }

            path_trail.remove_first ();
            recursive_insert (item, path_trail, path, size);
        }
    }

} // class SelectiveSyncWidget

} // namespace Ui
} // namespace Occ
