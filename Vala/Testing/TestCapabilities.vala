// #include <QTest>

namespace Testing {

public class TestCapabilities : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_activities_available_return_true () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("activities");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var activities_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.ACTIVITIES);

        GLib.assert_true (activities_push_notifications_available == true);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_activities_not_available_return_false () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("noactivities");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var activities_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.ACTIVITIES);

        GLib.assert_true (activities_push_notifications_available == false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_files_available_return_true () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("files");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var files_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.FILES);

        GLib.assert_true (files_push_notifications_available == true);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_files_not_available_return_false () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("nofiles");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var files_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.FILES);

        GLib.assert_true (files_push_notifications_available == false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_notifications_available_return_true () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("notifications");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var notifications_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.NOTIFICATIONS);

        GLib.assert_true (notifications_push_notifications_available == true);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_for_notifications_not_available_return_false () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("nonotifications");

        QVariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var notifications_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.NOTIFICATIONS);

        GLib.assert_true (notifications_push_notifications_available == false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_available_push_notifications_not_available_return_false () {
        var capabilities = Capabilities (QVariantMap ());
        var activities_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.ACTIVITIES);
        var files_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.FILES);
        var notifications_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.NOTIFICATIONS);

        GLib.assert_true (activities_push_notifications_available == false);
        GLib.assert_true (files_push_notifications_available == false);
        GLib.assert_true (notifications_push_notifications_available == false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_push_notifications_web_socket_url_url_available_return_url () {
        string websocket_url = "testurl";

        QVariantMap endpoints_map;
        endpoints_map["websocket"] = websocket_url;

        QVariantMap notify_push_map;
        notify_push_map["endpoints"] = endpoints_map;

        QVariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);

        GLib.assert_true (capabilities.push_notifications_web_socket_url () == websocket_url);
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_user_status_available_return_true () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = true;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (capabilities.user_status ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_user_status_not_available_return_false () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = false;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_user_status_not_in_capabilites_return_false () {
        QVariantMap capabilities_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_supports_emoji_supports_emoji_available_return_true () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = true;
        user_status_map["supports_emoji"] = true;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (capabilities.user_status ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_supports_emoji_supports_emoji_not_available_return_false () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = true;
        user_status_map["supports_emoji"] = false;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status_supports_emoji ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_user_status_supports_emoji_supports_emoji_not_in_capabilites_return_false () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = true;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status_supports_emoji ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_share_default_permissions_default_share_permissions_not_in_capabilities_return_zero () {
        QVariantMap file_sharing_map;
        file_sharing_map["api_enabled"] = false;

        QVariantMap capabilities_map;
        capabilities_map["files_sharing"] = file_sharing_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);
        var default_share_permissions_not_in_capabilities = capabilities.share_default_permissions ();

        GLib.assert_true (default_share_permissions_not_in_capabilities == {});
    }


    /***********************************************************
    ***********************************************************/
    private void test_share_default_permissions_default_share_permissions_available_return_permissions () {
        QVariantMap file_sharing_map;
        file_sharing_map["api_enabled"] = true;
        file_sharing_map["default_permissions"] = 31;

        QVariantMap capabilities_map;
        capabilities_map["files_sharing"] = file_sharing_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);
        var default_share_permissions_available = capabilities.share_default_permissions ();

        GLib.assert_true (default_share_permissions_available == 31);
    }


    /***********************************************************
    ***********************************************************/
    private void test_bulk_upload_available_bulk_upload_available_return_true () {
        QVariantMap bulkupload_map;
        bulkupload_map["bulkupload"] = "1.0";

        QVariantMap capabilities_map;
        capabilities_map["dav"] = bulkupload_map;

        var capabilities = Capabilities (capabilities_map);
        var bulkupload_available = capabilities.bulk_upload ();

        GLib.assert_true (bulkupload_available == true);
    }

} // class TestCapabilities
} // namespace Testing
