/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QApplication>

// #include <qt5keychain/keychain.h>

using namespace Occ;
using namespace QKeychain;

// #pragma once

// #include <GLib.Object>
// #include <string>
// #include <QNetworkProxy>
// #include <QAuthenticator>
// #include <QPointer>
// #include <QScopedPointer>
// #include <QSettings>
// #include <QSet>

namespace QKeychain {
}

namespace Occ {


/***********************************************************
@brief Handle proxyAuthenticationRequired signals from our QNetworkAccessManagers.

The main complication here is that the slot needs to return credential informa
synchronously - but running a dialog or getting password data from synchron
storage are asynchronous operations. This leads to reentrant calls that are
fairly complicated to handle.
***********************************************************/
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

    string keychainUsernameKey ();
    string keychainPasswordKey ();

    /// The hostname:port of the current proxy, used for detecting switches
    /// to a different proxy.
    string _proxy;

    string _username;
    string _password;

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







ProxyAuthHandler *ProxyAuthHandler.instance () {
    static ProxyAuthHandler inst;
    return &inst;
}

ProxyAuthHandler.ProxyAuthHandler () {
    _dialog = new ProxyAuthDialog ();

    _configFile.reset (new ConfigFile);
    _settings.reset (new QSettings (_configFile.configFile (), QSettings.IniFormat));
    _settings.beginGroup (QLatin1String ("Proxy"));
    _settings.beginGroup (QLatin1String ("Credentials"));
}

ProxyAuthHandler.~ProxyAuthHandler () {
    delete _dialog;
}

void ProxyAuthHandler.handleProxyAuthenticationRequired (
    const QNetworkProxy &proxy,
    QAuthenticator *authenticator) {
    if (!_dialog) {
        return;
    }

    string key = proxy.hostName () + QLatin1Char (':') + string.number (proxy.port ());

    // If the proxy server has changed, forget what we know.
    if (key != _proxy) {
        _proxy = key;
        _username.clear ();
        _password.clear ();
        _blocked = false;
        _gaveCredentialsTo.clear ();

        // If the user explicitly configured the proxy in the
        // network settings, don't ask about it.
        if (_configFile.proxyType () == QNetworkProxy.HttpProxy
            || _configFile.proxyType () == QNetworkProxy.Socks5Proxy) {
            _blocked = true;
        }
    }

    if (_blocked) {
        return;
    }

    // Find the responsible QNAM if possible.
    QPointer<QNetworkAccessManager> sending_qnam = nullptr;
    if (auto account = qobject_cast<Account> (sender ())) {
        // Since we go into an event loop, it's possible for the account's qnam
        // to be destroyed before we get back. We can use this to check for its
        // liveness.
        sending_qnam = account.sharedNetworkAccessManager ().data ();
    }
    if (!sending_qnam) {
        qCWarning (lcProxy) << "Could not get the sending QNAM for" << sender ();
    }

    qCInfo (lcProxy) << "Proxy auth required for" << key << proxy.type ();

    // If we already had a username but auth still failed,
    // invalidate the old credentials! Unfortunately, authenticator.user ()
    // isn't reliable, so we also invalidate credentials if we previously
    // gave presumably valid credentials to the same QNAM.
    bool invalidated = false;
    if (!_waitingForDialog && !_waitingForKeychain && (!authenticator.user ().isEmpty ()
                                                          || (sending_qnam && _gaveCredentialsTo.contains (sending_qnam)))) {
        qCInfo (lcProxy) << "invalidating old creds" << key;
        _username.clear ();
        _password.clear ();
        invalidated = true;
        _gaveCredentialsTo.clear ();
    }

    if (_username.isEmpty () || _waitingForKeychain) {
        if (invalidated || !getCredsFromKeychain ()) {
            if (getCredsFromDialog ()) {
                storeCredsInKeychain ();
            } else {
                // dialog was cancelled, never ask for that proxy again
                _blocked = true;
                return;
            }
        }
    }

    qCInfo (lcProxy) << "got creds for" << _proxy;
    authenticator.setUser (_username);
    authenticator.setPassword (_password);
    if (sending_qnam) {
        _gaveCredentialsTo.insert (sending_qnam);
        connect (sending_qnam, &GLib.Object.destroyed,
            this, &ProxyAuthHandler.slotSenderDestroyed);
    }
}

void ProxyAuthHandler.slotSenderDestroyed (GLib.Object *obj) {
    _gaveCredentialsTo.remove (obj);
}

bool ProxyAuthHandler.getCredsFromDialog () {
    // Open the credentials dialog
    if (!_waitingForDialog) {
        _dialog.reset ();
        _dialog.setProxyAddress (_proxy);
        _dialog.open ();
    }

    // This function can be reentered while the dialog is open.
    // If that's the case, continue processing the dialog until
    // it's done.
    if (_dialog) {
        execAwait (_dialog.data (),
                  &Gtk.Dialog.finished,
                  _waitingForDialog,
                  QEventLoop.ExcludeSocketNotifiers);
    }

    if (_dialog && _dialog.result () == Gtk.Dialog.Accepted) {
        qCInfo (lcProxy) << "got creds for" << _proxy << "from dialog";
        _username = _dialog.username ();
        _password = _dialog.password ();
        return true;
    }
    return false;
}

template<class T, typename PointerToMemberFunction>
void ProxyAuthHandler.execAwait (T *sender,
                                 PointerToMemberFunction signal,
                                 int &counter,
                                 const QEventLoop.ProcessEventsFlags flags) {
    if (!sender) {
        return;
    }

    QEventLoop waitLoop;
    connect (sender, signal, &waitLoop, &QEventLoop.quit);

    ++counter;
    waitLoop.exec (flags);
    --counter;
}

bool ProxyAuthHandler.getCredsFromKeychain () {
    if (_waitingForDialog) {
        return false;
    }

    qCDebug (lcProxy) << "trying to load" << _proxy;

    if (!_waitingForKeychain) {
        _username = _settings.value (keychainUsernameKey ()).toString ();
        if (_username.isEmpty ()) {
            return false;
        }

        _readPasswordJob.reset (new ReadPasswordJob (Theme.instance ().appName ()));
        _readPasswordJob.setSettings (_settings.data ());
        _readPasswordJob.setInsecureFallback (false);
        _readPasswordJob.setKey (keychainPasswordKey ());
        _readPasswordJob.setAutoDelete (false);
        _readPasswordJob.start ();
    }

    // While we wait for the password job to be done, this code may be reentered.
    // This really needs the counter and the flag here, because otherwise we get
    // bad behavior when we reenter this code after the flag has been switched
    // but before the while loop has finished.
    execAwait (_readPasswordJob.data (),
              &QKeychain.Job.finished,
              _waitingForKeychain);

    if (_readPasswordJob.error () == NoError) {
        qCInfo (lcProxy) << "got creds for" << _proxy << "from keychain";
        _password = _readPasswordJob.textData ();
        return true;
    }

    _username.clear ();
    if (_readPasswordJob.error () != EntryNotFound) {
        qCWarning (lcProxy) << "ReadPasswordJob failed with" << _readPasswordJob.errorString ();
    }
    return false;
}

void ProxyAuthHandler.storeCredsInKeychain () {
    if (_waitingForKeychain) {
        return;
    }

    qCInfo (lcProxy) << "storing" << _proxy;

    _settings.setValue (keychainUsernameKey (), _username);

    auto job = new WritePasswordJob (Theme.instance ().appName (), this);
    job.setSettings (_settings.data ());
    job.setInsecureFallback (false);
    job.setKey (keychainPasswordKey ());
    job.setTextData (_password);
    job.setAutoDelete (false);
    job.start ();

    execAwait (job,
              &QKeychain.Job.finished,
              _waitingForKeychain);

    job.deleteLater ();
    if (job.error () != NoError) {
        qCWarning (lcProxy) << "WritePasswordJob failed with" << job.errorString ();
    }
}

string ProxyAuthHandler.keychainUsernameKey () {
    return string.fromLatin1 ("%1/username").arg (_proxy);
}

string ProxyAuthHandler.keychainPasswordKey () {
    return string.fromLatin1 ("%1/password").arg (_proxy);
}
