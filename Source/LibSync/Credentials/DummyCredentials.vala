/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class DummyCredentials : AbstractCredentials {

    public string _user;
    public string _password;
    public string auth_type () override;
    public string user () override;
    public string password () override;
    public QNetworkAccessManager *create_qNAM () override;
    public bool ready () override;
    public bool still_valid (QNetworkReply *reply) override;
    public void fetch_from_keychain () override;
    public void ask_from_user () override;
    public void persist () override;
    public void invalidate_token () override {}
    public void forget_sensitive_data () override{};
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
    