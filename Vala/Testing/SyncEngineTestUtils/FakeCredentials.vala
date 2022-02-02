
class FakeCredentials : Occ.AbstractCredentials {
    QNetworkAccessManager this.qnam;

    /***********************************************************
    ***********************************************************/
    public FakeCredentials (QNetworkAccessManager qnam) : this.qnam{qnam} { }
    public string authType () override { return "test"; }
    public string user () override { return "admin"; }
    public string password () override { return "password"; }
    public QNetworkAccessManager createQNAM () override { return this.qnam; }
    public bool ready () override { return true; }
    public void fetchFromKeychain () override { }
    public void askFromUser () override { }
    public bool stillValid (Soup.Reply *) override { return true; }
    public void persist () override { }
    public void invalidateToken () override { }
    public void forgetSensitiveData () override { }
};