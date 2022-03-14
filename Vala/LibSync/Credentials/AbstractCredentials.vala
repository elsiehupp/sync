/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QCoreApplication>

using CSync;

namespace Occ {
namespace LibSync {

abstract class AbstractCredentials : GLib.Object {

    /***********************************************************
    The bound account for the credentials instance.

    Credentials are always used in conjunction with an account.
    Calling Account.credentials () will call this function.
    Credentials only live as long as the underlying account object.


    //  ENFORCE (!this.account, "should only set account once");
    ***********************************************************/
    Account account { protected get; public set; }

    /***********************************************************
    Whether fetch_from_keychain () was called before.
    ***********************************************************/
    bool was_fetched { public get; protected set; }

    /***********************************************************
    ***********************************************************/
    string signal_auth_type { public get; protected set; }

    /***********************************************************
    ***********************************************************/
    string user { public get; protected set; }

    /***********************************************************
    Emitted when fetch_from_keychain () is done.

    Note that ready () can be true or false, depending on
    whether there was useful data in the keychain.
    ***********************************************************/
    internal signal void signal_fetched ();

    /***********************************************************
    Emitted when ask_from_user () is done.

    Note that ready () can be true or false, depending on
    whether the user provided data or not.
    ***********************************************************/
    internal signal void signal_asked ();

    /***********************************************************
    ***********************************************************/
    protected AbstractCredentials () {
        base ();
        this.was_fetched = false;
    }


    /***********************************************************
    ***********************************************************/
    public abstract string password ();


    /***********************************************************
    ***********************************************************/
    public abstract QNetworkAccessManager create_qnam ();


    /***********************************************************
    Whether there are credentials that can be used for a
    connection attempt.
    ***********************************************************/
    public abstract bool ready ();


    /***********************************************************
    Trigger (async) fetching of credential information

    Should set this.was_fetched = true, and later emit
    fetched () when done.
    ***********************************************************/
    public abstract void fetch_from_keychain ();


    /***********************************************************
    Ask credentials from the user (typically async)

    Should emit asked () when done.
    ***********************************************************/
    public abstract void ask_from_user ();


    /***********************************************************
    ***********************************************************/
    public abstract bool still_valid (Soup.Reply reply);


    /***********************************************************
    ***********************************************************/
    public abstract void persist ();


    /***********************************************************
    Invalidates token used to authorize requests, it will no
    longer be used.

    For http auth, this would be the session cookie.

    Note that sensitive data (like the password used to acquire t
    session cookie) may be retained. See forget_sensitive_data ().

    ready () must return false afterwards.
    ***********************************************************/
    public abstract void invalidate_token ();

    /***********************************************************
    Clears out all sensitive data; used for fully signing out users.

    This should always imply invalidate_token () but may go beyond it.

    For http auth, this would clear the session cookie and password.
    ***********************************************************/
    public abstract void forget_sensitive_data ();

    /***********************************************************
    ***********************************************************/
    public static string keychain_key (string url, string user, string account_id) {
        if (url == "") {
            GLib.warning ("Empty url in keychain, error!");
            return "";
        }
        if (user == "") {
            GLib.warning ("Error: User is empty!");
            return "";
        }

        string url_copy = url;
        if (!url.has_suffix ("/")) {
            url_copy += "/";
        }

        string key = user + ":" + url_copy;
        if (account_id != "") {
            key += ":" + account_id;
        }
        return key;
    }


    /***********************************************************
    If the job need to be restarted or queue, this does it and returns true.
    ***********************************************************/
    public virtual bool retry_if_needed (AbstractNetworkJob job) {
        return false;
    }

} // class AbstractCredentials

} // namespace LibSync
} // namespace Occ
    