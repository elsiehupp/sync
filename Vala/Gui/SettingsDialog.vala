/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLabel>
// #include <QStandard_item_model>
// #include <QStacked_widget>
// #include <QPushButton>
// #include <QSettings>
// #include <QTool_bar>
// #include <QToolButton>
// #include <QLayout>
// #include <QVBoxLayout>
// #include <QPixmap>
// #include <QImage>
// #include <QWidget_action>
// #include <QPainter>
// #include <QPainterPath>

// #include <Gtk.Dialog>
// #include <QStyled_item_delegate>

class QStandard_item_model;


namespace {
    const string TOOLBAR_CSS () {
        return QStringLiteral ("QTool_bar { background : %1; margin : 0; padding : 0; border : none; border-bottom : 1px solid %2; spacing : 0; } "
                               "QTool_bar QToolButton { background : %1; border : none; border-bottom : 1px solid %2; margin : 0; padding : 5px; } "
                               "QTool_bar QTool_bar_extension { padding:0; } "
                               "QTool_bar QToolButton:checked { background : %3; color : %4; }");
    }

    const float button_size_ratio = 1.618f; // golden ratio

    /***********************************************************
    display name with two lines that is displayed in the settings
    If width is bigger than 0, the string will be ellided so it does not exceed that width
    ***********************************************************/
    string short_display_name_for_settings (Occ.Account account, int width) {
        string user = account.dav_display_name ();
        if (user.is_empty ()) {
            user = account.credentials ().user ();
        }
        string host = account.url ().host ();
        int port = account.url ().port ();
        if (port > 0 && port != 80 && port != 443) {
            host.append (':');
            host.append (string.number (port));
        }
        if (width > 0) {
            QFont f;
            QFontMetrics fm (f);
            host = fm.elided_text (host, Qt.Elide_middle, width);
            user = fm.elided_text (user, Qt.Elide_right, width);
        }
        return QStringLiteral ("%1\n%2").arg (user, host);
    }
}

namespace Occ {


namespace Ui {
    class SettingsDialog;
}
class OwncloudGui;

/***********************************************************
@brief The SettingsDialog class
@ingroup gui
***********************************************************/
class SettingsDialog : Gtk.Dialog {
    Q_PROPERTY (Gtk.Widget* current_page READ current_page)

    /***********************************************************
    ***********************************************************/
    public SettingsDialog (OwncloudGui gui, Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public on_ void show_issues_list (AccountStat

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void on_account_avatar_changed ();


    public void on_account_display_name_changed ();

signals:
    void style_changed ();
    void on_activate ();


    protected void reject () override;
    protected void on_accept () override;
    protected void change_event (QEvent *) override;


    /***********************************************************
    ***********************************************************/
    private void on_account_added (AccountState *);
    private void on_account_removed (AccountState *);


    /***********************************************************
    ***********************************************************/
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private QAction create_color_aware_action (string icon_name, string filename);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private QAction_group this.action_group;
    // Maps the actions from the action group to the corresponding widgets
    private GLib.HashMap<QAction *, Gtk.Widget> this.action_group_widgets;

    // Maps the action in the dialog to their according account. Needed in
    // case the account avatar changes
    private GLib.HashMap<Account *, QAction> this.action_for_account;

    /***********************************************************
    ***********************************************************/
    private QTool_bar this.tool_bar;

    /***********************************************************
    ***********************************************************/
    private OwncloudGui this.gui;
};


    SettingsDialog.SettingsDialog (OwncloudGui gui, Gtk.Widget parent)
        : Gtk.Dialog (parent)
        , this.ui (new Ui.SettingsDialog)
        , this.gui (gui) {
        ConfigFile cfg;

        this.ui.setup_ui (this);
        this.tool_bar = new QTool_bar;
        this.tool_bar.set_icon_size (QSize (32, 32));
        this.tool_bar.set_tool_button_style (Qt.Tool_button_text_under_icon);
        layout ().set_menu_bar (this.tool_bar);

        // People perceive this as a Window, so also make Ctrl+W work
        var close_window_action = new QAction (this);
        close_window_action.set_shortcut (QKeySequence ("Ctrl+W"));
        connect (close_window_action, &QAction.triggered, this, &SettingsDialog.accept);
        add_action (close_window_action);

        set_object_name ("Settings"); // required as group for save_geometry call

        // : This name refers to the application name e.g Nextcloud
        set_window_title (_("%1 Settings").arg (Theme.instance ().app_name_gui ()));

        connect (AccountManager.instance (), &AccountManager.on_account_added,
            this, &SettingsDialog.on_account_added);
        connect (AccountManager.instance (), &AccountManager.on_account_removed,
            this, &SettingsDialog.on_account_removed);

        this.action_group = new QAction_group (this);
        this.action_group.set_exclusive (true);
        connect (this.action_group, &QAction_group.triggered, this, &SettingsDialog.on_switch_page);

        // Adds space between users + activities and general + network actions
        var spacer = new Gtk.Widget ();
        spacer.set_minimum_width (10);
        spacer.set_size_policy (QSize_policy.Minimum_expanding, QSize_policy.Minimum);
        this.tool_bar.add_widget (spacer);

        QAction general_action = create_color_aware_action (QLatin1String (":/client/theme/settings.svg"), _("General"));
        this.action_group.add_action (general_action);
        this.tool_bar.add_action (general_action);
        var general_settings = new General_settings;
        this.ui.stack.add_widget (general_settings);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &SettingsDialog.style_changed, general_settings, &General_settings.on_style_changed);

        QAction network_action = create_color_aware_action (QLatin1String (":/client/theme/network.svg"), _("Network"));
        this.action_group.add_action (network_action);
        this.tool_bar.add_action (network_action);
        var network_settings = new Network_settings;
        this.ui.stack.add_widget (network_settings);

        this.action_group_widgets.insert (general_action, general_settings);
        this.action_group_widgets.insert (network_action, network_settings);

        foreach (var ai, AccountManager.instance ().accounts ()) {
            on_account_added (ai.data ());
        }

        QTimer.single_shot (1, this, &SettingsDialog.show_first_page);

        var show_log_window = new QAction (this);
        show_log_window.set_shortcut (QKeySequence ("F12"));
        connect (show_log_window, &QAction.triggered, gui, &OwncloudGui.on_toggle_log_browser);
        add_action (show_log_window);

        var show_log_window2 = new QAction (this);
        show_log_window2.set_shortcut (QKeySequence (Qt.CTRL + Qt.Key_L));
        connect (show_log_window2, &QAction.triggered, gui, &OwncloudGui.on_toggle_log_browser);
        add_action (show_log_window2);

        connect (this, &SettingsDialog.on_activate, gui, &OwncloudGui.on_settings_dialog_activated);

        customize_style ();

        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        cfg.restore_geometry (this);
    }

    SettingsDialog.~SettingsDialog () {
        delete this.ui;
    }

    Gtk.Widget* SettingsDialog.current_page () {
        return this.ui.stack.current_widget ();
    }

    // close event is not being called here
    void SettingsDialog.reject () {
        ConfigFile cfg;
        cfg.save_geometry (this);
        Gtk.Dialog.reject ();
    }

    void SettingsDialog.on_accept () {
        ConfigFile cfg;
        cfg.save_geometry (this);
        Gtk.Dialog.on_accept ();
    }

    void SettingsDialog.change_event (QEvent e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customize_style ();

            // Notify the other widgets (Dark-/Light-Mode switching)
            /* emit */ style_changed ();
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

    void SettingsDialog.on_switch_page (QAction action) {
        this.ui.stack.set_current_widget (this.action_group_widgets.value (action));
    }

    void SettingsDialog.show_first_page () {
        GLib.List<QAction> actions = this.tool_bar.actions ();
        if (!actions.empty ()) {
            actions.first ().trigger ();
        }
    }

    void SettingsDialog.show_issues_list (AccountState account) {
        const var user_model = User_model.instance ();
        const var id = user_model.find_user_id_for_account (account);
        User_model.instance ().switch_current_user (id);
        /* emit */ Systray.instance ().show_window ();
    }

    void SettingsDialog.on_account_added (AccountState s) {
        var height = this.tool_bar.size_hint ().height ();
        bool branding_single_account = !Theme.instance ().multi_account ();

        QAction account_action = nullptr;
        QImage avatar = s.account ().avatar ();
        const string action_text = branding_single_account ? _("Account") : s.account ().display_name ();
        if (avatar.is_null ()) {
            account_action = create_color_aware_action (QLatin1String (":/client/theme/account.svg"),
                action_text);
        } else {
            QIcon icon (QPixmap.from_image (AvatarJob.make_circular_avatar (avatar)));
            account_action = create_action_with_icon (icon, action_text);
        }

        if (!branding_single_account) {
            account_action.set_tool_tip (s.account ().display_name ());
            account_action.set_icon_text (short_display_name_for_settings (s.account ().data (), static_cast<int> (height * button_size_ratio)));
        }

        this.tool_bar.insert_action (this.tool_bar.actions ().at (0), account_action);
        var account_settings = new AccountSettings (s, this);
        string object_name = QLatin1String ("account_settings_");
        object_name += s.account ().display_name ();
        account_settings.set_object_name (object_name);
        this.ui.stack.insert_widget (0 , account_settings);

        this.action_group.add_action (account_action);
        this.action_group_widgets.insert (account_action, account_settings);
        this.action_for_account.insert (s.account ().data (), account_action);
        account_action.trigger ();

        connect (account_settings, &AccountSettings.folder_changed, this.gui, &OwncloudGui.on_folders_changed);
        connect (account_settings, &AccountSettings.open_folder_alias,
            this.gui, &OwncloudGui.on_folder_open_action);
        connect (account_settings, &AccountSettings.show_issues_list, this, &SettingsDialog.show_issues_list);
        connect (s.account ().data (), &Account.account_changed_avatar, this, &SettingsDialog.on_account_avatar_changed);
        connect (s.account ().data (), &Account.account_changed_display_name, this, &SettingsDialog.on_account_display_name_changed);

        // Connect style_changed event, to adapt (Dark-/Light-Mode switching)
        connect (this, &SettingsDialog.style_changed, account_settings, &AccountSettings.on_style_changed);
    }

    void SettingsDialog.on_account_avatar_changed () {
        var account = static_cast<Account> (sender ());
        if (account && this.action_for_account.contains (account)) {
            QAction action = this.action_for_account[account];
            if (action) {
                QImage pix = account.avatar ();
                if (!pix.is_null ()) {
                    action.set_icon (QPixmap.from_image (AvatarJob.make_circular_avatar (pix)));
                }
            }
        }
    }

    void SettingsDialog.on_account_display_name_changed () {
        var account = static_cast<Account> (sender ());
        if (account && this.action_for_account.contains (account)) {
            QAction action = this.action_for_account[account];
            if (action) {
                string display_name = account.display_name ();
                action.on_set_text (display_name);
                var height = this.tool_bar.size_hint ().height ();
                action.set_icon_text (short_display_name_for_settings (account, static_cast<int> (height * button_size_ratio)));
            }
        }
    }

    void SettingsDialog.on_account_removed (AccountState s) {
        for (var it = this.action_group_widgets.begin (); it != this.action_group_widgets.end (); ++it) {
            var as = qobject_cast<AccountSettings> (*it);
            if (!as) {
                continue;
            }
            if (as.on_accounts_state () == s) {
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

        if (this.action_for_account.contains (s.account ().data ())) {
            this.action_for_account.remove (s.account ().data ());
        }

        // Hide when the last account is deleted. We want to enter the same
        // state we'd be in the client was started up without an account
        // configured.
        if (AccountManager.instance ().accounts ().is_empty ()) {
            hide ();
        }
    }

    void SettingsDialog.customize_style () {
        string highlight_color (palette ().highlight ().color ().name ());
        string highlight_text_color (palette ().highlighted_text ().color ().name ());
        string dark (palette ().dark ().color ().name ());
        string background (palette ().base ().color ().name ());
        this.tool_bar.set_style_sheet (TOOLBAR_CSS ().arg (background, dark, highlight_color, highlight_text_color));

        Q_FOREACH (QAction a, this.action_group.actions ()) {
            QIcon icon = Theme.create_color_aware_icon (a.property ("icon_path").to_string (), palette ());
            a.set_icon (icon);
            var btn = qobject_cast<QToolButton> (this.tool_bar.widget_for_action (a));
            if (btn)
                btn.set_icon (icon);
        }
    }

class Tool_button_action : QWidget_action {

    /***********************************************************
    ***********************************************************/
    public Tool_button_action (QIcon icon, string text, GLib.Object parent)
        : QWidget_action (parent) {
        on_set_text (text);
        set_icon (icon);
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Widget create_widget (Gtk.Widget parent) override {
        var toolbar = qobject_cast<QTool_bar> (parent);
        if (!toolbar) {
            // this means we are in the extention menu, no special action here
            return nullptr;
        }

        var btn = new QToolButton (parent);
        string object_name = QLatin1String ("settingsdialog_toolbutton_");
        object_name += text ();
        btn.set_object_name (object_name);

        btn.set_default_action (this);
        btn.set_tool_button_style (Qt.Tool_button_text_under_icon);
        btn.set_size_policy (QSize_policy.Fixed, QSize_policy.Expanding);
        return btn;
    }
};

    QAction *SettingsDialog.create_action_with_icon (QIcon icon, string text, string icon_path) {
        QAction action = new Tool_button_action (icon, text, this);
        action.set_checkable (true);
        if (!icon_path.is_empty ()) {
            action.set_property ("icon_path", icon_path);
        }
        return action;
    }

    QAction *SettingsDialog.create_color_aware_action (string icon_path, string text) {
        // all buttons must have the same size in order to keep a good layout
        QIcon colored_icon = Theme.create_color_aware_icon (icon_path, palette ());
        return create_action_with_icon (colored_icon, text, icon_path);
    }

    } // namespace Occ
    