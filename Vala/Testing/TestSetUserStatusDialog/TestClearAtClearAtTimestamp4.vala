/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtTimestamp4 : GLib.Object {

    private TestClearAtClearAtTimestamp4 (GLib.DateTime current_time) {
        LibSync.UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.TIMESTAMP;
        clear_at.timestamp = current_time.add_secs (60 * 30).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("30 minutes"));
    }

} // class TestClearAtClearAtTimestamp4

} // namespace Testing
} // namespace Occ
