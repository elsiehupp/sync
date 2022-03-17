/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The EntityExistsJob class
@ingroup libsync
***********************************************************/
public class EntityExistsJob : AbstractNetworkJob {

    internal signal void exists (GLib.InputStream reply);

    /***********************************************************
    ***********************************************************/
    public EntityExistsJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        send_request ("HEAD", make_account_url (path ()));
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        /* emit */ exists (reply ());
        return true;
    }

} // class EntityExistsJob

} // namespace LibSync
} // namespace Occ
