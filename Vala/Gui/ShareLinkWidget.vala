/***********************************************************
@author Roeland Jago Douma <roeland@famdouma.nl>
@author 2015 by Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.OutputStream>
//  #include <GLib.Clipboard>
//  #include <GLib.FileInfo>
//  #include <GLib.DesktopServices>
//  #include <Gtk.MessageBox>
//  #include <GLib.Menu>
//  #include <GLib.Text_edit>
//  #include <GLib.ToolButton>
//  #include <GLib.PropertyAnimation>
//  #include <Gtk.Dialog
//  #include <GLib.ToolBu
//  #include <GLib.HBox_layo
//  #include <GLib.LineEdit>
//  #include <GLib.WidgetAction>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ShareDialog class
@ingroup gui
***********************************************************/
public class ShareLinkWidget : Gtk.Widget {

    private const string PASSWORD_IS_PLACEHOLDER = "●●●●●●●●";

    private ShareLinkWidget instance;
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

    private GLib.Menu link_context_menu;
    private GLib.Action read_only_link_action;
    private GLib.Action allow_editing_link_action;
    private GLib.Action allow_upload_editing_link_action;
    private GLib.Action allow_upload_link_action;
    private GLib.Action password_protect_link_action;
    private GLib.Action expiration_date_link_action;
    private GLib.Action unshare_link_action;
    private GLib.Action add_another_link_action;
    private GLib.Action note_link_action;
    private GLib.HBoxLayout share_link_layout = new GLib.HBoxLayout ();
    private Gtk.Label share_link_label = new Gtk.Label ();
    private ElidedLabel share_link_elided_label = new ElidedLabel ();
    private GLib.LineEdit share_link_edit = new GLib.LineEdit ();
    private GLib.ToolButton share_link_button = new GLib.ToolButton ();
    private GLib.ProgressIndicator share_link_progress_indicator = new GLib.ProgressIndicator ();
    private Gtk.Widget share_link_default_widget = new Gtk.Widget ();
    private GLib.WidgetAction share_link_widget_action = new GLib.WidgetAction ();


    internal signal void create_link_share ();
    internal signal void delete_link_share ();
    internal signal void signal_resize_requested ();
    internal signal void visual_deletion_done ();
    internal signal void create_password (string password);
    internal signal void create_password_processed ();


    /***********************************************************
    ***********************************************************/
    public ShareLinkWidget (
        unowned Account account,
        string share_path,
        string local_path,
        SharePermissions max_sharing_permissions,
        Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new ShareLinkWidget ();
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
        this.instance.up_ui (this);

        this.instance.share_link_tool_button.hide ();

        //Is this a file or folder?
        GLib.FileInfo file_info = new GLib.FileInfo (local_path);
        this.is_file = file_info.is_file ();

        this.instance.enable_share_link.clicked.connect (
            this.on_signal_create_share_link
        );
        this.instance.line_edit_password.return_pressed.connect (
            this.on_signal_create_password
        );
        this.instance.confirm_password.clicked.connect (
            this.on_signal_create_password
        );
        this.instance.confirm_note.clicked.connect (
            this.on_signal_create_note
        );
        this.instance.confirm_expiration_date.clicked.connect (
            this.on_signal_expire_date
        );

        this.instance.error_label.hide ();

        var sharing_possible = true;
        if (!this.account.capabilities.share_public_link ()) {
            GLib.warning ("Link shares have been disabled.");
            sharing_possible = false;
        } else if (! (max_sharing_permissions & Share_permission_share)) {
            GLib.warning ("The file can not be shared because it was shared without sharing permission.");
            sharing_possible = false;
        }

        this.instance.enable_share_link.checked (false);
        this.instance.share_link_tool_button.enabled (false);
        this.instance.share_link_tool_button.hide ();

        // Older servers don't support multiple public link shares
        if (!this.account.capabilities.share_public_link_multiple ()) {
            this.names_supported = false;
        }

        toggle_password_options (false);
        toggle_expire_date_options (false);
        toggle_note_options (false);

        this.instance.note_progress_indicator.visible (false);
        this.instance.password_progress_indicator.visible (false);
        this.instance.expiration_date_progress_indicator.visible (false);
        this.instance.sharelink_progress_indicator.visible (false);

        // check if the file is already inside of a synced folder
        if (share_path == "") {
            GLib.warning ("Unable to share files not in a sync folder.");
            return;
        }
    }


    override ~ShareLinkWidget () {
        //  delete this.instance;
    }

    /***********************************************************
    ***********************************************************/
    public void toggle_button (bool show);


    /***********************************************************
    ***********************************************************/
    public void set_up_ui_options () {
        this.link_share.signal_note_set.connect (
            this.on_signal_link_share_note_set
        );
        this.link_share.signal_password_set.connect (
            this.on_signal_link_share_password_set
        );
        this.link_share.signal_password_error.connect (
            this.on_signal_link_share_password_error
        );
        this.link_share.signal_label_set.connect (
            this.on_signal_link_share_label_set
        );

        // Prepare permissions check and create group action
        GLib.Date expire_date;
        if (this.link_share.expire_date.is_valid) {
            expire_date = this.link_share.expire_date;
        } else {
            expire_date = GLib.Date ();
        }
        SharePermissions share_permissions = this.link_share.permissions;
        var checked = false;
        var permissions_group = new GLib.ActionGroup (this);

        // Prepare sharing menu
        this.link_context_menu = new GLib.Menu (this);

        // radio button style
        permissions_group.exclusive (true);

        if (this.is_file) {
            checked = (share_permissions & SharePermissionRead) && (share_permissions & Share_permission_update);
            this.allow_editing_link_action = this.link_context_menu.add_action (_("Allow editing"));
            this.allow_editing_link_action.checkable (true);
            this.allow_editing_link_action.checked (checked);

        } else {
            checked = (share_permissions == SharePermissionRead);
            this.read_only_link_action = permissions_group.add_action (_("View only"));
            this.read_only_link_action.checkable (true);
            this.read_only_link_action.checked (checked);

            checked = (share_permissions & SharePermissionRead) && (share_permissions & Share_permission_create)
                && (share_permissions & Share_permission_update) && (share_permissions & Share_permission_delete);
            this.allow_upload_editing_link_action = permissions_group.add_action (_("Allow upload and editing"));
            this.allow_upload_editing_link_action.checkable (true);
            this.allow_upload_editing_link_action.checked (checked);

            checked = (share_permissions == Share_permission_create);
            this.allow_upload_link_action = permissions_group.add_action (_("File drop (upload only)"));
            this.allow_upload_link_action.checkable (true);
            this.allow_upload_link_action.checked (checked);
        }

        this.share_link_elided_label = new ElidedLabel (this);
        this.share_link_elided_label.elide_mode (GLib.Elide_right);
        display_share_link_label ();
        this.instance.horizontal_layout.insert_widget (2, this.share_link_elided_label);

        this.share_link_layout = new GLib.HBoxLayout (this);

        this.share_link_label = new Gtk.Label (this);
        this.share_link_label.pixmap (":/client/theme/black/edit.svg");
        this.share_link_layout.add_widget (this.share_link_label);

        this.share_link_edit = new GLib.LineEdit (this);
        this.share_link_edit.return_pressed.connect (
            this.on_signal_create_label
        );
        this.share_link_edit.placeholder_text (_("Link name"));
        this.share_link_edit.on_signal_text (this.link_share.label);
        this.share_link_layout.add_widget (this.share_link_edit);

        this.share_link_button = new GLib.ToolButton (this);
        this.share_link_button.clicked.connect (
            this.on_signal_create_label
        );
        this.share_link_button.icon (Gtk.Icon (":/client/theme/confirm.svg"));
        this.share_link_button.tool_button_style (GLib.Tool_button_icon_only);
        this.share_link_layout.add_widget (this.share_link_button);

        this.share_link_progress_indicator = new GLib.ProgressIndicator (this);
        this.share_link_progress_indicator.visible (false);
        this.share_link_layout.add_widget (this.share_link_progress_indicator);

        this.share_link_default_widget = new Gtk.Widget (this);
        this.share_link_default_widget.layout (this.share_link_layout);

        this.share_link_widget_action = new GLib.WidgetAction (this);
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

        if (this.link_share.note.is_simple_text () && this.link_share.note != "") {
            this.instance.text_edit_note.on_signal_text (this.link_share.note);
            this.note_link_action.checked (true);
            toggle_note_options ();
        }

        // Adds action to display password widget (check box)
        this.password_protect_link_action = this.link_context_menu.add_action (_("Password protect"));
        this.password_protect_link_action.checkable (true);

        if (this.link_share.password_is_set) {
            this.password_protect_link_action.checked (true);
            this.instance.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
            toggle_password_options ();
        }

        // If password is enforced then don't allow users to disable it
        if (this.account.capabilities.share_public_link_enforce_password ()) {
            if (this.link_share.password_is_set) {
                this.password_protect_link_action.checked (true);
                this.password_protect_link_action.enabled = false;
            }
            this.password_required = true;
        }

        // Adds action to display expiration date widget (check box)
        this.expiration_date_link_action = this.link_context_menu.add_action (_("Set expiration date"));
        this.expiration_date_link_action.checkable (true);
        if (!expire_date == null) {
            this.instance.calendar.date (expire_date);
            this.expiration_date_link_action.checked (true);
            toggle_expire_date_options ();
        }
        this.instance.calendar.date_changed.connect (
            this.on_signal_expire_date
        );
        this.link_share.signal_expire_date_set.connect (
            this.on_signal_expire_date_set
        );

        // If expiredate is enforced do not allow disable and set max days
        if (this.account.capabilities.share_public_link_enforce_expire_date ()) {
            this.instance.calendar.maximum_date (GLib.Date.current_date ().add_days (
                this.account.capabilities.share_public_link_expire_date_days ()));
            this.expiration_date_link_action.checked (true);
            this.expiration_date_link_action.enabled = false;
            this.expiry_required = true;
        }

        // Adds action to unshare widget (check box)
        this.unshare_link_action = this.link_context_menu.add_action (Gtk.Icon (":/client/theme/delete.svg"),
            _("Delete link"));

        this.link_context_menu.add_separator ();

        this.add_another_link_action = this.link_context_menu.add_action (Gtk.Icon (":/client/theme/add.svg"),
            _("Add another link"));

        this.instance.enable_share_link.icon (Gtk.Icon (":/client/theme/copy.svg"));
        this.instance.enable_share_link.clicked.disconnect (
            this.on_signal_create_share_link
        );
        this.instance.enable_share_link.clicked.connect (
            this.on_signal_copy_link_share
        );
        this.link_context_menu.triggered.connect (
            this.on_signal_link_context_menu_action_triggered
        );

        this.instance.share_link_tool_button.menu (this.link_context_menu);
        this.instance.share_link_tool_button.enabled (true);
        this.instance.enable_share_link.enabled (true);
        this.instance.enable_share_link.checked (true);

        // show sharing options
        this.instance.share_link_tool_button.show ();

        customize_style ();
    }



    /***********************************************************
    ***********************************************************/
    public void on_signal_toggle_share_link_animation (bool on_signal_start) {
        this.instance.sharelink_progress_indicator.visible (on_signal_start);
        if (on_signal_start) {
            if (!this.instance.sharelink_progress_indicator.is_animated ()) {
                this.instance.sharelink_progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.instance.sharelink_progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_focus_password_line_edit () {
        this.instance.line_edit_password.focus ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_delete_share_fetched () {
        on_signal_toggle_share_link_animation (false);

        this.link_share = null;
        toggle_password_options (false);
        toggle_note_options (false);
        toggle_expire_date_options (false);
        /* emit */ delete_link_share ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_link_share_note_set () {
        toggle_button_animation (this.instance.confirm_note, this.instance.note_progress_indicator, this.note_link_action);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_link_context_menu_action_triggered (GLib.Action action) {
        var state = action.is_checked ();
        SharePermissions share_permissions = SharePermissionRead;

        if (action == this.add_another_link_action) {
            /* emit */ create_link_share ();

        } else if (action == this.read_only_link_action && state) {
            this.link_share.permissions = share_permissions;

        } else if (action == this.allow_editing_link_action && state) {
            share_permissions |= Share_permission_update;
            this.link_share.permissions = share_permissions;

        } else if (action == this.allow_upload_editing_link_action && state) {
            share_permissions |= Share_permission_create | Share_permission_update | Share_permission_delete;
            this.link_share.permissions = share_permissions;

        } else if (action == this.allow_upload_link_action && state) {
            share_permissions = Share_permission_create;
            this.link_share.permissions = share_permissions;

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
    public void on_signal_server_error (int code, string message) {
        on_signal_toggle_share_link_animation (false);

        GLib.warning ("Error from server " + code.to_string () + message);
        on_signal_display_error (message);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_create_share_requires_password (string message) {
        on_signal_toggle_share_link_animation (message == "");

        if (message != "") {
            this.instance.error_label.on_signal_text (message);
            this.instance.error_label.show ();
        }

        this.password_required = true;

        toggle_password_options ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_share_link (bool clicked) {
        //  Q_UNUSED (clicked);
        on_signal_toggle_share_link_animation (true);
        /* emit */ create_link_share ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_password () {
        if (this.link_share == null || this.instance.line_edit_password.text () == "") {
            return;
        }

        toggle_button_animation (this.instance.confirm_password, this.instance.password_progress_indicator, this.password_protect_link_action);
        this.instance.error_label.hide ();
        /* emit */ create_password (this.instance.line_edit_password.text ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_password_set () {
        toggle_button_animation (this.instance.confirm_password, this.instance.password_progress_indicator, this.password_protect_link_action);

        this.instance.line_edit_password.on_signal_text ({});

        if (this.link_share.password_is_set) {
            this.instance.line_edit_password.enabled (true);
            this.instance.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
        } else {
            this.instance.line_edit_password.placeholder_text ({});
        }

        /* emit */ create_password_processed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_password_error (int code, string message) {
        toggle_button_animation (this.instance.confirm_password, this.instance.password_progress_indicator, this.password_protect_link_action);

        on_signal_server_error (code, message);
        toggle_password_options ();
        this.instance.line_edit_password.focus ();
        /* emit */ create_password_processed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_note () {
        var note = this.instance.text_edit_note.to_plain_text ();
        if (this.link_share == null || this.link_share.note == note || note == "") {
            return;
        }

        toggle_button_animation (this.instance.confirm_note, this.instance.note_progress_indicator, this.note_link_action);
        this.instance.error_label.hide ();
        this.link_share.note = note;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_copy_link_share (bool clicked) {
        //  Q_UNUSED (clicked);

        GLib.Application.clipboard ().on_signal_text (this.link_share.share_link ().to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date () {
        if (this.link_share == null) {
            return;
        }

        toggle_button_animation (this.instance.confirm_expiration_date, this.instance.expiration_date_progress_indicator, this.expiration_date_link_action);
        this.instance.error_label.hide ();
        this.link_share.expire_date = this.instance.calendar.date;
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date_set () {
        toggle_button_animation (this.instance.confirm_expiration_date, this.instance.expiration_date_progress_indicator, this.expiration_date_link_action);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_context_menu_button_clicked () {
        this.link_context_menu.exec (GLib.Cursor.position ());
    }


    /***********************************************************
    There is a painting bug where a small line of this widget
    isn't properly cleared. This explicit repaint () call makes
    sure any trace of the share widget is removed once it's
    destroyed. #4189
    ***********************************************************/
    private void on_signal_delete_animation_finished () {
        this.destroyed.connect (
            parent_widget ().repaint
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_animation_finished () {
        /* emit */ on_signal_resize_requested ();
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_label () {
        string label_text = this.share_link_edit.text ();
        if (this.link_share == null || this.link_share.label == label_text || label_text == "") {
            return;
        }
        this.share_link_widget_action.checked (true);
        toggle_button_animation (this.share_link_button, this.share_link_progress_indicator, this.share_link_widget_action);
        this.instance.error_label.hide ();
        this.link_share.label = this.share_link_edit.text ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_label_set () {
        toggle_button_animation (this.share_link_button, this.share_link_progress_indicator, this.share_link_widget_action);
        display_share_link_label ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_display_error (string error_message) {
        this.instance.error_label.on_signal_text (error_message);
        this.instance.error_label.show ();
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_password_options (bool enable = true) {
        this.instance.password_label.visible (enable);
        this.instance.line_edit_password.visible (enable);
        this.instance.confirm_password.visible (enable);
        this.instance.line_edit_password.focus ();

        if (!enable && this.link_share && this.link_share.password_is_set) {
            this.link_share.password ({});
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_note_options (bool enable = true) {
        this.instance.note_label.visible (enable);
        this.instance.text_edit_note.visible (enable);
        this.instance.confirm_note.visible (enable);
        this.instance.text_edit_note.on_signal_text (enable && this.link_share ? this.link_share.note: "");

        if (!enable && this.link_share != null && this.link_share.note != "") {
            this.link_share.note = "";
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_expire_date_options (bool enable = true) {
        this.instance.expiration_label.visible (enable);
        this.instance.calendar.visible (enable);
        this.instance.confirm_expiration_date.visible (enable);

        var date = enable ? this.link_share.expire_date : GLib.Date.current_date ().add_days (1);
        this.instance.calendar.date (date);
        this.instance.calendar.minimum_date (GLib.Date.current_date ().add_days (1));
        this.instance.calendar.maximum_date (
            GLib.Date.current_date ().add_days (this.account.capabilities.share_public_link_expire_date_days ()));
        this.instance.calendar.focus ();

        if (!enable && this.link_share && this.link_share.expire_date.is_valid) {
            this.link_share.expire_date = {};
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_button_animation (GLib.ToolButton button, GLib.ProgressIndicator progress_indicator, GLib.Action checked_action) {
        var on_signal_start_animation = false;
        var action_is_checked = checked_action.is_checked ();
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
        var message_box = new Gtk.MessageBox (
            Gtk.MessageBox.Question,
            _("Confirm Link Share Deletion"),
            _("<p>Do you really want to delete the public link share <i>%1</i>?</p>"
            + "<p>Note: This action cannot be undone.</p>")
                .printf (share_name),
            Gtk.MessageBox.NoButton,
            this);
        GLib.PushButton yes_button =
            message_box.add_button (_("Delete"), Gtk.MessageBox.YesRole);
        message_box.add_button (_("Cancel"), Gtk.MessageBox.NoRole);

        message_box.signal_finished.connect (
            this.on_message_box_signal_finished
        );
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_message_box_signal_finished (Gtk.MessageBox message_box, Gtk.Button yes_button) {
        if (message_box.clicked_button () == yes_button) {
            this.on_signal_toggle_share_link_animation (true);
            this.link_share.delete_share ();
        }
    }


    /***********************************************************
    Retrieve a share's name, accounting for this.names_supported
    ***********************************************************/
    private string share_name {
        private get {
            string name = this.link_share.name;
            if (!name == "") {
                return name;
            }
            if (!ShareLinkWidget.names_supported) {
                return _("Public link");
            }
            return this.link_share.token;
        }
    }


    /***********************************************************
    ***********************************************************/
    void on_signal_start_animation (int start_index, int end) {
        var maximum_height_animation = new GLib.PropertyAnimation (this, "maximum_height", this);

        maximum_height_animation.duration (500);
        maximum_height_animation.start_value (start_index);
        maximum_height_animation.end_value (end);

        maximum_height_animation.signal_finished.connect (
            this.on_signal_animation_finished
        );
        if (end < start_index) { // that is to remove the widget, not to show it
            maximum_height_animation.signal_finished.connect (
                this.on_signal_delete_animation_finished
            );
        }
        maximum_height_animation.value_changed.connect (
            this.on_signal_resize_requested
        );

        maximum_height_animation.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.unshare_link_action.icon (Theme.create_color_aware_icon (":/client/theme/delete.svg"));

        this.add_another_link_action.icon (Theme.create_color_aware_icon (":/client/theme/add.svg"));

        this.instance.enable_share_link.icon (Theme.create_color_aware_icon (":/client/theme/copy.svg"));

        this.instance.share_link_icon_label.pixmap (Theme.create_color_aware_pixmap (":/client/theme/public.svg"));

        this.instance.share_link_tool_button.icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        this.instance.confirm_note.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.instance.confirm_password.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.instance.confirm_expiration_date.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

        this.instance.password_progress_indicator.on_signal_color (GLib.Application.palette ().color (Gtk.Palette.Text));
    }


    /***********************************************************
    ***********************************************************/
    private void display_share_link_label () {
        this.share_link_elided_label = "";
        if (this.link_share.label != "") {
            this.share_link_elided_label.on_signal_text (" (%1)".printf (this.link_share.label));
        }
    }

} // class ShareLinkWidget

} // namespace Ui
} // namespace Occ
