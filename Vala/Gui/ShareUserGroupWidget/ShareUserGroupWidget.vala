/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include <QFile_icon_provider>
//  #include <QClipboard>
//  #include <QFileInfo>
//  #include <QAbstract_proxy_model>
//  #include <QCompleter>
//  #include <QBox_layout>
//  #include <QIcon>
//  #include <QLayout>
//  #include <QPropertyAnimation>
//  #include <QMenu>
//  #include <QAction>
//  #include <QDesktopServices>
//  #include <QInputDialog>
//  #include <QMessageBox>
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
//  #include <GLib.List>
//  #include <QTimer>
//  #include <qpushbutton.h>
//  #include <qscrollarea.h>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Share_dialog (user/group) class
@ingroup gui
***********************************************************/
class Share_user_group_widget : Gtk.Widget {

    const string password_is_set_placeholder = "●●●●●●●●";

    /***********************************************************
    ***********************************************************/
    public Share_user_group_widget (AccountPointer account,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const string private_link_url,
        Gtk.Widget parent = null);
    ~Share_user_group_widget () override;

signals:
    void toggle_public_link_share (bool);
    void style_changed ();

    /***********************************************************
    ***********************************************************/
    public void on_get_shares ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void on_style_changed ();


    /***********************************************************
    ***********************************************************/
    private void on_shares_fetched (GLib.List<unowned<Share>> shares);

    /***********************************************************
    ***********************************************************/
    private void on_sharee_line_edit_text_changed (string text);
    private void on_search_for_sharees (Sharee_model.Lookup_mode lookup_mode);
    private void on_line_edit_text_edited (string text);

    /***********************************************************
    ***********************************************************/
    private void on_line_edit_return ();
    private void on_completer_activated (QModelIndex index);
    private void on_completer_highlighted (QModelIndex index);
    private void on_sharees_ready ();
    private void on_adjust_scroll_widget_size ();
    private void on_private_link_share ();
    private void on_display_error (int code, string message);

    /***********************************************************
    ***********************************************************/
    private void on_private_link_open_browser ();
    private void on_private_link_copy ();
    private void on_private_link_email ();


    /***********************************************************
    ***********************************************************/
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private void activate_sharee_line_edit ();

    /***********************************************************
    ***********************************************************/
    private Ui.Share_user_group_widget this.ui;
    private QScroll_area this.parent_scroll_area;
    private AccountPointer this.account;
    private string this.share_path;
    private string this.local_path;
    private Share_permissions this.max_sharing_permissions;
    private string this.private_link_url;

    /***********************************************************
    ***********************************************************/
    private QCompleter this.completer;
    private Sharee_model this.completer_model;
    private QTimer this.completion_timer;

    /***********************************************************
    ***********************************************************/
    private bool this.is_file;
    private bool this.disable_completer_activated; // in order to avoid that we share the contents twice
    private Share_manager this.manager;

    /***********************************************************
    ***********************************************************/
    private QProgress_indicator this.pi_sharee;

    /***********************************************************
    ***********************************************************/
    private string this.last_created_share_id;
}




    Share_user_group_widget.Share_user_group_widget (AccountPointer account,
        const string share_path,
        const string local_path,
        Share_permissions max_sharing_permissions,
        const string private_link_url,
        Gtk.Widget parent)
        : Gtk.Widget (parent)
        this.ui (new Ui.Share_user_group_widget)
        this.account (account)
        this.share_path (share_path)
        this.local_path (local_path)
        this.max_sharing_permissions (max_sharing_permissions)
        this.private_link_url (private_link_url)
        this.disable_completer_activated (false) {
        set_attribute (Qt.WA_DeleteOnClose);
        set_object_name ("Sharing_dialog_uG"); // required as group for save_geometry call

        this.ui.setup_ui (this);

        //Is this a file or folder?
        this.is_file = QFileInfo (local_path).is_file ();

        this.completer = new QCompleter (this);
        this.completer_model = new Sharee_model (this.account,
            this.is_file ? QLatin1String ("file") : QLatin1String ("folder"),
            this.completer);
        connect (this.completer_model, &Sharee_model.sharees_ready, this, &Share_user_group_widget.on_sharees_ready);
        connect (this.completer_model, &Sharee_model.display_error_message, this, &Share_user_group_widget.on_display_error);

        this.completer.set_model (this.completer_model);
        this.completer.set_case_sensitivity (Qt.CaseInsensitive);
        this.completer.set_completion_mode (QCompleter.Unfiltered_popup_completion);
        this.ui.sharee_line_edit.set_completer (this.completer);

        var search_globally_action = new QAction (this.ui.sharee_line_edit);
        search_globally_action.set_icon (QIcon (":/client/theme/magnifying-glass.svg"));
        search_globally_action.set_tool_tip (_("Search globally"));

        connect (search_globally_action, &QAction.triggered, this, [this] () {
            on_search_for_sharees (Sharee_model.Global_search);
        });

        this.ui.sharee_line_edit.add_action (search_globally_action, QLineEdit.Leading_position);

        this.manager = new Share_manager (this.account, this);
        connect (this.manager, &Share_manager.on_shares_fetched, this, &Share_user_group_widget.on_shares_fetched);
        connect (this.manager, &Share_manager.share_created, this, &Share_user_group_widget.on_share_created);
        connect (this.manager, &Share_manager.on_server_error, this, &Share_user_group_widget.on_display_error);
        connect (this.ui.sharee_line_edit, &QLineEdit.return_pressed, this, &Share_user_group_widget.on_line_edit_return);
        connect (this.ui.confirm_share, &QAbstractButton.clicked, this, &Share_user_group_widget.on_line_edit_return);
        //TODO connect (this.ui.private_link_text, &QLabel.link_activated, this, &Share_user_group_widget.on_private_link_share);

        // By making the next two Queued_connections we can override
        // the strings the completer sets on the line edit.
        connect (this.completer, SIGNAL (activated (QModelIndex)), SLOT (on_completer_activated (QModelIndex)),
            Qt.QueuedConnection);
        connect (this.completer, SIGNAL (highlighted (QModelIndex)), SLOT (on_completer_highlighted (QModelIndex)),
            Qt.QueuedConnection);

        // Queued connection so this signal is recieved after text_changed
        connect (this.ui.sharee_line_edit, &QLineEdit.text_edited,
            this, &Share_user_group_widget.on_line_edit_text_edited, Qt.QueuedConnection);
        this.ui.sharee_line_edit.install_event_filter (this);
        connect (&this.completion_timer, &QTimer.timeout, this, [this] () {
            on_search_for_sharees (Sharee_model.Local_search);
        });
        this.completion_timer.set_single_shot (true);
        this.completion_timer.set_interval (600);

        this.ui.error_label.hide ();

        // TODO Progress Indicator where should it go?
        // Setup the sharee search progress indicator
        //this.ui.sharee_horizontal_layout.add_widget (&this.pi_sharee);

        this.parent_scroll_area = parent_widget ().find_child<QScroll_area> ("scroll_area");

        customize_style ();
    }

    Share_user_group_widget.~Share_user_group_widget () {
        delete this.ui;
    }

    void Share_user_group_widget.on_sharee_line_edit_text_changed (string ) {
        this.completion_timer.stop ();
        /* emit */ toggle_public_link_share (false);
    }

    void Share_user_group_widget.on_line_edit_text_edited (string text) {
        this.disable_completer_activated = false;
        // First text_changed is called first and we stopped the timer when the text is changed, programatically or not
        // Then we restart the timer here if the user touched a key
        if (!text.is_empty ()) {
            this.completion_timer.on_start ();
            /* emit */ toggle_public_link_share (true);
        }
    }

    void Share_user_group_widget.on_line_edit_return () {
        this.disable_completer_activated = false;
        // did the user type in one of the options?
        const var text = this.ui.sharee_line_edit.text ();
        for (int i = 0; i < this.completer_model.row_count (); ++i) {
            const var sharee = this.completer_model.get_sharee (i);
            if (sharee.format () == text
                || sharee.display_name () == text
                || sharee.share_with () == text) {
                on_completer_activated (this.completer_model.index (i));
                // make sure we do not send the same item twice (because return is called when we press
                // return to activate an item inthe completer)
                this.disable_completer_activated = true;
                return;
            }
        }

        // nothing found? try to refresh completion
        this.completion_timer.on_start ();
    }

    void Share_user_group_widget.on_search_for_sharees (Sharee_model.Lookup_mode lookup_mode) {
        if (this.ui.sharee_line_edit.text ().is_empty ()) {
            return;
        }

        this.ui.sharee_line_edit.set_enabled (false);
        this.completion_timer.stop ();
        this.pi_sharee.on_start_animation ();
        Sharee_model.Sharee_set blocklist;

        // Add the current user to this.sharees since we can't share with ourself
        unowned<Sharee> current_user (new Sharee (this.account.credentials ().user (), "", Sharee.Type.User));
        blocklist << current_user;

        foreach (var sw, this.parent_scroll_area.find_children<Share_user_line> ()) {
            blocklist << sw.share ().get_share_with ();
        }
        this.ui.error_label.hide ();
        this.completer_model.fetch (this.ui.sharee_line_edit.text (), blocklist, lookup_mode);
    }

    void Share_user_group_widget.on_get_shares () {
        this.manager.fetch_shares (this.share_path);
    }

    void Share_user_group_widget.on_share_created (unowned<Share> share) {
        if (share && this.account.capabilities ().share_email_password_enabled () && !this.account.capabilities ().share_email_password_enforced ()) {
            // remember this share Id so we can set it's password Line Edit to focus later
            this.last_created_share_id = share.get_id ();
        }
        // fetch all shares including the one we've just created
        on_get_shares ();
    }

    void Share_user_group_widget.on_shares_fetched (GLib.List<unowned<Share>> shares) {
        QScroll_area scroll_area = this.parent_scroll_area;

        var new_view_port = new Gtk.Widget (scroll_area);
        var layout = new QVBoxLayout (new_view_port);
        layout.set_contents_margins (0, 0, 0, 0);
        int x = 0;
        int height = 0;
        GLib.List<string> link_owners ({});

        Share_user_line just_created_share_that_needs_password = null;

        foreach (var share, shares) {
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
            if (x == 0 && !share.get_uid_owner ().is_empty () && ! (share.get_uid_owner () == this.account.credentials ().user ())) {
                this.ui.main_owner_label.on_set_text (string ("SharedFlag.SHARED with you by ").append (share.get_owner_display_name ()));
            }

            //  Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share.get_share_type ()));
            var user_group_share = q_shared_pointer_dynamic_cast<User_group_share> (share);
            var s = new Share_user_line (this.account, user_group_share, this.max_sharing_permissions, this.is_file, this.parent_scroll_area);
            connect (s, &Share_user_line.resize_requested, this, &Share_user_group_widget.on_adjust_scroll_widget_size);
            connect (s, &Share_user_line.visual_deletion_done, this, &Share_user_group_widget.on_get_shares);
            s.set_background_role (layout.count () % 2 == 0 ? QPalette.Base : QPalette.Alternate_base);

            // Connect style_changed events to our widget, so it can adapt (Dark-/Light-Mode switching)
            connect (this, &Share_user_group_widget.style_changed, s, &Share_user_line.on_style_changed);

            layout.add_widget (s);

            if (!this.last_created_share_id.is_empty () && share.get_id () == this.last_created_share_id) {
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

        foreach (string owner, link_owners) {
            var owner_label = new QLabel (string (owner + " shared via link"));
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

        this.disable_completer_activated = false;
        activate_sharee_line_edit ();

        if (just_created_share_that_needs_password) {
            // always set focus to a password Line Edit when the new email share is created on a server with optional passwords enabled for email shares
            just_created_share_that_needs_password.on_focus_password_line_edit ();
        }
    }

    void Share_user_group_widget.on_adjust_scroll_widget_size () {
        QScroll_area scroll_area = this.parent_scroll_area;
        const var share_user_line_childs = scroll_area.find_children<Share_user_line> ();

        // Ask the child widgets to calculate their size
        for (var share_user_line_child : share_user_line_childs) {
            share_user_line_child.adjust_size ();
        }

        const var share_user_line_childs_count = share_user_line_childs.count ();
        scroll_area.set_visible (share_user_line_childs_count > 0);
        if (share_user_line_childs_count > 0 && share_user_line_childs_count <= 3) {
            scroll_area.set_fixed_height (scroll_area.widget ().size_hint ().height ());
        }
        scroll_area.set_frame_shape (share_user_line_childs_count > 3 ? QFrame.Styled_panel : QFrame.No_frame);
    }

    void Share_user_group_widget.on_private_link_share () {
        var menu = new QMenu (this);
        menu.set_attribute (Qt.WA_DeleteOnClose);

        // this icon is not handled by on_style_changed () . customize_style but we can live with that
        menu.add_action (Theme.create_color_aware_icon (":/client/theme/copy.svg"),
                        _("Copy link"),
            this, SLOT (on_private_link_copy ()));

        menu.exec (QCursor.position ());
    }

    void Share_user_group_widget.on_sharees_ready () {
        activate_sharee_line_edit ();

        this.pi_sharee.on_stop_animation ();
        if (this.completer_model.row_count () == 0) {
            on_display_error (0, _("No results for \"%1\"").arg (this.completer_model.current_search ()));
        }

        // if no rows are present in the model - complete () will hide the completer
        this.completer.complete ();
    }

    void Share_user_group_widget.on_completer_activated (QModelIndex index) {
        if (this.disable_completer_activated)
            return;
        // The index is an index from the QCompletion model which is itelf a proxy
        // model proxying the this.completer_model
        var sharee = qvariant_cast<unowned<Sharee>> (index.data (Qt.User_role));
        if (sharee.is_null ()) {
            return;
        }

    // TODO Progress Indicator where should it go?
    //    var indicator = new QProgress_indicator (view_port);
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

        this.last_created_share_id = "";

        string password;
        if (sharee.type () == Sharee.Email && this.account.capabilities ().share_email_password_enforced ()) {
            this.ui.sharee_line_edit.clear ();
            // always show a dialog for password-enforced email shares
            bool ok = false;

            do {
                password = QInputDialog.get_text (
                    this,
                    _("Password for share required"),
                    _("Please enter a password for your email share:"),
                    QLineEdit.Password,
                    "",
                    ok);
            } while (password.is_empty () && ok);

            if (!ok) {
                return;
            }
        }

        this.manager.create_share (this.share_path, Share.Share_type (sharee.type ()),
            sharee.share_with (), this.max_sharing_permissions, password);

        this.ui.sharee_line_edit.set_enabled (false);
        this.ui.sharee_line_edit.clear ();
    }

    void Share_user_group_widget.on_completer_highlighted (QModelIndex index) {
        // By default the completer would set the text to EditRole,
        // override that here.
        this.ui.sharee_line_edit.on_set_text (index.data (Qt.Display_role).to_string ());
    }

    void Share_user_group_widget.on_display_error (int code, string message) {
        this.pi_sharee.on_stop_animation ();

        // Also remove the spinner in the widget list, if any
        foreach (var pi, this.parent_scroll_area.find_children<QProgress_indicator> ()) {
            delete pi;
        }

        GLib.warn (lc_sharing) << "Sharing error from server" << code << message;
        this.ui.error_label.on_set_text (message);
        this.ui.error_label.show ();
        activate_sharee_line_edit ();
    }

    void Share_user_group_widget.on_private_link_open_browser () {
        Utility.open_browser (this.private_link_url, this);
    }

    void Share_user_group_widget.on_private_link_copy () {
        QApplication.clipboard ().on_set_text (this.private_link_url);
    }

    void Share_user_group_widget.on_private_link_email () {
        Utility.open_email_composer (
            _("I shared something with you"),
            this.private_link_url,
            this);
    }

    void Share_user_group_widget.on_style_changed () {
        customize_style ();

        // Notify the other widgets (Share_user_line in this case, Dark-/Light-Mode switching)
        /* emit */ style_changed ();
    }

    void Share_user_group_widget.customize_style () {
        this.ui.confirm_share.set_icon (Theme.create_color_aware_icon (":/client/theme/confirm.svg"));

        this.pi_sharee.on_set_color (QGuiApplication.palette ().color (QPalette.Text));

        foreach (var pi, this.parent_scroll_area.find_children<QProgress_indicator> ()) {
            pi.on_set_color (QGuiApplication.palette ().color (QPalette.Text));;
        }
    }

    void Share_user_group_widget.activate_sharee_line_edit () {
        this.ui.sharee_line_edit.set_enabled (true);
        this.ui.sharee_line_edit.set_focus ();
    }

    }
    