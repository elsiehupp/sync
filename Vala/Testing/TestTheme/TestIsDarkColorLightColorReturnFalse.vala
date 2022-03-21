namespace Occ {
namespace Testing {

/***********************************************************
@class TestIsDarkColorLightColorReturnFalse

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestIsDarkColorLightColorReturnFalse : AbstractTestTheme {

    /***********************************************************
    ***********************************************************/
    private TestIsDarkColorLightColorReturnFalse () {
        const Gtk.Color color = new Gtk.Color (255, 255, 255);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == false);
    }

} // class TestIsDarkColorLightColorReturnFalse

} // namespace Testing
} // namespace Occ
