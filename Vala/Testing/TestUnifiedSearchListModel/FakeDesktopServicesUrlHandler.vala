/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

/***********************************************************
@brief The FakeDesktopServicesUrlHandler
overrides QDesktopServices.open_url
***********************************************************/
class FakeDesktopServicesUrlHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    signal void signal_result_clicked (GLib.Uri url);

}
}
