/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestCtorFetchStatusAndPredefinedStatuses : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCtorFetchStatusAndPredefinedStatuses () {
        const GLib.DateTime current_date_time = GLib.DateTime.current_date_time ();

        const string user_status_id = "fake-identifier";
        const string user_status_message = "Some status";
        const string user_status_icon = "❤";
        const LibSync.UserStatus.OnlineStatus user_status_state = LibSync.UserStatus.OnlineStatus.DoNotDisturb;
        const bool user_status_message_predefined = false;
        Optional<ClearAt> user_status_clear_at; {
            ClearAt clear_at;
            clear_at.type = ClearAtType.TIMESTAMP;
            clear_at.timestamp = current_date_time.add_days (1).to_time_t ();
            user_status_clear_at = clear_at;
        }

        const LibSync.UserStatus user_status = new LibSync.UserStatus (user_status_id, user_status_message,
            user_status_icon, user_status_state, user_status_message_predefined, user_status_clear_at);

        var fake_predefined_statuses = create_fake_predefined_statuses (create_date_time ());

        var fake_user_status_job = new FakeUserStatusConnector ();
        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_date_time);
        fake_user_status_job.set_fake_user_status (user_status);
        fake_user_status_job.predefined_statuses (fake_predefined_statuses);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job, std.move (fake_date_time_provider));

        // Was user status set correctly?
        GLib.assert_true (model.user_status_message () == user_status_message);
        GLib.assert_true (model.user_status_emoji () == user_status_icon);
        GLib.assert_true (model.online_status () == user_status_state);
        GLib.assert_true (model.clear_at () == _("1 day"));

        // Were predefined statuses fetched correctly?
        var predefined_statuses_count = model.predefined_statuses_count ();
        GLib.assert_true (predefined_statuses_count == fake_predefined_statuses.size ());
        for (int i = 0; i < predefined_statuses_count; ++i) {
            var predefined_status = model.predefined_status (i);
            GLib.assert_true (predefined_status.identifier ==
                fake_predefined_statuses[i].identifier);
            GLib.assert_true (predefined_status.message () ==
                fake_predefined_statuses[i].message ());
            GLib.assert_true (predefined_status.icon () ==
                fake_predefined_statuses[i].icon ());
            GLib.assert_true (predefined_status.message_predefined () ==
                fake_predefined_statuses[i].message_predefined ());
        }
    }

} // class TestCtorFetchStatusAndPredefinedStatuses

} // namespace Testing
} // namespace Occ
