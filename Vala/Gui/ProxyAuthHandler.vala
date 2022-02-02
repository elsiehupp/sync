/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QApplication>

// #include <qt5keychain/keychain.h>

using namespace Occ;
using namespace QKeychain;

// #pragma once

// #include <QNetworkProxy>
// #include <QAuthenticator>
// #include <QPointer>
// #include <QScopedPointer>
// #include <QSettings>

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
    public void on_handle_proxy_authentication_required (QNetworkProxy proxy,
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
                   int counter,
                   const QEventLoop.Process_events_flags flags = QEventLoop.All_events);

    /***********************************************************
    ***********************************************************/
    private string keychain_username_key ();
    private string keychain_password_key ();

    /// The hostname:port of the current proxy, used for detecting switches
    /// to a different proxy.
    private string this.proxy;

    /***********************************************************
    ***********************************************************/
    private string this.username;
    private string this.password;

    /// If the user cancels the credential dialog, blocked will be set to
    /// true and we won't bother him again.
    private bool this.blocked = false;

    /// In several instances on_handle_proxy_authentication_required () can be called
    /// while it is still running. These counters detect what we're currently
    /// waiting for.
    private int this.waiting_for_dialog = 0;
    private int this.waiting_for_keychain = 0;

    /***********************************************************
    ***********************************************************/
    private QPointer<Proxy_auth_dialog> this.dialog;

    /// The QSettings instance to securely store username/password in the keychain.
    private QScopedPointer<QSettings> this.settings;

    /// Pointer to the most-recently-run ReadPasswordJob, needed due to reentrancy.
    private QScopedPointer<QKeychain.ReadPasswordJob> this.read_password_job;

    /// For checking the proxy config settings.
    private QScopedPointer<ConfigFile> this.config_file;

    /// To distinguish between a new QNAM asking for credentials and credentials
    /// failing for an existing QNAM, we keep track of the senders of the
    /// proxy_auth_required signal here.
    private GLib.Set<GLib.Object> this.gave_credentials_to;
};

} // namespace Occ







ProxyAuthHandler *ProxyAuthHandler.instance () {
    static ProxyAuthHandler inst;
    return inst;
}

ProxyAuthHandler.ProxyAuthHandler () {
    this.dialog = new Proxy_auth_dialog ();

    this.config_file.on_reset (new ConfigFile);
    this.settings.on_reset (new QSettings (this.config_file.config_file (), QSettings.IniFormat));
    this.settings.begin_group (QLatin1String ("Proxy"));
    this.settings.begin_group (QLatin1String ("Credentials"));
}

ProxyAuthHandler.~ProxyAuthHandler () {
    delete this.dialog;
}

void ProxyAuthHandler.on_handle_proxy_authentication_required (
    const QNetworkProxy proxy,
    QAuthenticator authenticator) {
    if (!this.dialog) {
        return;
    }

    string key = proxy.host_name () + ':' + string.number (proxy.port ());

    // If the proxy server has changed, forget what we know.
    if (key != this.proxy) {
        this.proxy = key;
        this.username.clear ();
        this.password.clear ();
        this.blocked = false;
        this.gave_credentials_to.clear ();

        // If the user explicitly configured the proxy in the
        // network settings, don't ask about it.
        if (this.config_file.proxy_type () == QNetworkProxy.HttpProxy
            || this.config_file.proxy_type () == QNetworkProxy.Socks5Proxy) {
            this.blocked = true;
        }
    }

    if (this.blocked) {
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
    if (!this.waiting_for_dialog && !this.waiting_for_keychain && (!authenticator.user ().is_empty ()
                                                          || (sending_qnam && this.gave_credentials_to.contains (sending_qnam)))) {
        q_c_info (lc_proxy) << "invalidating old creds" << key;
        this.username.clear ();
        this.password.clear ();
        invalidated = true;
        this.gave_credentials_to.clear ();
    }

    if (this.username.is_empty () || this.waiting_for_keychain) {
        if (invalidated || !get_creds_from_keychain ()) {
            if (get_creds_from_dialog ()) {
                store_creds_in_keychain ();
            } else {
                // dialog was cancelled, never ask for that proxy again
                this.blocked = true;
                return;
            }
        }
    }

    q_c_info (lc_proxy) << "got creds for" << this.proxy;
    authenticator.set_user (this.username);
    authenticator.set_password (this.password);
    if (sending_qnam) {
        this.gave_credentials_to.insert (sending_qnam);
        connect (sending_qnam, &GLib.Object.destroyed,
            this, &ProxyAuthHandler.on_sender_destroyed);
    }
}

void ProxyAuthHandler.on_sender_destroyed (GLib.Object obj) {
    this.gave_credentials_to.remove (obj);
}

bool ProxyAuthHandler.get_creds_from_dialog () {
    // Open the credentials dialog
    if (!this.waiting_for_dialog) {
        this.dialog.on_reset ();
        this.dialog.set_proxy_address (this.proxy);
        this.dialog.open ();
    }

    // This function can be reentered while the dialog is open.
    // If that's the case, continue processing the dialog until
    // it's done.
    if (this.dialog) {
        exec_await (this.dialog.data (),
                  &Gtk.Dialog.on_finished,
                  this.waiting_for_dialog,
                  QEventLoop.Exclude_socket_notifiers);
    }

    if (this.dialog && this.dialog.result () == Gtk.Dialog.Accepted) {
        q_c_info (lc_proxy) << "got creds for" << this.proxy << "from dialog";
        this.username = this.dialog.username ();
        this.password = this.dialog.password ();
        return true;
    }
    return false;
}

template<class T, typename Pointer_to_member_function>
void ProxyAuthHandler.exec_await (T *sender,
                                 Pointer_to_member_function signal,
                                 int counter,
                                 const QEventLoop.Process_events_flags flags) {
    if (!sender) {
        return;
    }

    QEventLoop wait_loop;
    connect (sender, signal, wait_loop, &QEventLoop.quit);

    ++counter;
    wait_loop.exec (flags);
    --counter;
}

bool ProxyAuthHandler.get_creds_from_keychain () {
    if (this.waiting_for_dialog) {
        return false;
    }

    GLib.debug (lc_proxy) << "trying to load" << this.proxy;

    if (!this.waiting_for_keychain) {
        this.username = this.settings.value (keychain_username_key ()).to_string ();
        if (this.username.is_empty ()) {
            return false;
        }

        this.read_password_job.on_reset (new ReadPasswordJob (Theme.instance ().app_name ()));
        this.read_password_job.set_settings (this.settings.data ());
        this.read_password_job.set_insecure_fallback (false);
        this.read_password_job.set_key (keychain_password_key ());
        this.read_password_job.set_auto_delete (false);
        this.read_password_job.on_start ();
    }

    // While we wait for the password job to be done, this code may be reentered.
    // This really needs the counter and the flag here, because otherwise we get
    // bad behavior when we reenter this code after the flag has been switched
    // but before the while loop has on_finished.
    exec_await (this.read_password_job.data (),
              &QKeychain.Job.on_finished,
              this.waiting_for_keychain);

    if (this.read_password_job.error () == NoError) {
        q_c_info (lc_proxy) << "got creds for" << this.proxy << "from keychain";
        this.password = this.read_password_job.text_data ();
        return true;
    }

    this.username.clear ();
    if (this.read_password_job.error () != EntryNotFound) {
        GLib.warn (lc_proxy) << "ReadPasswordJob failed with" << this.read_password_job.error_string ();
    }
    return false;
}

void ProxyAuthHandler.store_creds_in_keychain () {
    if (this.waiting_for_keychain) {
        return;
    }

    q_c_info (lc_proxy) << "storing" << this.proxy;

    this.settings.set_value (keychain_username_key (), this.username);

    var job = new WritePasswordJob (Theme.instance ().app_name (), this);
    job.set_settings (this.settings.data ());
    job.set_insecure_fallback (false);
    job.set_key (keychain_password_key ());
    job.set_text_data (this.password);
    job.set_auto_delete (false);
    job.on_start ();

    exec_await (job,
              &QKeychain.Job.on_finished,
              this.waiting_for_keychain);

    job.delete_later ();
    if (job.error () != NoError) {
        GLib.warn (lc_proxy) << "WritePasswordJob failed with" << job.error_string ();
    }
}

string ProxyAuthHandler.keychain_username_key () {
    return string.from_latin1 ("%1/username").arg (this.proxy);
}

string ProxyAuthHandler.keychain_password_key () {
    return string.from_latin1 ("%1/password").arg (this.proxy);
}
