
namespace Testing {

public class FakeCredentials : AbstractCredentials {

    Soup soup_context;

    /***********************************************************
    ***********************************************************/
    public FakeCredentials (Soup soup_context) {
        //  this.soup_context = soup_context;
    }


    /***********************************************************
    ***********************************************************/
    public override string authentication_type () {
        //  return "test";
    }


    /***********************************************************
    ***********************************************************/
    public override string user () {
        //  return "admin";
    }


    /***********************************************************
    ***********************************************************/
    public override string password () {
        //  return "password";
    }


    /***********************************************************
    ***********************************************************/
    public override Soup create_access_manager () {
        //  return this.soup_context;
    }


    /***********************************************************
    ***********************************************************/
    public override bool ready () {
        //  return true;
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_from_keychain () { }

    /***********************************************************
    ***********************************************************/
    public override void ask_from_user () { }

    /***********************************************************
    ***********************************************************/
    public override bool still_valid (GLib.InputStream reply) {
        //  return true;
    }


    /***********************************************************
    ***********************************************************/
    public override void persist () { }

    /***********************************************************
    ***********************************************************/
    public override void invalidate_token () { }

    /***********************************************************
    ***********************************************************/
    public override void forget_sensitive_data () { }

}

} // namespace Testing
} // namespace Occ