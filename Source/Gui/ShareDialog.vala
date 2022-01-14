/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileInfo>
// #include <QFile_icon_provider>
// #include <QInputDialog>
// #include <QPointer>
// #include <QPushButton>
// #include <QFrame>

// #include <QSharedPointer>
// #include <QPointer>
// #include <string>
// #include <Gtk.Dialog>
// #include <Gtk.Widget>

namespace {
    string create_random_password () {
        const auto words = Occ.Word_list.get_random_words (10);
    
        const auto add_first_letter = [] (string &current, string &next) . string {
            return current + next.at (0);
        };
    
        return std.accumulate (std.cbegin (words), std.cend (words), string (), add_first_letter);
    }
}

namespace Occ {

namespace Ui {
    class Share_dialog;
}

class Link_share;

class Share_dialog : Gtk.Dialog {

public:
    Share_dialog (QPointer<AccountState> account_state,
        const string &share_path,
        const string &local_path,
        Share_permissions max_sharing_permissions,
        const QByteArray &numeric_file_id,
        Share_dialog_start_page start_page,
        Gtk.Widget *parent = nullptr);
    ~Share_dialog () override;

private slots:
    void done (int r) override;
    void slot_propfind_received (QVariantMap &result);
    void slot_propfind_error ();
    void slot_thumbnail_fetched (int &status_code, QByteArray &reply);
    void slot_account_state_changed (int state);

    void slot_shares_fetched (QList<QSharedPointer<Share>> &shares);
    void slot_add_link_share_widget (QSharedPointer<Link_share> &link_share);
    void slot_delete_share ();
    void slot_create_link_share ();
    void slot_create_password_for_link_share (string &password);
    void slot_create_password_for_link_share_processed ();
    void slot_link_share_requires_password ();
    void slot_adjust_scroll_widget_size ();

signals:
    void toggle_share_link_animation (bool start);
    void style_changed ();

protected:
    void change_event (QEvent *) override;

private:
    void show_sharing_ui ();
    Share_link_widget *add_link_share_widget (QSharedPointer<Link_share> &link_share);
    void init_link_share_widget ();

    Ui.Share_dialog *_ui;

    QPointer<AccountState> _account_state;
    string _share_path;
    string _local_path;
    Share_permissions _max_sharing_permissions;
    QByteArray _numeric_file_id;
    string _private_link_url;
    Share_dialog_start_page _start_page;
    Share_manager *_manager = nullptr;

    QList<Share_link_widget> _link_widget_list;
    Share_link_widget* _empty_share_link_widget = nullptr;
    Share_user_group_widget *_user_group_widget = nullptr;
    QProgress_indicator *_progress_indicator = nullptr;
};
    
    static const int thumbnail_size = 40;
    
    Share_dialog.Share_dialog (QPointer<AccountState> account_state,
        const string &share_path,
        const string &local_path,
        Share_permissions max_sharing_permissions,
        const QByteArray &numeric_file_id,
        Share_dialog_start_page start_page,
        Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.Share_dialog)
        , _account_state (account_state)
        , _share_path (share_path)
        , _local_path (local_path)
        , _max_sharing_permissions (max_sharing_permissions)
        , _private_link_url (account_state.account ().deprecated_private_link_url (numeric_file_id).to_string (QUrl.FullyEncoded))
        , _start_page (start_page) {
        set_window_flags (window_flags () & ~Qt.Window_context_help_button_hint);
        set_attribute (Qt.WA_DeleteOnClose);
        set_object_name ("Sharing_dialog"); // required as group for save_geometry call
    
        _ui.setup_ui (this);
    
        // We want to act on account state changes
        connect (_account_state.data (), &AccountState.state_changed, this, &Share_dialog.slot_account_state_changed);
    
        // Set icon
        QFileInfo f_info (_local_path);
        QFile_icon_provider icon_provider;
        QIcon icon = icon_provider.icon (f_info);
        auto pixmap = icon.pixmap (thumbnail_size, thumbnail_size);
        if (pixmap.width () > 0) {
            _ui.label_icon.set_pixmap (pixmap);
        }
    
        // Set filename
        string file_name = QFileInfo (_share_path).file_name ();
        _ui.label_name.set_text (tr ("%1").arg (file_name));
        QFont f (_ui.label_name.font ());
        f.set_point_size (q_round (f.point_size () * 1.4));
        _ui.label_name.set_font (f);
    
        string oc_dir (_share_path);
        oc_dir.truncate (oc_dir.length () - file_name.length ());
    
        oc_dir.replace (QRegularExpression ("^/*"), "");
        oc_dir.replace (QRegularExpression ("/*$"), "");
    
        // Laying this out is complex because share_path
        // may be in use or not.
        _ui.grid_layout.remove_widget (_ui.label_share_path);
        _ui.grid_layout.remove_widget (_ui.label_name);
        if (oc_dir.is_empty ()) {
            _ui.grid_layout.add_widget (_ui.label_name, 0, 1, 2, 1);
            _ui.label_share_path.set_text (string ());
        } else {
            _ui.grid_layout.add_widget (_ui.label_name, 0, 1, 1, 1);
            _ui.grid_layout.add_widget (_ui.label_share_path, 1, 1, 1, 1);
            _ui.label_share_path.set_text (tr ("Folder : %2").arg (oc_dir));
        }
    
        this.set_window_title (tr ("%1 Sharing").arg (Theme.instance ().app_name_g_u_i ()));
    
        if (!account_state.account ().capabilities ().share_a_p_i ()) {
            return;
        }
    
        if (QFileInfo (_local_path).is_file ()) {
            auto *job = new Thumbnail_job (_share_path, _account_state.account (), this);
            connect (job, &Thumbnail_job.job_finished, this, &Share_dialog.slot_thumbnail_fetched);
            job.start ();
        }
    
        auto job = new PropfindJob (account_state.account (), _share_path);
        job.set_properties (
            QList<QByteArray> ()
            << "http://open-collaboration-services.org/ns:share-permissions"
            << "http://owncloud.org/ns:fileid" // numeric file id for fallback private link generation
            << "http://owncloud.org/ns:privatelink");
        job.set_timeout (10 * 1000);
        connect (job, &PropfindJob.result, this, &Share_dialog.slot_propfind_received);
        connect (job, &PropfindJob.finished_with_error, this, &Share_dialog.slot_propfind_error);
        job.start ();
    
        bool sharing_possible = true;
        if (!account_state.account ().capabilities ().share_public_link ()) {
            q_c_warning (lc_sharing) << "Link shares have been disabled";
            sharing_possible = false;
        } else if (! (max_sharing_permissions & Share_permission_share)) {
            q_c_warning (lc_sharing) << "The file cannot be shared because it does not have sharing permission.";
            sharing_possible = false;
        }
    
        if (sharing_possible) {
            _manager = new Share_manager (account_state.account (), this);
            connect (_manager, &Share_manager.shares_fetched, this, &Share_dialog.slot_shares_fetched);
            connect (_manager, &Share_manager.link_share_created, this, &Share_dialog.slot_add_link_share_widget);
            connect (_manager, &Share_manager.link_share_requires_password, this, &Share_dialog.slot_link_share_requires_password);
        }
    }
    
    Share_link_widget *Share_dialog.add_link_share_widget (QSharedPointer<Link_share> &link_share) {
        _link_widget_list.append (new Share_link_widget (_account_state.account (), _share_path, _local_path, _max_sharing_permissions, this));
    
        const auto link_share_widget = _link_widget_list.at (_link_widget_list.size () - 1);
        link_share_widget.set_link_share (link_share);
    
        connect (link_share.data (), &Share.server_error, link_share_widget, &Share_link_widget.slot_server_error);
        connect (link_share.data (), &Share.share_deleted, link_share_widget, &Share_link_widget.slot_delete_share_fetched);
    
        if (_manager) {
            connect (_manager, &Share_manager.server_error, link_share_widget, &Share_link_widget.slot_server_error);
        }
    
        // Connect all shares signals to gui slots
        connect (this, &Share_dialog.toggle_share_link_animation, link_share_widget, &Share_link_widget.slot_toggle_share_link_animation);
        connect (link_share_widget, &Share_link_widget.create_link_share, this, &Share_dialog.slot_create_link_share);
        connect (link_share_widget, &Share_link_widget.delete_link_share, this, &Share_dialog.slot_delete_share);
        connect (link_share_widget, &Share_link_widget.create_password, this, &Share_dialog.slot_create_password_for_link_share);
    
        //connect (_link_widget_list.at (index), &Share_link_widget.resize_requested, this, &Share_dialog.slot_adjust_scroll_widget_size);
    
        // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
        connect (this, &Share_dialog.style_changed, link_share_widget, &Share_link_widget.slot_style_changed);
    
        _ui.vertical_layout.insert_widget (_link_widget_list.size () + 1, link_share_widget);
        link_share_widget.setup_ui_options ();
    
        return link_share_widget;
    }
    
    void Share_dialog.init_link_share_widget () {
        if (_link_widget_list.size () == 0) {
            _empty_share_link_widget = new Share_link_widget (_account_state.account (), _share_path, _local_path, _max_sharing_permissions, this);
            _link_widget_list.append (_empty_share_link_widget);
    
            connect (_empty_share_link_widget, &Share_link_widget.resize_requested, this, &Share_dialog.slot_adjust_scroll_widget_size);
            connect (this, &Share_dialog.toggle_share_link_animation, _empty_share_link_widget, &Share_link_widget.slot_toggle_share_link_animation);
            connect (_empty_share_link_widget, &Share_link_widget.create_link_share, this, &Share_dialog.slot_create_link_share);
    
            connect (_empty_share_link_widget, &Share_link_widget.create_password, this, &Share_dialog.slot_create_password_for_link_share);
    
            _ui.vertical_layout.insert_widget (_link_widget_list.size ()+1, _empty_share_link_widget);
            _empty_share_link_widget.show ();
        } else if (_empty_share_link_widget) {
            _empty_share_link_widget.hide ();
            _ui.vertical_layout.remove_widget (_empty_share_link_widget);
            _link_widget_list.remove_all (_empty_share_link_widget);
            _empty_share_link_widget = nullptr;
        }
    }
    
    void Share_dialog.slot_add_link_share_widget (QSharedPointer<Link_share> &link_share) {
        emit toggle_share_link_animation (true);
        const auto added_link_share_widget = add_link_share_widget (link_share);
        init_link_share_widget ();
        if (link_share.is_password_set ()) {
            added_link_share_widget.focus_password_line_edit ();
        }
        emit toggle_share_link_animation (false);
    }
    
    void Share_dialog.slot_shares_fetched (QList<QSharedPointer<Share>> &shares) {
        emit toggle_share_link_animation (true);
    
        const string version_string = _account_state.account ().server_version ();
        q_c_info (lc_sharing) << version_string << "Fetched" << shares.count () << "shares";
        foreach (auto share, shares) {
            if (share.get_share_type () != Share.Type_link || share.get_uid_owner () != share.account ().dav_user ()) {
                continue;
            }
    
            QSharedPointer<Link_share> link_share = q_shared_pointer_dynamic_cast<Link_share> (share);
            add_link_share_widget (link_share);
        }
    
        init_link_share_widget ();
        emit toggle_share_link_animation (false);
    }
    
    void Share_dialog.slot_adjust_scroll_widget_size () {
        int count = this.find_children<Share_link_widget> ().count ();
        _ui.scroll_area.set_visible (count > 0);
        if (count > 0 && count <= 3) {
            _ui.scroll_area.set_fixed_height (_ui.scroll_area.widget ().size_hint ().height ());
        }
        _ui.scroll_area.set_frame_shape (count > 3 ? QFrame.Styled_panel : QFrame.No_frame);
    }
    
    Share_dialog.~Share_dialog () {
        _link_widget_list.clear ();
        delete _ui;
    }
    
    void Share_dialog.done (int r) {
        ConfigFile cfg;
        cfg.save_geometry (this);
        Gtk.Dialog.done (r);
    }
    
    void Share_dialog.slot_propfind_received (QVariantMap &result) {
        const QVariant received_permissions = result["share-permissions"];
        if (!received_permissions.to_string ().is_empty ()) {
            _max_sharing_permissions = static_cast<Share_permissions> (received_permissions.to_int ());
            q_c_info (lc_sharing) << "Received sharing permissions for" << _share_path << _max_sharing_permissions;
        }
        auto private_link_url = result["privatelink"].to_string ();
        auto numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url.is_empty ()) {
            q_c_info (lc_sharing) << "Received private link url for" << _share_path << private_link_url;
            _private_link_url = private_link_url;
        } else if (!numeric_file_id.is_empty ()) {
            q_c_info (lc_sharing) << "Received numeric file id for" << _share_path << numeric_file_id;
            _private_link_url = _account_state.account ().deprecated_private_link_url (numeric_file_id).to_string (QUrl.FullyEncoded);
        }
    
        show_sharing_ui ();
    }
    
    void Share_dialog.slot_propfind_error () {
        // On error show the share ui anyway. The user can still see shares,
        // delete them and so on, even though adding new shares or granting
        // some of the permissions might fail.
    
        show_sharing_ui ();
    }
    
    void Share_dialog.show_sharing_ui () {
        auto theme = Theme.instance ();
    
        // There's no difference between being unable to reshare and
        // being unable to reshare with reshare permission.
        bool can_reshare = _max_sharing_permissions & Share_permission_share;
    
        if (!can_reshare) {
            auto label = new QLabel (this);
            label.set_text (tr ("The file cannot be shared because it does not have sharing permission."));
            label.set_word_wrap (true);
            _ui.vertical_layout.insert_widget (1, label);
            return;
        }
    
        // We only do user/group sharing from 8.2.0
        bool user_group_sharing =
            theme.user_group_sharing ()
            && _account_state.account ().server_version_int () >= Account.make_server_version (8, 2, 0);
    
        if (user_group_sharing) {
            _user_group_widget = new Share_user_group_widget (_account_state.account (), _share_path, _local_path, _max_sharing_permissions, _private_link_url, this);
    
            // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            connect (this, &Share_dialog.style_changed, _user_group_widget, &Share_user_group_widget.slot_style_changed);
    
            _ui.vertical_layout.insert_widget (1, _user_group_widget);
            _user_group_widget.get_shares ();
        }
    
        if (theme.link_sharing ()) {
            if (_manager) {
                _manager.fetch_shares (_share_path);
            }
        }
    }
    
    void Share_dialog.slot_create_link_share () {
        if (_manager) {
            const auto ask_optional_password = _account_state.account ().capabilities ().share_public_link_ask_optional_password ();
            const auto password = ask_optional_password ? create_random_password () : string ();
            _manager.create_link_share (_share_path, string (), password);
        }
    }
    
    void Share_dialog.slot_create_password_for_link_share (string &password) {
        const auto share_link_widget = qobject_cast<Share_link_widget> (sender ());
        Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            connect (_manager, &Share_manager.link_share_requires_password, share_link_widget, &Share_link_widget.slot_create_share_requires_password);
            connect (share_link_widget, &Share_link_widget.create_password_processed, this, &Share_dialog.slot_create_password_for_link_share_processed);
            share_link_widget.get_link_share ().set_password (password);
        } else {
            q_c_critical (lc_sharing) << "share_link_widget is not a sender!";
        }
    }
    
    void Share_dialog.slot_create_password_for_link_share_processed () {
        const auto share_link_widget = qobject_cast<Share_link_widget> (sender ());
        Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            disconnect (_manager, &Share_manager.link_share_requires_password, share_link_widget, &Share_link_widget.slot_create_share_requires_password);
            disconnect (share_link_widget, &Share_link_widget.create_password_processed, this, &Share_dialog.slot_create_password_for_link_share_processed);
        } else {
            q_c_critical (lc_sharing) << "share_link_widget is not a sender!";
        }
    }
    
    void Share_dialog.slot_link_share_requires_password () {
        bool ok = false;
        string password = QInputDialog.get_text (this,
                                                 tr ("Password for share required"),
                                                 tr ("Please enter a password for your link share:"),
                                                 QLineEdit.Password,
                                                 string (),
                                                 &ok);
    
        if (!ok) {
            // The dialog was canceled so no need to do anything
            emit toggle_share_link_animation (false);
            return;
        }
    
        if (_manager) {
            // Try to create the link share again with the newly entered password
            _manager.create_link_share (_share_path, string (), password);
        }
    }
    
    void Share_dialog.slot_delete_share () {
        auto sharelink_widget = dynamic_cast<Share_link_widget> (sender ());
        sharelink_widget.hide ();
        _ui.vertical_layout.remove_widget (sharelink_widget);
        _link_widget_list.remove_all (sharelink_widget);
        init_link_share_widget ();
    }
    
    void Share_dialog.slot_thumbnail_fetched (int &status_code, QByteArray &reply) {
        if (status_code != 200) {
            q_c_warning (lc_sharing) << "Thumbnail status code : " << status_code;
            return;
        }
    
        QPixmap p;
        p.load_from_data (reply, "PNG");
        p = p.scaled_to_height (thumbnail_size, Qt.Smooth_transformation);
        _ui.label_icon.set_pixmap (p);
        _ui.label_icon.show ();
    }
    
    void Share_dialog.slot_account_state_changed (int state) {
        bool enabled = (state == AccountState.State.Connected);
        q_c_debug (lc_sharing) << "Account connected?" << enabled;
    
        if (_user_group_widget) {
            _user_group_widget.set_enabled (enabled);
        }
    
        if (_link_widget_list.size () > 0){
            foreach (Share_link_widget *widget, _link_widget_list){
                widget.set_enabled (state);
            }
        }
    }
    
    void Share_dialog.change_event (QEvent *e) {
        switch (e.type ()) {
        case QEvent.Style_change:
        case QEvent.Palette_change:
        case QEvent.Theme_change:
            // Notify the other widgets (Dark-/Light-Mode switching)
            emit style_changed ();
            break;
        default:
            break;
        }
    
        Gtk.Dialog.change_event (e);
    }
    
    } // namespace Occ
    