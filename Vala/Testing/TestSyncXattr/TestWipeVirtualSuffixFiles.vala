namespace Occ {
namespace Testing {

/***********************************************************
@class TestWipeVirtualSuffixFiles

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestWipeVirtualSuffixFiles : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestWipeVirtualSuffixFiles () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);

        // Create a suffix-vfs baseline

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().mkdir ("A/B");
        fake_folder.remote_modifier ().insert ("f1");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().insert ("A/B/b1");
        fake_folder.local_modifier.mkdir ("A");
        fake_folder.local_modifier.mkdir ("A/B");
        fake_folder.local_modifier.insert ("f2");
        fake_folder.local_modifier.insert ("A/a2");
        fake_folder.local_modifier.insert ("A/B/b2");

        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "f1");
        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a3");
        xaverify_virtual (fake_folder, "A/B/b1");

        // Make local changes to a3
        fake_folder.local_modifier.remove ("A/a3");
        fake_folder.local_modifier.insert ("A/a3", 100);

        // Now wipe the virtuals
        SyncEngine.wipe_virtual_files (fake_folder.local_path, fake_folder.sync_journal (), *fake_folder.sync_engine.sync_options ().vfs);

        cfverify_gone (fake_folder, "f1");
        cfverify_gone (fake_folder, "A/a1");
        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a3").exists ());
        GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid);
        cfverify_gone (fake_folder, "A/B/b1");

        fake_folder.switch_to_vfs (new VfsOff ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("A"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f2"));

        // a3 has a conflict
        GLib.assert_true (item_instruction (complete_spy, "A/a3", CSync.SyncInstructions.CONFLICT));

        // conflict files should exist
        GLib.assert_true (fake_folder.sync_journal ().conflict_record_paths ().size () == 1);
    }

} // class TestWipeVirtualSuffixFiles

} // namespace Testing
} // namespace Occ
