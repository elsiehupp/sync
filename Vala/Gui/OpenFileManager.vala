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
void show_in_file_manager (string local_path);


// according to the QStandard_dir impl from Qt5
static string[] xdg_data_dirs () {
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

// Linux impl only, make sure to process %u and %U which might be returned
static string find_default_file_manager () {
    QProcess p;
    p.on_signal_start ("xdg-mime", string[] ("query"
                                      + "default"
                                      + "inode/directory",
        GLib.File.ReadOnly);
    p.wait_for_finished ();
    string filename = string.from_utf8 (p.read_all ().trimmed ());
    if (filename.is_empty ())
        return "";

    QFileInfo fi;
    string[] dirs = xdg_data_dirs ();
    string[] subdirs;
    subdirs + "/applications/"
            + "/applications/kde4/";
    foreach (string dir, dirs) {
        foreach (string subdir, subdirs) {
            fi.file (dir + subdir + filename);
            if (fi.exists ()) {
                return fi.absolute_file_path ();
            }
        }
    }
    return "";
}

// early dolphin versions did not have --select
static bool check_dolphin_can_select () {
    QProcess p;
    p.on_signal_start ("dolphin", string[] ("--help", GLib.File.ReadOnly);
    p.wait_for_finished ();
    return p.read_all ().contains ("--select");
}

// inspired by Qt Creator's show_in_graphical_shell ();
void show_in_file_manager (string local_path) {
    string app;
    string[] args;

    /***********************************************************
    ***********************************************************/
    static string default_manager = find_default_file_manager ();
    QSettings desktop_file (default_manager, QSettings.IniFormat);
    string exec = desktop_file.value ("Desktop Entry/Exec").to_string ();

    string file_to_open = QFileInfo (local_path).absolute_file_path ();
    string path_to_open = QFileInfo (local_path).absolute_path ();
    bool can_handle_file = false; // assume dumb fm

    args = exec.split (' ');
    if (args.count () > 0)
        app = args.take_first ();

    string kde_select_param ("--select");

    if (app.contains ("konqueror") && !args.contains (kde_select_param)) {
        // konq needs '--select' in order not to launch the file
        args.prepend (kde_select_param);
        can_handle_file = true;
    }

    if (app.contains ("dolphin")) {
        static bool dolphin_can_select = check_dolphin_can_select ();
        if (dolphin_can_select && !args.contains (kde_select_param)) {
            args.prepend (kde_select_param);
            can_handle_file = true;
        }
    }

    // allowlist
    if (app.contains ("nautilus") || app.contains ("nemo")) {
        can_handle_file = true;
    }


    /***********************************************************
    ***********************************************************/
    static string name;
    if (name.is_empty ()) {
        name = desktop_file.value (string.from_latin1 ("Desktop Entry/Name[%1]").arg (Gtk.Application.property ("ui_lang").to_string ())).to_string ();
        if (name.is_empty ()) {
            name = desktop_file.value (string.from_latin1 ("Desktop Entry/Name")).to_string ();
        }
    }

    std.replace (args.begin (), args.end (), string.from_latin1 ("%c"), name);
    std.replace (args.begin (), args.end (), string.from_latin1 ("%u"), file_to_open);
    std.replace (args.begin (), args.end (), string.from_latin1 ("%U"), file_to_open);
    std.replace (args.begin (), args.end (), string.from_latin1 ("%f"), file_to_open);
    std.replace (args.begin (), args.end (), string.from_latin1 ("%F"), file_to_open);

    // fixme : needs to append --icon, according to http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
    string[].iterator it = std.find (args.begin (), args.end (), string.from_latin1 ("%i"));
    if (it != args.end ()) {
        (*it) = desktop_file.value ("Desktop Entry/Icon").to_string ();
        args.insert (it, string.from_latin1 ("--icon")); // before
    }

    if (args.count () == 0)
        args + file_to_open;

    if (app.is_empty () || args.is_empty () || !can_handle_file) {
        // fall back : open the default file manager, without ever selecting the file
        QDesktopServices.open_url (GLib.Uri.from_local_file (path_to_open));
    } else {
        QProcess.start_detached (app, args);
    }
}
}
