namespace Occ {
namespace Testing {

/***********************************************************
@class TestForbiddenMoves

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestForbiddenMoves : AbstractTestPermissions {

    /***********************************************************
    What happens if the source can't be moved or the target
    can't be created?
    ***********************************************************/
    private TestForbiddenMoves () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 1;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        var lm = fake_folder.local_modifier;
        var rm = fake_folder.remote_modifier ();
        rm.mkdir ("allowed");
        rm.mkdir ("norename");
        rm.mkdir ("nomove");
        rm.mkdir ("nocreatefile");
        rm.mkdir ("nocreatedir");
        rm.mkdir ("zallowed"); // order of discovery matters

        rm.mkdir ("allowed/sub");
        rm.mkdir ("allowed/sub2");
        rm.insert ("allowed/file");
        rm.insert ("allowed/sub/file");
        rm.insert ("allowed/sub2/file");
        rm.mkdir ("norename/sub");
        rm.insert ("norename/file");
        rm.insert ("norename/sub/file");
        rm.mkdir ("nomove/sub");
        rm.insert ("nomove/file");
        rm.insert ("nomove/sub/file");
        rm.mkdir ("zallowed/sub");
        rm.mkdir ("zallowed/sub2");
        rm.insert ("zallowed/file");
        rm.insert ("zallowed/sub/file");
        rm.insert ("zallowed/sub2/file");

        on_set_all_perm (rm.find ("norename"), Common.RemotePermissions.from_server_string ("WDVCK"));
        on_set_all_perm (rm.find ("nomove"), Common.RemotePermissions.from_server_string ("WDNCK"));
        on_set_all_perm (rm.find ("nocreatefile"), Common.RemotePermissions.from_server_string ("WDNVK"));
        on_set_all_perm (rm.find ("nocreatedir"), Common.RemotePermissions.from_server_string ("WDNVC"));

        GLib.assert_true (fake_folder.sync_once ());

        // Renaming errors
        lm.rename ("norename/file", "norename/file_renamed");
        lm.rename ("norename/sub", "norename/sub_renamed");
        // Moving errors
        lm.rename ("nomove/file", "allowed/file_moved");
        lm.rename ("nomove/sub", "allowed/sub_moved");
        // Createfile errors
        lm.rename ("allowed/file", "nocreatefile/file");
        lm.rename ("zallowed/file", "nocreatefile/zfile");
        lm.rename ("allowed/sub", "nocreatefile/sub"); // TODO : probably forbidden because it contains file children?
        // Createdir errors
        lm.rename ("allowed/sub2", "nocreatedir/sub2");
        lm.rename ("zallowed/sub2", "nocreatedir/zsub2");

        // also hook into discovery!!
        GLib.List<LibSync.SyncFileItem> discovery;
        fake_folder.sync_engine.signal_about_to_propagate.connect (
            this.on_signal_sync_engine_about_to_propagate
        );
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (!fake_folder.sync_once ());

        // if renaming doesn't work, just delete+create
        GLib.assert_true (item_instruction (complete_spy, "norename/file", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "norename/sub", CSync.SyncInstructions.NONE));
        GLib.assert_true (discovery_instruction (discovery, "norename/sub", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "norename/file_renamed", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "norename/sub_renamed", CSync.SyncInstructions.NEW));
        // the contents can this.move_
        GLib.assert_true (item_instruction (complete_spy, "norename/sub_renamed/file", CSync.SyncInstructions.RENAME));

        // simiilarly forbidding moves becomes delete+create
        GLib.assert_true (item_instruction (complete_spy, "nomove/file", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "nomove/sub", CSync.SyncInstructions.NONE));
        GLib.assert_true (discovery_instruction (discovery, "nomove/sub", CSync.SyncInstructions.REMOVE));
        // nomove/sub/file is removed as part of the directory
        GLib.assert_true (item_instruction (complete_spy, "allowed/file_moved", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub_moved", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub_moved/file", CSync.SyncInstructions.NEW));

        // when moving to an invalid target, the targets should be an error
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/file", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/zfile", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/sub", CSync.SyncInstructions.RENAME)); // TODO : What does a real server say?
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/sub2", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/zsub2", CSync.SyncInstructions.ERROR));

        // and the sources of the invalid moves should be restored, not deleted
        // (depending on the order of discovery a follow-up sync is needed)
        GLib.assert_true (item_instruction (complete_spy, "allowed/file", CSync.SyncInstructions.NONE));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2", CSync.SyncInstructions.NONE));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/sub2", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/sub2/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);

        // A follow-up sync will restore allowed/file and allowed/sub2 and maintain the nocreatedir/file errors
        complete_spy = "";
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/file", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/zfile", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/sub2", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/zsub2", CSync.SyncInstructions.ERROR));

        GLib.assert_true (item_instruction (complete_spy, "allowed/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2/file", CSync.SyncInstructions.NEW));

        var cls = fake_folder.current_local_state ();
        GLib.assert_true (cls.find ("allowed/file"));
        GLib.assert_true (cls.find ("allowed/sub2"));
        GLib.assert_true (cls.find ("zallowed/file"));
        GLib.assert_true (cls.find ("zallowed/sub2"));
        GLib.assert_true (cls.find ("zallowed/sub2/file"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_engine_about_to_propagate (GLib.List<LibSync.SyncFileItem> *discovery, GLib.List<LibSync.SyncFileItem> v) {
        discovery = *v;
    }

} // class TestForbiddenMoves

} // namespace Testing
} // namespace Occ
