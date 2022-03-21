/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
@brief The FakeDesktopServicesUrlHandler
overrides QDesktopServices.open_url
***********************************************************/
public class FakeDesktopServicesUrlHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    internal signal void signal_result_clicked (GLib.Uri url);

}

} // namespace Testing
} // namespace Occ
