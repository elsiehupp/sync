namespace Occ {
namespace Testing {

/***********************************************************
@class TestMoveFailsInAConflict

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestMoveFailsInAConflict : GLib.Object {

    /***********************************************************
    We want to test the case in which the renaming of the
    original to the conflict file succeeds, but renaming the
    temporary file fails. This test uses the fact that a
    "touched_file" notification will be sent at the right moment.

    Note that there will be first a notification on the file and
    the conflict file before.

    Test for https://github.com/owncloud/client/issues/7015
    ***********************************************************/
    private TestMoveFailsInAConflict () {

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.set_ignore_hidden_files (true);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'A');
        fake_folder.local_modifier.set_contents ("A/a1", 'B');

        bool prop_connected = false;
        string conflict_file;
        var trans_progress = connect (
            fake_folder.sync_engine,
            SyncEngine.signal_transmission_progress,
            this.on_signal_sync_engine_transmission_progress
        );

        GLib.assert_true (!fake_folder.sync_once ()); // The sync must fail because the rename failed
        GLib.assert_true (conflict_file != "");

        // restore permissions
        new GLib.File (fake_folder.local_path + "A/").set_permissions (GLib.File.Permissions (0x7777));

        disconnect (trans_progress);
        fake_folder.set_server_override (this.override_delegate_move_fails_in_a_conflict);

        GLib.assert_true (fake_folder.sync_once ());

        // The a1 file is still tere and have the right content
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1").content_char == 'A');

        GLib.assert_true (GLib.File.remove (conflict_file)); // So the comparison succeeds;
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private GLib.InputStream override_delegate_move_fails_in_a_conflict (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (operation == Soup.GetOperation) {
            GLib.assert_fail ("There shouldn't be any download", __FILE__, __LINE__);
        }
        return null;
    }


    private void on_signal_sync_engine_transmission_progress (ProgressInfo progress_info) {
        var propagator = fake_folder.sync_engine.propagator;
        if (progress_info.status () != ProgressInfo.Status.PROPAGATION || prop_connected || !propagator)
            return;
        prop_connected = true;
        propagator.touched_file.connect (
            this.on_signal_propagator_touched_file
        );
    }


    private void on_signal_propagator_touched_file (string string_value) {
        if (string_value.contains ("conflicted copy")) {
            GLib.assert_true (conflict_file == "");
            conflict_file = string_value;
            return;
        }
        if (!conflict_file == "") {
            // Check that the temporary file is still there
            GLib.assert_true (new GLib.Dir (fake_folder.local_path + "A/").entry_list ({ "*.~*" }, GLib.Dir.Files | GLib.Dir.Hidden).length == 1);
            // Set the permission to read only on the folder, so the rename of the temporary file will fail
            new GLib.File (fake_folder.local_path + "A/").set_permissions (GLib.File.Permissions (0x5555));
        }
    }

} // class TestMoveFailsInAConflict

} // namespace Testing
} // namespace Occ
