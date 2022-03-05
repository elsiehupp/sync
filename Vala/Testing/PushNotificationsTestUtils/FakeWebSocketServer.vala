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
        this.web_socket_server = new QWebSocketServer ("Fake Server", QWebSocketServer.NonSecureMode, this);
        if (!this.web_socket_server.listen (QHostAddress.Any, port)) {
            Q_UNREACHABLE ();
        }
        connect (this.web_socket_server, &QWebSocketServer.newConnection, this, &FakeWebSocketServer.on_signal_new_connection);
        connect (this.web_socket_server, &QWebSocketServer.signal_closed, this, &FakeWebSocketServer.signal_closed);
        GLib.info (lcFakeWebSocketServer) + "Open fake websocket server on port:" + port;
        this.process_text_message_spy = std.make_unique<QSignalSpy> (this, &FakeWebSocketServer.signal_process_text_message);
    }

    ~FakeWebSocketServer () {
        close ();
    }

    delegate void BeforeAuthentication (Occ.PushNotifications push_notifications);
    delegate void AfterAuthentication ();

    /***********************************************************
    ***********************************************************/
    public QWebSocket authenticate_account (Occ.AccountPointer account, BeforeAuthentication before_authentication, AfterAuthentication after_authentication) {
        var push_notifications = account.push_notifications ();
        //  Q_ASSERT (push_notifications);
        QSignalSpy ready_spy = new QSignalSpy (push_notifications, &Occ.PushNotifications.ready);

        before_authentication (push_notifications);

        // Wait for authentication
        if (!waitForTextMessages ()) {
            return null;
        }

        // Right authentication data should be sent
        if (text_messages_count () != 2) {
            return null;
        }

        var socket = socketForTextMessage (0);
        var user_sent = text_message (0);
        var password_sent = text_message (1);

        if (user_sent != account.credentials ().user () || password_sent != account.credentials ().password ()) {
            return null;
        }

        // Sent authenticated
        socket.sendTextMessage ("authenticated");

        // Wait for ready signal
        ready_spy.wait ();
        if (ready_spy.count () != 1 || !account.push_notifications ().isReady ()) {
            return null;
        }

        after_authentication ();

        return socket;
    }

    /***********************************************************
    ***********************************************************/
    public void close () {
        if (this.web_socket_server.isListening ()) {
            GLib.info (lcFakeWebSocketServer) + "Close fake websocket server";

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
    public string text_message (int message_number) {
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

        string web_socket_url = "ws://localhost:12345";

        QVariantMap endpoints_map;
        endpoints_map["websocket"] = web_socket_url;

        QVariantMap notify_push_map;
        notify_push_map["type"] = typeList;
        notify_push_map["endpoints"] = endpoints_map;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        account.setCapabilities (capabilities_map);

        var credentials = new CredentialsStub (username, password);
        account.setCredentials (credentials);

        return account;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_next_message_internal (string message) {
        var client = (QWebSocket) sender ();
        /* emit */ signal_process_text_message (client, message);
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection () {
        GLib.info ("New connection on fake websocket server");

        var socket = this.web_socket_server.next_pending_connection ();

        connect (socket, QWebSocket.textMessageReceived, this, FakeWebSocketServer.on_signal_process_next_message_internal);
        connect (socket, QWebSocket.disconnected, this, FakeWebSocketServer.on_signal_socket_disconnected);

        this.clients + socket;
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_socket_disconnected () {
        GLib.info ("Socket disconnected");

        var client = (QWebSocket) sender ();

        if (client) {
            this.clients.removeAll (client);
            client.deleteLater ();
        }
    }

}
}
