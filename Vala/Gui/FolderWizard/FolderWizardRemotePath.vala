/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Soup;

namespace Occ {

/***********************************************************
@brief page to ask for the target folder
@ingroup gui
***********************************************************/
class Folder_wizard_remote_path : Format_warnings_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Folder_wizard_remote_path (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void initialize_page () override;
    public void cleanup_page () override;

protected slots:

    void show_warn (string  = "");
    void on_add_remote_folder ();
    void on_create_remote_folder (string );
    void on_create_remote_folder_finished ();
    void on_handle_mkdir_network_error (Soup.Reply *);
    void on_handle_ls_col_network_error (Soup.Reply *);
    void on_update_directories (string[] &);
    void on_gather_encrypted_paths (string , GLib.HashMap<string, string> &);
    void on_refresh_folders ();
    void on_item_expanded (QTree_widget_item *);
    void on_current_item_changed (QTree_widget_item *);
    void on_folder_entry_edited (string text);
    void on_ls_col_folder_entry ();
    void on_typed_path_found (string[] subpaths);


    /***********************************************************
    ***********************************************************/
    private LsColJob run_ls_col_job (string path);
    private void recursive_insert (QTree_widget_item parent, string[] path_trail, string path);
    private bool select_by_path (string path);
    private Ui_Folder_wizard_target_page this.ui;
    private bool this.warn_was_visible;
    private AccountPointer this.account;
    private QTimer this.lscol_timer;
    private string[] this.encrypted_paths;
}








    Folder_wizard_remote_path.Folder_wizard_remote_path (AccountPointer account)
        : Format_warnings_wizard_page ()
        this.warn_was_visible (false)
        this.account (account)
     {
        this.ui.setup_ui (this);
        this.ui.warn_frame.hide ();

        this.ui.folder_tree_widget.set_sorting_enabled (true);
        this.ui.folder_tree_widget.sort_by_column (0, Qt.Ascending_order);

        connect (this.ui.add_folder_button, &QAbstractButton.clicked, this, &Folder_wizard_remote_path.on_add_remote_folder);
        connect (this.ui.refresh_button, &QAbstractButton.clicked, this, &Folder_wizard_remote_path.on_refresh_folders);
        connect (this.ui.folder_tree_widget, &QTree_widget.item_expanded, this, &Folder_wizard_remote_path.on_item_expanded);
        connect (this.ui.folder_tree_widget, &QTree_widget.current_item_changed, this, &Folder_wizard_remote_path.on_current_item_changed);
        connect (this.ui.folder_entry, &QLineEdit.text_edited, this, &Folder_wizard_remote_path.on_folder_entry_edited);

        this.lscol_timer.set_interval (500);
        this.lscol_timer.set_single_shot (true);
        connect (&this.lscol_timer, &QTimer.timeout, this, &Folder_wizard_remote_path.on_ls_col_folder_entry);

        this.ui.folder_tree_widget.header ().set_section_resize_mode (0, QHeaderView.Resize_to_contents);
        // Make sure that there will be a scrollbar when the contents is too wide
        this.ui.folder_tree_widget.header ().set_stretch_last_section (false);
    }

    void Folder_wizard_remote_path.on_add_remote_folder () {
        QTree_widget_item current = this.ui.folder_tree_widget.current_item ();

        string parent ('/');
        if (current) {
            parent = current.data (0, Qt.User_role).to_string ();
        }

        var dlg = new QInputDialog (this);

        dlg.set_window_title (_("Create Remote Folder"));
        dlg.set_label_text (_("Enter the name of the new folder to be created below \"%1\":")
                              .arg (parent));
        dlg.open (this, SLOT (on_create_remote_folder (string)));
        dlg.set_attribute (Qt.WA_DeleteOnClose);
    }

    void Folder_wizard_remote_path.on_create_remote_folder (string folder) {
        if (folder.is_empty ())
            return;

        QTree_widget_item current = this.ui.folder_tree_widget.current_item ();
        string full_path;
        if (current) {
            full_path = current.data (0, Qt.User_role).to_string ();
        }
        full_path += "/" + folder;

        var job = new MkColJob (this.account, full_path, this);
        /* check the owncloud configuration file and query the own_cloud */
        connect (job, &MkColJob.finished_without_error,
            this, &Folder_wizard_remote_path.on_create_remote_folder_finished);
        connect (job, &AbstractNetworkJob.network_error, this, &Folder_wizard_remote_path.on_handle_mkdir_network_error);
        job.on_start ();
    }

    void Folder_wizard_remote_path.on_create_remote_folder_finished () {
        GLib.debug (lc_wizard) << "webdav mkdir request on_finished";
        show_warn (_("Folder was successfully created on %1.").arg (Theme.instance ().app_name_gui ()));
        on_refresh_folders ();
        this.ui.folder_entry.on_set_text (static_cast<MkColJob> (sender ()).path ());
        on_ls_col_folder_entry ();
    }

    void Folder_wizard_remote_path.on_handle_mkdir_network_error (Soup.Reply reply) {
        GLib.warn (lc_wizard) << "webdav mkdir request failed:" << reply.error ();
        if (!this.account.credentials ().still_valid (reply)) {
            show_warn (_("Authentication failed accessing %1").arg (Theme.instance ().app_name_gui ()));
        } else {
            show_warn (_("Failed to create the folder on %1. Please check manually.")
                         .arg (Theme.instance ().app_name_gui ()));
        }
    }

    void Folder_wizard_remote_path.on_handle_ls_col_network_error (Soup.Reply reply) {
        // Ignore 404s, otherwise users will get annoyed by error popups
        // when not typing fast enough. It's still clear that a given path
        // was not found, because the 'Next' button is disabled and no entry
        // is selected in the tree view.
        int http_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        if (http_code == 404) {
            show_warn (""); // hides the warning pane
            return;
        }
        var job = qobject_cast<LsColJob> (sender ());
        ASSERT (job);
        show_warn (_("Failed to list a folder. Error : %1")
                     .arg (job.error_string_parsing_body ()));
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
        return null;
    }

    void Folder_wizard_remote_path.recursive_insert (QTree_widget_item parent, string[] path_trail, string path) {
        if (path_trail.is_empty ())
            return;

        const string parent_path = parent.data (0, Qt.User_role).to_string ();
        const string folder_name = path_trail.first ();
        string folder_path;
        if (parent_path == QLatin1String ("/")) {
            folder_path = folder_name;
        } else {
            folder_path = parent_path + "/" + folder_name;
        }
        QTree_widget_item item = find_first_child (parent, folder_name);
        if (!item) {
            item = new QTree_widget_item (parent);
            QFile_icon_provider prov;
            QIcon folder_icon = prov.icon (QFile_icon_provider.Folder);
            item.set_icon (0, folder_icon);
            item.on_set_text (0, folder_name);
            item.set_data (0, Qt.User_role, folder_path);
            item.set_tool_tip (0, folder_path);
            item.set_child_indicator_policy (QTree_widget_item.Show_indicator);
        }

        path_trail.remove_first ();
        recursive_insert (item, path_trail, path);
    }

    bool Folder_wizard_remote_path.select_by_path (string path) {
        if (path.starts_with ('/')) {
            path = path.mid (1);
        }
        if (path.ends_with ('/')) {
            path.chop (1);
        }

        QTree_widget_item it = this.ui.folder_tree_widget.top_level_item (0);
        if (!path.is_empty ()) {
            const string[] path_trail = path.split ('/');
            foreach (string path, path_trail) {
                if (!it) {
                    return false;
                }
                it = find_first_child (it, path);
            }
        }
        if (!it) {
            return false;
        }

        this.ui.folder_tree_widget.set_current_item (it);
        this.ui.folder_tree_widget.scroll_to_item (it);
        return true;
    }

    void Folder_wizard_remote_path.on_update_directories (string[] list) {
        string webdav_folder = GLib.Uri (this.account.dav_url ()).path ();

        QTree_widget_item root = this.ui.folder_tree_widget.top_level_item (0);
        if (!root) {
            root = new QTree_widget_item (this.ui.folder_tree_widget);
            root.on_set_text (0, Theme.instance ().app_name_gui ());
            root.set_icon (0, Theme.instance ().application_icon ());
            root.set_tool_tip (0, _("Choose this to sync the entire account"));
            root.set_data (0, Qt.User_role, "/");
        }
        string[] sorted_list = list;
        Utility.sort_filenames (sorted_list);
        foreach (string path, sorted_list) {
            path.remove (webdav_folder);

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
            recursive_insert (root, paths, path);
        }
        root.set_expanded (true);
    }

    void Folder_wizard_remote_path.on_gather_encrypted_paths (string path, GLib.HashMap<string, string> properties) {
        const var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }

        const var webdav_folder = GLib.Uri (this.account.dav_url ()).path ();
        //  Q_ASSERT (path.starts_with (webdav_folder));
        this.encrypted_paths << path.mid (webdav_folder.size ());
    }

    void Folder_wizard_remote_path.on_refresh_folders () {
        this.encrypted_paths.clear ();
        run_ls_col_job ("/");
        this.ui.folder_tree_widget.clear ();
        this.ui.folder_entry.clear ();
    }

    void Folder_wizard_remote_path.on_item_expanded (QTree_widget_item item) {
        string dir = item.data (0, Qt.User_role).to_string ();
        run_ls_col_job (dir);
    }

    void Folder_wizard_remote_path.on_current_item_changed (QTree_widget_item item) {
        if (item) {
            string dir = item.data (0, Qt.User_role).to_string ();

            // We don't want to allow creating subfolders in encrypted folders outside of the sync logic
            const var encrypted = this.encrypted_paths.contains (dir);
            this.ui.add_folder_button.set_enabled (!encrypted);

            if (!dir.starts_with ('/')) {
                dir.prepend ('/');
            }
            this.ui.folder_entry.on_set_text (dir);
        }

        /* emit */ complete_changed ();
    }

    void Folder_wizard_remote_path.on_folder_entry_edited (string text) {
        if (select_by_path (text)) {
            this.lscol_timer.stop ();
            return;
        }

        this.ui.folder_tree_widget.set_current_item (null);
        this.lscol_timer.on_start (); // avoid sending a request on each keystroke
    }

    void Folder_wizard_remote_path.on_ls_col_folder_entry () {
        string path = this.ui.folder_entry.text ();
        if (path.starts_with ('/'))
            path = path.mid (1);

        LsColJob job = run_ls_col_job (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (job, null, this, null);
        connect (job, &LsColJob.finished_with_error,
            this, &Folder_wizard_remote_path.on_handle_ls_col_network_error);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Folder_wizard_remote_path.on_typed_path_found);
    }

    void Folder_wizard_remote_path.on_typed_path_found (string[] subpaths) {
        on_update_directories (subpaths);
        select_by_path (this.ui.folder_entry.text ());
    }

    LsColJob *Folder_wizard_remote_path.run_ls_col_job (string path) {
        var job = new LsColJob (this.account, path, this);
        var props = GLib.List<GLib.ByteArray> () << "resourcetype";
        if (this.account.capabilities ().client_side_encryption_available ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
        job.set_properties (props);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Folder_wizard_remote_path.on_update_directories);
        connect (job, &LsColJob.finished_with_error,
            this, &Folder_wizard_remote_path.on_handle_ls_col_network_error);
        connect (job, &LsColJob.directory_listing_iterated,
            this, &Folder_wizard_remote_path.on_gather_encrypted_paths);
        job.on_start ();

        return job;
    }

    Folder_wizard_remote_path.~Folder_wizard_remote_path () = default;

    bool Folder_wizard_remote_path.is_complete () {
        if (!this.ui.folder_tree_widget.current_item ())
            return false;

        string[] warn_strings;
        string dir = this.ui.folder_tree_widget.current_item ().data (0, Qt.User_role).to_string ();
        if (!dir.starts_with ('/')) {
            dir.prepend ('/');
        }
        wizard ().set_property ("target_path", dir);

        Folder.Map map = FolderMan.instance ().map ();
        Folder.Map.Const_iterator i = map.const_begin ();
        for (i = map.const_begin (); i != map.const_end (); i++) {
            var f = static_cast<Folder> (i.value ());
            if (f.account_state ().account () != this.account) {
                continue;
            }
            string cur_dir = f.remote_path_trailing_slash ();
            if (QDir.clean_path (dir) == QDir.clean_path (cur_dir)) {
                warn_strings.append (_("This folder is already being synced."));
            } else if (dir.starts_with (cur_dir)) {
                warn_strings.append (_("You are already syncing <i>%1</i>, which is a parent folder of <i>%2</i>.").arg (Utility.escape (cur_dir), Utility.escape (dir)));
            } else if (cur_dir.starts_with (dir)) {
                warn_strings.append (_("You are already syncing <i>%1</i>, which is a subfolder of <i>%2</i>.").arg (Utility.escape (cur_dir), Utility.escape (dir)));
            }
        }

        show_warn (format_warnings (warn_strings));
        return true;
    }

    void Folder_wizard_remote_path.cleanup_page () {
        show_warn ();
    }

    void Folder_wizard_remote_path.initialize_page () {
        show_warn ();
        on_refresh_folders ();
    }

    void Folder_wizard_remote_path.show_warn (string msg) {
        if (msg.is_empty ()) {
            this.ui.warn_frame.hide ();

        } else {
            this.ui.warn_frame.show ();
            this.ui.warn_label.on_set_text (msg);
        }
    }
