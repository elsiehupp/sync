/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtStages : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearAtStages () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.clear_at () == _("Don't clear"));
        var clear_at_values = model.clear_at_values;
        GLib.assert_true (clear_at_values.length == 6);

        GLib.assert_true (clear_at_values[0] == _("Don't clear"));
        GLib.assert_true (clear_at_values[1] == _("30 minutes"));
        GLib.assert_true (clear_at_values[2] == _("1 hour"));
        GLib.assert_true (clear_at_values[3] == _("4 hours"));
        GLib.assert_true (clear_at_values[4] == _("Today"));
        GLib.assert_true (clear_at_values[5] == _("This week"));
    }

} // class TestClearAtStages

} // namespace Testing
} // namespace Occ
