/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestLateAbortRecoverable : AbstractTestChunkingNg {

    //  /***********************************************************
    //  Check what happens when we on_signal_abort during the final
    //  MOVE and the final MOVE is short enough for the abort-delay
    //  to help.
    //  ***********************************************************/
    //  private TestLateAbortRecoverable () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ( { "chunking", "1.0" } ) }, { "checksums", new GLib.HashMap ( { "supportedTypes", { "SHA1" } } ) } });
    //      int size = 15 * 1000 * 1000; // 15 MB
    //      set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

    //      // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
    //      GLib.Object parent;
    //      int response_delay = 200; // smaller than on_signal_abort-wait timeout
    //      fake_folder.set_server_override (this.override_delegate_abort_recoverable);

    //      // Test 1 : NEW file aborted
    //      fake_folder.local_modifier.insert ("A/a0", size);
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      // Test 2 : modified file upload aborted
    //      fake_folder.local_modifier.append_byte ("A/a0");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //  }


    //  private GLib.InputStream override_delegate_abort_recoverable (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
    //      if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
    //          GLib.Timeout.add (50, fake_folder.sync_engine.on_signal_abort);
    //          return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, parent);
    //      }
    //      return null;
    //  }

} // class TestLateAbortRecoverable

} // namespace Testing
} // namespace Occ
