/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QProcess>
//  #include <QSettings>
//  #include <QDir>
//  #include <QDesktopServices>
//  #include <QApplication>

//  const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

//  #if ! (QTLEGACY)
//  #include <QOperatingSystemVersion>
//  #endif

namespace Occ {
namespace Ui {

/***********************************************************
@brief Open the file manager with the specified file pre-selected
@ingroup gui
***********************************************************/
public class OpenFileManager {

    static string default_manager;
    static string name;

    static bool dolphin_can_select;

    /***********************************************************
    Inspired by Qt Creator's show_in_graphical_shell ();
    ***********************************************************/
    public static void show_in_file_manager (string local_path) {
        string app;
        string[] args;

        OpenFileManager.default_manager = find_default_file_manager ();
        QSettings desktop_file = new QSettings (OpenFileManager.default_manager, QSettings.IniFormat);
        string exec = desktop_file.value ("Desktop Entry/Exec").to_string ();

        string file_to_open = GLib.FileInfo (local_path).absolute_file_path ();
        string path_to_open = GLib.FileInfo (local_path).absolute_path ();
        bool can_handle_file = false; // assume dumb font_metrics

        args = exec.split (' ');
        if (args.count () > 0)
            app = args.take_first ();

        string kde_select_param = "--select";

        if (app.contains ("konqueror") && !args.contains (kde_select_param)) {
            // konq needs '--select' in order not to launch the file
            args.prepend (kde_select_param);
            can_handle_file = true;
        }

        if (app.contains ("dolphin")) {
            OpenFileManager.dolphin_can_select = check_dolphin_can_select ();
            if (dolphin_can_select && !args.contains (kde_select_param)) {
                args.prepend (kde_select_param);
                can_handle_file = true;
            }
        }

        // allowlist
        if (app.contains ("nautilus") || app.contains ("nemo")) {
            can_handle_file = true;
        }

        if (OpenFileManager.name.is_empty ()) {
            OpenFileManager.name = desktop_file.value (string.from_latin1 ("Desktop Entry/Name[%1]").arg (Gtk.Application.property ("ui_lang").to_string ())).to_string ();
            if (OpenFileManager.name.is_empty ()) {
                OpenFileManager.name = desktop_file.value (string.from_latin1 ("Desktop Entry/Name")).to_string ();
            }
        }

        std.replace (args.begin (), args.end (), string.from_latin1 ("%c"), OpenFileManager.name);
        std.replace (args.begin (), args.end (), string.from_latin1 ("%u"), file_to_open);
        std.replace (args.begin (), args.end (), string.from_latin1 ("%U"), file_to_open);
        std.replace (args.begin (), args.end (), string.from_latin1 ("%f"), file_to_open);
        std.replace (args.begin (), args.end (), string.from_latin1 ("%F"), file_to_open);

        // fixme: needs to append --icon, according to http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
        foreach (string arg in args) {
            if (arg == "%i") {
                args.insert (desktop_file.value ("Desktop Entry/Icon").to_string (), "--icon"); // before
            }
        }

        if (args.count () == 0) {
            args += file_to_open;
        }

        if (app.is_empty () || args.is_empty () || !can_handle_file) {
            // fallback: open the default file manager, without ever selecting the file
            QDesktopServices.open_url (GLib.Uri.from_local_file (path_to_open));
        } else {
            QProcess.start_detached (app, args);
        }
    }


    /***********************************************************
    According to the QStandardDir implementation from Qt5
    ***********************************************************/
    public static string[] xdg_data_dirs () {
        string[] dirs;
        // http://standards.freedesktop.org/basedir-spec/latest/
        string xdg_data_dirs_env = GLib.File.decode_name (qgetenv ("XDG_DATA_DIRS"));
        if (xdg_data_dirs_env.is_empty ()) {
            dirs.append (string.from_latin1 ("/usr/local/share"));
            dirs.append (string.from_latin1 ("/usr/share"));
        } else {
            dirs = xdg_data_dirs_env.split (':');
        }
        // local location
        string xdg_data_home = GLib.File.decode_name (qgetenv ("XDG_DATA_HOME"));
        if (xdg_data_home.is_empty ()) {
            xdg_data_home = QDir.home_path () + "/.local/share";
        }
        dirs.prepend (xdg_data_home);
        return dirs;
    }


    /***********************************************************
    Linux implementation only, make sure to process %u and %U
    which might be returned
    ***********************************************************/
    public static string find_default_file_manager () {
        QProcess p;
        p.on_signal_start (
            "xdg-mime",
            {
                "query",
                "default",
                "inode/directory"
            },
            GLib.File.ReadOnly
        );
        p.wait_for_finished ();
        string filename = p.read_all ().trimmed ();
        if (filename.is_empty ()) {
            return "";
        }

        GLib.FileInfo file_info;
        string[] dirs = xdg_data_dirs ();
        string[] subdirectories;
        subdirectories += "/applications/"
                + "/applications/kde4/";
        foreach (string directory in dirs) {
            foreach (string subdir in subdirectories) {
                file_info.file (directory + subdir + filename);
                if (file_info.exists ()) {
                    return file_info.absolute_file_path ();
                }
            }
        }
        return "";
    }


    /***********************************************************
    Early dolphin versions did not have --select
    ***********************************************************/
    public static bool check_dolphin_can_select () {
        QProcess p;
        p.on_signal_start ("dolphin", { "--help", GLib.File.ReadOnly });
        p.wait_for_finished ();
        return p.read_all ().contains ("--select");
    }

}

}
}
