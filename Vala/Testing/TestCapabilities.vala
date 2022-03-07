// #include <QTest>

namespace Testing {

class TestCapabilities : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForActivitiesAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("activities");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.ACTIVITIES);

        //  QCOMPARE (activitiesPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForActivitiesNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("noactivities");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.ACTIVITIES);

        //  QCOMPARE (activitiesPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForFilesAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("files");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.FILES);

        //  QCOMPARE (filesPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForFilesNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("nofiles");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.FILES);

        //  QCOMPARE (filesPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForNotificationsAvailable_returnTrue () {
        string[] typeList;
        typeList.append ("notifications");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.NOTIFICATIONS);

        //  QCOMPARE (notificationsPushNotificationsAvailable, true);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsForNotificationsNotAvailable_returnFalse () {
        string[] typeList;
        typeList.append ("nonotifications");

        QVariantMap notifyPushMap;
        notifyPushMap["type"] = typeList;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.NOTIFICATIONS);

        //  QCOMPARE (notificationsPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsAvailable_pushNotificationsNotAvailable_returnFalse () {
        const var capabilities = Occ.Capabilities (QVariantMap ());
        const var activitiesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.ACTIVITIES);
        const var filesPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.FILES);
        const var notificationsPushNotificationsAvailable = capabilities.availablePushNotifications ().testFlag (Occ.PushNotificationType.NOTIFICATIONS);

        //  QCOMPARE (activitiesPushNotificationsAvailable, false);
        //  QCOMPARE (filesPushNotificationsAvailable, false);
        //  QCOMPARE (notificationsPushNotificationsAvailable, false);
    }


    /***********************************************************
    ***********************************************************/
    private void testPushNotificationsWebSocketUrl_urlAvailable_returnUrl () {
        string websocketUrl = "testurl";

        QVariantMap endpointsMap;
        endpointsMap["websocket"] = websocketUrl;

        QVariantMap notifyPushMap;
        notifyPushMap["endpoints"] = endpointsMap;

        QVariantMap capabilitiesMap;
        capabilitiesMap["notify_push"] = notifyPushMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);

        //  QCOMPARE (capabilities.pushNotificationsWebSocketUrl (), websocketUrl);
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatus_userStatusAvailable_returnTrue () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatus_userStatusNotAvailable_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (!capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatus_userStatusNotInCapabilites_returnFalse () {
        QVariantMap capabilitiesMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (!capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatusSupportsEmoji_supportsEmojiAvailable_returnTrue () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;
        userStatusMap["supports_emoji"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (capabilities.userStatus ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatusSupportsEmoji_supportsEmojiNotAvailable_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;
        userStatusMap["supports_emoji"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (!capabilities.userStatusSupportsEmoji ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUserStatusSupportsEmoji_supportsEmojiNotInCapabilites_returnFalse () {
        QVariantMap userStatusMap;
        userStatusMap["enabled"] = true;

        QVariantMap capabilitiesMap;
        capabilitiesMap["user_status"] = userStatusMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);

        //  QVERIFY (!capabilities.userStatusSupportsEmoji ());
    }


    /***********************************************************
    ***********************************************************/
    private void testShareDefaultPermissions_defaultSharePermissionsNotInCapabilities_returnZero () {
        QVariantMap filesSharingMap;
        filesSharingMap["api_enabled"] = false;

        QVariantMap capabilitiesMap;
        capabilitiesMap["files_sharing"] = filesSharingMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);
        const var defaultSharePermissionsNotInCapabilities = capabilities.shareDefaultPermissions ();

        //  QCOMPARE (defaultSharePermissionsNotInCapabilities, {});
    }


    /***********************************************************
    ***********************************************************/
    private void testShareDefaultPermissions_defaultSharePermissionsAvailable_returnPermissions () {
        QVariantMap filesSharingMap;
        filesSharingMap["api_enabled"] = true;
        filesSharingMap["default_permissions"] = 31;

        QVariantMap capabilitiesMap;
        capabilitiesMap["files_sharing"] = filesSharingMap;

        const Occ.Capabilities capabilities = new Occ.Capabilities (capabilitiesMap);
        const var defaultSharePermissionsAvailable = capabilities.shareDefaultPermissions ();

        //  QCOMPARE (defaultSharePermissionsAvailable, 31);
    }


    /***********************************************************
    ***********************************************************/
    private void testBulkUploadAvailable_bulkUploadAvailable_returnTrue () {
        QVariantMap bulkuploadMap;
        bulkuploadMap["bulkupload"] = "1.0";

        QVariantMap capabilitiesMap;
        capabilitiesMap["dav"] = bulkuploadMap;

        const var capabilities = Occ.Capabilities (capabilitiesMap);
        const var bulkuploadAvailable = capabilities.bulkUpload ();

        //  QCOMPARE (bulkuploadAvailable, true);
    }

} // class TestCapabilities
} // namespace Testing
