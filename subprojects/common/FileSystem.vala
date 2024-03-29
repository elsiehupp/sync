namespace Occ {
namespace Common {

public errordomain FileSystemError {
    MOVE_TO_TRASH_ERROR,
    OPEN_AND_SEEK_FILE_SHARED_ERROR,
    REMOVE_ERROR,
    RENAME_ERROR,
    UNCHECKED_RENAME_REPLACE_ERROR,
}

/***********************************************************
@class FileSystem

@brief This file contains file system helper

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class FileSystem { //: GLib.Object {

    static GLib.FileAttributeInfoList default_write_permissions;

    /***********************************************************
    @brief Marks the file as read-only.

    On linux this either revokes all 'w' permissions or
    restores permissions according to the umask.
    ***********************************************************/
    public static void file_read_only (string filename, bool read_only) {
        //      GLib.FileUtils.chmod ()
        //      GLib.File file = GLib.File.new_for_path (filename);
        //      GLib.FileAttributeInfoList permissions = file.permissions ();

        //      GLib.FileAttributeInfoList all_write_permissions =
        //          GLib.File.WriteUser | GLib.File.WriteGroup | GLib.File.WriteOther | GLib.File.WriteOwner;
        //      FileSystem.default_write_permissions = get_default_write_permissions ();

        //      permissions &= ~all_write_permissions;
        //      if (!read_only) {
        //          permissions |= default_write_permissions;
        //      }
        //      file.permissions (permissions);
    }


    /***********************************************************
    @brief Marks the file as read-only.

    It's like file_read_only (), but weaker : if read_only is false and t
    already has write permissions, no change to the permissions is made.

    This means that it will preserve explicitly set rw-r--r-- permissions even
    when the umask is 0002. (file_read_only () would adjust to rw-rw-r--)
    ***********************************************************/
    public static void file_read_only_weak (string filename, bool read_only) {
        //      GLib.File file = GLib.File.new_for_path (filename);
        //      GLib.FileAttributeInfoList permissions = file.permissions ();

        //      if (!read_only && (permissions & GLib.File.WriteOwner)) {
        //          /***********************************************************
        //          Already writable enough
        //          ***********************************************************/
        //          return;
        //      }

        //      file_read_only (filename, read_only);
    }


    /***********************************************************
    @brief Try to set permissions so that other users on the
        //      local machine can not go into the folder.
    ***********************************************************/
    public static void folder_minimum_permissions (string filename) {
    }


    /***********************************************************
    Convert a "normal" windows path into a path that can be 32k
    chars long.
    ***********************************************************/
    public static string long_win_path (string inpath) {
        //      return inpath;
    }


    /***********************************************************
    @brief Checks whether a file exists.

    Use this over GLib.FileInfo.exists () and GLib.File.exists () to avoid bugs with lnk
    files, see above.
    ***********************************************************/
    public static bool file_exists (string filename, GLib.FileInfo file_info = new GLib.FileInfo ()) {
        //      bool re = file_info.exists ();
        //      /***********************************************************
        //      If the filename is different from the filename in file_info,
        //      the file_info is not valid. There needs to be one
        //      initialised here. Otherwise the incoming file_info is
        //      reused.
        //      ***********************************************************/
        //      if (file_info.file_path != filename) {
        //          GLib.FileInfo my_f_i = new GLib.FileInfo (filename);
        //          re = my_f_i.exists ();
        //      }
        //      return re;
    }


    /***********************************************************
    @brief Rename the file {origin_filename} to
    {destination_filename}.

    It behaves as {GLib.File.rename ()} but handles {.lnk} files
    correctly on Windows.
    ***********************************************************/
    public static bool rename (
        //      string origin_filename,
        //      string destination_filename
    ) throws FileSystemError {
        //      bool success = false;
        //      string error_string;

        //      GLib.File orig = GLib.File.new_for_path (origin_filename);
        //      success = orig.rename (destination_filename);
        //      if (!success) {
        //          error_string = orig.error_string;

        //          GLib.warning (
        //              "Error renaming file " + origin_filename
        //              + " to " + destination_filename
        //              + " failed: " + error_string
        //          );
        //          throw new FileSystemError.RENAME_ERROR (error_string);
        //      }
        //      return success;
    }


    /***********************************************************
    Rename the file \a origin_filename to
    \a destination_filename, and overwrite the destination if
    it already exists, without extra checks.
    ***********************************************************/
    public static bool unchecked_rename_replace (
        //      string origin_filename,
        //      string destination_filename
    ) throws FileSystemError {

        //      bool success = false;
        //      GLib.File orig = new GLib.File (origin_filename);
        //      /***********************************************************
        //      We want a rename that also overwites. GLib.File.rename does
        //      not overwite. Qt 5.1 has GLib.SaveFile.rename_overwrite we
        //      could use.
        //      ### FIXME
        //      ***********************************************************/
        //      success = true;
        //      bool dest_exists = file_exists (destination_filename);
        //      if (dest_exists && !GLib.File.remove (destination_filename)) {
        //          GLib.warning ("Target file could not be removed.");
        //          throw new FileSystemError.UNCHECKED_RENAME_REPLACE_ERROR (orig.error_string);
        //      }
        //      if (success) {
        //          success = orig.rename (destination_filename);
        //      }
        //      if (!success) {
        //          GLib.warning ("Renaming temp file to final failed: " + orig.error_string);
        //          throw new FileSystemError.UNCHECKED_RENAME_REPLACE_ERROR (orig.error_string);
        //      }

        //      return true;
    }


    /***********************************************************
    Removes a file.

    Equivalent to GLib.File.remove (), except on Windows, where it will also
    successfully remove read-only files.
    ***********************************************************/
    public static bool remove (string filename) throws FileSystemError {
        //      GLib.File file = GLib.File.new_for_path (filename);
        //      if (!file.remove ()) {
        //          throw new FileSystemError.REMOVE_ERROR (file.error_string);
        //      }
        //      return true;
    }


    /***********************************************************
    Move the specified file or folder to the trash.
    (Only implemented on linux)
    ***********************************************************/
    public static bool move_to_trash (string filename) throws FileSystemError {
        //      /***********************************************************
        //      TODO: Qt 5.15 bool GLib.File.move_to_trash ()
        //      ***********************************************************/
        //      string trash_path;
        //      string trash_file_path;
        //      string trash_info_path;
        //      string xdg_data_home = GLib.File.decode_name (GLib.Environment.get_variable ("XDG_DATA_HOME"));
        //      if (xdg_data_home == "") {
        //          /***********************************************************
        //          Trash path that should exist
        //          ***********************************************************/
        //          trash_path = GLib.Dir.home_path + "/.local/share/Trash/";
        //      } else {
        //          trash_path = xdg_data_home + "/Trash/";
        //      }
        //      /***********************************************************
        //      Trash file path contain delete files.
        //      ***********************************************************/
        //      trash_file_path = trash_path + "files/";
        //      /***********************************************************
        //      Trash info path contain delete files information.
        //      ***********************************************************/
        //      trash_info_path = trash_path + "info/";

        //      if (! (new GLib.Dir ().mkpath (trash_file_path) && new GLib.Dir ().mkpath (trash_info_path))) {
        //          error_string = _("FileSystem", "Could not make directories in trash");
        //          /***********************************************************
        //          Mkpath will return true if path exists.
        //          ***********************************************************/
        //          return false;
        //      }

        //      GLib.FileInfo file_info = new GLib.FileInfo (filename);

        //      GLib.Dir file;
        //      int suffix_number = 1;
        //      /***********************************************************
        //      File in trash already exists, move to "filename.1"
        //      ***********************************************************/
        //      if (file.exists (trash_file_path + file_info.filename ())) {
        //          string path = trash_file_path + file_info.filename () + '.';
        //          /***********************************************************
        //          Or to "filename.2" if "filename.1" exists, etc
        //          ***********************************************************/
        //          while (file.exists (path + string.number (suffix_number))) {
        //              suffix_number++;
        //          }
        //          /***********************************************************
        //          rename (file old path, file trash path)
        //          ***********************************************************/
        //          if (!file.rename (file_info.absolute_file_path, path + string.number (suffix_number))) {
        //              error_string = _("FileSystem", " (Could not move \"%1\" to \"%2\")")
        //                                 .printf (file_info.absolute_file_path, path + string.number (suffix_number));
        //              return false;
        //          }
        //      } else {
        //          /***********************************************************
        //          rename (file old path, file trash path)
        //          ***********************************************************/
        //          if (!file.rename (file_info.absolute_file_path, trash_file_path + file_info.filename ())) {
        //              error_string = _("FileSystem", " (Could not move \"%1\" to \"%2\")")
        //                                 .printf (file_info.absolute_file_path, trash_file_path + file_info.filename ());
        //              return false;
        //          }
        //      }

        //      /***********************************************************
        //      Create file format for trash info file----- START
        //      ***********************************************************/
        //      GLib.File info_file;
        //      /***********************************************************
        //      TrashInfo file already exists, create "filename.1.trashinfo"
        //      ***********************************************************/
        //      if (file.exists (trash_info_path + file_info.filename () + ".trashinfo")) {
        //          string filename = trash_info_path + file_info.filename () + '.' + string.number (suffix_number) + ".trashinfo";
        //          /***********************************************************
        //          filename+.trashinfo
        //          create file information file in /.local/share/Trash/info/
        //          folder
        //          ***********************************************************/
        //          info_file.filename (filename);
        //      } else {
        //          string filename = trash_info_path + file_info.filename () + ".trashinfo";
        //          /***********************************************************
        //          filename+.trashinfo
        //          create file information file in /.local/share/Trash/info/
        //          folder
        //          ***********************************************************/
        //          info_file.filename (filename);
        //      }

        //      info_file.open (GLib.IODevice.ReadWrite);

        //      /***********************************************************
        //      For write data on open file
        //      ***********************************************************/
        //      GLib.OutputStream stream = new GLib.OutputStream (info_file);

        //      stream += "[Trash Info]\n"
        //             + "Path="
        //             + GLib.Uri.to_percent_encoding (file_info.absolute_file_path, "~this.-./")
        //             + "\n"
        //             + "DeletionDate="
        //             + GLib.DateTime.current_date_time ().to_string (GLib.ISODate)
        //             + "\n";
        //      info_file.close ();

        //      /***********************************************************
        //      Create info file format of trash file----- END
        //      ***********************************************************/

        //      return true;
    }


    /***********************************************************
    Replacement for GLib.File.open (ReadOnly) followed by a
    seek (). This version sets a more permissive sharing mode on
    Windows.

    Warning: The resulting file may have an empty filename and
    be unsuitable for use with GLib.FileInfo! Calling seek () on
    the GLib.File with >32bit signed values will fail!
    ***********************************************************/
    public static bool open_and_seek_file_shared_read (
        //      GLib.File file,
        //      string error_or_null,
        //      int64 seek
    ) throws FileSystemError {
        //      if (!file.open (GLib.File.ReadOnly)) {
        //          throw new FileSystemError.OPEN_AND_SEEK_FILE_SHARED_ERROR (file.error_string);
        //      }
        //      if (!file.seek (seek)) {
        //          throw new FileSystemError.OPEN_AND_SEEK_FILE_SHARED_ERROR (file.error_string);
        //      }
        //      return true;
    }


    /***********************************************************
    Returns whether the file is a shortcut file (ends with .lnk)
    ***********************************************************/
    public static bool is_lnk_file (string filename) {
        //      return filename.has_suffix (".lnk");
    }


    /***********************************************************
    Returns whether the file is an exclude file (contains
    patterns to exclude from sync).
    ***********************************************************/
    public static bool is_exclude_file (string filename) {
        //      return filename.down () == ".sync-exclude.lst"
        //          || filename.down () == "exclude.lst"
        //          || filename.down ().has_suffix ("/.sync-exclude.lst")
        //          || filename.down ().has_suffix ("/exclude.lst");
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.FileAttributeInfoList get_default_write_permissions () {
        //      GLib.FileAttributeInfoList result = GLib.File.WriteUser;
        //      mode_t mask = umask (0);
        //      umask (mask);
        //      if (! (mask & S_IWGRP)) {
        //          result |= GLib.File.WriteGroup;
        //      }
        //      if (! (mask & S_IWOTH)) {
        //          result |= GLib.File.WriteOther;
        //      }
        //      return result;
    }

} // class FileSystem

} // namespace Common
} // namespace Occ
