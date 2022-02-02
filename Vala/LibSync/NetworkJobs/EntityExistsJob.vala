/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The EntityExistsJob class
@ingroup libsync
***********************************************************/
class EntityExistsJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public EntityExistsJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;

signals:
    void exists (Soup.Reply *);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;







    EntityExistsJob.EntityExistsJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    void EntityExistsJob.on_start () {
        send_request ("HEAD", make_account_url (path ()));
        AbstractNetworkJob.on_start ();
    }

    bool EntityExistsJob.on_finished () {
        /* emit */ exists (reply ());
        return true;
    }

};