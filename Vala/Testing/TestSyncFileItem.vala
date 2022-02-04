/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>

using namespace Occ;

class TestSyncFileItem : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_init_test_case () {
    }


    /***********************************************************
    ***********************************************************/
    private void on_cleanup_test_case () {}


    private
    private on_ SyncFileItem createItem ( const string file ) {
        SyncFileItem i;
        i.file = file;
        return i;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testComparator_data () {
        QTest.addColumn<SyncFileItem> ("a");
        QTest.addColumn<SyncFileItem> ("b");
        QTest.addColumn<SyncFileItem> ("c");

        QTest.newRow ("a1") << createItem ("client") << createItem ("client/build") << createItem ("client-build") ;
        QTest.newRow ("a2") << createItem ("test/t1") << createItem ("test/t2") << createItem ("test/t3") ;
        QTest.newRow ("a3") << createItem ("ABCD") << createItem ("abcd") << createItem ("zzzz");

        SyncFileItem movedItem1;
        movedItem1.file = "folder/source/file.f";
        movedItem1.renameTarget = "folder/destination/file.f";
        movedItem1.instruction = CSYNC_INSTRUCTION_RENAME;

        QTest.newRow ("move1") << createItem ("folder/destination") << movedItem1 << createItem ("folder/destination-2");
        QTest.newRow ("move2") << createItem ("folder/destination/1") << movedItem1 << createItem ("folder/source");
        QTest.newRow ("move3") << createItem ("abc") << movedItem1 << createItem ("ijk");
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testComparator () {
        QFETCH ( SyncFileItem , a );
        QFETCH ( SyncFileItem , b );
        QFETCH ( SyncFileItem , c );

        QVERIFY (a < b);
        QVERIFY (b < c);
        QVERIFY (a < c);

        QVERIFY (! (b < a));
        QVERIFY (! (c < b));
        QVERIFY (! (c < a));

        QVERIFY (! (a < a));
        QVERIFY (! (b < b));
        QVERIFY (! (c < c));
    }
}

QTEST_APPLESS_MAIN (TestSyncFileItem)
