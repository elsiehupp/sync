/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSelectiveSyncMovedFolder : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestSelectiveSyncMovedFolder () {
        // issue #5224
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo (
                "", {
                    new FileInfo (
                        "parent_folder", {
                            new FileInfo (
                                "sub_folder_a", {
                                    {
                                        "file_a.txt", 400
                                    }
                                }
                            ), new FileInfo (
                                "sub_folder_b", {
                                    {
                                        "file_b.txt", 400
                                    }
                                }
                            )
                        }
                    )
                }
            )
        );

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var expected_server_state = fake_folder.current_remote_state ();

        // Remove sub_folder_a with selective_sync:
        fake_folder.sync_engine.journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, { "parent_folder/sub_folder_a/" });
        fake_folder.sync_engine.journal.schedule_path_for_remote_discovery ("parent_folder/sub_folder_a/");

        fake_folder.sync_once ();

        // Nothing changed on the server
        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        // The local state should not have sub_folder_a
        var remote_state = fake_folder.current_remote_state ();
        remote_state.remove ("parent_folder/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        // Rename parent_folder on the server
        fake_folder.remote_modifier ().rename ("parent_folder", "parent_folder_renamed");
        expected_server_state = fake_folder.current_remote_state ();
        fake_folder.sync_once ();

        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        remote_state = fake_folder.current_remote_state ();
        // The sub_folder_a should still be there on the server.
        GLib.assert_true (remote_state.find ("parent_folder_renamed/sub_folder_a/file_a.txt"));
        // But not on the client because of the selective sync
        remote_state.remove ("parent_folder_renamed/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        // Rename it again, locally this time.
        fake_folder.local_modifier.rename ("parent_folder_renamed", "parent_third_name");
        fake_folder.sync_once ();

        remote_state = fake_folder.current_remote_state ();
        // The sub_folder_a should still be there on the server.
        GLib.assert_true (remote_state.find ("parent_third_name/sub_folder_a/file_a.txt"));
        // But not on the client because of the selective sync
        remote_state.remove ("parent_third_name/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        expected_server_state = fake_folder.current_remote_state ();
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.sync_once (); // This sync should do nothing
        GLib.assert_true (complete_spy.length == 0);

        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        GLib.assert_true (fake_folder.current_local_state () == remote_state);
    }

} // class TestSelectiveSyncMovedFolder

} // namespace Testing
} // namespace Occ
