/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <owncloudpropagator.h>

using Occ;

namespace Testing {

public class TestDownload : GLib.Object {

    const int64 STOP_AFTER = 3123668;

    /***********************************************************
    ***********************************************************/
    private void test_resume () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.set_ignore_hidden_files (true);
        QSignalSpy complete_spy = new QSignalSpy (
            fake_folder.sync_engine,
            signal_item_completed (SyncFileItemPtr)
        );
        var size = 30 * 1000 * 1000;
        fake_folder.remote_modifier ().insert ("A/a0", size);

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override (this.override_delegate_resume1);

        GLib.assert_true (!fake_folder.sync_once ()); // The sync must fail because not all the file was downloaded
        GLib.assert_true (get_item (complete_spy, "A/a0").status == SyncFileItem.Status.SOFT_ERROR);
        GLib.assert_true (get_item (complete_spy, "A/a0").error_string == "The file could not be downloaded completely.");
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed ());

        // Now, we need to restart, this time, it should resume.
        string ranges;
        fake_folder.set_server_override (this.override_delegate_resume2);

        GLib.assert_true (fake_folder.sync_once ()); // now this succeeds
        GLib.assert_true (ranges == "bytes=" + STOP_AFTER.to_string () + "-");
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private Soup.Reply override_delegate_resume1 (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation && request.url.path ().ends_with ("A/a0")) {
            return new BrokenFakeGetReply (fake_folder.remote_modifier (), operation, request, this);
        }
        return null;
    }


    private Soup.Reply override_delegate_resume2 (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation && request.url.path ().ends_with ("A/a0")) {
            ranges = request.raw_header ("Range");
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_message () {
        // This test's main goal is to test that the error string from the server is shown in the UI

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.set_ignore_hidden_files (true);
        QSignalSpy complete_spy = new QSignalSpy (
            fake_folder.sync_engine,
            signal_item_completed (SyncFileItemPtr)
        );
        var size = 3500000;
        fake_folder.remote_modifier ().insert ("A/broken", size);

        string server_message = "The file was not downloaded because the tests wants so!";

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override (this.override_delegate_error_message);

        bool timed_out = false;
        QTimer.single_shot (
            10000,
            fake_folder.sync_engine,
            () => {
                timed_out = true;
                fake_folder.sync_engine.on_signal_abort ();
            });
        GLib.assert_true (!fake_folder.sync_once ());  // Fail because A/broken
        GLib.assert_true (!timed_out);
        GLib.assert_true (get_item (complete_spy, "A/broken").status == SyncFileItem.Status.NORMAL_ERROR);
        GLib.assert_true (get_item (complete_spy, "A/broken").error_string.contains (server_message));
    }


    private Soup.Reply override_delegate_error_message (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation && request.url.path ().ends_with ("A/broken")) {
            return new FakeErrorReply (operation, request, this, 400,
                "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                + "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                + "<s:exception>Sabre\\DAV\\Exception\\Forbidden</s:exception>\n"
                + "<s:message>" + server_message + "</s:message>\n"
                + "</d:error>");
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void server_maintenence () {
        // Server in maintenance must on_signal_abort the sync.

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("A/broken");
        fake_folder.set_server_override (this.override_delegate_server_maintenence);

        QSignalSpy complete_spy = new QSignalSpy (
            fake_folder.sync_engine,
            SyncEngine.signal_item_completed
        );
        GLib.assert_true (!fake_folder.sync_once ()); // Fail because A/broken
        // FatalError means the sync was aborted, which is what we want
        GLib.assert_true (get_item (complete_spy, "A/broken").status == SyncFileItem.Status.FATAL_ERROR);
        GLib.assert_true (get_item (complete_spy, "A/broken").error_string.contains ("System in maintenance mode"));
    }


    private Soup.Reply override_delegate_server_maintenence (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation) {
            return new FakeErrorReply (operation, request, this, 503,
                "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                + "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                + "<s:exception>Sabre\\DAV\\Exception\\ServiceUnavailable</s:exception>\n"
                + "<s:message>System in maintenance mode.</s:message>\n"
                + "</d:error>");
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void test_move_fails_in_a_conflict () {
        // Test for https://github.com/owncloud/client/issues/7015
        // We want to test the case in which the renaming of the original to the conflict file succeeds,
        // but renaming the temporary file fails.
        // This tests uses the fact that a "touched_file" notification will be sent at the right moment.
        // Note that there will be first a notification on the file and the conflict file before.

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.set_ignore_hidden_files (true);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'A');
        fake_folder.local_modifier ().set_contents ("A/a1", 'B');

        bool prop_connected = false;
        string conflict_file;
        var trans_progress = connect (
            fake_folder.sync_engine,
            SyncEngine.signal_transmission_progress,
            this.on_signal_sync_engine_transmission_progress
        );

        GLib.assert_true (!fake_folder.sync_once ()); // The sync must fail because the rename failed
        GLib.assert_true (!conflict_file == "");

        // restore permissions
        GLib.File (fake_folder.local_path () + "A/").set_permissions (GLib.File.Permissions (0x7777));

        GLib.Object.disconnect (trans_progress);
        fake_folder.set_server_override (this.override_delegate_move_fails_in_a_conflict);

        GLib.assert_true (fake_folder.sync_once ());

        // The a1 file is still tere and have the right content
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1").content_char == 'A');

        GLib.assert_true (GLib.File.remove (conflict_file)); // So the comparison succeeds;
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private Soup.Reply override_delegate_move_fails_in_a_conflict (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation) {
            GLib.assert_fail ("There shouldn't be any download", __FILE__, __LINE__);
        }
        return null;
    }


    private void on_signal_sync_engine_transmission_progress (ProgressInfo progress_info) {
        var propagator = fake_folder.sync_engine.get_propagator ();
        if (progress_info.status () != ProgressInfo.Status.PROPAGATION || prop_connected || !propagator)
            return;
        prop_connected = true;
        connect (
            propagator,
            OwncloudPropagator.touched_file,
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
            GLib.assert_true (GLib.Dir (fake_folder.local_path () + "A/").entry_list ({ "*.~*" }, GLib.Dir.Files | GLib.Dir.Hidden).count () == 1);
            // Set the permission to read only on the folder, so the rename of the temporary file will fail
            GLib.File (fake_folder.local_path () + "A/").set_permissions (GLib.File.Permissions (0x5555));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_http2_resend () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("A/resendme", 300);

        string server_message = "Needs to be resend on a new connection!";
        int resend_actual = 0;
        int resend_expected = 2;

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override (this.override_delegate_http2_resend);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (resend_actual == 2);

        fake_folder.remote_modifier ().append_byte ("A/resendme");
        resend_actual = 0;
        resend_expected = 10;

        QSignalSpy complete_spy = new QSignalSpy (
            fake_folder.sync_engine,
            signal_item_completed (SyncFileItemPtr)
        );
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (resend_actual == 4); // the 4th fails because it only resends 3 times
        GLib.assert_true (get_item (complete_spy, "A/resendme").status == SyncFileItem.Status.NORMAL_ERROR);
        GLib.assert_true (get_item (complete_spy, "A/resendme").error_string.contains (server_message));
    }


    private Soup.Reply override_delegate_http2_resend (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation && request.url.path ().ends_with ("A/resendme") && resend_actual < resend_expected) {
            var error_reply = new FakeErrorReply (operation, request, this, 400, "ignore this body");
            error_reply.set_error (Soup.Reply.ContentReSendError, server_message);
            error_reply.set_attribute (Soup.Request.HTTP2WasUsedAttribute, true);
            error_reply.set_attribute (Soup.Request.HttpStatusCodeAttribute, GLib.Variant ());
            resend_actual += 1;
            return error_reply;
        }
        return null;
    }

}
}
