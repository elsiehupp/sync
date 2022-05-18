namespace Occ {
namespace Cmd {

/***********************************************************
@class HttpCredentialsText

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Heule <daniel.heule@gmail.com>

@copyright GPLv3 or Later
***********************************************************/
public class HttpCredentialsText : LibSync.HttpCredentials {

    /***********************************************************
    ***********************************************************/
    private bool ssl_trusted;

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsText (string user, string password) {
        base (user, password);
        /***********************************************************
        FIXME: not working with client certificates yet (qknight)
        ***********************************************************/
        this.ssl_trusted = false;
    }


    /***********************************************************
    ***********************************************************/
    public override void ask_from_user () {
        this.password = query_password (user ());
        this.ready = true;
        persist ();
        signal_asked ();
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

} // class HttpCredentialsText

} // namespace Cmd
} // namespace Occ
