/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>

using Occ;

namespace Testing {

class TestSyncFileItem : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {}


    //  private
    private SyncFileItem createItem (string file ) {
        SyncFileItem i;
        i.file = file;
        return i;
    }


    /***********************************************************
    ***********************************************************/
    private void testComparator_data () {
        QTest.add_column<SyncFileItem> ("a");
        QTest.add_column<SyncFileItem> ("b");
        QTest.add_column<SyncFileItem> ("c");

        QTest.new_row ("a1") + createItem ("client") + createItem ("client/build") + createItem ("client-build") ;
        QTest.new_row ("a2") + createItem ("test/t1") + createItem ("test/t2") + createItem ("test/t3") ;
        QTest.new_row ("a3") + createItem ("ABCD") + createItem ("abcd") + createItem ("zzzz");

        SyncFileItem movedItem1;
        movedItem1.file = "folder/source/file.f";
        movedItem1.renameTarget = "folder/destination/file.f";
        movedItem1.instruction = CSYNC_INSTRUCTION_RENAME;

        QTest.new_row ("move1") + createItem ("folder/destination") + movedItem1 << createItem ("folder/destination-2");
        QTest.new_row ("move2") + createItem ("folder/destination/1") + movedItem1 << createItem ("folder/source");
        QTest.new_row ("move3") + createItem ("abc") + movedItem1 << createItem ("ijk");
    }


    /***********************************************************
    ***********************************************************/
    private void testComparator () {
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
