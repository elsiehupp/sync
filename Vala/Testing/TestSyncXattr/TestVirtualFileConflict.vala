namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileConflict

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileConflict : AbstractTestSyncXAttr {

//    /***********************************************************
//    ***********************************************************/
//    private TestVirtualFileConflict () {
//        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
//        set_up_vfs (fake_folder);
//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

//        clean_up_test_virtual_file_conflict ();

//        // Create a virtual file for a new remote file
//        fake_folder.remote_modifier ().mkdir ("A");
//        fake_folder.remote_modifier ().insert ("A/a1", 11);
//        fake_folder.remote_modifier ().insert ("A/a2", 12);
//        fake_folder.remote_modifier ().mkdir ("B");
//        fake_folder.remote_modifier ().insert ("B/b1", 21);
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        xaverify_virtual (fake_folder, "A/a2");
//        xaverify_virtual (fake_folder, "B/b1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 11);
//        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 12);
//        GLib.assert_true (database_record (fake_folder, "B/b1").file_size == 21);
//        clean_up_test_virtual_file_conflict ();

//        // All the files are touched on the server
//        fake_folder.remote_modifier ().append_byte ("A/a1");
//        fake_folder.remote_modifier ().append_byte ("A/a2");
//        fake_folder.remote_modifier ().append_byte ("B/b1");

//        // A : the correct file and a conflicting file are added
//        // B : user adds a directory* locally
//        fake_folder.local_modifier.remove ("A/a1");
//        fake_folder.local_modifier.insert ("A/a1", 12);
//        fake_folder.local_modifier.remove ("A/a2");
//        fake_folder.local_modifier.insert ("A/a2", 10);
//        fake_folder.local_modifier.remove ("B/b1");
//        fake_folder.local_modifier.mkdir ("B/b1");
//        fake_folder.local_modifier.insert ("B/b1/foo");
//        GLib.assert_true (fake_folder.sync_once ());

//        // Everything is CONFLICT
//        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.CONFLICT));
//        GLib.assert_true (item_instruction (complete_spy, "A/a2", CSync.SyncInstructions.CONFLICT));
//        GLib.assert_true (item_instruction (complete_spy, "B/b1", CSync.SyncInstructions.CONFLICT));

//        // conflict files should exist
//        GLib.assert_true (fake_folder.sync_journal ().conflict_record_paths ().size () == 2);

//        // nothing should have the virtual file tag
//        xaverify_nonvirtual (fake_folder, "A/a1");
//        xaverify_nonvirtual (fake_folder, "A/a2");
//        xaverify_nonvirtual (fake_folder, "B/b1");

//        clean_up_test_virtual_file_conflict ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private static void clean_up_test_virtual_file_conflict () {
//        complete_spy = "";
//    }

} // class TestVirtualFileConflict

} // namespace Testing
} // namespace Occ
