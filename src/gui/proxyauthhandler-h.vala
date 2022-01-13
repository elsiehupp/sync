/*
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

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

// #include <GLib.Object>
// #include <QString>
// #include <QNetworkProxy>
// #include <QAuthenticator>
// #include <QPointer>
// #include <QScopedPointer>
// #include <QSettings>
// #include <QSet>

namespace QKeychain {
class ReadPasswordJob;
}

namespace Occ {

class ProxyAuthDialog;

/**
@brief Handle proxyAuthenticationRequired signals from our QNetworkAccessManagers.

The main complication here is that the slot needs to return credential informa
synchronously - but running a dialog or getting password data from synchron
storage are asynchronous operations. This leads to reentrant calls that are
fairly complicated to handle.
*/
class ProxyAuthHandler : GLib.Object {

public:
    static ProxyAuthHandler *instance ();

    ~ProxyAuthHandler () override;

public slots:
    /// Intended for QNetworkAccessManager.proxyAuthenticationRequired ()
    void handleProxyAuthenticationRequired (QNetworkProxy &proxy,
        QAuthenticator *authenticator);

private slots:
    void slotSenderDestroyed (GLib.Object *);

private:
    ProxyAuthHandler ();

    /// Runs the ProxyAuthDialog and returns true if new credentials were entered.
    bool getCredsFromDialog ();

    /// Checks the keychain for credentials of the current proxy.
    bool getCredsFromKeychain ();

    /// Stores the current credentials in the keychain.
    void storeCredsInKeychain ();

    template<class T, typename PointerToMemberFunction>
    void execAwait (T *sender,
                   PointerToMemberFunction signal,
                   int &counter,
                   const QEventLoop.ProcessEventsFlags flags = QEventLoop.AllEvents);

    QString keychainUsernameKey ();
    QString keychainPasswordKey ();

    /// The hostname:port of the current proxy, used for detecting switches
    /// to a different proxy.
    QString _proxy;

    QString _username;
    QString _password;

    /// If the user cancels the credential dialog, blocked will be set to
    /// true and we won't bother him again.
    bool _blocked = false;

    /// In several instances handleProxyAuthenticationRequired () can be called
    /// while it is still running. These counters detect what we're currently
    /// waiting for.
    int _waitingForDialog = 0;
    int _waitingForKeychain = 0;

    QPointer<ProxyAuthDialog> _dialog;

    /// The QSettings instance to securely store username/password in the keychain.
    QScopedPointer<QSettings> _settings;

    /// Pointer to the most-recently-run ReadPasswordJob, needed due to reentrancy.
    QScopedPointer<QKeychain.ReadPasswordJob> _readPasswordJob;

    /// For checking the proxy config settings.
    QScopedPointer<ConfigFile> _configFile;

    /// To distinguish between a new QNAM asking for credentials and credentials
    /// failing for an existing QNAM, we keep track of the senders of the
    /// proxyAuthRequired signal here.
    QSet<GLib.Object> _gaveCredentialsTo;
};

} // namespace Occ
