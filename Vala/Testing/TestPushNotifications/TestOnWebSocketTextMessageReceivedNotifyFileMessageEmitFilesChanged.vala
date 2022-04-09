namespace Occ {
namespace Testing {

/***********************************************************
@class TestOnWebSocketTextMessageReceivedNotifyFileMessageEmitFilesChanged

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestOnWebSocketTextMessageReceivedNotifyFileMessageEmitFilesChanged : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestOnWebSocketTextMessageReceivedNotifyFileMessageEmitFilesChanged () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);
        GLib.SignalSpy files_changed_spy = new GLib.SignalSpy (account.push_notifications (), &PushNotificationManager.files_changed);

        socket.send_text_message ("notify_file");

        // files_changed signal should be emitted
        GLib.assert_true (files_changed_spy.wait ());
        GLib.assert_true (verify_called_once_with_account (files_changed_spy, account));
    }

} // class TestOnWebSocketTextMessageReceivedNotifyFileMessageEmitFilesChanged

} // namespace Testing
} // namespace Occ
