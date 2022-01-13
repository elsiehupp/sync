/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QStringList>
// #include <QVariantMap>
// #include <QNetworkReply>

namespace Occ {

/**
This is a job-like class to check that the server is up and that we are connected.
There are two entry points : checkServerAndAuth and checkAuthentication
checkAuthentication is the quick version that only does the propfind
while checkServerAndAuth is doing the 4 calls.

We cannot use the capabilites call to test the l
https://github.com/owncloud/core/issues/12930

Here follows the state machine

\code{.unparsed}
*--. checkServerAndAuth  (check status.php)
        Will asynchronously check for system proxy (if using system proxy)
        And then invoke slotCheckServerAndAuth
        CheckServerJob
        |
        +. slotNoStatusFound -. X
        |
        +. slotJobTimeout -. X
        |
        +. slotStatusFound --+-. X (if credentials are still missing)
                              |
  +---------------------------+
  |
*-+. checkAuthentication (PROPFIND on root)
        PropfindJob
        |
        +. slotAuthFailed -. X
        |
        +. slotAuthSuccess --+-. X (depending if coming from checkServerAndAuth or not)
                              |
  +---------------------------+
  |
  +. checkServerCapabilities --------------v (in parallel)
        JsonApiJob (cloud/capabilities)
        +. slotCapabilitiesRecieved -+
                                      |
    +---------------------------------+
    |
  fetchUser
        Utilizes the UserInfo class to fetch the user and avatar image
  +-----------------------------------+
  |
  +. Client Side Encryption Checks --+ --reportResult ()
    \endcode
*/


class ConnectionValidator : GLib.Object {
public:
    ConnectionValidator (AccountStatePtr accountState, GLib.Object *parent = nullptr);

    enum Status {
        Undefined,
        Connected,
        NotConfigured,
        ServerVersionMismatch, // The server version is too old
        CredentialsNotReady, // Credentials aren't ready
        CredentialsWrong, // AuthenticationRequiredError
        SslError, // SSL handshake error, certificate rejected by user?
        StatusNotFound, // Error retrieving status.php
        ServiceUnavailable, // 503 on authed request
        MaintenanceMode, // maintenance enabled in status.php
        Timeout // actually also used for other errors on the authed request
    };
    Q_ENUM (Status);

    // How often should the Application ask this object to check for the connection?
    enum { DefaultCallingIntervalMsec = 62 * 1000 };

public slots:
    /// Checks the server and the authentication.
    void checkServerAndAuth ();
    void systemProxyLookupDone (QNetworkProxy &proxy);

    /// Checks authentication only.
    void checkAuthentication ();

signals:
    void connectionResult (ConnectionValidator.Status status, QStringList &errors);

protected slots:
    void slotCheckServerAndAuth ();

    void slotStatusFound (QUrl &url, QJsonObject &info);
    void slotNoStatusFound (QNetworkReply *reply);
    void slotJobTimeout (QUrl &url);

    void slotAuthFailed (QNetworkReply *reply);
    void slotAuthSuccess ();

    void slotCapabilitiesRecieved (QJsonDocument &);
    void slotUserFetched (UserInfo *userInfo);

private:
#ifndef TOKEN_AUTH_ONLY
    void reportConnected ();
#endif
    void reportResult (Status status);
    void checkServerCapabilities ();
    void fetchUser ();

    /** Sets the account's server version
     *
     * Returns false and reports ServerVersionMismatch for very old servers.
     */
    bool setAndCheckServerVersion (QString &version);

    QStringList _errors;
    AccountStatePtr _accountState;
    AccountPtr _account;
    bool _isCheckingServerAndAuth;
};
}
