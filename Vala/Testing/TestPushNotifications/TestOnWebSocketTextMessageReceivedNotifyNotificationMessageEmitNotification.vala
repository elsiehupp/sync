namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketTextMessageReceivedNotifyNotificationMessageEmitNotification

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketTextMessageReceivedNotifyNotificationMessageEmitNotification : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestOnWebSocketTextMessageReceivedNotifyNotificationMessageEmitNotification () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);
        QSignalSpy notification_spy = new QSignalSpy (account.push_notifications (), &PushNotificationManager.notifications_changed);
        GLib.assert_true (notification_spy.is_valid);

        // Send notify_file push notification
        socket.send_text_message ("notify_notification");

        // notification signal should be emitted
        GLib.assert_true (notification_spy.wait ());
        GLib.assert_true (verify_called_once_with_account (notification_spy, account));
    }

} // class TestOnWebSocketTextMessageReceivedNotifyNotificationMessageEmitNotification

} // namespace Testing
} // namespace Occ
