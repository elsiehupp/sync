namespace Occ {
namespace Testing {

/***********************************************************
@class CredentialsStub

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class CredentialsStub : AbstractCredentials {

    public string user { public get; private set; }
    public string password { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public CredentialsStub (string user, string password) {
        this.user = user;
        this.password = password;
    }


    /***********************************************************
    ***********************************************************/
    public string authentication_type {
        public get {
            return "";
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool ready {
        public get {
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public Soup create_access_manager () {
        return null;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_from_keychain () { }

    /***********************************************************
    ***********************************************************/
    public void ask_from_user () { }

    /***********************************************************
    ***********************************************************/
    public bool still_valid (Soup.Reply reply) {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public void persist () { }

    /***********************************************************
    ***********************************************************/
    public void invalidate_token () { }

    /***********************************************************
    ***********************************************************/
    public void forget_sensitive_data () { }

} // class CredentialsStub

} // namespace Testing
} // namespace Occ
