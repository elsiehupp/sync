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
public:
    FakeWebSocketServer (uint16 port = 12345, GLib.Object *parent = nullptr);

    ~FakeWebSocketServer () override;

    QWebSocket *authenticateAccount (
        const Occ.AccountPtr account, std.function<void (Occ.PushNotifications *pushNotifications)> beforeAuthentication = [] (Occ.PushNotifications *) {}, std.function<void (void)> afterAuthentication = [] {});

    void close ();

    bool waitForTextMessages ();

    uint32_t textMessagesCount ();

    string textMessage (int messageNumber) const;

    QWebSocket *socketForTextMessage (int messageNumber) const;

    void clearTextMessages ();

    static Occ.AccountPtr createAccount (string &username = "user", string &password = "password");

signals:
    void closed ();
    void processTextMessage (QWebSocket *sender, string &message);

private slots:
    void processTextMessageInternal (string &message);
    void onNewConnection ();
    void socketDisconnected ();

private:
    QWebSocketServer *_webSocketServer;
    QList<QWebSocket> _clients;

    std.unique_ptr<QSignalSpy> _processTextMessageSpy;
};

class CredentialsStub : Occ.AbstractCredentials {

public:
    CredentialsStub (string &user, string &password);
    string authType () const override;
    string user () const override;
    string password () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    void fetchFromKeychain () override;
    void askFromUser () override;

    bool stillValid (QNetworkReply *reply) override;
    void persist () override;
    void invalidateToken () override;
    void forgetSensitiveData () override;

private:
    string _user;
    string _password;
};
