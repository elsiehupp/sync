namespace Occ {
namespace Testing {

/***********************************************************
@class TestRemoteDiscoveryError

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRemoteDiscoveryError : GLib.Object {

    /***********************************************************
    Check what happens when there is an error.
    ***********************************************************/
    private TestRemoteDiscoveryError () {
        GLib.FETCH (int, error_kind);
        GLib.FETCH (string, expected_error_string);
        GLib.FETCH (bool, sync_succeeds);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Do Some change as well
        fake_folder.local_modifier.insert ("A/z1");
        fake_folder.local_modifier.insert ("B/z1");
        fake_folder.local_modifier.insert ("C/z1");
        fake_folder.remote_modifier ().insert ("A/z2");
        fake_folder.remote_modifier ().insert ("B/z2");
        fake_folder.remote_modifier ().insert ("C/z2");

        var old_local_state = fake_folder.current_local_state ();
        var old_remote_state = fake_folder.current_remote_state ();

        string error_folder = "dav/files/admin/B";
        string fatal_error_prefix = "Server replied with an error while reading directory \"B\": ";
        fake_folder.set_server_override (this.override_delegate_remote_error);

        // So the test that test timeout finishes fast
        GLib.ScopedValueRollback<int> set_http_timeout = new GLib.ScopedValueRollback<int> (AbstractNetworkJob.http_timeout, error_kind == Timeout ? 1 : 10000);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.SignalSpy error_spy = new GLib.SignalSpy (
            fake_folder.sync_engine,
            SyncEngine.signal_sync_error
        );
        GLib.assert_true (fake_folder.sync_once () == sync_succeeds);

        // The folder B should not have been sync'ed (and in particular not removed)
        GLib.assert_true (old_local_state.children["B"] == fake_folder.current_local_state ().children["B"]);
        GLib.assert_true (old_remote_state.children["B"] == fake_folder.current_remote_state ().children["B"]);
        if (!sync_succeeds) {
            GLib.assert_true (error_spy.size () == 1);
            GLib.assert_true (error_spy[0][0].to_string () == fatal_error_prefix + expected_error_string);
        } else {
            GLib.assert_true (complete_spy.find_item ("B").instruction == CSync.SyncInstructions.IGNORE);
            GLib.assert_true (complete_spy.find_item ("B").error_string.contains (expected_error_string));

            // The other folder should have been sync'ed as the sync just ignored the faulty directory
            GLib.assert_true (fake_folder.current_remote_state ().children["A"] == fake_folder.current_local_state ().children["A"]);
            GLib.assert_true (fake_folder.current_remote_state ().children["C"] == fake_folder.current_local_state ().children["C"]);
            GLib.assert_true (complete_spy.find_item ("A/z1").instruction == CSync.SyncInstructions.NEW);
        }

        //  
        // Check the same discovery error on the sync root
        //  
        error_folder = "dav/files/admin/";
        fatal_error_prefix = "Server replied with an error while reading directory \"\": ";
        error_spy == "";
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (error_spy.size () == 1);
        GLib.assert_true (error_spy[0][0].to_string () == fatal_error_prefix + expected_error_string);
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream override_delegate_remote_error (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url.path.has_suffix (error_folder)) {
            if (error_kind == InvalidXML) {
                return new FakeBrokenXmlPropfindReply (fake_folder.remote_modifier (), operation, request, this);
            } else if (error_kind == Timeout) {
                return new FakeHangingReply (operation, request, this);
            } else if (error_kind < 1000) {
                return new FakeErrorReply (operation, request, this, error_kind);
            }
        }
        return null;
    }

} // class TestRemoteDiscoveryError

} // namespace Testing
} // namespace Occ
