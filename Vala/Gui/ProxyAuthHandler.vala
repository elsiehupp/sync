/***********************************************************
@author 2015 by Christian Kamm <kamm@incasoftware.de>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Application>
//  #include <qt5keychain/keychain.h>

using Secret.Collection;

//  #include <Soup.NetworkProxy>
//  #include <GLib.Authenticator>
//  #include <GLib.Pointer>
//  #include <GLib.ScopedPointer>
//  #include <GLib.Settings>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Handle proxy_authentication_required signals from
our GLib.Network_access_managers.

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
    private ProxyAuthDialog dialog;

    /***********************************************************
    The GLib.Settings instance to securely store username/password
    in the keychain.
    ***********************************************************/
    private GLib.Settings settings;

    /***********************************************************
    Pointer to the most-recently-run ReadPasswordJob, needed
    due to reentrancy.
    ***********************************************************/
    private Secret.Collection.ReadPasswordJob read_password_job;

    /***********************************************************
    For checking the proxy config settings.
    ***********************************************************/
    private ConfigFile config_file;

    /***********************************************************
    To distinguish between a new Soup.Session asking for credentials and
    credentials failing for an existing Soup.Session, we keep track of
    the senders of the proxy_auth_required signal here.
    ***********************************************************/
    private GLib.List<GLib.Object> gave_credentials_to;

    ~ProxyAuthHandler () {
        //  delete this.dialog;
    }


    /***********************************************************
    Intended for Soup.Context.proxy_authentication_required ()
    ***********************************************************/
    public void on_signal_handle_proxy_authentication_required (
        Soup.NetworkProxy proxy,
        GLib.Authenticator authenticator) {
        if (this.dialog == null) {
            return;
        }

        string key = proxy.host_name () + ':' + string.number (proxy.port ());

        // If the proxy server has changed, forget what we know.
        if (key != this.proxy) {
            this.proxy = key;
            this.username = "";
            this.password = "";
            this.blocked = false;
            this.gave_credentials_to = new GLib.List<GLib.Object> ();

            // If the user explicitly configured the proxy in the
            // network settings, don't ask about it.
            if (this.ConfigFile.proxy_type () == Soup.NetworkProxy.HttpProxy
                || this.ConfigFile.proxy_type () == Soup.NetworkProxy.Socks5Proxy) {
                this.blocked = true;
            }
        }

        if (this.blocked) {
            return;
        }

        // Find the responsible Soup.Session if possible.
        Soup.Context sending_access_manager = null;
        var account = (Account) sender ();
        if (account) {
            // Since we go into an event loop, it's possible for the account's soup_context
            // to be destroyed before we get back. We can use this to check for its
            // liveness.
            sending_access_manager = account.shared_network_access_manager;
        }
        if (sending_access_manager == null) {
            GLib.warning ("Could not get the sending Soup.Session for " + sender ());
        }

        GLib.info ("Proxy auth required for " + key + proxy.type ());

        // If we already had a username but auth still failed,
        // invalidate the old credentials! Unfortunately, authenticator.user ()
        // isn't reliable, so we also invalidate credentials if we previously
        // gave presumably valid credentials to the same Soup.Session.
        bool invalidated = false;
        if (this.waiting_for_dialog <= 0 && this.waiting_for_keychain <= 0 && (
            authenticator.user () != "" || (
                sending_access_manager != null && this.gave_credentials_to.contains (sending_access_manager)
            )
        )) {
            GLib.info ("Invalidating old credentials " + key);
            this.username = "";
            this.password = "";
            invalidated = true;
            for (GLib.Object receiver in this.gave_credentials_to) {
                this.gave_credentials_to.remove_all (receiver);
            }
        }

        if (this.username == "" || this.waiting_for_keychain > 0) {
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
        if (sending_access_manager != null) {
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

        this.ConfigFile.reset (new ConfigFile ());
        this.settings.reset (new GLib.Settings (this.ConfigFile.config_file (), GLib.Settings.IniFormat));
        this.settings.begin_group ("Proxy");
        this.settings.begin_group ("Credentials");
    }


    /***********************************************************
    Runs the ProxyAuthDialog and returns true if new
    credentials were entered.
    ***********************************************************/
    private bool creds_from_dialog () {
        // Open the credentials dialog
        if (this.waiting_for_dialog <= 0) {
            this.dialog.reset ();
            this.dialog.proxy_address (this.proxy);
            this.dialog.open ();
        }

        // This function can be reentered while the dialog is open.
        // If that's the case, continue processing the dialog until
        // it's done.
        if (this.dialog != null) {
            exec_await (
                this.dialog,
                Gtk.Dialog.signal_finished,
                this.waiting_for_dialog,
                GLib.MainLoop.ExcludeSocketNotifiers
            );
        }

        if (this.dialog != null && this.dialog.result () == Gtk.Dialog.Accepted) {
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
        if (this.waiting_for_dialog != 0) {
            return false;
        }

        GLib.debug ("Trying to load " + this.proxy);

        if (this.waiting_for_keychain <= 0) {
            this.username = this.settings.get_value (keychain_username_key ()).to_string ();
            if (this.username == "") {
                return false;
            }

            this.read_password_job.reset (new ReadPasswordJob (Theme.app_name));
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

        this.username = "";
        if (this.read_password_job.error != EntryNotFound) {
            GLib.warning ("ReadPasswordJob failed with " + this.read_password_job.error_string);
        }
        return false;
    }


    /***********************************************************
    Stores the current credentials in the keychain.
    ***********************************************************/
    private void store_creds_in_keychain () {
        if (this.waiting_for_keychain > 0) {
            return;
        }

        GLib.info ("Storing " + this.proxy);

        this.settings.get_value (keychain_username_key (), this.username);

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
        GLib.MainLoop.ProcessEventsFlags flags = GLib.MainLoop.AllEvents) {
        if (sender == null) {
            return;
        }

        GLib.MainLoop wait_loop;
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
