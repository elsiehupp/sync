/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <string>

namespace Occ {
/***********************************************************
@brief Open the file manager with the specified file pre-selected
@ingroup gui
***********************************************************/
void showInFileManager (string &localPath);
}






/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QProcess>
// #include <QSettings>
// #include <QDir>
// #include <QUrl>
// #include <QDesktopServices>
// #include <QApplication>

const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

#if ! (QTLEGACY)
// #include <QOperatingSystemVersion>
#endif

namespace Occ {

// according to the QStandardDir impl from Qt5
static QStringList xdgDataDirs () {
    QStringList dirs;
    // http://standards.freedesktop.org/basedir-spec/latest/
    string xdgDataDirsEnv = QFile.decodeName (qgetenv ("XDG_DATA_DIRS"));
    if (xdgDataDirsEnv.isEmpty ()) {
        dirs.append (string.fromLatin1 ("/usr/local/share"));
        dirs.append (string.fromLatin1 ("/usr/share"));
    } else {
        dirs = xdgDataDirsEnv.split (QLatin1Char (':'));
    }
    // local location
    string xdgDataHome = QFile.decodeName (qgetenv ("XDG_DATA_HOME"));
    if (xdgDataHome.isEmpty ()) {
        xdgDataHome = QDir.homePath () + "/.local/share";
    }
    dirs.prepend (xdgDataHome);
    return dirs;
}

// Linux impl only, make sure to process %u and %U which might be returned
static string findDefaultFileManager () {
    QProcess p;
    p.start ("xdg-mime", QStringList () << "query"
                                      << "default"
                                      << "inode/directory",
        QFile.ReadOnly);
    p.waitForFinished ();
    string fileName = string.fromUtf8 (p.readAll ().trimmed ());
    if (fileName.isEmpty ())
        return string ();

    QFileInfo fi;
    QStringList dirs = xdgDataDirs ();
    QStringList subdirs;
    subdirs << "/applications/"
            << "/applications/kde4/";
    foreach (string dir, dirs) {
        foreach (string subdir, subdirs) {
            fi.setFile (dir + subdir + fileName);
            if (fi.exists ()) {
                return fi.absoluteFilePath ();
            }
        }
    }
    return string ();
}

// early dolphin versions did not have --select
static bool checkDolphinCanSelect () {
    QProcess p;
    p.start ("dolphin", QStringList () << "--help", QFile.ReadOnly);
    p.waitForFinished ();
    return p.readAll ().contains ("--select");
}

// inspired by Qt Creator's showInGraphicalShell ();
void showInFileManager (string &localPath) {
    string app;
    QStringList args;

    static string defaultManager = findDefaultFileManager ();
    QSettings desktopFile (defaultManager, QSettings.IniFormat);
    string exec = desktopFile.value ("Desktop Entry/Exec").toString ();

    string fileToOpen = QFileInfo (localPath).absoluteFilePath ();
    string pathToOpen = QFileInfo (localPath).absolutePath ();
    bool canHandleFile = false; // assume dumb fm

    args = exec.split (' ');
    if (args.count () > 0)
        app = args.takeFirst ();

    string kdeSelectParam ("--select");

    if (app.contains ("konqueror") && !args.contains (kdeSelectParam)) {
        // konq needs '--select' in order not to launch the file
        args.prepend (kdeSelectParam);
        canHandleFile = true;
    }

    if (app.contains ("dolphin")) {
        static bool dolphinCanSelect = checkDolphinCanSelect ();
        if (dolphinCanSelect && !args.contains (kdeSelectParam)) {
            args.prepend (kdeSelectParam);
            canHandleFile = true;
        }
    }

    // whitelist
    if (app.contains ("nautilus") || app.contains ("nemo")) {
        canHandleFile = true;
    }

    static string name;
    if (name.isEmpty ()) {
        name = desktopFile.value (string.fromLatin1 ("Desktop Entry/Name[%1]").arg (qApp.property ("ui_lang").toString ())).toString ();
        if (name.isEmpty ()) {
            name = desktopFile.value (string.fromLatin1 ("Desktop Entry/Name")).toString ();
        }
    }

    std.replace (args.begin (), args.end (), string.fromLatin1 ("%c"), name);
    std.replace (args.begin (), args.end (), string.fromLatin1 ("%u"), fileToOpen);
    std.replace (args.begin (), args.end (), string.fromLatin1 ("%U"), fileToOpen);
    std.replace (args.begin (), args.end (), string.fromLatin1 ("%f"), fileToOpen);
    std.replace (args.begin (), args.end (), string.fromLatin1 ("%F"), fileToOpen);

    // fixme : needs to append --icon, according to http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
    QStringList.iterator it = std.find (args.begin (), args.end (), string.fromLatin1 ("%i"));
    if (it != args.end ()) {
        (*it) = desktopFile.value ("Desktop Entry/Icon").toString ();
        args.insert (it, string.fromLatin1 ("--icon")); // before
    }

    if (args.count () == 0)
        args << fileToOpen;

    if (app.isEmpty () || args.isEmpty () || !canHandleFile) {
        // fall back : open the default file manager, without ever selecting the file
        QDesktopServices.openUrl (QUrl.fromLocalFile (pathToOpen));
    } else {
        QProcess.startDetached (app, args);
    }
}
}
