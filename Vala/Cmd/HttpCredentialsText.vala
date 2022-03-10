/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Heule <daniel.heule@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Occ;

//  #ifndef TOKEN_AUTH_ONLY
class HttpCredentialsText : HttpCredentials {

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsText (string user, string password)
        : HttpCredentials (user, password)
        , // FIXME: not working with client certificates yet (qknight)
        this.ssl_trusted (false) {
    }


    /***********************************************************
    ***********************************************************/
    public void ask_from_user () override {
        this.password = .query_password (user ());
        this.ready = true;
        persist ();
        /* emit */ asked ();
    }


    /***********************************************************
    ***********************************************************/
    public void s_sLTrusted (bool is_trusted) {
        this.ssl_trusted = is_trusted;
    }


    /***********************************************************
    ***********************************************************/
    public bool ssl_is_trusted () override {
        return this.ssl_trusted;
    }


    /***********************************************************
    ***********************************************************/
    private bool this.ssl_trusted;
}
//  #endif /* TOKEN_AUTH_ONLY */