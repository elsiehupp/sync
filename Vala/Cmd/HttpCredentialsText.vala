/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Heule <daniel.heule@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
public class HttpCredentialsText : HttpCredentials {

    /***********************************************************
    ***********************************************************/
    private bool ssl_trusted;

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsText (string user, string password) {
        base (user, password);
        // FIXME: not working with client certificates yet (qknight)
        this.ssl_trusted = false;
    }


    /***********************************************************
    ***********************************************************/
    public override void ask_from_user () {
        this.password = query_password (user ());
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
    public override bool ssl_is_trusted () {
        return this.ssl_trusted;
    }

}
//  #endif /* TOKEN_AUTH_ONLY */