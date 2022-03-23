namespace Occ {
namespace Testing {

/***********************************************************
@class TestMissingData

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestMissingData : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestMissingData () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        fake_folder.remote_modifier ().insert ("good");
        fake_folder.remote_modifier ().insert ("noetag");
        fake_folder.remote_modifier ().find ("noetag").etag == "";
        fake_folder.remote_modifier ().insert ("nofileid");
        fake_folder.remote_modifier ().find ("nofileid").file_identifier == "";
        fake_folder.remote_modifier ().mkdir ("nopermissions");
        fake_folder.remote_modifier ().insert ("nopermissions/A");

        fake_folder.set_server_override (this.override_delegate_missing_data);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (complete_spy.find_item ("good").instruction == CSync.SyncInstructions.NEW);
        GLib.assert_true (complete_spy.find_item ("noetag").instruction == CSync.SyncInstructions.ERROR);
        GLib.assert_true (complete_spy.find_item ("nofileid").instruction == CSync.SyncInstructions.ERROR);
        GLib.assert_true (complete_spy.find_item ("nopermissions").instruction == CSync.SyncInstructions.NEW);
        GLib.assert_true (complete_spy.find_item ("nopermissions/A").instruction == CSync.SyncInstructions.ERROR);
        GLib.assert_true (complete_spy.find_item ("noetag").error_string.contains ("ETag"));
        GLib.assert_true (complete_spy.find_item ("nofileid").error_string.contains ("file identifier"));
        GLib.assert_true (complete_spy.find_item ("nopermissions/A").error_string.contains ("permission"));
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream override_delegate_missing_data (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url.path.has_suffix ("nopermissions"))
            return new MissingPermissionsPropfindReply (fake_folder.remote_modifier (), operation, request, this);
        return null;
    }

} // class TestMissingData

} // namespace Testing
} // namespace Occ
