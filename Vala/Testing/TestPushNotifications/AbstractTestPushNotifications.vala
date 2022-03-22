namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestPushNotifications

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public abstract class AbstractTestPushNotifications : GLib.Object {

    protected delegate bool ReturnFalseOnFail ();

    protected static bool return_false_on_fail (ReturnFalseOnFail expression_to_fail) {
        if (!expression_to_fail ()) {
            return false;
        }
        return true;
    }


    protected static bool verify_called_once_with_account (QSignalSpy spy, unowned Account account) {
        return_false_on_fail (spy.length == 1);
        var account_from_spy = spy.at (0).at (0).value<Account> ();
        return_false_on_fail (account_from_spy == account);

        return true;
    }


    protected static bool fail_three_authentication_attempts (FakeWebSocketServer fake_server, unowned Account account) {
        return_false_on_fail (account);
        return_false_on_fail (account.push_notifications ());

        account.push_notifications ().set_reconnect_timer_interval (0);

        QSignalSpy authentication_failed_spy = new QSignalSpy (account.push_notifications (), &PushNotificationManager.authentication_failed);

        // Let three authentication attempts fail
        for (uint8 i = 0; i < 3; ++i) {
            return_false_on_fail (fake_server.wait_for_text_messages ());
            return_false_on_fail (fake_server.text_messages_count () == 2);
            var socket = fake_server.socket_for_text_message (0);
            fake_server.clear_text_messages ();
            socket.send_text_message ("err : Invalid credentials");
        }

        // Now the authentication_failed Signal should be emitted
        return_false_on_fail (authentication_failed_spy.wait ());
        return_false_on_fail (authentication_failed_spy.length == 1);

        return true;
    }

} // class AbstractTestPushNotifications

} // namespace Testing
} // namespace Occ
