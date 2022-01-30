/***********************************************************
Copyright (C) by Cédric Bellegarde <gnumdk@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QCursor>
// #include <QGuiApplication>
// #include <QQml_application_engine>
// #include <QQml_context>
// #include <QQuick_window>
// #include <QScreen>
// #include <QMenu>

#ifdef USE_FDO_NOTIFICATIONS
// #include <QDBus_connection>
// #include <QDBus_interface>
// #include <QDBus_message>
// #include <QDBus_pending_call>
const int NOTIFICATIONS_SERVICE "org.freedesktop.Notifications"
const int NOTIFICATIONS_PATH "/org/freedesktop/Notifications"
const int NOTIFICATIONS_IFACE "org.freedesktop.Notifications"
#endif

// #include <QSystemTrayIcon>

// #include <QQml_network_access_manager_factory>

class QWindow;

namespace Occ {

class Access_manager_factory : QQml_network_access_manager_factory {

    public Access_manager_factory ();

    public QNetworkAccessManager* create (GLib.Object parent) override;
};

#ifdef Q_OS_OSX
bool can_os_x_send_user_notification ();
void send_os_xUser_notification (string title, string message);
void set_tray_window_level_and_visible_on_all_spaces (QWindow window);
#endif

/***********************************************************
@brief The Systray class
@ingroup gui
***********************************************************/
class Systray
   : QSystemTrayIcon {

    Q_PROPERTY (string window_title READ window_title CONSTANT)
    Q_PROPERTY (bool use_normal_window READ use_normal_window CONSTANT)

    public static Systray instance ();
    ~Systray () override = default;

    public enum class Task_bar_position {
        Bottom,
        Left,
        Top,
        Right
    };

    public void set_tray_engine (QQml_application_engine tray_engine);


    public void create ();


    public void show_message (string title, string message, Message_icon icon = Information);


    public void set_tool_tip (string tip);


    public bool is_open ();


    public string window_title ();


    public bool use_normal_window ();

    public Q_INVOKABLE void pause_resume_sync ();


    public Q_INVOKABLE bool sync_is_paused ();


    public Q_INVOKABLE void set_opened ();


    public Q_INVOKABLE void set_closed ();


    public Q_INVOKABLE void position_window (QQuick_window window);


    public Q_INVOKABLE void force_window_init (QQuick_window window);

signals:
    void current_user_changed ();
    void open_account_wizard ();
    void open_main_dialog ();
    void open_settings ();
    void open_help ();
    void shutdown ();

    void hide_window ();
    void show_window ();
    void open_share_dialog (string share_path, string local_path);
    void show_file_activity_dialog (string share_path, string local_path);


    public void on_new_user_selected ();


    private void on_unpause_all_folders ();
    private void on_pause_all_folders ();


    private void set_pause_on_all_folders_helper (bool pause);

    private static Systray _instance;
    private Systray ();

    private QScreen current_screen ();
    private QRect current_screen_rect ();
    private QPoint compute_window_reference_point ();
    private QPoint calc_tray_icon_center ();
    private Task_bar_position taskbar_orientation ();
    private QRect taskbar_geometry ();
    private QPoint compute_window_position (int width, int height);

    private bool _is_open = false;
    private bool _sync_is_paused = true;
    private QPointer<QQml_application_engine> _tray_engine;

    private Access_manager_factory _access_manager_factory;
};


Systray *Systray._instance = nullptr;

Systray *Systray.instance () {
    if (!_instance) {
        _instance = new Systray ();
    }
    return _instance;
}

void Systray.set_tray_engine (QQml_application_engine tray_engine) {
    _tray_engine = tray_engine;

    _tray_engine.set_network_access_manager_factory (&_access_manager_factory);

    _tray_engine.add_import_path ("qrc:/qml/theme");
    _tray_engine.add_image_provider ("avatars", new Image_provider);
    _tray_engine.add_image_provider (QLatin1String ("svgimage-custom-color"), new Occ.Ui.Svg_image_provider);
    _tray_engine.add_image_provider (QLatin1String ("unified-search-result-icon"), new Unified_search_result_image_provider);
}

Systray.Systray ()
    : QSystemTrayIcon (nullptr) {
    qml_register_singleton_type<User_model> ("com.nextcloud.desktopclient", 1, 0, "User_model",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return User_model.instance ();
        }
    );

    qml_register_singleton_type<User_apps_model> ("com.nextcloud.desktopclient", 1, 0, "User_apps_model",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return User_apps_model.instance ();
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
        context_menu.add_action (_("Add account"), this, &Systray.open_account_wizard);
    } else {
        context_menu.add_action (_("Open main dialog"), this, &Systray.open_main_dialog);
    }

    var pause_action = context_menu.add_action (_("Pause sync"), this, &Systray.on_pause_all_folders);
    var resume_action = context_menu.add_action (_("Resume sync"), this, &Systray.on_unpause_all_folders);
    context_menu.add_action (_("Settings"), this, &Systray.open_settings);
    context_menu.add_action (_("Exit %1").arg (Theme.instance ().app_name_gui ()), this, &Systray.shutdown);
    set_context_menu (context_menu);

    connect (context_menu, &QMenu.about_to_show, [=] {
        const var folders = FolderMan.instance ().map ();

        const var all_paused = std.all_of (std.cbegin (folders), std.cend (folders), [] (Folder f) {
            return f.sync_paused ();
        });
        const var pause_text = folders.size () > 1 ? _("Pause sync for all") : _("Pause sync");
        pause_action.on_set_text (pause_text);
        pause_action.set_visible (!all_paused);
        pause_action.set_enabled (!all_paused);

        const var any_paused = std.any_of (std.cbegin (folders), std.cend (folders), [] (Folder f) {
            return f.sync_paused ();
        });
        const var resume_text = folders.size () > 1 ? _("Resume sync for all") : _("Resume sync");
        resume_action.on_set_text (resume_text);
        resume_action.set_visible (any_paused);
        resume_action.set_enabled (any_paused);
    });

    connect (User_model.instance (), &User_model.new_user_selected,
        this, &Systray.on_new_user_selected);
    connect (User_model.instance (), &User_model.add_account,
            this, &Systray.open_account_wizard);

    connect (AccountManager.instance (), &AccountManager.on_account_added,
        this, &Systray.show_window);
}

void Systray.create () {
    if (_tray_engine) {
        if (!AccountManager.instance ().accounts ().is_empty ()) {
            _tray_engine.root_context ().set_context_property ("activity_model", User_model.instance ().current_activity_model ());
        }
        _tray_engine.on_load ("qrc:/qml/src/gui/tray/Window.qml");
    }
    hide_window ();
    emit activated (QSystemTrayIcon.Activation_reason.Unknown);

    const var folder_map = FolderMan.instance ().map ();
    for (var folder : folder_map) {
        if (!folder.sync_paused ()) {
            _sync_is_paused = false;
            break;
        }
    }
}

void Systray.on_new_user_selected () {
    if (_tray_engine) {
        // Change Activity_model
        _tray_engine.root_context ().set_context_property ("activity_model", User_model.instance ().current_activity_model ());
    }

    // Rebuild App list
    User_apps_model.instance ().build_app_list ();
}

void Systray.on_unpause_all_folders () {
    set_pause_on_all_folders_helper (false);
}

void Systray.on_pause_all_folders () {
    set_pause_on_all_folders_helper (true);
}

void Systray.set_pause_on_all_folders_helper (bool pause) {
    // For some reason we get the raw pointer from Folder.account_state ()
    // that's why we need a list of raw pointers for the call to contains
    // later on...
    const var accounts = [=] {
        const var ptr_list = AccountManager.instance ().accounts ();
        var result = GLib.List<AccountState> ();
        result.reserve (ptr_list.size ());
        std.transform (std.cbegin (ptr_list), std.cend (ptr_list), std.back_inserter (result), [] (AccountStatePtr &account) {
            return account.data ();
        });
        return result;
    } ();
    const var folders = FolderMan.instance ().map ();
    for (var f : folders) {
        if (accounts.contains (f.account_state ())) {
            f.set_sync_paused (pause);
            if (pause) {
                f.on_terminate_sync ();
            }
        }
    }
}

bool Systray.is_open () {
    return _is_open;
}

string Systray.window_title () {
    return Theme.instance ().app_name_gui ();
}

bool Systray.use_normal_window () {
    if (!is_system_tray_available ()) {
        return true;
    }

    ConfigFile cfg;
    return cfg.show_main_dialog_as_normal_window ();
}

Q_INVOKABLE void Systray.set_opened () {
    _is_open = true;
}

Q_INVOKABLE void Systray.set_closed () {
    _is_open = false;
}

void Systray.show_message (string title, string message, Message_icon icon) {
#ifdef USE_FDO_NOTIFICATIONS
    if (QDBus_interface (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE).is_valid ()) {
        const QVariantMap hints = {{QStringLiteral ("desktop-entry"), LINUX_APPLICATION_ID}};
        GLib.List<QVariant> args = GLib.List<QVariant> () << APPLICATION_NAME << uint32 (0) << APPLICATION_ICON_NAME
                                                 << title << message << string[] () << hints << int32 (-1);
        QDBus_message method = QDBus_message.create_method_call (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE, "Notify");
        method.set_arguments (args);
        QDBus_connection.session_bus ().async_call (method);
    } else
#endif
#ifdef Q_OS_OSX
        if (can_os_x_send_user_notification ()) {
        send_os_xUser_notification (title, message);
    } else
#endif {
        QSystemTrayIcon.show_message (title, message, icon);
    }
}

void Systray.set_tool_tip (string tip) {
    QSystemTrayIcon.set_tool_tip (_("%1 : %2").arg (Theme.instance ().app_name_gui (), tip));
}

bool Systray.sync_is_paused () {
    return _sync_is_paused;
}

void Systray.pause_resume_sync () {
    if (_sync_is_paused) {
        _sync_is_paused = false;
        on_unpause_all_folders ();
    } else {
        _sync_is_paused = true;
        on_pause_all_folders ();
    }
}

/***************************************************************************/
/* Helper functions for cross-platform tray icon position and taskbar orientation detection */
/***************************************************************************/

void Systray.position_window (QQuick_window window) {
    if (!use_normal_window ()) {
        window.set_screen (current_screen ());
        const var position = compute_window_position (window.width (), window.height ());
        window.set_position (position);
    }
}

void Systray.force_window_init (QQuick_window window) {
    // HACK : At least on Windows, if the systray window is not shown at least once
    // it can prevent session handling to carry on properly, so we show/hide it here
    // this shouldn't flicker
    window.show ();
    window.hide ();
}

QScreen *Systray.current_screen () {
    const var screens = QGuiApplication.screens ();
    const var cursor_pos = QCursor.pos ();

    for (var screen : screens) {
        if (screen.geometry ().contains (cursor_pos)) {
            return screen;
        }
    }

    // Didn't find anything matching the cursor position,
    // falling back to the primary screen
    return QGuiApplication.primary_screen ();
}

Systray.Task_bar_position Systray.taskbar_orientation () {
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

// TODO : Get real taskbar dimensions Linux as well
QRect Systray.taskbar_geometry () {
    if (taskbar_orientation () == Task_bar_position.Bottom || taskbar_orientation () == Task_bar_position.Top) {
        var screen_width = current_screen_rect ().width ();
        return {0, 0, screen_width, 32};
    } else {
        var screen_height = current_screen_rect ().height ();
        return {0, 0, 32, screen_height};
    }
}

QRect Systray.current_screen_rect () {
    const var screen = current_screen ();
    Q_ASSERT (screen);
    return screen.geometry ();
}

QPoint Systray.compute_window_reference_point () {
    constexpr var spacing = 4;
    const var tray_icon_center = calc_tray_icon_center ();
    const var taskbar_rect = taskbar_geometry ();
    const var taskbar_screen_edge = taskbar_orientation ();
    const var screen_rect = current_screen_rect ();

    GLib.debug (lc_systray) << "screen_rect:" << screen_rect;
    GLib.debug (lc_systray) << "taskbar_rect:" << taskbar_rect;
    GLib.debug (lc_systray) << "taskbar_screen_edge:" << taskbar_screen_edge;
    GLib.debug (lc_systray) << "tray_icon_center:" << tray_icon_center;

    switch (taskbar_screen_edge) {
    case Task_bar_position.Bottom:
        return {
            tray_icon_center.x (),
            screen_rect.bottom () - taskbar_rect.height () - spacing
        };
    case Task_bar_position.Left:
        return {
            screen_rect.left () + taskbar_rect.width () + spacing,
            tray_icon_center.y ()
        };
    case Task_bar_position.Top:
        return {
            tray_icon_center.x (),
            screen_rect.top () + taskbar_rect.height () + spacing
        };
    case Task_bar_position.Right:
        return {
            screen_rect.right () - taskbar_rect.width () - spacing,
            tray_icon_center.y ()
        };
    }
    Q_UNREACHABLE ();
}

QPoint Systray.compute_window_position (int width, int height) {
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
        Q_UNREACHABLE ();
    } ();
    const var bottom_right = top_left + QPoint (width, height);
    const var window_rect = [=] () {
        const var rect = QRect (top_left, bottom_right);
        var offset = QPoint ();

        if (rect.left () < screen_rect.left ()) {
            offset.set_x (screen_rect.left () - rect.left () + 4);
        } else if (rect.right () > screen_rect.right ()) {
            offset.set_x (screen_rect.right () - rect.right () - 4);
        }

        if (rect.top () < screen_rect.top ()) {
            offset.set_y (screen_rect.top () - rect.top () + 4);
        } else if (rect.bottom () > screen_rect.bottom ()) {
            offset.set_y (screen_rect.bottom () - rect.bottom () - 4);
        }

        return rect.translated (offset);
    } ();

    GLib.debug (lc_systray) << "taskbar_screen_edge:" << taskbar_screen_edge;
    GLib.debug (lc_systray) << "screen_rect:" << screen_rect;
    GLib.debug (lc_systray) << "window_rect (reference)" << QRect (top_left, bottom_right);
    GLib.debug (lc_systray) << "window_rect (adjusted)" << window_rect;

    return window_rect.top_left ();
}

QPoint Systray.calc_tray_icon_center () {
    // On Linux, fall back to mouse position (assuming tray icon is activated by mouse click)
    return QCursor.pos (current_screen ());
}

Access_manager_factory.Access_manager_factory ()
    : QQml_network_access_manager_factory () {
}

QNetworkAccessManager* Access_manager_factory.create (GLib.Object parent) {
    return new AccessManager (parent);
}

} // namespace Occ
