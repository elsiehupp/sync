/***********************************************************
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.FileInfo>
//  #include <GLib.FileIconProvider>
//  #include <GLib.InputDialog>
//  #include <GLib.Pointer>
//  #include <GLib.PushButton>
//  #include <Gdk.Frame>

//  #include <GLib.Pointer>
//  #include <Gtk.Dialog>
//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public class ShareDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private const int THUMBNAIL_SIZE = 40;

    /***********************************************************
    ***********************************************************/
    private ShareDialog instance;

    /***********************************************************
    ***********************************************************/
    private AccountState account_state;
    private string share_path;
    private string local_path;
    private SharePermissions max_sharing_permissions;
    private string numeric_file_id;
    private string private_link_url;
    private ShareDialogStartPage start_page;
    private ShareManager share_manager = null;

    /***********************************************************
    ***********************************************************/
    private GLib.List<ShareLinkWidget> link_widget_list;
    private ShareLinkWidget* empty_share_link_widget = null;
    private ShareUserGroupWidget user_group_widget = null;
    private GLib.ProgressIndicator progress_indicator = null;


    internal signal void signal_toggle_share_link_animation (bool on_signal_start);
    internal signal void signal_style_changed ();

    /***********************************************************
    ***********************************************************/
    public ShareDialog (
        AccountState account_state,
        string share_path,
        string local_path,
        SharePermissions max_sharing_permissions,
        string numeric_file_id,
        ShareDialogStartPage start_page,
        Gtk.Widget parent = new Gtk.Widget ()
    ) {
        base (parent);
        this.instance = new ShareDialog ();
        this.account_state = account_state;
        this.share_path = share_path;
        this.local_path = local_path;
        this.max_sharing_permissions = max_sharing_permissions;
        this.private_link_url = account_state.account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);
        this.start_page = start_page;
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        attribute (Qt.WA_DeleteOnClose);
        object_name ("Sharing_dialog"); // required as group for save_geometry call

        this.instance.up_ui (this);

        // We want to act on account state changes
        this.account_state.signal_state_changed.connect (
            this.on_signal_account_state_changed
        );

        // Set icon
        GLib.FileInfo file_info = new GLib.FileInfo (this.local_path);
        GLib.FileIconProvider icon_provider;
        Gtk.Icon icon = icon_provider.icon (file_info);
        var pixmap = icon.pixmap (THUMBNAIL_SIZE, THUMBNAIL_SIZE);
        if (pixmap.width () > 0) {
            this.instance.label_icon.pixmap (pixmap);
        }

        // Set filename
        string filename = new GLib.FileInfo (this.share_path).filename ();
        this.instance.label_name.on_signal_text (_("%1").printf (filename));
        Cairo.FontFace font = new Cairo.FontFace (this.instance.label_name.font ());
        font.point_size (q_round (font.point_size () * 1.4));
        this.instance.label_name.font (font);

        string oc_dir = this.share_path;
        oc_dir.truncate (oc_dir.length - filename.length);

        oc_dir.replace (new GLib.Regex ("^/*"), "");
        oc_dir.replace (new GLib.Regex ("/*$"), "");

        // Laying this out is complex because share_path
        // may be in use or not.
        this.instance.grid_layout.remove_widget (this.instance.label_share_path);
        this.instance.grid_layout.remove_widget (this.instance.label_name);
        if (oc_dir == "") {
            this.instance.grid_layout.add_widget (this.instance.label_name, 0, 1, 2, 1);
            this.instance.label_share_path.on_signal_text ("");
        } else {
            this.instance.grid_layout.add_widget (this.instance.label_name, 0, 1, 1, 1);
            this.instance.grid_layout.add_widget (this.instance.label_share_path, 1, 1, 1, 1);
            this.instance.label_share_path.on_signal_text (_("FolderConnection : %2").printf (oc_dir));
        }

        this.window_title (_("%1 Sharing").printf (Theme.app_name_gui));

        if (!account_state.account.capabilities.share_api ()) {
            return;
        }

        if (new GLib.FileInfo (this.local_path).is_file ()) {
            var thumbnail_job = new ThumbnailJob (this.share_path, this.account_state.account, this);
            thumbnail_job.signal_job_finished.connect (
                this.on_signal_thumbnail_fetched
            );
            thumbnail_job.on_signal_start ();
        }

        var propfind_job = new PropfindJob (account_state.account, this.share_path);
        propfind_job.properties (
            GLib.List<string> ()
            + "http://open-collaboration-services.org/ns:share-permissions"
            + "http://owncloud.org/ns:fileid" // numeric file identifier for fallback private link generation
            + "http://owncloud.org/ns:privatelink");
        propfind_job.on_signal_timeout (10 * 1000);
        propfind_job.result.connect (
            this.on_signal_propfind_received
        );
        propfind_job.signal_finished_with_error.connect (
            this.on_signal_propfind_error
        );
        propfind_job.on_signal_start ();

        bool sharing_possible = true;
        if (!account_state.account.capabilities.share_public_link ()) {
            GLib.warning ("Link shares have been disabled.");
            sharing_possible = false;
        } else if (!(max_sharing_permissions & Share_permission_share)) {
            GLib.warning ("The file cannot be shared because it does not have sharing permission.");
            sharing_possible = false;
        }

        if (sharing_possible) {
            this.share_manager = new ShareManager (account_state.account, this);
            this.share_manager.signal_shares_fetched.connect (
                this.on_signal_shares_fetched
            );
            this.share_manager.signal_link_share_created.connect (
                this, ShareDialog.on_signal_add_link_share_widget);
                this.share_manager.signal_link_share_requires_password.connect (
                this.on_signal_link_share_requires_password
            );
        }
    }



    override ~ShareDialog () {
        this.link_widget_list = null;
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    private override void on_signal_done (int r) {
        ConfigFile config;
        config.save_geometry (this);
        Gtk.Dialog.on_signal_done (r);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_received (GLib.VariantMap result) {
        const GLib.Variant received_permissions = result["share-permissions"];
        if (!received_permissions.to_string () == "") {
            this.max_sharing_permissions = static_cast<SharePermissions> (received_permissions.to_int ());
            GLib.info ("Received sharing permissions for " + this.share_path + this.max_sharing_permissions.to_string ());
        }
        var private_link_url = result["privatelink"].to_string ();
        var numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url == "") {
            GLib.info ("Received private link url for " + this.share_path + private_link_url);
            this.private_link_url = private_link_url;
        } else if (!numeric_file_id == "") {
            GLib.info ("Received numeric file identifier for " + this.share_path + numeric_file_id);
            this.private_link_url = this.account_state.account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);
        }

        show_sharing_ui ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_error () {
        // On error show the share instance anyway. The user can still see shares,
        // delete them and so on, even though adding new shares or granting
        // some of the permissions might fail.

        show_sharing_ui ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_thumbnail_fetched (int status_code, string reply) {
        if (status_code != 200) {
            GLib.warning ("Thumbnail status code: " + status_code.to_string ());
            return;
        }

        Gdk.Pixbuf p;
        p.load_from_data (reply, "PNG");
        p = p.scaled_to_height (THUMBNAIL_SIZE, Qt.Smooth_transformation);
        this.instance.label_icon.pixmap (p);
        this.instance.label_icon.show ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_state_changed (int state) {
        bool enabled = (state == AccountState.State.Connected);
        GLib.debug ("Account connected? " + enabled);

        if (this.user_group_widget != null) {
            this.user_group_widget.enabled (enabled);
        }

        if (this.link_widget_list.length () > 0) {
            foreach (ShareLinkWidget widget in this.link_widget_list) {
                widget.enabled (state);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (GLib.List<unowned Share> shares) {
        /* emit */ signal_toggle_share_link_animation (true);

        const string version_string = this.account_state.account.server_version ();
        GLib.info (version_string + "Fetched" + shares.length + "shares");
        foreach (var share in shares) {
            if (share.share_type != Share.Type.LINK || share.owner_uid != share.account.dav_user) {
                continue;
            }

            unowned LinkShare link_share = q_shared_pointer_dynamic_cast<LinkShare> (share);
            add_link_share_widget (link_share);
        }

        init_link_share_widget ();
        /* emit */ signal_toggle_share_link_animation (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_add_link_share_widget (LinkShare link_share) {
        /* emit */ signal_toggle_share_link_animation (true);
        ShareLinkWidget added_link_share_widget = add_link_share_widget (link_share);
        init_link_share_widget ();
        if (link_share.password_is_set) {
            added_link_share_widget.on_signal_focus_password_line_edit ();
        }
        /* emit */ signal_toggle_share_link_animation (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_share () {
        var sharelink_widget = dynamic_cast<ShareLinkWidget> (sender ());
        sharelink_widget.hide ();
        this.instance.vertical_layout.remove_widget (sharelink_widget);
        this.link_widget_list.remove_all (sharelink_widget);
        init_link_share_widget ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_link_share () {
        if (this.share_manager != null) {
            const bool ask_optional_password = this.account_state.account.capabilities.share_public_link_ask_optional_password ();
            const string password = ask_optional_password ? create_random_password (): "";
            this.share_manager.create_link_share (this.share_path, "", password);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_password_for_link_share (string password) {
        const var share_link_widget = qobject_cast<ShareLinkWidget> (sender ());
        //  Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            this.share_manager.signal_link_share_requires_password.connect (
                share_link_widget.on_signal_create_share_requires_password
            );
            share_link_widget.create_password_processed.connect (
                this.on_signal_create_password_for_link_share_processed
            );
            share_link_widget.link_share ().password (password);
        } else {
            GLib.critical ("share_link_widget is not a sender!");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_password_for_link_share_processed () {
        const var share_link_widget = qobject_cast<ShareLinkWidget> (sender ());
        //  Q_ASSERT (share_link_widget);
        if (share_link_widget) {
            disconnect (this.share_manager, ShareManager.on_signal_link_share_requires_password, share_link_widget, ShareLinkWidget.on_signal_create_share_requires_password);
            disconnect (share_link_widget, ShareLinkWidget.create_password_processed, this, ShareDialog.on_signal_create_password_for_link_share_processed);
        } else {
            GLib.critical ("share_link_widget is not a sender!");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_requires_password () {
        bool ok = false;
        string password = GLib.InputDialog.text (this,
                                                 _("Password for share required"),
                                                 _("Please enter a password for your link share:"),
                                                 GLib.LineEdit.Password,
                                                 "",
                                                 ok);

        if (!ok) {
            // The dialog was canceled so no need to do anything
            /* emit */ signal_toggle_share_link_animation (false);
            return;
        }

        if (this.share_manager != null) {
            // Try to create the link share again with the newly entered password
            this.share_manager.create_link_share (this.share_path, "", password);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_adjust_scroll_widget_size () {
        int count = this.find_children<ShareLinkWidget> ().length;
        this.instance.scroll_area.visible (count > 0);
        if (count > 0 && count <= 3) {
            this.instance.scroll_area.fixed_height (this.instance.scroll_area.widget ().size_hint ().height ());
        }
        this.instance.scroll_area.frame_shape (count > 3 ? Gdk.Frame.Styled_panel : Gdk.Frame.No_frame);
    }


    /***********************************************************
    ***********************************************************/
    protected override void change_event (GLib.Event e) {
        switch (e.type ()) {
        case GLib.Event.StyleChange:
        case GLib.Event.PaletteChange:
        case GLib.Event.ThemeChange:
            // Notify the other widgets (Dark-/Light-Mode switching)
            /* emit */ signal_style_changed ();
            break;
        default:
            break;
        }

        Gtk.Dialog.change_event (e);
    }


    /***********************************************************
    ***********************************************************/
    private void show_sharing_ui () {
        var theme = Theme.instance;

        // There's no difference between being unable to reshare and
        // being unable to reshare with reshare permission.
        bool can_reshare = this.max_sharing_permissions & Share_permission_share;

        if (!can_reshare) {
            var label = new Gtk.Label (this);
            label.on_signal_text (_("The file cannot be shared because it does not have sharing permission."));
            label.word_wrap (true);
            this.instance.vertical_layout.insert_widget (1, label);
            return;
        }

        // We only do user/group sharing from 8.2.0
        bool user_group_sharing =
            theme.user_group_sharing
            && this.account_state.account.server_version_int >= Account.make_server_version (8, 2, 0);

        if (user_group_sharing) {
            this.user_group_widget = new ShareUserGroupWidget (this.account_state.account, this.share_path, this.local_path, this.max_sharing_permissions, this.private_link_url, this);

            // Connect signal_style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            this.signal_style_changed.connect (
                this.user_group_widget.on_signal_style_changed
            );

            this.instance.vertical_layout.insert_widget (1, this.user_group_widget);
            this.user_group_widget.on_signal_get_shares ();
        }

        if (theme.link_sharing) {
            if (this.share_manager != null) {
                this.share_manager.fetch_shares (this.share_path);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private ShareLinkWidget add_link_share_widget (LinkShare link_share) {
        this.link_widget_list.append (new ShareLinkWidget (this.account_state.account, this.share_path, this.local_path, this.max_sharing_permissions, this));

        ShareLinkWidget link_share_widget = this.link_widget_list.at (this.link_widget_list.size () - 1);
        link_share_widget.link_share (link_share);

        link_share.signal_server_error.connect (
            link_share_widget.on_signal_server_error
        );
        link_share.signal_share_deleted.connect (
            link_share_widget.on_signal_delete_share_fetched
        );

        if (this.share_manager != null) {
            this.share_manager.signal_server_error.connect (
                link_share_widget.on_signal_server_error
            );
        }

        // Connect all shares signals to gui slots
        this.signal_toggle_share_link_animation.connect (
            link_share_widget.on_signal_toggle_share_link_animation
        );
        link_share_widget.create_link_share.connect (
            this.on_signal_create_link_share
        );
        link_share_widget.delete_link_share.connect (
            this.on_signal_delete_share
        );
        link_share_widget.create_password.connect (
            this.on_signal_create_password_for_link_share
        );

        //  connect (
        //      this.link_widget_list.at (index), ShareLinkWidget.resize_requested,
        //      this, ShareDialog.on_signal_adjust_scroll_widget_size
        //  );

        // Connect signal_style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            link_share_widget.on_signal_style_changed
        );

        this.instance.vertical_layout.insert_widget (this.link_widget_list.size () + 1, link_share_widget);
        link_share_widget.set_up_ui_options ();

        return link_share_widget;
    }


    /***********************************************************
    ***********************************************************/
    private void init_link_share_widget () {
        if (this.link_widget_list.length () == 0) {
            this.empty_share_link_widget = new ShareLinkWidget (this.account_state.account, this.share_path, this.local_path, this.max_sharing_permissions, this);
            this.link_widget_list.append (this.empty_share_link_widget);

            this.empty_share_link_widget.resize_requested.connect (
                this.on_signal_adjust_scroll_widget_size
            );
            this.signal_toggle_share_link_animation.connect (
                this.empty_share_link_widget.on_signal_toggle_share_link_animation
            );
            this.empty_share_link_widget.create_link_share.connect (
                this.on_signal_create_link_share
            );
            this.empty_share_link_widget.create_password.connect (
                this.on_signal_create_password_for_link_share
            );

            this.instance.vertical_layout.insert_widget (this.link_widget_list.size ()+1, this.empty_share_link_widget);
            this.empty_share_link_widget.show ();
        } else if (this.empty_share_link_widget != null) {
            this.empty_share_link_widget.hide ();
            this.instance.vertical_layout.remove_widget (this.empty_share_link_widget);
            this.link_widget_list.remove_all (this.empty_share_link_widget);
            this.empty_share_link_widget = null;
        }
    }


    /***********************************************************
    ***********************************************************/
    private static string create_random_password () {
        string password;
        foreach (string word in WordList.random_words (10)) {
            password += word;
        }
        return password;
    }

} // class ShareDialog

} // namespace Ui
} // namespace Occ
