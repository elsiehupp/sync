namespace Occ {
namespace Testing {

public class TestClearDoesContainNotificationClearNotifications : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearDoesContainNotificationClearNotifications () {
        Gui.NotificationCache notification_cache;
        Gui.NotificationCache.Notification notification = new Gui.NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);
        notification_cache = "";

        GLib.assert_true (!notification_cache.contains (notification));
    }

} // class TestClearDoesContainNotificationClearNotifications

} // namespace Testing
} // namespace Occ
