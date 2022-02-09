/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class AccountApp : GLib.Object {

    /***********************************************************
    ***********************************************************/
    string name { public get; private set; }
    string identifier { public get; private set; }
    GLib.Uri icon_url { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public AccountApp (string name, GLib.Uri url,
        const string identifier, GLib.Uri icon_url,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.name = name;
        this.url = url;
        this.identifier = identifier;
        this.icon_url = icon_url;
    }

} // class AccountApp

} // namespace Occ