/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMoveCustomRemoteRoot : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestMoveCustomRemoteRoot () {
        FileInfo sub_folder = new FileInfo (
            "AS", {
                {
                    "f1", 4
                }
            }
        );
        FileInfo folder = new FileInfo (
            "A", {
                sub_folder
            }
        );
        FileInfo file_info = new FileInfo (
            {

            },
            {
                folder
            }
        );

        FakeFolder fake_folder = new FakeFolder (file_info, folder, "/A");
        var local_modifier = fake_folder.local_modifier;

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Move file and then move it back again
        counter.on_signal_reset ();
        local_modifier.rename ("AS/f1", "f1");

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);

        GLib.assert_true (item_successful (complete_spy, "f1", CSync.SyncInstructions.RENAME));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/f1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/AS/f1"));
    }

} // class TestMoveCustomRemoteRoot

} // namespace Testing
} // namespace Occ
