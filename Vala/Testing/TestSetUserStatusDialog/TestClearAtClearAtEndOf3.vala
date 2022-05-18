/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtEndOf3 : GLib.Object {

    private TestClearAtClearAtEndOf3 () {
        LibSync.UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.END_OF;
        clear_at.endof = "week";
        user_status.set_clear_at (clear_at);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

        GLib.assert_true (model.clear_at () == _("This week"));
    }

} // class TestClearAtClearAtEndOf3

} // namespace Testing
} // namespace Occ
