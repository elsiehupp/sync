/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

//  #include <QStandard_item_model>
//  #include <QStacked_widget>
//  #include <QPushButton>
//  #include <QSettings>
//  #include <QToolBar>
//  #include <QToolButton>
//  #include <QLayout>
//  #include <QVBoxLayout>
//  #include <Gdk.Pixbuf>
//  #include <Gtk.Image>
//  #include <QWidgetAction>
//  #include <QPainter>
//  #include <QPainterPath>
//  #include <Gtk.Dialog>
//  #include <QStyled_item_delegate>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SettingsDialog class
@ingroup gui
***********************************************************/
public class SettingsDialog : Gtk.Dialog {

    class ToolButtonAction : QWidgetAction {

        /***********************************************************
        ***********************************************************/
        public ToolButtonAction (Gtk.Icon icon, string text, GLib.Object parent) {
            base (parent);
            on_signal_text (text);
            icon (icon);
        }


        /***********************************************************
        ***********************************************************/
        public override Gtk.Widget create_widget (Gtk.Widget parent) {
            var toolbar = qobject_cast<QToolBar> (parent);
            if (!toolbar) {
                // this means we are in the extention menu, no special action here
                return null;
            }

            var btn = new QToolButton (parent);
            string object_name = "settingsdialog_toolbutton_";
            object_name += text ();
            btn.object_name (object_name);

            btn.default_action (this);
            btn.tool_button_style (Qt.Tool_button_text_under_icon);
            btn.size_policy (QSizePolicy.Fixed, QSizePolicy.Expanding);
            return btn;
        }
    }

    /***********************************************************
    ***********************************************************/
    private const string TOOLBAR_CSS =
        "QToolBar { background : %1; margin : 0; padding : 0; border : none; border-bottom : 1px solid %2; spacing : 0; } "
        + "QToolBar QToolButton { background : %1; border : none; border-bottom : 1px solid %2; margin : 0; padding : 5px; } "
        + "QToolBar QTool_bar_extension { padding:0; } "
        + "QToolBar QToolButton:checked { background : %3; color : %4; }";

    /***********************************************************
    golden ratio
    ***********************************************************/
    const float BUTTON_SIZE_RATIO = 1.618f;

    /***********************************************************
    ***********************************************************/
    private GLib.ActionGroup action_group;

    /***********************************************************
    Maps the actions from the action group to the corresponding
    widgets
    ***********************************************************/
    private GLib.HashTable<QAction *, Gtk.Widget> action_group_widgets;

    /***********************************************************
    Maps the action in the dialog to their according account.
    Needed in case the account avatar changes.
    ***********************************************************/
    private GLib.HashTable<Account *, QAction> action_for_account;

    /***********************************************************
    ***********************************************************/
    private QToolBar tool_bar;

    /***********************************************************
    ***********************************************************/
    private OwncloudGui gui;

    internal signal void signal_style_changed ();
    internal signal void signal_activate ();

    /***********************************************************
    ***********************************************************/
    public SettingsDialog (OwncloudGui gui, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui = new Ui.SettingsDialog ();
        this.gui = gui;
        ConfigFile config;

        this.ui.up_ui (this);
        this.tool_bar = new QToolBar ();
        this.tool_bar.icon_size (QSize (32, 32));
        this.tool_bar.tool_button_style (Qt.Tool_button_text_under_icon);
        layout ().menu_bar (this.tool_bar);

        // People perceive this as a Window, so also make Ctrl+W work
        var close_window_action = new QAction (this);
        close_window_action.shortcut (QKeySequence ("Ctrl+W"));
        close_window_action.triggered.connect (
            this.accept
        );
        add_action (close_window_action);

        object_name ("Settings"); // required as group for save_geometry call

        // : This name refers to the application name e.g Nextcloud
        window_title (_("%1 Settings").printf (Theme.app_name_gui));

        AccountManager.instance.signal_account_added.connect (
            this.signal_account_added
        );
        AccountManager.instance.on_signal_account_removed.connect (
            this.on_signal_account_removed
        );

        this.action_group = new GLib.ActionGroup (this);
        this.action_group.exclusive (true);
        this.action_group.triggered.connect (
            this.on_signal_switch_page
        );

        // Adds space between users + activities and general + network actions
        var spacer = new Gtk.Widget ();
        spacer.minimum_width (10);
        spacer.size_policy (QSizePolicy.Minimum_expanding, QSizePolicy.Minimum);
        this.tool_bar.add_widget (spacer);

        QAction general_action = create_color_aware_action (":/client/theme/settings.svg", _("General"));
        this.action_group.add_action (general_action);
        this.tool_bar.add_action (general_action);
        var general_settings = new GeneralSettings ();
        this.ui.stack.add_widget (general_settings);

        // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            general_settings.on_signal_style_changed
        );

        QAction network_action = create_color_aware_action (":/client/theme/network.svg", _("Network"));
        this.action_group.add_action (network_action);
        this.tool_bar.add_action (network_action);
        var network_settings = new NetworkSettings ();
        this.ui.stack.add_widget (network_settings);

        this.action_group_widgets.insert (general_action, general_settings);
        this.action_group_widgets.insert (network_action, network_settings);

        foreach (var account_instance in AccountManager.instance.accounts) {
            signal_account_added (account_instance);
        }

        GLib.Timeout.single_shot (1, this, SettingsDialog.show_first_page);

        var show_log_window = new QAction (this);
        show_log_window.shortcut (QKeySequence ("F12"));
        show_log_window.triggered.connect (
            gui.on_signal_toggle_log_browser
        );
        add_action (show_log_window);

        var show_log_window2 = new QAction (this);
        show_log_window2.shortcut (QKeySequence (Qt.CTRL + Qt.Key_L));
        show_log_window2.triggered.connect (
            gui.on_signal_toggle_log_browser
        );
        add_action (show_log_window2);

        this.on_signal_activate.connect (
            gui.on_signal_settings_dialog_activated
        );

        customize_style ();

        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        config.restore_geometry (this);
    }


    ~SettingsDialog () {
        delete this.ui;
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Widget current_page () {
        return this.ui.stack.current_widget ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_switch_page (QAction action) {
        this.ui.stack.current_widget (this.action_group_widgets.value (action));
    }


    /***********************************************************
    ***********************************************************/
    public void show_first_page () {
        GLib.List<QAction> actions = this.tool_bar.actions ();
        if (!actions.empty ()) {
            actions.first ().trigger ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_issues_list (AccountState account) {
        const var user_model = UserModel.instance;
        const var identifier = user_model.find_identifier_for_account (account);
        UserModel.instance.switch_current_user (identifier);
        /* emit */ Systray.instance.show_window ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_account_avatar_changed () {
        var account = static_cast<Account> (sender ());
        if (account && this.action_for_account.contains (account)) {
            QAction action = this.action_for_account[account];
            if (action) {
                Gtk.Image pix = account.avatar ();
                if (!pix == null) {
                    action.icon (Gdk.Pixbuf.from_image (AvatarJob.make_circular_avatar (pix)));
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_account_display_name_changed () {
        var account = static_cast<Account> (sender ());
        if (account && this.action_for_account.contains (account)) {
            QAction action = this.action_for_account[account];
            if (action) {
                string display_name = account.display_name;
                action.on_signal_text (display_name);
                var height = this.tool_bar.size_hint ().height ();
                action.icon_text (short_display_name_for_settings (account, static_cast<int> (height * BUTTON_SIZE_RATIO)));
            }
        }
    }


    /***********************************************************
    Close event is not being called here
    ***********************************************************/
    protected override void reject () {
        ConfigFile config;
        config.save_geometry (this);
        Gtk.Dialog.reject ();
    }


    /***********************************************************
    ***********************************************************/
    protected override void on_signal_accept () {
        ConfigFile config;
        config.save_geometry (this);
        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    protected override void change_event (QEvent e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customize_style ();

            // Notify the other widgets (Dark-/Light-Mode switching)
            /* emit */ signal_style_changed ();
            break;
        case QEvent.ActivationChange:
            if (is_active_window ())
                /* emit */ activate ();
            break;
        default:
            break;
        }

        Gtk.Dialog.change_event (e);
    }


    /***********************************************************
    ***********************************************************/
    private void signal_account_added (AccountState account_state) {
        var height = this.tool_bar.size_hint ().height ();
        bool branding_single_account = !Theme.multi_account;

        QAction account_action = null;
        Gtk.Image avatar = account_state.account.avatar ();
        const string action_text = branding_single_account ? _("Account") : account_state.account.display_name;
        if (avatar == null) {
            account_action = create_color_aware_action (":/client/theme/account.svg",
                action_text);
        } else {
            Gtk.Icon icon = new Gtk.Icon (Gdk.Pixbuf.from_image (AvatarJob.make_circular_avatar (avatar)));
            account_action = create_action_with_icon (icon, action_text);
        }

        if (!branding_single_account) {
            account_action.tool_tip (account_state.account.display_name);
            account_action.icon_text (short_display_name_for_settings (account_state.account, static_cast<int> (height * BUTTON_SIZE_RATIO)));
        }

        this.tool_bar.insert_action (this.tool_bar.actions ().at (0), account_action);
        var account_settings = new AccountSettings (account_state, this);
        string object_name = "account_settings_";
        object_name += account_state.account.display_name;
        account_settings.object_name (object_name);
        this.ui.stack.insert_widget (0 , account_settings);

        this.action_group.add_action (account_action);
        this.action_group_widgets.insert (account_action, account_settings);
        this.action_for_account.insert (account_state.account, account_action);
        account_action.trigger ();

        account_settings.signal_folder_changed.connect (
            this.gui.on_signal_folders_changed
        );
        account_settings.signal_open_folder_alias.connect (
            this.gui.on_signal_folder_open_action
        );
        account_settings.signal_show_issues_list.connect (
            this.on_signal_show_issues_list
        );
        account_state.account.account_changed_avatar.connect (
            this.on_signal_account_avatar_changed
        );
        account_state.account.account_changed_display_name.connect (
            this.on_signal_account_display_name_changed
        );

        // Connect signal_style_changed event, to adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            account_settings.on_signal_style_changed
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_removed (AccountState account_state) {
        for (var it = this.action_group_widgets.begin (); it != this.action_group_widgets.end (); ++it) {
            var as = qobject_cast<AccountSettings> (*it);
            if (!as) {
                continue;
            }
            if (as.on_signal_accounts_state () == account_state) {
                this.tool_bar.remove_action (it.key ());

                if (this.ui.stack.current_widget () == it.value ()) {
                    show_first_page ();
                }

                it.key ().delete_later ();
                it.value ().delete_later ();
                this.action_group_widgets.erase (it);
                break;
            }
        }

        if (this.action_for_account.contains (account_state.account)) {
            this.action_for_account.remove (account_state.account);
        }

        // Hide when the last account is deleted. We want to enter the same
        // state we'd be in the client was started up without an account
        // configured.
        if (AccountManager.instance.accounts == "") {
            hide ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        string highlight_color = palette ().highlight ().color ().name ();
        string highlight_text_color = palette ().highlighted_text ().color ().name ();
        string dark = palette ().dark ().color ().name ();
        string background = palette ().base ().color ().name ();
        this.tool_bar.style_sheet (TOOLBAR_CSS ().printf (background, dark, highlight_color, highlight_text_color));

        foreach (QAction a in this.action_group.actions ()) {
            Gtk.Icon icon = Theme.create_color_aware_icon (a.property ("icon_path").to_string (), palette ());
            a.icon (icon);
            var btn = qobject_cast<QToolButton> (this.tool_bar.widget_for_action (a));
            if (btn) {
                btn.icon (icon);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private QAction create_color_aware_action (string icon_name, string filename) {
        // all buttons must have the same size in order to keep a good layout
        Gtk.Icon colored_icon = Theme.create_color_aware_icon (icon_path, palette ());
        return create_action_with_icon (colored_icon, filename, icon_path);
    }


    /***********************************************************
    ***********************************************************/
    private QAction create_action_with_icon (Gtk.Icon icon, string text, string icon_path) {
        QAction action = new ToolButtonAction (icon, text, this);
        action.checkable (true);
        if (!icon_path == "") {
            action.property ("icon_path", icon_path);
        }
        return action;
    }


    /***********************************************************
    Display name with two lines that is displayed in the
    settings. If width is bigger than 0, the string will be
    ellided so it does not exceed that width.
    ***********************************************************/
    private static string short_display_name_for_settings (Account account, int width) {
        string user = account.dav_display_name ();
        if (user == "") {
            user = account.credentials ().user ();
        }
        string host = account.url.host ();
        int port = account.url.port ();
        if (port > 0 && port != 80 && port != 443) {
            host.append (':');
            host.append (string.number (port));
        }
        if (width > 0) {
            QFont f;
            QFontMetrics font_metrics = new QFontMetrics (f);
            host = font_metrics.elided_text (host, Qt.Elide_middle, width);
            user = font_metrics.elided_text (user, Qt.Elide_right, width);
        }
        return "%1\n%2".printf (user, host);
    }

} // class SettingsDialog

} // namespace Ui
} // namespace Occ
    