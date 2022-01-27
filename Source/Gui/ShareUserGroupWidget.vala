/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QFile_icon_provider>
// #include <QClipboard>
// #include <QFileInfo>
// #include <QAbstract_proxy_model>
// #include <QCompleter>
// #include <QBox_layout>
// #include <QIcon>
// #include <QLayout>
// #include <QPropertyAnimation>
// #include <QMenu>
// #include <QAction>
// #include <QDesktopServices>
// #include <QInputDialog>
// #include <QMessageBox>
// #include <QCryptographicHash>
// #include <QColor>
// #include <QPainter>
// #include <QList_widget>
// #include <QSvgRenderer>
// #include <QPushButton>
// #include <QContext_menu_event>

// #include <cstring>

// #include <Gtk.Dialog>
// #include <Gtk.Widget>

// #include <GLib.List>
// #include <QVector>
// #include <QTimer>
// #include <qpushbutton.h>
// #include <qscrollarea.h>

namespace {
    const char *password_is_set_placeholder = "●●●●●●●●";

}

namespace Occ {

namespace Ui {
    class Share_user_group_widget;
    class Share_user_line;
}

class Share_manager;

class Avatar_event_filter : GLib.Object {

    public Avatar_event_filter (GLib.Object *parent = nullptr);

signals:
    void clicked ();
    void context_menu (QPoint &global_position);


    protected bool event_filter (GLib.Object *obj, QEvent *event) override;
};

/***********************************************************
@brief The Share_dialog (user/group) class
@ingroup gui
***********************************************************/
class Share_user_group_widget : Gtk.Widget {

    public Share_user_group_widget (AccountPtr account,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const string private_link_url,
        Gtk.Widget *parent = nullptr);
    ~Share_user_group_widget () override;

signals:
    void toggle_public_link_share (bool);
    void style_changed ();

    public void on_get_shares ();
    public void on_share_created (unowned<Share> &share);
    public void on_style_changed ();


    private void on_shares_fetched (GLib.List<unowned<Share>> &shares);

    private void on_sharee_line_edit_text_changed (string text);
    private void on_search_for_sharees (Sharee_model.Lookup_mode lookup_mode);
    private void on_line_edit_text_edited (string text);

    private void on_line_edit_return ();
    private void on_completer_activated (QModelIndex &index);
    private void on_completer_highlighted (QModelIndex &index);
    private void on_sharees_ready ();
    private void on_adjust_scroll_widget_size ();
    private void on_private_link_share ();
    private void on_display_error (int code, string message);

    private void on_private_link_open_browser ();
    private void on_private_link_copy ();
    private void on_private_link_email ();


    private void customize_style ();

    private void activate_sharee_line_edit ();

    private Ui.Share_user_group_widget _ui;
    private QScroll_area _parent_scroll_area;
    private AccountPtr _account;
    private string _share_path;
    private string _local_path;
    private Share_permissions _max_sharing_permissions;
    private string _private_link_url;

    private QCompleter _completer;
    private Sharee_model _completer_model;
    private QTimer _completion_timer;

    private bool _is_file;
    private bool _disable_completer_activated; // in order to avoid that we share the contents twice
    private Share_manager _manager;

    private QProgress_indicator _pi_sharee;

    private string _last_created_share_id;
};

/***********************************************************
The widget displayed for each user/group share
***********************************************************/
class Share_user_line : Gtk.Widget {

    public Share_user_line (AccountPtr account,
        unowned<User_group_share> Share,
        Share_permissions max_sharing_permissions,
        bool is_file,
        Gtk.Widget *parent = nullptr);
    ~Share_user_line () override;

    public unowned<Share> share ();

signals:
    void visual_deletion_done ();
    void resize_requested ();

    public void on_style_changed ();

    public void on_focus_password_line_edit ();


    private void on_delete_share_button_clicked ();
    private void on_permissions_changed ();
    private void on_edit_permissions_changed ();
    private void on_password_checkbox_changed ();
    private void on_delete_animation_finished ();

    private void on_refresh_password_options ();

    private void on_refresh_password_line_edit_placeholder ();

    private void on_password_set ();
    private void on_password_set_error (int status_code, string message);

    private void on_share_deleted ();
    private void on_permissions_set ();

    private void on_avatar_loaded (QImage avatar);

    private void on_set_password_confirmed ();

    private void on_line_edit_password_return_pressed ();

    private void on_confirm_password_clicked ();

    private void on_avatar_context_menu (QPoint &global_position);


    private void display_permissions ();
    private void load_avatar ();
    private void set_default_avatar (int avatar_size);
    private void customize_style ();

    private QPixmap pixmap_for_sharee_type (Sharee.Type type, QColor &background_color = QColor ());
    private QColor background_color_for_sharee_type (Sharee.Type type);

    private void show_note_options (bool show);
    private void toggle_note_options (bool enable);
    private void on_note_confirm_button_clicked ();
    private void set_note (string note);

    private void toggle_expire_date_options (bool enable);
    private void show_expire_date_options (bool show, QDate &initial_date = QDate ());
    private void set_expire_date ();

    private void toggle_password_set_progress_animation (bool show);

    private void enable_progess_indicator_animation (bool enable);
    private void disable_progess_indicator_animation ();

    private QDate max_expiration_date_for_share (Share.Share_type type, QDate &fallback_date);
    private bool enforce_expiration_date_for_share (Share.Share_type type);

    private Ui.Share_user_line _ui;
    private AccountPtr _account;
    private unowned<User_group_share> _share;
    private bool _is_file;

    private Profile_page_menu _profile_page_menu;

    // _permission_edit is a checkbox
    private QAction _permission_reshare;
    private QAction _delete_share_button;
    private QAction _permission_create;
    private QAction _permission_change;
    private QAction _permission_delete;
    private QAction _note_link_action;
    private QAction _expiration_date_link_action;
    private QAction _password_protect_link_action;
};


    Avatar_event_filter.Avatar_event_filter (GLib.Object *parent)
        : GLib.Object (parent) {
    }

    bool Avatar_event_filter.event_filter (GLib.Object *obj, QEvent *event) {
        if (event.type () == QEvent.Context_menu) {
            const auto context_menu_event = dynamic_cast<QContext_menu_event> (event);
            if (!context_menu_event) {
                return false;
            }
            emit context_menu (context_menu_event.global_pos ());
            return true;
        }
        return GLib.Object.event_filter (obj, event);
    }

    Share_user_group_widget.Share_user_group_widget (AccountPtr account,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const string private_link_url,
        Gtk.Widget *parent)
        : Gtk.Widget (parent)
        , _ui (new Ui.Share_user_group_widget)
        , _account (account)
        , _share_path (share_path)
        , _local_path (local_path)
        , _max_sharing_permissions (max_sharing_permissions)
        , _private_link_url (private_link_url)
        , _disable_completer_activated (false) {
        set_attribute (Qt.WA_DeleteOnClose);
        set_object_name ("Sharing_dialog_uG"); // required as group for save_geometry call

        _ui.setup_ui (this);

        //Is this a file or folder?
        _is_file = QFileInfo (local_path).is_file ();

        _completer = new QCompleter (this);
        _completer_model = new Sharee_model (_account,
            _is_file ? QLatin1String ("file") : QLatin1String ("folder"),
            _completer);
        connect (_completer_model, &Sharee_model.sharees_ready, this, &Share_user_group_widget.on_sharees_ready);
        connect (_completer_model, &Sharee_model.display_error_message, this, &Share_user_group_widget.on_display_error);

        _completer.set_model (_completer_model);
        _completer.set_case_sensitivity (Qt.CaseInsensitive);
        _completer.set_completion_mode (QCompleter.Unfiltered_popup_completion);
        _ui.sharee_line_edit.set_completer (_completer);

        auto search_globally_action = new QAction (_ui.sharee_line_edit);
        search_globally_action.set_icon (QIcon (":/client/theme/magnifying-glass.svg"));
        search_globally_action.set_tool_tip (tr ("Search globally"));

        connect (search_globally_action, &QAction.triggered, this, [this] () {
            on_search_for_sharees (Sharee_model.Global_search);
        });

        _ui.sharee_line_edit.add_action (search_globally_action, QLineEdit.Leading_position);

        _manager = new Share_manager (_account, this);
        connect (_manager, &Share_manager.on_shares_fetched, this, &Share_user_group_widget.on_shares_fetched);
        connect (_manager, &Share_manager.share_created, this, &Share_user_group_widget.on_share_created);
        connect (_manager, &Share_manager.on_server_error, this, &Share_user_group_widget.on_display_error);
        connect (_ui.sharee_line_edit, &QLineEdit.return_pressed, this, &Share_user_group_widget.on_line_edit_return);
        connect (_ui.confirm_share, &QAbstractButton.clicked, this, &Share_user_group_widget.on_line_edit_return);
        //TODO connect (_ui.private_link_text, &QLabel.link_activated, this, &Share_user_group_widget.on_private_link_share);

        // By making the next two Queued_connections we can override
        // the strings the completer sets on the line edit.
        connect (_completer, SIGNAL (activated (QModelIndex)), SLOT (on_completer_activated (QModelIndex)),
            Qt.QueuedConnection);
        connect (_completer, SIGNAL (highlighted (QModelIndex)), SLOT (on_completer_highlighted (QModelIndex)),
            Qt.QueuedConnection);

        // Queued connection so this signal is recieved after text_changed
        connect (_ui.sharee_line_edit, &QLineEdit.text_edited,
            this, &Share_user_group_widget.on_line_edit_text_edited, Qt.QueuedConnection);
        _ui.sharee_line_edit.install_event_filter (this);
        connect (&_completion_timer, &QTimer.timeout, this, [this] () {
            on_search_for_sharees (Sharee_model.Local_search);
        });
        _completion_timer.set_single_shot (true);
        _completion_timer.set_interval (600);

        _ui.error_label.hide ();

        // TODO Progress Indicator where should it go?
        // Setup the sharee search progress indicator
        //_ui.sharee_horizontal_layout.add_widget (&_pi_sharee);

        _parent_scroll_area = parent_widget ().find_child<QScroll_area> ("scroll_area");

        customize_style ();
    }

    Share_user_group_widget.~Share_user_group_widget () {
        delete _ui;
    }

    void Share_user_group_widget.on_sharee_line_edit_text_changed (string ) {
        _completion_timer.stop ();
        emit toggle_public_link_share (false);
    }

    void Share_user_group_widget.on_line_edit_text_edited (string text) {
        _disable_completer_activated = false;
        // First text_changed is called first and we stopped the timer when the text is changed, programatically or not
        // Then we restart the timer here if the user touched a key
        if (!text.is_empty ()) {
            _completion_timer.on_start ();
            emit toggle_public_link_share (true);
        }
    }

    void Share_user_group_widget.on_line_edit_return () {
        _disable_completer_activated = false;
        // did the user type in one of the options?
        const auto text = _ui.sharee_line_edit.text ();
        for (int i = 0; i < _completer_model.row_count (); ++i) {
            const auto sharee = _completer_model.get_sharee (i);
            if (sharee.format () == text
                || sharee.display_name () == text
                || sharee.share_with () == text) {
                on_completer_activated (_completer_model.index (i));
                // make sure we do not send the same item twice (because return is called when we press
                // return to activate an item inthe completer)
                _disable_completer_activated = true;
                return;
            }
        }

        // nothing found? try to refresh completion
        _completion_timer.on_start ();
    }

    void Share_user_group_widget.on_search_for_sharees (Sharee_model.Lookup_mode lookup_mode) {
        if (_ui.sharee_line_edit.text ().is_empty ()) {
            return;
        }

        _ui.sharee_line_edit.set_enabled (false);
        _completion_timer.stop ();
        _pi_sharee.on_start_animation ();
        Sharee_model.Sharee_set blacklist;

        // Add the current user to _sharees since we can't share with ourself
        unowned<Sharee> current_user (new Sharee (_account.credentials ().user (), "", Sharee.Type.User));
        blacklist << current_user;

        foreach (auto sw, _parent_scroll_area.find_children<Share_user_line> ()) {
            blacklist << sw.share ().get_share_with ();
        }
        _ui.error_label.hide ();
        _completer_model.fetch (_ui.sharee_line_edit.text (), blacklist, lookup_mode);
    }

    void Share_user_group_widget.on_get_shares () {
        _manager.fetch_shares (_share_path);
    }

    void Share_user_group_widget.on_share_created (unowned<Share> &share) {
        if (share && _account.capabilities ().share_email_password_enabled () && !_account.capabilities ().share_email_password_enforced ()) {
            // remember this share Id so we can set it's password Line Edit to focus later
            _last_created_share_id = share.get_id ();
        }
        // fetch all shares including the one we've just created
        on_get_shares ();
    }

    void Share_user_group_widget.on_shares_fetched (GLib.List<unowned<Share>> &shares) {
        QScroll_area *scroll_area = _parent_scroll_area;

        auto new_view_port = new Gtk.Widget (scroll_area);
        auto layout = new QVBoxLayout (new_view_port);
        layout.set_contents_margins (0, 0, 0, 0);
        int x = 0;
        int height = 0;
        GLib.List<string> link_owners ({});

        Share_user_line *just_created_share_that_needs_password = nullptr;

        foreach (auto &share, shares) {
            // We don't handle link shares, only Type_user or Type_group
            if (share.get_share_type () == Share.Type_link) {
                if (!share.get_uid_owner ().is_empty () &&
                        share.get_uid_owner () != share.account ().dav_user ()){
                    link_owners.append (share.get_owner_display_name ());
                 }
                continue;
            }

            // the owner of the file that shared it first
            // leave out if it's the current user
            if (x == 0 && !share.get_uid_owner ().is_empty () && ! (share.get_uid_owner () == _account.credentials ().user ())) {
                _ui.main_owner_label.on_set_text (string ("Shared with you by ").append (share.get_owner_display_name ()));
            }

            Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share.get_share_type ()));
            auto user_group_share = q_shared_pointer_dynamic_cast<User_group_share> (share);
            auto *s = new Share_user_line (_account, user_group_share, _max_sharing_permissions, _is_file, _parent_scroll_area);
            connect (s, &Share_user_line.resize_requested, this, &Share_user_group_widget.on_adjust_scroll_widget_size);
            connect (s, &Share_user_line.visual_deletion_done, this, &Share_user_group_widget.on_get_shares);
            s.set_background_role (layout.count () % 2 == 0 ? QPalette.Base : QPalette.Alternate_base);

            // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            connect (this, &Share_user_group_widget.style_changed, s, &Share_user_line.on_style_changed);

            layout.add_widget (s);

            if (!_last_created_share_id.is_empty () && share.get_id () == _last_created_share_id) {
                _last_created_share_id = string ();
                if (_account.capabilities ().share_email_password_enabled () && !_account.capabilities ().share_email_password_enforced ()) {
                    just_created_share_that_needs_password = s;
                }
            }

            x++;
            if (x <= 3) {
                height = new_view_port.size_hint ().height ();
            }
        }

        foreach (string owner, link_owners) {
            auto owner_label = new QLabel (string (owner + " shared via link"));
            layout.add_widget (owner_label);
            owner_label.set_visible (true);

            x++;
            if (x <= 6) {
                height = new_view_port.size_hint ().height ();
            }
        }

        scroll_area.set_frame_shape (x > 6 ? QFrame.Styled_panel : QFrame.No_frame);
        scroll_area.set_visible (!shares.is_empty ());
        scroll_area.set_fixed_height (height);
        scroll_area.set_widget (new_view_port);

        _disable_completer_activated = false;
        activate_sharee_line_edit ();

        if (just_created_share_that_needs_password) {
            // always set focus to a password Line Edit when the new email share is created on a server with optional passwords enabled for email shares
            just_created_share_that_needs_password.on_focus_password_line_edit ();
        }
    }

    void Share_user_group_widget.on_adjust_scroll_widget_size () {
        QScroll_area *scroll_area = _parent_scroll_area;
        const auto share_user_line_childs = scroll_area.find_children<Share_user_line> ();

        // Ask the child widgets to calculate their size
        for (auto share_user_line_child : share_user_line_childs) {
            share_user_line_child.adjust_size ();
        }

        const auto share_user_line_childs_count = share_user_line_childs.count ();
        scroll_area.set_visible (share_user_line_childs_count > 0);
        if (share_user_line_childs_count > 0 && share_user_line_childs_count <= 3) {
            scroll_area.set_fixed_height (scroll_area.widget ().size_hint ().height ());
        }
        scroll_area.set_frame_shape (share_user_line_childs_count > 3 ? QFrame.Styled_panel : QFrame.No_frame);
    }

    void Share_user_group_widget.on_private_link_share () {
        auto menu = new QMenu (this);
        menu.set_attribute (Qt.WA_DeleteOnClose);

        // this icon is not handled by on_style_changed () . customize_style but we can live with that
        menu.add_action (Theme.create_color_aware_icon (":/client/theme/copy.svg"),
                        tr ("Copy link"),
            this, SLOT (on_private_link_copy ()));

        menu.exec (QCursor.pos ());
    }

    void Share_user_group_widget.on_sharees_ready () {
        activate_sharee_line_edit ();

        _pi_sharee.on_stop_animation ();
        if (_completer_model.row_count () == 0) {
            on_display_error (0, tr ("No results for \"%1\"").arg (_completer_model.current_search ()));
        }

        // if no rows are present in the model - complete () will hide the completer
        _completer.complete ();
    }

    void Share_user_group_widget.on_completer_activated (QModelIndex &index) {
        if (_disable_completer_activated)
            return;
        // The index is an index from the QCompletion model which is itelf a proxy
        // model proxying the _completer_model
        auto sharee = qvariant_cast<unowned<Sharee>> (index.data (Qt.User_role));
        if (sharee.is_null ()) {
            return;
        }

    // TODO Progress Indicator where should it go?
    //    auto indicator = new QProgress_indicator (view_port);
    //    indicator.on_start_animation ();
    //    if (layout.count () == 1) {
    //        // No shares yet! Remove the label, add some stretch.
    //        delete layout.item_at (0).widget ();
    //        layout.add_stretch (1);
    //    }
    //    layout.insert_widget (layout.count () - 1, indicator);

        /***********************************************************
        Don't send the reshare permissions for federated shares for servers <9.1
        https://github.com/owncloud/core/issues/22122#issuecomment-185637344
        https://github.com/owncloud/client/issues/4996
         */

        _last_created_share_id = string ();

        string password;
        if (sharee.type () == Sharee.Email && _account.capabilities ().share_email_password_enforced ()) {
            _ui.sharee_line_edit.clear ();
            // always show a dialog for password-enforced email shares
            bool ok = false;

            do {
                password = QInputDialog.get_text (
                    this,
                    tr ("Password for share required"),
                    tr ("Please enter a password for your email share:"),
                    QLineEdit.Password,
                    string (),
                    &ok);
            } while (password.is_empty () && ok);

            if (!ok) {
                return;
            }
        }

        _manager.create_share (_share_path, Share.Share_type (sharee.type ()),
            sharee.share_with (), _max_sharing_permissions, password);

        _ui.sharee_line_edit.set_enabled (false);
        _ui.sharee_line_edit.clear ();
    }

    void Share_user_group_widget.on_completer_highlighted (QModelIndex &index) {
        // By default the completer would set the text to Edit_role,
        // override that here.
        _ui.sharee_line_edit.on_set_text (index.data (Qt.Display_role).to_string ());
    }

    void Share_user_group_widget.on_display_error (int code, string message) {
        _pi_sharee.on_stop_animation ();

        // Also remove the spinner in the widget list, if any
        foreach (auto pi, _parent_scroll_area.find_children<QProgress_indicator> ()) {
            delete pi;
        }

        q_c_warning (lc_sharing) << "Sharing error from server" << code << message;
        _ui.error_label.on_set_text (message);
        _ui.error_label.show ();
        activate_sharee_line_edit ();
    }

    void Share_user_group_widget.on_private_link_open_browser () {
        Utility.open_browser (_private_link_url, this);
    }

    void Share_user_group_widget.on_private_link_copy () {
        QApplication.clipboard ().on_set_text (_private_link_url);
    }

    void Share_user_group_widget.on_private_link_email () {
        Utility.open_email_composer (
            tr ("I shared something with you"),
            _private_link_url,
            this);
    }

    void Share_user_group_widget.on_style_changed () {
        customize_style ();

        // Notify the other widgets (Share_user_line in this case, Dark-/Light-Mode switching)
        emit style_changed ();
    }

    void Share_user_group_widget.customize_style () {
        _ui.confirm_share.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

        _pi_sharee.on_set_color (QGuiApplication.palette ().color (QPalette.Text));

        foreach (auto pi, _parent_scroll_area.find_children<QProgress_indicator> ()) {
            pi.on_set_color (QGuiApplication.palette ().color (QPalette.Text));;
        }
    }

    void Share_user_group_widget.activate_sharee_line_edit () {
        _ui.sharee_line_edit.set_enabled (true);
        _ui.sharee_line_edit.set_focus ();
    }

    Share_user_line.Share_user_line (AccountPtr account, unowned<User_group_share> share,
        Share_permissions max_sharing_permissions, bool is_file, Gtk.Widget *parent)
        : Gtk.Widget (parent)
        , _ui (new Ui.Share_user_line)
        , _account (account)
        , _share (share)
        , _is_file (is_file)
        , _profile_page_menu (account, share.get_share_with ().share_with ()) {
        Q_ASSERT (_share);
        _ui.setup_ui (this);

        _ui.shared_with.set_elide_mode (Qt.Elide_right);
        _ui.shared_with.on_set_text (share.get_share_with ().format ());

        // adds permissions
        // can edit permission
        bool enabled = (max_sharing_permissions & Share_permission_update);
        if (!_is_file) enabled = enabled && (max_sharing_permissions & Share_permission_create &&
                                          max_sharing_permissions & Share_permission_delete);
        _ui.permissions_edit.set_enabled (enabled);
        connect (_ui.permissions_edit, &QAbstractButton.clicked, this, &Share_user_line.on_edit_permissions_changed);
        connect (_ui.note_confirm_button, &QAbstractButton.clicked, this, &Share_user_line.on_note_confirm_button_clicked);
        connect (_ui.calendar, &QDate_time_edit.date_changed, this, &Share_user_line.set_expire_date);

        connect (_share.data (), &User_group_share.note_set, this, &Share_user_line.disable_progess_indicator_animation);
        connect (_share.data (), &User_group_share.note_set_error, this, &Share_user_line.disable_progess_indicator_animation);
        connect (_share.data (), &User_group_share.expire_date_set, this, &Share_user_line.disable_progess_indicator_animation);

        connect (_ui.confirm_password, &QToolButton.clicked, this, &Share_user_line.on_confirm_password_clicked);
        connect (_ui.line_edit_password, &QLineEdit.return_pressed, this, &Share_user_line.on_line_edit_password_return_pressed);

        // create menu with checkable permissions
        auto *menu = new QMenu (this);
        _permission_reshare= new QAction (tr ("Can reshare"), this);
        _permission_reshare.set_checkable (true);
        _permission_reshare.set_enabled (max_sharing_permissions & Share_permission_share);
        menu.add_action (_permission_reshare);
        connect (_permission_reshare, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

        show_note_options (false);

        const bool is_note_supported = _share.get_share_type () != Share.Share_type.Type_email && _share.get_share_type () != Share.Share_type.Type_room;

        if (is_note_supported) {
            _note_link_action = new QAction (tr ("Note to recipient"));
            _note_link_action.set_checkable (true);
            menu.add_action (_note_link_action);
            connect (_note_link_action, &QAction.triggered, this, &Share_user_line.toggle_note_options);
            if (!_share.get_note ().is_empty ()) {
                _note_link_action.set_checked (true);
                show_note_options (true);
            }
        }

        show_expire_date_options (false);

        const bool is_expiration_date_supported = _share.get_share_type () != Share.Share_type.Type_email;

        if (is_expiration_date_supported) {
            // email shares do not support expiration dates
            _expiration_date_link_action = new QAction (tr ("Set expiration date"));
            _expiration_date_link_action.set_checkable (true);
            menu.add_action (_expiration_date_link_action);
            connect (_expiration_date_link_action, &QAction.triggered, this, &Share_user_line.toggle_expire_date_options);
            const auto expire_date = _share.get_expire_date ().is_valid () ? share.data ().get_expire_date () : QDate ();
            if (!expire_date.is_null ()) {
                _expiration_date_link_action.set_checked (true);
                show_expire_date_options (true, expire_date);
            }
        }

        menu.add_separator ();

          // Adds action to delete share widget
          QIcon deleteicon = QIcon.from_theme (QLatin1String ("user-trash"),QIcon (QLatin1String (":/client/theme/delete.svg")));
          _delete_share_button= new QAction (deleteicon,tr ("Unshare"), this);

        menu.add_action (_delete_share_button);
        connect (_delete_share_button, &QAction.triggered, this, &Share_user_line.on_delete_share_button_clicked);

        /***********************************************************
        Files can't have create or delete permissions
         */
        if (!_is_file) {
            _permission_create = new QAction (tr ("Can create"), this);
            _permission_create.set_checkable (true);
            _permission_create.set_enabled (max_sharing_permissions & Share_permission_create);
            menu.add_action (_permission_create);
            connect (_permission_create, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

            _permission_change = new QAction (tr ("Can change"), this);
            _permission_change.set_checkable (true);
            _permission_change.set_enabled (max_sharing_permissions & Share_permission_update);
            menu.add_action (_permission_change);
            connect (_permission_change, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

            _permission_delete = new QAction (tr ("Can delete"), this);
            _permission_delete.set_checkable (true);
            _permission_delete.set_enabled (max_sharing_permissions & Share_permission_delete);
            menu.add_action (_permission_delete);
            connect (_permission_delete, &QAction.triggered, this, &Share_user_line.on_permissions_changed);
        }

        // Adds action to display password widget (check box)
        if (_share.get_share_type () == Share.Type_email && (_share.is_password_set () || _account.capabilities ().share_email_password_enabled ())) {
            _password_protect_link_action = new QAction (tr ("Password protect"), this);
            _password_protect_link_action.set_checkable (true);
            _password_protect_link_action.set_checked (_share.is_password_set ());
            // checkbox can be checked/unchedkec if the password is not yet set or if it's not enforced
            _password_protect_link_action.set_enabled (!_share.is_password_set () || !_account.capabilities ().share_email_password_enforced ());

            menu.add_action (_password_protect_link_action);
            connect (_password_protect_link_action, &QAction.triggered, this, &Share_user_line.on_password_checkbox_changed);

            on_refresh_password_line_edit_placeholder ();

            connect (_share.data (), &Share.password_set, this, &Share_user_line.on_password_set);
            connect (_share.data (), &Share.password_set_error, this, &Share_user_line.on_password_set_error);
        }

        on_refresh_password_options ();

        _ui.error_label.hide ();

        _ui.permission_tool_button.set_menu (menu);
        _ui.permission_tool_button.set_popup_mode (QToolButton.Instant_popup);

        _ui.password_progress_indicator.set_visible (false);

        // Set the permissions checkboxes
        display_permissions ();

        /***********************************************************
        We don't show permission share for federated shares with server <9.1
        https://github.com/owncloud/core/issues/22122#issuecomment-185637344
        https://github.com/owncloud/client/issues/4996
         */
        if (share.get_share_type () == Share.Type_remote
            && share.account ().server_version_int () < Account.make_server_version (9, 1, 0)) {
            _permission_reshare.set_visible (false);
            _ui.permission_tool_button.set_visible (false);
        }

        connect (share.data (), &Share.permissions_set, this, &Share_user_line.on_permissions_set);
        connect (share.data (), &Share.share_deleted, this, &Share_user_line.on_share_deleted);

        if (!share.account ().capabilities ().share_resharing ()) {
            _permission_reshare.set_visible (false);
        }

        const auto avatar_event_filter = new Avatar_event_filter (_ui.avatar);
        connect (avatar_event_filter, &Avatar_event_filter.context_menu, this, &Share_user_line.on_avatar_context_menu);
        _ui.avatar.install_event_filter (avatar_event_filter);

        load_avatar ();

        customize_style ();
    }

    void Share_user_line.on_avatar_context_menu (QPoint &global_position) {
        if (_share.get_share_type () == Share.Type_user) {
            _profile_page_menu.exec (global_position);
        }
    }

    void Share_user_line.load_avatar () {
        const int avatar_size = 36;

        // Set size of the placeholder
        _ui.avatar.set_minimum_height (avatar_size);
        _ui.avatar.set_minimum_width (avatar_size);
        _ui.avatar.set_maximum_height (avatar_size);
        _ui.avatar.set_maximum_width (avatar_size);
        _ui.avatar.set_alignment (Qt.AlignCenter);

        set_default_avatar (avatar_size);

        /* Start the network job to fetch the avatar data.

        Currently only regular users can have avatars.
         */
        if (_share.get_share_with ().type () == Sharee.User) {
            auto *job = new AvatarJob (_share.account (), _share.get_share_with ().share_with (), avatar_size, this);
            connect (job, &AvatarJob.avatar_pixmap, this, &Share_user_line.on_avatar_loaded);
            job.on_start ();
        }
    }

    void Share_user_line.set_default_avatar (int avatar_size) {
        /* Create the fallback avatar.

        This will be shown until the avatar image data arrives.
         */

        // See core/js/placeholder.js for details on colors and styling
        const auto background_color = background_color_for_sharee_type (_share.get_share_with ().type ());
        const string style = string (R" (* {
            color : #fff;
            background-color : %1;
            border-radius : %2px;
            text-align : center;
            line-height : %2px;
            font-size : %2px;
        })").arg (background_color.name (), string.number (avatar_size / 2));
        _ui.avatar.set_style_sheet (style);

        const auto pixmap = pixmap_for_sharee_type (_share.get_share_with ().type (), background_color);

        if (!pixmap.is_null ()) {
            _ui.avatar.set_pixmap (pixmap);
        } else {
            q_c_debug (lc_sharing) << "pixmap is null for share type : " << _share.get_share_with ().type ();

            // The avatar label is the first character of the user name.
            const auto text = _share.get_share_with ().display_name ();
            _ui.avatar.on_set_text (text.at (0).to_upper ());
        }
    }

    void Share_user_line.on_avatar_loaded (QImage avatar) {
        if (avatar.is_null ())
            return;

        avatar = AvatarJob.make_circular_avatar (avatar);
        _ui.avatar.set_pixmap (QPixmap.from_image (avatar));

        // Remove the stylesheet for the fallback avatar
        _ui.avatar.set_style_sheet ("");
    }

    void Share_user_line.on_delete_share_button_clicked () {
        set_enabled (false);
        _share.delete_share ();
    }

    Share_user_line.~Share_user_line () {
        delete _ui;
    }

    void Share_user_line.on_edit_permissions_changed () {
        set_enabled (false);

        // Can never manually be set to "partial".
        // This works because the state cycle for clicking is
        // unchecked . partial . checked . unchecked.
        if (_ui.permissions_edit.check_state () == Qt.Partially_checked) {
            _ui.permissions_edit.set_check_state (Qt.Checked);
        }

        Share.Permissions permissions = Share_permission_read;

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (_ui.permissions_edit.check_state () == Qt.Checked) {

            /***********************************************************
            Files can't have create or delete permisisons
             */
            if (!_is_file) {
                if (_permission_change.is_enabled ())
                    permissions |= Share_permission_update;
                if (_permission_create.is_enabled ())
                    permissions |= Share_permission_create;
                if (_permission_delete.is_enabled ())
                    permissions |= Share_permission_delete;
            } else {
                permissions |= Share_permission_update;
            }
        }

        if (_is_file && _permission_reshare.is_enabled () && _permission_reshare.is_checked ())
            permissions |= Share_permission_share;

        _share.set_permissions (permissions);
    }

    void Share_user_line.on_permissions_changed () {
        set_enabled (false);

        Share.Permissions permissions = Share_permission_read;

        if (_permission_reshare.is_checked ())
            permissions |= Share_permission_share;

        if (!_is_file) {
            if (_permission_change.is_checked ())
                permissions |= Share_permission_update;
            if (_permission_create.is_checked ())
                permissions |= Share_permission_create;
            if (_permission_delete.is_checked ())
                permissions |= Share_permission_delete;
        } else {
            if (_ui.permissions_edit.is_checked ())
                permissions |= Share_permission_update;
        }

        _share.set_permissions (permissions);
    }

    void Share_user_line.on_password_checkbox_changed () {
        if (!_password_protect_link_action.is_checked ()) {
            _ui.error_label.hide ();
            _ui.error_label.clear ();

            if (!_share.is_password_set ()) {
                _ui.line_edit_password.clear ();
                on_refresh_password_options ();
            } else {
                // do not call on_refresh_password_options here, as it will be called after the network request is complete
                toggle_password_set_progress_animation (true);
                _share.set_password (string ());
            }
        } else {
            on_refresh_password_options ();

            if (_ui.line_edit_password.is_visible () && _ui.line_edit_password.is_enabled ()) {
                on_focus_password_line_edit ();
            }
        }
    }

    void Share_user_line.on_delete_animation_finished () {
        emit resize_requested ();
        emit visual_deletion_done ();
        delete_later ();

        // There is a painting bug where a small line of this widget isn't
        // properly cleared. This explicit repaint () call makes sure any trace of
        // the share widget is removed once it's destroyed. #4189
        connect (this, SIGNAL (destroyed (GLib.Object *)), parent_widget (), SLOT (repaint ()));
    }

    void Share_user_line.on_refresh_password_options () {
        const bool is_password_enabled = _share.get_share_type () == Share.Type_email && _password_protect_link_action.is_checked ();

        _ui.password_label.set_visible (is_password_enabled);
        _ui.line_edit_password.set_enabled (is_password_enabled);
        _ui.line_edit_password.set_visible (is_password_enabled);
        _ui.confirm_password.set_visible (is_password_enabled);

        emit resize_requested ();
    }

    void Share_user_line.on_refresh_password_line_edit_placeholder () {
        if (_share.is_password_set ()) {
            _ui.line_edit_password.set_placeholder_text (string.from_utf8 (password_is_set_placeholder));
        } else {
            _ui.line_edit_password.set_placeholder_text ("");
        }
    }

    void Share_user_line.on_password_set () {
        toggle_password_set_progress_animation (false);
        _ui.line_edit_password.set_enabled (true);
        _ui.confirm_password.set_enabled (true);

        _ui.line_edit_password.on_set_text ("");

        _password_protect_link_action.set_enabled (!_share.is_password_set () || !_account.capabilities ().share_email_password_enforced ());

        on_refresh_password_line_edit_placeholder ();

        on_refresh_password_options ();
    }

    void Share_user_line.on_password_set_error (int status_code, string message) {
        q_c_warning (lc_sharing) << "Error from server" << status_code << message;

        toggle_password_set_progress_animation (false);

        _ui.line_edit_password.set_enabled (true);
        _ui.confirm_password.set_enabled (true);

        on_refresh_password_line_edit_placeholder ();

        on_refresh_password_options ();

        on_focus_password_line_edit ();

        _ui.error_label.show ();
        _ui.error_label.on_set_text (message);

        emit resize_requested ();
    }

    void Share_user_line.on_share_deleted () {
        auto *animation = new QPropertyAnimation (this, "maximum_height", this);

        animation.set_duration (500);
        animation.set_start_value (height ());
        animation.set_end_value (0);

        connect (animation, &QAbstractAnimation.on_finished, this, &Share_user_line.on_delete_animation_finished);
        connect (animation, &QVariant_animation.value_changed, this, &Share_user_line.resize_requested);

        animation.on_start ();
    }

    void Share_user_line.on_permissions_set () {
        display_permissions ();
        set_enabled (true);
    }

    unowned<Share> Share_user_line.share () {
        return _share;
    }

    void Share_user_line.display_permissions () {
        auto perm = _share.get_permissions ();

    //  folders edit = CREATE, READ, UPDATE, DELETE
    //  files edit = READ + UPDATE
        if (perm & Share_permission_update && (_is_file ||
                                             (perm & Share_permission_create && perm & Share_permission_delete))) {
            _ui.permissions_edit.set_check_state (Qt.Checked);
        } else if (!_is_file && perm & (Share_permission_update | Share_permission_create | Share_permission_delete)) {
            _ui.permissions_edit.set_check_state (Qt.Partially_checked);
        } else if (perm & Share_permission_read) {
            _ui.permissions_edit.set_check_state (Qt.Unchecked);
        }

    //  edit is independent of reshare
        if (perm & Share_permission_share)
            _permission_reshare.set_checked (true);

        if (!_is_file){
            _permission_create.set_checked (perm & Share_permission_create);
            _permission_change.set_checked (perm & Share_permission_update);
            _permission_delete.set_checked (perm & Share_permission_delete);
        }
    }

    void Share_user_line.on_style_changed () {
        customize_style ();
    }

    void Share_user_line.on_focus_password_line_edit () {
        _ui.line_edit_password.set_focus ();
    }

    void Share_user_line.customize_style () {
        _ui.permission_tool_button.set_icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        QIcon deleteicon = QIcon.from_theme (QLatin1String ("user-trash"),Theme.create_color_aware_icon (QLatin1String (":/client/theme/delete.svg")));
        _delete_share_button.set_icon (deleteicon);

        _ui.note_confirm_button.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        _ui.progress_indicator.on_set_color (QGuiApplication.palette ().color (QPalette.Window_text));

        // make sure to force Background_role to QPalette.Window_text for a lable, because it's parent always has a different role set that applies to children unless customized
        _ui.error_label.set_background_role (QPalette.Window_text);
    }

    QPixmap Share_user_line.pixmap_for_sharee_type (Sharee.Type type, QColor &background_color) {
        switch (type) {
        case Sharee.Room:
            return Ui.Icon_utils.pixmap_for_background (QStringLiteral ("talk-app.svg"), background_color);
        case Sharee.Email:
            return Ui.Icon_utils.pixmap_for_background (QStringLiteral ("email.svg"), background_color);
        case Sharee.Group:
        case Sharee.Federated:
        case Sharee.Circle:
        case Sharee.User:
            break;
        }

        return {};
    }

    QColor Share_user_line.background_color_for_sharee_type (Sharee.Type type) {
        switch (type) {
        case Sharee.Room:
            return Theme.instance ().wizard_header_background_color ();
        case Sharee.Email:
            return Theme.instance ().wizard_header_title_color ();
        case Sharee.Group:
        case Sharee.Federated:
        case Sharee.Circle:
        case Sharee.User:
            break;
        }

        const auto calculate_background_based_on_text = [this] () {
            const auto hash = QCryptographicHash.hash (_ui.shared_with.text ().to_utf8 (), QCryptographicHash.Md5);
            Q_ASSERT (hash.size () > 0);
            if (hash.size () == 0) {
                q_c_warning (lc_sharing) << "Failed to calculate hash color for share:" << _share.path ();
                return QColor{};
            }
            const double hue = static_cast<uint8> (hash[0]) / 255.;
            return QColor.from_hsl_f (hue, 0.7, 0.68);
        };

        return calculate_background_based_on_text ();
    }

    void Share_user_line.show_note_options (bool show) {
        _ui.note_label.set_visible (show);
        _ui.note_text_edit.set_visible (show);
        _ui.note_confirm_button.set_visible (show);

        if (show) {
            const auto note = _share.get_note ();
            _ui.note_text_edit.on_set_text (note);
            _ui.note_text_edit.set_focus ();
        }

        emit resize_requested ();
    }

    void Share_user_line.toggle_note_options (bool enable) {
        show_note_options (enable);

        if (!enable) {
            // Delete note
            _share.set_note (string ());
        }
    }

    void Share_user_line.on_note_confirm_button_clicked () {
        set_note (_ui.note_text_edit.to_plain_text ());
    }

    void Share_user_line.set_note (string note) {
        enable_progess_indicator_animation (true);
        _share.set_note (note);
    }

    void Share_user_line.toggle_expire_date_options (bool enable) {
        show_expire_date_options (enable);

        if (!enable) {
            _share.set_expire_date (QDate ());
        }
    }

    void Share_user_line.show_expire_date_options (bool show, QDate &initial_date) {
        _ui.expiration_label.set_visible (show);
        _ui.calendar.set_visible (show);

        if (show) {
            _ui.calendar.set_minimum_date (QDate.current_date ().add_days (1));
            _ui.calendar.set_date (initial_date.is_valid () ? initial_date : _ui.calendar.minimum_date ());
            _ui.calendar.set_focus ();

            if (enforce_expiration_date_for_share (_share.get_share_type ())) {
                _ui.calendar.set_maximum_date (max_expiration_date_for_share (_share.get_share_type (), _ui.calendar.maximum_date ()));
                _expiration_date_link_action.set_checked (true);
                _expiration_date_link_action.set_enabled (false);
            }
        }

        emit resize_requested ();
    }

    void Share_user_line.set_expire_date () {
        enable_progess_indicator_animation (true);
        _share.set_expire_date (_ui.calendar.date ());
    }

    void Share_user_line.enable_progess_indicator_animation (bool enable) {
        if (enable) {
            if (!_ui.progress_indicator.is_animated ()) {
                _ui.progress_indicator.on_start_animation ();
            }
        } else {
            _ui.progress_indicator.on_stop_animation ();
        }
    }

    void Share_user_line.toggle_password_set_progress_animation (bool show) {
        // button and progress indicator are interchanged depending on if the network request is in progress or not
        _ui.confirm_password.set_visible (!show && _password_protect_link_action.is_checked ());
        _ui.password_progress_indicator.set_visible (show);
        if (show) {
            if (!_ui.password_progress_indicator.is_animated ()) {
                _ui.password_progress_indicator.on_start_animation ();
            }
        } else {
            _ui.password_progress_indicator.on_stop_animation ();
        }
    }

    void Share_user_line.disable_progess_indicator_animation () {
        enable_progess_indicator_animation (false);
    }

    QDate Share_user_line.max_expiration_date_for_share (Share.Share_type type, QDate &fallback_date) {
        auto days_to_expire = 0;
        if (type == Share.Share_type.Type_remote) {
            days_to_expire = _account.capabilities ().share_remote_expire_date_days ();
        } else if (type == Share.Share_type.Type_email) {
           days_to_expire = _account.capabilities ().share_public_link_expire_date_days ();
        } else {
            days_to_expire = _account.capabilities ().share_internal_expire_date_days ();
        }

        if (days_to_expire > 0) {
            return QDate.current_date ().add_days (days_to_expire);
        }

        return fallback_date;
    }

    bool Share_user_line.enforce_expiration_date_for_share (Share.Share_type type) {
        if (type == Share.Share_type.Type_remote) {
            return _account.capabilities ().share_remote_enforce_expire_date ();
        } else if (type == Share.Share_type.Type_email) {
            return _account.capabilities ().share_public_link_enforce_expire_date ();
        }

        return _account.capabilities ().share_internal_enforce_expire_date ();
    }

    void Share_user_line.on_set_password_confirmed () {
        if (_ui.line_edit_password.text ().is_empty ()) {
            return;
        }

        _ui.line_edit_password.set_enabled (false);
        _ui.confirm_password.set_enabled (false);

        _ui.error_label.hide ();
        _ui.error_label.clear ();

        toggle_password_set_progress_animation (true);
        _share.set_password (_ui.line_edit_password.text ());
    }

    void Share_user_line.on_line_edit_password_return_pressed () {
        on_set_password_confirmed ();
    }

    void Share_user_line.on_confirm_password_clicked () {
        on_set_password_confirmed ();
    }
    }
    