/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtEndOf1 : GLib.Object {

    private TestClearAtClearAtEndOf1 () {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.EndOf;
        clear_at.endof = "day";
        user_status.set_clear_at (clear_at);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

        GLib.assert_true (model.clear_at () == _("Today"));
    }

} // class TestClearAtClearAtEndOf1

} // namespace Testing
} // namespace Occ
