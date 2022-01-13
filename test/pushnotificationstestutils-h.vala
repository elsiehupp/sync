/*
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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

    QString textMessage (int messageNumber) const;

    QWebSocket *socketForTextMessage (int messageNumber) const;

    void clearTextMessages ();

    static Occ.AccountPtr createAccount (QString &username = "user", QString &password = "password");

signals:
    void closed ();
    void processTextMessage (QWebSocket *sender, QString &message);

private slots:
    void processTextMessageInternal (QString &message);
    void onNewConnection ();
    void socketDisconnected ();

private:
    QWebSocketServer *_webSocketServer;
    QList<QWebSocket> _clients;

    std.unique_ptr<QSignalSpy> _processTextMessageSpy;
};

class CredentialsStub : Occ.AbstractCredentials {

public:
    CredentialsStub (QString &user, QString &password);
    QString authType () const override;
    QString user () const override;
    QString password () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    void fetchFromKeychain () override;
    void askFromUser () override;

    bool stillValid (QNetworkReply *reply) override;
    void persist () override;
    void invalidateToken () override;
    void forgetSensitiveData () override;

private:
    QString _user;
    QString _password;
};
