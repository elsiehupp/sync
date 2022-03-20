// #include <QTest>

namespace Occ {
namespace Testing {

public class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestContainsDoesNotContainNotificationReturnsFalse () {
        NotificationCache notification_cache;

        GLib.assert_true (!notification_cache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private TestContainsDoesContainNotificationReturnsTrue () {
        NotificationCache notification_cache;
        const NotificationCache.Notification notification = new NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);

        GLib.assert_true (notification_cache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private TestClearDoesContainNotificationClearNotifications () {
        NotificationCache notification_cache;
        const NotificationCache.Notification notification = new NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);
        notification_cache.clear ();

        GLib.assert_true (!notification_cache.contains (notification));
    }

}

} // namespace Testing
} // namespace Occ
