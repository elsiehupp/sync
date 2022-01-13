/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QPointer>

namespace Occ {


class OcsUserStatusConnector : UserStatusConnector {
public:
    OcsUserStatusConnector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetchUserStatus () override;

    void fetchPredefinedStatuses () override;

    void setUserStatus (UserStatus &userStatus) override;

    void clearMessage () override;

    UserStatus userStatus () const override;

private:
    void onUserStatusFetched (QJsonDocument &json, int statusCode);
    void onPredefinedStatusesFetched (QJsonDocument &json, int statusCode);
    void onUserStatusOnlineStatusSet (QJsonDocument &json, int statusCode);
    void onUserStatusMessageSet (QJsonDocument &json, int statusCode);
    void onMessageCleared (QJsonDocument &json, int statusCode);

    void logResponse (string &message, QJsonDocument &json, int statusCode);
    void startFetchUserStatusJob ();
    void startFetchPredefinedStatuses ();
    void setUserStatusOnlineStatus (UserStatus.OnlineStatus onlineStatus);
    void setUserStatusMessage (UserStatus &userStatus);
    void setUserStatusMessagePredefined (UserStatus &userStatus);
    void setUserStatusMessageCustom (UserStatus &userStatus);

    AccountPtr _account;

    bool _userStatusSupported = false;
    bool _userStatusEmojisSupported = false;

    QPointer<JsonApiJob> _clearMessageJob {};
    QPointer<JsonApiJob> _setMessageJob {};
    QPointer<JsonApiJob> _setOnlineStatusJob {};
    QPointer<JsonApiJob> _getPredefinedStausesJob {};
    QPointer<JsonApiJob> _getUserStatusJob {};

    UserStatus _userStatus;
};
}







/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <networkjobs.h>

// #include <QDateTime>
// #include <QtGlobal>
// #include <QJsonDocument>
// #include <QJsonValue>
// #include <QLoggingCategory>
// #include <string>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <qdatetime.h>
// #include <qjsonarray.h>
// #include <qjsonobject.h>
// #include <qloggingcategory.h>

namespace {

    Q_LOGGING_CATEGORY (lcOcsUserStatusConnector, "nextcloud.gui.ocsuserstatusconnector", QtInfoMsg)
    
    Occ.UserStatus.OnlineStatus stringToUserOnlineStatus (string &status) {
        // it needs to match the Status enum
        const QHash<string, Occ.UserStatus.OnlineStatus> preDefinedStatus { { "online", Occ.UserStatus.OnlineStatus.Online }, { "dnd", Occ.UserStatus.OnlineStatus.DoNotDisturb }, { "away", Occ.UserStatus.OnlineStatus.Away }, { "offline", Occ.UserStatus.OnlineStatus.Offline }, { "invisible", Occ.UserStatus.OnlineStatus.Invisible }
        };
    
        // api should return invisible, dnd,... toLower () it is to make sure
        // it matches _preDefinedStatus, otherwise the default is online (0)
        return preDefinedStatus.value (status.toLower (), Occ.UserStatus.OnlineStatus.Online);
    }
    
    string onlineStatusToString (Occ.UserStatus.OnlineStatus status) {
        switch (status) {
        case Occ.UserStatus.OnlineStatus.Online:
            return QStringLiteral ("online");
        case Occ.UserStatus.OnlineStatus.DoNotDisturb:
            return QStringLiteral ("dnd");
        case Occ.UserStatus.OnlineStatus.Away:
            return QStringLiteral ("offline");
        case Occ.UserStatus.OnlineStatus.Offline:
            return QStringLiteral ("offline");
        case Occ.UserStatus.OnlineStatus.Invisible:
            return QStringLiteral ("invisible");
        }
        return QStringLiteral ("online");
    }
    
    Occ.Optional<Occ.ClearAt> jsonExtractClearAt (QJsonObject jsonObject) {
        Occ.Optional<Occ.ClearAt> clearAt {};
        if (jsonObject.contains ("clearAt") && !jsonObject.value ("clearAt").isNull ()) {
            Occ.ClearAt clearAtValue;
            clearAtValue._type = Occ.ClearAtType.Timestamp;
            clearAtValue._timestamp = jsonObject.value ("clearAt").toInt ();
            clearAt = clearAtValue;
        }
        return clearAt;
    }
    
    Occ.UserStatus jsonExtractUserStatus (QJsonObject json) {
        const auto clearAt = jsonExtractClearAt (json);
    
        const Occ.UserStatus userStatus (json.value ("messageId").toString (),
            json.value ("message").toString ().trimmed (),
            json.value ("icon").toString ().trimmed (), stringToUserOnlineStatus (json.value ("status").toString ()),
            json.value ("messageIsPredefined").toBool (false), clearAt);
    
        return userStatus;
    }
    
    Occ.UserStatus jsonToUserStatus (QJsonDocument &json) { { QJsonObject d { "icon", "" }, { "message", "" }, { "status", "online" }, { "messageIsPredefined", "false" },
            { "statusIsUserDefined", "false" }
        };
        const auto retrievedData = json.object ().value ("ocs").toObject ().value ("data").toObject (defaultValues);
        return jsonExtractUserStatus (retrievedData);
    }
    
    uint64 clearAtEndOfToTimestamp (Occ.ClearAt &clearAt) {
        Q_ASSERT (clearAt._type == Occ.ClearAtType.EndOf);
    
        if (clearAt._endof == "day") {
            return QDate.currentDate ().addDays (1).startOfDay ().toTime_t ();
        } else if (clearAt._endof == "week") {
            const auto days = Qt.Sunday - QDate.currentDate ().dayOfWeek ();
            return QDate.currentDate ().addDays (days + 1).startOfDay ().toTime_t ();
        }
        qCWarning (lcOcsUserStatusConnector) << "Can not handle clear at endof day type" << clearAt._endof;
        return QDateTime.currentDateTime ().toTime_t ();
    }
    
    uint64 clearAtPeriodToTimestamp (Occ.ClearAt &clearAt) {
        return QDateTime.currentDateTime ().addSecs (clearAt._period).toTime_t ();
    }
    
    uint64 clearAtToTimestamp (Occ.ClearAt &clearAt) {
        switch (clearAt._type) {
        case Occ.ClearAtType.Period : {
            return clearAtPeriodToTimestamp (clearAt);
        }
    
        case Occ.ClearAtType.EndOf : {
            return clearAtEndOfToTimestamp (clearAt);
        }
    
        case Occ.ClearAtType.Timestamp : {
            return clearAt._timestamp;
        }
        }
    
        return 0;
    }
    
    uint64 clearAtToTimestamp (Occ.Optional<Occ.ClearAt> &clearAt) {
        if (clearAt) {
            return clearAtToTimestamp (*clearAt);
        }
        return 0;
    }
    
    Occ.Optional<Occ.ClearAt> jsonToClearAt (QJsonObject jsonObject) {
        Occ.Optional<Occ.ClearAt> clearAt;
    
        if (jsonObject.value ("clearAt").isObject () && !jsonObject.value ("clearAt").isNull ()) {
            Occ.ClearAt clearAtValue;
            const auto clearAtObject = jsonObject.value ("clearAt").toObject ();
            const auto typeValue = clearAtObject.value ("type").toString ("period");
            if (typeValue == "period") {
                const auto timeValue = clearAtObject.value ("time").toInt (0);
                clearAtValue._type = Occ.ClearAtType.Period;
                clearAtValue._period = timeValue;
            } else if (typeValue == "end-of") {
                const auto timeValue = clearAtObject.value ("time").toString ("day");
                clearAtValue._type = Occ.ClearAtType.EndOf;
                clearAtValue._endof = timeValue;
            } else {
                qCWarning (lcOcsUserStatusConnector) << "Can not handle clear type value" << typeValue;
            }
            clearAt = clearAtValue;
        }
    
        return clearAt;
    }
    
    Occ.UserStatus jsonToUserStatus (QJsonObject jsonObject) {
        const auto clearAt = jsonToClearAt (jsonObject);
    
        Occ.UserStatus userStatus (
            jsonObject.value ("id").toString ("no-id"),
            jsonObject.value ("message").toString ("No message"),
            jsonObject.value ("icon").toString ("no-icon"),
            Occ.UserStatus.OnlineStatus.Online,
            true,
            clearAt);
    
        return userStatus;
    }
    
    std.vector<Occ.UserStatus> jsonToPredefinedStatuses (QJsonArray jsonDataArray) {
        std.vector<Occ.UserStatus> statuses;
        for (auto &jsonEntry : jsonDataArray) {
            Q_ASSERT (jsonEntry.isObject ());
            if (!jsonEntry.isObject ()) {
                continue;
            }
            statuses.push_back (jsonToUserStatus (jsonEntry.toObject ()));
        }
    
        return statuses;
    }
    
    const string baseUrl ("/ocs/v2.php/apps/user_status/api/v1");
    const string userStatusBaseUrl = baseUrl + QStringLiteral ("/user_status");
    }
    
    namespace Occ {
    
    OcsUserStatusConnector.OcsUserStatusConnector (AccountPtr account, GLib.Object *parent)
        : UserStatusConnector (parent)
        , _account (account) {
        Q_ASSERT (_account);
        _userStatusSupported = _account.capabilities ().userStatus ();
        _userStatusEmojisSupported = _account.capabilities ().userStatusSupportsEmoji ();
    }
    
    void OcsUserStatusConnector.fetchUserStatus () {
        qCDebug (lcOcsUserStatusConnector) << "Try to fetch user status";
    
        if (!_userStatusSupported) {
            qCDebug (lcOcsUserStatusConnector) << "User status not supported";
            emit error (Error.UserStatusNotSupported);
            return;
        }
    
        startFetchUserStatusJob ();
    }
    
    void OcsUserStatusConnector.startFetchUserStatusJob () {
        if (_getUserStatusJob) {
            qCDebug (lcOcsUserStatusConnector) << "Get user status job is already running.";
            return;
        }
    
        _getUserStatusJob = new JsonApiJob (_account, userStatusBaseUrl, this);
        connect (_getUserStatusJob, &JsonApiJob.jsonReceived, this, &OcsUserStatusConnector.onUserStatusFetched);
        _getUserStatusJob.start ();
    }
    
    void OcsUserStatusConnector.onUserStatusFetched (QJsonDocument &json, int statusCode) {
        logResponse ("user status fetched", json, statusCode);
    
        if (statusCode != 200) {
            qCInfo (lcOcsUserStatusConnector) << "Slot fetch UserStatus finished with status code" << statusCode;
            emit error (Error.CouldNotFetchUserStatus);
            return;
        }
    
        _userStatus = jsonToUserStatus (json);
        emit userStatusFetched (_userStatus);
    }
    
    void OcsUserStatusConnector.startFetchPredefinedStatuses () {
        if (_getPredefinedStausesJob) {
            qCDebug (lcOcsUserStatusConnector) << "Get predefined statuses job is already running";
            return;
        }
    
        _getPredefinedStausesJob = new JsonApiJob (_account,
            baseUrl + QStringLiteral ("/predefined_statuses"), this);
        connect (_getPredefinedStausesJob, &JsonApiJob.jsonReceived, this,
            &OcsUserStatusConnector.onPredefinedStatusesFetched);
        _getPredefinedStausesJob.start ();
    }
    
    void OcsUserStatusConnector.fetchPredefinedStatuses () {
        if (!_userStatusSupported) {
            emit error (Error.UserStatusNotSupported);
            return;
        }
        startFetchPredefinedStatuses ();
    }
    
    void OcsUserStatusConnector.onPredefinedStatusesFetched (QJsonDocument &json, int statusCode) {
        logResponse ("predefined statuses", json, statusCode);
    
        if (statusCode != 200) {
            qCInfo (lcOcsUserStatusConnector) << "Slot predefined user statuses finished with status code" << statusCode;
            emit error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        const auto jsonData = json.object ().value ("ocs").toObject ().value ("data");
        Q_ASSERT (jsonData.isArray ());
        if (!jsonData.isArray ()) {
            return;
        }
        const auto statuses = jsonToPredefinedStatuses (jsonData.toArray ());
        emit predefinedStatusesFetched (statuses);
    }
    
    void OcsUserStatusConnector.logResponse (string &message, QJsonDocument &json, int statusCode) {
        qCDebug (lcOcsUserStatusConnector) << "Response from:" << message << "Status:" << statusCode << "Json:" << json;
    }
    
    void OcsUserStatusConnector.setUserStatusOnlineStatus (UserStatus.OnlineStatus onlineStatus) {
        _setOnlineStatusJob = new JsonApiJob (_account,
            userStatusBaseUrl + QStringLiteral ("/status"), this);
        _setOnlineStatusJob.setVerb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject dataObject;
        dataObject.insert ("statusType", onlineStatusToString (onlineStatus));
        QJsonDocument body;
        body.setObject (dataObject);
        _setOnlineStatusJob.setBody (body);
        connect (_setOnlineStatusJob, &JsonApiJob.jsonReceived, this, &OcsUserStatusConnector.onUserStatusOnlineStatusSet);
        _setOnlineStatusJob.start ();
    }
    
    void OcsUserStatusConnector.setUserStatusMessagePredefined (UserStatus &userStatus) {
        Q_ASSERT (userStatus.messagePredefined ());
        if (!userStatus.messagePredefined ()) {
            return;
        }
    
        _setMessageJob = new JsonApiJob (_account, userStatusBaseUrl + QStringLiteral ("/message/predefined"), this);
        _setMessageJob.setVerb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject dataObject;
        dataObject.insert ("messageId", userStatus.id ());
        if (userStatus.clearAt ()) {
            dataObject.insert ("clearAt", static_cast<int> (clearAtToTimestamp (userStatus.clearAt ())));
        } else {
            dataObject.insert ("clearAt", QJsonValue ());
        }
        QJsonDocument body;
        body.setObject (dataObject);
        _setMessageJob.setBody (body);
        connect (_setMessageJob, &JsonApiJob.jsonReceived, this, &OcsUserStatusConnector.onUserStatusMessageSet);
        _setMessageJob.start ();
    }
    
    void OcsUserStatusConnector.setUserStatusMessageCustom (UserStatus &userStatus) {
        Q_ASSERT (!userStatus.messagePredefined ());
        if (userStatus.messagePredefined ()) {
            return;
        }
    
        if (!_userStatusEmojisSupported) {
            emit error (Error.EmojisNotSupported);
            return;
        }
        _setMessageJob = new JsonApiJob (_account, userStatusBaseUrl + QStringLiteral ("/message/custom"), this);
        _setMessageJob.setVerb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject dataObject;
        dataObject.insert ("statusIcon", userStatus.icon ());
        dataObject.insert ("message", userStatus.message ());
        const auto clearAt = userStatus.clearAt ();
        if (clearAt) {
            dataObject.insert ("clearAt", static_cast<int> (clearAtToTimestamp (*clearAt)));
        } else {
            dataObject.insert ("clearAt", QJsonValue ());
        }
        QJsonDocument body;
        body.setObject (dataObject);
        _setMessageJob.setBody (body);
        connect (_setMessageJob, &JsonApiJob.jsonReceived, this, &OcsUserStatusConnector.onUserStatusMessageSet);
        _setMessageJob.start ();
    }
    
    void OcsUserStatusConnector.setUserStatusMessage (UserStatus &userStatus) {
        if (userStatus.messagePredefined ()) {
            setUserStatusMessagePredefined (userStatus);
            return;
        }
        setUserStatusMessageCustom (userStatus);
    }
    
    void OcsUserStatusConnector.setUserStatus (UserStatus &userStatus) {
        if (!_userStatusSupported) {
            emit error (Error.UserStatusNotSupported);
            return;
        }
    
        if (_setOnlineStatusJob || _setMessageJob) {
            qCDebug (lcOcsUserStatusConnector) << "Set online status job or set message job are already running.";
            return;
        }
    
        setUserStatusOnlineStatus (userStatus.state ());
        setUserStatusMessage (userStatus);
    }
    
    void OcsUserStatusConnector.onUserStatusOnlineStatusSet (QJsonDocument &json, int statusCode) {
        logResponse ("Online status set", json, statusCode);
    
        if (statusCode != 200) {
            emit error (Error.CouldNotSetUserStatus);
            return;
        }
    }
    
    void OcsUserStatusConnector.onUserStatusMessageSet (QJsonDocument &json, int statusCode) {
        logResponse ("Message set", json, statusCode);
    
        if (statusCode != 200) {
            emit error (Error.CouldNotSetUserStatus);
            return;
        }
    
        // We fetch the user status again because json does not contain
        // the new message when user status was set from a predefined
        // message
        fetchUserStatus ();
    
        emit userStatusSet ();
    }
    
    void OcsUserStatusConnector.clearMessage () {
        _clearMessageJob = new JsonApiJob (_account, userStatusBaseUrl + QStringLiteral ("/message"));
        _clearMessageJob.setVerb (JsonApiJob.Verb.Delete);
        connect (_clearMessageJob, &JsonApiJob.jsonReceived, this, &OcsUserStatusConnector.onMessageCleared);
        _clearMessageJob.start ();
    }
    
    UserStatus OcsUserStatusConnector.userStatus () {
        return _userStatus;
    }
    
    void OcsUserStatusConnector.onMessageCleared (QJsonDocument &json, int statusCode) {
        logResponse ("Message cleared", json, statusCode);
    
        if (statusCode != 200) {
            emit error (Error.CouldNotClearMessage);
            return;
        }
    
        _userStatus = {};
        emit messageCleared ();
    }
    }
    