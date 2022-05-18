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
        Gdk.RGBA color = Gdk.RGBA (0, 130, 201);

        var result = LibSync.Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }

} // class TestIsDarkColorNextcloudBlueReturnTrue

} // namespace Testing
} // namespace Occ
