/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using namespace Occ;

class DesktopServiceHook : GLib.Object {
signals:
    void hooked (GLib.Uri );

    /***********************************************************
    ***********************************************************/
    public DesktopServiceHook () {
        QDesktopServices.setUrlHandler ("oauthtest", this, "hooked");
    }
};