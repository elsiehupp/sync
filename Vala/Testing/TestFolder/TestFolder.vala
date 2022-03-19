/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/


namespace Occ {
namespace Testing {

public class TestFolder : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private test_folder () {
        QFETCH (string, folder);
        QFETCH (string, expected_folder);
        Folder f = new Folder ("alias", folder, "http://foo.bar.net");
        GLib.assert_true (f.path == expected_folder);
        delete f;
    }


    /***********************************************************
    ***********************************************************/
    private test_folder_data () {
        QTest.add_column<string> ("folder");
        QTest.add_column<string> ("expected_folder");

        QTest.new_row ("unixcase") + "/foo/bar" + "/foo/bar";
        QTest.new_row ("doubleslash") + "/foo//bar" + "/foo/bar";
        QTest.new_row ("tripleslash") + "/foo///bar" + "/foo/bar";
        QTest.new_row ("mixedslash") + "/foo/\\bar" + "/foo/bar";
        QTest.new_row ("windowsfwslash") + "C:/foo/bar" + "C:/foo/bar";
        QTest.new_row ("windowsbwslash") + "C:\\foo" + "C:/foo";
        QTest.new_row ("windowsbwslash2") + "C:\\foo\\bar" + "C:/foo/bar";
    }

} // class TestFolder
} // namespace Testing
} // namespace Occ
