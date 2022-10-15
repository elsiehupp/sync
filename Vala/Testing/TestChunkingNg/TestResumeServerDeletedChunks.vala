/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestResumeServerDeletedChunks : AbstractTestChunkingNg {

    /***********************************************************
    ***********************************************************/
    private TestResumeServerDeletedChunks () {

        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ({ "chunking", "1.0" }) } });
        //  int size = 30 * 1000 * 1000; // 30 MB
        //  set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
        //  partial_upload (fake_folder, "A/a0", size);
        //  GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        //  var chunking_identifier = fake_folder.upload_state ().children.nth_data (0).name;

        //  // Delete the chunks on the server
        //  fake_folder.upload_state ().children = "";
        //  GLib.assert_true (fake_folder.sync_once ());

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

        //  // A different chunk identifier was used
        //  GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        //  GLib.assert_true (fake_folder.upload_state ().children.nth_data (0).name != chunking_identifier);
    }


    /***********************************************************
    Check what happens when the connection is dropped on the PUT
    (non-chunking) or MOVE (chunking) for on the issue #5106
    ***********************************************************/
    private static void connection_dropped_before_etag_recieved_data () {
        //  GLib.Test.add_column<bool> ("chunking");
        //  GLib.Test.new_row ("big file") + true;
        //  GLib.Test.new_row ("small file") + false;
    }


    /***********************************************************
    ***********************************************************/
    private static void connection_dropped_before_etag_recieved () {
        //  GLib.FETCH (bool, chunking);
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ( { "chunking", "1.0" } ) }, { "checksums", new GLib.HashMap ( { "supportedTypes", { "SHA1" } } ) } });
        //  int size = chunking ? 1 * 1000 * 1000 : 300;
        //  set_chunk_size (fake_folder.sync_engine, 300 * 1000);

        //  // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        //  string checksum_header;
        //  int n_get = 0;
        //  GLib.ScopedValueRollback<int> set_http_timeout = new GLib.ScopedValueRollback<int> (LibSync.AbstractNetworkJob.http_timeout, 1);
        //  int response_delay = LibSync.AbstractNetworkJob.http_timeout * 1000 * 1000; // much bigger than http timeout (so a timeout will occur)
        //  // This will perform the operation on the server, but the reply will not come to the client
        //  fake_folder.set_server_override (this.override_delegate_connection_dropped);

        //  // Test 1 : a NEW file
        //  fake_folder.local_modifier.insert ("A/a0", size);
        //  GLib.assert_true (!fake_folder.sync_once ()); // timeout!
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ()); // but the upload succeeded
        //  GLib.assert_true (checksum_header != "");
        //  fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header; // The test system don't do that automatically
        //  // Should be resolved properly
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (n_get == 0);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // Test 2 : Modify the file further
        //  fake_folder.local_modifier.append_byte ("A/a0");
        //  GLib.assert_true (!fake_folder.sync_once ()); // timeout!
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ()); // but the upload succeeded
        //  fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header;
        //  // modify again, should not cause conflict
        //  fake_folder.local_modifier.append_byte ("A/a0");
        //  GLib.assert_true (!fake_folder.sync_once ()); // now it's trying to upload the modified file
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header;
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (n_get == 0);
    }


    private GLib.InputStream override_delegate_connection_dropped (Soup.Operation operation, Soup.Request request, GLib.OutputStream outgoing_data) {
        //  if (!chunking) {
        //      GLib.assert_true (!request.url.path.contains ("/uploads/")
        //          && "Should not touch uploads endpoint when not chunking");
        //  }
        //  if (!chunking && operation == Soup.PutOperation) {
        //      checksum_header = request.raw_header ("OC-Checksum");
        //      return new DelayedReply<FakePutReply> (response_delay, fake_folder.remote_modifier (), operation, request, outgoing_data.read_all (), fake_folder.sync_engine);
        //  } else if (chunking && request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
        //      checksum_header = request.raw_header ("OC-Checksum");
        //      return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, fake_folder.sync_engine);
        //  } else if (operation == Soup.GetOperation) {
        //      n_get++;
        //  }
        //  return null;
    }

} // class TestResumeServerDeletedChunks

} // namespace Testing
} // namespace Occ
