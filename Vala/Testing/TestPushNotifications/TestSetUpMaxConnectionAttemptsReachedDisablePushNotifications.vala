namespace Occ {
namespace Testing {

/***********************************************************
@class TestSetUpMaxConnectionAttemptsReachedDisablePushNotifications

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSetUpMaxConnectionAttemptsReachedDisablePushNotifications : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestSetUpMaxConnectionAttemptsReachedDisablePushNotifications () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account, &Account.push_notifications_disabled);

        GLib.assert_true (fail_three_authentication_attempts (fake_server, account));
        // Account disabled the push notifications
        GLib.assert_true (push_notifications_disabled_spy.count () == 1);
    }

} // class TestSetUpMaxConnectionAttemptsReachedDisablePushNotifications

} // namespace Testing
} // namespace Occ
