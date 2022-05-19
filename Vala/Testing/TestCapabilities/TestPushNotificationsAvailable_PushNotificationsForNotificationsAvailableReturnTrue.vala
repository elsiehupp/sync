

namespace Occ {
namespace Testing {

public class TestPushNotificationsAvailable_PushNotificationsForNotificationsAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestPushNotificationsAvailable_PushNotificationsForNotificationsAvailableReturnTrue () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("notifications");

        GLib.HashMap notify_push_map;
        notify_push_map["type"] = type_list;

        GLib.HashMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var notifications_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.NOTIFICATIONS);

        GLib.assert_true (notifications_push_notifications_available == true);
    }

} // class TestPushNotificationsAvailable_PushNotificationsForNotificationsAvailableReturnTrue

} // namespace Testing
} // namespace Occ
