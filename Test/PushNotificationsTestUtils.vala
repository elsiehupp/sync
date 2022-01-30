/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <functional>

// #include <QWebSocketServer>
// #include <QWebSocket>
// #include <QSignalSpy>

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
    public 
    public static Occ.AccountPointer createAccount (string username = "user", string password = "password");

signals:
    void closed ();
    void processTextMessage (QWebSocket sender, string message);


    /***********************************************************
    ***********************************************************/
    private void on_process_next_message_internal (string message);
    private void on_new_connection ();
    private void on_socket_disconnected ();


    /***********************************************************
    ***********************************************************/
    private QWebSocketServer _webSocketServer;

    /***********************************************************
    ***********************************************************/
    private 
    private std.unique_ptr<QSignalSpy> _processTextMessageSpy;
};

class CredentialsStub : Occ.AbstractCredentials {

    /***********************************************************
    ***********************************************************/
    public CredentialsStub (string user, string password);

    /***********************************************************
    ***********************************************************/
    public 
    public string authType () override;
    public string user () override;
    public string password () override;
    public QNetworkAccessManager createQNAM () override;
    public bool ready () override;
    public void fetchFromKeychain () override;
    public void askFromUser () override;

    /***********************************************************
    ***********************************************************/
    public bool stillValid (QNetworkReply reply) override;
    public void persist () override;
    public void invalidateToken () override;
    public void forgetSensitiveData () override;


    /***********************************************************
    ***********************************************************/
    private string _user;
    private string _password;
};









// #include <QLoggingCategory>
// #include <QSignalSpy>
// #include <QTest>
// #include <cstdint>
// #include <functional>

Q_LOGGING_CATEGORY (lcFakeWebSocketServer, "nextcloud.test.fakewebserver", QtInfoMsg)

FakeWebSocketServer.FakeWebSocketServer (uint16 port, GLib.Object parent)
    : GLib.Object (parent)
    , _webSocketServer (new QWebSocketServer (QStringLiteral ("Fake Server"), QWebSocketServer.NonSecureMode, this)) {
    if (!_webSocketServer.listen (QHostAddress.Any, port)) {
        Q_UNREACHABLE ();
    }
    connect (_webSocketServer, &QWebSocketServer.newConnection, this, &FakeWebSocketServer.on_new_connection);
    connect (_webSocketServer, &QWebSocketServer.closed, this, &FakeWebSocketServer.closed);
    qCInfo (lcFakeWebSocketServer) << "Open fake websocket server on port:" << port;
    _processTextMessageSpy = std.make_unique<QSignalSpy> (this, &FakeWebSocketServer.processTextMessage);
}

FakeWebSocketServer.~FakeWebSocketServer () {
    close ();
}

QWebSocket *FakeWebSocketServer.authenticateAccount (Occ.AccountPointer account, std.function<void (Occ.PushNotifications pushNotifications)> beforeAuthentication, std.function<void (void)> afterAuthentication) {
    const var pushNotifications = account.pushNotifications ();
    Q_ASSERT (pushNotifications);
    QSignalSpy readySpy (pushNotifications, &Occ.PushNotifications.ready);

    beforeAuthentication (pushNotifications);

    // Wait for authentication
    if (!waitForTextMessages ()) {
        return nullptr;
    }

    // Right authentication data should be sent
    if (textMessagesCount () != 2) {
        return nullptr;
    }

    const var socket = socketForTextMessage (0);
    const var userSent = textMessage (0);
    const var passwordSent = textMessage (1);

    if (userSent != account.credentials ().user () || passwordSent != account.credentials ().password ()) {
        return nullptr;
    }

    // Sent authenticated
    socket.sendTextMessage ("authenticated");

    // Wait for ready signal
    readySpy.wait ();
    if (readySpy.count () != 1 || !account.pushNotifications ().isReady ()) {
        return nullptr;
    }

    afterAuthentication ();

    return socket;
}

void FakeWebSocketServer.close () {
    if (_webSocketServer.isListening ()) {
        qCInfo (lcFakeWebSocketServer) << "Close fake websocket server";

        _webSocketServer.close ();
        qDeleteAll (_clients.begin (), _clients.end ());
    }
}

void FakeWebSocketServer.on_process_next_message_internal (string message) {
    var client = qobject_cast<QWebSocket> (sender ());
    emit processTextMessage (client, message);
}

void FakeWebSocketServer.on_new_connection () {
    qCInfo (lcFakeWebSocketServer) << "New connection on fake websocket server";

    var socket = _webSocketServer.nextPendingConnection ();

    connect (socket, &QWebSocket.textMessageReceived, this, &FakeWebSocketServer.on_process_next_message_internal);
    connect (socket, &QWebSocket.disconnected, this, &FakeWebSocketServer.on_socket_disconnected);

    _clients << socket;
}

void FakeWebSocketServer.on_socket_disconnected () {
    qCInfo (lcFakeWebSocketServer) << "Socket disconnected";

    var client = qobject_cast<QWebSocket> (sender ());

    if (client) {
        _clients.removeAll (client);
        client.deleteLater ();
    }
}

bool FakeWebSocketServer.waitForTextMessages () {
    return _processTextMessageSpy.wait ();
}

uint32_t FakeWebSocketServer.textMessagesCount () {
    return _processTextMessageSpy.count ();
}

string FakeWebSocketServer.textMessage (int messageNumber) {
    Q_ASSERT (0 <= messageNumber && messageNumber < _processTextMessageSpy.count ());
    return _processTextMessageSpy.at (messageNumber).at (1).toString ();
}

QWebSocket *FakeWebSocketServer.socketForTextMessage (int messageNumber) {
    Q_ASSERT (0 <= messageNumber && messageNumber < _processTextMessageSpy.count ());
    return _processTextMessageSpy.at (messageNumber).at (0).value<QWebSocket> ();
}

void FakeWebSocketServer.clearTextMessages () {
    _processTextMessageSpy.clear ();
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

CredentialsStub.CredentialsStub (string user, string password)
    : _user (user)
    , _password (password) {
}

string CredentialsStub.authType () {
    return "";
}

string CredentialsStub.user () {
    return _user;
}

string CredentialsStub.password () {
    return _password;
}

QNetworkAccessManager *CredentialsStub.createQNAM () {
    return nullptr;
}

bool CredentialsStub.ready () {
    return false;
}

void CredentialsStub.fetchFromKeychain () { }

void CredentialsStub.askFromUser () { }

bool CredentialsStub.stillValid (QNetworkReply * /*reply*/) {
    return false;
}

void CredentialsStub.persist () { }

void CredentialsStub.invalidateToken () { }

void CredentialsStub.forgetSensitiveData () { }
