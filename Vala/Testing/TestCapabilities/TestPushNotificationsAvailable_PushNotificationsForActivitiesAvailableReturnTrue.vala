

namespace Occ {
namespace Testing {

public class TestPushNotificationsAvailable_PushNotificationsForActivitiesAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestPushNotificationsAvailable_PushNotificationsForActivitiesAvailableReturnTrue () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("activities");

        GLib.VariantMap notify_push_map;
        notify_push_map["type"] = type_list;

        GLib.VariantMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = Capabilities (capabilities_map);
        var activities_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.ACTIVITIES);

        GLib.assert_true (activities_push_notifications_available == true);
    }

} // class TestPushNotificationsAvailable_PushNotificationsForActivitiesAvailableReturnTrue

} // namespace Testing
} // namespace Occ
