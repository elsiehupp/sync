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
        var account = FakeWebSocketServer.createAccount ();
        account.setPushNotificationsReconnectInterval (0);

        // Let if fail a few times
        //  QVERIFY (failThreeAuthenticationAttempts (fakeServer, account));
        //  QVERIFY (failThreeAuthenticationAttempts (fakeServer, account));

        // Push notifications should try to reconnect
        //  QVERIFY (fakeServer.authenticateAccount (account));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetup_correctCredentials_authenticateAndEmitReady () {
        FakeWebSocketServer fakeServer;
        std.unique_ptr<QSignalSpy> filesChangedSpy;
        std.unique_ptr<QSignalSpy> notificationsChangedSpy;
        std.unique_ptr<QSignalSpy> activitiesChangedSpy;
        var account = FakeWebSocketServer.createAccount ();

        //  QVERIFY (fakeServer.authenticateAccount (
        //      account, [&] (Occ.PushNotifications pushNotifications) {
        //          filesChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.filesChanged));
        //          notificationsChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.notificationsChanged));
        //          activitiesChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.activitiesChanged));
        //      },
        //      [&] {
        //          //  QVERIFY (verifyCalledOnceWithAccount (*filesChangedSpy, account));
        //          //  QVERIFY (verifyCalledOnceWithAccount (*notificationsChangedSpy, account));
        //          //  QVERIFY (verifyCalledOnceWithAccount (*activitiesChangedSpy, account));
        //      }));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyFileMessage_emitFilesChanged () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        const var socket = fakeServer.authenticateAccount (account);
        //  QVERIFY (socket);
        QSignalSpy filesChangedSpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.filesChanged);

        socket.sendTextMessage ("notify_file");

        // filesChanged signal should be emitted
        //  QVERIFY (filesChangedSpy.wait ());
        //  QVERIFY (verifyCalledOnceWithAccount (filesChangedSpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyActivityMessage_emitNotification () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        const var socket = fakeServer.authenticateAccount (account);
        //  QVERIFY (socket);
        QSignalSpy activitySpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.activitiesChanged);
        //  QVERIFY (activitySpy.isValid ());

        // Send notify_file push notification
        socket.sendTextMessage ("notify_activity");

        // notification signal should be emitted
        //  QVERIFY (activitySpy.wait ());
        //  QVERIFY (verifyCalledOnceWithAccount (activitySpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_notifyNotificationMessage_emitNotification () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        const var socket = fakeServer.authenticateAccount (account);
        //  QVERIFY (socket);
        QSignalSpy notificationSpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.notificationsChanged);
        //  QVERIFY (notificationSpy.isValid ());

        // Send notify_file push notification
        socket.sendTextMessage ("notify_notification");

        // notification signal should be emitted
        //  QVERIFY (notificationSpy.wait ());
        //  QVERIFY (verifyCalledOnceWithAccount (notificationSpy, account));
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketTextMessageReceived_invalidCredentialsMessage_reconnectWebSocket () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        // Need to set reconnect timer interval to zero for tests
        account.pushNotifications ().setReconnectTimerInterval (0);

        // Wait for authentication attempt and then sent invalid credentials
        //  QVERIFY (fakeServer.waitForTextMessages ());
        //  QCOMPARE (fakeServer.text_messages_count (), 2);
        const var socket = fakeServer.socketForTextMessage (0);
        const var firstPasswordSent = fakeServer.textMessage (1);
        //  QCOMPARE (firstPasswordSent, account.credentials ().password ());
        fakeServer.clearTextMessages ();
        socket.sendTextMessage ("err : Invalid credentials");

        // Wait for a new authentication attempt
        //  QVERIFY (fakeServer.waitForTextMessages ());
        //  QCOMPARE (fakeServer.text_messages_count (), 2);
        const var secondPasswordSent = fakeServer.textMessage (1);
        //  QCOMPARE (secondPasswordSent, account.credentials ().password ());
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketError_connectionLost_emitConnectionLost () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        QSignalSpy connectionLostSpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.connectionLost);
        QSignalSpy pushNotificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.pushNotificationsDisabled);
        //  QVERIFY (connectionLostSpy.isValid ());

        // Wait for authentication and then sent a network error
        //  QVERIFY (fakeServer.waitForTextMessages ());
        //  QCOMPARE (fakeServer.text_messages_count (), 2);
        var socket = fakeServer.socketForTextMessage (0);
        socket.on_signal_abort ();

        //  QVERIFY (connectionLostSpy.wait ());
        // Account handled connectionLost signal and disabled push notifications
        //  QCOMPARE (pushNotificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetup_maxConnectionAttemptsReached_disablePushNotifications () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        QSignalSpy pushNotificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.pushNotificationsDisabled);

        //  QVERIFY (failThreeAuthenticationAttempts (fakeServer, account));
        // Account disabled the push notifications
        //  QCOMPARE (pushNotificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testOnWebSocketSslError_sslError_disablePushNotifications () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        QSignalSpy pushNotificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.pushNotificationsDisabled);

        //  QVERIFY (fakeServer.waitForTextMessages ());
        // FIXME : This a little bit ugly but I had no better idea how to trigger a error on the websocket client.
        // The websocket that is retrived through the server is not connected to the ssl error signal.
        var pushNotificationsWebSocketChildren = account.pushNotifications ().findChildren<QWebSocket> ();
        //  QVERIFY (pushNotificationsWebSocketChildren.size () == 1);
        /* emit */ pushNotificationsWebSocketChildren[0].sslErrors (GLib.List<QSslError> ());

        // Account handled connectionLost signal and the authenticationFailed Signal should be emitted
        //  QCOMPARE (pushNotificationsDisabledSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testAccount_web_socket_connectionLost_emitNotificationsDisabled () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        // Need to set reconnect timer interval to zero for tests
        account.pushNotifications ().setReconnectTimerInterval (0);
        const var socket = fakeServer.authenticateAccount (account);
        //  QVERIFY (socket);

        QSignalSpy connectionLostSpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.connectionLost);
        //  QVERIFY (connectionLostSpy.isValid ());

        QSignalSpy pushNotificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.pushNotificationsDisabled);
        //  QVERIFY (pushNotificationsDisabledSpy.isValid ());

        // Wait for authentication and then sent a network error
        socket.on_signal_abort ();

        //  QVERIFY (pushNotificationsDisabledSpy.wait ());
        //  QCOMPARE (pushNotificationsDisabledSpy.count (), 1);

        //  QCOMPARE (connectionLostSpy.count (), 1);

        var accountSent = pushNotificationsDisabledSpy.at (0).at (0).value<Occ.Account> ();
        //  QCOMPARE (accountSent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void testAccount_web_socket_authenticationFailed_emitNotificationsDisabled () {
        FakeWebSocketServer fakeServer;
        var account = FakeWebSocketServer.createAccount ();
        account.setPushNotificationsReconnectInterval (0);
        QSignalSpy pushNotificationsDisabledSpy = new QSignalSpy (account.data (), &Occ.Account.pushNotificationsDisabled);
        //  QVERIFY (pushNotificationsDisabledSpy.isValid ());

        //  QVERIFY (failThreeAuthenticationAttempts (fakeServer, account));

        // Now the pushNotificationsDisabled Signal should be emitted
        //  QCOMPARE (pushNotificationsDisabledSpy.count (), 1);
        var accountSent = pushNotificationsDisabledSpy.at (0).at (0).value<Occ.Account> ();
        //  QCOMPARE (accountSent, account.data ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPingTimeout_pingTimedOut_reconnect () {
        FakeWebSocketServer fakeServer;
        std.unique_ptr<QSignalSpy> filesChangedSpy;
        std.unique_ptr<QSignalSpy> notificationsChangedSpy;
        std.unique_ptr<QSignalSpy> activitiesChangedSpy;
        var account = FakeWebSocketServer.createAccount ();
        //  QVERIFY (fakeServer.authenticateAccount (account));

        // Set the ping timeout interval to zero and check if the server attemps to authenticate again
        fakeServer.clearTextMessages ();
        account.pushNotifications ().setPingInterval (0);
        //  QVERIFY (fakeServer.authenticateAccount (
        //      account, [&] (Occ.PushNotifications pushNotifications) {
        //          filesChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.filesChanged));
        //          notificationsChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.notificationsChanged));
        //          activitiesChangedSpy.on_signal_reset (new QSignalSpy (pushNotifications, &Occ.PushNotifications.activitiesChanged));
        //      },
        //      [&] {
        //          //  QVERIFY (verifyCalledOnceWithAccount (*filesChangedSpy, account));
        //          //  QVERIFY (verifyCalledOnceWithAccount (*notificationsChangedSpy, account));
        //          //  QVERIFY (verifyCalledOnceWithAccount (*activitiesChangedSpy, account));
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
        return_false_on_fail (account.pushNotifications ());
    
        account.pushNotifications ().setReconnectTimerInterval (0);
    
        QSignalSpy authenticationFailedSpy = new QSignalSpy (account.pushNotifications (), &Occ.PushNotifications.authenticationFailed);
    
        // Let three authentication attempts fail
        for (uint8 i = 0; i < 3; ++i) {
            return_false_on_fail (fakeServer.waitForTextMessages ());
            return_false_on_fail (fakeServer.text_messages_count () == 2);
            var socket = fakeServer.socketForTextMessage (0);
            fakeServer.clearTextMessages ();
            socket.sendTextMessage ("err : Invalid credentials");
        }
    
        // Now the authenticationFailed Signal should be emitted
        return_false_on_fail (authenticationFailedSpy.wait ());
        return_false_on_fail (authenticationFailedSpy.count () == 1);
    
        return true;
    }

} // class TestPushNotifications
} // namespace Testing
