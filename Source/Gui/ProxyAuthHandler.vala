/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QApplication>

// #include <qt5keychain/keychain.h>

using namespace Occ;
using namespace QKeychain;

// #pragma once

// #include <string>
// #include <QNetworkProxy>
// #include <QAuthenticator>
// #include <QPointer>
// #include <QScopedPointer>
// #include <QSettings>
// #include <GLib.Set>

namespace QKeychain {
}

namespace Occ {


/***********************************************************
@brief Handle proxy_authentication_required signals from our QNetwork_access_managers.

The main complication here is that the slot needs to return credential informa
synchronously - but running a dialog or getting password data from synchron
storage are asynchronous operations. This leads to reentrant calls that are
fairly complicated to handle.
***********************************************************/
class ProxyAuthHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public static ProxyAuthHandler instance ();

    ~ProxyAuthHandler () override;

    /// Intended for QNetworkAccessManager.proxy_authentication_required ()
    public void on_handle_proxy_authentication_required (QNetworkProxy &proxy,
        QAuthenticator authenticator);


    /***********************************************************
    ***********************************************************/
    private void on_sender_destroyed (GLib.Object *);

    /***********************************************************
    ***********************************************************/
    private 
    private ProxyAuthHandler ();

    /// Runs the Proxy_auth_dialog and returns true if new credentials were entered.
    private bool get_creds_from_dialog ();

    /// Checks the keychain for credentials of the current proxy.
    private bool get_creds_from_keychain ();

    /// Stores the current credentials in the keychain.
    private void store_creds_in_keychain ();

    /***********************************************************
    ***********************************************************/
    private template<class T, typename Pointer_to_member_function>
    private void exec_await (T *sender,
                   Pointer_to_member_function signal,
                   int &counter,
                   const QEventLoop.Process_events_flags flags = QEventLoop.All_events);

    /***********************************************************
    ***********************************************************/
    private string keychain_username_key ();
    private string keychain_password_key ();

    /// The hostname:port of the current proxy, used for detecting switches
    /// to a different proxy.
    private string _proxy;

    /***********************************************************
    ***********************************************************/
    private string _username;
    private string _password;

    /// If the user cancels the credential dialog, blocked will be set to
    /// true and we won't bother him again.
    private bool _blocked = false;

    /// In several instances on_handle_proxy_authentication_required () can be called
    /// while it is still running. These counters detect what we're currently
    /// waiting for.
    private int _waiting_for_dialog = 0;
    private int _waiting_for_keychain = 0;

    /***********************************************************
    ***********************************************************/
    private QPointer<Proxy_auth_dialog> _dialog;

    /// The QSettings instance to securely store username/password in the keychain.
    private QScopedPointer<QSettings> _settings;

    /// Pointer to the most-recently-run ReadPasswordJob, needed due to reentrancy.
    private QScopedPointer<QKeychain.ReadPasswordJob> _read_password_job;

    /// For checking the proxy config settings.
    private QScopedPointer<ConfigFile> _config_file;

    /// To distinguish between a new QNAM asking for credentials and credentials
    /// failing for an existing QNAM, we keep track of the senders of the
    /// proxy_auth_required signal here.
    private GLib.Set<GLib.Object> _gave_credentials_to;
};

} // namespace Occ







ProxyAuthHandler *ProxyAuthHandler.instance () {
    static ProxyAuthHandler inst;
    return &inst;
}

ProxyAuthHandler.ProxyAuthHandler () {
    _dialog = new Proxy_auth_dialog ();

    _config_file.on_reset (new ConfigFile);
    _settings.on_reset (new QSettings (_config_file.config_file (), QSettings.IniFormat));
    _settings.begin_group (QLatin1String ("Proxy"));
    _settings.begin_group (QLatin1String ("Credentials"));
}

ProxyAuthHandler.~ProxyAuthHandler () {
    delete _dialog;
}

void ProxyAuthHandler.on_handle_proxy_authentication_required (
    const QNetworkProxy &proxy,
    QAuthenticator authenticator) {
    if (!_dialog) {
        return;
    }

    string key = proxy.host_name () + ':' + string.number (proxy.port ());

    // If the proxy server has changed, forget what we know.
    if (key != _proxy) {
        _proxy = key;
        _username.clear ();
        _password.clear ();
        _blocked = false;
        _gave_credentials_to.clear ();

        // If the user explicitly configured the proxy in the
        // network settings, don't ask about it.
        if (_config_file.proxy_type () == QNetworkProxy.HttpProxy
            || _config_file.proxy_type () == QNetworkProxy.Socks5Proxy) {
            _blocked = true;
        }
    }

    if (_blocked) {
        return;
    }

    // Find the responsible QNAM if possible.
    QPointer<QNetworkAccessManager> sending_qnam = nullptr;
    if (var account = qobject_cast<Account> (sender ())) {
        // Since we go into an event loop, it's possible for the account's qnam
        // to be destroyed before we get back. We can use this to check for its
        // liveness.
        sending_qnam = account.shared_network_access_manager ().data ();
    }
    if (!sending_qnam) {
        GLib.warn (lc_proxy) << "Could not get the sending QNAM for" << sender ();
    }

    q_c_info (lc_proxy) << "Proxy auth required for" << key << proxy.type ();

    // If we already had a username but auth still failed,
    // invalidate the old credentials! Unfortunately, authenticator.user ()
    // isn't reliable, so we also invalidate credentials if we previously
    // gave presumably valid credentials to the same QNAM.
    bool invalidated = false;
    if (!_waiting_for_dialog && !_waiting_for_keychain && (!authenticator.user ().is_empty ()
                                                          || (sending_qnam && _gave_credentials_to.contains (sending_qnam)))) {
        q_c_info (lc_proxy) << "invalidating old creds" << key;
        _username.clear ();
        _password.clear ();
        invalidated = true;
        _gave_credentials_to.clear ();
    }

    if (_username.is_empty () || _waiting_for_keychain) {
        if (invalidated || !get_creds_from_keychain ()) {
            if (get_creds_from_dialog ()) {
                store_creds_in_keychain ();
            } else {
                // dialog was cancelled, never ask for that proxy again
                _blocked = true;
                return;
            }
        }
    }

    q_c_info (lc_proxy) << "got creds for" << _proxy;
    authenticator.set_user (_username);
    authenticator.set_password (_password);
    if (sending_qnam) {
        _gave_credentials_to.insert (sending_qnam);
        connect (sending_qnam, &GLib.Object.destroyed,
            this, &ProxyAuthHandler.on_sender_destroyed);
    }
}

void ProxyAuthHandler.on_sender_destroyed (GLib.Object obj) {
    _gave_credentials_to.remove (obj);
}

bool ProxyAuthHandler.get_creds_from_dialog () {
    // Open the credentials dialog
    if (!_waiting_for_dialog) {
        _dialog.on_reset ();
        _dialog.set_proxy_address (_proxy);
        _dialog.open ();
    }

    // This function can be reentered while the dialog is open.
    // If that's the case, continue processing the dialog until
    // it's done.
    if (_dialog) {
        exec_await (_dialog.data (),
                  &Gtk.Dialog.on_finished,
                  _waiting_for_dialog,
                  QEventLoop.Exclude_socket_notifiers);
    }

    if (_dialog && _dialog.result () == Gtk.Dialog.Accepted) {
        q_c_info (lc_proxy) << "got creds for" << _proxy << "from dialog";
        _username = _dialog.username ();
        _password = _dialog.password ();
        return true;
    }
    return false;
}

template<class T, typename Pointer_to_member_function>
void ProxyAuthHandler.exec_await (T *sender,
                                 Pointer_to_member_function signal,
                                 int &counter,
                                 const QEventLoop.Process_events_flags flags) {
    if (!sender) {
        return;
    }

    QEventLoop wait_loop;
    connect (sender, signal, &wait_loop, &QEventLoop.quit);

    ++counter;
    wait_loop.exec (flags);
    --counter;
}

bool ProxyAuthHandler.get_creds_from_keychain () {
    if (_waiting_for_dialog) {
        return false;
    }

    GLib.debug (lc_proxy) << "trying to load" << _proxy;

    if (!_waiting_for_keychain) {
        _username = _settings.value (keychain_username_key ()).to_"";
        if (_username.is_empty ()) {
            return false;
        }

        _read_password_job.on_reset (new ReadPasswordJob (Theme.instance ().app_name ()));
        _read_password_job.set_settings (_settings.data ());
        _read_password_job.set_insecure_fallback (false);
        _read_password_job.set_key (keychain_password_key ());
        _read_password_job.set_auto_delete (false);
        _read_password_job.on_start ();
    }

    // While we wait for the password job to be done, this code may be reentered.
    // This really needs the counter and the flag here, because otherwise we get
    // bad behavior when we reenter this code after the flag has been switched
    // but before the while loop has on_finished.
    exec_await (_read_password_job.data (),
              &QKeychain.Job.on_finished,
              _waiting_for_keychain);

    if (_read_password_job.error () == NoError) {
        q_c_info (lc_proxy) << "got creds for" << _proxy << "from keychain";
        _password = _read_password_job.text_data ();
        return true;
    }

    _username.clear ();
    if (_read_password_job.error () != EntryNotFound) {
        GLib.warn (lc_proxy) << "ReadPasswordJob failed with" << _read_password_job.error_string ();
    }
    return false;
}

void ProxyAuthHandler.store_creds_in_keychain () {
    if (_waiting_for_keychain) {
        return;
    }

    q_c_info (lc_proxy) << "storing" << _proxy;

    _settings.set_value (keychain_username_key (), _username);

    var job = new WritePasswordJob (Theme.instance ().app_name (), this);
    job.set_settings (_settings.data ());
    job.set_insecure_fallback (false);
    job.set_key (keychain_password_key ());
    job.set_text_data (_password);
    job.set_auto_delete (false);
    job.on_start ();

    exec_await (job,
              &QKeychain.Job.on_finished,
              _waiting_for_keychain);

    job.delete_later ();
    if (job.error () != NoError) {
        GLib.warn (lc_proxy) << "WritePasswordJob failed with" << job.error_string ();
    }
}

string ProxyAuthHandler.keychain_username_key () {
    return string.from_latin1 ("%1/username").arg (_proxy);
}

string ProxyAuthHandler.keychain_password_key () {
    return string.from_latin1 ("%1/password").arg (_proxy);
}
