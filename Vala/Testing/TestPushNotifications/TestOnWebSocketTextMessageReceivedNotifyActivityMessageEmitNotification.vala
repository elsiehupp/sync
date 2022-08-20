namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketTextMessageReceivedNotifyActivityMessageEmitNotification

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketTextMessageReceivedNotifyActivityMessageEmitNotification : AbstractTestPushNotifications {

//    /***********************************************************
//    ***********************************************************/
//    private TestOnWebSocketTextMessageReceivedNotifyActivityMessageEmitNotification () {
//        FakeWebSocketServer fake_server;
//        var account = FakeWebSocketServer.create_account ();
//        var socket = fake_server.authenticate_account (account);
//        GLib.assert_true (socket);
//        GLib.SignalSpy activity_spy = new GLib.SignalSpy (account.push_notifications (), PushNotificationManager.activities_changed);
//        GLib.assert_true (activity_spy.is_valid);

//        // Send notify_file push notification
//        socket.send_text_message ("notify_activity");

//        // notification signal should be emitted
//        GLib.assert_true (activity_spy.wait ());
//        GLib.assert_true (verify_called_once_with_account (activity_spy, account));
//    }

} // class TestOnWebSocketTextMessageReceivedNotifyActivityMessageEmitNotification

} // namespace Testing
} // namespace Occ
