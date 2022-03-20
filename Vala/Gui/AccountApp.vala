/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class AccountApp : GLib.Object {

    /***********************************************************
    ***********************************************************/
    string name { public get; private set; }
    string identifier { public get; private set; }
    GLib.Uri url { public get; private set; }
    GLib.Uri icon_url { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public AccountApp (
        string name, GLib.Uri url,
        string identifier, GLib.Uri icon_url,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.name = name;
        this.url = url;
        this.identifier = identifier;
        this.icon_url = icon_url;
    }

} // class AccountApp

} // namespace Occ
