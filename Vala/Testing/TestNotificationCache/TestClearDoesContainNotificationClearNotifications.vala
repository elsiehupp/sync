namespace Occ {
namespace Testing {

public class TestClearDoesContainNotificationClearNotifications : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearDoesContainNotificationClearNotifications () {
        NotificationCache notification_cache;
        const NotificationCache.Notification notification = new NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);
        notification_cache.clear ();

        GLib.assert_true (!notification_cache.contains (notification));
    }

} // class TestClearDoesContainNotificationClearNotifications

} // namespace Testing
} // namespace Occ
