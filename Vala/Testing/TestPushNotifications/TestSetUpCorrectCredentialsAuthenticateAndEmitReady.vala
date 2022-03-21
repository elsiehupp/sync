namespace Occ {
namespace Testing {

/***********************************************************
@class TestSetUpCorrectCredentialsAuthenticateAndEmitReady

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSetUpCorrectCredentialsAuthenticateAndEmitReady : AbstractTestPushNotifications {

    /***********************************************************
    ***********************************************************/
    private TestSetUpCorrectCredentialsAuthenticateAndEmitReady () {
        FakeWebSocketServer fake_server;
        QSignalSpy files_changed_spy;
        QSignalSpy notifications_changed_spy;
        QSignalSpy activities_changed_spy;
        var account = FakeWebSocketServer.create_account ();

        GLib.assert_true (
            fake_server.authenticate_account (
                account,
                authentication_delegate_1,
                authentication_delegate_1
            )
        );
    }


    private void authentication_delegate_setup_correct_credentials_authenticate_and_emit_read_1 (PushNotifications push_notifications) {
        files_changed_spy.on_signal_reset (
            new QSignalSpy (
                push_notifications,
                PushNotifications.files_changed
            )
        );
        notifications_changed_spy.on_signal_reset (
            new QSignalSpy (
                push_notifications,
                PushNotifications.notifications_changed
            )
        );
        activities_changed_spy.on_signal_reset (
            new QSignalSpy (
                push_notifications,
                PushNotifications.activities_changed
            )
        );
    }


    private void authentication_delegate_setup_correct_credentials_authenticate_and_emit_read_2 () {
        GLib.assert_true (verify_called_once_with_account (*files_changed_spy, account));
        GLib.assert_true (verify_called_once_with_account (*notifications_changed_spy, account));
        GLib.assert_true (verify_called_once_with_account (*activities_changed_spy, account));
    }

} // class TestSetUpCorrectCredentialsAuthenticateAndEmitReady

} // namespace Testing
} // namespace Occ
