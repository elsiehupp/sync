/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QFileInfo>
//  #include <QFileIconProvider>
//  #include <QInputDialog>
//  #include <QPointer>
//  #include <QPushButton>
//  #include <QFrame>

//  #include <QPointer>
//  #include <Gtk.Dialog>
//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

class Share_dialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public Share_dialog (QPointer<AccountState> account_state,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const GLib.ByteArray numeric_file_id,
        Share_dialog_start_page start_page,
        Gtk.Widget parent = null);
    ~Share_dialog () override;


    /***********************************************************
    ***********************************************************/
    private void on_signal_done (int r) override;
    private void on_signal_propfind_received (QVariantMap result);
    private void on_signal_propfind_error ();
    private void on_signal_thumbnail_fetched (int status_code, GLib.ByteArray reply);
    private void on_signal_account_state_changed (int state);

    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (GLib.List<unowned<Share>> shares);
    private void on_signal_add_link_share_widget (unowned<Link_share> link_share);
    private void on_signal_delete_share ();
    private void on_signal_create_link_share ();
    private void on_signal_create_password_for_link_share (string password);
    private void on_signal_create_password_for_link_share_processed ();
    private void on_signal_link_share_requires_password ();
    private void on_signal_adjust_scroll_widget_size ();

signals:
    void toggle_share_link_animation (bool on_signal_start);
    void style_changed ();


    protected void change_event (QEvent *) override;


    /***********************************************************
    ***********************************************************/
    private void show_sharing_ui ();
    private Share_link_widget add_link_share_widget (unowned<Link_share> link_share);
    private void init_link_share_widget ();

    /***********************************************************
    ***********************************************************/
    private Ui.Share_dialog this.ui;

    /***********************************************************
    ***********************************************************/
    private QPointer<AccountState> this.account_state;
    private string this.share_path;
    private string this.local_path;
    private Share_permissions this.max_sharing_permissions;
    private GLib.ByteArray this.numeric_file_id;
    private string this.private_link_url;
    private Share_dialog_start_page this.start_page;
    private Share_manager this.manager = null;

    /***********************************************************
    ***********************************************************/
    private GLib.List<Share_link_widget> this.link_widget_list;
    private Share_link_widget* this.empty_share_link_widget = null;
    private Share_user_group_widget this.user_group_widget = null;
    private QProgressIndicator this.progress_indicator = null;
}


    /***********************************************************
    ***********************************************************/
    const int thumbnail_size = 40;

    Share_dialog.Share_dialog (QPointer<AccountState> account_state,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const GLib.ByteArray numeric_file_id,
        Share_dialog_start_page start_page,
        Gtk.Widget parent)
        : Gtk.Dialog (parent)
        this.ui (new Ui.Share_dialog)
        this.account_state (account_state)
        this.share_path (share_path)
        this.local_path (local_path)
        this.max_sharing_permissions (max_sharing_permissions)
        this.private_link_url (account_state.account ().deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded))
        this.start_page (start_page) {
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        attribute (Qt.WA_DeleteOnClose);
        object_name ("Sharing_dialog"); // required as group for save_geometry call

        this.ui.up_ui (this);

        // We want to act on account state changes
        connect (this.account_state.data (), &AccountState.state_changed, this, &Share_dialog.on_signal_account_state_changed);

        // Set icon
        QFileInfo f_info (this.local_path);
        QFileIconProvider icon_provider;
        QIcon icon = icon_provider.icon (f_info);
        var pixmap = icon.pixmap (thumbnail_size, thumbnail_size);
        if (pixmap.width () > 0) {
            this.ui.label_icon.pixmap (pixmap);
        }

        // Set filename
        string filename = QFileInfo (this.share_path).filename ();
        this.ui.label_name.on_signal_text (_("%1").arg (filename));
        QFont f (this.ui.label_name.font ());
        f.point_size (q_round (f.point_size () * 1.4));
        this.ui.label_name.font (f);

        string oc_dir (this.share_path);
        oc_dir.truncate (oc_dir.length () - filename.length ());

        oc_dir.replace (QRegularExpression ("^/*"), "");
        oc_dir.replace (QRegularExpression ("/*$"), "");

        // Laying this out is complex because share_path
        // may be in use or not.
        this.ui.grid_layout.remove_widget (this.ui.label_share_path);
        this.ui.grid_layout.remove_widget (this.ui.label_name);
        if (oc_dir.is_empty ()) {
            this.ui.grid_layout.add_widget (this.ui.label_name, 0, 1, 2, 1);
            this.ui.label_share_path.on_signal_text ("");
        } else {
            this.ui.grid_layout.add_widget (this.ui.label_name, 0, 1, 1, 1);
            this.ui.grid_layout.add_widget (this.ui.label_share_path, 1, 1, 1, 1);
            this.ui.label_share_path.on_signal_text (_("Folder : %2").arg (oc_dir));
        }

        this.window_title (_("%1 Sharing").arg (Theme.instance ().app_name_gui ()));

        if (!account_state.account ().capabilities ().share_api ()) {
            return;
        }

        if (QFileInfo (this.local_path).is_file ()) {
            var job = new Thumbnail_job (this.share_path, this.account_state.account (), this);
            connect (job, &Thumbnail_job.job_finished, this, &Share_dialog.on_signal_thumbnail_fetched);
            job.on_signal_start ();
        }

        var job = new PropfindJob (account_state.account (), this.share_path);
        job.properties (
            GLib.List<GLib.ByteArray> ()
            + "http://open-collaboration-services.org/ns:share-permissions"
            + "http://owncloud.org/ns:fileid" // numeric file identifier for fallback private link generation
            + "http://owncloud.org/ns:privatelink");
        job.on_signal_timeout (10 * 1000);
        connect (job, &PropfindJob.result, this, &Share_dialog.on_signal_propfind_received);
        connect (job, &PropfindJob.finished_with_error, this, &Share_dialog.on_signal_propfind_error);
        job.on_signal_start ();

        bool sharing_possible = true;
        if (!account_state.account ().capabilities ().share_public_link ()) {
            GLib.warn ("Link shares have been disabled";
            sharing_possible = false;
        } else if (! (max_sharing_permissions & Share_permission_share)) {
            GLib.warn ("The file cannot be shared because it does not have sharing permission.";
            sharing_possible = false;
        }

        if (sharing_possible) {
            this.manager = new Share_manager (account_state.account (), this);
            connect (this.manager, &Share_manager.on_signal_shares_fetched, this, &Share_dialog.on_signal_shares_fetched);
            connect (this.manager, &Share_manager.on_signal_link_share_created, this, &Share_dialog.on_signal_add_link_share_widget);
            connect (this.manager, &Share_manager.on_signal_link_share_requires_password, this, &Share_dialog.on_signal_link_share_requires_password);
        }
    }

    Share_link_widget *Share_dialog.add_link_share_widget (unowned<Link_share> link_share) {
        this.link_widget_list.append (new Share_link_widget (this.account_state.account (), this.share_path, this.local_path, this.max_sharing_permissions, this));

        const var link_share_widget = this.link_widget_list.at (this.link_widget_list.size () - 1);
        link_share_widget.link_share (link_share);

        connect (link_share.data (), &Share.on_signal_server_error, link_share_widget, &Share_link_widget.on_signal_server_error);
        connect (link_share.data (), &Share.share_deleted, link_share_widget, &Share_link_widget.on_signal_delete_share_fetched);

        if (this.manager) {
            connect (this.manager, &Share_manager.on_signal_server_error, link_share_widget, &Share_link_widget.on_signal_server_error);
        }

        // Connect all shares signals to gui slots
        connect (this, &Share_dialog.toggle_share_link_animation, link_share_widget, &Share_link_widget.on_signal_toggle_share_link_animation);
        connect (link_share_widget, &Share_link_widget.create_link_share, this, &Share_dialog.on_signal_create_link_share);
        connect (link_share_widget, &Share_link_widget.delete_link_share, this, &Share_dialog.on_signal_delete_share);
        connect (link_share_widget, &Share_link_widget.create_password, this, &Share_dialog.on_signal_create_password_for_link_share);

        //connect (this.link_widget_list.at (index), &Share_link_widget.resize_requested, this, &Share_dialog.on_signal_adjust_scroll_widget_size);

        // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
        connect (this, &Share_dialog.style_changed, link_share_widget, &Share_link_widget.on_signal_style_changed);

        this.ui.vertical_layout.insert_widget (this.link_widget_list.size () + 1, link_share_widget);
        link_share_widget.setup_ui_options ();

        return link_share_widget;
    }

    void Share_dialog.init_link_share_widget () {
        if (this.link_widget_list.size () == 0) {
            this.empty_share_link_widget = new Share_link_widget (this.account_state.account (), this.share_path, this.local_path, this.max_sharing_permissions, this);
            this.link_widget_list.append (this.empty_share_link_widget);

            connect (this.empty_share_link_widget, &Share_link_widget.resize_requested, this, &Share_dialog.on_signal_adjust_scroll_widget_size);
            connect (this, &Share_dialog.toggle_share_link_animation, this.empty_share_link_widget, &Share_link_widget.on_signal_toggle_share_link_animation);
            connect (this.empty_share_link_widget, &Share_link_widget.create_link_share, this, &Share_dialog.on_signal_create_link_share);

            connect (this.empty_share_link_widget, &Share_link_widget.create_password, this, &Share_dialog.on_signal_create_password_for_link_share);

            this.ui.vertical_layout.insert_widget (this.link_widget_list.size ()+1, this.empty_share_link_widget);
            this.empty_share_link_widget.show ();
        } else if (this.empty_share_link_widget) {
            this.empty_share_link_widget.hide ();
            this.ui.vertical_layout.remove_widget (this.empty_share_link_widget);
            this.link_widget_list.remove_all (this.empty_share_link_widget);
            this.empty_share_link_widget = null;
        }
    }

    void Share_dialog.on_signal_add_link_share_widget (unowned<Link_share> link_share) {
        /* emit */ toggle_share_link_animation (true);
        const var added_link_share_widget = add_link_share_widget (link_share);
        init_link_share_widget ();
        if (link_share.is_password_set ()) {
            added_link_share_widget.on_signal_focus_password_line_edit ();
        }
        /* emit */ toggle_share_link_animation (false);
    }

    void Share_dialog.on_signal_shares_fetched (GLib.List<unowned<Share>> shares) {
        /* emit */ toggle_share_link_animation (true);

        const string version_string = this.account_state.account ().server_version ();
        GLib.info () + version_string + "Fetched" + shares.count ("shares";
        foreach (var share, shares) {
            if (share.get_share_type () != Share.Type_link || share.get_uid_owner () != share.account ().dav_user ()) {
                continue;
            }

            unowned<Link_share> link_share = q_shared_pointer_dynamic_cast<Link_share> (share);
            add_link_share_widget (link_share);
        }

        init_link_share_widget ();
        /* emit */ toggle_share_link_animation (false);
    }

    void Share_dialog.on_signal_adjust_scroll_widget_size () {
        int count = this.find_children<Share_link_widget> ().count ();
        this.ui.scroll_area.visible (count > 0);
        if (count > 0 && count <= 3) {
            this.ui.scroll_area.fixed_height (this.ui.scroll_area.widget ().size_hint ().height ());
        }
        this.ui.scroll_area.frame_shape (count > 3 ? QFrame.Styled_panel : QFrame.No_frame);
    }

    Share_dialog.~Share_dialog () {
        this.link_widget_list.clear ();
        delete this.ui;
    }

    void Share_dialog.on_signal_done (int r) {
        ConfigFile config;
        config.save_geometry (this);
        Gtk.Dialog.on_signal_done (r);
    }

    void Share_dialog.on_signal_propfind_received (QVariantMap result) {
        const GLib.Variant received_permissions = result["share-permissions"];
        if (!received_permissions.to_string ().is_empty ()) {
            this.max_sharing_permissions = static_cast<Share_permissions> (received_permissions.to_int ());
            GLib.info ("Received sharing permissions for" + this.share_path + this.max_sharing_permissions;
        }
        var private_link_url = result["privatelink"].to_string ();
        var numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url.is_empty ()) {
            GLib.info ("Received private link url for" + this.share_path + private_link_url;
            this.private_link_url = private_link_url;
        } else if (!numeric_file_id.is_empty ()) {
            GLib.info ("Received numeric file identifier for" + this.share_path + numeric_file_id;
            this.private_link_url = this.account_state.account ().deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);
        }

        show_sharing_ui ();
    }

    void Share_dialog.on_signal_propfind_error () {
        // On error show the share ui anyway. The user can still see shares,
        // delete them and so on, even though adding new shares or granting
        // some of the permissions might fail.

        show_sharing_ui ();
    }

    void Share_dialog.show_sharing_ui () {
        var theme = Theme.instance ();

        // There's no difference between being unable to reshare and
        // being unable to reshare with reshare permission.
        bool can_reshare = this.max_sharing_permissions & Share_permission_share;

        if (!can_reshare) {
            var label = new Gtk.Label (this);
            label.on_signal_text (_("The file cannot be shared because it does not have sharing permission."));
            label.word_wrap (true);
            this.ui.vertical_layout.insert_widget (1, label);
            return;
        }

        // We only do user/group sharing from 8.2.0
        bool user_group_sharing =
            theme.user_group_sharing ()
            && this.account_state.account ().server_version_int () >= Account.make_server_version (8, 2, 0);

        if (user_group_sharing) {
            this.user_group_widget = new Share_user_group_widget (this.account_state.account (), this.share_path, this.local_path, this.max_sharing_permissions, this.private_link_url, this);

            // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            connect (this, &Share_dialog.style_changed, this.user_group_widget, &Share_user_group_widget.on_signal_style_changed);

            this.ui.vertical_layout.insert_widget (1, this.user_group_widget);
            this.user_group_widget.on_signal_get_shares ();
        }

        if (theme.link_sharing ()) {
            if (this.manager) {
                this.manager.fetch_shares (this.share_path);
            }
        }
    }

    void Share_dialog.on_signal_create_link_share () {
        if (this.manager) {
            const var ask_optional_password = this.account_state.account ().capabilities ().share_public_link_ask_optional_password ();
            const var password = ask_optional_password ? create_random_password () : "";
            this.manager.create_link_share (this.share_path, "", password);
        }
    }

    void Share_dialog.on_signal_create_password_for_link_share (string password) {
        const var share_link_widget = qobject_cast<Share_link_widget> (sender ());
        //  Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            connect (this.manager, &Share_manager.on_signal_link_share_requires_password, share_link_widget, &Share_link_widget.on_signal_create_share_requires_password);
            connect (share_link_widget, &Share_link_widget.create_password_processed, this, &Share_dialog.on_signal_create_password_for_link_share_processed);
            share_link_widget.get_link_share ().password (password);
        } else {
            GLib.critical ("share_link_widget is not a sender!";
        }
    }

    void Share_dialog.on_signal_create_password_for_link_share_processed () {
        const var share_link_widget = qobject_cast<Share_link_widget> (sender ());
        //  Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            disconnect (this.manager, &Share_manager.on_signal_link_share_requires_password, share_link_widget, &Share_link_widget.on_signal_create_share_requires_password);
            disconnect (share_link_widget, &Share_link_widget.create_password_processed, this, &Share_dialog.on_signal_create_password_for_link_share_processed);
        } else {
            GLib.critical ("share_link_widget is not a sender!";
        }
    }

    void Share_dialog.on_signal_link_share_requires_password () {
        bool ok = false;
        string password = QInputDialog.get_text (this,
                                                 _("Password for share required"),
                                                 _("Please enter a password for your link share:"),
                                                 QLineEdit.Password,
                                                 "",
                                                 ok);

        if (!ok) {
            // The dialog was canceled so no need to do anything
            /* emit */ toggle_share_link_animation (false);
            return;
        }

        if (this.manager) {
            // Try to create the link share again with the newly entered password
            this.manager.create_link_share (this.share_path, "", password);
        }
    }

    void Share_dialog.on_signal_delete_share () {
        var sharelink_widget = dynamic_cast<Share_link_widget> (sender ());
        sharelink_widget.hide ();
        this.ui.vertical_layout.remove_widget (sharelink_widget);
        this.link_widget_list.remove_all (sharelink_widget);
        init_link_share_widget ();
    }

    void Share_dialog.on_signal_thumbnail_fetched (int status_code, GLib.ByteArray reply) {
        if (status_code != 200) {
            GLib.warn ("Thumbnail status code : " + status_code;
            return;
        }

        QPixmap p;
        p.load_from_data (reply, "PNG");
        p = p.scaled_to_height (thumbnail_size, Qt.Smooth_transformation);
        this.ui.label_icon.pixmap (p);
        this.ui.label_icon.show ();
    }

    void Share_dialog.on_signal_account_state_changed (int state) {
        bool enabled = (state == AccountState.State.Connected);
        GLib.debug ("Account connected?" + enabled;

        if (this.user_group_widget) {
            this.user_group_widget.enabled (enabled);
        }

        if (this.link_widget_list.size () > 0) {
            foreach (Share_link_widget widget, this.link_widget_list) {
                widget.enabled (state);
            }
        }
    }

    void Share_dialog.change_event (QEvent e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            // Notify the other widgets (Dark-/Light-Mode switching)
            /* emit */ style_changed ();
            break;
        default:
            break;
        }

        Gtk.Dialog.change_event (e);
    }
    

    static string create_random_password () {
        const var words = Occ.Word_list.get_random_words (10);

        const var add_first_letter = [] (string current, string next) . string {
            return current + next.at (0);
        }

        return std.accumulate (std.cbegin (words), std.cend (words), "", add_first_letter);
    }

    } // namespace Occ
    