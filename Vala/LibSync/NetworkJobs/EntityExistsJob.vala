/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The EntityExistsJob class
@ingroup libsync
***********************************************************/
class EntityExistsJob : AbstractNetworkJob {

    signal void exists (Soup.Reply reply);

    /***********************************************************
    ***********************************************************/
    public EntityExistsJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        send_request ("HEAD", make_account_url (path ()));
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        /* emit */ exists (reply ());
        return true;
    }

} // class EntityExistsJob

} // namespace Occ
