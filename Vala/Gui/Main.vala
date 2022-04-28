/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QtGlobal>
//  #include <cmath>
//  #include <csignal>
//  #include <qqml.h>

//  #ifdef Q_OS_UNIX
//  #include <sys/time.h>
//  #include <sys/resource.h>
//  #endif

//  #if defined (BUILD_UPDATER)
//  #endif

//  #include <Gtk.MessageBox>
//  #include <GLib.Debug>
//  #include <GLib.Quick_style>
//  #include <GLib.Quick_window>
//  #include <GLib.Surface_format>

namespace Occ {
namespace Ui {

void warn_systray () {
    Gtk.MessageBox.critical (null,
        _("main.cpp", "System Tray not available"),
        _("%1 requires on a working system tray. "
        + "If you are running XFCE, please follow "
        + "<a href=\"http://docs.xfce.org/xfce/xfce4-panel/systray\">these instructions</a>. "
        + "Otherwise, please install a system tray application such as \"trayer\" and try again.")
            .printf (Theme.app_name_gui));
}

int main (int argc, char **argv) {
    Q_INIT_RESOURCE (resources);
    Q_INIT_RESOURCE (theme);

    qml_register_type<SyncStatusSummary> ("com.nextcloud.desktopclient", 1, 0, "SyncStatusSummary");
    qml_register_type<EmojiModel> ("com.nextcloud.desktopclient", 1, 0, "EmojiModel");
    qml_register_type<UserStatusSelectorModel> ("com.nextcloud.desktopclient", 1, 0, "UserStatusSelectorModel");
    qml_register_type<ActivityListModel> ("com.nextcloud.desktopclient", 1, 0, "ActivityListModel");
    qml_register_type<FileActivityListModel> ("com.nextcloud.desktopclient", 1, 0, "FileActivityListModel");
    qml_register_uncreatable_type<UnifiedSearchResultsListModel> (
        "com.nextcloud.desktopclient", 1, 0, "UnifiedSearchResultsListModel", "UnifiedSearchResultsListModel");
    q_register_meta_type<UnifiedSearchResultsListModel> ("UnifiedSearchResultsListModel*");

    qml_register_uncreatable_type<UserStatus> ("com.nextcloud.desktopclient", 1, 0, "UserStatus", "Access to Status enum");

    q_register_meta_type_stream_operators<Emoji> ();
    q_register_meta_type<UserStatus> ("UserStatus");

    // Work around a bug in KDE's qqc2-desktop-style which breaks
    // buttons with icons not based on a name, by forcing a style name
    // the platformtheme plugin won't try to force qqc2-desktops-style
    // anymore.
    // Can be removed once the bug in qqc2-desktop-style is gone.
    GLib.Quick_style.style ("Default");

    // OpenSSL 1.1.0 : No explicit initialisation or de-initialisation is necessary.

    GLib.Application.attribute (GLib.AAUseHighDpiPixmaps, true);
    GLib.Application.attribute (GLib.AA_Enable_high_dpi_scaling, true);
    Application app = new Application (argc, argv);

    if (app.give_help ()) {
        app.show_help ();
        return 0;
    }
    if (app.version_only ()) {
        app.show_version ();
        return 0;
    }


    GLib.Quick_window.text_render_type (GLib.Quick_window.Native_text_rendering);


    var surface_format = GLib.Surface_format.default_format ();
    surface_format.option (GLib.Surface_format.Reset_notification);
    GLib.Surface_format.default_format (surface_format);

// check a environment variable for core dumps
//  #ifdef Q_OS_UNIX
    if (!q_environment_variable_is_empty ("OWNCLOUD_CORE_DUMP")) {
        RLimit core_limit;
        core_limit.rlim_cur = RLIM_INFINITY;
        core_limit.rlim_max = RLIM_INFINITY;

        if (setrlimit (RLIMIT_CORE, core_limit) < 0) {
            fprintf (stderr, "Unable to set core dump limit\n");
        } else {
            GLib.info ("Core dumps enabled.");
        }
    }
//  #endif

//  #if defined (BUILD_UPDATER)
    // if handle_startup returns true, main ()
    // needs to terminate here, e.g. because
    // the updater is triggered
    AbstractUpdater updater = AbstractUpdater.instance;
    if (updater != null && updater.handle_startup ()) {
        return 1;
    }
//  #endif

    // if the application is already running, notify it.
    if (app.is_running ()) {
        GLib.info ("Already running; exiting...");
        if (app.is_session_restored ()) {
            // This call is mirrored with the one in Application.on_signal_parse_message
            GLib.info ("Session was restored; don't notify app!");
            return -1;
        }

        GLib.List<string> args = app.arguments ();
        if (args.size () > 1) {
            string message = args.join ("|");
            if (!app.on_signal_send_message ("MSG_PARSEOPTIONS:" + message)) {
                return -1;
            }
        } else if (!app.background_mode () && !app.on_signal_send_message ("MSG_SHOWMAINDIALOG")) {
            return -1;
        }
        return 0;
    }

    // We can't call is_system_tray_available with appmenu-qt5 begause it hides the systemtray
    // (issue #4693)
    if (qgetenv ("GLib.T_QPA_PLATFORMTHEME") != "appmenu-qt5") {
        if (!GLib.SystemTrayIcon.is_system_tray_available ()) {
            // If the systemtray is not there, we will wait one second for it to maybe on_signal_start
            // (eg boot time) then we show the settings dialog if there is still no systemtray.
            // On XFCE however, we show a message box with explainaition how to install a systemtray.
            GLib.info ("System tray is not available; waiting...");
            Utility.sleep (1);

            var desktop_session = qgetenv ("XDG_CURRENT_DESKTOP").to_lower ();
            if (desktop_session == "") {
                desktop_session = qgetenv ("DESKTOP_SESSION").to_lower ();
            }
            if (desktop_session == "xfce") {
                int attempts = 0;
                while (!GLib.SystemTrayIcon.is_system_tray_available ()) {
                    attempts++;
                    if (attempts >= 30) {
                        GLib.warning ("System tray unavailable (xfce)");
                        warn_systray ();
                        break;
                    }
                    Utility.sleep (1);
                }
            }

            if (GLib.SystemTrayIcon.is_system_tray_available ()) {
                app.on_signal_try_tray_again ();
            } else if (!app.background_mode () && AccountManager.instance.accounts.length () != 0) {
                if (desktop_session != "ubuntu") {
                    GLib.info ("System tray still not available; showing window and trying again later.");
                    app.show_main_dialog ();
                    GLib.Timeout.single_shot (10000, app, Application.on_signal_try_tray_again);
                } else {
                    GLib.info ("System tray still not available; but assuming it's fine on 'ubuntu' desktop.");
                }
            }
        }
    }

    return app.exec ();
}

} // namespace Ui
} // namespace Occ
