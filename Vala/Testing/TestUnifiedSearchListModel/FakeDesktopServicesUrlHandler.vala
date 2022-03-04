/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

/***********************************************************
@brief The FakeDesktopServicesUrlHandler
overrides QDesktopServices.openUrl
***********************************************************/
 class FakeDesktopServicesUrlHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler (GLib.Object parent = new GLib.Object ())
        : GLib.Object (parent) {}

signals:
    void resultClicked (GLib.Uri url);
};