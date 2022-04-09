namespace Occ {
namespace Testing {

/***********************************************************
@class TestHidpiFilenameLightBackgroundReturnPathPathToBlackIcon

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestHidpiFilenameLightBackgroundReturnPathPathToBlackIcon : AbstractTestTheme {

    /***********************************************************
    ***********************************************************/
    private TestHidpiFilenameLightBackgroundReturnPathPathToBlackIcon () {
        FakePaintDevice paint_device;
        Gdk.RGBA background_color = Gdk.RGBA ("#ffffff");
        string icon_name = "icon-name";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/black/" + icon_name + ".png");
    }

} // class TestHidpiFilenameLightBackgroundReturnPathPathToBlackIcon

} // namespace Testing
} // namespace Occ
