/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QSignalSpy>
//  #include <QTest>
//  #include <cstdint>
//  #include <functional>

namespace Testing {

class FakeWebSocketServer : GLib.Object {


    /***********************************************************
    ***********************************************************/
    private QWebSocketServer web_socket_server;

    /***********************************************************
    ***********************************************************/
    private std.unique_ptr<QSignalSpy> process_text_message_spy;


    void signal_closed ();
    void signal_process_text_message (QWebSocket sender, string message);

    /***********************************************************
    ***********************************************************/
    public FakeWebSocketServer (uint16 port = 12345, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.web_socket_server = new QWebSocketServer ("Fake Server", QWebSocketServer.NonSecureMode, this));
        if (!this.web_socket_server.listen (QHostAddress.Any, port)) {
            Q_UNREACHABLE ();
        }
        connect (this.web_socket_server, &QWebSocketServer.newConnection, this, &FakeWebSocketServer.on_signal_new_connection);
        connect (this.web_socket_server, &QWebSocketServer.signal_closed, this, &FakeWebSocketServer.signal_closed);
        qCInfo (lcFakeWebSocketServer) + "Open fake websocket server on port:" + port;
        this.process_text_message_spy = std.make_unique<QSignalSpy> (this, &FakeWebSocketServer.signal_process_text_message);
    }

    ~FakeWebSocketServer () {
        close ();
    }

    /***********************************************************
    ***********************************************************/
    public QWebSocket authenticateAccount (Occ.AccountPointer account, std.function<void (Occ.PushNotifications pushNotifications)> beforeAuthentication, std.function<void (void)> afterAuthentication) {
        const var pushNotifications = account.pushNotifications ();
        //  Q_ASSERT (pushNotifications);
        QSignalSpy readySpy (pushNotifications, &Occ.PushNotifications.ready);

        beforeAuthentication (pushNotifications);

        // Wait for authentication
        if (!waitForTextMessages ()) {
            return null;
        }

        // Right authentication data should be sent
        if (text_messages_count () != 2) {
            return null;
        }

        const var socket = socketForTextMessage (0);
        const var userSent = textMessage (0);
        const var passwordSent = textMessage (1);

        if (userSent != account.credentials ().user () || passwordSent != account.credentials ().password ()) {
            return null;
        }

        // Sent authenticated
        socket.sendTextMessage ("authenticated");

        // Wait for ready signal
        readySpy.wait ();
        if (readySpy.count () != 1 || !account.pushNotifications ().isReady ()) {
            return null;
        }

        afterAuthentication ();

        return socket;
    }

    /***********************************************************
    ***********************************************************/
    public void close () {
        if (this.web_socket_server.isListening ()) {
            qCInfo (lcFakeWebSocketServer) + "Close fake websocket server";

            this.web_socket_server.close ();
            qDeleteAll (this.clients.begin (), this.clients.end ());
        }
    }

    /***********************************************************
    ***********************************************************/
    public bool waitForTextMessages () {
        return this.process_text_message_spy.wait ();
    }

    /***********************************************************
    ***********************************************************/
    public uint32 text_messages_count () {
        return this.process_text_message_spy.count ();
    }

    /***********************************************************
    ***********************************************************/
    public string textMessage (int message_number) {
        //  Q_ASSERT (0 <= message_number && message_number < this.process_text_message_spy.count ());
        return this.process_text_message_spy.at (message_number).at (1).toString ();
    }

    /***********************************************************
    ***********************************************************/
    public QWebSocket socketForTextMessage (int message_number) {
        //  Q_ASSERT (0 <= message_number && message_number < this.process_text_message_spy.count ());
        return this.process_text_message_spy.at (message_number).at (0).value<QWebSocket> ();
    }

    /***********************************************************
    ***********************************************************/
    public void clearTextMessages () {
        this.process_text_message_spy.clear ();
    }

    /***********************************************************
    ***********************************************************/
    public static Occ.AccountPointer createAccount (string username = "user", string password = "password") {
        var account = Occ.Account.create ();

        string[] typeList;
        typeList.append ("files");
        typeList.append ("activities");
        typeList.append ("notifications");

        string websocketUrl ("ws://localhost:12345");

        QVariantMap endpointsMap;
        endpointsMap["websocket"] = websocketUrl;

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;
        notifyPushMap["endpoints"] = endpointsMap;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        account.setCapabilities (capabilitiesMap);

        var credentials = new CredentialsStub (username, password);
        account.setCredentials (credentials);

        return account;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_next_message_internal (string message) {
        var client = qobject_cast<QWebSocket> (sender ());
        /* emit */ signal_process_text_message (client, message);
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection () {
        qCInfo (lcFakeWebSocketServer) + "New connection on fake websocket server";

        var socket = this.web_socket_server.nextPendingConnection ();

        connect (socket, &QWebSocket.textMessageReceived, this, &FakeWebSocketServer.on_signal_process_next_message_internal);
        connect (socket, &QWebSocket.disconnected, this, &FakeWebSocketServer.on_signal_socket_disconnected);

        this.clients + socket;
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_socket_disconnected () {
        qCInfo (lcFakeWebSocketServer) + "Socket disconnected";

        var client = qobject_cast<QWebSocket> (sender ());

        if (client) {
            this.clients.removeAll (client);
            client.deleteLater ();
        }
    }

}
}
