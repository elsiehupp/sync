/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

class FakeWebSocketServer : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeWebSocketServer (uint16 port = 12345, GLib.Object parent = new GLib.Object ());

    ~FakeWebSocketServer () override;

    /***********************************************************
    ***********************************************************/
    public QWebSocket authenticateAccount (

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public static Occ.AccountPointer createAccount (string username = "user", string password = "password");

signals:
    void closed ();
    void processTextMessage (QWebSocket sender, string message);


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_next_message_internal (string message);
    private void on_signal_new_connection ();
    private void on_signal_socket_disconnected ();


    /***********************************************************
    ***********************************************************/
    private QWebSocketServer this.webSocketServer;

    /***********************************************************
    ***********************************************************/
    private 
    private std.unique_ptr<QSignalSpy> this.processTextMessageSpy;
}


//  #include <QLoggingCategory>
//  #include <QSignalSpy>
//  #include <QTest>
//  #include <cstdint>
//  #include <functional>

FakeWebSocketServer.FakeWebSocketServer (uint16 port, GLib.Object parent)
    : GLib.Object (parent)
    this.webSocketServer (new QWebSocketServer (QStringLiteral ("Fake Server"), QWebSocketServer.NonSecureMode, this)) {
    if (!this.webSocketServer.listen (QHostAddress.Any, port)) {
        Q_UNREACHABLE ();
    }
    connect (this.webSocketServer, &QWebSocketServer.newConnection, this, &FakeWebSocketServer.on_signal_new_connection);
    connect (this.webSocketServer, &QWebSocketServer.closed, this, &FakeWebSocketServer.closed);
    qCInfo (lcFakeWebSocketServer) + "Open fake websocket server on port:" + port;
    this.processTextMessageSpy = std.make_unique<QSignalSpy> (this, &FakeWebSocketServer.processTextMessage);
}

FakeWebSocketServer.~FakeWebSocketServer () {
    close ();
}

QWebSocket *FakeWebSocketServer.authenticateAccount (Occ.AccountPointer account, std.function<void (Occ.PushNotifications pushNotifications)> beforeAuthentication, std.function<void (void)> afterAuthentication) {
    const var pushNotifications = account.pushNotifications ();
    //  Q_ASSERT (pushNotifications);
    QSignalSpy readySpy (pushNotifications, &Occ.PushNotifications.ready);

    beforeAuthentication (pushNotifications);

    // Wait for authentication
    if (!waitForTextMessages ()) {
        return null;
    }

    // Right authentication data should be sent
    if (textMessagesCount () != 2) {
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

void FakeWebSocketServer.close () {
    if (this.webSocketServer.isListening ()) {
        qCInfo (lcFakeWebSocketServer) + "Close fake websocket server";

        this.webSocketServer.close ();
        qDeleteAll (this.clients.begin (), this.clients.end ());
    }
}

void FakeWebSocketServer.on_signal_process_next_message_internal (string message) {
    var client = qobject_cast<QWebSocket> (sender ());
    /* emit */ processTextMessage (client, message);
}

void FakeWebSocketServer.on_signal_new_connection () {
    qCInfo (lcFakeWebSocketServer) + "New connection on fake websocket server";

    var socket = this.webSocketServer.nextPendingConnection ();

    connect (socket, &QWebSocket.textMessageReceived, this, &FakeWebSocketServer.on_signal_process_next_message_internal);
    connect (socket, &QWebSocket.disconnected, this, &FakeWebSocketServer.on_signal_socket_disconnected);

    this.clients + socket;
}

void FakeWebSocketServer.on_signal_socket_disconnected () {
    qCInfo (lcFakeWebSocketServer) + "Socket disconnected";

    var client = qobject_cast<QWebSocket> (sender ());

    if (client) {
        this.clients.removeAll (client);
        client.deleteLater ();
    }
}

bool FakeWebSocketServer.waitForTextMessages () {
    return this.processTextMessageSpy.wait ();
}

uint32_t FakeWebSocketServer.textMessagesCount () {
    return this.processTextMessageSpy.count ();
}

string FakeWebSocketServer.textMessage (int messageNumber) {
    //  Q_ASSERT (0 <= messageNumber && messageNumber < this.processTextMessageSpy.count ());
    return this.processTextMessageSpy.at (messageNumber).at (1).toString ();
}

QWebSocket *FakeWebSocketServer.socketForTextMessage (int messageNumber) {
    //  Q_ASSERT (0 <= messageNumber && messageNumber < this.processTextMessageSpy.count ());
    return this.processTextMessageSpy.at (messageNumber).at (0).value<QWebSocket> ();
}

void FakeWebSocketServer.clearTextMessages () {
    this.processTextMessageSpy.clear ();
}

Occ.AccountPointer FakeWebSocketServer.createAccount (string username, string password) {
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