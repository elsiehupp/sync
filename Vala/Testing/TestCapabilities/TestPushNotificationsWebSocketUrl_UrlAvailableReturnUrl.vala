

namespace Occ {
namespace Testing {

public class TestPushNotificationsWebSocketUrl_UrlAvailableReturnUrl : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestPushNotificationsWebSocketUrl_UrlAvailableReturnUrl () {
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

} // class TestPushNotificationsWebSocketUrl_UrlAvailableReturnUrl

} // namespace Testing
} // namespace Occ
