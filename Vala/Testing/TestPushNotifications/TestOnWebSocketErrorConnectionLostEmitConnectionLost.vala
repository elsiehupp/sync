namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketErrorConnectionLostEmitConnectionLost

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketErrorConnectionLostEmitConnectionLost : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestOnWebSocketErrorConnectionLostEmitConnectionLost () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy connection_lost_spy = new QSignalSpy (account.push_notifications (), &PushNotificationManager.connection_lost);
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account, &Account.push_notifications_disabled);
        GLib.assert_true (connection_lost_spy.is_valid);

        // Wait for authentication and then sent a network error
        GLib.assert_true (fake_server.wait_for_text_messages ());
        GLib.assert_true (fake_server.text_messages_count () == 2);
        var socket = fake_server.socket_for_text_message (0);
        socket.on_signal_abort ();

        GLib.assert_true (connection_lost_spy.wait ());
        // Account handled connection_lost signal and disabled push notifications
        GLib.assert_true (push_notifications_disabled_spy.count () == 1);
    }

} // class TestOnWebSocketErrorConnectionLostEmitConnectionLost

} // namespace Testing
} // namespace Occ
