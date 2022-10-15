namespace Occ {
namespace Testing {

/***********************************************************
@class TestPingTimeoutPingTimeoutReconnect

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestPingTimeoutPingTimeoutReconnect : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestPingTimeoutPingTimeoutReconnect () {
        //  FakeWebSocketServer fake_server;
        //  GLib.SignalSpy files_changed_spy;
        //  GLib.SignalSpy notifications_changed_spy;
        //  GLib.SignalSpy activities_changed_spy;
        //  var account = FakeWebSocketServer.create_account ();
        //  GLib.assert_true (fake_server.authenticate_account (account));

        //  // Set the ping timeout interval to zero and check if the server attemps to authenticate again
        //  fake_server.clear_text_messages ();
        //  account.push_notifications ().set_ping_interval (0);
        //  GLib.assert_true (
        //      fake_server.authenticate_account (
        //          account,
        //          this.authentication_delegate_ping_timeout_ping_timed_out_reconnect_1,
        //          this.authentication_delegate_ping_timeout_ping_timed_out_reconnect_2
        //      )
        //  );
    }


    private void authentication_delegate_ping_timeout_ping_timed_out_reconnect_1 (PushNotificationManager push_notifications) {
        //  files_changed_spy.reset (
        //      new GLib.SignalSpy (
        //          push_notifications,
        //          PushNotificationManager.files_changed
        //      )
        //  );
        //  notifications_changed_spy.reset (
        //      new GLib.SignalSpy (
        //          push_notifications,
        //          PushNotificationManager.notifications_changed
        //      )
        //  );
        //  activities_changed_spy.reset (
        //      new GLib.SignalSpy (
        //          push_notifications,
        //          PushNotificationManager.activities_changed
        //      )
        //  );
    }


    private void authentication_delegate_ping_timeout_ping_timed_out_reconnect_2 () {
        //  GLib.assert_true (verify_called_once_with_account (files_changed_spy, account));
        //  GLib.assert_true (verify_called_once_with_account (notifications_changed_spy, account));
        //  GLib.assert_true (verify_called_once_with_account (activities_changed_spy, account));
    }

} // class TestPingTimeoutPingTimeoutReconnect

} // namespace Testing
} // namespace Occ
