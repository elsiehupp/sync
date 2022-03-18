/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>
//  #include <QSignalSpy>
//  #include <memory>

namespace Testing {

public class TestSetUserStatusDialog : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_ctor_fetch_status_and_predefined_statuses () {
        const GLib.DateTime current_date_time = GLib.DateTime.current_date_time ();

        const string user_status_id = "fake-identifier";
        const string user_status_message = "Some status";
        const string user_status_icon = "❤";
        const UserStatus.OnlineStatus user_status_state = UserStatus.OnlineStatus.DoNotDisturb;
        const bool user_status_message_predefined = false;
        Optional<ClearAt> user_status_clear_at; {
            ClearAt clear_at;
            clear_at.type = ClearAtType.Timestamp;
            clear_at.timestamp = current_date_time.add_days (1).to_time_t ();
            user_status_clear_at = clear_at;
        }

        const UserStatus user_status = new UserStatus (user_status_id, user_status_message,
            user_status_icon, user_status_state, user_status_message_predefined, user_status_clear_at);

        var fake_predefined_statuses = create_fake_predefined_statuses (create_date_time ());

        var fake_user_status_job = new FakeUserStatusConnector ();
        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_date_time);
        fake_user_status_job.set_fake_user_status (user_status);
        fake_user_status_job.set_fake_predefined_statuses (fake_predefined_statuses);
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
            GLib.assert_true (predefined_status.identifier () ==
                fake_predefined_statuses[i].identifier ());
            GLib.assert_true (predefined_status.message () ==
                fake_predefined_statuses[i].message ());
            GLib.assert_true (predefined_status.icon () ==
                fake_predefined_statuses[i].icon ());
            GLib.assert_true (predefined_status.message_predefined () ==
                fake_predefined_statuses[i].message_predefined ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_ctor_no_status_set_show_sensible_defaults () {
        UserStatusSelectorModel model = new UserStatusSelectorModel (null, null);

        GLib.assert_true (model.user_status_message () == "");
        GLib.assert_true (model.user_status_emoji () == "😀");
        GLib.assert_true (model.clear_at () == _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_ctor_fetch_status_but_no_status_set_show_sensible_defaults () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_fake_user_status ({ "", "", "",
            UserStatus.OnlineStatus.Offline, false, {} });
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.online_status () == UserStatus.OnlineStatus.Online);
        GLib.assert_true (model.user_status_message () == "");
        GLib.assert_true (model.user_status_emoji () == "😀");
        GLib.assert_true (model.clear_at () == _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_online_status_emit_online_status_changed () {
        const UserStatus.OnlineStatus online_status = UserStatus.OnlineStatus.Invisible;
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy online_status_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.online_status_changed
        );

        model.set_online_status (online_status);

        GLib.assert_true (online_status_changed_spy.count () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_user_status_set_custom_message_user_status_set_correct () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy finished_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.on_signal_finished
        );

        const string user_status_message = "Some status";
        const string user_status_icon = "❤";
        const UserStatus.OnlineStatus user_status_state = UserStatus.OnlineStatus.Online;

        model.set_online_status (user_status_state);
        model.set_user_status_message (user_status_message);
        model.set_user_status_emoji (user_status_icon);
        model.set_clear_at (1);

        model.set_user_status ();
        GLib.assert_true (finished_spy.count () == 1);

        var signal_user_status_set = fake_user_status_job.user_status_set_by_caller_of_set_user_status ();
        GLib.assert_true (signal_user_status_set.icon () == user_status_icon);
        GLib.assert_true (signal_user_status_set.message () == user_status_message);
        GLib.assert_true (signal_user_status_set.state () == user_status_state);
        GLib.assert_true (signal_user_status_set.message_predefined () == false);
        var clear_at = signal_user_status_set.clear_at ();
        GLib.assert_true (clear_at.is_valid ());
        GLib.assert_true (clear_at.type == ClearAtType.Period);
        GLib.assert_true (clear_at.period == 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_user_status_message_predefined_status_was_set_user_status_set_correct () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_fake_predefined_statuses (create_fake_predefined_statuses (create_date_time ()));
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.set_predefined_status (0);
        QSignalSpy finished_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.on_signal_finished
        );

        const string user_status_message = "Some status";
        const UserStatus.OnlineStatus user_status_state = UserStatus.OnlineStatus.Online;

        model.set_online_status (user_status_state);
        model.set_user_status_message (user_status_message);
        model.set_clear_at (1);

        model.set_user_status ();
        GLib.assert_true (finished_spy.count () == 1);

        var signal_user_status_set = fake_user_status_job.user_status_set_by_caller_of_set_user_status ();
        GLib.assert_true (signal_user_status_set.message () == user_status_message);
        GLib.assert_true (signal_user_status_set.state () == user_status_state);
        GLib.assert_true (signal_user_status_set.message_predefined () == false);
        var clear_at = signal_user_status_set.clear_at ();
        GLib.assert_true (clear_at.is_valid ());
        GLib.assert_true (clear_at.type == ClearAtType.Period);
        GLib.assert_true (clear_at.period == 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_user_status_emoji_predefined_status_was_set_user_status_set_correct () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_fake_predefined_statuses (create_fake_predefined_statuses (create_date_time ()));
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.set_predefined_status (0);
        QSignalSpy finished_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.on_signal_finished
        );

        const string user_status_icon = "❤";
        const UserStatus.OnlineStatus user_status_state = UserStatus.OnlineStatus.Online;

        model.set_online_status (user_status_state);
        model.set_user_status_emoji (user_status_icon);
        model.set_clear_at (1);

        model.set_user_status ();
        GLib.assert_true (finished_spy.count () == 1);

        var signal_user_status_set = fake_user_status_job.user_status_set_by_caller_of_set_user_status ();
        GLib.assert_true (signal_user_status_set.icon () == user_status_icon);
        GLib.assert_true (signal_user_status_set.state () == user_status_state);
        GLib.assert_true (signal_user_status_set.message_predefined () == false);
        var clear_at = signal_user_status_set.clear_at ();
        GLib.assert_true (clear_at.is_valid ());
        GLib.assert_true (clear_at.type == ClearAtType.Period);
        GLib.assert_true (clear_at.period == 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_predefined_status_emit_user_status_changed_and_set_user_status () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        var fake_date_time_provider = new FakeDateTimeProvider ();
        var current_time = create_date_time ();
        fake_date_time_provider.set_current_date_time (current_time);
        var fake_predefined_statuses = create_fake_predefined_statuses (current_time);
        fake_user_status_job.set_fake_predefined_statuses (fake_predefined_statuses);
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

        GLib.assert_true (user_status_changed_spy.count () == 1);
        GLib.assert_true (clear_at_changed_spy.count () == 1);

        // Was user status set correctly?
        var fake_predefined_user_status = fake_predefined_statuses[fake_predefined_user_status_index];
        GLib.assert_true (model.user_status_message () == fake_predefined_user_status.message ());
        GLib.assert_true (model.user_status_emoji () == fake_predefined_user_status.icon ());
        GLib.assert_true (model.online_status () == fake_predefined_user_status.state ());
        GLib.assert_true (model.clear_at () == _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage0_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 0;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage1_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 1;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("30 minutes"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage2_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 2;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage3_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 3;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("4 hours"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage4_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 4;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("Today"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_set_clear_set_clear_at_stage5_emit_clear_at_changed_and_clear_at_set () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 5;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_at_stages () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.clear_at () == _("Don't clear"));
        var clear_at_values = model.clear_at_values ();
        GLib.assert_true (clear_at_values.count () == 6);

        GLib.assert_true (clear_at_values[0] == _("Don't clear"));
        GLib.assert_true (clear_at_values[1] == _("30 minutes"));
        GLib.assert_true (clear_at_values[2] == _("1 hour"));
        GLib.assert_true (clear_at_values[3] == _("4 hours"));
        GLib.assert_true (clear_at_values[4] == _("Today"));
        GLib.assert_true (clear_at_values[5] == _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_at_clear_at_timestamp () {
        const GLib.DateTime current_time = create_date_time ();
        clear_at_clear_at_timestamp_test_1 (current_time);
        clear_at_clear_at_timestamp_test_2 (current_time);
        clear_at_clear_at_timestamp_test_3 (current_time);
        clear_at_clear_at_timestamp_test_4 (current_time);
        clear_at_clear_at_timestamp_test_5 (current_time);
        clear_at_clear_at_timestamp_test_6 (current_time);
        clear_at_clear_at_timestamp_test_7 (current_time);
    }


    private void clear_at_clear_at_timestamp_test_1 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (30).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("Less than a minute"));
    }


    private void clear_at_clear_at_timestamp_test_2 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (60).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("1 minute"));
    }


    private void clear_at_clear_at_timestamp_test_3 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (60 * 30).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("30 minutes"));
    }


    private void clear_at_clear_at_timestamp_test_4 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (60 * 60).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("1 hour"));
    }


    private void clear_at_clear_at_timestamp_test_5 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (60 * 60 * 4).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("4 hours"));
    }


    private void clear_at_clear_at_timestamp_test_6 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_days (1).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("1 day"));
    }


    private void clear_at_clear_at_timestamp_test_7 (GLib.DateTime current_time) {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_days (7).to_time_t ();
        user_status.set_clear_at (clear_at);

        var fake_date_time_provider = new FakeDateTimeProvider ();
        fake_date_time_provider.set_current_date_time (current_time);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status, std.move (fake_date_time_provider));

        GLib.assert_true (model.clear_at () == _("7 days"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_at_clear_at_end_of () {
        clear_at_clear_at_end_of_test_1 ();
        clear_at_clear_at_end_of_test_2 ();
    }



    private void clear_at_clear_at_end_of_test_1 () {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.EndOf;
        clear_at.endof = "day";
        user_status.set_clear_at (clear_at);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

        GLib.assert_true (model.clear_at () == _("Today"));
    }


    private void clear_at_clear_at_end_of_test_2 () {
        UserStatus user_status;
        ClearAt clear_at;
        clear_at.type = ClearAtType.EndOf;
        clear_at.endof = "week";
        user_status.set_clear_at (clear_at);

        UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

        GLib.assert_true (model.clear_at () == _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_at_clear_at_after_period () {
        {
            UserStatus user_status;
            ClearAt clear_at;
            clear_at.type = ClearAtType.Period;
            clear_at.period = 60 * 30;
            user_status.set_clear_at (clear_at);

            UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

            GLib.assert_true (model.clear_at () == _("30 minutes"));
        }
        {
            UserStatus user_status;
            ClearAt clear_at;
            clear_at.type = ClearAtType.Period;
            clear_at.period = 60 * 60;
            user_status.set_clear_at (clear_at);

            UserStatusSelectorModel model = new UserStatusSelectorModel (user_status);

            GLib.assert_true (model.clear_at () == _("1 hour"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_user_status () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        model.clear_user_status ();

        GLib.assert_true (fake_user_status_job.message_cleared ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_could_not_fetch_predefined_statuses_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_fetch_predefined_user_statuses (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Could not fetch predefined statuses. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_could_not_fetch_user_status_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_fetch_user_status (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Could not fetch user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_user_status_not_supported_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_user_status_not_supported (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("User status feature is not supported. You will not be able to set your user status."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_could_set_user_status_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_set_user_status_message (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.set_user_status ();

        GLib.assert_true (model.error_message () ==
            _("Could not set user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_emojis_not_supported_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_emojis_not_supported (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Emojis feature is not supported. Some user status functionality may not work."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_could_not_clear_message_emit_error () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_clear_user_status_message (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.clear_user_status ();

        GLib.assert_true (model.error_message () ==
            _("Could not clear user status message. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_set_user_status_clear_error_message () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        fake_user_status_job.set_error_could_not_set_user_status_message (true);
        model.set_user_status ();
        GLib.assert_true (!model.error_message () == "");
        fake_user_status_job.set_error_could_not_set_user_status_message (false);
        model.set_user_status ();
        GLib.assert_true (model.error_message () == "");
    }


    /***********************************************************
    ***********************************************************/
    private void test_error_clear_user_status_clear_erroressage () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        fake_user_status_job.set_error_could_not_set_user_status_message (true);
        model.set_user_status ();
        GLib.assert_true (!model.error_message () == "");
        fake_user_status_job.set_error_could_not_set_user_status_message (false);
        model.clear_user_status ();
        GLib.assert_true (model.error_message () == "");
    }

}
}
