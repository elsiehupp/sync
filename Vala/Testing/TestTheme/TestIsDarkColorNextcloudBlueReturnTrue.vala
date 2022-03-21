namespace Occ {
namespace Testing {

/***********************************************************
@class TestIsDarkColorNextcloudBlueReturnTrue

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestIsDarkColorNextcloudBlueReturnTrue : AbstractTestTheme {

    /***********************************************************
    ***********************************************************/
    private TestIsDarkColorNextcloudBlueReturnTrue () {
        const Gtk.Color color = new Gtk.Color (0, 130, 201);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }

} // class TestIsDarkColorNextcloudBlueReturnTrue

} // namespace Testing
} // namespace Occ
