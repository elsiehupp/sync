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
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account, &Account.push_notifications_disabled);

        GLib.assert_true (fake_server.wait_for_text_messages ());
        // FIXME: This a little bit ugly but I had no better idea how to trigger a error on the websocket client.
        // The websocket that is retrived through the server is not connected to the ssl error signal.
        var push_notifications_web_socket_children = account.push_notifications ().find_children<QWebSocket> ();
        GLib.assert_true (push_notifications_web_socket_children.size () == 1);
        /* emit */ push_notifications_web_socket_children[0].ssl_errors (GLib.List<QSslError> ());

        // Account handled connection_lost signal and the authentication_failed Signal should be emitted
        GLib.assert_true (push_notifications_disabled_spy.count () == 1);
    }

} // class TestOnWebSocketSslErrorSslErrorDisablePushNotifications

} // namespace Testing
} // namespace Occ
