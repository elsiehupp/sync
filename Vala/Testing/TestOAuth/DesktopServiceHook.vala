/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class DesktopServiceHook : GLib.Object {

    internal signal void signal_hooked (GLib.Uri uri);

    /***********************************************************
    ***********************************************************/
    public DesktopServiceHook () {
        GLib.DesktopServices.set_url_handler ("oauthtest", this, "signal_hooked");
    }

} // class DesktopServiceHook
} // namespace Testing
} // namespace Occ
