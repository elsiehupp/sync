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
    private void testTryReconnect_capabilitesReportPushNotificationsAvailable_reconnectForEver () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        account.setPushNotificationsReconnectInterval (0);

        // Let if fail a few times
        GLib.assert_true (failThreeAuthenticationAttempts (fakeServer, account));
        GLib.assert_true (failThreeAuthenticationAttempts (fakeServer, account));

        // Push notifications should try to reconnect
        GLib.assert_true (fakeServer.authenticateAccount (account));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetup_correctCredentials_authenticateAndEmitReady () {
        FakeWebSocketServer fakeServer;
        std.unique_ptr<QSignalSpy> filesChangedSpy;
        std.unique_ptr<QSignalSpy> notificationsChangedSpy;
        std.unique_ptr<QSignalSpy> activitiesChangedSpy;
        var account = FakeWebSocketServer.create_account ();

        GLib.assert_true (fakeServer.authenticateAccount (
        //      account, [&] (Occ.PushNotifications push_notifications) {
        //          filesChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.filesChanged));
        //          notificationsChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.notificationsChanged));
        //          activitiesChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.activitiesChanged));
        //      },
        //      [&] {
        //          GLib.assert_true (verifyCalledOnceWithAccount (*filesChangedSpy, account));
        //          GLib.assert_true (verifyCalledOnceWithAccount (*notificationsChangedSpy, account));
        //          GLib.assert_true (verifyCalledOnceWithAccount (*activitiesChangedSpy, account));
        //      }));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyFileMessage_emitFilesChanged () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        var socket = fakeServer.authenticateAccount (account);
        GLib.assert_true (socket);
        QSignalSpy filesChangedSpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.filesChanged);

        socket.send_text_message ("notify_file");

        // filesChanged signal should be emitted
        GLib.assert_true (filesChangedSpy.wait ());
        GLib.assert_true (verifyCalledOnceWithAccount (filesChangedSpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyActivityMessage_emitNotification () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        var socket = fakeServer.authenticateAccount (account);
        GLib.assert_true (socket);
        QSignalSpy activitySpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.activitiesChanged);
        GLib.assert_true (activitySpy.is_valid ());

        // Send notify_file push notification
        socket.send_text_message ("notify_activity");

        // notification signal should be emitted
        GLib.assert_true (activitySpy.wait ());
        GLib.assert_true (verifyCalledOnceWithAccount (activitySpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyNotificationMessage_emitNotification () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        var socket = fakeServer.authenticateAccount (account);
        GLib.assert_true (socket);
        QSignalSpy notificationSpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.notificationsChanged);
        GLib.assert_true (notificationSpy.is_valid ());

        // Send notify_file push notification
        socket.send_text_message ("notify_notification");

        // notification signal should be emitted
        GLib.assert_true (notificationSpy.wait ());
        GLib.assert_true (verifyCalledOnceWithAccount (notificationSpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_invalidCredentialsMessage_reconnectWebSocket () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        // Need to set reconnect timer interval to zero for tests
        account.push_notifications ().setReconnectTimerInterval (0);

        // Wait for authentication attempt and then sent invalid credentials
        GLib.assert_true (fakeServer.wait_for_text_messages ());
        GLib.assert_cmp (fakeServer.text_messages_count (), 2);
        var socket = fakeServer.socket_for_text_message (0);
        var firstPasswordSent = fakeServer.textMessage (1);
        GLib.assert_cmp (firstPasswordSent, account.credentials ().password ());
        fakeServer.clear_text_messages ();
        socket.send_text_message ("err : Invalid credentials");

        // Wait for a new authentication attempt
        GLib.assert_true (fakeServer.wait_for_text_messages ());
        GLib.assert_cmp (fakeServer.text_messages_count (), 2);
        var secondPasswordSent = fakeServer.textMessage (1);
        GLib.assert_cmp (secondPasswordSent, account.credentials ().password ());
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketError_connectionLost_emitConnectionLost () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy connectionLostSpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.connectionLost);
        QSignalSpy push_notificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.push_notificationsDisabled);
        GLib.assert_true (connectionLostSpy.is_valid ());

        // Wait for authentication and then sent a network error
        GLib.assert_true (fakeServer.wait_for_text_messages ());
        GLib.assert_cmp (fakeServer.text_messages_count (), 2);
        var socket = fakeServer.socket_for_text_message (0);
        socket.on_signal_abort ();

        GLib.assert_true (connectionLostSpy.wait ());
        // Account handled connectionLost signal and disabled push notifications
        GLib.assert_cmp (push_notificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetup_maxConnectionAttemptsReached_disablePushNotifications () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy push_notificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.push_notificationsDisabled);

        GLib.assert_true (failThreeAuthenticationAttempts (fakeServer, account));
        // Account disabled the push notifications
        GLib.assert_cmp (push_notificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketSslError_sslError_disablePushNotifications () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        QSignalSpy push_notificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.push_notificationsDisabled);

        GLib.assert_true (fakeServer.wait_for_text_messages ());
        // FIXME : This a little bit ugly but I had no better idea how to trigger a error on the websocket client.
        // The websocket that is retrived through the server is not connected to the ssl error signal.
        var push_notificationsWebSocketChildren = account.push_notifications ().findChildren<QWebSocket> ();
        GLib.assert_true (push_notificationsWebSocketChildren.size () == 1);
        /* emit */ push_notificationsWebSocketChildren[0].sslErrors (GLib.List<QSslError> ());

        // Account handled connectionLost signal and the authenticationFailed Signal should be emitted
        GLib.assert_cmp (push_notificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testAccount_web_socket_connectionLost_emitNotificationsDisabled () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        // Need to set reconnect timer interval to zero for tests
        account.push_notifications ().setReconnectTimerInterval (0);
        var socket = fakeServer.authenticateAccount (account);
        GLib.assert_true (socket);

        QSignalSpy connectionLostSpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.connectionLost);
        GLib.assert_true (connectionLostSpy.is_valid ());

        QSignalSpy push_notificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.push_notificationsDisabled);
        GLib.assert_true (push_notificationsDisabledSpy.is_valid ());

        // Wait for authentication and then sent a network error
        socket.on_signal_abort ();

        GLib.assert_true (push_notificationsDisabledSpy.wait ());
        GLib.assert_cmp (push_notificationsDisabledSpy.count (), 1);

        GLib.assert_cmp (connectionLostSpy.count (), 1);

        var accountSent = push_notificationsDisabledSpy.at (0).at (0).value<Occ.Account> ();
        GLib.assert_cmp (accountSent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void testAccount_web_socket_authenticationFailed_emitNotificationsDisabled () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.create_account ();
        account.setPushNotificationsReconnectInterval (0);
        QSignalSpy push_notificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.push_notificationsDisabled);
        GLib.assert_true (push_notificationsDisabledSpy.is_valid ());

        GLib.assert_true (failThreeAuthenticationAttempts (fakeServer, account));

        // Now the push_notificationsDisabled Signal should be emitted
        GLib.assert_cmp (push_notificationsDisabledSpy.count (), 1);
        var accountSent = push_notificationsDisabledSpy.at (0).at (0).value<Occ.Account> ();
        GLib.assert_cmp (accountSent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPingTimeout_pingTimedOut_reconnect () {
        FakeWebSocketServer fakeServer;
        std.unique_ptr<QSignalSpy> filesChangedSpy;
        std.unique_ptr<QSignalSpy> notificationsChangedSpy;
        std.unique_ptr<QSignalSpy> activitiesChangedSpy;
        var account = FakeWebSocketServer.create_account ();
        GLib.assert_true (fakeServer.authenticateAccount (account));

        // Set the ping timeout interval to zero and check if the server attemps to authenticate again
        fakeServer.clear_text_messages ();
        account.push_notifications ().setPingInterval (0);
        GLib.assert_true (fakeServer.authenticateAccount (
        //      account, [&] (Occ.PushNotifications push_notifications) {
        //          filesChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.filesChanged));
        //          notificationsChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.notificationsChanged));
        //          activitiesChangedSpy.on_signal_reset (new QSignalSpy (push_notifications, &Occ.PushNotifications.activitiesChanged));
        //      },
        //      [&] {
        //          GLib.assert_true (verifyCalledOnceWithAccount (*filesChangedSpy, account));
        //          GLib.assert_true (verifyCalledOnceWithAccount (*notificationsChangedSpy, account));
        //          GLib.assert_true (verifyCalledOnceWithAccount (*activitiesChangedSpy, account));
        //      }));
    }

    static int return_false_on_fail (var expr) {
        if (! (expr)) {
            return false;
        }
    }
    
    static bool verifyCalledOnceWithAccount (QSignalSpy spy, Occ.AccountPointer account) {
        return_false_on_fail (spy.count () == 1);
        var accountFromSpy = spy.at (0).at (0).value<Occ.Account> ();
        return_false_on_fail (accountFromSpy == account.data ());
    
        return true;
    }
    
    static bool failThreeAuthenticationAttempts (FakeWebSocketServer fakeServer, Occ.AccountPointer account) {
        return_false_on_fail (account);
        return_false_on_fail (account.push_notifications ());
    
        account.push_notifications ().setReconnectTimerInterval (0);
    
        QSignalSpy authenticationFailedSpy = new QSignalSpy (account.push_notifications (), &Occ.PushNotifications.authenticationFailed);
    
        // Let three authentication attempts fail
        for (uint8 i = 0; i < 3; ++i) {
            return_false_on_fail (fakeServer.wait_for_text_messages ());
            return_false_on_fail (fakeServer.text_messages_count () == 2);
            var socket = fakeServer.socket_for_text_message (0);
            fakeServer.clear_text_messages ();
            socket.send_text_message ("err : Invalid credentials");
        }
    
        // Now the authenticationFailed Signal should be emitted
        return_false_on_fail (authenticationFailedSpy.wait ());
        return_false_on_fail (authenticationFailedSpy.count () == 1);
    
        return true;
    }

} // class TestPushNotifications
} // namespace Testing
