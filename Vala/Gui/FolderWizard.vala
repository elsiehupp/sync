/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDesktopServices>
// #include <QDir>
// #include <QFileDialog>
// #include <QFileInfo>
// #include <QFile_icon_provider>
// #include <QInputDialog>
// #include <GLib.Uri>
// #include <QValidator>
// #include <QWizard_page>
// #include <QTree_widget>
// #include <QVBoxLayout>
// #include <QEvent>
// #include <QCheckBox>
// #include <QMessageBox>

// #include <cstdlib>

// #include <QWizard>
// #include <QNetworkReply>
// #include <QTimer>


namespace Occ {



/***********************************************************
@brief The Format_warnings_wizard_page class
@ingroup gui
***********************************************************/
class Format_warnings_wizard_page : QWizard_page {

    protected string format_warnings (string[] warnings);
};

/***********************************************************
@brief Page to ask for the local source folder
@ingroup gui
***********************************************************/
class Folder_wizard_local_path : Format_warnings_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Folder_wizard_local_path (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    public 
    public bool is_complete () override;
    public void initialize_page () override;
    public void cleanup_page () override;

    /***********************************************************
    ***********************************************************/
    public void set_folder_map (Folder.Map fm) {
        this.folder_map = fm;
    }
protected slots:
    void on_choose_local_folder ();


    /***********************************************************
    ***********************************************************/
    private Ui_Folder_wizard_source_page this.ui;
    private Folder.Map this.folder_map;
    private AccountPointer this.account;
};

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
    public 
    public void initialize_page () override;
    public void cleanup_page () override;

protected slots:

    void show_warn (string  = "");
    void on_add_remote_folder ();
    void on_create_remote_folder (string );
    void on_create_remote_folder_finished ();
    void on_handle_mkdir_network_error (QNetworkReply *);
    void on_handle_ls_col_network_error (QNetworkReply *);
    void on_update_directories (string[] &);
    void on_gather_encrypted_paths (string , QMap<string, string> &);
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
};

/***********************************************************
@brief The Folder_wizard_selective_sync class
@ingroup gui
***********************************************************/
class Folder_wizard_selective_sync : QWizard_page {

    /***********************************************************
    ***********************************************************/
    public Folder_wizard_selective_sync (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public void initialize_page () override;
    public void cleanup_page () override;


    /***********************************************************
    ***********************************************************/
    private void on_virtual_files_checkbox_clicked ();

    /***********************************************************
    ***********************************************************/
    private 
    private Selective_sync_widget this.selective_sync;
    private QCheckBox this.virtual_files_check_box = nullptr;
};

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
class FolderWizard : QWizard {

    /***********************************************************
    ***********************************************************/
    public enum {
        Page_Source,
        Page_Target,
        Page_Selective_sync
    };

    /***********************************************************
    ***********************************************************/
    public FolderWizard (AccountPointer account, Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 
    public bool event_filter (GLib.Object watched, QEvent event) override;
    public void resize_event (QResizeEvent event) override;


    /***********************************************************
    ***********************************************************/
    private Folder_wizard_local_path this.folder_wizard_source_page;
    private Folder_wizard_remote_path this.folder_wizard_target_page;
    private Folder_wizard_selective_sync this.folder_wizard_selective_sync_page;
};



    string Format_warnings_wizard_page.format_warnings (string[] warnings) {
        string ret;
        if (warnings.count () == 1) {
            ret = _("<b>Warning:</b> %1").arg (warnings.first ());
        } else if (warnings.count () > 1) {
            ret = _("<b>Warning:</b>") + " <ul>";
            Q_FOREACH (string warning, warnings) {
                ret += string.from_latin1 ("<li>%1</li>").arg (warning);
            }
            ret += "</ul>";
        }

        return ret;
    }

    Folder_wizard_local_path.Folder_wizard_local_path (AccountPointer account)
        : Format_warnings_wizard_page ()
        , this.account (account) {
        this.ui.setup_ui (this);
        register_field (QLatin1String ("source_folder*"), this.ui.local_folder_line_edit);
        connect (this.ui.local_folder_choose_btn, &QAbstractButton.clicked, this, &Folder_wizard_local_path.on_choose_local_folder);
        this.ui.local_folder_choose_btn.set_tool_tip (_("Click to select a local folder to sync."));

        GLib.Uri server_url = this.account.url ();
        server_url.set_user_name (this.account.credentials ().user ());
        string default_path = QDir.home_path () + '/' + Theme.instance ().app_name ();
        default_path = FolderMan.instance ().find_good_path_for_new_sync_folder (default_path, server_url);
        this.ui.local_folder_line_edit.on_set_text (QDir.to_native_separators (default_path));
        this.ui.local_folder_line_edit.set_tool_tip (_("Enter the path to the local folder."));

        this.ui.warn_label.set_text_format (Qt.RichText);
        this.ui.warn_label.hide ();
    }

    Folder_wizard_local_path.~Folder_wizard_local_path () = default;

    void Folder_wizard_local_path.initialize_page () {
        this.ui.warn_label.hide ();
    }

    void Folder_wizard_local_path.cleanup_page () {
        this.ui.warn_label.hide ();
    }

    bool Folder_wizard_local_path.is_complete () {
        GLib.Uri server_url = this.account.url ();
        server_url.set_user_name (this.account.credentials ().user ());

        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (
            QDir.from_native_separators (this.ui.local_folder_line_edit.text ()), server_url);

        bool is_ok = error_str.is_empty ();
        string[] warn_strings;
        if (!is_ok) {
            warn_strings << error_str;
        }

        this.ui.warn_label.set_word_wrap (true);
        if (is_ok) {
            this.ui.warn_label.hide ();
            this.ui.warn_label.clear ();
        } else {
            this.ui.warn_label.show ();
            string warnings = format_warnings (warn_strings);
            this.ui.warn_label.on_set_text (warnings);
        }
        return is_ok;
    }

    void Folder_wizard_local_path.on_choose_local_folder () {
        string sf = QStandardPaths.writable_location (QStandardPaths.Home_location);
        QDir d (sf);

        // open the first entry of the home dir. Otherwise the dir picker comes
        // up with the closed home dir icon, stupid Qt default...
        string[] dirs = d.entry_list (QDir.Dirs | QDir.NoDotAndDotDot | QDir.No_sym_links,
            QDir.Dirs_first | QDir.Name);

        if (dirs.count () > 0)
            sf += "/" + dirs.at (0); // Take the first dir in home dir.

        string dir = QFileDialog.get_existing_directory (this,
            _("Select the source folder"),
            sf);
        if (!dir.is_empty ()) {
            // set the last directory component name as alias
            this.ui.local_folder_line_edit.on_set_text (QDir.to_native_separators (dir));
        }
        /* emit */ complete_changed ();
    }

    // =================================================================================
    Folder_wizard_remote_path.Folder_wizard_remote_path (AccountPointer account)
        : Format_warnings_wizard_page ()
        , this.warn_was_visible (false)
        , this.account (account)
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

    void Folder_wizard_remote_path.on_handle_mkdir_network_error (QNetworkReply reply) {
        GLib.warn (lc_wizard) << "webdav mkdir request failed:" << reply.error ();
        if (!this.account.credentials ().still_valid (reply)) {
            show_warn (_("Authentication failed accessing %1").arg (Theme.instance ().app_name_gui ()));
        } else {
            show_warn (_("Failed to create the folder on %1. Please check manually.")
                         .arg (Theme.instance ().app_name_gui ()));
        }
    }

    void Folder_wizard_remote_path.on_handle_ls_col_network_error (QNetworkReply reply) {
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
        return nullptr;
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

    void Folder_wizard_remote_path.on_gather_encrypted_paths (string path, QMap<string, string> properties) {
        const var it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }

        const var webdav_folder = GLib.Uri (this.account.dav_url ()).path ();
        Q_ASSERT (path.starts_with (webdav_folder));
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

        this.ui.folder_tree_widget.set_current_item (nullptr);
        this.lscol_timer.on_start (); // avoid sending a request on each keystroke
    }

    void Folder_wizard_remote_path.on_ls_col_folder_entry () {
        string path = this.ui.folder_entry.text ();
        if (path.starts_with ('/'))
            path = path.mid (1);

        LsColJob job = run_ls_col_job (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (job, nullptr, this, nullptr);
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

    // ====================================================================================

    Folder_wizard_selective_sync.Folder_wizard_selective_sync (AccountPointer account) {
        var layout = new QVBoxLayout (this);
        this.selective_sync = new Selective_sync_widget (account, this);
        layout.add_widget (this.selective_sync);

        if (Theme.instance ().show_virtual_files_option () && best_available_vfs_mode () != Vfs.Off) {
            this.virtual_files_check_box = new QCheckBox (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
            connect (this.virtual_files_check_box, &QCheckBox.clicked, this, &Folder_wizard_selective_sync.on_virtual_files_checkbox_clicked);
            connect (this.virtual_files_check_box, &QCheckBox.state_changed, this, [this] (int state) {
                this.selective_sync.set_enabled (state == Qt.Unchecked);
            });
            this.virtual_files_check_box.set_checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
            layout.add_widget (this.virtual_files_check_box);
        }
    }

    Folder_wizard_selective_sync.~Folder_wizard_selective_sync () = default;

    void Folder_wizard_selective_sync.initialize_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        if (target_path.starts_with ('/')) {
            target_path = target_path.mid (1);
        }
        string alias = QFileInfo (target_path).filename ();
        if (alias.is_empty ())
            alias = Theme.instance ().app_name ();
        string[] initial_blocklist;
        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            initial_blocklist = string[] ("/");
        }
        this.selective_sync.set_folder_info (target_path, alias, initial_blocklist);

        if (this.virtual_files_check_box) {
            // TODO : remove when UX decision is made
            if (Utility.is_path_windows_drive_partition_root (wizard ().field (QStringLiteral ("source_folder")).to_string ())) {
                this.virtual_files_check_box.set_checked (false);
                this.virtual_files_check_box.set_enabled (false);
                this.virtual_files_check_box.on_set_text (_("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            } else {
                this.virtual_files_check_box.set_checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
                this.virtual_files_check_box.set_enabled (true);
                this.virtual_files_check_box.on_set_text (_("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));

                if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
                    this.virtual_files_check_box.set_checked (true);
                    this.virtual_files_check_box.set_disabled (true);
                }
            }
            //
        }

        QWizard_page.initialize_page ();
    }

    bool Folder_wizard_selective_sync.validate_page () {
        const bool use_virtual_files = this.virtual_files_check_box && this.virtual_files_check_box.is_checked ();
        if (use_virtual_files) {
            const var availability = Vfs.check_availability (wizard ().field (QStringLiteral ("source_folder")).to_string ());
            if (!availability) {
                var msg = new QMessageBox (QMessageBox.Warning, _("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                msg.set_attribute (Qt.WA_DeleteOnClose);
                msg.open ();
                return false;
            }
        }
        wizard ().set_property ("selective_sync_block_list", use_virtual_files ? GLib.Variant () : GLib.Variant (this.selective_sync.create_block_list ()));
        wizard ().set_property ("use_virtual_files", GLib.Variant (use_virtual_files));
        return true;
    }

    void Folder_wizard_selective_sync.cleanup_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        string alias = QFileInfo (target_path).filename ();
        if (alias.is_empty ())
            alias = Theme.instance ().app_name ();
        this.selective_sync.set_folder_info (target_path, alias);
        QWizard_page.cleanup_page ();
    }

    void Folder_wizard_selective_sync.on_virtual_files_checkbox_clicked () {
        // The click has already had an effect on the box, so if it's
        // checked it was newly activated.
        if (this.virtual_files_check_box.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (this, [this] (bool enable) {
                if (!enable)
                    this.virtual_files_check_box.set_checked (false);
            });
        }
    }

    // ====================================================================================

    /***********************************************************
    Folder wizard itself
    ***********************************************************/

    FolderWizard.FolderWizard (AccountPointer account, Gtk.Widget parent)
        : QWizard (parent)
        , this.folder_wizard_source_page (new Folder_wizard_local_path (account))
        , this.folder_wizard_target_page (nullptr)
        , this.folder_wizard_selective_sync_page (new Folder_wizard_selective_sync (account)) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        set_page (Page_Source, this.folder_wizard_source_page);
        this.folder_wizard_source_page.install_event_filter (this);
        if (!Theme.instance ().single_sync_folder ()) {
            this.folder_wizard_target_page = new Folder_wizard_remote_path (account);
            set_page (Page_Target, this.folder_wizard_target_page);
            this.folder_wizard_target_page.install_event_filter (this);
        }
        set_page (Page_Selective_sync, this.folder_wizard_selective_sync_page);

        set_window_title (_("Add Folder Sync Connection"));
        set_options (QWizard.Cancel_button_on_left);
        set_button_text (QWizard.Finish_button, _("Add Sync Connection"));
    }

    FolderWizard.~FolderWizard () = default;

    bool FolderWizard.event_filter (GLib.Object watched, QEvent event) {
        if (event.type () == QEvent.Layout_request) {
            // Workaround QTBUG-3396 :  forces QWizard_private.update_layout ()
            QTimer.single_shot (0, this, [this] {
                set_title_format (title_format ());
            });
        }
        return QWizard.event_filter (watched, event);
    }

    void FolderWizard.resize_event (QResizeEvent event) {
        QWizard.resize_event (event);

        // workaround for QTBUG-22819 : when the error label word wrap, the minimum height is not adjusted
        if (var page = current_page ()) {
            int hfw = page.height_for_width (page.width ());
            if (page.height () < hfw) {
                page.set_minimum_size (page.minimum_size_hint ().width (), hfw);
                set_title_format (title_format ()); // And another workaround for QTBUG-3396
            }
        }
    }

    } // end namespace
    