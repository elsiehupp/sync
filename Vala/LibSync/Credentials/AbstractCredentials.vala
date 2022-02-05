/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QCoreApplication>

using CSync;

namespace Occ {

class AbstractCredentials : GLib.Object {

    protected Account account = null;
    protected bool was_fetched = false;


    /***********************************************************
    Emitted when fetch_from_keychain () is done.

    Note that ready () can be true or false, depending on
    whether there was useful data in the keychain.
    ***********************************************************/
    signal void fetched ();


    /***********************************************************
    Emitted when ask_from_user () is done.

    Note that ready () can be true or false, depending on
    whether the user provided data or not.
    ***********************************************************/
    signal void asked ();


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials ();
    AbstractCredentials.AbstractCredentials () = default;


    /***********************************************************
    No need for virtual destructor - GLib.Object already has one.
    ***********************************************************/

    /***********************************************************
    The bound account for the credentials instance.

    Credentials are always used in conjunction with an account.
    Calling Account.credentials () will call this function.
    Credentials only live as long as the underlying account object.
    ***********************************************************/
    public virtual void account (Account account) {
        ENFORCE (!this.account, "should only account once");
        this.account = account;
    }


    /***********************************************************
    ***********************************************************/
    public virtual string auth_type ();


    /***********************************************************
    ***********************************************************/
    public virtual string user ();


    /***********************************************************
    ***********************************************************/
    public virtual string password ();


    /***********************************************************
    ***********************************************************/
    public virtual QNetworkAccessManager create_qnam ();


    /***********************************************************
    Whether there are credentials that can be used for a
    connection attempt.
    ***********************************************************/
    public virtual bool ready ();


    /***********************************************************
    Whether fetch_from_keychain () was called before.
    ***********************************************************/
    public bool was_fetched () {
        return this.was_fetched;
    }


    /***********************************************************
    Trigger (async) fetching of credential information

    Should set this.was_fetched = true, and later emit
    fetched () when done.
    ***********************************************************/
    public virtual void fetch_from_keychain ();


    /***********************************************************
    Ask credentials from the user (typically async)

    Should emit asked () when done.
    ***********************************************************/
    public virtual void ask_from_user ();


    /***********************************************************
    ***********************************************************/
    public virtual bool still_valid (Soup.Reply reply);


    /***********************************************************
    ***********************************************************/
    public virtual void persist ();


    /***********************************************************
    Invalidates token used to authorize requests, it will no
    longer be used.

    For http auth, this would be the session cookie.

    Note that sensitive data (like the password used to acquire t
    session cookie) may be retained. See forget_sensitive_data ().

    ready () must return false afterwards.
    ***********************************************************/
    public virtual void invalidate_token ();


    /***********************************************************
    Clears out all sensitive data; used for fully signing out users.

    This should always imply invalidate_token () but may go beyond it.

    For http auth, this would clear the session cookie and password.
    ***********************************************************/
    public virtual void forget_sensitive_data ();


    /***********************************************************
    ***********************************************************/
    public static string keychain_key (string url, string user, string account_id) {
        string u (url);
        if (u.is_empty ()) {
            GLib.warn (lc_credentials) << "Empty url in key_chain, error!";
            return "";
        }
        if (user.is_empty ()) {
            GLib.warn (lc_credentials) << "Error : User is empty!";
            return "";
        }

        if (!u.ends_with (char ('/'))) {
            u.append (char ('/'));
        }

        string key = user + ':' + u;
        if (!account_id.is_empty ()) {
            key += ':' + account_id;
        }
        return key;
    }


    /***********************************************************
    If the job need to be restarted or queue, this does it and returns true.
    ***********************************************************/
    public virtual bool retry_if_needed (AbstractNetworkJob *) {
        return false;
    }

} // class AbstractCredentials

} // namespace Occ
    