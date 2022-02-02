/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <functional>

// #include <QWebSocketServer>
// #include <QWebSocket>
// #include <QSignalSpy>

class CredentialsStub : Occ.AbstractCredentials {

    /***********************************************************
    ***********************************************************/
    public CredentialsStub (string user, string password);

    /***********************************************************
    ***********************************************************/
    public 
    public string authType () override;
    public string user () override;
    public string password () override;
    public QNetworkAccessManager createQNAM () override;
    public bool ready () override;
    public void fetchFromKeychain () override;
    public void askFromUser () override;

    /***********************************************************
    ***********************************************************/
    public bool stillValid (Soup.Reply reply) override;
    public void persist () override;
    public void invalidateToken () override;
    public void forgetSensitiveData () override;


    /***********************************************************
    ***********************************************************/
    private string this.user;
    private string this.password;
}










CredentialsStub.CredentialsStub (string user, string password)
    : this.user (user)
    , this.password (password) {
}

string CredentialsStub.authType () {
    return "";
}

string CredentialsStub.user () {
    return this.user;
}

string CredentialsStub.password () {
    return this.password;
}

QNetworkAccessManager *CredentialsStub.createQNAM () {
    return nullptr;
}

bool CredentialsStub.ready () {
    return false;
}

void CredentialsStub.fetchFromKeychain () { }

void CredentialsStub.askFromUser () { }

bool CredentialsStub.stillValid (Soup.Reply * /*reply*/) {
    return false;
}

void CredentialsStub.persist () { }

void CredentialsStub.invalidateToken () { }

void CredentialsStub.forgetSensitiveData () { }
