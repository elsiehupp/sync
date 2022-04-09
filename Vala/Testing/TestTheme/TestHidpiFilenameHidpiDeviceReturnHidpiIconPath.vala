namespace Occ {
namespace Testing {

/***********************************************************
@class TestHidpiFilenameHidpiDeviceReturnHidpiIconPath

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestHidpiFilenameHidpiDeviceReturnHidpiIconPath : AbstractTestTheme {

    /***********************************************************
    ***********************************************************/
    private TestHidpiFilenameHidpiDeviceReturnHidpiIconPath () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);
        Gdk.RGBA background_color = Gdk.RGBA ("#000000");
        string icon_name = "wizard-files";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + "@2x.png");
    }

} // class TestHidpiFilenameHidpiDeviceReturnHidpiIconPath

} // namespace Testing
} // namespace Occ
