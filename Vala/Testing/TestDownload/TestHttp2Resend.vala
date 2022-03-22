namespace Occ {
namespace Testing {

/***********************************************************
@class TestHttp2Resend

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestHttp2Resend : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestHttp2Resend () {
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
            signal_item_completed (SyncFileItem)
        );
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (resend_actual == 4); // the 4th fails because it only resends 3 times
        GLib.assert_true (get_item (complete_spy, "A/resendme").status == SyncFileItem.Status.NORMAL_ERROR);
        GLib.assert_true (get_item (complete_spy, "A/resendme").error_string.contains (server_message));
    }


    private GLib.InputStream override_delegate_http2_resend (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation && request.url.path.has_suffix ("A/resendme") && resend_actual < resend_expected) {
            var error_reply = new FakeErrorReply (operation, request, this, 400, "ignore this body");
            error_reply.set_error (GLib.InputStream.ContentReSendError, server_message);
            error_reply.set_attribute (Soup.Request.HTTP2WasUsedAttribute, true);
            error_reply.set_attribute (Soup.Request.HttpStatusCodeAttribute, GLib.Variant ());
            resend_actual += 1;
            return error_reply;
        }
        return null;
    }

} // class TestHttp2Resend

} // namespace Testing
} // namespace Occ
