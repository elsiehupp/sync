/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <cmath>

// #include <QDesktopServices>
// #include <QDialogButtonBox>
// #include <QDir>
// #include <QListWidgetTtem>
// #include <QMessageBox>
// #include <QAction>
// #include <QVBoxLayout>
// #include <QTreeView>
// #include <QKeySequence>
// #include <QIcon>
// #include <QVariant>
// #include <QJsonDocument>
// #include <QToolTip>

// #include <Gtk.Widget>
// #include <QUrl>
// #include <QPointer>
// #include <QHash>
// #include <QTimer>

class QLabel;

namespace Occ {

namespace {
    constexpr auto property_folder = "folder";
    constexpr auto property_path = "path";
    }

namespace Ui {
    class AccountSettings;
}



/***********************************************************
@brief The AccountSettings class
@ingroup gui
***********************************************************/
class AccountSettings : Gtk.Widget {
    Q_PROPERTY (AccountState* account_state MEMBER _account_state)

    public AccountSettings (AccountState *account_state, Gtk.Widget *parent = nullptr);
    public ~AccountSettings () override;
    public QSize size_hint () const override {
        return OwncloudGui.settings_dialog_size ();
    }
    public bool can_encrypt_or_decrypt (FolderStatusModel.SubFolderInfo* folder_info);

signals:
    void folder_changed ();
    void open_folder_alias (string &);
    void show_issues_list (AccountState *account);
    void request_mnemonic ();
    void remove_account_folders (AccountState *account);
    void style_changed ();

public slots:
    void slot_open_oC ();
    void slot_update_quota (int64 total, int64 used);
    void slot_account_state_changed ();
    void slot_style_changed ();
    AccountState *accounts_state () {
        return _account_state;
    }
    void slot_hide_selective_sync_widget ();

protected slots:
    void slot_add_folder ();
    void slot_enable_current_folder (bool terminate = false);
    void slot_schedule_current_folder ();
    void slot_schedule_current_folder_force_remote_discovery ();
    void slot_force_sync_current_folder ();
    void slot_remove_current_folder ();
    void slot_open_current_folder (); // sync folder
    void slot_open_current_local_sub_folder (); // selected subfolder in sync folder
    void slot_edit_current_ignored_files ();
    void slot_open_make_folder_dialog ();
    void slot_edit_current_local_ignored_files ();
    void slot_enable_vfs_current_folder ();
    void slot_disable_vfs_current_folder ();
    void slot_set_current_folder_availability (PinState state);
    void slot_set_sub_folder_availability (Folder *folder, string &path, PinState state);
    void slot_folder_wizard_accepted ();
    void slot_folder_wizard_rejected ();
    void slot_delete_account ();
    void slot_toggle_sign_in_state ();
    void refresh_selective_sync_status ();
    void slot_mark_subfolder_encrypted (FolderStatusModel.SubFolderInfo *folder_info);
    void slot_subfolder_context_menu_requested (QModelIndex& idx, QPoint& point);
    void slot_custom_context_menu_requested (QPoint &);
    void slot_folder_list_clicked (QModelIndex &indx);
    void do_expand ();
    void slot_link_activated (string &link);

    // Encryption Related Stuff.
    void slot_show_mnemonic (string &mnemonic);
    void slot_new_mnemonic_generated ();
    void slot_encrypt_folder_finished (int status);

    void slot_selective_sync_changed (QModelIndex &top_left, QModelIndex &bottom_right,
                                  const QVector<int> &roles);

private:
    void show_connection_label (string &message,
        QStringList errors = QStringList ());
    bool event (QEvent *) override;
    void create_account_toolbox ();
    void open_ignored_files_dialog (string & abs_folder_path);
    void customize_style ();

    /// Returns the alias of the selected folder, empty string if none
    string selected_folder_alias ();

    Ui.AccountSettings *_ui;

    FolderStatusModel *_model;
    QUrl _OCUrl;
    bool _was_disabled_before;
    AccountState *_account_state;
    UserInfo _user_info;
    QAction *_toggle_sign_in_out_action;
    QAction *_add_account_action;

    bool _menu_shown;
};





    static const char progress_bar_style_c[] =
        "QProgressBar {"
        "border : 1px solid grey;"
        "border-radius : 5px;"
        "text-align : center;"
        "}"
        "QProgressBar.chunk {"
        "background-color : %1; width : 1px;"
        "}";

    void show_enable_e2ee_with_virtual_files_warning_dialog (std.function<void (void)> on_accept) {
        const auto message_box = new QMessageBox;
        message_box.set_attribute (Qt.WA_DeleteOnClose);
        message_box.set_text (AccountSettings.tr ("End-to-End Encryption with Virtual Files"));
        message_box.set_informative_text (AccountSettings.tr ("You seem to have the Virtual Files feature enabled on this folder. "
                                                           "At the moment, it is not possible to implicitly download virtual files that are "
                                                           "End-to-End encrypted. To get the best experience with Virtual Files and "
                                                           "End-to-End Encryption, make sure the encrypted folder is marked with "
                                                           "\"Make always available locally\"."));
        message_box.set_icon (QMessageBox.Warning);
        const auto dont_encrypt_button = message_box.add_button (QMessageBox.StandardButton.Cancel);
        Q_ASSERT (dont_encrypt_button);
        dont_encrypt_button.set_text (AccountSettings.tr ("Don't encrypt folder"));
        const auto encrypt_button = message_box.add_button (QMessageBox.StandardButton.Ok);
        Q_ASSERT (encrypt_button);
        encrypt_button.set_text (AccountSettings.tr ("Encrypt folder"));
        GLib.Object.connect (message_box, &QMessageBox.accepted, on_accept);

        message_box.open ();
    }

    /***********************************************************
    Adjusts the mouse cursor based on the region it is on over the folder tree view.

    Used to show that one can click the red error list box by changing the cursor
    to the pointing hand.
    ***********************************************************/
    class MouseCursorChanger : GLib.Object {

        public MouseCursorChanger (GLib.Object *parent)
            : GLib.Object (parent) {
        }

        public QTreeView *folder_list;
        public FolderStatusModel *model;

    protected:
        bool event_filter (GLib.Object *watched, QEvent *event) override {
            if (event.type () == QEvent.HoverMove) {
                Qt.CursorShape shape = Qt.ArrowCursor;
                auto pos = folder_list.map_from_global (QCursor.pos ());
                auto index = folder_list.index_at (pos);
                if (model.classify (index) == FolderStatusModel.RootFolder
                    && (FolderStatusDelegate.errors_list_rect (folder_list.visual_rect (index)).contains (pos)
                        || FolderStatusDelegate.options_button_rect (folder_list.visual_rect (index),folder_list.layout_direction ()).contains (pos))) {
                    shape = Qt.PointingHandCursor;
                }
                folder_list.set_cursor (shape);
            }
            return GLib.Object.event_filter (watched, event);
        }
    };

    AccountSettings.AccountSettings (AccountState *account_state, Gtk.Widget *parent)
        : Gtk.Widget (parent)
        , _ui (new Ui.AccountSettings)
        , _was_disabled_before (false)
        , _account_state (account_state)
        , _user_info (account_state, false, true)
        , _menu_shown (false) {
        _ui.setup_ui (this);

        _model = new FolderStatusModel;
        _model.set_account_state (_account_state);
        _model.set_parent (this);
        auto *delegate = new FolderStatusDelegate;
        delegate.set_parent (this);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &AccountSettings.style_changed, delegate, &FolderStatusDelegate.slot_style_changed);

        _ui._folder_list.header ().hide ();
        _ui._folder_list.set_item_delegate (delegate);
        _ui._folder_list.set_model (_model);
        _ui._folder_list.set_minimum_width (300);
        new ToolTipUpdater (_ui._folder_list);

        auto mouse_cursor_changer = new MouseCursorChanger (this);
        mouse_cursor_changer.folder_list = _ui._folder_list;
        mouse_cursor_changer.model = _model;
        _ui._folder_list.set_mouse_tracking (true);
        _ui._folder_list.set_attribute (Qt.WA_Hover, true);
        _ui._folder_list.install_event_filter (mouse_cursor_changer);

        connect (this, &AccountSettings.remove_account_folders,
                AccountManager.instance (), &AccountManager.remove_account_folders);
        connect (_ui._folder_list, &Gtk.Widget.custom_context_menu_requested,
            this, &AccountSettings.slot_custom_context_menu_requested);
        connect (_ui._folder_list, &QAbstractItemView.clicked,
            this, &AccountSettings.slot_folder_list_clicked);
        connect (_ui._folder_list, &QTreeView.expanded, this, &AccountSettings.refresh_selective_sync_status);
        connect (_ui._folder_list, &QTreeView.collapsed, this, &AccountSettings.refresh_selective_sync_status);
        connect (_ui.selective_sync_notification, &QLabel.link_activated,
            this, &AccountSettings.slot_link_activated);
        connect (_model, &FolderStatusModel.suggest_expand, _ui._folder_list, &QTreeView.expand);
        connect (_model, &FolderStatusModel.dirty_changed, this, &AccountSettings.refresh_selective_sync_status);
        refresh_selective_sync_status ();
        connect (_model, &QAbstractItemModel.rows_inserted,
            this, &AccountSettings.refresh_selective_sync_status);

        auto *sync_now_action = new QAction (this);
        sync_now_action.set_shortcut (QKeySequence (Qt.Key_F6));
        connect (sync_now_action, &QAction.triggered, this, &AccountSettings.slot_schedule_current_folder);
        add_action (sync_now_action);

        auto *sync_now_with_remote_discovery = new QAction (this);
        sync_now_with_remote_discovery.set_shortcut (QKeySequence (Qt.CTRL + Qt.Key_F6));
        connect (sync_now_with_remote_discovery, &QAction.triggered, this, &AccountSettings.slot_schedule_current_folder_force_remote_discovery);
        add_action (sync_now_with_remote_discovery);

        slot_hide_selective_sync_widget ();
        _ui.big_folder_ui.set_visible (false);
        connect (_model, &QAbstractItemModel.data_changed, this, &AccountSettings.slot_selective_sync_changed);
        connect (_ui.selective_sync_apply, &QAbstractButton.clicked, this, &AccountSettings.slot_hide_selective_sync_widget);
        connect (_ui.selective_sync_cancel, &QAbstractButton.clicked, this, &AccountSettings.slot_hide_selective_sync_widget);

        connect (_ui.selective_sync_apply, &QAbstractButton.clicked, _model, &FolderStatusModel.slot_apply_selective_sync);
        connect (_ui.selective_sync_cancel, &QAbstractButton.clicked, _model, &FolderStatusModel.reset_folders);
        connect (_ui.big_folder_apply, &QAbstractButton.clicked, _model, &FolderStatusModel.slot_apply_selective_sync);
        connect (_ui.big_folder_sync_all, &QAbstractButton.clicked, _model, &FolderStatusModel.slot_sync_all_pending_big_folders);
        connect (_ui.big_folder_sync_none, &QAbstractButton.clicked, _model, &FolderStatusModel.slot_sync_no_pending_big_folders);

        connect (FolderMan.instance (), &FolderMan.folder_list_changed, _model, &FolderStatusModel.reset_folders);
        connect (this, &AccountSettings.folder_changed, _model, &FolderStatusModel.reset_folders);

        // quota_progress_bar style now set in customize_style ()
        /*QColor color = palette ().highlight ().color ();
         _ui.quota_progress_bar.set_style_sheet (string.from_latin1 (progress_bar_style_c).arg (color.name ()));*/

        // Connect E2E stuff
        connect (this, &AccountSettings.request_mnemonic, _account_state.account ().e2e (), &ClientSideEncryption.slot_request_mnemonic);
        connect (_account_state.account ().e2e (), &ClientSideEncryption.show_mnemonic, this, &AccountSettings.slot_show_mnemonic);

        connect (_account_state.account ().e2e (), &ClientSideEncryption.mnemonic_generated, this, &AccountSettings.slot_new_mnemonic_generated);
        if (_account_state.account ().e2e ().new_mnemonic_generated ()) {
            slot_new_mnemonic_generated ();
        } else {
            _ui.encryption_message.set_text (tr ("This account supports end-to-end encryption"));

            auto *mnemonic = new QAction (tr ("Display mnemonic"), this);
            connect (mnemonic, &QAction.triggered, this, &AccountSettings.request_mnemonic);
            _ui.encryption_message.add_action (mnemonic);
            _ui.encryption_message.hide ();
        }

        _ui.connect_label.set_text (tr ("No account configured."));

        connect (_account_state, &AccountState.state_changed, this, &AccountSettings.slot_account_state_changed);
        slot_account_state_changed ();

        connect (&_user_info, &UserInfo.quota_updated,
            this, &AccountSettings.slot_update_quota);

        customize_style ();
    }

    void AccountSettings.slot_new_mnemonic_generated () {
        _ui.encryption_message.set_text (tr ("This account supports end-to-end encryption"));

        auto *mnemonic = new QAction (tr ("Enable encryption"), this);
        connect (mnemonic, &QAction.triggered, this, &AccountSettings.request_mnemonic);
        connect (mnemonic, &QAction.triggered, _ui.encryption_message, &KMessageWidget.hide);

        _ui.encryption_message.add_action (mnemonic);
        _ui.encryption_message.show ();
    }

    void AccountSettings.slot_encrypt_folder_finished (int status) {
        q_c_info (lc_account_settings) << "Current folder encryption status code:" << status;
        auto job = qobject_cast<EncryptFolderJob> (sender ());
        Q_ASSERT (job);
        if (!job.error_string ().is_empty ()) {
            QMessageBox.warning (nullptr, tr ("Warning"), job.error_string ());
        }

        const auto folder = job.property (property_folder).value<Folder> ();
        Q_ASSERT (folder);
        const auto path = job.property (property_path).value<string> ();
        const auto index = _model.index_for_path (folder, path);
        Q_ASSERT (index.is_valid ());
        _model.reset_and_fetch (index.parent ());

        job.delete_later ();
    }

    string AccountSettings.selected_folder_alias () {
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid ())
            return "";
        return _model.data (selected, FolderStatusDelegate.FolderAliasRole).to_string ();
    }

    void AccountSettings.slot_toggle_sign_in_state () {
        if (_account_state.is_signed_out ()) {
            _account_state.account ().reset_rejected_certificates ();
            _account_state.sign_in ();
        } else {
            _account_state.sign_out_by_ui ();
        }
    }

    void AccountSettings.do_expand () {
        // Make sure at least the root items are expanded
        for (int i = 0; i < _model.row_count (); ++i) {
            auto idx = _model.index (i);
            if (!_ui._folder_list.is_expanded (idx))
                _ui._folder_list.set_expanded (idx, true);
        }
    }

    void AccountSettings.slot_show_mnemonic (string &mnemonic) {
        AccountManager.instance ().display_mnemonic (mnemonic);
    }

    bool AccountSettings.can_encrypt_or_decrypt (FolderStatusModel.SubFolderInfo* info) {
        if (info._folder.sync_result ().status () != SyncResult.Status.Success) {
            QMessageBox msg_box;
            msg_box.set_text ("Please wait for the folder to sync before trying to encrypt it.");
            msg_box.exec ();
            return false;
        }

        // for some reason the actual folder in disk is info._folder.path + info._path.
        QDir folder_path (info._folder.path () + info._path);
        folder_path.set_filter ( QDir.AllEntries | QDir.NoDotAndDotDot );

        if (folder_path.count () != 0) {
            QMessageBox msg_box;
            msg_box.set_text (tr ("You cannot encrypt a folder with contents, please remove the files.\n"
                           "Wait for the new sync, then encrypt it."));
            msg_box.exec ();
            return false;
        }
        return true;
    }

    void AccountSettings.slot_mark_subfolder_encrypted (FolderStatusModel.SubFolderInfo* folder_info) {
        if (!can_encrypt_or_decrypt (folder_info)) {
            return;
        }

        const auto folder = folder_info._folder;
        Q_ASSERT (folder);

        const auto folder_alias = folder.alias ();
        const auto path = folder_info._path;
        const auto file_id = folder_info._file_id;
        const auto encrypt_folder = [this, file_id, path, folder_alias] {
            const auto folder = FolderMan.instance ().folder (folder_alias);
            if (!folder) {
                q_c_warning (lc_account_settings) << "Could not encrypt folder because folder" << folder_alias << "does not exist anymore";
                QMessageBox.warning (nullptr, tr ("Encryption failed"), tr ("Could not encrypt folder because the folder does not exist anymore"));
                return;
            }

            // Folder info have directory paths in Foo/Bar/ convention...
            Q_ASSERT (!path.starts_with ('/') && path.ends_with ('/'));
            // But EncryptFolderJob expects directory path Foo/Bar convention
            const auto chopped_path = path.chopped (1);
            auto job = new Occ.EncryptFolderJob (accounts_state ().account (), folder.journal_db (), chopped_path, file_id, this);
            job.set_property (property_folder, QVariant.from_value (folder));
            job.set_property (property_path, QVariant.from_value (path));
            connect (job, &Occ.EncryptFolderJob.finished, this, &AccountSettings.slot_encrypt_folder_finished);
            job.start ();
        };

        if (folder.virtual_files_enabled ()
            && folder.vfs ().mode () == Vfs.WindowsCfApi) {
            show_enable_e2ee_with_virtual_files_warning_dialog (encrypt_folder);
            return;
        }
        encrypt_folder ();
    }

    void AccountSettings.slot_edit_current_ignored_files () {
        Folder *f = FolderMan.instance ().folder (selected_folder_alias ());
        if (!f)
            return;
        open_ignored_files_dialog (f.path ());
    }

    void AccountSettings.slot_open_make_folder_dialog () {
        const auto &selected = _ui._folder_list.selection_model ().current_index ();

        if (!selected.is_valid ()) {
            q_c_warning (lc_account_settings) << "Selection model current folder index is not valid.";
            return;
        }

        const auto &classification = _model.classify (selected);

        if (classification != FolderStatusModel.SubFolder && classification != FolderStatusModel.RootFolder) {
            return;
        }

        const string file_name = [this, &selected, &classification] {
            string result;
            if (classification == FolderStatusModel.RootFolder) {
                const auto alias = _model.data (selected, FolderStatusDelegate.FolderAliasRole).to_string ();
                if (auto folder = FolderMan.instance ().folder (alias)) {
                    result = folder.path ();
                }
            } else {
                result = _model.data (selected, FolderStatusDelegate.FolderPathRole).to_string ();
            }

            if (result.ends_with ('/')) {
                result.chop (1);
            }

            return result;
        } ();

        if (!file_name.is_empty ()) {
            const auto folder_creation_dialog = new FolderCreationDialog (file_name, this);
            folder_creation_dialog.set_attribute (Qt.WA_DeleteOnClose);
            folder_creation_dialog.open ();
        }
    }

    void AccountSettings.slot_edit_current_local_ignored_files () {
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || _model.classify (selected) != FolderStatusModel.SubFolder)
            return;
        string file_name = _model.data (selected, FolderStatusDelegate.FolderPathRole).to_string ();
        open_ignored_files_dialog (file_name);
    }

    void AccountSettings.open_ignored_files_dialog (string & abs_folder_path) {
        Q_ASSERT (QFileInfo (abs_folder_path).is_absolute ());

        const string ignore_file = abs_folder_path + ".sync-exclude.lst";
        auto layout = new QVBoxLayout ();
        auto ignore_list_widget = new IgnoreListTableWidget (this);
        ignore_list_widget.read_ignore_file (ignore_file);
        layout.add_widget (ignore_list_widget);

        auto button_box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel);
        layout.add_widget (button_box);

        auto dialog = new Gtk.Dialog ();
        dialog.set_layout (layout);

        connect (button_box, &QDialogButtonBox.clicked, [=] (QAbstractButton * button) {
            if (button_box.button_role (button) == QDialogButtonBox.AcceptRole)
                ignore_list_widget.slot_write_ignore_file (ignore_file);
            dialog.close ();
        });
        connect (button_box, &QDialogButtonBox.rejected,
                dialog,    &Gtk.Dialog.close);

        dialog.open ();
    }

    void AccountSettings.slot_subfolder_context_menu_requested (QModelIndex& index, QPoint& pos) {
        Q_UNUSED (pos);

        QMenu menu;
        auto ac = menu.add_action (tr ("Open folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_open_current_local_sub_folder);

        auto file_name = _model.data (index, FolderStatusDelegate.FolderPathRole).to_string ();
        if (!QFile.exists (file_name)) {
            ac.set_enabled (false);
        }
        auto info   = _model.info_for_index (index);
        auto acc = _account_state.account ();

        if (acc.capabilities ().client_side_encryption_available ()) {
            // Verify if the folder is empty before attempting to encrypt.

            bool is_encrypted = info._is_encrypted;
            bool is_parent_encrypted = _model.is_any_ancestor_encrypted (index);

            if (!is_encrypted && !is_parent_encrypted) {
                ac = menu.add_action (tr ("Encrypt"));
                connect (ac, &QAction.triggered, [this, info] {
                    slot_mark_subfolder_encrypted (info);
                });
            } else {
                // Ingore decrypting for now since it only works with an empty folder
                // connect (ac, &QAction.triggered, [this, &info] {
                //    slot_mark_subfolder_decrypted (info);
                // });
            }
        }

        ac = menu.add_action (tr ("Edit Ignored Files"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_edit_current_local_ignored_files);

        ac = menu.add_action (tr ("Create new folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_open_make_folder_dialog);
        ac.set_enabled (QFile.exists (file_name));

        const auto folder = info._folder;
        if (folder && folder.virtual_files_enabled ()) {
            auto availability_menu = menu.add_menu (tr ("Availability"));

            // Has '/' suffix convention for paths here but VFS and
            // sync engine expects no such suffix
            Q_ASSERT (info._path.ends_with ('/'));
            const auto remote_path = info._path.chopped (1);

            // It might be an E2EE mangled path, so let's try to demangle it
            const auto journal = folder.journal_db ();
            SyncJournalFileRecord rec;
            journal.get_file_record_by_e2e_mangled_name (remote_path, &rec);

            const auto path = rec.is_valid () ? rec._path : remote_path;

            ac = availability_menu.add_action (Utility.vfs_pin_action_text ());
            connect (ac, &QAction.triggered, this, [this, folder, path] {
                slot_set_sub_folder_availability (folder, path, PinState.AlwaysLocal);
            });

            ac = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            connect (ac, &QAction.triggered, this, [this, folder, path] {
                slot_set_sub_folder_availability (folder, path, PinState.OnlineOnly);
            });
        }

        menu.exec (QCursor.pos ());
    }

    void AccountSettings.slot_custom_context_menu_requested (QPoint &pos) {
        QTreeView *tv = _ui._folder_list;
        QModelIndex index = tv.index_at (pos);
        if (!index.is_valid ()) {
            return;
        }

        if (_model.classify (index) == FolderStatusModel.SubFolder) {
            slot_subfolder_context_menu_requested (index, pos);
            return;
        }

        if (_model.classify (index) != FolderStatusModel.RootFolder) {
            return;
        }

        tv.set_current_index (index);
        string alias = _model.data (index, FolderStatusDelegate.FolderAliasRole).to_string ();
        bool folder_paused = _model.data (index, FolderStatusDelegate.FolderSyncPaused).to_bool ();
        bool folder_connected = _model.data (index, FolderStatusDelegate.FolderAccountConnected).to_bool ();
        auto folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder (alias);
        if (!folder)
            return;

        auto *menu = new QMenu (tv);

        menu.set_attribute (Qt.WA_DeleteOnClose);

        QAction *ac = menu.add_action (tr ("Open folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_open_current_folder);

        ac = menu.add_action (tr ("Edit Ignored Files"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_edit_current_ignored_files);

        ac = menu.add_action (tr ("Create new folder"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_open_make_folder_dialog);
        ac.set_enabled (QFile.exists (folder.path ()));

        if (!_ui._folder_list.is_expanded (index) && folder.supports_selective_sync ()) {
            ac = menu.add_action (tr ("Choose what to sync"));
            ac.set_enabled (folder_connected);
            connect (ac, &QAction.triggered, this, &AccountSettings.do_expand);
        }

        if (!folder_paused) {
            ac = menu.add_action (tr ("Force sync now"));
            if (folder && folder.is_sync_running ()) {
                ac.set_text (tr ("Restart sync"));
            }
            ac.set_enabled (folder_connected);
            connect (ac, &QAction.triggered, this, &AccountSettings.slot_force_sync_current_folder);
        }

        ac = menu.add_action (folder_paused ? tr ("Resume sync") : tr ("Pause sync"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_enable_current_folder);

        ac = menu.add_action (tr ("Remove folder sync connection"));
        connect (ac, &QAction.triggered, this, &AccountSettings.slot_remove_current_folder);

        if (folder.virtual_files_enabled ()) {
            auto availability_menu = menu.add_menu (tr ("Availability"));

            ac = availability_menu.add_action (Utility.vfs_pin_action_text ());
            connect (ac, &QAction.triggered, this, [this] () {
                slot_set_current_folder_availability (PinState.AlwaysLocal);
            });
            ac.set_disabled (Theme.instance ().enforce_virtual_files_sync_folder ());

            ac = availability_menu.add_action (Utility.vfs_free_space_action_text ());
            connect (ac, &QAction.triggered, this, [this] () {
                slot_set_current_folder_availability (PinState.OnlineOnly);
            });

            ac = menu.add_action (tr ("Disable virtual file support …"));
            connect (ac, &QAction.triggered, this, &AccountSettings.slot_disable_vfs_current_folder);
            ac.set_disabled (Theme.instance ().enforce_virtual_files_sync_folder ());
        }

        if (Theme.instance ().show_virtual_files_option ()
            && !folder.virtual_files_enabled () && Vfs.check_availability (folder.path ())) {
            const auto mode = best_available_vfs_mode ();
            if (mode == Vfs.WindowsCfApi || ConfigFile ().show_experimental_options ()) {
                ac = menu.add_action (tr ("Enable virtual file support %1 …").arg (mode == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
                // TODO : remove when UX decision is made
                ac.set_enabled (!Utility.is_path_windows_drive_partition_root (folder.path ()));
                //
                connect (ac, &QAction.triggered, this, &AccountSettings.slot_enable_vfs_current_folder);
            }
        }

        menu.popup (tv.map_to_global (pos));
    }

    void AccountSettings.slot_folder_list_clicked (QModelIndex &indx) {
        if (indx.data (FolderStatusDelegate.AddButton).to_bool ()) {
            // "Add Folder Sync Connection"
            QTreeView *tv = _ui._folder_list;
            auto pos = tv.map_from_global (QCursor.pos ());
            QStyleOptionViewItem opt;
            opt.init_from (tv);
            auto btn_rect = tv.visual_rect (indx);
            auto btn_size = tv.item_delegate (indx).size_hint (opt, indx);
            auto actual = QStyle.visual_rect (opt.direction, btn_rect, QRect (btn_rect.top_left (), btn_size));
            if (!actual.contains (pos))
                return;

            if (indx.flags () & Qt.ItemIsEnabled) {
                slot_add_folder ();
            } else {
                QToolTip.show_text (
                    QCursor.pos (),
                    _model.data (indx, Qt.ToolTipRole).to_string (),
                    this);
            }
            return;
        }
        if (_model.classify (indx) == FolderStatusModel.RootFolder) {
            // tries to find if we clicked on the '...' button.
            QTreeView *tv = _ui._folder_list;
            auto pos = tv.map_from_global (QCursor.pos ());
            if (FolderStatusDelegate.options_button_rect (tv.visual_rect (indx), layout_direction ()).contains (pos)) {
                slot_custom_context_menu_requested (pos);
                return;
            }
            if (FolderStatusDelegate.errors_list_rect (tv.visual_rect (indx)).contains (pos)) {
                emit show_issues_list (_account_state);
                return;
            }

            // Expand root items on single click
            if (_account_state && _account_state.state () == AccountState.Connected) {
                bool expanded = ! (_ui._folder_list.is_expanded (indx));
                _ui._folder_list.set_expanded (indx, expanded);
            }
        }
    }

    void AccountSettings.slot_add_folder () {
        FolderMan *folder_man = FolderMan.instance ();
        folder_man.set_sync_enabled (false); // do not start more syncs.

        auto *folder_wizard = new FolderWizard (_account_state.account (), this);
        folder_wizard.set_attribute (Qt.WA_DeleteOnClose);

        connect (folder_wizard, &Gtk.Dialog.accepted, this, &AccountSettings.slot_folder_wizard_accepted);
        connect (folder_wizard, &Gtk.Dialog.rejected, this, &AccountSettings.slot_folder_wizard_rejected);
        folder_wizard.open ();
    }

    void AccountSettings.slot_folder_wizard_accepted () {
        auto *folder_wizard = qobject_cast<FolderWizard> (sender ());
        FolderMan *folder_man = FolderMan.instance ();

        q_c_info (lc_account_settings) << "Folder wizard completed";

        FolderDefinition definition;
        definition.local_path = FolderDefinition.prepare_local_path (
            folder_wizard.field (QLatin1String ("source_folder")).to_string ());
        definition.target_path = FolderDefinition.prepare_target_path (
            folder_wizard.property ("target_path").to_string ());

        if (folder_wizard.property ("use_virtual_files").to_bool ()) {
            definition.virtual_files_mode = best_available_vfs_mode ();
        }
     {
            QDir dir (definition.local_path);
            if (!dir.exists ()) {
                q_c_info (lc_account_settings) << "Creating folder" << definition.local_path;
                if (!dir.mkpath (".")) {
                    QMessageBox.warning (this, tr ("Folder creation failed"),
                        tr ("<p>Could not create local folder <i>%1</i>.</p>")
                            .arg (QDir.to_native_separators (definition.local_path)));
                    return;
                }
            }
            FileSystem.set_folder_minimum_permissions (definition.local_path);
            Utility.setup_fav_link (definition.local_path);
        }

        /***********************************************************
        take the value from the definition of already existing folders. All folders have
        the same setting so far.
        The default is to sync hidden files
        ***********************************************************/
        definition.ignore_hidden_files = folder_man.ignore_hidden_files ();

        if (folder_man.navigation_pane_helper ().show_in_explorer_navigation_pane ())
            definition.navigation_pane_clsid = QUuid.create_uuid ();

        auto selective_sync_black_list = folder_wizard.property ("selective_sync_black_list").to_string_list ();

        folder_man.set_sync_enabled (true);

        Folder *f = folder_man.add_folder (_account_state, definition);
        if (f) {
            if (definition.virtual_files_mode != Vfs.Off && folder_wizard.property ("use_virtual_files").to_bool ())
                f.set_root_pin_state (PinState.OnlineOnly);

            f.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, selective_sync_black_list);

            // The user already accepted the selective sync dialog. everything is in the white list
            f.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList,
                QStringList () << QLatin1String ("/"));
            folder_man.schedule_all_folders ();
            emit folder_changed ();
        }
    }

    void AccountSettings.slot_folder_wizard_rejected () {
        q_c_info (lc_account_settings) << "Folder wizard cancelled";
        FolderMan *folder_man = FolderMan.instance ();
        folder_man.set_sync_enabled (true);
    }

    void AccountSettings.slot_remove_current_folder () {
        auto folder = FolderMan.instance ().folder (selected_folder_alias ());
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (selected.is_valid () && folder) {
            int row = selected.row ();

            q_c_info (lc_account_settings) << "Remove Folder alias " << folder.alias ();
            string short_gui_local_path = folder.short_gui_local_path ();

            auto message_box = new QMessageBox (QMessageBox.Question,
                tr ("Confirm Folder Sync Connection Removal"),
                tr ("<p>Do you really want to stop syncing the folder <i>%1</i>?</p>"
                   "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                    .arg (short_gui_local_path),
                QMessageBox.NoButton,
                this);
            message_box.set_attribute (Qt.WA_DeleteOnClose);
            QPushButton *yes_button =
                message_box.add_button (tr ("Remove Folder Sync Connection"), QMessageBox.YesRole);
            message_box.add_button (tr ("Cancel"), QMessageBox.NoRole);
            connect (message_box, &QMessageBox.finished, this, [message_box, yes_button, folder, row, this]{
                if (message_box.clicked_button () == yes_button) {
                    Utility.remove_fav_link (folder.path ());
                    FolderMan.instance ().remove_folder (folder);
                    _model.remove_row (row);

                    // single folder fix to show add-button and hide remove-button
                    emit folder_changed ();
                }
            });
            message_box.open ();
        }
    }

    void AccountSettings.slot_open_current_folder () {
        auto alias = selected_folder_alias ();
        if (!alias.is_empty ()) {
            emit open_folder_alias (alias);
        }
    }

    void AccountSettings.slot_open_current_local_sub_folder () {
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || _model.classify (selected) != FolderStatusModel.SubFolder)
            return;
        string file_name = _model.data (selected, FolderStatusDelegate.FolderPathRole).to_string ();
        QUrl url = QUrl.from_local_file (file_name);
        QDesktopServices.open_url (url);
    }

    void AccountSettings.slot_enable_vfs_current_folder () {
        FolderMan *folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder (selected_folder_alias ());
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        OwncloudWizard.ask_experimental_virtual_files_feature (this, [folder, this] (bool enable) {
            if (!enable || !folder)
                return;

            // we might need to add or remove the panel entry as cfapi brings this feature out of the box
            FolderMan.instance ().navigation_pane_helper ().schedule_update_cloud_storage_registry ();

            // It is unsafe to switch on vfs while a sync is running - wait if necessary.
            auto connection = std.make_shared<QMetaObject.Connection> ();
            auto switch_vfs_on = [folder, connection, this] () {
                if (*connection)
                    GLib.Object.disconnect (*connection);

                q_c_info (lc_account_settings) << "Enabling vfs support for folder" << folder.path ();

                // Wipe selective sync blacklist
                bool ok = false;
                const auto old_blacklist = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
                folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, {});

                // Change the folder vfs mode and load the plugin
                folder.set_virtual_files_enabled (true);
                folder.set_vfs_on_off_switch_pending (false);

                // Setting to Unspecified retains existing data.
                // Selective sync excluded folders become OnlineOnly.
                folder.set_root_pin_state (PinState.Unspecified);
                for (auto &entry : old_blacklist) {
                    folder.journal_db ().schedule_path_for_remote_discovery (entry);
                    if (!folder.vfs ().set_pin_state (entry, PinState.OnlineOnly)) {
                        q_c_warning (lc_account_settings) << "Could not set pin state of" << entry << "to online only";
                    }
                }
                folder.slot_next_sync_full_local_discovery ();

                FolderMan.instance ().schedule_folder (folder);

                _ui._folder_list.do_items_layout ();
                _ui.selective_sync_status.set_visible (false);
            };

            if (folder.is_sync_running ()) {
                *connection = connect (folder, &Folder.sync_finished, this, switch_vfs_on);
                folder.set_vfs_on_off_switch_pending (true);
                folder.slot_terminate_sync ();
                _ui._folder_list.do_items_layout ();
            } else {
                switch_vfs_on ();
            }
        });
    }

    void AccountSettings.slot_disable_vfs_current_folder () {
        FolderMan *folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder (selected_folder_alias ());
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        auto msg_box = new QMessageBox (
            QMessageBox.Question,
            tr ("Disable virtual file support?"),
            tr ("This action will disable virtual file support. As a consequence contents of folders that "
               "are currently marked as \"available online only\" will be downloaded."
               "\n\n"
               "The only advantage of disabling virtual file support is that the selective sync feature "
               "will become available again."
               "\n\n"
               "This action will abort any currently running synchronization."));
        auto accept_button = msg_box.add_button (tr ("Disable support"), QMessageBox.AcceptRole);
        msg_box.add_button (tr ("Cancel"), QMessageBox.RejectRole);
        connect (msg_box, &QMessageBox.finished, msg_box, [this, msg_box, folder, accept_button] {
            msg_box.delete_later ();
            if (msg_box.clicked_button () != accept_button|| !folder)
                return;

            // we might need to add or remove the panel entry as cfapi brings this feature out of the box
            FolderMan.instance ().navigation_pane_helper ().schedule_update_cloud_storage_registry ();

            // It is unsafe to switch off vfs while a sync is running - wait if necessary.
            auto connection = std.make_shared<QMetaObject.Connection> ();
            auto switch_vfs_off = [folder, connection, this] () {
                if (*connection)
                    GLib.Object.disconnect (*connection);

                q_c_info (lc_account_settings) << "Disabling vfs support for folder" << folder.path ();

                // Also wipes virtual files, schedules remote discovery
                folder.set_virtual_files_enabled (false);
                folder.set_vfs_on_off_switch_pending (false);

                // Wipe pin states and selective sync db
                folder.set_root_pin_state (PinState.AlwaysLocal);
                folder.journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, {});

                // Prevent issues with missing local files
                folder.slot_next_sync_full_local_discovery ();

                FolderMan.instance ().schedule_folder (folder);

                _ui._folder_list.do_items_layout ();
            };

            if (folder.is_sync_running ()) {
                *connection = connect (folder, &Folder.sync_finished, this, switch_vfs_off);
                folder.set_vfs_on_off_switch_pending (true);
                folder.slot_terminate_sync ();
                _ui._folder_list.do_items_layout ();
            } else {
                switch_vfs_off ();
            }
        });
        msg_box.open ();
    }

    void AccountSettings.slot_set_current_folder_availability (PinState state) {
        ASSERT (state == PinState.OnlineOnly || state == PinState.AlwaysLocal);

        FolderMan *folder_man = FolderMan.instance ();
        QPointer<Folder> folder = folder_man.folder (selected_folder_alias ());
        QModelIndex selected = _ui._folder_list.selection_model ().current_index ();
        if (!selected.is_valid () || !folder)
            return;

        // similar to socket api : sets pin state recursively and sync
        folder.set_root_pin_state (state);
        folder.schedule_this_folder_soon ();
    }

    void AccountSettings.slot_set_sub_folder_availability (Folder *folder, string &path, PinState state) {
        Q_ASSERT (folder && folder.virtual_files_enabled ());
        Q_ASSERT (!path.ends_with ('/'));

        // Update the pin state on all items
        if (!folder.vfs ().set_pin_state (path, state)) {
            q_c_warning (lc_account_settings) << "Could not set pin state of" << path << "to" << state;
        }

        // Trigger sync
        folder.schedule_path_for_local_discovery (path);
        folder.schedule_this_folder_soon ();
    }

    void AccountSettings.show_connection_label (string &message, QStringList errors) {
        const string err_style = QLatin1String ("color:#ffffff; background-color:#bb4d4d;padding:5px;"
                                               "border-width : 1px; border-style : solid; border-color : #aaaaaa;"
                                               "border-radius:5px;");
        if (errors.is_empty ()) {
            string msg = message;
            Theme.replace_link_color_string_background_aware (msg);
            _ui.connect_label.set_text (msg);
            _ui.connect_label.set_tool_tip (string ());
            _ui.connect_label.set_style_sheet (string ());
        } else {
            errors.prepend (message);
            string msg = errors.join (QLatin1String ("\n"));
            q_c_debug (lc_account_settings) << msg;
            Theme.replace_link_color_string (msg, QColor ("#c1c8e6"));
            _ui.connect_label.set_text (msg);
            _ui.connect_label.set_tool_tip (string ());
            _ui.connect_label.set_style_sheet (err_style);
        }
        _ui.account_status.set_visible (!message.is_empty ());
    }

    void AccountSettings.slot_enable_current_folder (bool terminate) {
        auto alias = selected_folder_alias ();

        if (!alias.is_empty ()) {
            FolderMan *folder_man = FolderMan.instance ();

            q_c_info (lc_account_settings) << "Application : enable folder with alias " << alias;
            bool currently_paused = false;

            // this sets the folder status to disabled but does not interrupt it.
            Folder *f = folder_man.folder (alias);
            if (!f) {
                return;
            }
            currently_paused = f.sync_paused ();
            if (!currently_paused && !terminate) {
                // check if a sync is still running and if so, ask if we should terminate.
                if (f.is_busy ()) { // its still running
                    auto msgbox = new QMessageBox (QMessageBox.Question, tr ("Sync Running"),
                        tr ("The syncing operation is running.<br/>Do you want to terminate it?"),
                        QMessageBox.Yes | QMessageBox.No, this);
                    msgbox.set_attribute (Qt.WA_DeleteOnClose);
                    msgbox.set_default_button (QMessageBox.Yes);
                    connect (msgbox, &QMessageBox.accepted, this, [this]{
                        slot_enable_current_folder (true);
                    });
                    msgbox.open ();
                    return;
                }
            }

            // message box can return at any time while the thread keeps running,
            // so better check again after the user has responded.
            if (f.is_busy () && terminate) {
                f.slot_terminate_sync ();
            }
            f.set_sync_paused (!currently_paused);

            // keep state for the icon setting.
            if (currently_paused)
                _was_disabled_before = true;

            _model.slot_update_folder_state (f);
        }
    }

    void AccountSettings.slot_schedule_current_folder () {
        FolderMan *folder_man = FolderMan.instance ();
        if (auto folder = folder_man.folder (selected_folder_alias ())) {
            folder_man.schedule_folder (folder);
        }
    }

    void AccountSettings.slot_schedule_current_folder_force_remote_discovery () {
        FolderMan *folder_man = FolderMan.instance ();
        if (auto folder = folder_man.folder (selected_folder_alias ())) {
            folder.slot_wipe_error_blacklist ();
            folder.journal_db ().force_remote_discovery_next_sync ();
            folder_man.schedule_folder (folder);
        }
    }

    void AccountSettings.slot_force_sync_current_folder () {
        FolderMan *folder_man = FolderMan.instance ();
        if (auto selected_folder = folder_man.folder (selected_folder_alias ())) {
            // Terminate and reschedule any running sync
            for (auto f : folder_man.map ()) {
                if (f.is_sync_running ()) {
                    f.slot_terminate_sync ();
                    folder_man.schedule_folder (f);
                }
            }

            selected_folder.slot_wipe_error_blacklist (); // issue #6757

            // Insert the selected folder at the front of the queue
            folder_man.schedule_folder_next (selected_folder);
        }
    }

    void AccountSettings.slot_open_oC () {
        if (_OCUrl.is_valid ()) {
            Utility.open_browser (_OCUrl);
        }
    }

    void AccountSettings.slot_update_quota (int64 total, int64 used) {
        if (total > 0) {
            _ui.quota_progress_bar.set_visible (true);
            _ui.quota_progress_bar.set_enabled (true);
            // workaround the label only accepting ints (which may be only 32 bit wide)
            const double percent = used / (double)total * 100;
            const int percent_int = q_min (q_round (percent), 100);
            _ui.quota_progress_bar.set_value (percent_int);
            string used_str = Utility.octets_to_string (used);
            string total_str = Utility.octets_to_string (total);
            string percent_str = Utility.compact_format_double (percent, 1);
            string tool_tip = tr ("%1 (%3%) of %2 in use. Some folders, including network mounted or shared folders, might have different limits.").arg (used_str, total_str, percent_str);
            _ui.quota_info_label.set_text (tr ("%1 of %2 in use").arg (used_str, total_str));
            _ui.quota_info_label.set_tool_tip (tool_tip);
            _ui.quota_progress_bar.set_tool_tip (tool_tip);
        } else {
            _ui.quota_progress_bar.set_visible (false);
            _ui.quota_info_label.set_tool_tip (string ());

            /* -1 means not computed; -2 means unknown; -3 means unlimited  (#owncloud/client/issues/3940)*/
            if (total == 0 || total == -1) {
                _ui.quota_info_label.set_text (tr ("Currently there is no storage usage information available."));
            } else {
                string used_str = Utility.octets_to_string (used);
                _ui.quota_info_label.set_text (tr ("%1 in use").arg (used_str));
            }
        }
    }

    void AccountSettings.slot_account_state_changed () {
        const AccountState.State state = _account_state ? _account_state.state () : AccountState.Disconnected;
        if (state != AccountState.Disconnected) {
            _ui.ssl_button.update_account_state (_account_state);
            AccountPtr account = _account_state.account ();
            QUrl safe_url (account.url ());
            safe_url.set_password (string ()); // Remove the password from the URL to avoid showing it in the UI
            const auto folders = FolderMan.instance ().map ().values ();
            for (Folder *folder : folders) {
                _model.slot_update_folder_state (folder);
            }

            const string server = string.from_latin1 ("<a href=\"%1\">%2</a>")
                                       .arg (Utility.escape (account.url ().to_string ()),
                                           Utility.escape (safe_url.to_string ()));
            string server_with_user = server;
            if (AbstractCredentials *cred = account.credentials ()) {
                string user = account.dav_display_name ();
                if (user.is_empty ()) {
                    user = cred.user ();
                }
                server_with_user = tr ("%1 as %2").arg (server, Utility.escape (user));
            }

            switch (state) {
            case AccountState.Connected : {
                QStringList errors;
                if (account.server_version_unsupported ()) {
                    errors << tr ("The server version %1 is unsupported! Proceed at your own risk.").arg (account.server_version ());
                }
                show_connection_label (tr ("Connected to %1.").arg (server_with_user), errors);
                break;
            }
            case AccountState.ServiceUnavailable:
                show_connection_label (tr ("Server %1 is temporarily unavailable.").arg (server));
                break;
            case AccountState.MaintenanceMode:
                show_connection_label (tr ("Server %1 is currently in maintenance mode.").arg (server));
                break;
            case AccountState.SignedOut:
                show_connection_label (tr ("Signed out from %1.").arg (server_with_user));
                break;
            case AccountState.AskingCredentials : {
                QUrl url;
                if (auto cred = qobject_cast<HttpCredentialsGui> (account.credentials ())) {
                    connect (cred, &HttpCredentialsGui.authorisation_link_changed,
                        this, &AccountSettings.slot_account_state_changed, Qt.UniqueConnection);
                    url = cred.authorisation_link ();
                }
                if (url.is_valid ()) {
                    show_connection_label (tr ("Obtaining authorization from the browser. "
                                           "<a href='%1'>Click here</a> to re-open the browser.")
                                            .arg (url.to_string (QUrl.FullyEncoded)));
                } else {
                    show_connection_label (tr ("Connecting to %1 …").arg (server_with_user));
                }
                break;
            }
            case AccountState.NetworkError:
                show_connection_label (tr ("No connection to %1 at %2.")
                                        .arg (Utility.escape (Theme.instance ().app_name_g_u_i ()), server),
                    _account_state.connection_errors ());
                break;
            case AccountState.ConfigurationError:
                show_connection_label (tr ("Server configuration error : %1 at %2.")
                                        .arg (Utility.escape (Theme.instance ().app_name_g_u_i ()), server),
                    _account_state.connection_errors ());
                break;
            case AccountState.Disconnected:
                // we can't end up here as the whole block is ifdeffed
                Q_UNREACHABLE ();
                break;
            }
        } else {
            // own_cloud is not yet configured.
            show_connection_label (tr ("No %1 connection configured.")
                                    .arg (Utility.escape (Theme.instance ().app_name_g_u_i ())));
        }

        /* Allow to expand the item if the account is connected. */
        _ui._folder_list.set_items_expandable (state == AccountState.Connected);

        if (state != AccountState.Connected) {
            /* check if there are expanded root items, if so, close them */
            int i = 0;
            for (i = 0; i < _model.row_count (); ++i) {
                if (_ui._folder_list.is_expanded (_model.index (i)))
                    _ui._folder_list.set_expanded (_model.index (i), false);
            }
        } else if (_model.is_dirty ()) {
            // If we connect and have pending changes, show the list.
            do_expand ();
        }

        // Disabling expansion of folders might require hiding the selective
        // sync user interface buttons.
        refresh_selective_sync_status ();

        if (state == AccountState.State.Connected) {
            /* TODO : We should probably do something better here.
            Verify if the user has a private key already uploaded to the server,
            if it has, do not offer to create one.
             */
            q_c_info (lc_account_settings) << "Account" << accounts_state ().account ().display_name ()
                << "Client Side Encryption" << accounts_state ().account ().capabilities ().client_side_encryption_available ();

            if (_account_state.account ().capabilities ().client_side_encryption_available ()) {
                _ui.encryption_message.show ();
            }
        }
    }

    void AccountSettings.slot_link_activated (string &link) {
        // Parse folder alias and filename from the link, calculate the index
        // and select it if it exists.
        const QStringList li = link.split (QLatin1String ("?folder="));
        if (li.count () > 1) {
            string my_folder = li[0];
            const string alias = li[1];
            if (my_folder.ends_with (QLatin1Char ('/')))
                my_folder.chop (1);

            // Make sure the folder itself is expanded
            Folder *f = FolderMan.instance ().folder (alias);
            QModelIndex folder_indx = _model.index_for_path (f, string ());
            if (!_ui._folder_list.is_expanded (folder_indx)) {
                _ui._folder_list.set_expanded (folder_indx, true);
            }

            QModelIndex indx = _model.index_for_path (f, my_folder);
            if (indx.is_valid ()) {
                // make sure all the parents are expanded
                for (auto i = indx.parent (); i.is_valid (); i = i.parent ()) {
                    if (!_ui._folder_list.is_expanded (i)) {
                        _ui._folder_list.set_expanded (i, true);
                    }
                }
                _ui._folder_list.set_selection_mode (QAbstractItemView.SingleSelection);
                _ui._folder_list.set_current_index (indx);
                _ui._folder_list.scroll_to (indx);
            } else {
                q_c_warning (lc_account_settings) << "Unable to find a valid index for " << my_folder;
            }
        }
    }

    AccountSettings.~AccountSettings () {
        delete _ui;
    }

    void AccountSettings.slot_hide_selective_sync_widget () {
        _ui.selective_sync_apply.set_enabled (false);
        _ui.selective_sync_status.set_visible (false);
        _ui.selective_sync_buttons.set_visible (false);
        _ui.selective_sync_label.hide ();
    }

    void AccountSettings.slot_selective_sync_changed (QModelIndex &top_left,
                                                   const QModelIndex &bottom_right,
                                                   const QVector<int> &roles) {
        Q_UNUSED (bottom_right);
        if (!roles.contains (Qt.CheckStateRole)) {
            return;
        }

        const auto info = _model.info_for_index (top_left);
        if (!info) {
            return;
        }

        const bool show_warning = _model.is_dirty () && _account_state.is_connected () && info._checked == Qt.Unchecked;

        // FIXME : the model is not precise enough to handle extra cases
        // e.g. the user clicked on the same checkbox 2x without applying the change in between.
        // We don't know which checkbox changed to be able to toggle the selective_sync_label display.
        if (show_warning) {
            _ui.selective_sync_label.show ();
        }

        const bool should_be_visible = _model.is_dirty ();
        const bool was_visible = _ui.selective_sync_status.is_visible ();
        if (should_be_visible) {
            _ui.selective_sync_status.set_visible (true);
        }

        _ui.selective_sync_apply.set_enabled (true);
        _ui.selective_sync_buttons.set_visible (true);

        if (should_be_visible != was_visible) {
            const auto hint = _ui.selective_sync_status.size_hint ();

            if (should_be_visible) {
                _ui.selective_sync_status.set_maximum_height (0);
            }

            const auto anim = new QPropertyAnimation (_ui.selective_sync_status, "maximum_height", _ui.selective_sync_status);
            anim.set_end_value (_model.is_dirty () ? hint.height () : 0);
            anim.start (QAbstractAnimation.DeleteWhenStopped);
            connect (anim, &QPropertyAnimation.finished, [this, should_be_visible] () {
                _ui.selective_sync_status.set_maximum_height (QWIDGETSIZE_MAX);
                if (!should_be_visible) {
                    _ui.selective_sync_status.hide ();
                }
            });
        }
    }

    void AccountSettings.refresh_selective_sync_status () {
        string msg;
        int cnt = 0;
        const auto folders = FolderMan.instance ().map ().values ();
        _ui.big_folder_ui.set_visible (false);
        for (Folder *folder : folders) {
            if (folder.account_state () != _account_state) {
                continue;
            }

            bool ok = false;
            const auto undecided_list = folder.journal_db ().get_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, &ok);
            for (auto &it : undecided_list) {
                // FIXME : add the folder alias in a hoover hint.
                // folder.alias () + QLatin1String ("/")
                if (cnt++) {
                    msg += QLatin1String (", ");
                }
                string my_folder = (it);
                if (my_folder.ends_with ('/')) {
                    my_folder.chop (1);
                }
                QModelIndex the_indx = _model.index_for_path (folder, my_folder);
                if (the_indx.is_valid ()) {
                    msg += string.from_latin1 ("<a href=\"%1?folder=%2\">%1</a>")
                               .arg (Utility.escape (my_folder), Utility.escape (folder.alias ()));
                } else {
                    msg += my_folder; // no link because we do not know the index yet.
                }
            }
        }

        if (!msg.is_empty ()) {
            ConfigFile cfg;
            string info = !cfg.confirm_external_storage ()
                    ? tr ("There are folders that were not synchronized because they are too big : ")
                    : !cfg.new_big_folder_size_limit ().first
                      ? tr ("There are folders that were not synchronized because they are external storages : ")
                      : tr ("There are folders that were not synchronized because they are too big or external storages : ");

            _ui.selective_sync_notification.set_text (info + msg);
            _ui.big_folder_ui.set_visible (true);
        }
    }

    void AccountSettings.slot_delete_account () {
        // Deleting the account potentially deletes 'this', so
        // the QMessageBox should be destroyed before that happens.
        auto message_box = new QMessageBox (QMessageBox.Question,
            tr ("Confirm Account Removal"),
            tr ("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
               "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                .arg (_account_state.account ().display_name ()),
            QMessageBox.NoButton,
            this);
        auto yes_button = message_box.add_button (tr ("Remove connection"), QMessageBox.YesRole);
        message_box.add_button (tr ("Cancel"), QMessageBox.NoRole);
        message_box.set_attribute (Qt.WA_DeleteOnClose);
        connect (message_box, &QMessageBox.finished, this, [this, message_box, yes_button]{
            if (message_box.clicked_button () == yes_button) {
                // Else it might access during destruction. This should be better handled by it having a QSharedPointer
                _model.set_account_state (nullptr);

                auto manager = AccountManager.instance ();
                manager.delete_account (_account_state);
                manager.save ();
            }
        });
        message_box.open ();
    }

    bool AccountSettings.event (QEvent *e) {
        if (e.type () == QEvent.Hide || e.type () == QEvent.Show) {
            _user_info.set_active (is_visible ());
        }
        if (e.type () == QEvent.Show) {
            // Expand the folder automatically only if there's only one, see #4283
            // The 2 is 1 folder + 1 'add folder' button
            if (_model.row_count () <= 2) {
                _ui._folder_list.set_expanded (_model.index (0, 0), true);
            }
        }
        return Gtk.Widget.event (e);
    }

    void AccountSettings.slot_style_changed () {
        customize_style ();

        // Notify the other widgets (Dark-/Light-Mode switching)
        emit style_changed ();
    }

    void AccountSettings.customize_style () {
        string msg = _ui.connect_label.text ();
        Theme.replace_link_color_string_background_aware (msg);
        _ui.connect_label.set_text (msg);

        QColor color = palette ().highlight ().color ();
        _ui.quota_progress_bar.set_style_sheet (string.from_latin1 (progress_bar_style_c).arg (color.name ()));
    }

    } // namespace Occ

    #include "accountsettings.moc"
    