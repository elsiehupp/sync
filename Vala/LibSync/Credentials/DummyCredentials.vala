/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
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
    public new string signal_auth_type () {
        return "dummy";
    }


    /***********************************************************
    ***********************************************************/
    public override QNetworkAccessManager create_qnam () {
        return new AccessManager ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool ready () {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public override bool still_valid (Soup.Reply reply) {
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
    