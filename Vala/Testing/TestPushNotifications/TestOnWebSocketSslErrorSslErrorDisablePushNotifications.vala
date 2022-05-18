namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketSslErrorSslErrorDisablePushNotifications

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketSslErrorSslErrorDisablePushNotifications : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestOnWebSocketSslErrorSslErrorDisablePushNotifications () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        GLib.SignalSpy push_notifications_disabled_spy = new GLib.SignalSpy (account, LibSync.Account.push_notifications_disabled);

        GLib.assert_true (fake_server.wait_for_text_messages ());
        // FIXME: This a little bit ugly but I had no better idea how to trigger a error on the websocket client.
        // The websocket that is retrived through the server is not connected to the ssl error signal.
        var push_notifications_web_socket_children = account.push_notifications ().find_children<GLib.WebSocket> ();
        GLib.assert_true (push_notifications_web_socket_children.size () == 1);
        push_notifications_web_socket_children[0].signal_ssl_errors (GLib.List<GLib.SslError> ());

        // LibSync.Account handled signal_connection_lost signal and the signal_authentication_failed Signal should be emitted
        GLib.assert_true (push_notifications_disabled_spy.length == 1);
    }

} // class TestOnWebSocketSslErrorSslErrorDisablePushNotifications

} // namespace Testing
} // namespace Occ
