/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class DummyCredentials : AbstractCredentials {

public:
    string _user;
    string _password;
    string authType () const override;
    string user () const override;
    string password () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    bool stillValid (QNetworkReply *reply) override;
    void fetchFromKeychain () override;
    void askFromUser () override;
    void persist () override;
    void invalidateToken () override {}
    void forgetSensitiveData () override{};
};

} // namespace Occ

#endif








namespace Occ {

    string DummyCredentials.authType () {
        return string.fromLatin1 ("dummy");
    }
    
    string DummyCredentials.user () {
        return _user;
    }
    
    string DummyCredentials.password () {
        Q_UNREACHABLE ();
        return string ();
    }
    
    QNetworkAccessManager *DummyCredentials.createQNAM () {
        return new AccessManager;
    }
    
    bool DummyCredentials.ready () {
        return true;
    }
    
    bool DummyCredentials.stillValid (QNetworkReply *reply) {
        Q_UNUSED (reply)
        return true;
    }
    
    void DummyCredentials.fetchFromKeychain () {
        _wasFetched = true;
        Q_EMIT (fetched ());
    }
    
    void DummyCredentials.askFromUser () {
        Q_EMIT (asked ());
    }
    
    void DummyCredentials.persist () {
    }
    
    } // namespace Occ
    