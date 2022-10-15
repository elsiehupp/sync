namespace Occ {
namespace Testing {

/***********************************************************
@class TestServerMaintenance

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestServerMaintenance { //: GLib.Object {

    /***********************************************************
    Server in maintenance must abort the sync.
    ***********************************************************/
    private TestServerMaintenance () {

        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.remote_modifier ().insert ("A/broken");
        //  fake_folder.set_server_override (this.override_delegate_server_maintenence);

        //  GLib.SignalSpy complete_spy = new GLib.SignalSpy (
        //      fake_folder.sync_engine,
        //      LibSync.SyncEngine.signal_item_completed
        //  );
        //  GLib.assert_true (!fake_folder.sync_once ()); // Fail because A/broken
        //  // FatalError means the sync was aborted, which is what we want
        //  GLib.assert_true (get_item (complete_spy, "A/broken").status == LibSync.SyncFileItem.Status.FATAL_ERROR);
        //  GLib.assert_true (get_item (complete_spy, "A/broken").error_string.contains ("System in maintenance mode"));
    }


    private GLib.InputStream override_delegate_server_maintenence (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        //  if (operation == Soup.GetOperation) {
        //      return new FakeErrorReply (operation, request, this, 503,
        //          "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        //          + "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
        //          + "<s:exception>Sabre\\DAV\\Exception\\ServiceUnavailable</s:exception>\n"
        //          + "<s:message>System in maintenance mode.</s:message>\n"
        //          + "</d:error>");
        //  }
        //  return null;
    }

} // class TestServerMaintenance

} // namespace Testing
} // namespace Occ
