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
    private void testCtor_fetchStatusAndPredefinedStatuses () {
        const GLib.DateTime currentDateTime (GLib.DateTime.currentDateTime ());

        const string user_statusId ("fake-identifier");
        const string user_statusMessage ("Some status");
        const string user_statusIcon ("❤");
        const Occ.UserStatus.OnlineStatus user_statusState (Occ.UserStatus.OnlineStatus.DoNotDisturb);
        const bool user_statusMessagePredefined (false);
        Occ.Optional<Occ.ClearAt> user_statusClearAt; {
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentDateTime.add_days (1).toTime_t ();
            user_statusClearAt = clearAt;
        }

        const Occ.UserStatus user_status (user_statusId, user_statusMessage,
            user_statusIcon, user_statusState, user_statusMessagePredefined, user_statusClearAt);

        var fakePredefinedStatuses = createFakePredefinedStatuses (createDateTime ());

        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        fakeDateTimeProvider.setCurrentDateTime (currentDateTime);
        fakeUserStatusJob.setFakeUserStatus (user_status);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob, std.move (fakeDateTimeProvider));

        // Was user status set correctly?
        GLib.assert_cmp (model.user_statusMessage (), user_statusMessage);
        GLib.assert_cmp (model.user_statusEmoji (), user_statusIcon);
        GLib.assert_cmp (model.onlineStatus (), user_statusState);
        GLib.assert_cmp (model.clearAt (), _("1 day"));

        // Were predefined statuses fetched correctly?
        var predefinedStatusesCount = model.predefinedStatusesCount ();
        GLib.assert_cmp (predefinedStatusesCount, fakePredefinedStatuses.size ());
        for (int i = 0; i < predefinedStatusesCount; ++i) {
            var predefinedStatus = model.predefinedStatus (i);
            GLib.assert_cmp (predefinedStatus.identifier (),
                fakePredefinedStatuses[i].identifier ());
            GLib.assert_cmp (predefinedStatus.message (),
                fakePredefinedStatuses[i].message ());
            GLib.assert_cmp (predefinedStatus.icon (),
                fakePredefinedStatuses[i].icon ());
            GLib.assert_cmp (predefinedStatus.messagePredefined (),
                fakePredefinedStatuses[i].messagePredefined ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testCtor_noStatusSet_showSensibleDefaults () {
        Occ.UserStatusSelectorModel model (null, null);

        GLib.assert_cmp (model.user_statusMessage (), "");
        GLib.assert_cmp (model.user_statusEmoji (), "😀");
        GLib.assert_cmp (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void testCtor_fetchStatusButNoStatusSet_showSensibleDefaults () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakeUserStatus ({ "", "", "",
            Occ.UserStatus.OnlineStatus.Offline, false, {} });
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.onlineStatus (), Occ.UserStatus.OnlineStatus.Online);
        GLib.assert_cmp (model.user_statusMessage (), "");
        GLib.assert_cmp (model.user_statusEmoji (), "😀");
        GLib.assert_cmp (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetOnlineStatus_emitOnlineStatusChanged () {
        const Occ.UserStatus.OnlineStatus onlineStatus (Occ.UserStatus.OnlineStatus.Invisible);
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy onlineStatusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.onlineStatusChanged);

        model.setOnlineStatus (onlineStatus);

        GLib.assert_cmp (onlineStatusChangedSpy.count (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetUserStatus_setCustomMessage_user_statusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string user_statusMessage ("Some status");
        const string user_statusIcon ("❤");
        const Occ.UserStatus.OnlineStatus user_statusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (user_statusState);
        model.setUserStatusMessage (user_statusMessage);
        model.setUserStatusEmoji (user_statusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        GLib.assert_cmp (finishedSpy.count (), 1);

        var user_statusSet = fakeUserStatusJob.user_statusSetByCallerOfSetUserStatus ();
        GLib.assert_cmp (user_statusSet.icon (), user_statusIcon);
        GLib.assert_cmp (user_statusSet.message (), user_statusMessage);
        GLib.assert_cmp (user_statusSet.state (), user_statusState);
        GLib.assert_cmp (user_statusSet.messagePredefined (), false);
        var clearAt = user_statusSet.clearAt ();
        GLib.assert_true (clearAt.is_valid ());
        GLib.assert_cmp (clearAt.type, Occ.ClearAtType.Period);
        GLib.assert_cmp (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetUserStatusMessage_predefinedStatusWasSet_user_statusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string user_statusMessage ("Some status");
        const Occ.UserStatus.OnlineStatus user_statusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (user_statusState);
        model.setUserStatusMessage (user_statusMessage);
        model.setClearAt (1);

        model.setUserStatus ();
        GLib.assert_cmp (finishedSpy.count (), 1);

        var user_statusSet = fakeUserStatusJob.user_statusSetByCallerOfSetUserStatus ();
        GLib.assert_cmp (user_statusSet.message (), user_statusMessage);
        GLib.assert_cmp (user_statusSet.state (), user_statusState);
        GLib.assert_cmp (user_statusSet.messagePredefined (), false);
        var clearAt = user_statusSet.clearAt ();
        GLib.assert_true (clearAt.is_valid ());
        GLib.assert_cmp (clearAt.type, Occ.ClearAtType.Period);
        GLib.assert_cmp (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetUserStatusEmoji_predefinedStatusWasSet_user_statusSetCorrect () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setFakePredefinedStatuses (createFakePredefinedStatuses (createDateTime ()));
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setPredefinedStatus (0);
        QSignalSpy finishedSpy (&model, &Occ.UserStatusSelectorModel.on_signal_finished);

        const string user_statusIcon ("❤");
        const Occ.UserStatus.OnlineStatus user_statusState (Occ.UserStatus.OnlineStatus.Online);

        model.setOnlineStatus (user_statusState);
        model.setUserStatusEmoji (user_statusIcon);
        model.setClearAt (1);

        model.setUserStatus ();
        GLib.assert_cmp (finishedSpy.count (), 1);

        var user_statusSet = fakeUserStatusJob.user_statusSetByCallerOfSetUserStatus ();
        GLib.assert_cmp (user_statusSet.icon (), user_statusIcon);
        GLib.assert_cmp (user_statusSet.state (), user_statusState);
        GLib.assert_cmp (user_statusSet.messagePredefined (), false);
        var clearAt = user_statusSet.clearAt ();
        GLib.assert_true (clearAt.is_valid ());
        GLib.assert_cmp (clearAt.type, Occ.ClearAtType.Period);
        GLib.assert_cmp (clearAt.period, 60 * 30);
    }


    /***********************************************************
    ***********************************************************/
    private void testSetPredefinedStatus_emitUserStatusChangedAndSetUserStatus () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
        var currentTime = createDateTime ();
        fakeDateTimeProvider.setCurrentDateTime (currentTime);
        var fakePredefinedStatuses = createFakePredefinedStatuses (currentTime);
        fakeUserStatusJob.setFakePredefinedStatuses (fakePredefinedStatuses);
        Occ.UserStatusSelectorModel model (std.move (fakeUserStatusJob),
            std.move (fakeDateTimeProvider));

        QSignalSpy user_statusChangedSpy (&model,
            &Occ.UserStatusSelectorModel.user_statusChanged);
        QSignalSpy clearAtChangedSpy (&model,
            &Occ.UserStatusSelectorModel.clearAtChanged);

        var fakePredefinedUserStatusIndex = 0;
        model.setPredefinedStatus (fakePredefinedUserStatusIndex);

        GLib.assert_cmp (user_statusChangedSpy.count (), 1);
        GLib.assert_cmp (clearAtChangedSpy.count (), 1);

        // Was user status set correctly?
        var fakePredefinedUserStatus = fakePredefinedStatuses[fakePredefinedUserStatusIndex];
        GLib.assert_cmp (model.user_statusMessage (), fakePredefinedUserStatus.message ());
        GLib.assert_cmp (model.user_statusEmoji (), fakePredefinedUserStatus.icon ());
        GLib.assert_cmp (model.onlineStatus (), fakePredefinedUserStatus.state ());
        GLib.assert_cmp (model.clearAt (), _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage0_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 0;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("Don't clear"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage1_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 1;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("30 minutes"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage2_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 2;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("1 hour"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage3_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 3;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("4 hours"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage4_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 4;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("Today"));
    }


    /***********************************************************
    ***********************************************************/
    private void testSetClear_setClearAtStage5_emitClearAtChangedAndClearAtSet () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        QSignalSpy clearAtChangedSpy (&model, &Occ.UserStatusSelectorModel.clearAtChanged);

        var clearAtIndex = 5;
        model.setClearAt (clearAtIndex);

        GLib.assert_cmp (clearAtChangedSpy.count (), 1);
        GLib.assert_cmp (model.clearAt (), _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private void testClearAtStages () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.clearAt (), _("Don't clear"));
        var clearAtValues = model.clearAtValues ();
        GLib.assert_cmp (clearAtValues.count (), 6);

        GLib.assert_cmp (clearAtValues[0], _("Don't clear"));
        GLib.assert_cmp (clearAtValues[1], _("30 minutes"));
        GLib.assert_cmp (clearAtValues[2], _("1 hour"));
        GLib.assert_cmp (clearAtValues[3], _("4 hours"));
        GLib.assert_cmp (clearAtValues[4], _("Today"));
        GLib.assert_cmp (clearAtValues[5], _("This week"));
    }


    /***********************************************************
    ***********************************************************/
    private void testClearAt_clearAtTimestamp () { {onst var currentTime = createDateTime ();
        {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_secs (30).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("Less than a minute"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_secs (60).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("1 minute"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_secs (60 * 30).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("30 minutes"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_secs (60 * 60).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("1 hour"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_secs (60 * 60 * 4).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("4 hours"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_days (1).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("1 day"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Timestamp;
            clearAt.timestamp = currentTime.add_days (7).toTime_t ();
            user_status.setClearAt (clearAt);

            var fakeDateTimeProvider = std.make_unique<FakeDateTimeProvider> ();
            fakeDateTimeProvider.setCurrentDateTime (currentTime);

            Occ.UserStatusSelectorModel model (user_status, std.move (fakeDateTimeProvider));

            GLib.assert_cmp (model.clearAt (), _("7 days"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testClearAt_clearAtEndOf () { {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.EndOf;
            clearAt.endof = "day";
            user_status.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (user_status);

            GLib.assert_cmp (model.clearAt (), _("Today"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.EndOf;
            clearAt.endof = "week";
            user_status.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (user_status);

            GLib.assert_cmp (model.clearAt (), _("This week"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testClearAt_clearAtAfterPeriod () { {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Period;
            clearAt.period = 60 * 30;
            user_status.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (user_status);

            GLib.assert_cmp (model.clearAt (), _("30 minutes"));
        }
 {
            Occ.UserStatus user_status;
            Occ.ClearAt clearAt;
            clearAt.type = Occ.ClearAtType.Period;
            clearAt.period = 60 * 60;
            user_status.setClearAt (clearAt);

            Occ.UserStatusSelectorModel model (user_status);

            GLib.assert_cmp (model.clearAt (), _("1 hour"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testClearUserStatus () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        model.clearUserStatus ();

        GLib.assert_true (fakeUserStatusJob.messageCleared ());
    }


    /***********************************************************
    ***********************************************************/
    private void testError_couldNotFetchPredefinedStatuses_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchPredefinedUserStatuses (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.errorMessage (),
            _("Could not fetch predefined statuses. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_couldNotFetchUserStatus_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotFetchUserStatus (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.errorMessage (),
            _("Could not fetch user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_user_statusNotSupported_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorUserStatusNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.errorMessage (),
            _("User status feature is not supported. You will not be able to set your user status."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_couldSetUserStatus_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.setUserStatus ();

        GLib.assert_cmp (model.errorMessage (),
            _("Could not set user status. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_emojisNotSupported_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorEmojisNotSupported (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        GLib.assert_cmp (model.errorMessage (),
            _("Emojis feature is not supported. Some user status functionality may not work."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_couldNotClearMessage_emitError () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        fakeUserStatusJob.setErrorCouldNotClearUserStatusMessage (true);
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);
        model.clearUserStatus ();

        GLib.assert_cmp (model.errorMessage (),
            _("Could not clear user status message. Make sure you are connected to the server."));
    }


    /***********************************************************
    ***********************************************************/
    private void testError_setUserStatus_clearErrorMessage () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        GLib.assert_true (!model.errorMessage ().is_empty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.setUserStatus ();
        GLib.assert_true (model.errorMessage ().is_empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void testError_clearUserStatus_clearErrorMessage () {
        var fakeUserStatusJob = std.make_shared<FakeUserStatusConnector> ();
        Occ.UserStatusSelectorModel model (fakeUserStatusJob);

        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (true);
        model.setUserStatus ();
        GLib.assert_true (!model.errorMessage ().is_empty ());
        fakeUserStatusJob.setErrorCouldNotSetUserStatusMessage (false);
        model.clearUserStatus ();
        GLib.assert_true (model.errorMessage ().is_empty ());
    }
}

QTEST_GUILESS_MAIN (TestSetUserStatusDialog)
