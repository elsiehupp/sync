/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtEndOf3 : GLib.Object {

    private TestClearAtClearAtEndOf3 () {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.EndOf;
        clear_at.endof = "week";
        user_status.set_clear_at (clear_at);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

        GLib.assert_true (model.clear_at () == _("This week"));
    }

} // class TestClearAtClearAtEndOf3

} // namespace Testing
} // namespace Occ
