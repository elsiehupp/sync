/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFileUpload : AbstractTestChunkingNg {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestFileUpload () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ({ "chunking", "1.0" }) } });
    //      set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
    //      int size = 10 * 1000 * 1000; // 10 MB

    //      fake_folder.local_modifier.insert ("A/a0", size);
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (fake_folder.upload_state ().children.length == 1); // the transfer was done with chunking
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

    //      // Check that another upload of the same file also work.
    //      fake_folder.local_modifier.append_byte ("A/a0");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (fake_folder.upload_state ().children.length == 2); // the transfer was done with chunking
    //  }

} // class TestFileUpload

} // namespace Testing
} // namespace Occ
