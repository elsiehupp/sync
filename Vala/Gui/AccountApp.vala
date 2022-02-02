/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class AccountApp : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public AccountApp (string name, GLib.Uri url,
        const string id, GLib.Uri icon_url,
        GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public string name ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string id ();


    public GLib.Uri icon_url ();


    /***********************************************************
    ***********************************************************/
    private string this.name;

    /***********************************************************
    ***********************************************************/
    private 
    private string this.id;
    private GLib.Uri this.icon_url;
}


    AccountApp.AccountApp (string name, GLib.Uri url,
        const string id, GLib.Uri icon_url,
        GLib.Object parent)
        : GLib.Object (parent)
        , this.name (name)
        , this.url (url)
        , this.id (id)
        , this.icon_url (icon_url) {
    }

    string AccountApp.name () {
        return this.name;
    }

    GLib.Uri AccountApp.url () {
        return this.url;
    }

    string AccountApp.id () {
        return this.id;
    }

    GLib.Uri AccountApp.icon_url () {
        return this.icon_url;
    }