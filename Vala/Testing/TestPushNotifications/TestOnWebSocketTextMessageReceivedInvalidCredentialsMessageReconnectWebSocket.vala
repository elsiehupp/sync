namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketTextMessageReceivedInvalidCredentialsMessageReconnectWebSocket

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketTextMessageReceivedInvalidCredentialsMessageReconnectWebSocket : AbstractTestPushNotifications {

//    /***********************************************************
//    ***********************************************************/
//    private TestOnWebSocketTextMessageReceivedInvalidCredentialsMessageReconnectWebSocket () {
//        FakeWebSocketServer fake_server;
//        var account = FakeWebSocketServer.create_account ();
//        // Need to set reconnect timer interval to zero for tests
//        account.push_notifications ().set_reconnect_timer_interval (0);

//        // Wait for authentication attempt and then sent invalid credentials
//        GLib.assert_true (fake_server.wait_for_text_messages ());
//        GLib.assert_true (fake_server.text_messages_count () == 2);
//        var socket = fake_server.socket_for_text_message (0);
//        var first_password_sent = fake_server.text_message (1);
//        GLib.assert_true (first_password_sent == account.credentials ().password ());
//        fake_server.clear_text_messages ();
//        socket.send_text_message ("Error: Invalid credentials");

//        // Wait for a new authentication attempt
//        GLib.assert_true (fake_server.wait_for_text_messages ());
//        GLib.assert_true (fake_server.text_messages_count () == 2);
//        var second_password_sent = fake_server.text_message (1);
//        GLib.assert_true (second_password_sent == account.credentials ().password ());
//    }

} // class TestOnWebSocketTextMessageReceivedInvalidCredentialsMessageReconnectWebSocket

} // namespace Testing
} // namespace Occ
