/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

public class FakeDateTimeProvider : Occ.DateTimeProvider {

    /***********************************************************
    ***********************************************************/
    private GLib.DateTime date_time;

    /***********************************************************
    ***********************************************************/
    public void set_current_date_time (GLib.DateTime date_time) {
        this.date_time = date_time;
    }


    /***********************************************************
    ***********************************************************/
    public override QDate current_date () {
        return this.date_time.date ();
    }


    /***********************************************************
    ***********************************************************/
    static GLib.List<Occ.UserStatus> create_fake_predefined_statuses (GLib.DateTime current_time) {
        GLib.List<Occ.UserStatus> statuses;

        const string user_status_id = "fake-identifier";
        const string user_status_message = "Predefined status";
        const string user_status_icon = "🏖";
        const Occ.UserStatus.OnlineStatus user_status_state = Occ.UserStatus.OnlineStatus.Online;
        const bool user_status_message_predefined = true;
        Occ.Optional<Occ.ClearAt> user_status_clear_at;
        Occ.ClearAt clear_at;
        clear_at.type = Occ.ClearAtType.Timestamp;
        clear_at.timestamp = current_time.add_secs (60 * 60).to_time_t ();
        user_status_clear_at = clear_at;

        statuses.emplace_back (user_status_id, user_status_message, user_status_icon,
            user_status_state, user_status_message_predefined, user_status_clear_at);

        return statuses;
    }


    /***********************************************************
    ***********************************************************/
    static GLib.DateTime create_date_time (
        int year = 2021, int month = 7, int day = 27,
        int hour = 12, int minute = 0, int second = 0) {
        QDate fake_date = new QDate (year, month, day);
        QTime fake_time = new QTime (hour, minute, second);
        GLib.DateTime fake_date_time;

        fake_date_time.set_date (fake_date);
        fake_date_time.set_time (fake_time);

        return fake_date_time;
    }

}
}
