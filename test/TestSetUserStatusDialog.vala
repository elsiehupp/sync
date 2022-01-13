/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTest>
// #include <QSignalSpy>
// #include <QDateTime>

// #include <memory>

class FakeUserStatusConnector : Occ.UserStatusConnector {
public:
    void fetchUserStatus () override {
        if (_couldNotFetchUserStatus) {
            emit error (Error.CouldNotFetchUserStatus);
            return;
        } else if (_userStatusNotSupported) {
            emit error (Error.UserStatusNotSupported);
            return;
        } else if (_emojisNotSupported) {
            emit error (Error.EmojisNotSupported);
            return;
        }

        emit userStatusFetched (_userStatus);
    }

    void fetchPredefinedStatuses () override {
        if (_couldNotFetchPredefinedUserStatuses) {
            emit error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        emit predefinedStatusesFetched (_predefinedStatuses);
    }

    void setUserStatus (Occ.UserStatus &userStatus) override {
        if (_couldNotSetUserStatusMessage) {
            emit error (Error.CouldNotSetUserStatus);
            return;
        }

        _userStatusSetByCallerOfSetUserStatus = userStatus;
        emit UserStatusConnector.userStatusSet ();
    }

    void clearMessage () override {
        if (_couldNotClearUserStatusMessage) {
            emit error (Error.CouldNotClearMessage);
        } else {
            _isMessageCleared = true;
        }
    }

    Occ.UserStatus userStatus () const override {
        return {}; // Not implemented
    }

    void setFakeUserStatus (Occ.UserStatus &userStatus) {
        _userStatus = userStatus;
    }

    void setFakePredefinedStatuses (
        const std.vector<Occ.UserStatus> &statuses) {
        _predefinedStatuses = statuses;
    }

    Occ.UserStatus userStatusSetByCallerOfSetUserStatus () { return _userStatusSetByCallerOfSetUserStatus; }

    bool messageCleared () { return _isMessageCleared; }

    void setErrorCouldNotFetchPredefinedUserStatuses (bool value) {
        _couldNotFetchPredefinedUserStatuses = value;
    }

    void setErrorCouldNotFetchUserStatus (bool value) {
        _couldNotFetchUserStatus = value;
    }

    void setErrorCouldNotSetUserStatusMessage (bool value) {
        _couldNotSetUserStatusMessage = value;
    }

    void setErrorUserStatusNotSupported (bool value) {
        _userStatusNotSupported = value;
    }

    void setErrorEmojisNotSupported (bool value) {
        _emojisNotSupported = value;
    }

    void setErrorCouldNotClearUserStatusMessage (bool value) {
        _couldNotClearUserStatusMessage = value;
    }

private:
    Occ.UserStatus _userStatusSetByCallerOfSetUserStatus;
    Occ.UserStatus _userStatus;
    std.vector<Occ.UserStatus> _predefinedStatuses;
    bool _isMessageCleared = false;
    bool _couldNotFetchPredefinedUserStatuses = false;
    bool _couldNotFetchUserStatus = false;
    bool _couldNotSetUserStatusMessage = false;
    bool _userStatusNotSupported = false;
    bool _emojisNotSupported = false;
    bool _couldNotClearUserStatusMessage = false;
};

class FakeDateTimeProvider : Occ.DateTimeProvider {
public:
    void setCurrentDateTime (QDateTime &dateTime) { _dateTime = dateTime; }

    QDateTime currentDateTime () const override { return _dateTime; }

    QDate currentDate () const override { return _dateTime.date (); }

private:
    QDateTime _dateTime;
};

static std.vector<Occ.UserStatus>
createFakePredefinedStatuses (QDateTime &currentTime) {
    std.vector<Occ.UserStatus> statuses;

    const string userStatusId ("fake-id");
    const string userStatusMessage ("Predefined status");
    const string userStatusIcon ("🏖");
    const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);
    const bool userStatusMessagePredefined (true);
    Occ.Optional<Occ.ClearAt> userStatusClearAt;
    Occ.ClearAt clearAt;
    clearAt._type = Occ.ClearAtType.Timestamp;
    clearAt._timestamp = currentTime.addSecs (60 * 60).toTime_t ();
    userStatusClearAt = clearAt;

    statuses.emplace_back (userStatusId, userStatusMessage, userStatusIcon,
        userStatusState, userStatusMessagePredefined, userStatusClearAt);

    return statuses;
}

static QDateTime createDateTime (int year = 2021, int month = 7, int day = 27,
    int hour = 12, int minute = 0, int second = 0) {
    QDate fakeDate (year, month, day);
    QTime fakeTime (hour, minute, second);
    QDateTime fakeDateTime;

    fakeDateTime.setDate (fakeDate);
    fakeDateTime.setTime (fakeTime);

    return fakeDateTime;
}

class TestSetUserStatusDialog : GLib.Object {

private slots:
    void testCtor_fetchStatusAndPredefinedStatuses () {
        const QDateTime currentDateTime (QDateTime.currentDateTime ());

        const string userStatusId ("fake-id");
        const string userStatusMessage ("Some status");
        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.DoNotDisturb);
        const bool userStatusMessagePredefined (false);
        Occ.Optional<Occ.ClearAt> userStatusClearAt; {
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentDateTime.addDays (1).toTime_t ();
            userStatusClearAt = clearAt;
        }

        const Occ.UserStatus userStatus (userStatusId, userStatusMessage,
            userStatusIcon, userStatusState, userStatusMessagePredefined, userStatusClearAt);

        const auto fakePredefinedStatuses = createFakePredefinedStatuses (createDateTime ());

        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        fakeDateTimeProvider.setCurrentDateTime (currentDateTime);
        fakeUserStatusJob.setFakeUserStatus (userStatus);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob, std.move (fakeDateTimeProvider));

        // Was user status set correctly?
        QCOMPARE (model.userStatusMessage (), userStatusMessage);
        QCOMPARE (model.userStatusEmoji (), userStatusIcon);
        QCOMPARE (model.onlineStatus (), userStatusState);
        QCOMPARE (model.clearAt (), tr ("1 day"));

        // Were predefined statuses fetched correctly?
        const auto predefinedStatusesCount = model.predefinedStatusesCount ();
        QCOMPARE (predefinedStatusesCount, fakePredefinedStatuses.size ());
        for (int i = 0; i < predefinedStatusesCount; ++i) {
            const auto predefinedStatus = model.predefinedStatus (i);
            QCOMPARE (predefinedStatus.id (),
                fakePredefinedStatuses[i].id ());
            QCOMPARE (predefinedStatus.message (),
                fakePredefinedStatuses[i].message ());
            QCOMPARE (predefinedStatus.icon (),
                fakePredefinedStatuses[i].icon ());
            QCOMPARE (predefinedStatus.messagePredefined (),
                fakePredefinedStatuses[i].messagePredefined ());
        }
    }

    void testCtor_noStatusSet_showSensibleDefaults () {
        Occ.UserStatusSelectorModel model (nullptr, nullptr);

        QCOMPARE (model.userStatusMessage (), "");
        QCOMPARE (model.userStatusEmoji (), "😀");
        QCOMPARE (model.clearAt (), tr ("Don't clear"));
    }

    void testCtor_fetchStatusButNoStatusSet_showSensibleDefaults () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakeUserStatus ({ "", "", "",
            Occ.UserStatus.OnlineStatus.Offline, false, {} });
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.onlineStatus (), Occ.UserStatus.OnlineStatus.Online);
        QCOMPARE (model.userStatusMessage (), "");
        QCOMPARE (model.userStatusEmoji (), "😀");
        QCOMPARE (model.clearAt (), tr ("Don't clear"));
    }

    void testSetOnlineStatus_emitOnlineStatusChanged () {
        const Occ.UserStatus.OnlineStatus onlineStatus (Occ.UserStatus.OnlineStatus.Invisible);
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy onlineStatusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.onlineStatusChanged);

        model.setOnlineStatus (onlineStatus);

        QCOMPARE (onlineStatusChangedSpy.count (), 1);
    }

    void testSetUserStatus_setCustomMessage_userStatusSetCorrect () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.finished);

        const string userStatusMessage ("Some status");
        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusMessage (userStatusMessage);
        model.setUserStatusEmoji (userStatusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        QCOMPARE (finishedSpy.count (), 1);

        const auto userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        QCOMPARE (userStatusSet.icon (), userStatusIcon);
        QCOMPARE (userStatusSet.message (), userStatusMessage);
        QCOMPARE (userStatusSet.state (), userStatusState);
        QCOMPARE (userStatusSet.messagePredefined (), false);
        const auto clearAt = userStatusSet.clearAt ();
        QVERIFY (clearAt.isValid ());
        QCOMPARE (clearAt._type, Occ.ClearAtType.Period);
        QCOMPARE (clearAt._period, 60 * 30);
    }

    void testSetUserStatusMessage_predefinedStatusWasSet_userStatusSetCorrect () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.finished);

        const string userStatusMessage ("Some status");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusMessage (userStatusMessage);
        model.setClearAt (1);

        model.setUserStatus ();
        QCOMPARE (finishedSpy.count (), 1);

        const auto userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        QCOMPARE (userStatusSet.message (), userStatusMessage);
        QCOMPARE (userStatusSet.state (), userStatusState);
        QCOMPARE (userStatusSet.messagePredefined (), false);
        const auto clearAt = userStatusSet.clearAt ();
        QVERIFY (clearAt.isValid ());
        QCOMPARE (clearAt._type, Occ.ClearAtType.Period);
        QCOMPARE (clearAt._period, 60 * 30);
    }

    void testSetUserStatusEmoji_predefinedStatusWasSet_userStatusSetCorrect () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.finished);

        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusEmoji (userStatusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        QCOMPARE (finishedSpy.count (), 1);

        const auto userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        QCOMPARE (userStatusSet.icon (), userStatusIcon);
        QCOMPARE (userStatusSet.state (), userStatusState);
        QCOMPARE (userStatusSet.messagePredefined (), false);
        const auto clearAt = userStatusSet.clearAt ();
        QVERIFY (clearAt.isValid ());
        QCOMPARE (clearAt._type, Occ.ClearAtType.Period);
        QCOMPARE (clearAt._period, 60 * 30);
    }

    void testSetPredefinedStatus_emitUserStatusChangedAndSetUserStatus () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        const auto currentTime = createDateTime ();
        fakeDateTimeProvider.setCurrentDateTime (currentTime);
        const auto fakePredefinedStatuses = createFakePredefinedStatuses (currentTime);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (std.move (fakeUserStatusJob),
            std.move (fakeDateTimeProvider));

        QSignalSpy userStatusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.userStatusChanged);
        QSignalSpy clearAtChangedSpy (&model,
            &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto fakePredefinedUserStatusIndex = 0;
        model.setPredefinedStatus (fakePredefinedUserStatusIndex);

        QCOMPARE (userStatusChangedSpy.count (), 1);
        QCOMPARE (clearAtChangedSpy.count (), 1);

        // Was user status set correctly?
        const auto fakePredefinedUserStatus = fakePredefinedStatuses[fakePredefinedUserStatusIndex];
        QCOMPARE (model.userStatusMessage (), fakePredefinedUserStatus.message ());
        QCOMPARE (model.userStatusEmoji (), fakePredefinedUserStatus.icon ());
        QCOMPARE (model.onlineStatus (), fakePredefinedUserStatus.state ());
        QCOMPARE (model.clearAt (), tr ("1 hour"));
    }

    void testSetClear_setClearAtStage0_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 0;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("Don't clear"));
    }

    void testSetClear_setClearAtStage1_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 1;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("30 minutes"));
    }

    void testSetClear_setClearAtStage2_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 2;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("1 hour"));
    }

    void testSetClear_setClearAtStage3_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 3;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("4 hours"));
    }

    void testSetClear_setClearAtStage4_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 4;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("Today"));
    }

    void testSetClear_setClearAtStage5_emitClearAtChangedAndClearAtSet () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const auto clearAtIndex = 5;
        model.setClearAt (clearAtIndex);

        QCOMPARE (clearAtChangedSpy.count (), 1);
        QCOMPARE (model.clearAt (), tr ("This week"));
    }

    void testClearAtStages () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.clearAt (), tr ("Don't clear"));
        const auto clearAtValues = model.clearAtValues ();
        QCOMPARE (clearAtValues.count (), 6);

        QCOMPARE (clearAtValues[0], tr ("Don't clear"));
        QCOMPARE (clearAtValues[1], tr ("30 minutes"));
        QCOMPARE (clearAtValues[2], tr ("1 hour"));
        QCOMPARE (clearAtValues[3], tr ("4 hours"));
        QCOMPARE (clearAtValues[4], tr ("Today"));
        QCOMPARE (clearAtValues[5], tr ("This week"));
    }

    void testClearAt_clearAtTimestamp () { {onst auto currentTime = createDateTime ();
        {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addSecs (30).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("Less than a minute"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addSecs (60).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("1 minute"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addSecs (60 * 30).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("30 minutes"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addSecs (60 * 60).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("1 hour"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addSecs (60 * 60 * 4).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("4 hours"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addDays (1).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("1 day"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Timestamp;
            clearAt._timestamp = currentTime.addDays (7).toTime_t ();
            userStatus.setClearAt (clearAt);

            auto fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            QCOMPARE (model.clearAt (), tr ("7 days"));
        }
    }

    void testClearAt_clearAtEndOf () { {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.EndOf;
            clearAt._endof = "day";
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            QCOMPARE (model.clearAt (), tr ("Today"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.EndOf;
            clearAt._endof = "week";
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            QCOMPARE (model.clearAt (), tr ("This week"));
        }
    }

    void testClearAt_clearAtAfterPeriod () { {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Period;
            clearAt._period = 60 * 30;
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            QCOMPARE (model.clearAt (), tr ("30 minutes"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt._type = Occ.ClearAtType.Period;
            clearAt._period = 60 * 60;
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            QCOMPARE (model.clearAt (), tr ("1 hour"));
        }
    }

    void testClearUserStatus () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        model.clearUserStatus ();

        QVERIFY (fakeUserStatusJob.messageCleared ());
    }

    void testError_couldNotFetchPredefinedStatuses_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchPredefinedUserStatuses (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.errorMessage (),
            tr ("Could not fetch predefined statuses. Make sure you are connected to the server."));
    }

    void testError_couldNotFetchUserStatus_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchUserStatus (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.errorMessage (),
            tr ("Could not fetch user status. Make sure you are connected to the server."));
    }

    void testError_userStatusNotSupported_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorUserStatusNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.errorMessage (),
            tr ("User status feature is not supported. You will not be able to set your user status."));
    }

    void testError_couldSetUserStatus_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setUserStatus ();

        QCOMPARE (model.errorMessage (),
            tr ("Could not set user status. Make sure you are connected to the server."));
    }

    void testError_emojisNotSupported_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorEmojisNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        QCOMPARE (model.errorMessage (),
            tr ("Emojis feature is not supported. Some user status functionality may not work."));
    }

    void testError_couldNotClearMessage_emitError () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotClearUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.clearUserStatus ();

        QCOMPARE (model.errorMessage (),
            tr ("Could not clear user status message. Make sure you are connected to the server."));
    }

    void testError_setUserStatus_clearErrorMessage () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        QVERIFY (!model.errorMessage ().isEmpty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.setUserStatus ();
        QVERIFY (model.errorMessage ().isEmpty ());
    }

    void testError_clearUserStatus_clearErrorMessage () {
        auto fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        QVERIFY (!model.errorMessage ().isEmpty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.clearUserStatus ();
        QVERIFY (model.errorMessage ().isEmpty ());
    }
};

QTEST_GUILESS_MAIN (TestSetUserStatusDialog)
#include "testsetuserstatusdialog.moc"
