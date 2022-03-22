/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtAfterPeriod : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearAtClearAtAfterPeriod () {
        {
            UserStatus user_status;
            ClearAt clear_at;
            clear_at.type = ClearAtType.PERIOD;
            clear_at.period = 60 * 30;
            user_status.set_clear_at (clear_at);

            UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

            GLib.assert_true (model.clear_at () == _("30 minutes"));
        }
        {
            UserStatus user_status;
            ClearAt clear_at;
            clear_at.type = ClearAtType.PERIOD;
            clear_at.period = 60 * 60;
            user_status.set_clear_at (clear_at);

            UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

            GLib.assert_true (model.clear_at () == _("1 hour"));
        }
    }

} // class TestClearAtClearAtAfterPeriod

} // namespace Testing
} // namespace Occ
