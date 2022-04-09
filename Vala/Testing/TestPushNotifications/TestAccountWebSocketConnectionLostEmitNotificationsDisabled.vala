namespace Occ {
namespace Testing {

/***********************************************************
@class TestAccountWebSocketConnectionLostEmitNotificationsDisabled

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestAccountWebSocketConnectionLostEmitNotificationsDisabled : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestAccountWebSocketConnectionLostEmitNotificationsDisabled () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        // Need to set reconnect timer interval to zero for tests
        account.push_notifications ().set_reconnect_timer_interval (0);
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);

        GLib.SignalSpy connection_lost_spy = new GLib.SignalSpy (account.push_notifications (), &PushNotificationManager.connection_lost);
        GLib.assert_true (connection_lost_spy.is_valid);

        GLib.SignalSpy push_notifications_disabled_spy = new GLib.SignalSpy (account, &Account.push_notifications_disabled);
        GLib.assert_true (push_notifications_disabled_spy.is_valid);

        // Wait for authentication and then sent a network error
        socket.on_signal_abort ();

        GLib.assert_true (push_notifications_disabled_spy.wait ());
        GLib.assert_true (push_notifications_disabled_spy.length == 1);

        GLib.assert_true (connection_lost_spy.length == 1);

        var account_sent = push_notifications_disabled_spy.at (0).at (0).value<Account> ();
        GLib.assert_true (account_sent == account);
    }

} // class TestAccountWebSocketConnectionLostEmitNotificationsDisabled

} // namespace Testing
} // namespace Occ
