namespace Occ {
namespace Testing {

/***********************************************************
@class TestHidpiFilenameDarkBackgroundReturnPathPathToWhiteIcon

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestHidpiFilenameDarkBackgroundReturnPathPathToWhiteIcon : AbstractTestTheme {

    /***********************************************************
    ***********************************************************/
    private TestHidpiFilenameDarkBackgroundReturnPathPathToWhiteIcon () {
        FakePaintDevice paint_device;
        const Gdk.RGBA background_color = Gdk.RGBA ("#000000");
        const string icon_name = "icon-name";

        const string icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + ".png");
    }

} // class TestHidpiFilenameDarkBackgroundReturnPathPathToWhiteIcon

} // namespace Testing
} // namespace Occ
