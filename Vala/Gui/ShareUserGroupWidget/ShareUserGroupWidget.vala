/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include <QFileIconProvider>
//  #include <QClipboard>
//  #include <GLib.FileInfo>
//  #include <QAbstract_proxy_model>
//  #include <QCompleter>
//  #include <QBox_layout>
//  #include <Gtk.Icon>
//  #include <QLayout>
//  #include <QPropertyAnimation>
//  #include <QMenu>
//  #include <QAction>
//  #include <QDesktopServices>
//  #include <QInputDialog>
//  #include <Gtk.MessageBox>
//  #include <QCryptographicHash>
//  #include <Gtk.Color>
//  #include <QPainter>
//  #include <QList_widget>
//  #include <QSvgRenderer>
//  #include <QPushButton>
//  #include <QContext_menu_event>
//  #include <cstring>
//  #include <Gtk.Dialog
//  #include <Gtk.Wid
//  #include <QTimer>
//  #include <qpushbutton.h>
//  #include <qscrollarea.h>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ShareDialog (user/group) class
@ingroup gui
***********************************************************/
public class ShareUserGroupWidget : Gtk.Widget {

    private const string PASSWORD_IS_PLACEHOLDER = "●●●●●●●●";

    /***********************************************************
    ***********************************************************/
    private Ui.ShareUserGroupWidget ui;
    private QScroll_area parent_scroll_area;
    private unowned Account account;
    private string share_path;
    private string local_path;
    private SharePermissions max_sharing_permissions;
    private string private_link_url;

    /***********************************************************
    ***********************************************************/
    private QCompleter completer;
    private ShareeModel completer_model;
    private QTimer completion_timer;

    /***********************************************************
    ***********************************************************/
    private bool is_file;

    /***********************************************************
    In order to avoid that we share the contents twice
    ***********************************************************/
    private bool disable_completer_activated;
    private ShareManager manager;

    /***********************************************************
    ***********************************************************/
    private QProgressIndicator pi_sharee;

    /***********************************************************
    ***********************************************************/
    private string last_created_share_id;

    internal signal void signal_toggle_public_link_share (bool value);
    internal signal void signal_style_changed ();

    /***********************************************************
    ***********************************************************/
    public ShareUserGroupWidget (
        unowned Account account,
        string share_path,
        string local_path,
        SharePermissions max_sharing_permissions,
        string private_link_url,
        Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui = new Ui.ShareUserGroupWidget ();
        this.account = account;
        this.share_path = share_path;
        this.local_path = local_path;
        this.max_sharing_permissions = max_sharing_permissions;
        this.private_link_url = private_link_url;
        this.disable_completer_activated = false;
        attribute (Qt.WA_DeleteOnClose);
        object_name ("Sharing_dialog_uG"); // required as group for save_geometry call

        this.ui.up_ui (this);

        //Is this a file or folder?
        this.is_file = GLib.FileInfo (local_path).is_file ();

        this.completer = new QCompleter (this);
        this.completer_model = new ShareeModel (this.account,
            this.is_file ? QLatin1String ("file") : QLatin1String ("folder"),
            this.completer);
        connect (this.completer_model, ShareeModel.signal_sharees_ready, this, ShareUserGroupWidget.on_signal_sharees_ready);
        connect (this.completer_model, ShareeModel.signal_display_error_message, this, ShareUserGroupWidget.on_signal_display_error);

        this.completer.model (this.completer_model);
        this.completer.case_sensitivity (Qt.CaseInsensitive);
        this.completer.completion_mode (QCompleter.Unfiltered_popup_completion);
        this.ui.sharee_line_edit.completer (this.completer);

        var search_globally_action = new QAction (this.ui.sharee_line_edit);
        search_globally_action.icon (Gtk.Icon (":/client/theme/magnifying-glass.svg"));
        search_globally_action.tool_tip (_("Search globally"));

        connect (
            search_globally_action,
            QAction.triggered,
            this,
            this.on_search_globally_action
        );

        this.ui.sharee_line_edit.add_action (search_globally_action, QLineEdit.Leading_position);

        this.manager = new ShareManager (this.account, this);
        connect (this.manager, ShareManager.on_signal_shares_fetched, this, ShareUserGroupWidget.on_signal_shares_fetched);
        connect (this.manager, ShareManager.signal_share_created, this, ShareUserGroupWidget.on_signal_share_created);
        connect (this.manager, ShareManager.on_signal_server_error, this, ShareUserGroupWidget.on_signal_display_error);
        connect (this.ui.sharee_line_edit, QLineEdit.return_pressed, this, ShareUserGroupWidget.on_signal_line_edit_return);
        connect (this.ui.confirm_share, QAbstractButton.clicked, this, ShareUserGroupWidget.on_signal_line_edit_return);
        // TODO connect (this.ui.private_link_text, Gtk.Label.link_activated, this, ShareUserGroupWidget.on_signal_private_link_share);

        // By making the next two Queued_connections we can override
        // the strings the completer sets on the line edit.
        connect (this.completer, SIGNAL (activated (QModelIndex)), SLOT (on_signal_completer_activated (QModelIndex)),
            Qt.QueuedConnection);
        connect (this.completer, SIGNAL (highlighted (QModelIndex)), SLOT (on_signal_completer_highlighted (QModelIndex)),
            Qt.QueuedConnection);

        // Queued connection so this signal is recieved after text_changed
        connect (this.ui.sharee_line_edit, QLineEdit.text_edited,
            this, ShareUserGroupWidget.on_signal_line_edit_text_edited, Qt.QueuedConnection);
        this.ui.sharee_line_edit.install_event_filter (this);
        connect (
            this.completion_timer,
            QTimer.timeout,
            this,
            this.on_completion_timer);
        this.completion_timer.single_shot (true);
        this.completion_timer.interval (600);

        this.ui.error_label.hide ();

        // TODO Progress Indicator where should it go?
        // Setup the sharee search progress indicator
        //this.ui.sharee_horizontal_layout.add_widget (this.pi_sharee);

        this.parent_scroll_area = parent_widget ().find_child<QScroll_area> ("scroll_area");

        customize_style ();
    }


    private void on_search_globally_action () {
        on_signal_search_for_sharees (ShareeModel.LookupMode.GLOBAL_SEARCH);
    }


    private void on_completion_timer () {
        on_signal_search_for_sharees (ShareeModel.LookupMode.LOCAL_SEARCH);
    }


    override ~ShareUserGroupWidget () {
        delete this.ui;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_get_shares () {
        this.manager.fetch_shares (this.share_path);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_share_created (unowned Share share) {
        if (share && this.account.capabilities ().share_email_password_enabled () && !this.account.capabilities ().share_email_password_enforced ()) {
            // remember this share Id so we can set it's password Line Edit to focus later
            this.last_created_share_id = share.identifier ();
        }
        // fetch all shares including the one we've just created
        on_signal_get_shares ();
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();

        // Notify the other widgets (ShareUserLine in this case, Dark-/Light-Mode switching)
        /* emit */ signal_style_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (GLib.List<unowned Share> shares) {
        QScroll_area scroll_area = this.parent_scroll_area;

        var new_view_port = new Gtk.Widget (scroll_area);
        var layout = new QVBoxLayout (new_view_port);
        layout.contents_margins (0, 0, 0, 0);
        int x = 0;
        int height = 0;
        GLib.List<string> link_owners = new GLib.List<string> ();

        ShareUserLine just_created_share_that_needs_password;

        foreach (var share in shares) {
            // We don't handle link shares, only Share.Type.USER or Share.Type.GROUP
            if (share.share_type () == Share.Type.LINK) {
                if (!share.owner_uid () == "" &&
                        share.owner_uid () != share.account.dav_user ()) {
                    link_owners.append (share.owner_display_name ());
                 }
                continue;
            }

            // the owner of the file that shared it first
            // leave out if it's the current user
            if (x == 0 && !share.owner_uid () == "" && ! (share.owner_uid () == this.account.credentials ().user ())) {
                this.ui.main_owner_label.on_signal_text (string ("SharedFlag.SHARED with you by ").append (share.owner_display_name ()));
            }

            //  Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share.share_type ()));
            var user_group_share = q_shared_pointer_dynamic_cast<UserGroupShare> (share);
            var s = new ShareUserLine (this.account, user_group_share, this.max_sharing_permissions, this.is_file, this.parent_scroll_area);
            connect (s, ShareUserLine.resize_requested, this, ShareUserGroupWidget.on_signal_adjust_scroll_widget_size);
            connect (s, ShareUserLine.visual_deletion_done, this, ShareUserGroupWidget.on_signal_get_shares);
            s.background_role (layout.count () % 2 == 0 ? QPalette.Base : QPalette.Alternate_base);

            // Connect signal_style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            connect (this, ShareUserGroupWidget.signal_style_changed, s, ShareUserLine.on_signal_style_changed);

            layout.add_widget (s);

            if (!this.last_created_share_id == "" && share.identifier () == this.last_created_share_id) {
                this.last_created_share_id = "";
                if (this.account.capabilities ().share_email_password_enabled () && !this.account.capabilities ().share_email_password_enforced ()) {
                    just_created_share_that_needs_password = s;
                }
            }

            x++;
            if (x <= 3) {
                height = new_view_port.size_hint ().height ();
            }
        }

        foreach (string owner in link_owners) {
            var owner_label = new Gtk.Label (string (owner + " shared via link"));
            layout.add_widget (owner_label);
            owner_label.visible (true);

            x++;
            if (x <= 6) {
                height = new_view_port.size_hint ().height ();
            }
        }

        scroll_area.frame_shape (x > 6 ? Gdk.Frame.Styled_panel : Gdk.Frame.No_frame);
        scroll_area.visible (!shares == "");
        scroll_area.fixed_height (height);
        scroll_area.widget (new_view_port);

        this.disable_completer_activated = false;
        activate_sharee_line_edit ();

        if (just_created_share_that_needs_password) {
            // always set focus to a password Line Edit when the new email share is created on a server with optional passwords enabled for email shares
            just_created_share_that_needs_password.on_signal_focus_password_line_edit ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sharee_line_edit_text_changed (string text) {
        this.completion_timer.stop ();
        /* emit */ signal_toggle_public_link_share (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_search_for_sharees (ShareeModel.LookupMode lookup_mode) {
        if (this.ui.sharee_line_edit.text () == "") {
            return;
        }

        this.ui.sharee_line_edit.enabled (false);
        this.completion_timer.stop ();
        this.pi_sharee.on_signal_start_animation ();
        ShareeModel.ShareeSet blocklist;

        // Add the current user to this.sharees since we can't share with ourself
        unowned Sharee current_user = new Sharee (this.account.credentials ().user (), "", Sharee.Type.USER);
        blocklist += current_user;

        foreach (var share_widget in this.parent_scroll_area.find_children<ShareUserLine> ()) {
            blocklist += share_widget.share ().share_with ();
        }
        this.ui.error_label.hide ();
        this.completer_model.fetch (this.ui.sharee_line_edit.text (), blocklist, lookup_mode);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_line_edit_text_edited (string text) {
        this.disable_completer_activated = false;
        // First text_changed is called first and we stopped the timer when the text is changed, programatically or not
        // Then we restart the timer here if the user touched a key
        if (!text == "") {
            this.completion_timer.on_signal_start ();
            /* emit */ signal_toggle_public_link_share (true);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_line_edit_return () {
        this.disable_completer_activated = false;
        // did the user type in one of the options?
        const var text = this.ui.sharee_line_edit.text ();
        for (int i = 0; i < this.completer_model.row_count (); ++i) {
            const var sharee = this.completer_model.sharee (i);
            if (sharee.to_string () == text
                || sharee.display_name () == text
                || sharee.share_with () == text) {
                on_signal_completer_activated (this.completer_model.index (i));
                // make sure we do not send the same item twice (because return is called when we press
                // return to activate an item inthe completer)
                this.disable_completer_activated = true;
                return;
            }
        }

        // nothing found? try to refresh completion
        this.completion_timer.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_completer_activated (QModelIndex index) {
        if (this.disable_completer_activated)
            return;
        // The index is an index from the QCompletion model which is itelf a proxy
        // model proxying the this.completer_model
        var sharee = qvariant_cast<unowned Sharee> (index.data (Qt.USER_ROLE));
        if (sharee.is_null ()) {
            return;
        }

    // TODO Progress Indicator where should it go?
    //    var indicator = new QProgressIndicator (view_port);
    //    indicator.on_signal_start_animation ();
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

        this.last_created_share_id = "";

        string password;
        if (sharee.type () == Sharee.Type.EMAIL && this.account.capabilities ().share_email_password_enforced ()) {
            this.ui.sharee_line_edit.clear ();
            // always show a dialog for password-enforced email shares
            bool ok = false;

            do {
                password = QInputDialog.text (
                    this,
                    _("Password for share required"),
                    _("Please enter a password for your email share:"),
                    QLineEdit.Password,
                    "",
                    ok);
            } while (password == "" && ok);

            if (!ok) {
                return;
            }
        }

        this.manager.create_share (this.share_path, Share.Type (sharee.type ()),
            sharee.share_with (), this.max_sharing_permissions, password);

        this.ui.sharee_line_edit.enabled (false);
        this.ui.sharee_line_edit.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_completer_highlighted (QModelIndex index) {
        // By default the completer would set the text to EditRole,
        // override that here.
        this.ui.sharee_line_edit.on_signal_text (index.data (Qt.Display_role).to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sharees_ready () {
        activate_sharee_line_edit ();

        this.pi_sharee.on_signal_stop_animation ();
        if (this.completer_model.row_count () == 0) {
            on_signal_display_error (0, _("No results for \"%1\"").printf (this.completer_model.current_search ()));
        }

        // if no rows are present in the model - complete () will hide the completer
        this.completer.complete ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_adjust_scroll_widget_size () {
        QScroll_area scroll_area = this.parent_scroll_area;
        const ShareUserLine share_user_line_childs = scroll_area.find_children<ShareUserLine> ();

        // Ask the child widgets to calculate their size
        foreach (var share_user_line_child in share_user_line_childs) {
            share_user_line_child.adjust_size ();
        }

        const int share_user_line_childs_count = share_user_line_childs.count ();
        scroll_area.visible (share_user_line_childs_count > 0);
        if (share_user_line_childs_count > 0 && share_user_line_childs_count <= 3) {
            scroll_area.fixed_height (scroll_area.widget ().size_hint ().height ());
        }
        scroll_area.frame_shape (share_user_line_childs_count > 3 ? Gdk.Frame.Styled_panel : Gdk.Frame.No_frame);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_private_link_share () {
        var menu = new QMenu (this);
        menu.attribute (Qt.WA_DeleteOnClose);

        // this icon is not handled by on_signal_style_changed () . customize_style but we can live with that
        menu.add_action (
            Theme.create_color_aware_icon (":/client/theme/copy.svg"),
            _("Copy link"),
            this,
            on_signal_private_link_copy ()
        );

        menu.exec (QCursor.position ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_display_error (int code, string message) {
        this.pi_sharee.on_signal_stop_animation ();

        // Also remove the spinner in the widget list, if any
        foreach (var progress_indicator in this.parent_scroll_area.find_children<QProgressIndicator> ()) {
            delete progress_indicator;
        }

        GLib.warning ("Sharing error from server " + code + message);
        this.ui.error_label.on_signal_text (message);
        this.ui.error_label.show ();
        activate_sharee_line_edit ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_private_link_open_browser () {
        OpenExtrernal.open_browser (this.private_link_url, this);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_private_link_copy () {
        Gtk.Application.clipboard ().on_signal_text (this.private_link_url);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_private_link_email () {
        OpenExtrernal.open_email_composer (
            _("I shared something with you"),
            this.private_link_url,
            this);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        this.ui.confirm_share.icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

        this.pi_sharee.on_signal_color (Gtk.Application.palette ().color (QPalette.Text));

        foreach (var progress_indicator in this.parent_scroll_area.find_children<QProgressIndicator> ()) {
            progress_indicator.on_signal_color (Gtk.Application.palette ().color (QPalette.Text));;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void activate_sharee_line_edit () {
        this.ui.sharee_line_edit.enabled (true);
        this.ui.sharee_line_edit.focus ();
    }

} // class ShareUserGroupWidget

} // namespace Ui
} // namespace Occ
