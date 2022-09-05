/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
TODO: In theory we should use GLib.assert_true instead of
GLib.assert_true for testing, but this only works when
directly called from a GLib.Test :- (
***********************************************************/
public class SyncEngineTestUtils { //: GLib.Object {

    //  const GLib.Uri s_root_url = "owncloud://somehost/owncloud/remote.php/dav/";
    //  const GLib.Uri s_root_url_2 = "owncloud://somehost/owncloud/remote.php/dav/files/admin/";
    //  const GLib.Uri s_upload_url = "owncloud://somehost/owncloud/remote.php/dav/uploads/admin/";

    //  /***********************************************************
    //  ***********************************************************/
    //  inline string get_file_path_from_url (GLib.Uri url) {
    //      string path = url.path;
    //      if (path.has_prefix (s_root_url_2.path))
    //          return path.mid (s_root_url_2.path.length);
    //      if (path.has_prefix (s_upload_url.path))
    //          return path.mid (s_upload_url.path.length);
    //      if (path.has_prefix (s_root_url.path))
    //          return path.mid (s_root_url.path.length);
    //      return "";
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline string generate_etag () {
    //      return string.number (GLib.DateTime.current_date_time_utc ().to_m_secs_since_epoch (), 16) + string.number (Utility.rand (), 16);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  inline string generate_file_id () {
    //      return string.number (Utility.rand (), 16);
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  // GLib.Test.to_string overloads
    //  //  namespace Occ {
    //  inline char sync_file_status_to_string (SyncFileStatus status) {
    //      return GLib.Test.to_string ("SyncFileStatus (" + status.to_socket_api_string () + ")");
    //  }
    //  //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline char file_info_to_string (FileInfo file_info) {
    //      return GLib.Test.to_string (to_string_no_elide (file_info));
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline void add_files (GLib.List<string> dest, FileInfo file_info) {
    //      if (file_info.is_directory) {
    //          dest += "%1 - directory".printf (file_info.path);
    //          foreach (FileInfo file_info in file_info.children) {
    //              add_files (dest, file_info);
    //          }
    //      } else {
    //          dest += "%1 - %2 %3-bytes".printf (file_info.path).printf (file_info.size).printf (file_info.content_char);
    //      }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline string to_string_no_elide (FileInfo file_info) {
    //      GLib.List<string> files;
    //      foreach (FileInfo file_info in file_info.children) {
    //          add_files (files, file_info);
    //      }
    //      files.sort ();
    //      return "FileInfo with %1 files (\n\t%2\n)".printf (files.size ()).printf (files.join ("\n\t"));
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline void add_files_database_data (GLib.List<string> dest, FileInfo file_info) {
    //      // could include etag, permissions etc, but would need extra work
    //      if (file_info.is_directory) {
    //          dest += "%1 - %2 %3 %4".printf (
    //              file_info.name,
    //              file_info.is_directory ? "directory": "file",
    //              string.number (file_info.last_modified.to_seconds_since_epoch ()),
    //              file_info.file_identifier);
    //          foreach (FileInfo file_info in file_info.children) {
    //              add_files_database_data (dest, file_info);
    //          }
    //      } else {
    //          dest += "%1 - %2 %3 %4 %5".printf (
    //              file_info.name,
    //              file_info.is_directory ? "directory": "file",
    //              string.number (file_info.size),
    //              string.number (file_info.last_modified.to_seconds_since_epoch ()),
    //              file_info.file_identifier);
    //      }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  inline char print_database_data (FileInfo file_info) {
    //      GLib.List<string> files;
    //      foreach (FileInfo file_info in file_info.children) {
    //          add_files_database_data (files, file_info);
    //      }
    //      return GLib.Test.to_string ("FileInfo with %1 files (%2)".printf (files.size ()).printf (files.join (", ")));
    //  }

} // class SyncEngineTestUtils
} // namespace Testing
} // namespace Occ
