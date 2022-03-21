/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestAbortAfterFailedMkdir : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestAbortAfterFailedMkdir () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        QSignalSpy finished_spy = new QSignalSpy (
            fake_folder.sync_engine,
            SIGNAL (on_signal_finished (bool))
        );
        fake_folder.server_error_paths ().append ("NewFolder");
        fake_folder.local_modifier.mkdir ("NewFolder");
        // This should be aborted and would otherwise fail in FileInfo.create.
        fake_folder.local_modifier.insert ("NewFolder/NewFile");
        fake_folder.sync_once ();
        GLib.assert_true (finished_spy.size () == 1);
        GLib.assert_true (finished_spy.first ().first ().to_bool () == false);
    }

} // class TestAbortAfterFailedMkdir

} // namespace Testing
} // namespace Occ
