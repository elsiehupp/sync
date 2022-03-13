/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
The widget displayed for each user/group share
***********************************************************/
class ShareUserLine : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private Ui.ShareUserLine ui;
    private AccountPointer account;

    unowned UserGroupShare share { public get; private set; }

    private bool is_file;

    /***********************************************************
    ***********************************************************/
    private ProfilePageMenu profile_page_menu;

    /***********************************************************
    this.permission_edit is a checkbox
    ***********************************************************/
    private QAction permission_reshare;
    private QAction delete_share_button;
    private QAction permission_create;
    private QAction permission_change;
    private QAction permission_delete;
    private QAction note_link_action;
    private QAction expiration_date_link_action;
    private QAction password_protect_link_action;

    signal void visual_deletion_done ();
    signal void resize_requested ();

    /***********************************************************
    ***********************************************************/
    public ShareUserLine (AccountPointer account,
        UserGroupShare Share,
        SharePermissions max_sharing_permissions,
        bool is_file,
        Gtk.Widget parent = null) {
        base (parent);
        this.ui = new Ui.ShareUserLine ();
        this.account = account;
        this.share = share;
        this.is_file = is_file;
        this.profile_page_menu (account, share.share_with ().share_with ());
        //  Q_ASSERT (this.share);
        this.ui.up_ui (this);

        this.ui.shared_with.elide_mode (Qt.Elide_right);
        this.ui.shared_with.on_signal_text (share.share_with ().to_string ());

        // adds permissions
        // can edit permission
        bool enabled = (max_sharing_permissions & Share_permission_update);
        if (!this.is_file) {
            enabled = enabled && (
                max_sharing_permissions & Share_permission_create
                && max_sharing_permissions & Share_permission_delete);
        }
    
        this.ui.permissions_edit.enabled (enabled);

        connect (
            this.ui.permissions_edit,
            QAbstractButton.clicked,
            this,
            ShareUserLine.on_signal_edit_permissions_changed
        );
        connect (
            this.ui.note_confirm_button,
            QAbstractButton.clicked,
            this,
            ShareUserLine.on_signal_note_confirm_button_clicked
        );
        connect (
            this.ui.calendar,
            QDateTimeEdit.date_changed,
            this,
            ShareUserLine.expire_date
        );
        connect (
            this.share.data (),
            UserGroupShare.signal_note_set,
            this,
            ShareUserLine.disable_progess_indicator_animation
        );
        connect (
            this.share.data (),
            UserGroupShare.signal_note_error,
            this,
            ShareUserLine.disable_progess_indicator_animation
        );
        connect (
            this.share.data (),
            UserGroupShare.signal_expire_date_set,
            this,
            ShareUserLine.disable_progess_indicator_animation
        );
        connect (
            this.ui.confirm_password,
            QToolButton.clicked,
            this,
            ShareUserLine.on_signal_confirm_password_clicked
        );
        connect (
            this.ui.line_edit_password,
            QLineEdit.return_pressed,
            this,
            ShareUserLine.on_signal_line_edit_password_return_pressed
        );

        // create menu with checkable permissions
        var menu = new QMenu (this);
        this.permission_reshare= new QAction (_("Can reshare"), this);
        this.permission_reshare.checkable (true);
        this.permission_reshare.enabled (max_sharing_permissions & Share_permission_share);
        menu.add_action (this.permission_reshare);
        connect (
            this.permission_reshare,
            QAction.triggered,
            this,
            ShareUserLine.on_signal_permissions_changed
        );

        show_note_options (false);

        const bool is_note_supported = this.share.share_type () != Share.Type.Share.Type.EMAIL && this.share.share_type () != Share.Type.Share.Type.ROOM;

        if (is_note_supported) {
            this.note_link_action = new QAction (_("Note to recipient"));
            this.note_link_action.checkable (true);
            menu.add_action (this.note_link_action);
            connect (
                this.note_link_action,
                QAction.triggered,
                this,
                ShareUserLine.toggle_note_options
            );
            if (!this.share.note ().is_empty ()) {
                this.note_link_action.checked (true);
                show_note_options (true);
            }
        }

        show_expire_date_options (false);

        const bool is_expiration_date_supported = this.share.share_type () != Share.Type.Share.Type.EMAIL;

        if (is_expiration_date_supported) {
            // email shares do not support expiration dates
            this.expiration_date_link_action = new QAction (_("Set expiration date"));
            this.expiration_date_link_action.checkable (true);
            menu.add_action (this.expiration_date_link_action);
            connect (
                this.expiration_date_link_action,
                QAction.triggered,
                this,
                ShareUserLine.toggle_expire_date_options
            );
            const var expire_date = this.share.expire_date ().is_valid () ? share.data ().expire_date () : QDate ();
            if (!expire_date.is_null ()) {
                this.expiration_date_link_action.checked (true);
                show_expire_date_options (true, expire_date);
            }
        }

        menu.add_separator ();

        // Adds action to delete share widget
        QIcon delete_icon = QIcon.from_theme (QLatin1String ("user-trash"),QIcon (QLatin1String (":/client/theme/delete.svg")));
        this.delete_share_button= new QAction (delete_icon,_("Unshare"), this);

        menu.add_action (this.delete_share_button);
        connect (
            this.delete_share_button,
            QAction.triggered,
            this,
            ShareUserLine.on_signal_delete_share_button_clicked
        );

        /***********************************************************
        Files can't have create or delete permissions
        ***********************************************************/
        if (!this.is_file) {
            this.permission_create = new QAction (_("Can create"), this);
            this.permission_create.checkable (true);
            this.permission_create.enabled (max_sharing_permissions & Share_permission_create);
            menu.add_action (this.permission_create);
            connect (
                this.permission_create,
                QAction.triggered,
                this,
                ShareUserLine.on_signal_permissions_changed
            );

            this.permission_change = new QAction (_("Can change"), this);
            this.permission_change.checkable (true);
            this.permission_change.enabled (max_sharing_permissions & Share_permission_update);
            menu.add_action (this.permission_change);
            connect (
                this.permission_change,
                QAction.triggered,
                this,
                ShareUserLine.on_signal_permissions_changed
            );

            this.permission_delete = new QAction (_("Can delete"), this);
            this.permission_delete.checkable (true);
            this.permission_delete.enabled (max_sharing_permissions & Share_permission_delete);
            menu.add_action (this.permission_delete);
            connect (
                this.permission_delete,
                QAction.triggered,
                this,
                ShareUserLine.on_signal_permissions_changed
            );
        }

        // Adds action to display password widget (check box)
        if (this.share.share_type () == Share.Type.EMAIL && (this.share.is_password_set () || this.account.capabilities ().share_email_password_enabled ())) {
            this.password_protect_link_action = new QAction (_("Password protect"), this);
            this.password_protect_link_action.checkable (true);
            this.password_protect_link_action.checked (this.share.is_password_set ());
            // checkbox can be checked/unchedkec if the password is not yet set or if it's not enforced
            this.password_protect_link_action.enabled (!this.share.is_password_set () || !this.account.capabilities ().share_email_password_enforced ());

            menu.add_action (this.password_protect_link_action);
            connect (
                this.password_protect_link_action,
                QAction.triggered,
                this,
                ShareUserLine.on_signal_password_checkbox_changed
            );

            on_signal_refresh_password_line_edit_placeholder ();

            connect (
                this.share.data (),
                Share.signal_password_set,
                this,
                ShareUserLine.on_signal_password_set
            );
            connect (
                this.share.data (),
                Share.signal_password_error,
                this,
                ShareUserLine.on_signal_password_error
            );
        }

        on_signal_refresh_password_options ();

        this.ui.error_label.hide ();

        this.ui.permission_tool_button.menu (menu);
        this.ui.permission_tool_button.popup_mode (QToolButton.Instant_popup);

        this.ui.password_progress_indicator.visible (false);

        // Set the permissions checkboxes
        display_permissions ();

        /***********************************************************
        We don't show permission share for federated shares with server <9.1
        https://github.com/owncloud/core/issues/22122#issuecomment-185637344
        https://github.com/owncloud/client/issues/4996
            */
        if (share.share_type () == Share.Type.REMOTE
            && share.account ().server_version_int () < Account.make_server_version (9, 1, 0)) {
            this.permission_reshare.visible (false);
            this.ui.permission_tool_button.visible (false);
        }

        connect (
            share.data (),
            Share.signal_permissions_set,
            this,
            ShareUserLine.on_signal_permissions_set
        );
        connect (
            share.data (),
            Share.signal_share_deleted,
            this,
            ShareUserLine.on_signal_share_deleted
        );

        if (!share.account ().capabilities ().share_resharing ()) {
            this.permission_reshare.visible (false);
        }

        const AvatarEventFilter avatar_event_filter = new AvatarEventFilter (this.ui.avatar);
        connect (
            avatar_event_filter,
            AvatarEventFilter.context_menu,
            this,
            ShareUserLine.on_signal_avatar_context_menu
        );
        this.ui.avatar.install_event_filter (avatar_event_filter);

        load_avatar ();

        customize_style ();
    }



    override ~ShareUserLine () {
        delete this.ui;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_focus_password_line_edit () {
        this.ui.line_edit_password.focus ();
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
            if (this.ui.permissions_edit.is_checked ()) {
                permissions |= Share_permission_update;
            }
        }

        this.share.permissions (permissions);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_edit_permissions_changed () {
        enabled (false);

        // Can never manually be set to "partial".
        // This works because the state cycle for clicking is
        // unchecked . partial . checked . unchecked.
        if (this.ui.permissions_edit.check_state () == Qt.PartiallyChecked) {
            this.ui.permissions_edit.check_state (Qt.Checked);
        }

        Share.Permissions permissions = SharePermissionRead;

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (this.ui.permissions_edit.check_state () == Qt.Checked) {

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

        this.share.permissions (permissions);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_checkbox_changed () {
        if (!this.password_protect_link_action.is_checked ()) {
            this.ui.error_label.hide ();
            this.ui.error_label.clear ();

            if (!this.share.is_password_set ()) {
                this.ui.line_edit_password.clear ();
                on_signal_refresh_password_options ();
            } else {
                // do not call on_signal_refresh_password_options here, as it will be called after the network request is complete
                toggle_password_progress_animation (true);
                this.share.password ("");
            }
        } else {
            on_signal_refresh_password_options ();

            if (this.ui.line_edit_password.is_visible () && this.ui.line_edit_password.is_enabled ()) {
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
        connect (
            this, 
            destroyed (object),
            parent_widget (),
            repaint ()
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_refresh_password_options () {
        const bool is_password_enabled = this.share.share_type () == Share.Type.EMAIL && this.password_protect_link_action.is_checked ();

        this.ui.password_label.visible (is_password_enabled);
        this.ui.line_edit_password.enabled (is_password_enabled);
        this.ui.line_edit_password.visible (is_password_enabled);
        this.ui.confirm_password.visible (is_password_enabled);

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_refresh_password_line_edit_placeholder () {
        if (this.share.is_password_set ()) {
            this.ui.line_edit_password.placeholder_text (string.from_utf8 (PASSWORD_IS_PLACEHOLDER));
        } else {
            this.ui.line_edit_password.placeholder_text ("");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_set () {
        toggle_password_progress_animation (false);
        this.ui.line_edit_password.enabled (true);
        this.ui.confirm_password.enabled (true);

        this.ui.line_edit_password.on_signal_text ("");

        this.password_protect_link_action.enabled (!this.share.is_password_set () || !this.account.capabilities ().share_email_password_enforced ());

        on_signal_refresh_password_line_edit_placeholder ();

        on_signal_refresh_password_options ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_share_deleted () {
        QPropertyAnimation animation = new QPropertyAnimation (this, "maximum_height", this);

        animation.duration (500);
        animation.start_value (height ());
        animation.end_value (0);

        connect (
            animation,
            QAbstractAnimation.on_signal_finished,
            this,
            ShareUserLine.on_signal_delete_animation_finished
        );
        connect (
            animation,
            QVariantAnimation.value_changed,
            this,
            ShareUserLine.resize_requested
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
        if (avatar.is_null ()) {
            return;
        }

        avatar = AvatarJob.make_circular_avatar (avatar);
        this.ui.avatar.pixmap (QPixmap.from_image (avatar));

        // Remove the stylesheet for the fallback avatar
        this.ui.avatar.style_sheet ("");
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_password_confirmed () {
        if (this.ui.line_edit_password.text ().is_empty ()) {
            return;
        }

        this.ui.line_edit_password.enabled (false);
        this.ui.confirm_password.enabled (false);

        this.ui.error_label.hide ();
        this.ui.error_label.clear ();

        toggle_password_progress_animation (true);
        this.share.password (this.ui.line_edit_password.text ());
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
    private void on_signal_avatar_context_menu (QPoint global_position) {
        if (this.share.share_type () == Share.Type.USER) {
            this.profile_page_menu.exec (global_position);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_error (int status_code, string message) {
        GLib.warning ("Error from server " + status_code + message);

        toggle_password_progress_animation (false);

        this.ui.line_edit_password.enabled (true);
        this.ui.confirm_password.enabled (true);

        on_signal_refresh_password_line_edit_placeholder ();

        on_signal_refresh_password_options ();

        on_signal_focus_password_line_edit ();

        this.ui.error_label.show ();
        this.ui.error_label.on_signal_text (message);

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void display_permissions () {
        var perm = this.share.permissions ();

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (perm & Share_permission_update
            && (
                this.is_file || (
                    perm & Share_permission_create && perm & Share_permission_delete)
                )
            ) {
            this.ui.permissions_edit.check_state (Qt.Checked);
        } else if (!this.is_file && perm & (Share_permission_update | Share_permission_create | Share_permission_delete)) {
            this.ui.permissions_edit.check_state (Qt.PartiallyChecked);
        } else if (perm & SharePermissionRead) {
            this.ui.permissions_edit.check_state (Qt.Unchecked);
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
        const int avatar_size = 36;

        // Set size of the placeholder
        this.ui.avatar.minimum_height (avatar_size);
        this.ui.avatar.minimum_width (avatar_size);
        this.ui.avatar.maximum_height (avatar_size);
        this.ui.avatar.maximum_width (avatar_size);
        this.ui.avatar.alignment (Qt.AlignCenter);

        default_avatar (avatar_size);

        /***********************************************************
        Start the network job to fetch the avatar data.

        Currently only regular users can have avatars.
        ***********************************************************/
        if (this.share.share_with ().type () == Sharee.Type.USER) {
            var job = new AvatarJob (this.share.account (), this.share.share_with ().share_with (), avatar_size, this);
            connect (job, AvatarJob.avatar_pixmap, this, ShareUserLine.on_signal_avatar_loaded);
            job.on_signal_start ();
        }
    }


    /***********************************************************
    Create the fallback avatar.

    This will be shown until the avatar image data arrives.
    ***********************************************************/
    private void default_avatar (int avatar_size) {

        // See core/js/placeholder.js for details on colors and styling
        const var background_color = background_color_for_sharee_type (this.share.share_with ().type ());
        const string style = """ (* {
            color : #fff;
            background-color : %1;
            border-radius : %2px;
            text-align : center;
            line-height : %2px;
            font-size : %2px;
        })""".arg (background_color.name (), string.number (avatar_size / 2));
        this.ui.avatar.style_sheet (style);

        const var pixmap = pixmap_for_sharee_type (this.share.share_with ().type (), background_color);

        if (!pixmap.is_null ()) {
            this.ui.avatar.pixmap (pixmap);
        } else {
            GLib.debug ("pixmap is null for share type: " + this.share.share_with ().type ());

            // The avatar label is the first character of the user name.
            this.ui.avatar.on_signal_text (this.share.share_with ().display_name ().at (0).to_upper ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.ui.permission_tool_button.icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        QIcon delete_icon = QIcon.from_theme (
            "user-trash",
            Theme.create_color_aware_icon (":/client/theme/delete.svg")
        );

        this.delete_share_button.icon (delete_icon);

        this.ui.note_confirm_button.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.ui.progress_indicator.on_signal_color (QGuiApplication.palette ().color (QPalette.Window_text));

        // make sure to force Background_role to QPalette.Window_text for a lable, because it's parent always has a different role set that applies to children unless customized
        this.ui.error_label.background_role (QPalette.Window_text);
    }


    /***********************************************************
    ***********************************************************/
    private QPixmap pixmap_for_sharee_type (Sharee.Type type, Gtk.Color background_color) {
        switch (type) {
        case Sharee.Type.ROOM:
            return Ui.IconUtils.pixmap_for_background ("talk-app.svg", background_color);
        case Sharee.Type.EMAIL:
            return Ui.IconUtils.pixmap_for_background ("email.svg", background_color);
        case Sharee.Type.GROUP:
        case Sharee.Type.FEDERATED:
        case Sharee.Type.CIRCLE:
        case Sharee.Type.USER:
            break;
        }

        return new QPixmap ();
    }


    /***********************************************************
    ***********************************************************/
    private void show_note_options (bool show) {
        this.ui.note_label.visible (show);
        this.ui.note_text_edit.visible (show);
        this.ui.note_confirm_button.visible (show);

        if (show) {
            const var note = this.share.note ();
            this.ui.note_text_edit.on_signal_text (note);
            this.ui.note_text_edit.focus ();
        }

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_note_options (bool enable);
    void ShareUserLine.toggle_note_options (bool enable) {
        show_note_options (enable);

        if (!enable) {
            // Delete note
            this.share.note ("");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_note_confirm_button_clicked ();
    void ShareUserLine.on_signal_note_confirm_button_clicked () {
        note (this.ui.note_text_edit.to_plain_text ());
    }


    /***********************************************************
    ***********************************************************/
    private void disable_progess_indicator_animation () {
        enable_progess_indicator_animation (false);
    }


    /***********************************************************
    ***********************************************************/
    private void note (string note) {
        enable_progess_indicator_animation (true);
        this.share.note (note);
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_expire_date_options (bool enable) {
        show_expire_date_options (enable);

        if (!enable) {
            this.share.expire_date (QDate ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void show_expire_date_options (bool show, QDate initial_date = new QDate ()) {
        this.ui.expiration_label.visible (show);
        this.ui.calendar.visible (show);

        if (show) {
            this.ui.calendar.minimum_date (QDate.current_date ().add_days (1));
            this.ui.calendar.date (initial_date.is_valid () ? initial_date : this.ui.calendar.minimum_date ());
            this.ui.calendar.focus ();

            if (enforce_expiration_date_for_share (this.share.share_type ())) {
                this.ui.calendar.maximum_date (max_expiration_date_for_share (this.share.share_type (), this.ui.calendar.maximum_date ()));
                this.expiration_date_link_action.checked (true);
                this.expiration_date_link_action.enabled (false);
            }
        }

        /* emit */ resize_requested ();
    }


    /***********************************************************
    ***********************************************************/
    private void expire_date () {
        enable_progess_indicator_animation (true);
        this.share.expire_date (this.ui.calendar.date ());
    }


    /***********************************************************
    ***********************************************************/
    private void toggle_password_progress_animation (bool show) {
        // button and progress indicator are interchanged depending on if the network request is in progress or not
        this.ui.confirm_password.visible (!show && this.password_protect_link_action.is_checked ());
        this.ui.password_progress_indicator.visible (show);
        if (show) {
            if (!this.ui.password_progress_indicator.is_animated ()) {
                this.ui.password_progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.ui.password_progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void enable_progess_indicator_animation (bool enable) {
        if (enable) {
            if (!this.ui.progress_indicator.is_animated ()) {
                this.ui.progress_indicator.on_signal_start_animation ();
            }
        } else {
            this.ui.progress_indicator.on_signal_stop_animation ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private QDate max_expiration_date_for_share (Share.Type type, QDate fallback_date) {
        var days_to_expire = 0;
        if (type == Share.Type.Share.Type.REMOTE) {
            days_to_expire = this.account.capabilities ().share_remote_expire_date_days ();
        } else if (type == Share.Type.Share.Type.EMAIL) {
           days_to_expire = this.account.capabilities ().share_public_link_expire_date_days ();
        } else {
            days_to_expire = this.account.capabilities ().share_internal_expire_date_days ();
        }

        if (days_to_expire > 0) {
            return QDate.current_date ().add_days (days_to_expire);
        }

        return fallback_date;
    }


    /***********************************************************
    ***********************************************************/
    private bool enforce_expiration_date_for_share (Share.Type type) {
        if (type == Share.Type.Share.Type.REMOTE) {
            return this.account.capabilities ().share_remote_enforce_expire_date ();
        } else if (type == Share.Type.Share.Type.EMAIL) {
            return this.account.capabilities ().share_public_link_enforce_expire_date ();
        }

        return this.account.capabilities ().share_internal_enforce_expire_date ();
    }



    /***********************************************************
    ***********************************************************/
    private Gtk.Color background_color_for_sharee_type (Sharee.Type type) {
        switch (type) {
        case Sharee.Type.ROOM:
            return Theme.instance ().wizard_header_background_color ();
        case Sharee.Type.EMAIL:
            return Theme.instance ().wizard_header_title_color ();
        case Sharee.Type.GROUP:
        case Sharee.Type.FEDERATED:
        case Sharee.Type.CIRCLE:
        case Sharee.Type.USER:
            break;
        }

        return calculate_background_based_on_signal_text ();
    }


    /***********************************************************
    ***********************************************************/
    private void calculate_background_based_on_signal_text () {
        const QCryptographicHash hash = QCryptographicHash.hash (this.ui.shared_with.text ().to_utf8 (), QCryptographicHash.Md5);
        //  Q_ASSERT (hash.size () > 0);
        if (hash.size () == 0) {
            GLib.warning ("Failed to calculate hash color for share: " + this.share.path ());
            return new Gtk.Color ();
        }
        const double hue = (uint8) (hash[0]) / 255.0;
        return Gtk.Color.from_hsl_f (hue, 0.7, 0.68);
    }

} // class ShareUserLine

} // namespace Ui
} // namespace Occ
