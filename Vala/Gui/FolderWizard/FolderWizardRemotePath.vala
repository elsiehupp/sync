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
    private Ui_Folder_wizard_target_page instance;
    private bool warn_was_visible;
    private LibSync.Account account;
    private bool lscol_timer_active = false;
    private bool lscol_timer_repeat = false;
    private GLib.List<string> encrypted_paths;

    /***********************************************************
    ***********************************************************/
    public FolderWizardRemotePath (LibSync.Account account) {
        base ();
        this.warn_was_visible = false;
        this.account = account;
        this.instance.up_ui (this);
        this.instance.warn_frame.hide ();

        this.instance.folder_tree_widget.sorting_enabled (true);
        this.instance.folder_tree_widget.sort_by_column (0, GLib.AscendingOrder);

        this.instance.add_folder_button.clicked.connect (
            this.on_signal_add_remote_folder
        );
        this.instance.refresh_button.clicked.connect (
            this.on_signal_refresh_folders
        );
        this.instance.folder_tree_widget.item_expanded.connect (
            this.on_signal_item_expanded
        );
        this.instance.folder_tree_widget.current_item_changed.connect (
            this.on_signal_current_item_changed
        );
        this.instance.folder_entry.text_edited.connect (
            this.on_signal_folder_entry_edited
        );

        GLib.Timeout.add (
            500,
            this.on_signal_lscol_folder_entry
        );

        this.instance.folder_tree_widget.header ().section_resize_mode (0, GLib.HeaderView.ResizeToContents);
        // Make sure that there will be a scrollbar when the contents is too wide
        this.instance.folder_tree_widget.header ().stretch_last_section (false);
    }

    /***********************************************************
    ***********************************************************/
    public bool is_complete {
        public get {
            if (!this.instance.folder_tree_widget.current_item ())
                return false;

            GLib.List<string> warn_strings;
            string directory = this.instance.folder_tree_widget.current_item ().data (0, GLib.USER_ROLE).to_string ();
            if (!directory.has_prefix ("/")) {
                directory.prepend ("/");
            }
            wizard ().property ("target_path", directory);

            FolderConnection.Map map = FolderManager.instance.map ();
            FolderConnection.Map.ConstIterator i = map.const_begin ();
            for (i = map.const_begin (); i != map.const_end (); i++) {
                var f = (FolderConnection)i.value ();
                if (f.account_state.account != this.account) {
                    continue;
                }
                string cur_dir = f.remote_path_trailing_slash;
                if (GLib.Dir.clean_path (directory) == GLib.Dir.clean_path (cur_dir)) {
                    warn_strings.append (_("This folder is already being synced."));
                } else if (directory.has_prefix (cur_dir)) {
                    warn_strings.append (_("You are already syncing <i>%1</i>, which is a parent folder of <i>%2</i>.").printf (Utility.escape (cur_dir), Utility.escape (directory)));
                } else if (cur_dir.has_prefix (directory)) {
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
            this.instance.warn_frame.hide ();

        } else {
            this.instance.warn_frame.show ();
            this.instance.warn_label.on_signal_text (message);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_add_remote_folder () {
        GLib.TreeWidgetItem current = this.instance.folder_tree_widget.current_item ();

        string parent = "/";
        if (current) {
            parent = current.data (0, GLib.USER_ROLE).to_string ();
        }

        var dialog = new GLib.InputDialog (this);

        dialog.window_title (_("Create Remote FolderConnection"));
        dialog.label_text (_("Enter the name of the new folder to be created below \"%1\":")
                              .printf (parent));
        dialog.open (this, SLOT (on_signal_create_remote_folder (string)));
        dialog.attribute (GLib.WA_DeleteOnClose);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_create_remote_folder (string folder) {
        if (folder == "")
            return;

        GLib.TreeWidgetItem current = this.instance.folder_tree_widget.current_item ();
        string full_path;
        if (current) {
            full_path = current.data (0, GLib.USER_ROLE).to_string ();
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
        GLib.debug ("webdav mkdir request finished");
        on_signal_show_warning (_("FolderConnection was successfully created on %1.").printf (LibSync.Theme.app_name_gui));
        on_signal_refresh_folders ();
        this.instance.folder_entry.on_signal_text (((MkColJob)sender ()).path);
        on_signal_lscol_folder_entry ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_handle_mkdir_network_error (GLib.InputStream reply) {
        GLib.warning ("webdav mkdir request failed: " + reply.error);
        if (!this.account.credentials ().still_valid (reply)) {
            on_signal_show_warning (_("Authentication failed accessing %1").printf (LibSync.Theme.app_name_gui));
        } else {
            on_signal_show_warning (_("Failed to create the folder on %1. Please check manually.")
                         .printf (LibSync.Theme.app_name_gui));
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
        var lscol_job = (LibSync.LscolJob)sender ();
        //  GLib.assert_true (lscol_job);
        on_signal_show_warning (_("Failed to list a folder. Error : %1")
                     .printf (lscol_job.error_string_parsing_body ()));
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_update_directories (LibSync.LscolJob lscol_job, GLib.List<string> list) {
        string webdav_folder = GLib.Uri (this.account.dav_url ()).path;

        GLib.TreeWidgetItem root = this.instance.folder_tree_widget.top_level_item (0);
        if (!root) {
            root = new GLib.TreeWidgetItem (this.instance.folder_tree_widget);
            root.on_signal_text (0, LibSync.Theme.app_name_gui);
            root.icon (0, LibSync.Theme.application_icon);
            root.tool_tip (0, _("Choose this to sync the entire account"));
            root.data (0, GLib.USER_ROLE, "/");
        }
        GLib.List<string> sorted_list = list;
        Utility.sort_filenames (sorted_list);
        foreach (string path in sorted_list) {
            path.remove (webdav_folder);

            // Don't allow to select subfolders of encrypted subfolders
            //  const var is_any_ancestor_encrypted = std.any_of (
            //      std.cbegin (this.encrypted_paths),
            //      std.cend (this.encrypted_paths), [=] (string encrypted_path) {
            //      return path.size () > encrypted_path.size () && path.has_prefix (encrypted_path);
            //  });
            if (is_any_ancestor_encrypted) {
                continue;
            }

            GLib.List<string> paths = path.split ("/");
            if (paths.last () == "")
                paths.remove_last ();
            recursive_insert (root, paths, path);
        }
        root.expanded (true);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_gather_encrypted_paths (string path, GLib.HashTable<string, string> properties) {
        var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != "1") {
            return;
        }

        var webdav_folder = GLib.Uri (this.account.dav_url ()).path;
        //  GLib.assert_true (path.has_prefix (webdav_folder));
        this.encrypted_paths + path.mid (webdav_folder.size ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_refresh_folders () {
        this.encrypted_paths = "";
        run_lscol_job ("/");
        this.instance.folder_tree_widget = "";
        this.instance.folder_entry = "";
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_item_expanded (GLib.TreeWidgetItem item) {
        string directory = item.data (0, GLib.USER_ROLE).to_string ();
        run_lscol_job (directory);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_current_item_changed (GLib.TreeWidgetItem item) {
        if (item) {
            string directory = item.data (0, GLib.USER_ROLE).to_string ();

            // We don't want to allow creating subfolders in encrypted folders outside of the sync logic
            var encrypted = this.encrypted_paths.contains (directory);
            this.instance.add_folder_button.enabled (!encrypted);

            if (!directory.has_prefix ("/")) {
                directory.prepend ("/");
            }
            this.instance.folder_entry.on_signal_text (directory);
        }

        signal_complete_changed ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_folder_entry_edited (string text) {
        if (select_by_path (text)) {
            this.lscol_timer_active = false;
            return;
        }

        this.instance.folder_tree_widget.current_item (null);

        // avoid sending a request on each keystroke
        this.lscol_timer_active = true;
        GLib.Timeout.add (
            500,
            this.on_signal_lscol_folder_entry
        );
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_lscol_folder_entry () {
        if (!lscol_timer_active) {
            return this.lscol_timer_repeat;
        }
        string path = this.instance.folder_entry.text ();
        if (path.has_prefix ("/"))
            path = path.mid (1);

        LibSync.LscolJob lscol_job = run_lscol_job (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (lscol_job, null, this, null);
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_handle_lscol_network_error
        );
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_typed_path_found
        );
        return this.lscol_timer_repeat;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_typed_path_found (GLib.List<string> subpaths) {
        on_signal_update_directories (subpaths);
        select_by_path (this.instance.folder_entry.text ());
    }


    /***********************************************************
    ***********************************************************/
    private LibSync.LscolJob run_lscol_job (string path) {
        var lscol_job = new LibSync.LscolJob (this.account, path, this);
        var props = new GLib.List<string> ({ "resourcetype" });
        if (this.account.capabilities.client_side_encryption_available) {
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
    private void recursive_insert (GLib.TreeWidgetItem parent, GLib.List<string> path_trail, string path) {
        if (path_trail == "")
            return;

        string parent_path = parent.data (0, GLib.USER_ROLE).to_string ();
        string folder_name = path_trail.nth_data (0);
        string folder_path;
        if (parent_path == "/") {
            folder_path = folder_name;
        } else {
            folder_path = parent_path + "/" + folder_name;
        }
        GLib.TreeWidgetItem item = find_first_child (parent, folder_name);
        if (!item) {
            item = new GLib.TreeWidgetItem (parent);
            GLib.FileIconProvider prov;
            Gtk.IconInfo folder_icon = prov.icon (GLib.FileIconProvider.FolderConnection);
            item.icon (0, folder_icon);
            item.on_signal_text (0, folder_name);
            item.data (0, GLib.USER_ROLE, folder_path);
            item.tool_tip (0, folder_path);
            item.child_indicator_policy (GLib.TreeWidgetItem.ShowIndicator);
        }

        path_trail.remove_first ();
        recursive_insert (item, path_trail, path);
    }


    /***********************************************************
    ***********************************************************/
    private bool select_by_path (string path) {
        if (path.has_prefix ("/")) {
            path = path.mid (1);
        }
        if (path.has_suffix ("/")) {
            path.chop (1);
        }

        GLib.TreeWidgetItem it = this.instance.folder_tree_widget.top_level_item (0);
        if (!path == "") {
            GLib.List<string> path_trail = path.split ("/");
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

        this.instance.folder_tree_widget.current_item (it);
        this.instance.folder_tree_widget.scroll_to_item (it);
        return true;
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

} // class FolderWizardRemotePath

} // namespace Ui
} // namespace Occ
