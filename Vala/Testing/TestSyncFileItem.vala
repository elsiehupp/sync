/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

public class TestSyncFileItem : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {}


    //  private
    private SyncFileItem create_item (string file ) {
        SyncFileItem i;
        i.file = file;
        return i;
    }


    /***********************************************************
    ***********************************************************/
    private void test_comparator_data () {
        QTest.add_column<SyncFileItem> ("a");
        QTest.add_column<SyncFileItem> ("b");
        QTest.add_column<SyncFileItem> ("c");

        QTest.new_row ("a1") + create_item ("client") + create_item ("client/build") + create_item ("client-build") ;
        QTest.new_row ("a2") + create_item ("test/t1") + create_item ("test/t2") + create_item ("test/t3") ;
        QTest.new_row ("a3") + create_item ("ABCD") + create_item ("abcd") + create_item ("zzzz");

        SyncFileItem moved_item1;
        moved_item1.file = "folder/source/file.f";
        moved_item1.rename_target = "folder/destination/file.f";
        moved_item1.instruction = CSync.SyncInstructions.RENAME;

        QTest.new_row ("move1") + create_item ("folder/destination") + moved_item1 << create_item ("folder/destination-2");
        QTest.new_row ("move2") + create_item ("folder/destination/1") + moved_item1 << create_item ("folder/source");
        QTest.new_row ("move3") + create_item ("abc") + moved_item1 << create_item ("ijk");
    }


    /***********************************************************
    ***********************************************************/
    private void test_comparator () {
        QFETCH ( SyncFileItem , a );
        QFETCH ( SyncFileItem , b );
        QFETCH ( SyncFileItem , c );

        GLib.assert_true (a < b);
        GLib.assert_true (b < c);
        GLib.assert_true (a < c);

        GLib.assert_true (! (b < a));
        GLib.assert_true (! (c < b));
        GLib.assert_true (! (c < a));

        GLib.assert_true (! (a < a));
        GLib.assert_true (! (b < b));
        GLib.assert_true (! (c < c));
    }

}
}
