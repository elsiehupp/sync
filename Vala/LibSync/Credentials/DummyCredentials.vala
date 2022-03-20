/***********************************************************
@author Krzesimir Nowak <krzesimir@endocode.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

public class DummyCredentials : AbstractCredentials {

    /***********************************************************
    ***********************************************************/
    public new string user; // get should be Q_UNREACHABLE ();
    public new string password;

    /***********************************************************
    ***********************************************************/
    public new string auth_type_string () {
        return "dummy";
    }


    /***********************************************************
    ***********************************************************/
    public override Soup.Session create_access_manager () {
        return new AccessManager ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool ready () {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public override bool still_valid (GLib.InputStream reply) {
        //  Q_UNUSED (reply)
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_from_keychain () {
        this.was_fetched = true;
        /* Q_EMIT */ fetched ();
    }


    /***********************************************************
    ***********************************************************/
    public override void ask_from_user () {
        /* Q_EMIT */ (asked ());
    }


    /***********************************************************
    ***********************************************************/
    public override void persist () { }


    /***********************************************************
    ***********************************************************/
    public override void invalidate_token () {}



    /***********************************************************
    ***********************************************************/
    public override void forget_sensitive_data () {}

} // class DummyCredentials

} // namespace LibSync
} // namespace Occ
    