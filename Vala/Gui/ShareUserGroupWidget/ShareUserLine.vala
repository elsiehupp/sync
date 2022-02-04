/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
The widget displayed for each user/group share
***********************************************************/
class Share_user_line : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public Share_user_line (AccountPointer account,
        unowned<User_group_share> Share,
        Share_permissions max_sharing_permissions,
        bool is_file,
        Gtk.Widget parent = null);
    ~Share_user_line () override;

    /***********************************************************
    ***********************************************************/
    public unowned<Share> share ();

signals:
    void visual_deletion_done ();
    void resize_requested ();

    /***********************************************************
    ***********************************************************/
    public void on_style_changed ();

    /***********************************************************
    ***********************************************************/
    public void on_focus_password_line_edit ();


    /***********************************************************
    ***********************************************************/
    private void on_delete_share_button_clicked ();
    private void on_permissions_changed ();
    private void on_edit_permissions_changed ();
    private void on_password_checkbox_changed ();
    private void on_delete_animation_finished ();

    /***********************************************************
    ***********************************************************/
    private void on_refresh_password_options ();

    /***********************************************************
    ***********************************************************/
    private void on_refresh_password_line_edit_placeholder ();

    /***********************************************************
    ***********************************************************/
    private void on_password_set ();

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private void on_permissions_set ();

    /***********************************************************
    ***********************************************************/
    private void on_avatar_loaded (QImage avat

    /***********************************************************
    ***********************************************************/
    private void on_set_password_confirmed ();

    /***********************************************************
    ***********************************************************/
    private void on_line_edit_password_return_pr

    /***********************************************************
    ***********************************************************/
    private void on_confirm_password_clicked ();

    /***********************************************************
    ***********************************************************/
    private void on_avatar_context_menu (QPoint global_position);


    /***********************************************************
    ***********************************************************/
    private void display_permissions ();
    private void load_avatar ();
    private void set_default_avatar (int avatar_size);
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private QPixmap pixmap_for_sharee_type (Sharee.Type type, Gtk.Color background_color = Gtk.Color ());

    /***********************************************************
    ***********************************************************/
    private 
    private void show_note_options (bool show);
    private void toggle_note_options (bool enable);
    private void on_note_confirm_button_clicked ();
    private void set_note (string note);

    /***********************************************************
    ***********************************************************/
    private void toggle_expire_date_options (bool enable);
    private void show_expire_date_options (bool show, QDate initial_date = QDate ());
    private void set_expire_date ();

    /***********************************************************
    ***********************************************************/
    private void toggle_password_set_progress_animation (bool show);

    /***********************************************************
    ***********************************************************/
    private void enable_progess_indicator_animation (bool enable);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private bool enforce_expiration_date_for_share (Share.Share_type type);

    /***********************************************************
    ***********************************************************/
    private Ui.Share_user_line this.ui;
    private AccountPointer this.account;
    private unowned<User_group_share> this.share;
    private bool this.is_file;

    /***********************************************************
    ***********************************************************/
    private Profile_page_menu this.profile_page_menu;

    // this.permission_edit is a checkbox
    private QAction this.permission_reshare;
    private QAction this.delete_share_button;
    private QAction this.permission_create;
    private QAction this.permission_change;
    private QAction this.permission_delete;
    private QAction this.note_link_action;
    private QAction this.expiration_date_link_action;
    private QAction this.password_protect_link_action;
}




    Share_user_line.Share_user_line (AccountPointer account, unowned<User_group_share> share,
        Share_permissions max_sharing_permissions, bool is_file, Gtk.Widget parent)
        : Gtk.Widget (parent)
        this.ui (new Ui.Share_user_line)
        this.account (account)
        this.share (share)
        this.is_file (is_file)
        this.profile_page_menu (account, share.get_share_with ().share_with ()) {
        //  Q_ASSERT (this.share);
        this.ui.setup_ui (this);

        this.ui.shared_with.set_elide_mode (Qt.Elide_right);
        this.ui.shared_with.on_set_text (share.get_share_with ().format ());

        // adds permissions
        // can edit permission
        bool enabled = (max_sharing_permissions & Share_permission_update);
        if (!this.is_file) enabled = enabled && (max_sharing_permissions & Share_permission_create &&
                                          max_sharing_permissions & Share_permission_delete);
        this.ui.permissions_edit.set_enabled (enabled);
        connect (this.ui.permissions_edit, &QAbstractButton.clicked, this, &Share_user_line.on_edit_permissions_changed);
        connect (this.ui.note_confirm_button, &QAbstractButton.clicked, this, &Share_user_line.on_note_confirm_button_clicked);
        connect (this.ui.calendar, &QDate_time_edit.date_changed, this, &Share_user_line.set_expire_date);

        connect (this.share.data (), &User_group_share.note_set, this, &Share_user_line.disable_progess_indicator_animation);
        connect (this.share.data (), &User_group_share.note_set_error, this, &Share_user_line.disable_progess_indicator_animation);
        connect (this.share.data (), &User_group_share.expire_date_set, this, &Share_user_line.disable_progess_indicator_animation);

        connect (this.ui.confirm_password, &QToolButton.clicked, this, &Share_user_line.on_confirm_password_clicked);
        connect (this.ui.line_edit_password, &QLineEdit.return_pressed, this, &Share_user_line.on_line_edit_password_return_pressed);

        // create menu with checkable permissions
        var menu = new QMenu (this);
        this.permission_reshare= new QAction (_("Can reshare"), this);
        this.permission_reshare.set_checkable (true);
        this.permission_reshare.set_enabled (max_sharing_permissions & Share_permission_share);
        menu.add_action (this.permission_reshare);
        connect (this.permission_reshare, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

        show_note_options (false);

        const bool is_note_supported = this.share.get_share_type () != Share.Share_type.Type_email && this.share.get_share_type () != Share.Share_type.Type_room;

        if (is_note_supported) {
            this.note_link_action = new QAction (_("Note to recipient"));
            this.note_link_action.set_checkable (true);
            menu.add_action (this.note_link_action);
            connect (this.note_link_action, &QAction.triggered, this, &Share_user_line.toggle_note_options);
            if (!this.share.get_note ().is_empty ()) {
                this.note_link_action.set_checked (true);
                show_note_options (true);
            }
        }

        show_expire_date_options (false);

        const bool is_expiration_date_supported = this.share.get_share_type () != Share.Share_type.Type_email;

        if (is_expiration_date_supported) {
            // email shares do not support expiration dates
            this.expiration_date_link_action = new QAction (_("Set expiration date"));
            this.expiration_date_link_action.set_checkable (true);
            menu.add_action (this.expiration_date_link_action);
            connect (this.expiration_date_link_action, &QAction.triggered, this, &Share_user_line.toggle_expire_date_options);
            const var expire_date = this.share.get_expire_date ().is_valid () ? share.data ().get_expire_date () : QDate ();
            if (!expire_date.is_null ()) {
                this.expiration_date_link_action.set_checked (true);
                show_expire_date_options (true, expire_date);
            }
        }

        menu.add_separator ();

          // Adds action to delete share widget
          QIcon deleteicon = QIcon.from_theme (QLatin1String ("user-trash"),QIcon (QLatin1String (":/client/theme/delete.svg")));
          this.delete_share_button= new QAction (deleteicon,_("Unshare"), this);

        menu.add_action (this.delete_share_button);
        connect (this.delete_share_button, &QAction.triggered, this, &Share_user_line.on_delete_share_button_clicked);

        /***********************************************************
        Files can't have create or delete permissions
         */
        if (!this.is_file) {
            this.permission_create = new QAction (_("Can create"), this);
            this.permission_create.set_checkable (true);
            this.permission_create.set_enabled (max_sharing_permissions & Share_permission_create);
            menu.add_action (this.permission_create);
            connect (this.permission_create, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

            this.permission_change = new QAction (_("Can change"), this);
            this.permission_change.set_checkable (true);
            this.permission_change.set_enabled (max_sharing_permissions & Share_permission_update);
            menu.add_action (this.permission_change);
            connect (this.permission_change, &QAction.triggered, this, &Share_user_line.on_permissions_changed);

            this.permission_delete = new QAction (_("Can delete"), this);
            this.permission_delete.set_checkable (true);
            this.permission_delete.set_enabled (max_sharing_permissions & Share_permission_delete);
            menu.add_action (this.permission_delete);
            connect (this.permission_delete, &QAction.triggered, this, &Share_user_line.on_permissions_changed);
        }

        // Adds action to display password widget (check box)
        if (this.share.get_share_type () == Share.Type_email && (this.share.is_password_set () || this.account.capabilities ().share_email_password_enabled ())) {
            this.password_protect_link_action = new QAction (_("Password protect"), this);
            this.password_protect_link_action.set_checkable (true);
            this.password_protect_link_action.set_checked (this.share.is_password_set ());
            // checkbox can be checked/unchedkec if the password is not yet set or if it's not enforced
            this.password_protect_link_action.set_enabled (!this.share.is_password_set () || !this.account.capabilities ().share_email_password_enforced ());

            menu.add_action (this.password_protect_link_action);
            connect (this.password_protect_link_action, &QAction.triggered, this, &Share_user_line.on_password_checkbox_changed);

            on_refresh_password_line_edit_placeholder ();

            connect (this.share.data (), &Share.password_set, this, &Share_user_line.on_password_set);
            connect (this.share.data (), &Share.password_set_error, this, &Share_user_line.on_password_set_error);
        }

        on_refresh_password_options ();

        this.ui.error_label.hide ();

        this.ui.permission_tool_button.set_menu (menu);
        this.ui.permission_tool_button.set_popup_mode (QToolButton.Instant_popup);

        this.ui.password_progress_indicator.set_visible (false);

        // Set the permissions checkboxes
        display_permissions ();

        /***********************************************************
        We don't show permission share for federated shares with server <9.1
        https://github.com/owncloud/core/issues/22122#issuecomment-185637344
        https://github.com/owncloud/client/issues/4996
         */
        if (share.get_share_type () == Share.Type_remote
            && share.account ().server_version_int () < Account.make_server_version (9, 1, 0)) {
            this.permission_reshare.set_visible (false);
            this.ui.permission_tool_button.set_visible (false);
        }

        connect (share.data (), &Share.permissions_set, this, &Share_user_line.on_permissions_set);
        connect (share.data (), &Share.share_deleted, this, &Share_user_line.on_share_deleted);

        if (!share.account ().capabilities ().share_resharing ()) {
            this.permission_reshare.set_visible (false);
        }

        const var avatar_event_filter = new Avatar_event_filter (this.ui.avatar);
        connect (avatar_event_filter, &Avatar_event_filter.context_menu, this, &Share_user_line.on_avatar_context_menu);
        this.ui.avatar.install_event_filter (avatar_event_filter);

        load_avatar ();

        customize_style ();
    }

    void Share_user_line.on_avatar_context_menu (QPoint global_position) {
        if (this.share.get_share_type () == Share.Type_user) {
            this.profile_page_menu.exec (global_position);
        }
    }

    void Share_user_line.load_avatar () {
        const int avatar_size = 36;

        // Set size of the placeholder
        this.ui.avatar.set_minimum_height (avatar_size);
        this.ui.avatar.set_minimum_width (avatar_size);
        this.ui.avatar.set_maximum_height (avatar_size);
        this.ui.avatar.set_maximum_width (avatar_size);
        this.ui.avatar.set_alignment (Qt.AlignCenter);

        set_default_avatar (avatar_size);

        /* Start the network job to fetch the avatar data.

        Currently only regular users can have avatars.
         */
        if (this.share.get_share_with ().type () == Sharee.User) {
            var job = new AvatarJob (this.share.account (), this.share.get_share_with ().share_with (), avatar_size, this);
            connect (job, &AvatarJob.avatar_pixmap, this, &Share_user_line.on_avatar_loaded);
            job.on_start ();
        }
    }

    void Share_user_line.set_default_avatar (int avatar_size) {
        /* Create the fallback avatar.

        This will be shown until the avatar image data arrives.
         */

        // See core/js/placeholder.js for details on colors and styling
        const var background_color = background_color_for_sharee_type (this.share.get_share_with ().type ());
        const string style = string (R" (* {
            color : #fff;
            background-color : %1;
            border-radius : %2px;
            text-align : center;
            line-height : %2px;
            font-size : %2px;
        })").arg (background_color.name (), string.number (avatar_size / 2));
        this.ui.avatar.set_style_sheet (style);

        const var pixmap = pixmap_for_sharee_type (this.share.get_share_with ().type (), background_color);

        if (!pixmap.is_null ()) {
            this.ui.avatar.set_pixmap (pixmap);
        } else {
            GLib.debug (lc_sharing) << "pixmap is null for share type : " << this.share.get_share_with ().type ();

            // The avatar label is the first character of the user name.
            const var text = this.share.get_share_with ().display_name ();
            this.ui.avatar.on_set_text (text.at (0).to_upper ());
        }
    }

    void Share_user_line.on_avatar_loaded (QImage avatar) {
        if (avatar.is_null ())
            return;

        avatar = AvatarJob.make_circular_avatar (avatar);
        this.ui.avatar.set_pixmap (QPixmap.from_image (avatar));

        // Remove the stylesheet for the fallback avatar
        this.ui.avatar.set_style_sheet ("");
    }

    void Share_user_line.on_delete_share_button_clicked () {
        set_enabled (false);
        this.share.delete_share ();
    }

    Share_user_line.~Share_user_line () {
        delete this.ui;
    }

    void Share_user_line.on_edit_permissions_changed () {
        set_enabled (false);

        // Can never manually be set to "partial".
        // This works because the state cycle for clicking is
        // unchecked . partial . checked . unchecked.
        if (this.ui.permissions_edit.check_state () == Qt.Partially_checked) {
            this.ui.permissions_edit.set_check_state (Qt.Checked);
        }

        Share.Permissions permissions = Share_permission_read;

        //  folders edit = CREATE, READ, UPDATE, DELETE
        //  files edit = READ + UPDATE
        if (this.ui.permissions_edit.check_state () == Qt.Checked) {

            /***********************************************************
            Files can't have create or delete permisisons
             */
            if (!this.is_file) {
                if (this.permission_change.is_enabled ())
                    permissions |= Share_permission_update;
                if (this.permission_create.is_enabled ())
                    permissions |= Share_permission_create;
                if (this.permission_delete.is_enabled ())
                    permissions |= Share_permission_delete;
            } else {
                permissions |= Share_permission_update;
            }
        }

        if (this.is_file && this.permission_reshare.is_enabled () && this.permission_reshare.is_checked ())
            permissions |= Share_permission_share;

        this.share.set_permissions (permissions);
    }

    void Share_user_line.on_permissions_changed () {
        set_enabled (false);

        Share.Permissions permissions = Share_permission_read;

        if (this.permission_reshare.is_checked ())
            permissions |= Share_permission_share;

        if (!this.is_file) {
            if (this.permission_change.is_checked ())
                permissions |= Share_permission_update;
            if (this.permission_create.is_checked ())
                permissions |= Share_permission_create;
            if (this.permission_delete.is_checked ())
                permissions |= Share_permission_delete;
        } else {
            if (this.ui.permissions_edit.is_checked ())
                permissions |= Share_permission_update;
        }

        this.share.set_permissions (permissions);
    }

    void Share_user_line.on_password_checkbox_changed () {
        if (!this.password_protect_link_action.is_checked ()) {
            this.ui.error_label.hide ();
            this.ui.error_label.clear ();

            if (!this.share.is_password_set ()) {
                this.ui.line_edit_password.clear ();
                on_refresh_password_options ();
            } else {
                // do not call on_refresh_password_options here, as it will be called after the network request is complete
                toggle_password_set_progress_animation (true);
                this.share.set_password ("");
            }
        } else {
            on_refresh_password_options ();

            if (this.ui.line_edit_password.is_visible () && this.ui.line_edit_password.is_enabled ()) {
                on_focus_password_line_edit ();
            }
        }
    }

    void Share_user_line.on_delete_animation_finished () {
        /* emit */ resize_requested ();
        /* emit */ visual_deletion_done ();
        delete_later ();

        // There is a painting bug where a small line of this widget isn't
        // properly cleared. This explicit repaint () call makes sure any trace of
        // the share widget is removed once it's destroyed. #4189
        connect (this, SIGNAL (destroyed (GLib.Object *)), parent_widget (), SLOT (repaint ()));
    }

    void Share_user_line.on_refresh_password_options () {
        const bool is_password_enabled = this.share.get_share_type () == Share.Type_email && this.password_protect_link_action.is_checked ();

        this.ui.password_label.set_visible (is_password_enabled);
        this.ui.line_edit_password.set_enabled (is_password_enabled);
        this.ui.line_edit_password.set_visible (is_password_enabled);
        this.ui.confirm_password.set_visible (is_password_enabled);

        /* emit */ resize_requested ();
    }

    void Share_user_line.on_refresh_password_line_edit_placeholder () {
        if (this.share.is_password_set ()) {
            this.ui.line_edit_password.set_placeholder_text (string.from_utf8 (password_is_set_placeholder));
        } else {
            this.ui.line_edit_password.set_placeholder_text ("");
        }
    }

    void Share_user_line.on_password_set () {
        toggle_password_set_progress_animation (false);
        this.ui.line_edit_password.set_enabled (true);
        this.ui.confirm_password.set_enabled (true);

        this.ui.line_edit_password.on_set_text ("");

        this.password_protect_link_action.set_enabled (!this.share.is_password_set () || !this.account.capabilities ().share_email_password_enforced ());

        on_refresh_password_line_edit_placeholder ();

        on_refresh_password_options ();
    }

    void Share_user_line.on_password_set_error (int status_code, string message) {
        GLib.warn (lc_sharing) << "Error from server" << status_code << message;

        toggle_password_set_progress_animation (false);

        this.ui.line_edit_password.set_enabled (true);
        this.ui.confirm_password.set_enabled (true);

        on_refresh_password_line_edit_placeholder ();

        on_refresh_password_options ();

        on_focus_password_line_edit ();

        this.ui.error_label.show ();
        this.ui.error_label.on_set_text (message);

        /* emit */ resize_requested ();
    }

    void Share_user_line.on_share_deleted () {
        var animation = new QPropertyAnimation (this, "maximum_height", this);

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
        return this.share;
    }

    void Share_user_line.display_permissions () {
        var perm = this.share.get_permissions ();

    //  folders edit = CREATE, READ, UPDATE, DELETE
    //  files edit = READ + UPDATE
        if (perm & Share_permission_update && (this.is_file ||
                                             (perm & Share_permission_create && perm & Share_permission_delete))) {
            this.ui.permissions_edit.set_check_state (Qt.Checked);
        } else if (!this.is_file && perm & (Share_permission_update | Share_permission_create | Share_permission_delete)) {
            this.ui.permissions_edit.set_check_state (Qt.Partially_checked);
        } else if (perm & Share_permission_read) {
            this.ui.permissions_edit.set_check_state (Qt.Unchecked);
        }

    //  edit is independent of reshare
        if (perm & Share_permission_share)
            this.permission_reshare.set_checked (true);

        if (!this.is_file){
            this.permission_create.set_checked (perm & Share_permission_create);
            this.permission_change.set_checked (perm & Share_permission_update);
            this.permission_delete.set_checked (perm & Share_permission_delete);
        }
    }

    void Share_user_line.on_style_changed () {
        customize_style ();
    }

    void Share_user_line.on_focus_password_line_edit () {
        this.ui.line_edit_password.set_focus ();
    }

    void Share_user_line.customize_style () {
        this.ui.permission_tool_button.set_icon (Theme.create_color_aware_icon (":/client/theme/more.svg"));

        QIcon deleteicon = QIcon.from_theme (QLatin1String ("user-trash"),Theme.create_color_aware_icon (QLatin1String (":/client/theme/delete.svg")));
        this.delete_share_button.set_icon (deleteicon);

        this.ui.note_confirm_button.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));
        this.ui.progress_indicator.on_set_color (QGuiApplication.palette ().color (QPalette.Window_text));

        // make sure to force Background_role to QPalette.Window_text for a lable, because it's parent always has a different role set that applies to children unless customized
        this.ui.error_label.set_background_role (QPalette.Window_text);
    }

    QPixmap Share_user_line.pixmap_for_sharee_type (Sharee.Type type, Gtk.Color background_color) {
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

    Gtk.Color Share_user_line.background_color_for_sharee_type (Sharee.Type type) {
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

        const var calculate_background_based_on_text = [this] () {
            const var hash = QCryptographicHash.hash (this.ui.shared_with.text ().to_utf8 (), QCryptographicHash.Md5);
            //  Q_ASSERT (hash.size () > 0);
            if (hash.size () == 0) {
                GLib.warn (lc_sharing) << "Failed to calculate hash color for share:" << this.share.path ();
                return Gtk.Color{};
            }
            const double hue = static_cast<uint8> (hash[0]) / 255.;
            return Gtk.Color.from_hsl_f (hue, 0.7, 0.68);
        };

        return calculate_background_based_on_text ();
    }

    void Share_user_line.show_note_options (bool show) {
        this.ui.note_label.set_visible (show);
        this.ui.note_text_edit.set_visible (show);
        this.ui.note_confirm_button.set_visible (show);

        if (show) {
            const var note = this.share.get_note ();
            this.ui.note_text_edit.on_set_text (note);
            this.ui.note_text_edit.set_focus ();
        }

        /* emit */ resize_requested ();
    }

    void Share_user_line.toggle_note_options (bool enable) {
        show_note_options (enable);

        if (!enable) {
            // Delete note
            this.share.set_note ("");
        }
    }

    void Share_user_line.on_note_confirm_button_clicked () {
        set_note (this.ui.note_text_edit.to_plain_text ());
    }

    void Share_user_line.set_note (string note) {
        enable_progess_indicator_animation (true);
        this.share.set_note (note);
    }

    void Share_user_line.toggle_expire_date_options (bool enable) {
        show_expire_date_options (enable);

        if (!enable) {
            this.share.set_expire_date (QDate ());
        }
    }

    void Share_user_line.show_expire_date_options (bool show, QDate initial_date) {
        this.ui.expiration_label.set_visible (show);
        this.ui.calendar.set_visible (show);

        if (show) {
            this.ui.calendar.set_minimum_date (QDate.current_date ().add_days (1));
            this.ui.calendar.set_date (initial_date.is_valid () ? initial_date : this.ui.calendar.minimum_date ());
            this.ui.calendar.set_focus ();

            if (enforce_expiration_date_for_share (this.share.get_share_type ())) {
                this.ui.calendar.set_maximum_date (max_expiration_date_for_share (this.share.get_share_type (), this.ui.calendar.maximum_date ()));
                this.expiration_date_link_action.set_checked (true);
                this.expiration_date_link_action.set_enabled (false);
            }
        }

        /* emit */ resize_requested ();
    }

    void Share_user_line.set_expire_date () {
        enable_progess_indicator_animation (true);
        this.share.set_expire_date (this.ui.calendar.date ());
    }

    void Share_user_line.enable_progess_indicator_animation (bool enable) {
        if (enable) {
            if (!this.ui.progress_indicator.is_animated ()) {
                this.ui.progress_indicator.on_start_animation ();
            }
        } else {
            this.ui.progress_indicator.on_stop_animation ();
        }
    }

    void Share_user_line.toggle_password_set_progress_animation (bool show) {
        // button and progress indicator are interchanged depending on if the network request is in progress or not
        this.ui.confirm_password.set_visible (!show && this.password_protect_link_action.is_checked ());
        this.ui.password_progress_indicator.set_visible (show);
        if (show) {
            if (!this.ui.password_progress_indicator.is_animated ()) {
                this.ui.password_progress_indicator.on_start_animation ();
            }
        } else {
            this.ui.password_progress_indicator.on_stop_animation ();
        }
    }

    void Share_user_line.disable_progess_indicator_animation () {
        enable_progess_indicator_animation (false);
    }

    QDate Share_user_line.max_expiration_date_for_share (Share.Share_type type, QDate fallback_date) {
        var days_to_expire = 0;
        if (type == Share.Share_type.Type_remote) {
            days_to_expire = this.account.capabilities ().share_remote_expire_date_days ();
        } else if (type == Share.Share_type.Type_email) {
           days_to_expire = this.account.capabilities ().share_public_link_expire_date_days ();
        } else {
            days_to_expire = this.account.capabilities ().share_internal_expire_date_days ();
        }

        if (days_to_expire > 0) {
            return QDate.current_date ().add_days (days_to_expire);
        }

        return fallback_date;
    }

    bool Share_user_line.enforce_expiration_date_for_share (Share.Share_type type) {
        if (type == Share.Share_type.Type_remote) {
            return this.account.capabilities ().share_remote_enforce_expire_date ();
        } else if (type == Share.Share_type.Type_email) {
            return this.account.capabilities ().share_public_link_enforce_expire_date ();
        }

        return this.account.capabilities ().share_internal_enforce_expire_date ();
    }

    void Share_user_line.on_set_password_confirmed () {
        if (this.ui.line_edit_password.text ().is_empty ()) {
            return;
        }

        this.ui.line_edit_password.set_enabled (false);
        this.ui.confirm_password.set_enabled (false);

        this.ui.error_label.hide ();
        this.ui.error_label.clear ();

        toggle_password_set_progress_animation (true);
        this.share.set_password (this.ui.line_edit_password.text ());
    }

    void Share_user_line.on_line_edit_password_return_pressed () {
        on_set_password_confirmed ();
    }

    void Share_user_line.on_confirm_password_clicked () {
        on_set_password_confirmed ();
    }