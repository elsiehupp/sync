/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDataFingerprint : AbstractTestAllFilesDeleted {

    /***********************************************************
    ***********************************************************/
    private TestDataFingerprint () {
        QFETCH (
            bool,
            has_initial_finger_print
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().set_contents (
            "C/c1",
            'N'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "C/c1",
            GLib.DateTime.current_date_time_utc ().add_days (-2)
        );
        fake_folder.remote_modifier ().remove ("C/c2");
        if (has_initial_finger_print) {
            fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint>initial_finger_print</oc:data-fingerprint>";
        } else {
            // Server support finger print but none is set.
            fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint></oc:data-fingerprint>";
        }

        int fingerprint_requests = 0;
        fake_folder.set_server_override (this.override_delegate);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fingerprint_requests ==
            1
        );
        // First sync, we did not change the finger print, so the file should be downloaded as normal
        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_remote_state ().find ("C/c1").content_char ==
            'N'
        );
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/c2"));

        /* Simulate a backup restoration */

        // A/a1 is an old file
        fake_folder.remote_modifier ().set_contents (
            "A/a1",
            'O'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "A/a1",
            GLib.DateTime.current_date_time_utc ().add_days (-2)
        );
        // B/b1 did not exist at the time of the backup
        fake_folder.remote_modifier ().remove ("B/b1");
        // B/b2 was uploaded by another user in the mean time.
        fake_folder.remote_modifier ().set_contents (
            "B/b2",
            'N'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "B/b2",
            GLib.DateTime.current_date_time_utc ().add_days (2)
        );

        // C/c3 was removed since we made the backup
        fake_folder.remote_modifier ().insert ("C/c3_removed");
        // C/c4 was moved to A/a2 since we made the backup
        fake_folder.remote_modifier ().rename (
            "A/a2",
            "C/old_a2_location"
        );

        // The admin sets the data-fingerprint property
        fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint>new_finger_print</oc:data-fingerprint>";

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fingerprint_requests ==
            2
        );
        var current_state = fake_folder.current_local_state ();
        // Altough the local file is kept as a conflict, the server file is downloaded
        GLib.assert_true (
            current_state.find ("A/a1").content_char ==
            'O'
        );
        var conflict = find_conflict (
            current_state,
            "A/a1"
        );
        GLib.assert_true (conflict);
        GLib.assert_true (
            conflict.content_char ==
            'W'
        );
        fake_folder.local_modifier.remove (conflict.path);
        // b1 was restored (re-uploaded)
        GLib.assert_true (current_state.find ("B/b1"));

        // b2 has the new content (was not restored), since its mode time goes forward in time
        GLib.assert_true (
            current_state.find ("B/b2").content_char ==
            'N'
        );
        conflict = find_conflict (
            current_state,
            "B/b2"
        );
        GLib.assert_true (conflict); // Just to be sure, we kept the old file in a conflict
        GLib.assert_true (
            conflict.content_char ==
            'W'
        );
        fake_folder.local_modifier.remove (conflict.path);

        // We actually do not remove files that technically should have been removed (we don't want data-loss)
        GLib.assert_true (current_state.find ("C/c3_removed"));
        GLib.assert_true (current_state.find ("C/old_a2_location"));

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

}

} // namespace Testing
} // namespace Occ
