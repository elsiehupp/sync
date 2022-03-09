/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

class FakeDateTimeProvider : Occ.DateTimeProvider {

    /***********************************************************
    ***********************************************************/
    public void setCurrentDateTime (GLib.DateTime dateTime) { this.dateTime = dateTime; }


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public QDate currentDate () override ( return this.dateTime.date (); }


    /***********************************************************
    ***********************************************************/
    private GLib.DateTime this.dateTime;
}




static GLib.Vector<Occ.UserStatus>
createFakePredefinedStatuses (GLib.DateTime currentTime) {
    GLib.Vector<Occ.UserStatus> statuses;

    const string user_statusId ("fake-identifier");
    const string user_statusMessage ("Predefined status");
    const string user_statusIcon ("🏖");
    const Occ.UserStatus.OnlineStatus user_statusState (Occ.UserStatus.OnlineStatus.Online);
    const bool user_statusMessagePredefined (true);
    Occ.Optional<Occ.ClearAt> user_statusClearAt;
    Occ.ClearAt clearAt;
    clearAt.type = Occ.ClearAtType.Timestamp;
    clearAt.timestamp = currentTime.add_secs (60 * 60).toTime_t ();
    user_statusClearAt = clearAt;

    statuses.emplace_back (user_statusId, user_statusMessage, user_statusIcon,
        user_statusState, user_statusMessagePredefined, user_statusClearAt);

    return statuses;
}

static GLib.DateTime createDateTime (int year = 2021, int month = 7, int day = 27,
    int hour = 12, int minute = 0, int second = 0) {
    QDate fakeDate (year, month, day);
    QTime fakeTime (hour, minute, second);
    GLib.DateTime fakeDateTime;

    fakeDateTime.setDate (fakeDate);
    fakeDateTime.setTime (fakeTime);

    return fakeDateTime;
}