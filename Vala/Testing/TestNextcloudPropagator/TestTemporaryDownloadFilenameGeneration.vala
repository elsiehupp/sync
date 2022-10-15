/***********************************************************
@class TestTemporaryDownloadFilenameGeneration

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
namespace Occ {
namespace Testing {

public class TestTemporaryDownloadFilenameGeneration { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestTemporaryDownloadFilenameGeneration () {
        //  string filename;
        //  // without directory
        //  for (int i = 1; i <= 1000; i++) {
        //      filename+="F";
        //      string temporary_file_name = create_download_temporary_filename (filename);
        //      if (temporary_file_name.contains ("/")) {
        //          temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ("/")+1);
        //      }
        //      GLib.assert_true ( temporary_file_name.length > 0);
        //      GLib.assert_true ( temporary_file_name.length <= 254);
        //  }
        //  // with absolute directory
        //  filename = "/Users/guruz/own_cloud/rocks/GPL";
        //  for (int i = 1; i < 1000; i++) {
        //      filename+="F";
        //      string temporary_file_name = create_download_temporary_filename (filename);
        //      if (temporary_file_name.contains ("/")) {
        //          temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ("/")+1);
        //      }
        //      GLib.assert_true ( temporary_file_name.length > 0);
        //      GLib.assert_true ( temporary_file_name.length <= 254);
        //  }
        //  // with relative directory
        //  filename = "rocks/GPL";
        //  for (int i = 1; i < 1000; i++) {
        //      filename+="F";
        //      string temporary_file_name = create_download_temporary_filename (filename);
        //      if (temporary_file_name.contains ("/")) {
        //          temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ("/")+1);
        //      }
        //      GLib.assert_true ( temporary_file_name.length > 0);
        //      GLib.assert_true ( temporary_file_name.length <= 254);
        //  }
    }

} // class TestTemporaryDownloadFilenameGeneration

} // namespace Testing
} // namespace Occ
