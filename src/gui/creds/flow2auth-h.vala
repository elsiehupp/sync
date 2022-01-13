/*
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

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
// #include <QPointer>
// #include <QUrl>
// #include <QTimer>

namespace Occ {

/**
Job that does the authorization, grants and fetches the access token via Login Flow v2

See : https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
*/
class Flow2Auth : GLib.Object {
public:
    enum TokenAction {
        actionOpenBrowser = 1,
        actionCopyLinkToClipboard
    };
    enum PollStatus {
        statusPollCountdown = 1,
        statusPollNow,
        statusFetchToken,
        statusCopyLinkToClipboard
    };

    Flow2Auth (Account *account, GLib.Object *parent);
    ~Flow2Auth () override;

    enum Result { NotSupported,
        LoggedIn,
        Error };
    Q_ENUM (Result);
    void start ();
    void openBrowser ();
    void copyLinkToClipboard ();
    QUrl authorisationLink ();

signals:
    /**
     * The state has changed.
     * when logged in, appPassword has the value of the app password.
     */
    void result (Flow2Auth.Result result, QString &errorString = QString (),
                const QString &user = QString (), QString &appPassword = QString ());

    void statusChanged (PollStatus status, int secondsLeft);

public slots:
    void slotPollNow ();

private slots:
    void slotPollTimerTimeout ();

private:
    void fetchNewToken (TokenAction action);

    Account *_account;
    QUrl _loginUrl;
    QString _pollToken;
    QString _pollEndpoint;
    QTimer _pollTimer;
    int64 _secondsLeft;
    int64 _secondsInterval;
    bool _isBusy;
    bool _hasToken;
    bool _enforceHttps = false;
};

} // namespace Occ
