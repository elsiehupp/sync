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
    Calling Account.setCredentials () will call this function.
    Credentials only live as long as the underlying account object.
    ***********************************************************/
    virtual void setAccount (Account *account);

    virtual string authType () const = 0;
    virtual string user () const = 0;
    virtual string password () const = 0;
    virtual QNetworkAccessManager *createQNAM () const = 0;

    /***********************************************************
    Whether there are credentials that can be used for a connection attempt. */
    virtual bool ready () const = 0;

    /***********************************************************
    Whether fetchFromKeychain () was called before. */
    bool wasFetched () { return _wasFetched; }

    /***********************************************************
    Trigger (async) fetching of credential information

    Should set _wasFetched = true, and later emit fetched () when done.
    ***********************************************************/
    virtual void fetchFromKeychain () = 0;

    /***********************************************************
    Ask credentials from the user (typically async)

    Should emit asked () when done.
    ***********************************************************/
    virtual void askFromUser () = 0;

    virtual bool stillValid (QNetworkReply *reply) = 0;
    virtual void persist () = 0;

    /***********************************************************
    Invalidates token used to authorize requests, it will no longer be used.

    For http auth, this would be the session cookie.
    
    Note that sensitive data (like the password used to acquire t
    session cookie) may be retained. See forgetSensitiveData ().

    ready () must return false afterwards.
    ***********************************************************/
    virtual void invalidateToken () = 0;

    /***********************************************************
    Clears out all sensitive data; used for fully signing out users.

    This should always imply invalidateToken () but may go beyond it.
    
    For http auth, this would clear the session cookie and password.
    ***********************************************************/
    virtual void forgetSensitiveData () = 0;

    static string keychainKey (string &url, string &user, string &accountId);

    /***********************************************************
    If the job need to be restarted or queue, this does it and returns true. */
    virtual bool retryIfNeeded (AbstractNetworkJob *) { return false; }

signals:
    /***********************************************************
    Emitted when fetchFromKeychain () is done.

    Note that ready () can be true or false, depending on whether there was useful
    data in the keychain.
    ***********************************************************/
    void fetched ();

    /***********************************************************
    Emitted when askFromUser () is done.

    Note that ready () can be true or false, depending on whether the user provided
    data or not.
    ***********************************************************/
    void asked ();

protected:
    Account *_account = nullptr;
    bool _wasFetched = false;
};


    AbstractCredentials.AbstractCredentials () = default;
    
    void AbstractCredentials.setAccount (Account *account) {
        ENFORCE (!_account, "should only setAccount once");
        _account = account;
    }
    
    string AbstractCredentials.keychainKey (string &url, string &user, string &accountId) {
        string u (url);
        if (u.isEmpty ()) {
            qCWarning (lcCredentials) << "Empty url in keyChain, error!";
            return string ();
        }
        if (user.isEmpty ()) {
            qCWarning (lcCredentials) << "Error : User is empty!";
            return string ();
        }
    
        if (!u.endsWith (QChar ('/'))) {
            u.append (QChar ('/'));
        }
    
        string key = user + QLatin1Char (':') + u;
        if (!accountId.isEmpty ()) {
            key += QLatin1Char (':') + accountId;
        }
        return key;
    }
    } // namespace Occ
    