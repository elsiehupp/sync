/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/


namespace Occ {
namespace Testing {

public class TestFolder { //: GLib.Object {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestFolder () {
    //      GLib.FETCH (string, folder);
    //      GLib.FETCH (string, expected_folder);
    //      FolderConnection f = new FolderConnection ("alias", folder, "http://foo.bar.net");
    //      GLib.assert_true (f.path == expected_folder);
    //      delete f;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private TestFolderData () {
    //      GLib.Test.add_column<string> ("folder");
    //      GLib.Test.add_column<string> ("expected_folder");

    //      GLib.Test.new_row ("unixcase") + "/foo/bar" + "/foo/bar";
    //      GLib.Test.new_row ("doubleslash") + "/foo//bar" + "/foo/bar";
    //      GLib.Test.new_row ("tripleslash") + "/foo///bar" + "/foo/bar";
    //      GLib.Test.new_row ("mixedslash") + "/foo/\\bar" + "/foo/bar";
    //      GLib.Test.new_row ("windowsfwslash") + "C:/foo/bar" + "C:/foo/bar";
    //      GLib.Test.new_row ("windowsbwslash") + "C:\\foo" + "C:/foo";
    //      GLib.Test.new_row ("windowsbwslash2") + "C:\\foo\\bar" + "C:/foo/bar";
    //  }

} // class TestFolder
} // namespace Testing
} // namespace Occ
