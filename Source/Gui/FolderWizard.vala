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
// #include <QUrl>
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
protected:
    string format_warnings (QStringList &warnings) const;
};

/***********************************************************
@brief Page to ask for the local source folder
@ingroup gui
***********************************************************/
class Folder_wizard_local_path : Format_warnings_wizard_page {

    public Folder_wizard_local_path (AccountPtr &account);
    public ~Folder_wizard_local_path () override;

    public bool is_complete () const override;
    public void initialize_page () override;
    public void cleanup_page () override;

    public void set_folder_map (Folder.Map &fm) {
        _folder_map = fm;
    }
protected slots:
    void slot_choose_local_folder ();

private:
    Ui_Folder_wizard_source_page _ui;
    Folder.Map _folder_map;
    AccountPtr _account;
};

/***********************************************************
@brief page to ask for the target folder
@ingroup gui
***********************************************************/

class Folder_wizard_remote_path : Format_warnings_wizard_page {

    public Folder_wizard_remote_path (AccountPtr &account);
    public ~Folder_wizard_remote_path () override;

    public bool is_complete () const override;

    public void initialize_page () override;
    public void cleanup_page () override;

protected slots:

    void show_warn (string & = string ()) const;
    void slot_add_remote_folder ();
    void slot_create_remote_folder (string &);
    void slot_create_remote_folder_finished ();
    void slot_handle_mkdir_network_error (QNetworkReply *);
    void slot_handle_ls_col_network_error (QNetworkReply *);
    void slot_update_directories (QStringList &);
    void slot_gather_encrypted_paths (string &, QMap<string, string> &);
    void slot_refresh_folders ();
    void slot_item_expanded (QTree_widget_item *);
    void slot_current_item_changed (QTree_widget_item *);
    void slot_folder_entry_edited (string &text);
    void slot_ls_col_folder_entry ();
    void slot_typed_path_found (QStringList &subpaths);

private:
    LsColJob *run_ls_col_job (string &path);
    void recursive_insert (QTree_widget_item *parent, QStringList path_trail, string path);
    bool select_by_path (string path);
    Ui_Folder_wizard_target_page _ui;
    bool _warn_was_visible;
    AccountPtr _account;
    QTimer _lscol_timer;
    QStringList _encrypted_paths;
};

/***********************************************************
@brief The Folder_wizard_selective_sync class
@ingroup gui
***********************************************************/
class Folder_wizard_selective_sync : QWizard_page {

    public Folder_wizard_selective_sync (AccountPtr &account);
    public ~Folder_wizard_selective_sync () override;

    public bool validate_page () override;

    public void initialize_page () override;
    public void cleanup_page () override;

private slots:
    void virtual_files_checkbox_clicked ();

private:
    Selective_sync_widget *_selective_sync;
    QCheckBox *_virtual_files_check_box = nullptr;
};

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
class FolderWizard : QWizard {

    public enum {
        Page_Source,
        Page_Target,
        Page_Selective_sync
    };

    public FolderWizard (AccountPtr account, Gtk.Widget *parent = nullptr);
    public ~FolderWizard () override;

    public bool event_filter (GLib.Object *watched, QEvent *event) override;
    public void resize_event (QResizeEvent *event) override;

private:
    Folder_wizard_local_path *_folder_wizard_source_page;
    Folder_wizard_remote_path *_folder_wizard_target_page;
    Folder_wizard_selective_sync *_folder_wizard_selective_sync_page;
};



    string Format_warnings_wizard_page.format_warnings (QStringList &warnings) {
        string ret;
        if (warnings.count () == 1) {
            ret = tr ("<b>Warning:</b> %1").arg (warnings.first ());
        } else if (warnings.count () > 1) {
            ret = tr ("<b>Warning:</b>") + " <ul>";
            Q_FOREACH (string warning, warnings) {
                ret += string.from_latin1 ("<li>%1</li>").arg (warning);
            }
            ret += "</ul>";
        }

        return ret;
    }

    Folder_wizard_local_path.Folder_wizard_local_path (AccountPtr &account)
        : Format_warnings_wizard_page ()
        , _account (account) {
        _ui.setup_ui (this);
        register_field (QLatin1String ("source_folder*"), _ui.local_folder_line_edit);
        connect (_ui.local_folder_choose_btn, &QAbstractButton.clicked, this, &Folder_wizard_local_path.slot_choose_local_folder);
        _ui.local_folder_choose_btn.set_tool_tip (tr ("Click to select a local folder to sync."));

        QUrl server_url = _account.url ();
        server_url.set_user_name (_account.credentials ().user ());
        string default_path = QDir.home_path () + QLatin1Char ('/') + Theme.instance ().app_name ();
        default_path = FolderMan.instance ().find_good_path_for_new_sync_folder (default_path, server_url);
        _ui.local_folder_line_edit.set_text (QDir.to_native_separators (default_path));
        _ui.local_folder_line_edit.set_tool_tip (tr ("Enter the path to the local folder."));

        _ui.warn_label.set_text_format (Qt.RichText);
        _ui.warn_label.hide ();
    }

    Folder_wizard_local_path.~Folder_wizard_local_path () = default;

    void Folder_wizard_local_path.initialize_page () {
        _ui.warn_label.hide ();
    }

    void Folder_wizard_local_path.cleanup_page () {
        _ui.warn_label.hide ();
    }

    bool Folder_wizard_local_path.is_complete () {
        QUrl server_url = _account.url ();
        server_url.set_user_name (_account.credentials ().user ());

        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (
            QDir.from_native_separators (_ui.local_folder_line_edit.text ()), server_url);

        bool is_ok = error_str.is_empty ();
        QStringList warn_strings;
        if (!is_ok) {
            warn_strings << error_str;
        }

        _ui.warn_label.set_word_wrap (true);
        if (is_ok) {
            _ui.warn_label.hide ();
            _ui.warn_label.clear ();
        } else {
            _ui.warn_label.show ();
            string warnings = format_warnings (warn_strings);
            _ui.warn_label.set_text (warnings);
        }
        return is_ok;
    }

    void Folder_wizard_local_path.slot_choose_local_folder () {
        string sf = QStandardPaths.writable_location (QStandardPaths.Home_location);
        QDir d (sf);

        // open the first entry of the home dir. Otherwise the dir picker comes
        // up with the closed home dir icon, stupid Qt default...
        QStringList dirs = d.entry_list (QDir.Dirs | QDir.NoDotAndDotDot | QDir.No_sym_links,
            QDir.Dirs_first | QDir.Name);

        if (dirs.count () > 0)
            sf += "/" + dirs.at (0); // Take the first dir in home dir.

        string dir = QFileDialog.get_existing_directory (this,
            tr ("Select the source folder"),
            sf);
        if (!dir.is_empty ()) {
            // set the last directory component name as alias
            _ui.local_folder_line_edit.set_text (QDir.to_native_separators (dir));
        }
        emit complete_changed ();
    }

    // =================================================================================
    Folder_wizard_remote_path.Folder_wizard_remote_path (AccountPtr &account)
        : Format_warnings_wizard_page ()
        , _warn_was_visible (false)
        , _account (account)
     {
        _ui.setup_ui (this);
        _ui.warn_frame.hide ();

        _ui.folder_tree_widget.set_sorting_enabled (true);
        _ui.folder_tree_widget.sort_by_column (0, Qt.Ascending_order);

        connect (_ui.add_folder_button, &QAbstractButton.clicked, this, &Folder_wizard_remote_path.slot_add_remote_folder);
        connect (_ui.refresh_button, &QAbstractButton.clicked, this, &Folder_wizard_remote_path.slot_refresh_folders);
        connect (_ui.folder_tree_widget, &QTree_widget.item_expanded, this, &Folder_wizard_remote_path.slot_item_expanded);
        connect (_ui.folder_tree_widget, &QTree_widget.current_item_changed, this, &Folder_wizard_remote_path.slot_current_item_changed);
        connect (_ui.folder_entry, &QLineEdit.text_edited, this, &Folder_wizard_remote_path.slot_folder_entry_edited);

        _lscol_timer.set_interval (500);
        _lscol_timer.set_single_shot (true);
        connect (&_lscol_timer, &QTimer.timeout, this, &Folder_wizard_remote_path.slot_ls_col_folder_entry);

        _ui.folder_tree_widget.header ().set_section_resize_mode (0, QHeaderView.Resize_to_contents);
        // Make sure that there will be a scrollbar when the contents is too wide
        _ui.folder_tree_widget.header ().set_stretch_last_section (false);
    }

    void Folder_wizard_remote_path.slot_add_remote_folder () {
        QTree_widget_item *current = _ui.folder_tree_widget.current_item ();

        string parent ('/');
        if (current) {
            parent = current.data (0, Qt.User_role).to_string ();
        }

        auto *dlg = new QInputDialog (this);

        dlg.set_window_title (tr ("Create Remote Folder"));
        dlg.set_label_text (tr ("Enter the name of the new folder to be created below \"%1\":")
                              .arg (parent));
        dlg.open (this, SLOT (slot_create_remote_folder (string)));
        dlg.set_attribute (Qt.WA_DeleteOnClose);
    }

    void Folder_wizard_remote_path.slot_create_remote_folder (string &folder) {
        if (folder.is_empty ())
            return;

        QTree_widget_item *current = _ui.folder_tree_widget.current_item ();
        string full_path;
        if (current) {
            full_path = current.data (0, Qt.User_role).to_string ();
        }
        full_path += "/" + folder;

        auto *job = new MkColJob (_account, full_path, this);
        /* check the owncloud configuration file and query the own_cloud */
        connect (job, &MkColJob.finished_without_error,
            this, &Folder_wizard_remote_path.slot_create_remote_folder_finished);
        connect (job, &AbstractNetworkJob.network_error, this, &Folder_wizard_remote_path.slot_handle_mkdir_network_error);
        job.start ();
    }

    void Folder_wizard_remote_path.slot_create_remote_folder_finished () {
        q_c_debug (lc_wizard) << "webdav mkdir request finished";
        show_warn (tr ("Folder was successfully created on %1.").arg (Theme.instance ().app_name_g_u_i ()));
        slot_refresh_folders ();
        _ui.folder_entry.set_text (static_cast<MkColJob> (sender ()).path ());
        slot_ls_col_folder_entry ();
    }

    void Folder_wizard_remote_path.slot_handle_mkdir_network_error (QNetworkReply *reply) {
        q_c_warning (lc_wizard) << "webdav mkdir request failed:" << reply.error ();
        if (!_account.credentials ().still_valid (reply)) {
            show_warn (tr ("Authentication failed accessing %1").arg (Theme.instance ().app_name_g_u_i ()));
        } else {
            show_warn (tr ("Failed to create the folder on %1. Please check manually.")
                         .arg (Theme.instance ().app_name_g_u_i ()));
        }
    }

    void Folder_wizard_remote_path.slot_handle_ls_col_network_error (QNetworkReply *reply) {
        // Ignore 404s, otherwise users will get annoyed by error popups
        // when not typing fast enough. It's still clear that a given path
        // was not found, because the 'Next' button is disabled and no entry
        // is selected in the tree view.
        int http_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        if (http_code == 404) {
            show_warn (string ()); // hides the warning pane
            return;
        }
        auto job = qobject_cast<LsColJob> (sender ());
        ASSERT (job);
        show_warn (tr ("Failed to list a folder. Error : %1")
                     .arg (job.error_string_parsing_body ()));
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

    void Folder_wizard_remote_path.recursive_insert (QTree_widget_item *parent, QStringList path_trail, string path) {
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
        QTree_widget_item *item = find_first_child (parent, folder_name);
        if (!item) {
            item = new QTree_widget_item (parent);
            QFile_icon_provider prov;
            QIcon folder_icon = prov.icon (QFile_icon_provider.Folder);
            item.set_icon (0, folder_icon);
            item.set_text (0, folder_name);
            item.set_data (0, Qt.User_role, folder_path);
            item.set_tool_tip (0, folder_path);
            item.set_child_indicator_policy (QTree_widget_item.Show_indicator);
        }

        path_trail.remove_first ();
        recursive_insert (item, path_trail, path);
    }

    bool Folder_wizard_remote_path.select_by_path (string path) {
        if (path.starts_with (QLatin1Char ('/'))) {
            path = path.mid (1);
        }
        if (path.ends_with (QLatin1Char ('/'))) {
            path.chop (1);
        }

        QTree_widget_item *it = _ui.folder_tree_widget.top_level_item (0);
        if (!path.is_empty ()) {
            const QStringList path_trail = path.split (QLatin1Char ('/'));
            foreach (string &path, path_trail) {
                if (!it) {
                    return false;
                }
                it = find_first_child (it, path);
            }
        }
        if (!it) {
            return false;
        }

        _ui.folder_tree_widget.set_current_item (it);
        _ui.folder_tree_widget.scroll_to_item (it);
        return true;
    }

    void Folder_wizard_remote_path.slot_update_directories (QStringList &list) {
        string webdav_folder = QUrl (_account.dav_url ()).path ();

        QTree_widget_item *root = _ui.folder_tree_widget.top_level_item (0);
        if (!root) {
            root = new QTree_widget_item (_ui.folder_tree_widget);
            root.set_text (0, Theme.instance ().app_name_g_u_i ());
            root.set_icon (0, Theme.instance ().application_icon ());
            root.set_tool_tip (0, tr ("Choose this to sync the entire account"));
            root.set_data (0, Qt.User_role, "/");
        }
        QStringList sorted_list = list;
        Utility.sort_filenames (sorted_list);
        foreach (string path, sorted_list) {
            path.remove (webdav_folder);

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
            recursive_insert (root, paths, path);
        }
        root.set_expanded (true);
    }

    void Folder_wizard_remote_path.slot_gather_encrypted_paths (string &path, QMap<string, string> &properties) {
        const auto it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }

        const auto webdav_folder = QUrl (_account.dav_url ()).path ();
        Q_ASSERT (path.starts_with (webdav_folder));
        _encrypted_paths << path.mid (webdav_folder.size ());
    }

    void Folder_wizard_remote_path.slot_refresh_folders () {
        _encrypted_paths.clear ();
        run_ls_col_job ("/");
        _ui.folder_tree_widget.clear ();
        _ui.folder_entry.clear ();
    }

    void Folder_wizard_remote_path.slot_item_expanded (QTree_widget_item *item) {
        string dir = item.data (0, Qt.User_role).to_string ();
        run_ls_col_job (dir);
    }

    void Folder_wizard_remote_path.slot_current_item_changed (QTree_widget_item *item) {
        if (item) {
            string dir = item.data (0, Qt.User_role).to_string ();

            // We don't want to allow creating subfolders in encrypted folders outside of the sync logic
            const auto encrypted = _encrypted_paths.contains (dir);
            _ui.add_folder_button.set_enabled (!encrypted);

            if (!dir.starts_with (QLatin1Char ('/'))) {
                dir.prepend (QLatin1Char ('/'));
            }
            _ui.folder_entry.set_text (dir);
        }

        emit complete_changed ();
    }

    void Folder_wizard_remote_path.slot_folder_entry_edited (string &text) {
        if (select_by_path (text)) {
            _lscol_timer.stop ();
            return;
        }

        _ui.folder_tree_widget.set_current_item (nullptr);
        _lscol_timer.start (); // avoid sending a request on each keystroke
    }

    void Folder_wizard_remote_path.slot_ls_col_folder_entry () {
        string path = _ui.folder_entry.text ();
        if (path.starts_with (QLatin1Char ('/')))
            path = path.mid (1);

        LsColJob *job = run_ls_col_job (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (job, nullptr, this, nullptr);
        connect (job, &LsColJob.finished_with_error,
            this, &Folder_wizard_remote_path.slot_handle_ls_col_network_error);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Folder_wizard_remote_path.slot_typed_path_found);
    }

    void Folder_wizard_remote_path.slot_typed_path_found (QStringList &subpaths) {
        slot_update_directories (subpaths);
        select_by_path (_ui.folder_entry.text ());
    }

    LsColJob *Folder_wizard_remote_path.run_ls_col_job (string &path) {
        auto *job = new LsColJob (_account, path, this);
        auto props = QList<QByteArray> () << "resourcetype";
        if (_account.capabilities ().client_side_encryption_available ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
        job.set_properties (props);
        connect (job, &LsColJob.directory_listing_subfolders,
            this, &Folder_wizard_remote_path.slot_update_directories);
        connect (job, &LsColJob.finished_with_error,
            this, &Folder_wizard_remote_path.slot_handle_ls_col_network_error);
        connect (job, &LsColJob.directory_listing_iterated,
            this, &Folder_wizard_remote_path.slot_gather_encrypted_paths);
        job.start ();

        return job;
    }

    Folder_wizard_remote_path.~Folder_wizard_remote_path () = default;

    bool Folder_wizard_remote_path.is_complete () {
        if (!_ui.folder_tree_widget.current_item ())
            return false;

        QStringList warn_strings;
        string dir = _ui.folder_tree_widget.current_item ().data (0, Qt.User_role).to_string ();
        if (!dir.starts_with (QLatin1Char ('/'))) {
            dir.prepend (QLatin1Char ('/'));
        }
        wizard ().set_property ("target_path", dir);

        Folder.Map map = FolderMan.instance ().map ();
        Folder.Map.Const_iterator i = map.const_begin ();
        for (i = map.const_begin (); i != map.const_end (); i++) {
            auto *f = static_cast<Folder> (i.value ());
            if (f.account_state ().account () != _account) {
                continue;
            }
            string cur_dir = f.remote_path_trailing_slash ();
            if (QDir.clean_path (dir) == QDir.clean_path (cur_dir)) {
                warn_strings.append (tr ("This folder is already being synced."));
            } else if (dir.starts_with (cur_dir)) {
                warn_strings.append (tr ("You are already syncing <i>%1</i>, which is a parent folder of <i>%2</i>.").arg (Utility.escape (cur_dir), Utility.escape (dir)));
            } else if (cur_dir.starts_with (dir)) {
                warn_strings.append (tr ("You are already syncing <i>%1</i>, which is a subfolder of <i>%2</i>.").arg (Utility.escape (cur_dir), Utility.escape (dir)));
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
        slot_refresh_folders ();
    }

    void Folder_wizard_remote_path.show_warn (string &msg) {
        if (msg.is_empty ()) {
            _ui.warn_frame.hide ();

        } else {
            _ui.warn_frame.show ();
            _ui.warn_label.set_text (msg);
        }
    }

    // ====================================================================================

    Folder_wizard_selective_sync.Folder_wizard_selective_sync (AccountPtr &account) {
        auto *layout = new QVBoxLayout (this);
        _selective_sync = new Selective_sync_widget (account, this);
        layout.add_widget (_selective_sync);

        if (Theme.instance ().show_virtual_files_option () && best_available_vfs_mode () != Vfs.Off) {
            _virtual_files_check_box = new QCheckBox (tr ("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
            connect (_virtual_files_check_box, &QCheckBox.clicked, this, &Folder_wizard_selective_sync.virtual_files_checkbox_clicked);
            connect (_virtual_files_check_box, &QCheckBox.state_changed, this, [this] (int state) {
                _selective_sync.set_enabled (state == Qt.Unchecked);
            });
            _virtual_files_check_box.set_checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
            layout.add_widget (_virtual_files_check_box);
        }
    }

    Folder_wizard_selective_sync.~Folder_wizard_selective_sync () = default;

    void Folder_wizard_selective_sync.initialize_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        if (target_path.starts_with ('/')) {
            target_path = target_path.mid (1);
        }
        string alias = QFileInfo (target_path).file_name ();
        if (alias.is_empty ())
            alias = Theme.instance ().app_name ();
        QStringList initial_blacklist;
        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            initial_blacklist = QStringList ("/");
        }
        _selective_sync.set_folder_info (target_path, alias, initial_blacklist);

        if (_virtual_files_check_box) {
            // TODO : remove when UX decision is made
            if (Utility.is_path_windows_drive_partition_root (wizard ().field (QStringLiteral ("source_folder")).to_string ())) {
                _virtual_files_check_box.set_checked (false);
                _virtual_files_check_box.set_enabled (false);
                _virtual_files_check_box.set_text (tr ("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            } else {
                _virtual_files_check_box.set_checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
                _virtual_files_check_box.set_enabled (true);
                _virtual_files_check_box.set_text (tr ("Use virtual files instead of downloading content immediately %1").arg (best_available_vfs_mode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));

                if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
                    _virtual_files_check_box.set_checked (true);
                    _virtual_files_check_box.set_disabled (true);
                }
            }
            //
        }

        QWizard_page.initialize_page ();
    }

    bool Folder_wizard_selective_sync.validate_page () {
        const bool use_virtual_files = _virtual_files_check_box && _virtual_files_check_box.is_checked ();
        if (use_virtual_files) {
            const auto availability = Vfs.check_availability (wizard ().field (QStringLiteral ("source_folder")).to_string ());
            if (!availability) {
                auto msg = new QMessageBox (QMessageBox.Warning, tr ("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                msg.set_attribute (Qt.WA_DeleteOnClose);
                msg.open ();
                return false;
            }
        }
        wizard ().set_property ("selective_sync_black_list", use_virtual_files ? QVariant () : QVariant (_selective_sync.create_black_list ()));
        wizard ().set_property ("use_virtual_files", QVariant (use_virtual_files));
        return true;
    }

    void Folder_wizard_selective_sync.cleanup_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        string alias = QFileInfo (target_path).file_name ();
        if (alias.is_empty ())
            alias = Theme.instance ().app_name ();
        _selective_sync.set_folder_info (target_path, alias);
        QWizard_page.cleanup_page ();
    }

    void Folder_wizard_selective_sync.virtual_files_checkbox_clicked () {
        // The click has already had an effect on the box, so if it's
        // checked it was newly activated.
        if (_virtual_files_check_box.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (this, [this] (bool enable) {
                if (!enable)
                    _virtual_files_check_box.set_checked (false);
            });
        }
    }

    // ====================================================================================

    /***********************************************************
    Folder wizard itself
    ***********************************************************/

    FolderWizard.FolderWizard (AccountPtr account, Gtk.Widget *parent)
        : QWizard (parent)
        , _folder_wizard_source_page (new Folder_wizard_local_path (account))
        , _folder_wizard_target_page (nullptr)
        , _folder_wizard_selective_sync_page (new Folder_wizard_selective_sync (account)) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        set_page (Page_Source, _folder_wizard_source_page);
        _folder_wizard_source_page.install_event_filter (this);
        if (!Theme.instance ().single_sync_folder ()) {
            _folder_wizard_target_page = new Folder_wizard_remote_path (account);
            set_page (Page_Target, _folder_wizard_target_page);
            _folder_wizard_target_page.install_event_filter (this);
        }
        set_page (Page_Selective_sync, _folder_wizard_selective_sync_page);

        set_window_title (tr ("Add Folder Sync Connection"));
        set_options (QWizard.Cancel_button_on_left);
        set_button_text (QWizard.Finish_button, tr ("Add Sync Connection"));
    }

    FolderWizard.~FolderWizard () = default;

    bool FolderWizard.event_filter (GLib.Object *watched, QEvent *event) {
        if (event.type () == QEvent.Layout_request) {
            // Workaround QTBUG-3396 :  forces QWizard_private.update_layout ()
            QTimer.single_shot (0, this, [this] {
                set_title_format (title_format ());
            });
        }
        return QWizard.event_filter (watched, event);
    }

    void FolderWizard.resize_event (QResizeEvent *event) {
        QWizard.resize_event (event);

        // workaround for QTBUG-22819 : when the error label word wrap, the minimum height is not adjusted
        if (auto page = current_page ()) {
            int hfw = page.height_for_width (page.width ());
            if (page.height () < hfw) {
                page.set_minimum_size (page.minimum_size_hint ().width (), hfw);
                set_title_format (title_format ()); // And another workaround for QTBUG-3396
            }
        }
    }

    } // end namespace
    