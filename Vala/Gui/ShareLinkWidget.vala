/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>
Copyright (C) 2015 by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include <QClipboard>
//  #include <GLib.FileInfo>
//  #include <QDesktopServices>
//  #include <QMessageBox>
//  #include <QMenu>
//  #include <QText_edit>
//  #include <QToolButton>
//  #include <QPropertyAnimation>
//  #include <Gtk.Dialog
//  #include <QToolBu
//  #include <QHBox_layo
//  #include <QLineEdit>
//  #include <QWidgetAction>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ShareDialog class
@ingroup gui
***********************************************************/
public class ShareLinkWidget : Gtk.Widget {

    private const string PASSWORD_IS_PLACEHOLDER = "●●●●●●●●";

    private Ui.ShareLinkWidget ui;
    private unowned Account account;
    private string share_path;
    private string local_path;
    private string share_url;

    public unowned LinkShare link_share;

    private bool is_file;
    private bool password_required;
    private bool expiry_required;
    private bool names_supported;
    private bool note_required;

    private QMenu link_context_menu;
    private QAction read_only_link_action;
    private QAction allow_editing_link_action;
    private QAction allow_upload_editing_link_action;
    private QAction allow_upload_link_action;
    private QAction password_protect_link_action;
    private QAction expiration_date_link_action;
    private QAction unshare_link_action;
    private QAction add_another_link_action;
    private QAction note_link_action;
    private QHBoxLayout share_link_layout = new QHBoxLayout ();
    private Gtk.Label share_link_label = new Gtk.Label ();
    private ElidedLabel share_link_elided_label = new ElidedLabel ();
    private QLineEdit share_link_edit = new QLineEdit ();
    private QToolButton share_link_button = new QToolButton ();
    private QProgressIndicator share_link_progress_indicator = new QProgressIndicator ();
    private Gtk.Widget share_link_default_widget = new Gtk.Widget ();
    private QWidgetAction share_link_widget_action = new QWidgetAction ();


    signal void create_link_share ();
    signal void delete_link_share ();
    signal void resize_requested ();
    signal void visual_deletion_done ();
    signal void create_password (string password);
    signal void create_password_processed ();


    /***********************************************************
    ***********************************************************/
    public ShareLinkWidget (
        unowned Account account,
        string share_path,
        string local_path,
        SharePermissions max_sharing_permissions,
        Gtk.Widget parent = null) {
        base (parent);
        this.ui = new Ui.ShareLinkWidget ();
        this.account = account;
        this.share_path = share_path;
        this.local_path = local_path;
        this.link_share = null;
        this.password_required = false;
        this.expiry_required = false;
        this.names_supported = true;
        this.note_required = false;
        this.link_context_menu = null;
        this.read_only_link_action = null;
        this.allow_editing_link_action = null;
        this.allow_upload_editing_link_action = null;
        this.allow_upload_link_action = null;
        this.password_protect_link_action = null;
        this.expiration_date_link_action = null;
        this.unshare_link_action = null;
        this.note_link_action = null;
        this.ui.up_ui (this);

        this.ui.share_link_tool_button.hide ();

        //Is this a file or folder?
        GLib.FileInfo file_info = new GLib.FileInfo (local_path);
        this.is_file = file_info.is_file ();

        connect (this.ui.enable_share_link, QPushButton.clicked, this, ShareLinkWidget.on_signal_create_share_link);
        connect (this.ui.line_edit_password, QLineEdit.return_pressed, this, ShareLinkWidget.on_signal_create_password);
        connect (this.ui.confirm_password, QAbstractButton.clicked, this, ShareLinkWidget.on_signal_create_password);
        connect (this.ui.confirm_note, QAbstractButton.clicked, this, ShareLinkWidget.on_signal_create_note);
        connect (this.ui.confirm_expiration_date, QAbstractButton.clicked, this, ShareLinkWidget.on_signal_expire_date);

        this.ui.error_label.hide ();

        var sharing_possible = true;
        if (!this.account.capabilities ().share_public_link ()) {
            GLib.warning ("Link shares have been disabled.");
            sharing_possible = false;
        } else if (! (max_sharing_permissions & Share_permission_share)) {
            GLib.warning ("The file can not be shared because it was shared without sharing permission.");
            sharing_possible = false;
        }

        this.ui.enable_share_link.checked (false);
        this.ui.share_link_tool_button.enabled (false);
        this.ui.share_link_tool_button.hide ();

        // Older servers don't support multiple public link shares
        if (!this.account.capabilities ().share_public_link_multiple ()) {
            this.names_supported = false;
        }

        toggle_password_options (false);
        toggle_expire_date_options (false);
        toggle_note_options (false);

        this.ui.note_progress_indicator.visible (false);
        this.ui.password_progress_indicator.visible (false);
        this.ui.expiration_date_progress_indicator.visible (false);
        this.ui.sharelink_progress_indicator.visible (false);

        // check if the file is already inside of a synced folder
        if (share_path.is_empty ()) {
            GLib.warning ("Unable to share files not in a sync folder.");
            return;
        }
    }


    override ~ShareLinkWidget () {
        delete this.ui;
    }

    /***********************************************************
    ***********************************************************/
    public void toggle_button (bool show);


    /***********************************************************
    ***********************************************************/
    public void setup_ui_options () {
        connect (this.link_share.data (), LinkShare.signal_note_set, this, ShareLinkWidget.on_signal_note_set);
        connect (this.link_share.data (), LinkShare.signal_password_set, this, ShareLinkWidget.on_signal_password_set);
        connect (this.link_share.data (), LinkShare.signal_password_error, this, ShareLinkWidget.on_signal_password_error);
        connect (this.link_share.data (), LinkShare.signal_label_set, this, ShareLinkWidget.on_signal_label_set);

        // Prepare permissions check and create group action
        const QDate expire_date = this.link_share.data ().expire_date ().is_valid () ? this.link_share.data ().expire_date () : QDate ();
        const SharePermissions perm = this.link_share.data ().permissions ();
        var checked = false;
        var permissions_group = new QAction_group (this);

        // Prepare sharing menu
        this.link_context_menu = new QMenu (this);

        // radio button style
        permissions_group.exclusive (true);

        if (this.is_file) {
            checked = (perm & SharePermissionRead) && (perm & Share_permission_update);
            this.allow_editing_link_action = this.link_context_menu.add_action (_("Allow editing"));
            this.allow_editing_link_action.checkable (true);
            this.allow_editing_link_action.checked (checked);

        } else {
            checked = (perm == SharePermissionRead);
            this.read_only_link_action = permissions_group.add_action (_("View only"));
            this.read_only_link_action.checkable (true);
            this.read_only_link_action.checked (checked);

            checked = (perm & SharePermissionRead) && (perm & Share_permission_create)
                && (perm & Share_permission_update) && (perm & Share_permission_delete);
            this.allow_upload_editing_link_action = permissions_group.add_action (_("Allow upload and editing"));
            this.allow_upload_editing_link_action.checkable (true);
            this.allow_upload_editing_link_action.checked (checked);

            checked = (perm == Share_permission_create);
            this.allow_upload_link_action = permissions_group.add_action (_("File drop (upload only)"));
            this.allow_upload_link_action.checkable (true);
            this.allow_upload_link_action.checked (checked);
        }

        this.share_link_elided_label = new Occ.ElidedLabel (this);
        this.share_link_elided_label.elide_mode (Qt.Elide_right);
        display_share_link_label ();
        this.ui.horizontal_layout.insert_widget (2, this.share_link_elided_label);

        this.share_link_layout = new QHBoxLayout (this);

        this.share_link_label = new Gtk.Label (this);
        this.share_link_label.pixmap (string (":/client/theme/black/edit.svg"));
        this.share_link_layout.add_widget (this.share_link_label);

        this.share_link_edit = new QLineEdit (this);
        connect (this.share_link_edit, QLineEdit.return_pressed, this, ShareLinkWidget.on_signal_create_label);
        this.share_link_edit.placeholder_text (_("Link name"));
        this.share_link_edit.on_signal_text (this.link_share.data ().label ());
        this.share_link_layout.add_widget (this.share_link_edit);

        this.share_link_button = new QToolButton (this);
        connect (this.share_link_button, QToolButton.clicked, this, ShareLinkWidget.on_signal_create_label);
        this.share_link_button.icon (QIcon (":/client/theme/confirm.svg"));
        this.share_link_button.tool_button_style (Qt.Tool_button_icon_only);
        this.share_link_layout.add_widget (this.share_link_button);

        this.share_link_progress_indicator = new QProgressIndicator (this);
        this.share_link_progress_indicator.visible (false);
        this.share_link_layout.add_widget (this.share_link_progress_indicator);

        this.share_link_default_widget = new Gtk.Widget (this);
        this.share_link_default_widget.layout (this.share_link_layout);

        this.share_link_widget_action = new QWidgetAction (this);
        this.share_link_widget_action.default_widget (this.share_link_default_widget);
        this.share_link_widget_action.checkable (true);
        this.link_context_menu.add_action (this.share_link_widget_action);

        // Adds permissions actions (radio button style)
        if (this.is_file) {
            this.link_context_menu.add_action (this.allow_editing_link_action);
        } else {
            this.link_context_menu.add_action (this.read_only_link_action);
            this.link_context_menu.add_action (this.allow_upload_editing_link_action);
            this.link_context_menu.add_action (this.allow_upload_link_action);
        }

        // Adds action to display note widget (check box)
        this.note_link_action = this.link_context_menu.add_action (_("Note to recipient"));
        this.note_link_action.checkable (true);

        if (this.link_share.note ().is_simple_text () && !this.link_share.note ().is_empty ()) {
            this.ui.text_edit_note.on_signal_text (this.link_share.note ());
            this.note_link_action.checked (true);
            toggle_note_options ();
        }

        // Adds action to display password widget (check box)
        this.password_protect_link_action = this.link_context_menu.add_action (_("Password protect"));
        this.password_protect_link_action.checkable (true);

        if (this.link_share.data ().is_password_set ()) {
            this.password_protect_link_action.checked (true);
            this.ui.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
            toggle_password_options ();
        }

        // If password is enforced then don't allow users to disable it
        if (this.account.capabilities ().share_public_link_enforce_password ()) {
            if (this.link_share.data ().is_password_set ()) {
                this.password_protect_link_action.checked (true);
                this.password_protect_link_action.enabled (false);
            }
            this.password_required = true;
        }

        // Adds action to display expiration date widget (check box)
        this.expiration_date_link_action = this.link_context_menu.add_action (_("Set expiration date"));
        this.expiration_date_link_action.checkable (true);
        if (!expire_date.is_null ()) {
            this.ui.calendar.date (expire_date);
            this.expiration_date_link_action.checked (true);
            toggle_expire_date_options ();
        }
        connect (this.ui.calendar, QDateTimeEdit.date_changed, this, ShareLinkWidget.on_signal_expire_date);
        connect (this.link_share.data (), LinkShare.signal_expire_date_set, this, ShareLinkWidget.on_signal_expire_date_set);

        // If expiredate is enforced do not allow disable and set max days
        if (this.account.capabilities ().share_public_link_enforce_expire_date ()) {
            this.ui.calendar.maximum_date (QDate.current_date ().add_days (
                this.account.capabilities ().share_public_link_expire_date_days ()));
            this.expiration_date_link_action.checked (true);
            this.expiration_date_link_action.enabled (false);
            this.expiry_required = true;
        }

        // Adds action to unshare widget (check box)
        this.unshare_link_action = this.link_context_menu.add_action (QIcon (":/client/theme/delete.svg"),
            _("Delete link"));

        this.link_context_menu.add_separator ();

        this.add_another_link_action = this.link_context_menu.add_action (QIcon (":/client/theme/add.svg"),
            _("Add another link"));

        this.ui.enable_share_link.icon (QIcon (":/client/theme/copy.svg"));
        disconnect (this.ui.enable_share_link, QPushButton.clicked, this, ShareLinkWidget.on_signal_create_share_link);
        connect (this.ui.enable_share_link, QPushButton.clicked, this, ShareLinkWidget.on_signal_copy_link_share);

        connect (this.link_context_menu, QMenu.triggered,
            this, ShareLinkWidget.on_signal_link_context_menu_action_triggered);

        this.ui.share_link_tool_button.menu (this.link_context_menu);
        this.ui.share_link_tool_button.enabled (true);
        this.ui.enable_share_link.enabled (true);
        this.ui.enable_share_link.checked (true);

        // show sharing options
        this.ui.share_link_tool_button.show ();

        customize_style ();
    }



    /***********************************************************
    ***********************************************************/
    public void on_signal_toggle_share_link_animation (bool on_signal_start) {
        this.ui.sharelink_progress_indicator.visible (on_signal_start);
        if (on_signal_start) {
            if (!this.ui.sharelink_progress_indicator.is_animated ()) {
                this.ui.sharelink_progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.ui.sharelink_progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_focus_password_line_edit () {
        this.ui.line_edit_password.focus ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_delete_share_fetched ();
    void ShareLinkWidget.on_signal_delete_share_fetched () {
        on_signal_toggle_share_link_animation (false);

        this.link_share.clear ();
        toggle_password_options (false);
        toggle_note_options (false);
        toggle_expire_date_options (false);
        /* emit */ delete_link_share ();
    }


    /***********************************************************
    ***********************************************************/
    public 
    void ShareLinkWidget.on_signal_note_set () {
        toggle_button_animation (this.ui.confirm_note, this.ui.note_progress_indicator, this.note_link_action);
    }



    /***********************************************************
    ***********************************************************/
    public 
    void ShareLinkWidget.on_signal_link_context_menu_action_triggered (QAction action) {
        const var state = action.is_checked ();
        SharePermissions perm = SharePermissionRead;

        if (action == this.add_another_link_action) {
            /* emit */ create_link_share ();

        } else if (action == this.read_only_link_action && state) {
            this.link_share.permissions (perm);

        } else if (action == this.allow_editing_link_action && state) {
            perm |= Share_permission_update;
            this.link_share.permissions (perm);

        } else if (action == this.allow_upload_editing_link_action && state) {
            perm |= Share_permission_create | Share_permission_update | Share_permission_delete;
            this.link_share.permissions (perm);

        } else if (action == this.allow_upload_link_action && state) {
            perm = Share_permission_create;
            this.link_share.permissions (perm);

        } else if (action == this.password_protect_link_action) {
            toggle_password_options (state);

        } else if (action == this.expiration_date_link_action) {
            toggle_expire_date_options (state);

        } else if (action == this.note_link_action) {
            toggle_note_options (state);

        } else if (action == this.unshare_link_action) {
            confirm_and_delete_share ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_server_error (int code, string message);
    void ShareLinkWidget.on_signal_server_error (int code, string message) {
        on_signal_toggle_share_link_animation (false);

        GLib.warning ("Error from server " + code + message);
        on_signal_display_error (message);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_create_share_requires_password (string message);
    void ShareLinkWidget.on_signal_create_share_requires_password (string message) {
        on_signal_toggle_share_link_animation (message.is_empty ());

        if (!message.is_empty ()) {
            this.ui.error_label.on_signal_text (message);
            this.ui.error_label.show ();
        }

        this.password_required = true;

        toggle_password_options ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed ();
    void ShareLinkWidget.on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_share_link (bool clicked);
    void ShareLinkWidget.on_signal_create_share_link (bool clicked) {
        //  Q_UNUSED (clicked);
        on_signal_toggle_share_link_animation (true);
        /* emit */ create_link_share ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_password ();
    void ShareLinkWidget.on_signal_create_password () {
        if (!this.link_share || this.ui.line_edit_password.text ().is_empty ()) {
            return;
        }

        toggle_button_animation (this.ui.confirm_password, this.ui.password_progress_indicator, this.password_protect_link_action);
        this.ui.error_label.hide ();
        /* emit */ create_password (this.ui.line_edit_password.text ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_set ();
    void ShareLinkWidget.on_signal_password_set () {
        toggle_button_animation (this.ui.confirm_password, this.ui.password_progress_indicator, this.password_protect_link_action);

        this.ui.line_edit_password.on_signal_text ({});

        if (this.link_share.is_password_set ()) {
            this.ui.line_edit_password.enabled (true);
            this.ui.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
        } else {
            this.ui.line_edit_password.placeholder_text ({});
        }

        /* emit */ create_password_processed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_error (int code, string message);
    void ShareLinkWidget.on_signal_password_error (int code, string message) {
        toggle_button_animation (this.ui.confirm_password, this.ui.password_progress_indicator, this.password_protect_link_action);

        on_signal_server_error (code, message);
        toggle_password_options ();
        this.ui.line_edit_password.focus ();
        /* emit */ create_password_processed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_note ();
    void ShareLinkWidget.on_signal_create_note () {
        const var note = this.ui.text_edit_note.to_plain_text ();
        if (!this.link_share || this.link_share.note () == note || note.is_empty ()) {
            return;
        }

        toggle_button_animation (this.ui.confirm_note, this.ui.note_progress_indicator, this.note_link_action);
        this.ui.error_label.hide ();
        this.link_share.note (note);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_copy_link_share (bool clicked) {
        //  Q_UNUSED (clicked);

        QApplication.clipboard ().on_signal_text (this.link_share.share_link ().to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date () {
        if (!this.link_share) {
            return;
        }

        toggle_button_animation (this.ui.confirm_expiration_date, this.ui.expiration_date_progress_indicator, this.expiration_date_link_action);
        this.ui.error_label.hide ();
        this.link_share.expire_date (this.ui.calendar.date ());
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date_set () {
        toggle_button_animation (this.ui.confirm_expiration_date, this.ui.expiration_date_progress_indicator, this.expiration_date_link_action);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_context_menu_button_clicked () {
        this.link_context_menu.exec (QCursor.position ());
    }


    /***********************************************************
    There is a painting bug where a small line of this widget
    isn't properly cleared. This explicit repaint () call makes
    sure any trace of the share widget is removed once it's
    destroyed. #4189
    ***********************************************************/
    private void on_signal_delete_animation_finished () {
        connect (
            this,
            GLib.Object.destroyed,
            parent_widget (),
            repaint ()
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_animation_finished () {
        /* emit */ resize_requested ();
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_label () {
        const var label_text = this.share_link_edit.text ();
        if (!this.link_share || this.link_share.label () == label_text || label_text.is_empty ()) {
            return;
        }
        this.share_link_widget_action.checked (true);
        toggle_button_animation (this.share_link_button, this.share_link_progress_indicator, this.share_link_widget_action);
        this.ui.error_label.hide ();
        this.link_share.label (this.share_link_edit.text ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_label_set () {
        toggle_button_animation (this.share_link_button, this.share_link_progress_indicator, this.share_link_widget_action);
        display_share_link_label ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_display_error (string error_message) {
        this.ui.error_label.on_signal_text (error_message);
        this.ui.error_label.show ();
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_password_options (bool enable = true) {
        this.ui.password_label.visible (enable);
        this.ui.line_edit_password.visible (enable);
        this.ui.confirm_password.visible (enable);
        this.ui.line_edit_password.focus ();

        if (!enable && this.link_share && this.link_share.is_password_set ()) {
            this.link_share.password ({});
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_note_options (bool enable = true) {
        this.ui.note_label.visible (enable);
        this.ui.text_edit_note.visible (enable);
        this.ui.confirm_note.visible (enable);
        this.ui.text_edit_note.on_signal_text (enable && this.link_share ? this.link_share.note (): "");

        if (!enable && this.link_share && !this.link_share.note ().is_empty ()) {
            this.link_share.note ({});
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_expire_date_options (bool enable = true) {
        this.ui.expiration_label.visible (enable);
        this.ui.calendar.visible (enable);
        this.ui.confirm_expiration_date.visible (enable);

        const var date = enable ? this.link_share.expire_date () : QDate.current_date ().add_days (1);
        this.ui.calendar.date (date);
        this.ui.calendar.minimum_date (QDate.current_date ().add_days (1));
        this.ui.calendar.maximum_date (
            QDate.current_date ().add_days (this.account.capabilities ().share_public_link_expire_date_days ()));
        this.ui.calendar.focus ();

        if (!enable && this.link_share && this.link_share.expire_date ().is_valid ()) {
            this.link_share.expire_date ({});
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_button_animation (QToolButton button, QProgressIndicator progress_indicator, QAction checked_action) {
        var on_signal_start_animation = false;
        const var action_is_checked = checked_action.is_checked ();
        if (!progress_indicator.is_animated () && action_is_checked) {
            progress_indicator.on_signal_start_animation ();
            on_signal_start_animation = true;
        } else {
            progress_indicator.on_signal_stop_animation ();
        }

        button.visible (!on_signal_start_animation && action_is_checked);
        progress_indicator.visible (on_signal_start_animation && action_is_checked);
    }


    /***********************************************************
    Confirm with the user and then delete the share
    ***********************************************************/
    void confirm_and_delete_share () {
        var message_box = new QMessageBox (
            QMessageBox.Question,
            _("Confirm Link Share Deletion"),
            _("<p>Do you really want to delete the public link share <i>%1</i>?</p>"
            + "<p>Note: This action cannot be undone.</p>")
                .arg (share_name ()),
            QMessageBox.NoButton,
            this);
        QPushButton yes_button =
            message_box.add_button (_("Delete"), QMessageBox.YesRole);
        message_box.add_button (_("Cancel"), QMessageBox.NoRole);

        connect (
            message_box,
            QMessageBox.signal_finished,
            this,
            this.on_message_box_signal_finished);
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_message_box_signal_finished (QMessageBox message_box, Gtk.Button yes_button) {
        if (message_box.clicked_button () == yes_button) {
            this.on_signal_toggle_share_link_animation (true);
            this.link_share.delete_share ();
        }
    }


    /***********************************************************
    Retrieve a share's name, accounting for this.names_supported
    ***********************************************************/
    private static string share_name () {
        string name = this.link_share.name ();
        if (!name.is_empty ()) {
            return name;
        }
        if (!this.names_supported) {
            return _("Public link");
        }
        return this.link_share.token ();
    }


    /***********************************************************
    ***********************************************************/
    void on_signal_start_animation (int start_index, int end) {
        var animation = new QPropertyAnimation (this, "maximum_height", this);

        animation.duration (500);
        animation.start_value (start_index);
        animation.end_value (end);

        connect (animation, QAbstractAnimation.on_signal_finished, this, ShareLinkWidget.on_signal_animation_finished);
        if (end < start_index) // that is to remove the widget, not to show it
            connect (animation, QAbstractAnimation.on_signal_finished, this, ShareLinkWidget.on_signal_delete_animation_finished);
        connect (animation, QVariantAnimation.value_changed, this, ShareLinkWidget.resize_requested);

        animation.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.unshare_link_action.icon (Theme.create_color_aware_icon (":/client/theme/delete.svg"));

        this.add_another_link_action.icon (Theme.create_color_aware_icon (":/client/theme/add.svg"));

        this.ui.enable_share_link.icon (Theme.create_color_aware_icon (":/client/theme/copy.svg"));

        this.ui.share_link_icon_label.pixmap (Theme.create_color_aware_pixmap (":/client/theme/public.svg"));

        this.ui.share_link_tool_button.icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        this.ui.confirm_note.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.ui.confirm_password.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.ui.confirm_expiration_date.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

        this.ui.password_progress_indicator.on_signal_color (QGuiApplication.palette ().color (QPalette.Text));
    }


    /***********************************************************
    ***********************************************************/
    private void display_share_link_label () {
        this.share_link_elided_label.clear ();
        if (!this.link_share.label ().is_empty ()) {
            this.share_link_elided_label.on_signal_text (string (" (%1)").arg (this.link_share.label ()));
        }
    }

} // class ShareLinkWidget

} // namespace Ui
} // namespace Occ
