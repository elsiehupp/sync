/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetUserStatusSetCustomMessageUserStatusSetCorrect : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetUserStatusSetCustomMessageUserStatusSetCorrect () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy finished_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.on_signal_finished
        );

        const string user_status_message = "Some status";
        const string user_status_icon = "❤";
        const LibSync.UserStatus.OnlineStatus user_status_state = LibSync.UserStatus.OnlineStatus.Online;

        model.set_online_status (user_status_state);
        model.set_user_status_message (user_status_message);
        model.set_user_status_emoji (user_status_icon);
        model.set_clear_at (1);

        model.user_status ();
        GLib.assert_true (finished_spy.length == 1);

        var signal_user_status_set = fake_user_status_job.user_status_set_by_caller_of_set_user_status;
        GLib.assert_true (signal_user_status_set.icon () == user_status_icon);
        GLib.assert_true (signal_user_status_set.message () == user_status_message);
        GLib.assert_true (signal_user_status_set.state == user_status_state);
        GLib.assert_true (signal_user_status_set.message_predefined () == false);
        var clear_at = signal_user_status_set.clear_at ();
        GLib.assert_true (clear_at.is_valid);
        GLib.assert_true (clear_at.type == ClearAtType.PERIOD);
        GLib.assert_true (clear_at.period == 60 * 30);
    }

} // class TestSetUserStatusSetCustomMessageUserStatusSetCorrect

} // namespace Testing
} // namespace Occ
