/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The FolderDefinition class
@ingroup gui
***********************************************************/
class FolderDefinition {

    /// The name of the folder in the ui and internally
    public string alias;
    /// path on local machine (always trailing /)
    public string local_path;
    /// path to the journal, usually relative to local_path
    public string journal_path;
    /// path on remote (usually no trailing /, exception "/")
    public string target_path;
    /// whether the folder is paused
    public bool paused = false;
    /// whether the folder syncs hidden files
    public bool ignore_hidden_files = false;
    /// Which virtual files setting the folder uses
    public Vfs.Mode virtual_files_mode = Vfs.Off;
    /// The CLSID where this folder appears in registry for the Explorer navigation pane entry.
    public QUuid navigation_pane_clsid;

    /// Whether the vfs mode shall silently be updated if possible
    public bool upgrade_vfs_mode = false;

    /// Saves the folder definition into the current settings group.
    public static void save (QSettings settings, FolderDefinition folder);

    /// Reads a folder definition from the current settings group.
    public static bool on_load (QSettings settings, string alias,
        FolderDefinition folder);


    /***********************************************************
    The highest version in the settings that on_load () can read

    Version 1: initial version (default if value absent in settings)
    Version 2: introduction of metadata_parent hash in 2.6.0
               (version remains readable by 2.5.1)
    Version 3: introduction of new windows vfs mode in 2.6.0
    ***********************************************************/
    public static int max_settings_version () {
        return 3;
    }

    /// Ensure / as separator and trailing /.
    public static string prepare_local_path (string path);

    /// Remove ending /, then ensure starting '/' : so "/foo/bar" and "/".
    public static string prepare_target_path (string path);

    /// journal_path relative to local_path.
    public string absolute_journal_path ();

    /// Returns the relative journal path that's appropriate for this folder and account.
    public string default_journal_path (AccountPointer account);
}




void FolderDefinition.save (QSettings settings, FolderDefinition folder) {
    settings.set_value (QLatin1String ("local_path"), folder.local_path);
    settings.set_value (QLatin1String ("journal_path"), folder.journal_path);
    settings.set_value (QLatin1String ("target_path"), folder.target_path);
    settings.set_value (QLatin1String ("paused"), folder.paused);
    settings.set_value (QLatin1String ("ignore_hidden_files"), folder.ignore_hidden_files);

    settings.set_value (QStringLiteral ("virtual_files_mode"), Vfs.mode_to_string (folder.virtual_files_mode));

    // Ensure new vfs modes won't be attempted by older clients
    if (folder.virtual_files_mode == Vfs.WindowsCfApi) {
        settings.set_value (QLatin1String (VERSION_C), 3);
    } else {
        settings.set_value (QLatin1String (VERSION_C), 2);
    }

    // Happens only on Windows when the explorer integration is enabled.
    if (!folder.navigation_pane_clsid.is_null ())
        settings.set_value (QLatin1String ("navigation_pane_clsid"), folder.navigation_pane_clsid);
    else
        settings.remove (QLatin1String ("navigation_pane_clsid"));
}

bool FolderDefinition.on_load (QSettings settings, string alias,
    FolderDefinition folder) {
    folder.alias = FolderMan.unescape_alias (alias);
    folder.local_path = settings.value (QLatin1String ("local_path")).to_string ();
    folder.journal_path = settings.value (QLatin1String ("journal_path")).to_string ();
    folder.target_path = settings.value (QLatin1String ("target_path")).to_string ();
    folder.paused = settings.value (QLatin1String ("paused")).to_bool ();
    folder.ignore_hidden_files = settings.value (QLatin1String ("ignore_hidden_files"), GLib.Variant (true)).to_bool ();
    folder.navigation_pane_clsid = settings.value (QLatin1String ("navigation_pane_clsid")).to_uuid ();

    folder.virtual_files_mode = Vfs.Off;
    string vfs_mode_string = settings.value (QStringLiteral ("virtual_files_mode")).to_string ();
    if (!vfs_mode_string.is_empty ()) {
        if (var mode = Vfs.mode_from_string (vfs_mode_string)) {
            folder.virtual_files_mode = *mode;
        } else {
            GLib.warn (lc_folder) << "Unknown virtual_files_mode:" << vfs_mode_string << "assuming 'off'";
        }
    } else {
        if (settings.value (QLatin1String ("use_placeholders")).to_bool ()) {
            folder.virtual_files_mode = Vfs.WithSuffix;
            folder.upgrade_vfs_mode = true; // maybe winvfs is available?
        }
    }

    // Old settings can contain paths with native separators. In the rest of the
    // code we assume /, so clean it up now.
    folder.local_path = prepare_local_path (folder.local_path);

    // Target paths also have a convention
    folder.target_path = prepare_target_path (folder.target_path);

    return true;
}

string FolderDefinition.prepare_local_path (string path) {
    string p = QDir.from_native_separators (path);
    if (!p.ends_with ('/')) {
        p.append ('/');
    }
    return p;
}

string FolderDefinition.prepare_target_path (string path) {
    string p = path;
    if (p.ends_with ('/')) {
        p.chop (1);
    }
    // Doing this second ensures the empty string or "/" come
    // out as "/".
    if (!p.starts_with ('/')) {
        p.prepend ('/');
    }
    return p;
}

string FolderDefinition.absolute_journal_path () {
    return QDir (local_path).file_path (journal_path);
}

string FolderDefinition.default_journal_path (AccountPointer account) {
    return SyncJournalDb.make_database_name (local_path, account.url (), target_path, account.credentials ().user ());
}
