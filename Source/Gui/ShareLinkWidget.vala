/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>
Copyright (C) 2015 by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QClipboard>
// #include <QFileInfo>
// #include <QDesktopServices>
// #include <QMessageBox>
// #include <QMenu>
// #include <QText_edit>
// #include <QToolButton>
// #include <QPropertyAnimation>

// #include <Gtk.Dialog>
// #include <QSharedPointer>
// #include <QList>
// #include <QToolButton>
// #include <QHBox_layout>
// #include <QLabel>
// #include <QLineEdit>
// #include <QWidget_action>


namespace Occ {

namespace {
    const char *password_is_set_placeholder = "●●●●●●●●";
}

namespace Ui {
    class Share_link_widget;
}

class Share;

/***********************************************************
@brief The Share_dialog class
@ingroup gui
***********************************************************/
class Share_link_widget : Gtk.Widget {

public:
    Share_link_widget (AccountPtr account,
        const string &share_path,
        const string &local_path,
        Share_permissions max_sharing_permissions,
        Gtk.Widget *parent = nullptr);
    ~Share_link_widget () override;

    void toggle_button (bool show);
    void setup_ui_options ();

    void set_link_share (QSharedPointer<Link_share> link_share);
    QSharedPointer<Link_share> get_link_share ();

    void focus_password_line_edit ();

public slots:
    void slot_delete_share_fetched ();
    void slot_toggle_share_link_animation (bool start);
    void slot_server_error (int code, string &message);
    void slot_create_share_requires_password (string &message);
    void slot_style_changed ();

private slots:
    void slot_create_share_link (bool clicked);
    void slot_copy_link_share (bool clicked) const;

    void slot_create_password ();
    void slot_password_set ();
    void slot_password_set_error (int code, string &message);

    void slot_create_note ();
    void slot_note_set ();

    void slot_set_expire_date ();
    void slot_expire_date_set ();

    void slot_context_menu_button_clicked ();
    void slot_link_context_menu_action_triggered (QAction *action);

    void slot_delete_animation_finished ();
    void slot_animation_finished ();

    void slot_create_label ();
    void slot_label_set ();

signals:
    void create_link_share ();
    void delete_link_share ();
    void resize_requested ();
    void visual_deletion_done ();
    void create_password (string &password);
    void create_password_processed ();

private:
    void display_error (string &err_msg);

    void toggle_password_options (bool enable = true);
    void toggle_note_options (bool enable = true);
    void toggle_expire_date_options (bool enable = true);
    void toggle_button_animation (QToolButton *button, QProgress_indicator *progress_indicator, QAction *checked_action) const;

    /***********************************************************
    Confirm with the user and then delete the share */
    void confirm_and_delete_share ();

    /***********************************************************
    Retrieve a share's name, accounting for _names_supported */
    string share_name ();

    void start_animation (int start, int end);

    void customize_style ();

    void display_share_link_label ();

    Ui.Share_link_widget *_ui;
    AccountPtr _account;
    string _share_path;
    string _local_path;
    string _share_url;

    QSharedPointer<Link_share> _link_share;

    bool _is_file;
    bool _password_required;
    bool _expiry_required;
    bool _names_supported;
    bool _note_required;

    QMenu *_link_context_menu;
    QAction *_read_only_link_action;
    QAction *_allow_editing_link_action;
    QAction *_allow_upload_editing_link_action;
    QAction *_allow_upload_link_action;
    QAction *_password_protect_link_action;
    QAction *_expiration_date_link_action;
    QAction *_unshare_link_action;
    QAction *_add_another_link_action;
    QAction *_note_link_action;
    QHBox_layout *_share_link_layout{};
    QLabel *_share_link_label{};
    ElidedLabel *_share_link_elided_label{};
    QLineEdit *_share_link_edit{};
    QToolButton *_share_link_button{};
    QProgress_indicator *_share_link_progress_indicator{};
    Gtk.Widget *_share_link_default_widget{};
    QWidget_action *_share_link_widget_action{};
};


Share_link_widget.Share_link_widget (AccountPtr account,
    const string &share_path,
    const string &local_path,
    Share_permissions max_sharing_permissions,
    Gtk.Widget *parent)
    : Gtk.Widget (parent)
    , _ui (new Ui.Share_link_widget)
    , _account (account)
    , _share_path (share_path)
    , _local_path (local_path)
    , _link_share (nullptr)
    , _password_required (false)
    , _expiry_required (false)
    , _names_supported (true)
    , _note_required (false)
    , _link_context_menu (nullptr)
    , _read_only_link_action (nullptr)
    , _allow_editing_link_action (nullptr)
    , _allow_upload_editing_link_action (nullptr)
    , _allow_upload_link_action (nullptr)
    , _password_protect_link_action (nullptr)
    , _expiration_date_link_action (nullptr)
    , _unshare_link_action (nullptr)
    , _note_link_action (nullptr) {
    _ui.setup_ui (this);

    _ui.share_link_tool_button.hide ();

    //Is this a file or folder?
    QFileInfo fi (local_path);
    _is_file = fi.is_file ();

    connect (_ui.enable_share_link, &QPushButton.clicked, this, &Share_link_widget.slot_create_share_link);
    connect (_ui.line_edit_password, &QLineEdit.return_pressed, this, &Share_link_widget.slot_create_password);
    connect (_ui.confirm_password, &QAbstractButton.clicked, this, &Share_link_widget.slot_create_password);
    connect (_ui.confirm_note, &QAbstractButton.clicked, this, &Share_link_widget.slot_create_note);
    connect (_ui.confirm_expiration_date, &QAbstractButton.clicked, this, &Share_link_widget.slot_set_expire_date);

    _ui.error_label.hide ();

    auto sharing_possible = true;
    if (!_account.capabilities ().share_public_link ()) {
        q_c_warning (lc_share_link) << "Link shares have been disabled";
        sharing_possible = false;
    } else if (! (max_sharing_permissions & Share_permission_share)) {
        q_c_warning (lc_share_link) << "The file can not be shared because it was shared without sharing permission.";
        sharing_possible = false;
    }

    _ui.enable_share_link.set_checked (false);
    _ui.share_link_tool_button.set_enabled (false);
    _ui.share_link_tool_button.hide ();

    // Older servers don't support multiple public link shares
    if (!_account.capabilities ().share_public_link_multiple ()) {
        _names_supported = false;
    }

    toggle_password_options (false);
    toggle_expire_date_options (false);
    toggle_note_options (false);

    _ui.note_progress_indicator.set_visible (false);
    _ui.password_progress_indicator.set_visible (false);
    _ui.expiration_date_progress_indicator.set_visible (false);
    _ui.sharelink_progress_indicator.set_visible (false);

    // check if the file is already inside of a synced folder
    if (share_path.is_empty ()) {
        q_c_warning (lc_share_link) << "Unable to share files not in a sync folder.";
        return;
    }
}

Share_link_widget.~Share_link_widget () {
    delete _ui;
}

void Share_link_widget.slot_toggle_share_link_animation (bool start) {
    _ui.sharelink_progress_indicator.set_visible (start);
    if (start) {
        if (!_ui.sharelink_progress_indicator.is_animated ()) {
            _ui.sharelink_progress_indicator.start_animation ();
        }
    } else {
        _ui.sharelink_progress_indicator.stop_animation ();
    }
}

void Share_link_widget.toggle_button_animation (QToolButton *button, QProgress_indicator *progress_indicator, QAction *checked_action) {
    auto start_animation = false;
    const auto action_is_checked = checked_action.is_checked ();
    if (!progress_indicator.is_animated () && action_is_checked) {
        progress_indicator.start_animation ();
        start_animation = true;
    } else {
        progress_indicator.stop_animation ();
    }

    button.set_visible (!start_animation && action_is_checked);
    progress_indicator.set_visible (start_animation && action_is_checked);
}

void Share_link_widget.set_link_share (QSharedPointer<Link_share> link_share) {
    _link_share = link_share;
}

QSharedPointer<Link_share> Share_link_widget.get_link_share () {
    return _link_share;
}

void Share_link_widget.focus_password_line_edit () {
    _ui.line_edit_password.set_focus ();
}

void Share_link_widget.setup_ui_options () {
    connect (_link_share.data (), &Link_share.note_set, this, &Share_link_widget.slot_note_set);
    connect (_link_share.data (), &Link_share.password_set, this, &Share_link_widget.slot_password_set);
    connect (_link_share.data (), &Link_share.password_set_error, this, &Share_link_widget.slot_password_set_error);
    connect (_link_share.data (), &Link_share.label_set, this, &Share_link_widget.slot_label_set);

    // Prepare permissions check and create group action
    const QDate expire_date = _link_share.data ().get_expire_date ().is_valid () ? _link_share.data ().get_expire_date () : QDate ();
    const Share_permissions perm = _link_share.data ().get_permissions ();
    auto checked = false;
    auto *permissions_group = new QAction_group (this);

    // Prepare sharing menu
    _link_context_menu = new QMenu (this);

    // radio button style
    permissions_group.set_exclusive (true);

    if (_is_file) {
        checked = (perm & Share_permission_read) && (perm & Share_permission_update);
        _allow_editing_link_action = _link_context_menu.add_action (tr ("Allow editing"));
        _allow_editing_link_action.set_checkable (true);
        _allow_editing_link_action.set_checked (checked);

    } else {
        checked = (perm == Share_permission_read);
        _read_only_link_action = permissions_group.add_action (tr ("View only"));
        _read_only_link_action.set_checkable (true);
        _read_only_link_action.set_checked (checked);

        checked = (perm & Share_permission_read) && (perm & Share_permission_create)
            && (perm & Share_permission_update) && (perm & Share_permission_delete);
        _allow_upload_editing_link_action = permissions_group.add_action (tr ("Allow upload and editing"));
        _allow_upload_editing_link_action.set_checkable (true);
        _allow_upload_editing_link_action.set_checked (checked);

        checked = (perm == Share_permission_create);
        _allow_upload_link_action = permissions_group.add_action (tr ("File drop (upload only)"));
        _allow_upload_link_action.set_checkable (true);
        _allow_upload_link_action.set_checked (checked);
    }

    _share_link_elided_label = new Occ.ElidedLabel (this);
    _share_link_elided_label.set_elide_mode (Qt.Elide_right);
    display_share_link_label ();
    _ui.horizontal_layout.insert_widget (2, _share_link_elided_label);

    _share_link_layout = new QHBox_layout (this);

    _share_link_label = new QLabel (this);
    _share_link_label.set_pixmap (string (":/client/theme/black/edit.svg"));
    _share_link_layout.add_widget (_share_link_label);

    _share_link_edit = new QLineEdit (this);
    connect (_share_link_edit, &QLineEdit.return_pressed, this, &Share_link_widget.slot_create_label);
    _share_link_edit.set_placeholder_text (tr ("Link name"));
    _share_link_edit.set_text (_link_share.data ().get_label ());
    _share_link_layout.add_widget (_share_link_edit);

    _share_link_button = new QToolButton (this);
    connect (_share_link_button, &QToolButton.clicked, this, &Share_link_widget.slot_create_label);
    _share_link_button.set_icon (QIcon (":/client/theme/confirm.svg"));
    _share_link_button.set_tool_button_style (Qt.Tool_button_icon_only);
    _share_link_layout.add_widget (_share_link_button);

    _share_link_progress_indicator = new QProgress_indicator (this);
    _share_link_progress_indicator.set_visible (false);
    _share_link_layout.add_widget (_share_link_progress_indicator);

    _share_link_default_widget = new Gtk.Widget (this);
    _share_link_default_widget.set_layout (_share_link_layout);

    _share_link_widget_action = new QWidget_action (this);
    _share_link_widget_action.set_default_widget (_share_link_default_widget);
    _share_link_widget_action.set_checkable (true);
    _link_context_menu.add_action (_share_link_widget_action);

    // Adds permissions actions (radio button style)
    if (_is_file) {
        _link_context_menu.add_action (_allow_editing_link_action);
    } else {
        _link_context_menu.add_action (_read_only_link_action);
        _link_context_menu.add_action (_allow_upload_editing_link_action);
        _link_context_menu.add_action (_allow_upload_link_action);
    }

    // Adds action to display note widget (check box)
    _note_link_action = _link_context_menu.add_action (tr ("Note to recipient"));
    _note_link_action.set_checkable (true);

    if (_link_share.get_note ().is_simple_text () && !_link_share.get_note ().is_empty ()) {
        _ui.text_edit_note.set_text (_link_share.get_note ());
        _note_link_action.set_checked (true);
        toggle_note_options ();
    }

    // Adds action to display password widget (check box)
    _password_protect_link_action = _link_context_menu.add_action (tr ("Password protect"));
    _password_protect_link_action.set_checkable (true);

    if (_link_share.data ().is_password_set ()) {
        _password_protect_link_action.set_checked (true);
        _ui.line_edit_password.set_placeholder_text (string.from_utf8 (password_is_set_placeholder));
        toggle_password_options ();
    }

    // If password is enforced then don't allow users to disable it
    if (_account.capabilities ().share_public_link_enforce_password ()) {
        if (_link_share.data ().is_password_set ()) {
            _password_protect_link_action.set_checked (true);
            _password_protect_link_action.set_enabled (false);
        }
        _password_required = true;
    }

    // Adds action to display expiration date widget (check box)
    _expiration_date_link_action = _link_context_menu.add_action (tr ("Set expiration date"));
    _expiration_date_link_action.set_checkable (true);
    if (!expire_date.is_null ()) {
        _ui.calendar.set_date (expire_date);
        _expiration_date_link_action.set_checked (true);
        toggle_expire_date_options ();
    }
    connect (_ui.calendar, &QDate_time_edit.date_changed, this, &Share_link_widget.slot_set_expire_date);
    connect (_link_share.data (), &Link_share.expire_date_set, this, &Share_link_widget.slot_expire_date_set);

    // If expiredate is enforced do not allow disable and set max days
    if (_account.capabilities ().share_public_link_enforce_expire_date ()) {
        _ui.calendar.set_maximum_date (QDate.current_date ().add_days (
            _account.capabilities ().share_public_link_expire_date_days ()));
        _expiration_date_link_action.set_checked (true);
        _expiration_date_link_action.set_enabled (false);
        _expiry_required = true;
    }

    // Adds action to unshare widget (check box)
    _unshare_link_action = _link_context_menu.add_action (QIcon (":/client/theme/delete.svg"),
        tr ("Delete link"));

    _link_context_menu.add_separator ();

    _add_another_link_action = _link_context_menu.add_action (QIcon (":/client/theme/add.svg"),
        tr ("Add another link"));

    _ui.enable_share_link.set_icon (QIcon (":/client/theme/copy.svg"));
    disconnect (_ui.enable_share_link, &QPushButton.clicked, this, &Share_link_widget.slot_create_share_link);
    connect (_ui.enable_share_link, &QPushButton.clicked, this, &Share_link_widget.slot_copy_link_share);

    connect (_link_context_menu, &QMenu.triggered,
        this, &Share_link_widget.slot_link_context_menu_action_triggered);

    _ui.share_link_tool_button.set_menu (_link_context_menu);
    _ui.share_link_tool_button.set_enabled (true);
    _ui.enable_share_link.set_enabled (true);
    _ui.enable_share_link.set_checked (true);

    // show sharing options
    _ui.share_link_tool_button.show ();

    customize_style ();
}

void Share_link_widget.slot_create_note () {
    const auto note = _ui.text_edit_note.to_plain_text ();
    if (!_link_share || _link_share.get_note () == note || note.is_empty ()) {
        return;
    }

    toggle_button_animation (_ui.confirm_note, _ui.note_progress_indicator, _note_link_action);
    _ui.error_label.hide ();
    _link_share.set_note (note);
}

void Share_link_widget.slot_note_set () {
    toggle_button_animation (_ui.confirm_note, _ui.note_progress_indicator, _note_link_action);
}

void Share_link_widget.slot_copy_link_share (bool clicked) {
    Q_UNUSED (clicked);

    QApplication.clipboard ().set_text (_link_share.get_link ().to_string ());
}

void Share_link_widget.slot_expire_date_set () {
    toggle_button_animation (_ui.confirm_expiration_date, _ui.expiration_date_progress_indicator, _expiration_date_link_action);
}

void Share_link_widget.slot_set_expire_date () {
    if (!_link_share) {
        return;
    }

    toggle_button_animation (_ui.confirm_expiration_date, _ui.expiration_date_progress_indicator, _expiration_date_link_action);
    _ui.error_label.hide ();
    _link_share.set_expire_date (_ui.calendar.date ());
}

void Share_link_widget.slot_create_password () {
    if (!_link_share || _ui.line_edit_password.text ().is_empty ()) {
        return;
    }

    toggle_button_animation (_ui.confirm_password, _ui.password_progress_indicator, _password_protect_link_action);
    _ui.error_label.hide ();
    emit create_password (_ui.line_edit_password.text ());
}

void Share_link_widget.slot_create_share_link (bool clicked) {
    Q_UNUSED (clicked);
    slot_toggle_share_link_animation (true);
    emit create_link_share ();
}

void Share_link_widget.slot_password_set () {
    toggle_button_animation (_ui.confirm_password, _ui.password_progress_indicator, _password_protect_link_action);

    _ui.line_edit_password.set_text ({});

    if (_link_share.is_password_set ()) {
        _ui.line_edit_password.set_enabled (true);
        _ui.line_edit_password.set_placeholder_text (string.from_utf8 (password_is_set_placeholder));
    } else {
        _ui.line_edit_password.set_placeholder_text ({});
    }

    emit create_password_processed ();
}

void Share_link_widget.slot_password_set_error (int code, string &message) {
    toggle_button_animation (_ui.confirm_password, _ui.password_progress_indicator, _password_protect_link_action);

    slot_server_error (code, message);
    toggle_password_options ();
    _ui.line_edit_password.set_focus ();
    emit create_password_processed ();
}

void Share_link_widget.start_animation (int start, int end) {
    auto *animation = new QPropertyAnimation (this, "maximum_height", this);

    animation.set_duration (500);
    animation.set_start_value (start);
    animation.set_end_value (end);

    connect (animation, &QAbstractAnimation.finished, this, &Share_link_widget.slot_animation_finished);
    if (end < start) // that is to remove the widget, not to show it
        connect (animation, &QAbstractAnimation.finished, this, &Share_link_widget.slot_delete_animation_finished);
    connect (animation, &QVariant_animation.value_changed, this, &Share_link_widget.resize_requested);

    animation.start ();
}

void Share_link_widget.slot_delete_share_fetched () {
    slot_toggle_share_link_animation (false);

    _link_share.clear ();
    toggle_password_options (false);
    toggle_note_options (false);
    toggle_expire_date_options (false);
    emit delete_link_share ();
}

void Share_link_widget.toggle_note_options (bool enable) {
    _ui.note_label.set_visible (enable);
    _ui.text_edit_note.set_visible (enable);
    _ui.confirm_note.set_visible (enable);
    _ui.text_edit_note.set_text (enable && _link_share ? _link_share.get_note () : string ());

    if (!enable && _link_share && !_link_share.get_note ().is_empty ()) {
        _link_share.set_note ({});
    }
}

void Share_link_widget.slot_animation_finished () {
    emit resize_requested ();
    delete_later ();
}

void Share_link_widget.slot_create_label () {
    const auto label_text = _share_link_edit.text ();
    if (!_link_share || _link_share.get_label () == label_text || label_text.is_empty ()) {
        return;
    }
    _share_link_widget_action.set_checked (true);
    toggle_button_animation (_share_link_button, _share_link_progress_indicator, _share_link_widget_action);
    _ui.error_label.hide ();
    _link_share.set_label (_share_link_edit.text ());
}

void Share_link_widget.slot_label_set () {
    toggle_button_animation (_share_link_button, _share_link_progress_indicator, _share_link_widget_action);
    display_share_link_label ();
}

void Share_link_widget.slot_delete_animation_finished () {
    // There is a painting bug where a small line of this widget isn't
    // properly cleared. This explicit repaint () call makes sure any trace of
    // the share widget is removed once it's destroyed. #4189
    connect (this, SIGNAL (destroyed (GLib.Object *)), parent_widget (), SLOT (repaint ()));
}

void Share_link_widget.slot_create_share_requires_password (string &message) {
    slot_toggle_share_link_animation (message.is_empty ());

    if (!message.is_empty ()) {
        _ui.error_label.set_text (message);
        _ui.error_label.show ();
    }

    _password_required = true;

    toggle_password_options ();
}

void Share_link_widget.toggle_password_options (bool enable) {
    _ui.password_label.set_visible (enable);
    _ui.line_edit_password.set_visible (enable);
    _ui.confirm_password.set_visible (enable);
    _ui.line_edit_password.set_focus ();

    if (!enable && _link_share && _link_share.is_password_set ()) {
        _link_share.set_password ({});
    }
}

void Share_link_widget.toggle_expire_date_options (bool enable) {
    _ui.expiration_label.set_visible (enable);
    _ui.calendar.set_visible (enable);
    _ui.confirm_expiration_date.set_visible (enable);

    const auto date = enable ? _link_share.get_expire_date () : QDate.current_date ().add_days (1);
    _ui.calendar.set_date (date);
    _ui.calendar.set_minimum_date (QDate.current_date ().add_days (1));
    _ui.calendar.set_maximum_date (
        QDate.current_date ().add_days (_account.capabilities ().share_public_link_expire_date_days ()));
    _ui.calendar.set_focus ();

    if (!enable && _link_share && _link_share.get_expire_date ().is_valid ()) {
        _link_share.set_expire_date ({});
    }
}

void Share_link_widget.confirm_and_delete_share () {
    auto message_box = new QMessageBox (
        QMessageBox.Question,
        tr ("Confirm Link Share Deletion"),
        tr ("<p>Do you really want to delete the public link share <i>%1</i>?</p>"
           "<p>Note : This action cannot be undone.</p>")
            .arg (share_name ()),
        QMessageBox.NoButton,
        this);
    QPushButton *yes_button =
        message_box.add_button (tr ("Delete"), QMessageBox.YesRole);
    message_box.add_button (tr ("Cancel"), QMessageBox.NoRole);

    connect (message_box, &QMessageBox.finished, this,
        [message_box, yes_button, this] () {
            if (message_box.clicked_button () == yes_button) {
                this.slot_toggle_share_link_animation (true);
                this._link_share.delete_share ();
            }
        });
    message_box.open ();
}

string Share_link_widget.share_name () {
    string name = _link_share.get_name ();
    if (!name.is_empty ())
        return name;
    if (!_names_supported)
        return tr ("Public link");
    return _link_share.get_token ();
}

void Share_link_widget.slot_context_menu_button_clicked () {
    _link_context_menu.exec (QCursor.pos ());
}

void Share_link_widget.slot_link_context_menu_action_triggered (QAction *action) {
    const auto state = action.is_checked ();
    Share_permissions perm = Share_permission_read;

    if (action == _add_another_link_action) {
        emit create_link_share ();

    } else if (action == _read_only_link_action && state) {
        _link_share.set_permissions (perm);

    } else if (action == _allow_editing_link_action && state) {
        perm |= Share_permission_update;
        _link_share.set_permissions (perm);

    } else if (action == _allow_upload_editing_link_action && state) {
        perm |= Share_permission_create | Share_permission_update | Share_permission_delete;
        _link_share.set_permissions (perm);

    } else if (action == _allow_upload_link_action && state) {
        perm = Share_permission_create;
        _link_share.set_permissions (perm);

    } else if (action == _password_protect_link_action) {
        toggle_password_options (state);

    } else if (action == _expiration_date_link_action) {
        toggle_expire_date_options (state);

    } else if (action == _note_link_action) {
        toggle_note_options (state);

    } else if (action == _unshare_link_action) {
        confirm_and_delete_share ();
    }
}

void Share_link_widget.slot_server_error (int code, string &message) {
    slot_toggle_share_link_animation (false);

    q_c_warning (lc_sharing) << "Error from server" << code << message;
    display_error (message);
}

void Share_link_widget.display_error (string &err_msg) {
    _ui.error_label.set_text (err_msg);
    _ui.error_label.show ();
}

void Share_link_widget.slot_style_changed () {
    customize_style ();
}

void Share_link_widget.customize_style () {
    _unshare_link_action.set_icon (Theme.create_color_aware_icon (":/client/theme/delete.svg"));

    _add_another_link_action.set_icon (Theme.create_color_aware_icon (":/client/theme/add.svg"));

    _ui.enable_share_link.set_icon (Theme.create_color_aware_icon (":/client/theme/copy.svg"));

    _ui.share_link_icon_label.set_pixmap (Theme.create_color_aware_pixmap (":/client/theme/public.svg"));

    _ui.share_link_tool_button.set_icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

    _ui.confirm_note.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
    _ui.confirm_password.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
    _ui.confirm_expiration_date.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

    _ui.password_progress_indicator.set_color (QGuiApplication.palette ().color (QPalette.Text));
}

void Share_link_widget.display_share_link_label () {
    _share_link_elided_label.clear ();
    if (!_link_share.get_label ().is_empty ()) {
        _share_link_elided_label.set_text (string (" (%1)").arg (_link_share.get_label ()));
    }
}

}
