/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
@brief The FakeDesktopServicesUrlHandler
overrides GLib.DesktopServices.open_url
***********************************************************/
public class FakeDesktopServicesUrlHandler { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler () {
        //  base ();
    }


    internal signal void signal_result_clicked (GLib.Uri url);

}

} // namespace Testing
} // namespace Occ
