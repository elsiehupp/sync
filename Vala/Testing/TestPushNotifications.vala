/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>
//  #include <QWebSocketServer>
//  #include <QSignalSpy>

namespace Testing {

class TestPushNotifications : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_try_reconnect_capabilites_report_push_notifications_available_reconnect_for_ever () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        account.set_push_notifications_reconnect_interval (0);

        // Let if fail a few times
        GLib.assert_true (fail_three_authentication_attempts (fake_server, account));
        GLib.assert_true (fail_three_authentication_attempts (fake_server, account));

        // Push notifications should try to reconnect
        GLib.assert_true (fake_server.authenticate_account (account));
    }


    /***********************************************************
    ***********************************************************/
    private void test_setup_correct_credentials_authenticate_and_emit_ready () {
        FakeWebSocketServer fake_server;
        std.unique_ptr<QSignalSpy> files_changed_spy;
        std.unique_ptr<QSignalSpy> notifications_changed_spy;
        std.unique_ptr<QSignalSpy> activities_changed_spy;
        var account = FakeWebSocketServer.create_account ();

        GLib.assert_true (fake_server.authenticate_account (
        //      account, [&] (Occ.PushNotifications push_notifications) {
        //          files_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.files_changed));
        //          notifications_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.notifications_changed));
        //          activities_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.activities_changed));
        //      },
        //      [&] {
        //          GLib.assert_true (verify_called_once_with_account (*files_changed_spy, account));
        //          GLib.assert_true (verify_called_once_with_account (*notifications_changed_spy, account));
        //          GLib.assert_true (verify_called_once_with_account (*activities_changed_spy, account));
        //      }));
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_text_message_received_notify_file_message_emit_files_changed () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);
        QSignalSpy files_changed_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.files_changed);

        socket.send_text_message ("notify_file");

        // files_changed signal should be emitted
        GLib.assert_true (files_changed_spy.wait ());
        GLib.assert_true (verify_called_once_with_account (files_changed_spy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_text_message_received_notify_activity_message_emit_notification () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);
        QSignalSpy activity_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.activities_changed);
        GLib.assert_true (activity_spy.is_valid ());

        // Send notify_file push notification
        socket.send_text_message ("notify_activity");

        // notification signal should be emitted
        GLib.assert_true (activity_spy.wait ());
        GLib.assert_true (verify_called_once_with_account (activity_spy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_text_message_received_notify_notification_message_emit_notification () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);
        QSignalSpy notification_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.notifications_changed);
        GLib.assert_true (notification_spy.is_valid ());

        // Send notify_file push notification
        socket.send_text_message ("notify_notification");

        // notification signal should be emitted
        GLib.assert_true (notification_spy.wait ());
        GLib.assert_true (verify_called_once_with_account (notification_spy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_text_message_received_invalid_credentials_message_reconnect_web_socket () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        // Need to set reconnect timer interval to zero for tests
        account.push_notifications ().set_reconnect_timer_interval (0);

        // Wait for authentication attempt and then sent invalid credentials
        GLib.assert_true (fake_server.wait_for_text_messages ());
        GLib.assert_cmp (fake_server.text_messages_count (), 2);
        var socket = fake_server.socket_for_text_message (0);
        var first_password_sent = fake_server.text_message (1);
        GLib.assert_cmp (first_password_sent, account.credentials ().password ());
        fake_server.clear_text_messages ();
        socket.send_text_message ("err : Invalid credentials");

        // Wait for a new authentication attempt
        GLib.assert_true (fake_server.wait_for_text_messages ());
        GLib.assert_cmp (fake_server.text_messages_count (), 2);
        var second_password_sent = fake_server.text_message (1);
        GLib.assert_cmp (second_password_sent, account.credentials ().password ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_error_connection_lost_emit_connection_lost () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy connection_lost_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.connection_lost);
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account.data (), &Occ.Account.push_notifications_disabled);
        GLib.assert_true (connection_lost_spy.is_valid ());

        // Wait for authentication and then sent a network error
        GLib.assert_true (fake_server.wait_for_text_messages ());
        GLib.assert_cmp (fake_server.text_messages_count (), 2);
        var socket = fake_server.socket_for_text_message (0);
        socket.on_signal_abort ();

        GLib.assert_true (connection_lost_spy.wait ());
        // Account handled connection_lost signal and disabled push notifications
        GLib.assert_cmp (push_notifications_disabled_spy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_setup_max_connection_attempts_reached_disable_push_notifications () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account.data (), &Occ.Account.push_notifications_disabled);

        GLib.assert_true (fail_three_authentication_attempts (fake_server, account));
        // Account disabled the push notifications
        GLib.assert_cmp (push_notifications_disabled_spy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_on_web_socket_ssl_error_ssl_error_disable_push_notifications () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account.data (), &Occ.Account.push_notifications_disabled);

        GLib.assert_true (fake_server.wait_for_text_messages ());
        // FIXME: This a little bit ugly but I had no better idea how to trigger a error on the websocket client.
        // The websocket that is retrived through the server is not connected to the ssl error signal.
        var push_notifications_web_socket_children = account.push_notifications ().find_children<QWebSocket> ();
        GLib.assert_true (push_notifications_web_socket_children.size () == 1);
        /* emit */ push_notifications_web_socket_children[0].ssl_errors (GLib.List<QSslError> ());

        // Account handled connection_lost signal and the authentication_failed Signal should be emitted
        GLib.assert_cmp (push_notifications_disabled_spy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_account_web_socket_connection_lost_emit_notifications_disabled () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        // Need to set reconnect timer interval to zero for tests
        account.push_notifications ().set_reconnect_timer_interval (0);
        var socket = fake_server.authenticate_account (account);
        GLib.assert_true (socket);

        QSignalSpy connection_lost_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.connection_lost);
        GLib.assert_true (connection_lost_spy.is_valid ());

        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account.data (), &Occ.Account.push_notifications_disabled);
        GLib.assert_true (push_notifications_disabled_spy.is_valid ());

        // Wait for authentication and then sent a network error
        socket.on_signal_abort ();

        GLib.assert_true (push_notifications_disabled_spy.wait ());
        GLib.assert_cmp (push_notifications_disabled_spy.count (), 1);

        GLib.assert_cmp (connection_lost_spy.count (), 1);

        var account_sent = push_notifications_disabled_spy.at (0).at (0).value<Occ.Account> ();
        GLib.assert_cmp (account_sent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_account_web_socket_authentication_failed_emit_notifications_disabled () {
        FakeWebSocketServer fake_server;
        var account = FakeWebSocketServer.create_account ();
        account.set_push_notifications_reconnect_interval (0);
        QSignalSpy push_notifications_disabled_spy = new QSignalSpy (account.data (), &Occ.Account.push_notifications_disabled);
        GLib.assert_true (push_notifications_disabled_spy.is_valid ());

        GLib.assert_true (fail_three_authentication_attempts (fake_server, account));

        // Now the push_notifications_disabled Signal should be emitted
        GLib.assert_cmp (push_notifications_disabled_spy.count (), 1);
        var account_sent = push_notifications_disabled_spy.at (0).at (0).value<Occ.Account> ();
        GLib.assert_cmp (account_sent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_ping_timeout_ping_timed_out_reconnect () {
        FakeWebSocketServer fake_server;
        std.unique_ptr<QSignalSpy> files_changed_spy;
        std.unique_ptr<QSignalSpy> notifications_changed_spy;
        std.unique_ptr<QSignalSpy> activities_changed_spy;
        var account = FakeWebSocketServer.create_account ();
        GLib.assert_true (fake_server.authenticate_account (account));

        // Set the ping timeout interval to zero and check if the server attemps to authenticate again
        fake_server.clear_text_messages ();
        account.push_notifications ().set_ping_interval (0);
        GLib.assert_true (fake_server.authenticate_account (
        //      account, [&] (Occ.PushNotifications push_notifications) {
        //          files_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.files_changed));
        //          notifications_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.notifications_changed));
        //          activities_changed_spy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.activities_changed));
        //      },
        //      [&] {
        //          GLib.assert_true (verify_called_once_with_account (*files_changed_spy, account));
        //          GLib.assert_true (verify_called_once_with_account (*notifications_changed_spy, account));
        //          GLib.assert_true (verify_called_once_with_account (*activities_changed_spy, account));
        //      }));
    }

    static int return_false_on_fail (var expr) {
        if (! (expr)) {
            return false;
        }
    }
    
    static bool verify_called_once_with_account (QSignalSpy spy, Occ.AccountPointer account) {
        return_false_on_fail (spy.count () == 1);
        var account_from_spy = spy.at (0).at (0).value<Occ.Account> ();
        return_false_on_fail (account_from_spy == account.data ());
    
        return true;
    }
    
    static bool fail_three_authentication_attempts (FakeWebSocketServer fake_server, Occ.AccountPointer account) {
        return_false_on_fail (account);
        return_false_on_fail (account.push_notifications ());
    
        account.push_notifications ().set_reconnect_timer_interval (0);
    
        QSignalSpy authentication_failed_spy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.authentication_failed);
    
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
        return_false_on_fail (authentication_failed_spy.count () == 1);
    
        return true;
    }

} // class TestPushNotifications
} // namespace Testing
