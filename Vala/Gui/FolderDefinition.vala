/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>
@author Daniel Molkentin <danimo@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderDefinition class
@ingroup gui
***********************************************************/
public class FolderDefinition { //: GLib.Object {

    /***********************************************************
    The name of the folder in the instance and internally
    ***********************************************************/
    public string alias;

    /***********************************************************
    path on local machine (always trailing /)
    ***********************************************************/
    public string local_path;

    /***********************************************************
    path to the journal, usually relative to local_path
    ***********************************************************/
    public string journal_path;

    /***********************************************************
    path on remote (usually no trailing /, exception "/")
    ***********************************************************/
    public string target_path;

    /***********************************************************
    whether the folder is paused
    ***********************************************************/
    public bool paused = false;

    /***********************************************************
    whether the folder syncs hidden files
    ***********************************************************/
    public bool ignore_hidden_files = false;

    /***********************************************************
    Which virtual files setting the folder uses
    ***********************************************************/
    public Common.VfsMode virtual_files_mode = Common.AbstractVfs.Off;

    /***********************************************************
    The CLSID where this folder appears in registry for the Explorer navigation pane entry.
    ***********************************************************/
    public GLib.Uuid navigation_pane_clsid;

    /***********************************************************
    Whether the vfs mode shall silently be updated if possible
    ***********************************************************/
    public bool upgrade_vfs_mode = false;

    //  /***********************************************************
    //  Saves the folder definition into the current settings group.
    //  ***********************************************************/
    //  public static void save (GLib.Settings settings, FolderDefinition folder) {
        //  settings.get_value ("local_path", folder.local_path);
        //  settings.get_value ("journal_path", folder.journal_path);
        //  settings.get_value ("target_path", folder.target_path);
        //  settings.get_value ("paused", folder.paused);
        //  settings.get_value ("ignore_hidden_files", folder.ignore_hidden_files);

        //  settings.get_value ("virtual_files_mode", Common.VfsMode.to_string (folder.virtual_files_mode));

        //  // Ensure new vfs modes won't be attempted by older clients
        //  if (folder.virtual_files_mode == Common.AbstractVfs.WindowsCfApi) {
        //      settings.get_value (VERSION_C, 3);
        //  } else {
        //      settings.get_value (VERSION_C, 2);
        //  }

        //  // Happens only on Windows when the explorer integration is enabled.
        //  if (!folder.navigation_pane_clsid == null) {
        //      settings.get_value ("navigation_pane_clsid", folder.navigation_pane_clsid);
        //  } else {
        //      settings.remove ("navigation_pane_clsid");
        //  }
    //  }


    //  /***********************************************************
    //  Reads a folder definition from the current settings group.
    //  ***********************************************************/
    //  public static bool on_signal_load (GLib.Settings settings, string alias,
        //  FolderDefinition folder) {
        //  folder.alias = FolderManager.unescape_alias (alias);
        //  folder.local_path = settings.get_value ("local_path").to_string ();
        //  folder.journal_path = settings.get_value ("journal_path").to_string ();
        //  folder.target_path = settings.get_value ("target_path").to_string ();
        //  folder.paused = settings.get_value ("paused").to_bool ();
        //  folder.ignore_hidden_files = settings.get_value ("ignore_hidden_files", GLib.Variant (true)).to_bool ();
        //  folder.navigation_pane_clsid = settings.get_value ("navigation_pane_clsid").to_uuid ();

        //  folder.virtual_files_mode = Common.AbstractVfs.Off;
        //  string vfs_mode_string = settings.get_value ("virtual_files_mode").to_string ();
        //  if (!vfs_mode_string == "") {
        //      if (var mode = Common.VfsMode.from_string (vfs_mode_string)) {
        //          folder.virtual_files_mode = *mode;
        //      } else {
        //          GLib.warning ("Unknown virtual_files_mode:" + vfs_mode_string + "assuming 'off'";
        //      }
        //  } else {
        //      if (settings.get_value ("use_placeholders").to_bool ()) {
        //          folder.virtual_files_mode = Common.AbstractVfs.WithSuffix;
        //          folder.upgrade_vfs_mode = true; // maybe winvfs is available?
        //      }
        //  }

        //  // Old settings can contain paths with native separators. In the rest of the
        //  // code we assume /, so clean it up now.
        //  folder.local_path = prepare_local_path (folder.local_path);

        //  // Target paths also have a convention
        //  folder.target_path = prepare_target_path (folder.target_path);

        //  return true;
    //  }


    /***********************************************************
    The highest version in the settings that on_signal_load () can read

    Version 1: initial version (default if value absent in settings)
    Version 2: introduction of metadata_parent hash in 2.6.0
               (version remains readable by 2.5.1)
    Version 3: introduction of new windows vfs mode in 2.6.0
    ***********************************************************/
    public static int max_settings_version () {
        return 3;
    }


    //  /***********************************************************
    //  Ensure / as separator and trailing /.
    //  ***********************************************************/
    //  public static string prepare_local_path (string path) {
        //  string p = GLib.Dir.from_native_separators (path);
        //  if (!p.has_suffix ("/")) {
        //      p.append ("/");
        //  }
        //  return p;
    //  }


    //  /***********************************************************
    //  Remove ending /, then ensure starting "/" : so "/foo/bar" and "/".
    //  ***********************************************************/
    //  public static string prepare_target_path (string path) {
        //  string p = path;
        //  if (p.has_suffix ("/")) {
        //      p.chop (1);
        //  }
        //  // Doing this second ensures the empty string or "/" come
        //  // out as "/".
        //  if (!p.has_prefix ("/")) {
        //      p.prepend ("/");
        //  }
        //  return p;
    //  }


    //  /***********************************************************
    //  journal_path relative to local_path.
    //  ***********************************************************/
    //  public string absolute_journal_path;
    //  string FolderDefinition.absolute_journal_path {
        //  return GLib.Dir (local_path).file_path (journal_path);
    //  }


    //  /***********************************************************
    //  Returns the relative journal path that's appropriate for
    //  this folder and account.
    //  ***********************************************************/
    //  public string default_journal_path (LibSync.Account account) {
        //  return Common.SyncJournalDb.make_database_name (local_path, account.url, target_path, account.credentials ().user ());
    //  }

} // class FolderDefinition

} // namespace Ui
} // namespace Occ
