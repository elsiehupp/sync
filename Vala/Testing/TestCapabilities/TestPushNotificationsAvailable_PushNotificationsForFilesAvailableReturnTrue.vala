

namespace Occ {
namespace Testing {

public class TestPushNotificationsAvailable_PushNotificationsForFilesAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestPushNotificationsAvailable_PushNotificationsForFilesAvailableReturnTrue () {
        GLib.List<string> type_list = new GLib.List<string> ();
        type_list.append ("files");

        GLib.HashMap notify_push_map;
        notify_push_map["type"] = type_list;

        GLib.HashMap capabilities_map;
        capabilities_map["notify_push"] = notify_push_map;

        var capabilities = new LibSync.Capabilities (capabilities_map);
        var files_push_notifications_available = capabilities.available_push_notifications ().test_flag (PushNotificationType.FILES);

        GLib.assert_true (files_push_notifications_available == true);
    }

} // class TestPushNotificationsAvailable_PushNotificationsForFilesAvailableReturnTrue

} // namespace Testing
} // namespace Occ
