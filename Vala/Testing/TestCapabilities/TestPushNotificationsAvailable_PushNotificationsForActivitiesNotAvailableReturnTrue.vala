

namespace Occ {
namespace Testing {

public class TestPushNotificationsAvailable_PushNotificationsForActivitiesNotAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestPushNotificationsAvailable_PushNotificationsForActivitiesNotAvailableReturnTrue () {
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

} // class TestPushNotificationsAvailable_PushNotificationsForActivitiesNotAvailableReturnTrue

} // namespace Testing
} // namespace Occ
