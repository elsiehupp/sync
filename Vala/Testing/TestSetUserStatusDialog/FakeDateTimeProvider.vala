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

    const string userStatusId ("fake-identifier");
    const string userStatusMessage ("Predefined status");
    const string userStatusIcon ("🏖");
    const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);
    const bool userStatusMessagePredefined (true);
    Occ.Optional<Occ.ClearAt> userStatusClearAt;
    Occ.ClearAt clearAt;
    clearAt.type = Occ.ClearAtType.Timestamp;
    clearAt.timestamp = currentTime.addSecs (60 * 60).toTime_t ();
    userStatusClearAt = clearAt;

    statuses.emplace_back (userStatusId, userStatusMessage, userStatusIcon,
        userStatusState, userStatusMessagePredefined, userStatusClearAt);

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