/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class DummyCredentials : AbstractCredentials {

public:
    string _user;
    string _password;
    string auth_type () const override;
    string user () const override;
    string password () const override;
    QNetworkAccessManager *create_qNAM () const override;
    bool ready () const override;
    bool still_valid (QNetworkReply *reply) override;
    void fetch_from_keychain () override;
    void ask_from_user () override;
    void persist () override;
    void invalidate_token () override {}
    void forget_sensitive_data () override{};
};

    string DummyCredentials.auth_type () {
        return string.from_latin1 ("dummy");
    }

    string DummyCredentials.user () {
        return _user;
    }

    string DummyCredentials.password () {
        Q_UNREACHABLE ();
        return string ();
    }

    QNetworkAccessManager *DummyCredentials.create_qNAM () {
        return new AccessManager;
    }

    bool DummyCredentials.ready () {
        return true;
    }

    bool DummyCredentials.still_valid (QNetworkReply *reply) {
        Q_UNUSED (reply)
        return true;
    }

    void DummyCredentials.fetch_from_keychain () {
        _was_fetched = true;
        Q_EMIT (fetched ());
    }

    void DummyCredentials.ask_from_user () {
        Q_EMIT (asked ());
    }

    void DummyCredentials.persist () {
    }

    } // namespace Occ
    