/***********************************************************
@author 2015 by Christian Kamm <kamm@incasoftware.de>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Application>
//  #include <qt5keychain/keychain.h>

using Secret.Collection;

//  #include <QNetworkProxy>
//  #include <QAuthenticator>
//  #include <QPointer>
//  #include <QScopedPointer>
//  #include <GLib.Settings>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Handle proxy_authentication_required signals from
our QNetwork_access_managers.

The main complication here is that the slot needs to return
credential informa
synchronously - but running a dialog or getting password
data from synchron
storage are asynchronous operations. This leads to reentrant
calls that are fairly complicated to handle.
***********************************************************/
public class ProxyAuthHandler : GLib.Object {

    static ProxyAuthHandler instance { public get; private set; }

    /***********************************************************
    The hostname:port of the current proxy, used for detecting
    switches to a different proxy.
    ***********************************************************/
    private string proxy;

    /***********************************************************
    ***********************************************************/
    private string username;
    private string password;

    /***********************************************************
    If the user cancels the credential dialog, blocked will be
    set to true and we won't bother them again.
    ***********************************************************/
    private bool blocked = false;

    /***********************************************************
    In several instances on_signal_handle_proxy_authentication_required ()
    can be called while it is still running. These counters
    detect what we're currently waiting for.
    ***********************************************************/
    private int waiting_for_dialog = 0;
    private int waiting_for_keychain = 0;

    /***********************************************************
    ***********************************************************/
    private QPointer<ProxyAuthDialog> dialog;

    /***********************************************************
    The GLib.Settings instance to securely store username/password
    in the keychain.
    ***********************************************************/
    private QScopedPointer<GLib.Settings> settings;

    /***********************************************************
    Pointer to the most-recently-run ReadPasswordJob, needed
    due to reentrancy.
    ***********************************************************/
    private QScopedPointer<Secret.Collection.ReadPasswordJob> read_password_job;

    /***********************************************************
    For checking the proxy config settings.
    ***********************************************************/
    private QScopedPointer<ConfigFile> config_file;

    /***********************************************************
    To distinguish between a new QNAM asking for credentials and
    credentials failing for an existing QNAM, we keep track of
    the senders of the proxy_auth_required signal here.
    ***********************************************************/
    private GLib.List<GLib.Object> gave_credentials_to;

    ~ProxyAuthHandler () {
        delete this.dialog;
    }


    /***********************************************************
    Intended for QNetworkAccessManager.proxy_authentication_required ()
    ***********************************************************/
    public void on_signal_handle_proxy_authentication_required (
        QNetworkProxy proxy,
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
        QPointer<QNetworkAccessManager> sending_access_manager = null;
        var account = (Account) sender ();
        if (account) {
            // Since we go into an event loop, it's possible for the account's access_manager
            // to be destroyed before we get back. We can use this to check for its
            // liveness.
            sending_access_manager = account.shared_network_access_manager;
        }
        if (!sending_access_manager) {
            GLib.warning ("Could not get the sending QNAM for " + sender ());
        }

        GLib.info ("Proxy auth required for " + key + proxy.type ());

        // If we already had a username but auth still failed,
        // invalidate the old credentials! Unfortunately, authenticator.user ()
        // isn't reliable, so we also invalidate credentials if we previously
        // gave presumably valid credentials to the same QNAM.
        bool invalidated = false;
        if (!this.waiting_for_dialog && !this.waiting_for_keychain && (!authenticator.user () == ""
                                                            || (sending_access_manager && this.gave_credentials_to.contains (sending_access_manager)))) {
            GLib.info ("Invalidating old credentials " + key);
            this.username.clear ();
            this.password.clear ();
            invalidated = true;
            this.gave_credentials_to.clear ();
        }

        if (this.username == "" || this.waiting_for_keychain) {
            if (invalidated || !creds_from_keychain ()) {
                if (creds_from_dialog ()) {
                    store_creds_in_keychain ();
                } else {
                    // dialog was cancelled, never ask for that proxy again
                    this.blocked = true;
                    return;
                }
            }
        }

        GLib.info ("Got credentials for " + this.proxy);
        authenticator.user (this.username);
        authenticator.password (this.password);
        if (sending_access_manager) {
            this.gave_credentials_to.insert (sending_access_manager);
            sending_access_manager.destroyed.connect (
                this.on_signal_sender_destroyed
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sender_destroyed (GLib.Object object) {
        this.gave_credentials_to.remove (object);
    }


    /***********************************************************
    ***********************************************************/
    private ProxyAuthHandler () {
        this.dialog = new ProxyAuthDialog ();

        this.config_file.on_signal_reset (new ConfigFile ());
        this.settings.on_signal_reset (new GLib.Settings (this.config_file.config_file (), GLib.Settings.IniFormat));
        this.settings.begin_group ("Proxy");
        this.settings.begin_group ("Credentials");
    }


    /***********************************************************
    Runs the ProxyAuthDialog and returns true if new
    credentials were entered.
    ***********************************************************/
    private bool creds_from_dialog () {
        // Open the credentials dialog
        if (!this.waiting_for_dialog) {
            this.dialog.on_signal_reset ();
            this.dialog.proxy_address (this.proxy);
            this.dialog.open ();
        }

        // This function can be reentered while the dialog is open.
        // If that's the case, continue processing the dialog until
        // it's done.
        if (this.dialog) {
            exec_await (this.dialog,
                    &Gtk.Dialog.signal_finished,
                    this.waiting_for_dialog,
                    QEventLoop.Exclude_socket_notifiers);
        }

        if (this.dialog && this.dialog.result () == Gtk.Dialog.Accepted) {
            GLib.info ("Got credentials for " + this.proxy + " from dialog.");
            this.username = this.dialog.username ();
            this.password = this.dialog.password ();
            return true;
        }
        return false;
    }


    /***********************************************************
    Checks the keychain for credentials of the current proxy.
    ***********************************************************/
    private bool creds_from_keychain () {
        if (this.waiting_for_dialog) {
            return false;
        }

        GLib.debug ("Trying to load " + this.proxy);

        if (!this.waiting_for_keychain) {
            this.username = this.settings.value (keychain_username_key ()).to_string ();
            if (this.username == "") {
                return false;
            }

            this.read_password_job.on_signal_reset (new ReadPasswordJob (Theme.app_name));
            this.read_password_job.settings (this.settings);
            this.read_password_job.insecure_fallback (false);
            this.read_password_job.key (keychain_password_key ());
            this.read_password_job.auto_delete (false);
            this.read_password_job.on_signal_start ();
        }

        // While we wait for the password job to be done, this code may be reentered.
        // This really needs the counter and the flag here, because otherwise we get
        // bad behavior when we reenter this code after the flag has been switched
        // but before the while loop has on_signal_finished.
        exec_await (
            this.read_password_job,
            Secret.Collection.Job.signal_finished,
            this.waiting_for_keychain);

        if (this.read_password_job.error == NoError) {
            GLib.info ("Got credentials for " + this.proxy + " from keychain");
            this.password = this.read_password_job.text_data ();
            return true;
        }

        this.username.clear ();
        if (this.read_password_job.error != EntryNotFound) {
            GLib.warning ("ReadPasswordJob failed with " + this.read_password_job.error_string);
        }
        return false;
    }


    /***********************************************************
    Stores the current credentials in the keychain.
    ***********************************************************/
    private void store_creds_in_keychain () {
        if (this.waiting_for_keychain) {
            return;
        }

        GLib.info ("Storing " + this.proxy);

        this.settings.value (keychain_username_key (), this.username);

        var write_password_job = new WritePasswordJob (Theme.app_name, this);
        write_password_job.settings (this.settings);
        write_password_job.insecure_fallback (false);
        write_password_job.key (keychain_password_key ());
        write_password_job.text_data (this.password);
        write_password_job.auto_delete (false);
        write_password_job.on_signal_start ();

        exec_await (
            write_password_job,
            Secret.Collection.Job.signal_finished,
            this.waiting_for_keychain);

        write_password_job.delete_later ();
        if (write_password_job.error != NoError) {
            GLib.warning ("WritePasswordJob failed with " + write_password_job.error_string);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  private template<class T, typename PointerToMemberFunction>
    private void exec_await (
        T *sender,
        PointerToMemberFunction some_signal,
        int counter,
        QEventLoop.ProcessEventsFlags flags = QEventLoop.AllEvents) {
        if (!sender) {
            return;
        }

        QEventLoop wait_loop;
        sender.some_signal.connect (
            wait_loop.quit
        );

        ++counter;
        wait_loop.exec (flags);
        --counter;
    }


    /***********************************************************
    ***********************************************************/
    private string keychain_username_key () {
        return "%1/username".printf (this.proxy);
    }


    /***********************************************************
    ***********************************************************/
    private string keychain_password_key () {
        return "%1/password".printf (this.proxy);
    }

} // class ProxyAuthHandler

} // namespace Ui
} // namespace Occ
