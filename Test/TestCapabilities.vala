// #include <QTest>

class TestCapabilities : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForActivitiesAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("activities");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Activities);

        QCOMPARE (activitiesPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForActivitiesNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("noactivities");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Activities);

        QCOMPARE (activitiesPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForFilesAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("files");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Files);

        QCOMPARE (filesPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForFilesNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("nofiles");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Files);

        QCOMPARE (filesPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForNotificationsAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("notifications");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Notifications);

        QCOMPARE (notificationsPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsForNotificationsNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("nonotifications");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Notifications);

        QCOMPARE (notificationsPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsAvailable_pushNotificationsNotAvailable_returnFalse () {
        const var &capabilities = Occ.Capabilities (QVariantMap ());
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Activities);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Files);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.Notifications);

        QCOMPARE (activitiesPushNotificationsAvailable, false);
        QCOMPARE (filesPushNotificationsAvailable, false);
        QCOMPARE (notificationsPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPushNotificationsWebSocketUrl_urlAvailable_returnUrl () {
        string websocketUrl ("testurl");

        QVariantMap endpointsMap;
        endpointsMap["websocket"] = websocketUrl;

        QVariantMap notifyPushMap;
        notifyPushMap["endpoints"] = endpointsMap;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);

        QCOMPARE (capabilities.pushNotificationsWebSocketUrl (), websocketUrl);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatus_userStatusAvailable_returnTrue () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatus_userStatusNotAvailable_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (!capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatus_userStatusNotInCapabilites_returnFalse () {
        QVariantMap capabilitiesMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (!capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatusSupportsEmoji_supportsEmojiAvailable_returnTrue () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;
        userStatusMap["supports_emoji"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatusSupportsEmoji_supportsEmojiNotAvailable_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;
        userStatusMap["supports_emoji"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (!capabilities.userStatusSupportsEmoji ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUserStatusSupportsEmoji_supportsEmojiNotInCapabilites_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities (capabilitiesMap);

        QVERIFY (!capabilities.userStatusSupportsEmoji ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testShareDefaultPermissions_defaultSharePermissionsNotInCapabilities_returnZero () {
        QVariantMap filesSharingMap;
        filesSharingMap["api_enabled"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["files_sharing"] = filesSharingMap;

        const Occ.Capabilities capabilities (capabilitiesMap);
        const var defaultSharePermissionsNotInCapabilities = capabilities.shareDefaultPermissions ();

        QCOMPARE (defaultSharePermissionsNotInCapabilities, {});
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testShareDefaultPermissions_defaultSharePermissionsAvailable_returnPermissions () {
        QVariantMap filesSharingMap;
        filesSharingMap["api_enabled"] = true;
        filesSharingMap["default_permissions"] = 31;

        QVariantMap capabilitiesMap;
        capabilitiesMap["files_sharing"] = filesSharingMap;

        const Occ.Capabilities capabilities (capabilitiesMap);
        const var defaultSharePermissionsAvailable = capabilities.shareDefaultPermissions ();

        QCOMPARE (defaultSharePermissionsAvailable, 31);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testBulkUploadAvailable_bulkUploadAvailable_returnTrue () {
        QVariantMap bulkuploadMap;
        bulkuploadMap["bulkupload"] = "1.0";

        QVariantMap capabilitiesMap;
        capabilitiesMap["dav"] = bulkuploadMap;

        const var &capabilities = Occ.Capabilities (capabilitiesMap);
        const var bulkuploadAvailable = capabilities.bulkUpload ();

        QCOMPARE (bulkuploadAvailable, true);
    }
};

QTEST_GUILESS_MAIN (TestCapabilities)
#include "testcapabilities.moc"
