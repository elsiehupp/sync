/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>
//  #include <QSignalSpy>
//  #include <memory>

namespace Testing {

class TestSetUserStatusDialog : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testCtor_fetchStatusAndPredefinedStatuses () {
        const GLib.DateTime currentDateTime (GLib.DateTime.currentDateTime ());

        const string userStatusId ("fake-identifier");
        const string userStatusMessage ("Some status");
        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.DoNotDisturb);
        const bool userStatusMessagePredefined (false);
        Occ.Optional<Occ.ClearAt> userStatusClearAt; {
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentDateTime.addDays (1).toTime_t ();
            userStatusClearAt = clearAt;
        }

        const Occ.UserStatus userStatus (userStatusId, userStatusMessage,
            userStatusIcon, userStatusState, userStatusMessagePredefined, userStatusClearAt);

        const var fakePredefinedStatuses = createFakePredefinedStatuses (createDateTime ());

        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        fakeDateTimeProvider.setCurrentDateTime (currentDateTime);
        fakeUserStatusJob.setFakeUserStatus (userStatus);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob, std.move (fakeDateTimeProvider));

        // Was user status set correctly?
        //  QCOMPARE (model.userStatusMessage (), userStatusMessage);
        //  QCOMPARE (model.userStatusEmoji (), userStatusIcon);
        //  QCOMPARE (model.onlineStatus (), userStatusState);
        //  QCOMPARE (model.clearAt (), _("1 day"));

        // Were predefined statuses fetched correctly?
        const var predefinedStatusesCount = model.predefinedStatusesCount ();
        //  QCOMPARE (predefinedStatusesCount, fakePredefinedStatuses.size ());
        for (int i = 0; i < predefinedStatusesCount; ++i) {
            const var predefinedStatus = model.predefinedStatus (i);
            //  QCOMPARE (predefinedStatus.identifier (),
                fakePredefinedStatuses[i].identifier ());
            //  QCOMPARE (predefinedStatus.message (),
                fakePredefinedStatuses[i].message ());
            //  QCOMPARE (predefinedStatus.icon (),
                fakePredefinedStatuses[i].icon ());
            //  QCOMPARE (predefinedStatus.messagePredefined (),
                fakePredefinedStatuses[i].messagePredefined ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCtor_noStatusSet_showSensibleDefaults () {
        Occ.UserStatusSelectorModel model (null, null);

        //  QCOMPARE (model.userStatusMessage (), "");
        //  QCOMPARE (model.userStatusEmoji (), "😀");
        //  QCOMPARE (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCtor_fetchStatusButNoStatusSet_showSensibleDefaults () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakeUserStatus ({ "", "", "",
            Occ.UserStatus.OnlineStatus.Offline, false, {} });
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.onlineStatus (), Occ.UserStatus.OnlineStatus.Online);
        //  QCOMPARE (model.userStatusMessage (), "");
        //  QCOMPARE (model.userStatusEmoji (), "😀");
        //  QCOMPARE (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetOnlineStatus_emitOnlineStatusChanged () {
        const Occ.UserStatus.OnlineStatus onlineStatus (Occ.UserStatus.OnlineStatus.Invisible);
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy onlineStatusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.onlineStatusChanged);

        model.setOnlineStatus (onlineStatus);

        //  QCOMPARE (onlineStatusChangedSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetUserStatus_setCustomMessage_userStatusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string userStatusMessage ("Some status");
        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusMessage (userStatusMessage);
        model.setUserStatusEmoji (userStatusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        //  QCOMPARE (finishedSpy.count (), 1);

        const var userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        //  QCOMPARE (userStatusSet.icon (), userStatusIcon);
        //  QCOMPARE (userStatusSet.message (), userStatusMessage);
        //  QCOMPARE (userStatusSet.state (), userStatusState);
        //  QCOMPARE (userStatusSet.messagePredefined (), false);
        const var clearAt = userStatusSet.clearAt ();
        //  QVERIFY (clearAt.isValid ());
        //  QCOMPARE (clearAt.type, Occ.ClearAtType.Period);
        //  QCOMPARE (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetUserStatusMessage_predefinedStatusWasSet_userStatusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string userStatusMessage ("Some status");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusMessage (userStatusMessage);
        model.setClearAt (1);

        model.setUserStatus ();
        //  QCOMPARE (finishedSpy.count (), 1);

        const var userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        //  QCOMPARE (userStatusSet.message (), userStatusMessage);
        //  QCOMPARE (userStatusSet.state (), userStatusState);
        //  QCOMPARE (userStatusSet.messagePredefined (), false);
        const var clearAt = userStatusSet.clearAt ();
        //  QVERIFY (clearAt.isValid ());
        //  QCOMPARE (clearAt.type, Occ.ClearAtType.Period);
        //  QCOMPARE (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetUserStatusEmoji_predefinedStatusWasSet_userStatusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string userStatusIcon ("❤");
        const Occ.UserStatus.OnlineStatus userStatusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (userStatusState);
        model.setUserStatusEmoji (userStatusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        //  QCOMPARE (finishedSpy.count (), 1);

        const var userStatusSet = fakeUserStatusJob.userStatusSetByCallerOfSetUserStatus ();
        //  QCOMPARE (userStatusSet.icon (), userStatusIcon);
        //  QCOMPARE (userStatusSet.state (), userStatusState);
        //  QCOMPARE (userStatusSet.messagePredefined (), false);
        const var clearAt = userStatusSet.clearAt ();
        //  QVERIFY (clearAt.isValid ());
        //  QCOMPARE (clearAt.type, Occ.ClearAtType.Period);
        //  QCOMPARE (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetPredefinedStatus_emitUserStatusChangedAndSetUserStatus () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        const var currentTime = createDateTime ();
        fakeDateTimeProvider.setCurrentDateTime (currentTime);
        const var fakePredefinedStatuses = createFakePredefinedStatuses (currentTime);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (std.move (fakeUserStatusJob),
            std.move (fakeDateTimeProvider));

        QSignalSpy userStatusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.userStatusChanged);
        QSignalSpy clearAtChangedSpy (&model,
            &Occ.UserStatusSelectorModel.clearAtChanged);

        const var fakePredefinedUserStatusIndex = 0;
        model.setPredefinedStatus (fakePredefinedUserStatusIndex);

        //  QCOMPARE (userStatusChangedSpy.count (), 1);
        //  QCOMPARE (clearAtChangedSpy.count (), 1);

        // Was user status set correctly?
        const var fakePredefinedUserStatus = fakePredefinedStatuses[fakePredefinedUserStatusIndex];
        //  QCOMPARE (model.userStatusMessage (), fakePredefinedUserStatus.message ());
        //  QCOMPARE (model.userStatusEmoji (), fakePredefinedUserStatus.icon ());
        //  QCOMPARE (model.onlineStatus (), fakePredefinedUserStatus.state ());
        //  QCOMPARE (model.clearAt (), _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage0_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 0;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage1_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 1;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("30 minutes"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage2_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 2;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage3_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 3;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("4 hours"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage4_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 4;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("Today"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSetClear_setClearAtStage5_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        const var clearAtIndex = 5;
        model.setClearAt (clearAtIndex);

        //  QCOMPARE (clearAtChangedSpy.count (), 1);
        //  QCOMPARE (model.clearAt (), _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClearAtStages () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.clearAt (), _("Don't clear"));
        const var clearAtValues = model.clearAtValues ();
        //  QCOMPARE (clearAtValues.count (), 6);

        //  QCOMPARE (clearAtValues[0], _("Don't clear"));
        //  QCOMPARE (clearAtValues[1], _("30 minutes"));
        //  QCOMPARE (clearAtValues[2], _("1 hour"));
        //  QCOMPARE (clearAtValues[3], _("4 hours"));
        //  QCOMPARE (clearAtValues[4], _("Today"));
        //  QCOMPARE (clearAtValues[5], _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClearAt_clearAtTimestamp () { {onst var currentTime = createDateTime ();
        {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addSecs (30).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("Less than a minute"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addSecs (60).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("1 minute"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addSecs (60 * 30).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("30 minutes"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addSecs (60 * 60).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("1 hour"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addSecs (60 * 60 * 4).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("4 hours"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addDays (1).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("1 day"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.addDays (7).toTime_t ();
            userStatus.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (userStatus, std.move (fakeDateTimeProvider));

            //  QCOMPARE (model.clearAt (), _("7 days"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClearAt_clearAtEndOf () { {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.EndOf;
            clearAt.endof = "day";
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            //  QCOMPARE (model.clearAt (), _("Today"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.EndOf;
            clearAt.endof = "week";
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            //  QCOMPARE (model.clearAt (), _("This week"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClearAt_clearAtAfterPeriod () { {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Period;
            clearAt.period = 60 * 30;
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            //  QCOMPARE (model.clearAt (), _("30 minutes"));
        }
 {
            Occ.UserStatus userStatus;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Period;
            clearAt.period = 60 * 60;
            userStatus.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (userStatus);

            //  QCOMPARE (model.clearAt (), _("1 hour"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClearUserStatus () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        model.clearUserStatus ();

        //  QVERIFY (fakeUserStatusJob.messageCleared ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_couldNotFetchPredefinedStatuses_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchPredefinedUserStatuses (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.errorMessage (),
            _("Could not fetch predefined statuses. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_couldNotFetchUserStatus_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchUserStatus (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.errorMessage (),
            _("Could not fetch user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_userStatusNotSupported_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorUserStatusNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.errorMessage (),
            _("User status feature is not supported. You will not be able to set your user status."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_couldSetUserStatus_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setUserStatus ();

        //  QCOMPARE (model.errorMessage (),
            _("Could not set user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_emojisNotSupported_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorEmojisNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        //  QCOMPARE (model.errorMessage (),
            _("Emojis feature is not supported. Some user status functionality may not work."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_couldNotClearMessage_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotClearUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.clearUserStatus ();

        //  QCOMPARE (model.errorMessage (),
            _("Could not clear user status message. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_setUserStatus_clearErrorMessage () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        //  QVERIFY (!model.errorMessage ().isEmpty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.setUserStatus ();
        //  QVERIFY (model.errorMessage ().isEmpty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testError_clearUserStatus_clearErrorMessage () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        //  QVERIFY (!model.errorMessage ().isEmpty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.clearUserStatus ();
        //  QVERIFY (model.errorMessage ().isEmpty ());
    }
}

QTEST_GUILESS_MAIN (TestSetUserStatusDialog)
