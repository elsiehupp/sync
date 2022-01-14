/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <string>
// #include <QCoreApplication>

// #include <GLib.Object>

// #include <csync.h>

namespace Occ {


class AbstractCredentials : GLib.Object {

public:
    AbstractCredentials ();
    // No need for virtual destructor - GLib.Object already has one.

    /***********************************************************
    The bound account for the credentials instance.

    Credentials are always used in conjunction with an account.
    Calling Account.set_credentials () will call this function.
    Credentials only live as long as the underlying account object.
    ***********************************************************/
    virtual void set_account (Account *account);

    virtual string auth_type () const = 0;
    virtual string user () const = 0;
    virtual string password () const = 0;
    virtual QNetworkAccessManager *create_qNAM () const = 0;

    /***********************************************************
    Whether there are credentials that can be used for a connection attempt. */
    virtual bool ready () const = 0;

    /***********************************************************
    Whether fetch_from_keychain () was called before. */
    bool was_fetched () { return _was_fetched; }

    /***********************************************************
    Trigger (async) fetching of credential information

    Should set _was_fetched = true, and later emit fetched () when done.
    ***********************************************************/
    virtual void fetch_from_keychain () = 0;

    /***********************************************************
    Ask credentials from the user (typically async)

    Should emit asked () when done.
    ***********************************************************/
    virtual void ask_from_user () = 0;

    virtual bool still_valid (QNetworkReply *reply) = 0;
    virtual void persist () = 0;

    /***********************************************************
    Invalidates token used to authorize requests, it will no longer be used.

    For http auth, this would be the session cookie.
    
    Note that sensitive data (like the password used to acquire t
    session cookie) may be retained. See forget_sensitive_data ().

    ready () must return false afterwards.
    ***********************************************************/
    virtual void invalidate_token () = 0;

    /***********************************************************
    Clears out all sensitive data; used for fully signing out users.

    This should always imply invalidate_token () but may go beyond it.
    
    For http auth, this would clear the session cookie and password.
    ***********************************************************/
    virtual void forget_sensitive_data () = 0;

    static string keychain_key (string &url, string &user, string &account_id);

    /***********************************************************
    If the job need to be restarted or queue, this does it and returns true. */
    virtual bool retry_if_needed (AbstractNetworkJob *) { return false; }

signals:
    /***********************************************************
    Emitted when fetch_from_keychain () is done.

    Note that ready () can be true or false, depending on whether there was useful
    data in the keychain.
    ***********************************************************/
    void fetched ();

    /***********************************************************
    Emitted when ask_from_user () is done.

    Note that ready () can be true or false, depending on whether the user provided
    data or not.
    ***********************************************************/
    void asked ();

protected:
    Account *_account = nullptr;
    bool _was_fetched = false;
};


    AbstractCredentials.AbstractCredentials () = default;
    
    void AbstractCredentials.set_account (Account *account) {
        ENFORCE (!_account, "should only set_account once");
        _account = account;
    }
    
    string AbstractCredentials.keychain_key (string &url, string &user, string &account_id) {
        string u (url);
        if (u.is_empty ()) {
            q_c_warning (lc_credentials) << "Empty url in key_chain, error!";
            return string ();
        }
        if (user.is_empty ()) {
            q_c_warning (lc_credentials) << "Error : User is empty!";
            return string ();
        }
    
        if (!u.ends_with (QChar ('/'))) {
            u.append (QChar ('/'));
        }
    
        string key = user + QLatin1Char (':') + u;
        if (!account_id.is_empty ()) {
            key += QLatin1Char (':') + account_id;
        }
        return key;
    }
    } // namespace Occ
    