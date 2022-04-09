/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSyncFileItem : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private SyncFileItem create_item (string file ) {
        SyncFileItem i;
        i.file = file;
        return i;
    }


    /***********************************************************
    ***********************************************************/
    private TestComparatorData () {
        GLib.Test.add_column<SyncFileItem> ("a");
        GLib.Test.add_column<SyncFileItem> ("b");
        GLib.Test.add_column<SyncFileItem> ("c");

        GLib.Test.new_row ("a1") + create_item ("client") + create_item ("client/build") + create_item ("client-build") ;
        GLib.Test.new_row ("a2") + create_item ("test/t1") + create_item ("test/t2") + create_item ("test/t3") ;
        GLib.Test.new_row ("a3") + create_item ("ABCD") + create_item ("abcd") + create_item ("zzzz");

        SyncFileItem moved_item1;
        moved_item1.file = "folder/source/file.f";
        moved_item1.rename_target = "folder/destination/file.f";
        moved_item1.instruction = CSync.SyncInstructions.RENAME;

        GLib.Test.new_row ("move1") + create_item ("folder/destination") + moved_item1 << create_item ("folder/destination-2");
        GLib.Test.new_row ("move2") + create_item ("folder/destination/1") + moved_item1 << create_item ("folder/source");
        GLib.Test.new_row ("move3") + create_item ("abc") + moved_item1 << create_item ("ijk");
    }


    /***********************************************************
    ***********************************************************/
    private TestComparator () {
        GLib.FETCH ( SyncFileItem , a );
        GLib.FETCH ( SyncFileItem , b );
        GLib.FETCH ( SyncFileItem , c );

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

} // namespace Testing
} // namespace Occ
