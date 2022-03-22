/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>

@copyright GPLv3 or Later
***********************************************************/

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief page to ask for the target folder
@ingroup gui
***********************************************************/
public class FolderWizardRemotePath : FormatWarningsWizardPage {

    /***********************************************************
    ***********************************************************/
    private Ui_Folder_wizard_target_page ui;
    private bool warn_was_visible;
    private unowned Account account;
    private GLib.Timeout lscol_timer;
    private string[] encrypted_paths;

    /***********************************************************
    ***********************************************************/
    public FolderWizardRemotePath (unowned Account account) {
        base ();
        this.warn_was_visible = false;
        this.account = account;
        this.ui.up_ui (this);
        this.ui.warn_frame.hide ();

        this.ui.folder_tree_widget.sorting_enabled (true);
        this.ui.folder_tree_widget.sort_by_column (0, Qt.AscendingOrder);

        this.ui.add_folder_button.clicked.connect (
            this.on_signal_add_remote_folder
        );
        this.ui.refresh_button.clicked.connect (
            this.on_signal_refresh_folders
        );
        this.ui.folder_tree_widget.item_expanded.connect (
            this.on_signal_item_expanded
        );
        this.ui.folder_tree_widget.current_item_changed.connect (
            this.on_signal_current_item_changed
        );
        this.ui.folder_entry.text_edited.connect (
            this.on_signal_folder_entry_edited
        );

        this.lscol_timer.interval (500);
        this.lscol_timer.single_shot (true);
        this.lscol_timer.timeout.connect (
            this.on_signal_lscol_folder_entry
        );

        this.ui.folder_tree_widget.header ().section_resize_mode (0, QHeaderView.ResizeToContents);
        // Make sure that there will be a scrollbar when the contents is too wide
        this.ui.folder_tree_widget.header ().stretch_last_section (false);
    }

    /***********************************************************
    ***********************************************************/
    public bool is_complete {
        public get {
            if (!this.ui.folder_tree_widget.current_item ())
                return false;

            string[] warn_strings;
            string directory = this.ui.folder_tree_widget.current_item ().data (0, Qt.USER_ROLE).to_string ();
            if (!directory.starts_with ('/')) {
                directory.prepend ('/');
            }
            wizard ().property ("target_path", directory);

            Folder.Map map = FolderMan.instance.map ();
            Folder.Map.ConstIterator i = map.const_begin ();
            for (i = map.const_begin (); i != map.const_end (); i++) {
                var f = static_cast<Folder> (i.value ());
                if (f.account_state.account != this.account) {
                    continue;
                }
                string cur_dir = f.remote_path_trailing_slash;
                if (GLib.Dir.clean_path (directory) == GLib.Dir.clean_path (cur_dir)) {
                    warn_strings.append (_("This folder is already being synced."));
                } else if (directory.starts_with (cur_dir)) {
                    warn_strings.append (_("You are already syncing <i>%1</i>, which is a parent folder of <i>%2</i>.").printf (Utility.escape (cur_dir), Utility.escape (directory)));
                } else if (cur_dir.starts_with (directory)) {
                    warn_strings.append (_("You are already syncing <i>%1</i>, which is a subfolder of <i>%2</i>.").printf (Utility.escape (cur_dir), Utility.escape (directory)));
                }
            }

            on_signal_show_warning (format_warnings (warn_strings));
            return true;
        }
    }

    /***********************************************************
    ***********************************************************/
    public override void initialize_page () {
        on_signal_show_warning ();
        on_signal_refresh_folders ();
    }


    /***********************************************************
    ***********************************************************/
    public override void clean_up_page () {
        on_signal_show_warning ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_show_warning (string message = "") {
        if (message == "") {
            this.ui.warn_frame.hide ();

        } else {
            this.ui.warn_frame.show ();
            this.ui.warn_label.on_signal_text (message);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_add_remote_folder () {
        QTreeWidgetItem current = this.ui.folder_tree_widget.current_item ();

        string parent = '/';
        if (current) {
            parent = current.data (0, Qt.USER_ROLE).to_string ();
        }

        var dialog = new QInputDialog (this);

        dialog.window_title (_("Create Remote Folder"));
        dialog.label_text (_("Enter the name of the new folder to be created below \"%1\":")
                              .printf (parent));
        dialog.open (this, SLOT (on_signal_create_remote_folder (string)));
        dialog.attribute (Qt.WA_DeleteOnClose);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_create_remote_folder (string folder) {
        if (folder == "")
            return;

        QTreeWidgetItem current = this.ui.folder_tree_widget.current_item ();
        string full_path;
        if (current) {
            full_path = current.data (0, Qt.USER_ROLE).to_string ();
        }
        full_path += "/" + folder;

        var mkcol_job = new MkColJob (this.account, full_path, this);
        /* check the owncloud configuration file and query the own_cloud */
        mkcol_job.signal_finished_without_error.connect (
            this.on_signal_create_remote_folder_finished
        );
        mkcol_job.signal_network_error.connect (
            this.on_signal_handle_mkdir_network_error
        );
        mkcol_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_create_remote_folder_finished () {
        GLib.debug ("webdav mkdir request on_signal_finished");
        on_signal_show_warning (_("Folder was successfully created on %1.").printf (Theme.app_name_gui));
        on_signal_refresh_folders ();
        this.ui.folder_entry.on_signal_text (static_cast<MkColJob> (sender ()).path);
        on_signal_lscol_folder_entry ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_handle_mkdir_network_error (GLib.InputStream reply) {
        GLib.warning ("webdav mkdir request failed: " + reply.error);
        if (!this.account.credentials ().still_valid (reply)) {
            on_signal_show_warning (_("Authentication failed accessing %1").printf (Theme.app_name_gui));
        } else {
            on_signal_show_warning (_("Failed to create the folder on %1. Please check manually.")
                         .printf (Theme.app_name_gui));
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_handle_lscol_network_error (GLib.InputStream reply) {
        // Ignore 404s, otherwise users will get annoyed by error popups
        // when not typing fast enough. It's still clear that a given path
        // was not found, because the 'Next' button is disabled and no entry
        // is selected in the tree view.
        int http_code = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (http_code == 404) {
            on_signal_show_warning (""); // hides the warning pane
            return;
        }
        var lscol_job = qobject_cast<LscolJob> (sender ());
        //  ASSERT (lscol_job);
        on_signal_show_warning (_("Failed to list a folder. Error : %1")
                     .printf (lscol_job.error_string_parsing_body ()));
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_update_directories (string[] list) {
        string webdav_folder = GLib.Uri (this.account.dav_url ()).path;

        QTreeWidgetItem root = this.ui.folder_tree_widget.top_level_item (0);
        if (!root) {
            root = new QTreeWidgetItem (this.ui.folder_tree_widget);
            root.on_signal_text (0, Theme.app_name_gui);
            root.icon (0, Theme.application_icon);
            root.tool_tip (0, _("Choose this to sync the entire account"));
            root.data (0, Qt.USER_ROLE, "/");
        }
        string[] sorted_list = list;
        Utility.sort_filenames (sorted_list);
        foreach (string path in sorted_list) {
            path.remove (webdav_folder);

            // Don't allow to select subfolders of encrypted subfolders
            //  const var is_any_ancestor_encrypted = std.any_of (
            //      std.cbegin (this.encrypted_paths),
            //      std.cend (this.encrypted_paths), [=] (string encrypted_path) {
            //      return path.size () > encrypted_path.size () && path.starts_with (encrypted_path);
            //  });
            if (is_any_ancestor_encrypted) {
                continue;
            }

            string[] paths = path.split ('/');
            if (paths.last () == "")
                paths.remove_last ();
            recursive_insert (root, paths, path);
        }
        root.expanded (true);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_gather_encrypted_paths (string path, GLib.HashTable<string, string> properties) {
        const var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != "1") {
            return;
        }

        const var webdav_folder = GLib.Uri (this.account.dav_url ()).path;
        //  Q_ASSERT (path.starts_with (webdav_folder));
        this.encrypted_paths + path.mid (webdav_folder.size ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_refresh_folders () {
        this.encrypted_paths.clear ();
        run_lscol_job ("/");
        this.ui.folder_tree_widget.clear ();
        this.ui.folder_entry.clear ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_item_expanded (QTreeWidgetItem item) {
        string directory = item.data (0, Qt.USER_ROLE).to_string ();
        run_lscol_job (directory);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_current_item_changed (QTreeWidgetItem item) {
        if (item) {
            string directory = item.data (0, Qt.USER_ROLE).to_string ();

            // We don't want to allow creating subfolders in encrypted folders outside of the sync logic
            const var encrypted = this.encrypted_paths.contains (directory);
            this.ui.add_folder_button.enabled (!encrypted);

            if (!directory.starts_with ('/')) {
                directory.prepend ('/');
            }
            this.ui.folder_entry.on_signal_text (directory);
        }

        /* emit */ complete_changed ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_folder_entry_edited (string text) {
        if (select_by_path (text)) {
            this.lscol_timer.stop ();
            return;
        }

        this.ui.folder_tree_widget.current_item (null);
        this.lscol_timer.on_signal_start (); // avoid sending a request on each keystroke
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_lscol_folder_entry () {
        string path = this.ui.folder_entry.text ();
        if (path.starts_with ('/'))
            path = path.mid (1);

        LscolJob lscol_job = run_lscol_job (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (lscol_job, null, this, null);
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_handle_lscol_network_error
        );
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_typed_path_found
        );
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_typed_path_found (string[] subpaths) {
        on_signal_update_directories (subpaths);
        select_by_path (this.ui.folder_entry.text ());
    }


    /***********************************************************
    ***********************************************************/
    private LscolJob run_lscol_job (string path) {
        var lscol_job = new LscolJob (this.account, path, this);
        var props = new GLib.List<string> ({ "resourcetype" });
        if (this.account.capabilities.client_side_encryption_available ()) {
            props += "http://nextcloud.org/ns:is-encrypted";
        }
        lscol_job.properties (props);
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_update_directories
        );
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_handle_lscol_network_error
        );
        lscol_job.signal_directory_listing_iterated.connect (
            this.on_signal_gather_encrypted_paths
        );
        lscol_job.on_signal_start ();

        return lscol_job;
    }


    /***********************************************************
    ***********************************************************/
    private void recursive_insert (QTreeWidgetItem parent, string[] path_trail, string path) {
        if (path_trail == "")
            return;

        const string parent_path = parent.data (0, Qt.USER_ROLE).to_string ();
        const string folder_name = path_trail.first ();
        string folder_path;
        if (parent_path == "/") {
            folder_path = folder_name;
        } else {
            folder_path = parent_path + "/" + folder_name;
        }
        QTreeWidgetItem item = find_first_child (parent, folder_name);
        if (!item) {
            item = new QTreeWidgetItem (parent);
            QFileIconProvider prov;
            Gtk.Icon folder_icon = prov.icon (QFileIconProvider.Folder);
            item.icon (0, folder_icon);
            item.on_signal_text (0, folder_name);
            item.data (0, Qt.USER_ROLE, folder_path);
            item.tool_tip (0, folder_path);
            item.child_indicator_policy (QTreeWidgetItem.ShowIndicator);
        }

        path_trail.remove_first ();
        recursive_insert (item, path_trail, path);
    }


    /***********************************************************
    ***********************************************************/
    private bool select_by_path (string path) {
        if (path.starts_with ('/')) {
            path = path.mid (1);
        }
        if (path.ends_with ('/')) {
            path.chop (1);
        }

        QTreeWidgetItem it = this.ui.folder_tree_widget.top_level_item (0);
        if (!path == "") {
            const string[] path_trail = path.split ('/');
            foreach (string path in path_trail) {
                if (!it) {
                    return false;
                }
                it = find_first_child (it, path);
            }
        }
        if (!it) {
            return false;
        }

        this.ui.folder_tree_widget.current_item (it);
        this.ui.folder_tree_widget.scroll_to_item (it);
        return true;
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

} // class FolderWizardRemotePath

} // namespace Ui
} // namespace Occ
