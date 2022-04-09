/***********************************************************
@author Roeland Jago Douma <roeland@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
The widget displayed for each user/group share
***********************************************************/
public class ShareUserLine : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private ShareUserLine instance;
    private unowned Account account;

    unowned UserGroupShare share { public get; private set; }

    private bool is_file;

    /***********************************************************
    ***********************************************************/
    private ProfilePageMenu profile_page_menu;

    /***********************************************************
    this.permission_edit is a checkbox
    ***********************************************************/
    private GLib.Action permission_reshare;
    private GLib.Action delete_share_button;
    private GLib.Action permission_create;
    private GLib.Action permission_change;
    private GLib.Action permission_delete;
    private GLib.Action note_link_action;
    private GLib.Action expiration_date_link_action;
    private GLib.Action password_protect_link_action;

    internal signal void visual_deletion_done ();
    internal signal void resize_requested ();

    /***********************************************************
    ***********************************************************/
    public ShareUserLine (unowned Account account,
        UserGroupShare Share,
        SharePermissions max_sharing_permissions,
        bool is_file,
        Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new ShareUserLine ();
        this.account = account;
        this.share = share;
        this.is_file = is_file;
        this.profile_page_menu = new ProfilePageMenu (account, share.share_with.share_with);
        //  Q_ASSERT (this.share);
        this.instance.up_ui (this);

        this.instance.shared_with.elide_mode (GLib.Elide_right);
        this.instance.shared_with.on_signal_text (share.share_with ().to_string ());

        // adds permissions
        // can edit permission
        bool enabled = (max_sharing_permissions & Share_permission_update);
        if (!this.is_file) {
            enabled = enabled && (
                max_sharing_permissions & Share_permission_create
                && max_sharing_permissions & Share_permission_delete);
        }

        this.instance.permissions_edit.enabled (enabled);

        this.instance.permissions_edit.clicked.connect (
            this.on_signal_edit_permissions_changed
        );
        this.instance.note_confirm_button.clicked.connect (
            this.on_signal_note_confirm_button_clicked
        );
        this.instance.calendar.date_changed.connect (
            this.on_signal_expire_date
        );
        this.share.signal_note_set.connect (
            this.disable_progess_indicator_animation
        );
        this.share.signal_note_error.connect (
            this.disable_progess_indicator_animation
        );
        this.share.signal_expire_date_set.connect (
            this.disable_progess_indicator_animation
        );
        this.instance.confirm_password.clicked.connect (
            this.on_signal_confirm_password_clicked
        );
        this.instance.line_edit_password.return_pressed.connect (
            this.on_signal_line_edit_password_return_pressed
        );

        // create menu with checkable permissions
        var menu = new GLib.Menu (this);
        this.permission_reshare= new GLib.Action (_("Can reshare"), this);
        this.permission_reshare.checkable (true);
        this.permission_reshare.enabled (max_sharing_permissions & Share_permission_share);
        menu.add_action (this.permission_reshare);
        this.permission_reshare.triggered.connect (
            this.on_signal_permissions_changed
        );

        show_note_options (false);

        bool is_note_supported = this.share.share_type != Share.Type.Share.Type.EMAIL && this.share.share_type != Share.Type.Share.Type.ROOM;

        if (is_note_supported) {
            this.note_link_action = new GLib.Action (_("Note to recipient"));
            this.note_link_action.checkable (true);
            menu.add_action (this.note_link_action);
            this.note_link_action.triggered.connect (
                this.toggle_note_options
            );
            if (this.share.note != "") {
                this.note_link_action.checked (true);
                show_note_options (true);
            }
        }

        show_expire_date_options (false);

        bool is_expiration_date_supported = this.share.share_type != Share.Type.Share.Type.EMAIL;

        if (is_expiration_date_supported) {
            // email shares do not support expiration dates
            this.expiration_date_link_action = new GLib.Action (_("Set expiration date"));
            this.expiration_date_link_action.checkable (true);
            menu.add_action (this.expiration_date_link_action);
            this.expiration_date_link_action.triggered.connect (
                this.toggle_expire_date_options
            );
            var on_signal_expire_date = this.share.on_signal_expire_date ().is_valid ? share.on_signal_expire_date () : GLib.Date ();
            if (on_signal_expire_date != null) {
                this.expiration_date_link_action.checked (true);
                show_expire_date_options (true, on_signal_expire_date);
            }
        }

        menu.add_separator ();

        // Adds action to delete share widget
        Gtk.Icon delete_icon = Gtk.Icon.from_theme ("user-trash", new Gtk.Icon (":/client/theme/delete.svg"));
        this.delete_share_button= new GLib.Action (delete_icon,_("Unshare"), this);

        menu.add_action (this.delete_share_button);
        this.delete_share_button.triggered.connect (
            this.on_signal_delete_share_button_clicked
        );

        /***********************************************************
        Files can't have create or delete permissions
        ***********************************************************/
        if (!this.is_file) {
            this.permission_create = new GLib.Action (_("Can create"), this);
            this.permission_create.checkable (true);
            this.permission_create.enabled (max_sharing_permissions & Share_permission_create);
            menu.add_action (this.permission_create);
            this.permission_create.triggered.connect (
                this.on_signal_permissions_changed
            );

            this.permission_change = new GLib.Action (_("Can change"), this);
            this.permission_change.checkable (true);
            this.permission_change.enabled (max_sharing_permissions & Share_permission_update);
            menu.add_action (this.permission_change);
            this.permission_change.triggered.connect (
                this.on_signal_permissions_changed
            );

            this.permission_delete = new GLib.Action (_("Can delete"), this);
            this.permission_delete.checkable (true);
            this.permission_delete.enabled (max_sharing_permissions & Share_permission_delete);
            menu.add_action (this.permission_delete);
            this.permission_delete.triggered.connect (
                this.on_signal_permissions_changed
            );
        }

        // Adds action to display password widget (check box)
        if (this.share.share_type == Share.Type.EMAIL && (this.share.password_is_set || this.account.capabilities.share_email_password_enabled ())) {
            this.password_protect_link_action = new GLib.Action (_("Password protect"), this);
            this.password_protect_link_action.checkable (true);
            this.password_protect_link_action.checked (this.share.password_is_set);
            // checkbox can be checked/unchedkec if the password is not yet set or if it's not enforced
            this.password_protect_link_action.enabled (!this.share.password_is_set || !this.account.capabilities.share_email_password_enforced ());

            menu.add_action (this.password_protect_link_action);
            this.password_protect_link_action.triggered.connect (
                this.on_signal_password_checkbox_changed
            );

            on_signal_refresh_password_line_edit_placeholder ();

            this.share.signal_password_set.connect (
                this.on_signal_link_share_password_set
            );
            this.share.signal_password_error.connect (
                this.on_signal_link_share_password_error
            );
        }

        on_signal_refresh_password_options ();

        this.instance.error_label.hide ();

        this.instance.permission_tool_button.menu (menu);
        this.instance.permission_tool_button.popup_mode (GLib.ToolButton.Instant_popup);

        this.instance.password_progress_indicator.visible (false);

        // Set the permissions checkboxes
        display_permissions ();

        /***********************************************************
        We don't show permission share for federated shares with server <9.1
        https://github.com/owncloud/core/issues/22122#issuecomment-185637344
        https://github.com/owncloud/client/issues/4996
            */
        if (share.share_type == Share.Type.REMOTE
            && share.account.server_version_int < Account.make_server_version (9, 1, 0)) {
            this.permission_reshare.visible (false);
            this.instance.permission_tool_button.visible (false);
        }

        share.signal_permissions_set.connect (
            this.on_signal_permissions_set
        );
        share.signal_share_deleted.connect (
            this.on_signal_share_deleted
        );

        if (!share.account.capabilities.share_resharing ()) {
            this.permission_reshare.visible (false);
        }

        AvatarEventFilter avatar_event_filter = new AvatarEventFilter (this.instance.avatar);
        avatar_event_filter.context_menu.connect (
            this.on_signal_avatar_context_menu
        );
        this.instance.avatar.install_event_filter (avatar_event_filter);

        load_avatar ();

        customize_style ();
    }



    override ~ShareUserLine () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_focus_password_line_edit () {
        this.instance.line_edit_password.focus ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_share_button_clicked () {
        enabled (false);
        this.share.delete_share ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_permissions_changed () {
        enabled (false);

        Share.Permissions permissions = SharePermissionRead;

        if (this.permission_reshare.is_checked ())
            permissions |= Share_permission_share;

        if (!this.is_file) {
            if (this.permission_change.is_checked ()) {
                permissions |= Share_permission_update;
            }
            if (this.permission_create.is_checked ()) {
                permissions |= Share_permission_create;
            }
            if (this.permission_delete.is_checked ()) {
                permissions |= Share_permission_delete;
            }
        } else {
            if (this.instance.permissions_edit.is_checked ()) {
                permissions |= Share_permission_update;
            }
        }

        this.share.permissions = permissions;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_edit_permissions_changed () {
        this.enabled = false;

        // Can never manually be set to "partial".
        // This works because the state cycle for clicking is
        // unchecked . partial . checked . unchecked.
        if (this.instance.permissions_edit.check_state () == GLib.PartiallyChecked) {
            this.instance.permissions_edit.check_state (GLib.Checked);
        }

        Share.Permissions permissions = SharePermissionRead;

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (this.instance.permissions_edit.check_state () == GLib.Checked) {

            /***********************************************************
            Files can't have create or delete permisisons
             */
            if (!this.is_file) {
                if (this.permission_change.is_enabled ()) {
                    permissions |= Share_permission_update;
                }
                if (this.permission_create.is_enabled ()) {
                    permissions |= Share_permission_create;
                }
                if (this.permission_delete.is_enabled ()) {
                    permissions |= Share_permission_delete;
                }
            } else {
                permissions |= Share_permission_update;
            }
        }

        if (this.is_file && this.permission_reshare.is_enabled () && this.permission_reshare.is_checked ()) {
            permissions |= Share_permission_share;
        }

        this.share.x;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_checkbox_changed () {
        if (!this.password_protect_link_action.is_checked ()) {
            this.instance.error_label.hide ();
            this.instance.error_label == "";

            if (!this.share.password_is_set) {
                this.instance.line_edit_password == "";
                on_signal_refresh_password_options ();
            } else {
                // do not call on_signal_refresh_password_options here, as it will be called after the network request is complete
                toggle_password_progress_animation (true);
                this.share.password ("");
            }
        } else {
            on_signal_refresh_password_options ();

            if (this.instance.line_edit_password.is_visible () && this.instance.line_edit_password.is_enabled ()) {
                on_signal_focus_password_line_edit ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_animation_finished () {
        /* emit */ resize_requested ();
        /* emit */ visual_deletion_done ();
        delete_later ();

        // There is a painting bug where a small line of this widget isn't
        // properly cleared. This explicit repaint () call makes sure any trace of
        // the share widget is removed once it's destroyed. #4189
        this.destroyed.connect (
            parent_widget ().repaint
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_refresh_password_options () {
        bool is_password_enabled = this.share.share_type == Share.Type.EMAIL && this.password_protect_link_action.is_checked ();

        this.instance.password_label.visible (is_password_enabled);
        this.instance.line_edit_password.enabled (is_password_enabled);
        this.instance.line_edit_password.visible (is_password_enabled);
        this.instance.confirm_password.visible (is_password_enabled);

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_refresh_password_line_edit_placeholder () {
        if (this.share.password_is_set) {
            this.instance.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
        } else {
            this.instance.line_edit_password.placeholder_text ("");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_password_set () {
        toggle_password_progress_animation (false);
        this.instance.line_edit_password.enabled (true);
        this.instance.confirm_password.enabled (true);

        this.instance.line_edit_password.on_signal_text ("");

        this.password_protect_link_action.enabled (!this.share.password_is_set || !this.account.capabilities.share_email_password_enforced ());

        on_signal_refresh_password_line_edit_placeholder ();

        on_signal_refresh_password_options ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_share_deleted () {
        GLib.PropertyAnimation animation = new GLib.PropertyAnimation (this, "maximum_height", this);

        animation.duration (500);
        animation.start_value (height ());
        animation.end_value (0);

        animation.on_signal_finished.connect (
            this.on_signal_delete_animation_finished
        );
        animation.value_changed.connect (
            this.resize_requested
        );

        animation.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_permissions_set () {
        display_permissions ();
        enabled (true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_avatar_loaded (Gtk.Image avatar) {
        if (avatar == null) {
            return;
        }

        avatar = AvatarJob.make_circular_avatar (avatar);
        this.instance.avatar.pixmap (Gdk.Pixbuf.from_image (avatar));

        // Remove the stylesheet for the fallback avatar
        this.instance.avatar.style_sheet ("");
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_password_confirmed () {
        if (this.instance.line_edit_password.text () == "") {
            return;
        }

        this.instance.line_edit_password.enabled (false);
        this.instance.confirm_password.enabled (false);

        this.instance.error_label.hide ();
        this.instance.error_label == "";

        toggle_password_progress_animation (true);
        this.share.password (this.instance.line_edit_password.text ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_line_edit_password_return_pressed () {
        on_signal_password_confirmed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_confirm_password_clicked () {
        on_signal_password_confirmed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_avatar_context_menu (GLib.Point global_position) {
        if (this.share.share_type == Share.Type.USER) {
            this.profile_page_menu.exec (global_position);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_password_error (int status_code, string message) {
        GLib.warning ("Error from server " + status_code.to_string () + message);

        toggle_password_progress_animation (false);

        this.instance.line_edit_password.enabled (true);
        this.instance.confirm_password.enabled (true);

        on_signal_refresh_password_line_edit_placeholder ();

        on_signal_refresh_password_options ();

        on_signal_focus_password_line_edit ();

        this.instance.error_label.show ();
        this.instance.error_label.on_signal_text (message);

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void display_permissions () {
        var perm = this.share.permissions;

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (perm & Share_permission_update
            && (
                this.is_file || (
                    perm & Share_permission_create && perm & Share_permission_delete)
                )
            ) {
            this.instance.permissions_edit.check_state (GLib.Checked);
        } else if (!this.is_file && perm & (Share_permission_update | Share_permission_create | Share_permission_delete)) {
            this.instance.permissions_edit.check_state (GLib.PartiallyChecked);
        } else if (perm & SharePermissionRead) {
            this.instance.permissions_edit.check_state (GLib.Unchecked);
        }

        // Edit is independent of reshare
        if (perm & Share_permission_share) {
            this.permission_reshare.checked (true);
        }

        if (!this.is_file) {
            this.permission_create.checked (perm & Share_permission_create);
            this.permission_change.checked (perm & Share_permission_update);
            this.permission_delete.checked (perm & Share_permission_delete);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void load_avatar () {
        int avatar_size = 36;

        // Set size of the placeholder
        this.instance.avatar.minimum_height (avatar_size);
        this.instance.avatar.minimum_width (avatar_size);
        this.instance.avatar.maximum_height (avatar_size);
        this.instance.avatar.maximum_width (avatar_size);
        this.instance.avatar.alignment (GLib.AlignCenter);

        default_avatar (avatar_size);

        /***********************************************************
        Start the network job to fetch the avatar data.

        Currently only regular users can have avatars.
        ***********************************************************/
        if (this.share.share_with.type == Sharee.Type.USER) {
            AvatarJob avatar_line = new AvatarJob (
                this.share.account,
                this.share.share_with.share_with,
                avatar_size,
                this
            );
            avatar_line.avatar_pixmap.connect (
                this.on_signal_avatar_loaded
            );
            avatar_line.on_signal_start ();
        }
    }


    /***********************************************************
    Create the fallback avatar.

    This will be shown until the avatar image data arrives.
    ***********************************************************/
    private void default_avatar (int avatar_size) {

        // See core/js/placeholder.js for details on colors and styling
        var background_color = background_color_for_sharee_type (this.share.share_with ().type ());
        string style = """ (* {
            color : #fff;
            background-color : %1;
            border-radius : %2px;
            text-align : center;
            line-height : %2px;
            font-size : %2px;
        })""".printf (background_color.name (), string.number (avatar_size / 2));
        this.instance.avatar.style_sheet (style);

        var pixmap = pixmap_for_sharee_type (this.share.share_with ().type (), background_color);

        if (!pixmap == null) {
            this.instance.avatar.pixmap (pixmap);
        } else {
            GLib.debug ("pixmap is null for share type: " + this.share.share_with.type);

            // The avatar label is the first character of the user name.
            this.instance.avatar.on_signal_text (this.share.share_with ().display_name.at (0).to_upper ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.instance.permission_tool_button.icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        Gtk.Icon delete_icon = Gtk.Icon.from_theme (
            "user-trash",
            Theme.create_color_aware_icon (":/client/theme/delete.svg")
        );

        this.delete_share_button.icon (delete_icon);

        this.instance.note_confirm_button.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.instance.progress_indicator.on_signal_color (GLib.Application.palette ().color (Gtk.Palette.Window_text));

        // make sure to force Background_role to Gtk.Palette.Window_text for a lable, because it's parent always has a different role set that applies to children unless customized
        this.instance.error_label.background_role (Gtk.Palette.Window_text);
    }


    /***********************************************************
    ***********************************************************/
    private Gdk.Pixbuf pixmap_for_sharee_type (Sharee.Type type, Gdk.RGBA background_color) {
        switch (type) {
        case Sharee.Type.ROOM:
            return IconUtils.pixmap_for_background ("talk-app.svg", background_color);
        case Sharee.Type.EMAIL:
            return IconUtils.pixmap_for_background ("email.svg", background_color);
        case Sharee.Type.GROUP:
        case Sharee.Type.FEDERATED:
        case Sharee.Type.CIRCLE:
        case Sharee.Type.USER:
            break;
        }

        return new Gdk.Pixbuf ();
    }


    /***********************************************************
    ***********************************************************/
    private void show_note_options (bool show) {
        this.instance.note_label.visible (show);
        this.instance.note_text_edit.visible (show);
        this.instance.note_confirm_button.visible (show);

        if (show) {
            var note = this.share.note;
            this.instance.note_text_edit.on_signal_text (note);
            this.instance.note_text_edit.focus ();
        }

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_note_options (bool enable) {
        show_note_options (enable);

        if (!enable) {
            // Delete note
            this.share.note = "";
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_note_confirm_button_clicked () {
        this.note = this.instance.note_text_edit.to_plain_text ();
    }


    /***********************************************************
    ***********************************************************/
    private void disable_progess_indicator_animation () {
        this.enable_progess_indicator_animation false;
    }


    /***********************************************************
    ***********************************************************/
    private string note {
        private set {
            this.enable_progess_indicator_animation = true;
            this.share.note = value;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_expire_date_options (bool enable) {
        show_expire_date_options (enable);

        if (!enable) {
            this.share.on_signal_expire_date (GLib.Date ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void show_expire_date_options (bool show, GLib.Date initial_date = new GLib.Date ()) {
        this.instance.expiration_label.visible (show);
        this.instance.calendar.visible (show);

        if (show) {
            this.instance.calendar.minimum_date (GLib.Date.current_date ().add_days (1));
            this.instance.calendar.date (initial_date.is_valid ? initial_date : this.instance.calendar.minimum_date ());
            this.instance.calendar.focus ();

            if (enforce_expiration_date_for_share (this.share.share_type)) {
                this.instance.calendar.maximum_date (max_expiration_date_for_share (this.share.share_type, this.instance.calendar.maximum_date ()));
                this.expiration_date_link_action.checked (true);
                this.expiration_date_link_action.enabled (false);
            }
        }

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date () {
        enable_progess_indicator_animation (true);
        this.share.on_signal_expire_date (this.instance.calendar.date ());
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_password_progress_animation (bool show) {
        // button and progress indicator are interchanged depending on if the network request is in progress or not
        this.instance.confirm_password.visible (!show && this.password_protect_link_action.is_checked ());
        this.instance.password_progress_indicator.visible (show);
        if (show) {
            if (!this.instance.password_progress_indicator.is_animated ()) {
                this.instance.password_progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.instance.password_progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void enable_progess_indicator_animation (bool enable) {
        if (enable) {
            if (!this.instance.progress_indicator.is_animated ()) {
                this.instance.progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.instance.progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Date max_expiration_date_for_share (Share.Type type, GLib.Date fallback_date) {
        var days_to_expire = 0;
        if (type == Share.Type.Share.Type.REMOTE) {
            days_to_expire = this.account.capabilities.share_remote_expire_date_days ();
        } else if (type == Share.Type.Share.Type.EMAIL) {
           days_to_expire = this.account.capabilities.share_public_link_expire_date_days ();
        } else {
            days_to_expire = this.account.capabilities.share_internal_expire_date_days ();
        }

        if (days_to_expire > 0) {
            return GLib.Date.current_date ().add_days (days_to_expire);
        }

        return fallback_date;
    }


    /***********************************************************
    ***********************************************************/
    private bool enforce_expiration_date_for_share (Share.Type type) {
        if (type == Share.Type.Share.Type.REMOTE) {
            return this.account.capabilities.share_remote_enforce_expire_date ();
        } else if (type == Share.Type.Share.Type.EMAIL) {
            return this.account.capabilities.share_public_link_enforce_expire_date ();
        }

        return this.account.capabilities.share_internal_enforce_expire_date ();
    }



    /***********************************************************
    ***********************************************************/
    private Gdk.RGBA background_color_for_sharee_type (Sharee.Type type) {
        switch (type) {
        case Sharee.Type.ROOM:
            return Theme.wizard_header_background_color;
        case Sharee.Type.EMAIL:
            return Theme.wizard_header_title_color;
        case Sharee.Type.GROUP:
        case Sharee.Type.FEDERATED:
        case Sharee.Type.CIRCLE:
        case Sharee.Type.USER:
            break;
        }

        calculate_background_based_on_signal_text ();
        return;
    }


    /***********************************************************
    ***********************************************************/
    private void calculate_background_based_on_signal_text () {
        GLib.CryptographicHash hash = GLib.CryptographicHash.hash (this.instance.shared_with.text ().to_utf8 (), GLib.ChecksumType.MD5);
        //  Q_ASSERT (hash.size () > 0);
        if (hash.size () == 0) {
            GLib.warning ("Failed to calculate hash color for share: " + this.share.path);
            return Gdk.RGBA ();
        }
        double hue = (uint8) (hash[0]) / 255.0;
        return Gdk.RGBA.from_hsl_f (hue, 0.7, 0.68);
    }

} // class ShareUserLine

} // namespace Ui
} // namespace Occ
