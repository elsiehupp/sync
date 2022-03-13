/***********************************************************
Copyright (C) by Cédric Bellegarde <gnumdk@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QCursor>
//  #include <QGuiApplication>
//  #include <QQmlApplicationEngine>
//  #include <QQml_context>
//  #include <QQuick_window>
//  #include <Gdk.Screen>
//  #include <QMenu>

//  #ifdef USE_FDO_NOTIFICATIONS
//  #include <QDBusConnection>
//  #include <QDBusInterface>
//  #include <QDBus_message>
//  #include <QDBus_pending_call>
//  #endif

//  #include <QSystemTrayIcon>
//  #include <QQmlNetworkAccessManagerFactory>

namespace Occ {
namespace Ui {


/***********************************************************
@brief The Systray class
@ingroup gui
***********************************************************/
class Systray : QSystemTrayIcon {

    const int NOTIFICATIONS_SERVICE "org.freedesktop.Notifications"
    const int NOTIFICATIONS_PATH "/org/freedesktop/Notifications"
    const int NOTIFICATIONS_IFACE "org.freedesktop.Notifications"

    class AccessManagerFactory : QQmlNetworkAccessManagerFactory {

        /***********************************************************
        ***********************************************************/
        public AccessManagerFactory () {
            base ();
        }
    
        /***********************************************************
        ***********************************************************/
        public override QNetworkAccessManager create (GLib.Object parent) {
            return new AccessManager (parent);
        }
    }

    /***********************************************************
    ***********************************************************/
    public enum Task_bar_position {
        Bottom,
        Left,
        Top,
        Right
    }

    /***********************************************************
    ***********************************************************/
    private static Systray instance;

    /***********************************************************
    ***********************************************************/
    public static Systray instance () {
        if (!this.instance) {
            this.instance = new Systray ();
        }
        return this.instance;
    }

    /***********************************************************
    ***********************************************************/
    private bool is_open = false;
    private bool sync_is_paused = true;
    private QPointer<QQmlApplicationEngine> tray_engine;

    /***********************************************************
    ***********************************************************/
    private AccessManagerFactory access_manager_factory;


    signal void signal_current_user_changed ();
    signal void signal_open_account_wizard ();
    signal void signal_open_main_dialog ();
    signal void signal_open_settings ();
    signal void signal_open_help ();
    signal void signal_shutdown ();

    signal void hide_window ();
    signal void show_window ();
    signal void open_share_dialog (string share_path, string local_path);
    signal void show_file_activity_dialog (string share_path, string local_path);


    private Systray () {
        base ();
        qml_register_singleton_type<UserModel> ("com.nextcloud.desktopclient", 1, 0, "UserModel",
            [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
                return UserModel.instance ();
            }
        );

        qml_register_singleton_type<UserAppsModel> ("com.nextcloud.desktopclient", 1, 0, "UserAppsModel",
            [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
                return UserAppsModel.instance ();
            }
        );

        qml_register_singleton_type<Systray> ("com.nextcloud.desktopclient", 1, 0, "Theme",
            [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
                return Theme.instance ();
            }
        );

        qml_register_singleton_type<Systray> ("com.nextcloud.desktopclient", 1, 0, "Systray",
            [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
                return Systray.instance ();
            }
        );

        qml_register_type<WheelHandler> ("com.nextcloud.desktopclient", 1, 0, "WheelHandler");

        var context_menu = new QMenu ();
        if (AccountManager.instance ().accounts ().is_empty ()) {
            context_menu.add_action (_("Add account"), this, Systray.signal_open_account_wizard);
        } else {
            context_menu.add_action (_("Open main dialog"), this, Systray.signal_open_main_dialog);
        }

        var pause_action = context_menu.add_action (_("Pause sync"), this, Systray.on_signal_pause_all_folders);
        var resume_action = context_menu.add_action (_("Resume sync"), this, Systray.on_signal_unpause_all_folders);
        context_menu.add_action (_("Settings"), this, Systray.signal_open_settings);
        context_menu.add_action (_("Exit %1").arg (Theme.instance ().app_name_gui ()), this, Systray.signal_shutdown);
        context_menu (context_menu);

        connect (context_menu, QMenu.about_to_show, [=] {
            const var folders = FolderMan.instance ().map ();

            const var all_paused = std.all_of (std.cbegin (folders), std.cend (folders), [] (Folder f) {
                return f.sync_paused ();
            });
            const var pause_text = folders.size () > 1 ? _("Pause sync for all") : _("Pause sync");
            pause_action.on_signal_text (pause_text);
            pause_action.visible (!all_paused);
            pause_action.enabled (!all_paused);

            const var any_paused = std.any_of (std.cbegin (folders), std.cend (folders), [] (Folder f) {
                return f.sync_paused ();
            });
            const var resume_text = folders.size () > 1 ? _("Resume sync for all") : _("Resume sync");
            resume_action.on_signal_text (resume_text);
            resume_action.visible (any_paused);
            resume_action.enabled (any_paused);
        });

        connect (UserModel.instance (), UserModel.signal_new_user_selected,
            this, Systray.on_signal_new_user_selected);
        connect (UserModel.instance (), UserModel.signal_add_account,
                this, Systray.signal_open_account_wizard);

        connect (AccountManager.instance (), AccountManager.on_signal_account_added,
            this, Systray.show_window);
    }


    /***********************************************************
    ***********************************************************/
    public void tray_engine (QQmlApplicationEngine tray_engine) {
        this.tray_engine = tray_engine;

        this.tray_engine.network_access_manager_factory (this.access_manager_factory);

        this.tray_engine.add_import_path ("qrc:/qml/theme");
        this.tray_engine.add_ImageProvider ("avatars", new ImageProvider ());
        this.tray_engine.add_ImageProvider ("svgimage-custom-color", new Occ.Ui.SvgImageProvider);
        this.tray_engine.add_ImageProvider ("unified-search-result-icon", new UnifiedSearchResultImageProvider);
    }


    /***********************************************************
    ***********************************************************/
    public void create () {
        if (this.tray_engine) {
            if (!AccountManager.instance ().accounts ().is_empty ()) {
                this.tray_engine.root_context ().context_property ("activity_model", UserModel.instance ().current_activity_model ());
            }
            this.tray_engine.on_signal_load ("qrc:/qml/src/gui/tray/Window.qml");
        }
        hide_window ();
        /* emit */ activated (QSystemTrayIcon.Activation_reason.Unknown);

        const var folder_map = FolderMan.instance ().map ();
        for (var folder : folder_map) {
            if (!folder.sync_paused ()) {
                this.sync_is_paused = false;
                break;
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    public void show_message (string title, string message, Message_icon icon) {
        if (QDBusInterface (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE).is_valid ()) {
            const QVariantMap hints = {{"desktop-entry", LINUX_APPLICATION_ID}};
            GLib.List<GLib.Variant> args = GLib.List<GLib.Variant> () + APPLICATION_NAME + uint32 (0) + APPLICATION_ICON_NAME
                                                    + title + message + string[] () + hints + int32 (-1);
            QDBus_message method = QDBus_message.create_method_call (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE, "Notify");
            method.arguments (args);
            QDBusConnection.session_bus ().async_call (method);
        } else {
            QSystemTrayIcon.show_message (title, message, icon);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_open () {
        return this.is_open;
    }


    /***********************************************************
    ***********************************************************/
    public string window_title () {
        return Theme.instance ().app_name_gui ();
    }


    /***********************************************************
    ***********************************************************/
    public bool use_normal_window () {
        if (!is_system_tray_available ()) {
            return true;
        }

        ConfigFile config;
        return config.show_main_dialog_as_normal_window ();
    }

    /***********************************************************
    ***********************************************************/
    public void pause_resume_sync () {
        if (this.sync_is_paused) {
            this.sync_is_paused = false;
            on_signal_unpause_all_folders ();
        } else {
            this.sync_is_paused = true;
            on_signal_pause_all_folders ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void tool_tip (string tip) {
        QSystemTrayIcon.tool_tip (_("%1 : %2").arg (Theme.instance ().app_name_gui (), tip));
    }


    /***********************************************************
    ***********************************************************/
    public bool sync_is_paused () {
        return this.sync_is_paused;
    }


    /***********************************************************
    ***********************************************************/
    public void opened () {
        this.is_open = true;
    }


    /***********************************************************
    ***********************************************************/
    public void closed () {
        this.is_open = false;
    }


    /***********************************************************
    Helper functions for cross-platform tray icon position and
    taskbar orientation detection
    ***********************************************************/


    /***********************************************************
    ***********************************************************/
    public void position_window (QQuick_window window) {
        if (!use_normal_window ()) {
            window.screen (current_screen ());
            const var position = compute_window_position (window.width (), window.height ());
            window.position (position);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void force_window_init (QQuick_window window) {
        // HACK : At least on Windows, if the systray window is not shown at least once
        // it can prevent session handling to carry on properly, so we show/hide it here
        // this shouldn't flicker
        window.show ();
        window.hide ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_new_user_selected () {
        if (this.tray_engine) {
            // Change Activity_model
            this.tray_engine.root_context ().context_property ("activity_model", UserModel.instance ().current_activity_model ());
        }

        // Rebuild App list
        UserAppsModel.instance ().build_app_list ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_unpause_all_folders () {
        pause_on_signal_all_folders_helper (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_pause_all_folders () {
        pause_on_signal_all_folders_helper (true);
    }


    /***********************************************************
    ***********************************************************/
    private void pause_on_signal_all_folders_helper (bool pause) {
        // For some reason we get the raw pointer from Folder.account_state ()
        // that's why we need a list of raw pointers for the call to contains
        // later on...
        const var accounts = [=] {
            const var ptr_list = AccountManager.instance ().accounts ();
            var result = GLib.List<AccountState> ();
            result.reserve (ptr_list.size ());
            std.transform (std.cbegin (ptr_list), std.cend (ptr_list), std.back_inserter (result), [] (AccountStatePtr account) {
                return account.data ();
            });
            return result;
        } ();
        const var folders = FolderMan.instance ().map ();
        for (var f : folders) {
            if (accounts.contains (f.account_state ())) {
                f.sync_paused (pause);
                if (pause) {
                    f.on_signal_terminate_sync ();
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private Gdk.Screen current_screen () {
        const var screens = QGuiApplication.screens ();
        const var cursor_pos = QCursor.position ();

        for (var screen : screens) {
            if (screen.geometry ().contains (cursor_pos)) {
                return screen;
            }
        }

        // Didn't find anything matching the cursor position,
        // falling back to the primary screen
        return QGuiApplication.primary_screen ();
    }


    /***********************************************************
    ***********************************************************/
    private QRect current_screen_rect () {
        const var screen = current_screen ();
        //  Q_ASSERT (screen);
        return screen.geometry ();
    }


    /***********************************************************
    ***********************************************************/
    private QPoint compute_window_reference_point () {
        constexpr var spacing = 4;
        const var tray_icon_center = calc_tray_icon_center ();
        const var taskbar_rect = taskbar_geometry ();
        const var taskbar_screen_edge = taskbar_orientation ();
        const var screen_rect = current_screen_rect ();

        GLib.debug ("screen_rect:" + screen_rect;
        GLib.debug ("taskbar_rect:" + taskbar_rect;
        GLib.debug ("taskbar_screen_edge:" + taskbar_screen_edge;
        GLib.debug ("tray_icon_center:" + tray_icon_center;

        switch (taskbar_screen_edge) {
        case Task_bar_position.Bottom:
            return {
                tray_icon_center.x (),
                screen_rect.bottom () - taskbar_rect.height () - spacing
            }
        case Task_bar_position.Left:
            return {
                screen_rect.left () + taskbar_rect.width () + spacing,
                tray_icon_center.y ()
            }
        case Task_bar_position.Top:
            return {
                tray_icon_center.x (),
                screen_rect.top () + taskbar_rect.height () + spacing
            }
        case Task_bar_position.Right:
            return {
                screen_rect.right () - taskbar_rect.width () - spacing,
                tray_icon_center.y ()
            }
        }
        GLib.assert_not_reached ();
    }


    /***********************************************************
    ***********************************************************/
    private QPoint calc_tray_icon_center () {
        // On Linux, fall back to mouse position (assuming tray icon is activated by mouse click)
        return QCursor.position (current_screen ());
    }


    /***********************************************************
    ***********************************************************/
    private Task_bar_position taskbar_orientation () {
        const var screen_rect = current_screen_rect ();
        const var tray_icon_center = calc_tray_icon_center ();

        const var dist_bottom = screen_rect.bottom () - tray_icon_center.y ();
        const var dist_right = screen_rect.right () - tray_icon_center.x ();
        const var dist_left = tray_icon_center.x () - screen_rect.left ();
        const var dist_top = tray_icon_center.y () - screen_rect.top ();

        const var min_dist = std.min ({dist_right, dist_top, dist_bottom});

        if (min_dist == dist_bottom) {
            return Task_bar_position.Bottom;
        } else if (min_dist == dist_left) {
            return Task_bar_position.Left;
        } else if (min_dist == dist_top) {
            return Task_bar_position.Top;
        } else {
            return Task_bar_position.Right;
        }
    }


    /***********************************************************
    TODO: Get real taskbar dimensions on Linux as well
    ***********************************************************/
    private QRect taskbar_geometry () {
        if (taskbar_orientation () == Task_bar_position.Bottom || taskbar_orientation () == Task_bar_position.Top) {
            var screen_width = current_screen_rect ().width ();
            return {0, 0, screen_width, 32};
        } else {
            var screen_height = current_screen_rect ().height ();
            return {0, 0, 32, screen_height};
        }
    }


    /***********************************************************
    ***********************************************************/
    private QPoint compute_window_position (int width, int height) {
        const var reference_point = compute_window_reference_point ();

        const var taskbar_screen_edge = taskbar_orientation ();
        const var screen_rect = current_screen_rect ();

        const var top_left = [=] () {
            switch (taskbar_screen_edge) {
            case Task_bar_position.Bottom:
                return reference_point - QPoint (width / 2, height);
            case Task_bar_position.Left:
                return reference_point;
            case Task_bar_position.Top:
                return reference_point - QPoint (width / 2, 0);
            case Task_bar_position.Right:
                return reference_point - QPoint (width, 0);
            }
            GLib.assert_not_reached ();
        } ();
        const var bottom_right = top_left + QPoint (width, height);
        const var window_rect = [=] () {
            const var rect = QRect (top_left, bottom_right);
            var offset = QPoint ();

            if (rect.left () < screen_rect.left ()) {
                offset.x (screen_rect.left () - rect.left () + 4);
            } else if (rect.right () > screen_rect.right ()) {
                offset.x (screen_rect.right () - rect.right () - 4);
            }

            if (rect.top () < screen_rect.top ()) {
                offset.y (screen_rect.top () - rect.top () + 4);
            } else if (rect.bottom () > screen_rect.bottom ()) {
                offset.y (screen_rect.bottom () - rect.bottom () - 4);
            }

            return rect.translated (offset);
        } ();

        GLib.debug ("taskbar_screen_edge: " + taskbar_screen_edge.to_string ());
        GLib.debug ("screen_rect: " + screen_rect.to_string ());
        GLib.debug ("window_rect (reference) " + QRect (top_left, bottom_right).to_string ());
        GLib.debug ("window_rect (adjusted) " + window_rect.to_string ());

        return window_rect.top_left ();
    }

} // class Systray

} // namespace Ui
} // namespace Occ
