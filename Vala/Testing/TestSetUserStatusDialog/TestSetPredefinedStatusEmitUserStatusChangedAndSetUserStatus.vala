/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetPredefinedStatusEmitUserStatusChangedAndSetUserStatus : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetPredefinedStatusEmitUserStatusChangedAndSetUserStatus () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        var fake_date_time_provider = new FakeDateTimeProvider ();
        var current_time = create_date_time ();
        fake_date_time_provider.set_current_date_time (current_time);
        var fake_predefined_statuses = create_fake_predefined_statuses (current_time);
        fake_user_status_job.predefined_statuses (fake_predefined_statuses);
        UserStatusSelectorModel model = new UserStatusSelectorModel (
            std.move (fake_user_status_job),
            std.move (fake_date_time_provider)
        );

        QSignalSpy user_status_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.user_status_changed
        );
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var fake_predefined_user_status_index = 0;
        model.set_predefined_status (fake_predefined_user_status_index);

        GLib.assert_true (user_status_changed_spy.length == 1);
        GLib.assert_true (clear_at_changed_spy.length == 1);

        // Was user status set correctly?
        var fake_predefined_user_status = fake_predefined_statuses[fake_predefined_user_status_index];
        GLib.assert_true (model.user_status_message () == fake_predefined_user_status.message ());
        GLib.assert_true (model.user_status_emoji () == fake_predefined_user_status.icon ());
        GLib.assert_true (model.online_status () == fake_predefined_user_status.state);
        GLib.assert_true (model.clear_at () == _("1 hour"));
    }

} // class TestSetPredefinedStatusEmitUserStatusChangedAndSetUserStatus

} // namespace Testing
} // namespace Occ
