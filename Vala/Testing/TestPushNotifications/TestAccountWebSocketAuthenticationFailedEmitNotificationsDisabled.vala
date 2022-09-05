namespace Occ {
namespace Testing {

/***********************************************************
@class TestAccountWebSocketAuthenticationFailedEmitNotificationsDisabled

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestAccountWebSocketAuthenticationFailedEmitNotificationsDisabled : AbstractTestPushNotifications {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestAccountWebSocketAuthenticationFailedEmitNotificationsDisabled () {
    //      FakeWebSocketServer fake_server;
    //      var account = FakeWebSocketServer.create_account ();
    //      account.set_push_notifications_reconnect_interval (0);
    //      GLib.SignalSpy push_notifications_disabled_spy = new GLib.SignalSpy (account, LibSync.Account.push_notifications_disabled);
    //      GLib.assert_true (push_notifications_disabled_spy.is_valid);

    //      GLib.assert_true (fail_three_authentication_attempts (fake_server, account));

    //      // Now the push_notifications_disabled Signal should be emitted
    //      GLib.assert_true (push_notifications_disabled_spy.length == 1);
    //      var account_sent = push_notifications_disabled_spy.at (0).at (0).value<LibSync.Account> ();
    //      GLib.assert_true (account_sent == account);
    //  }

} // class TestAccountWebSocketAuthenticationFailedEmitNotificationsDisabled

} // namespace Testing
} // namespace Occ
