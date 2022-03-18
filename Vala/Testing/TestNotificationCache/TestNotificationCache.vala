// #include <QTest>

namespace Occ {
namespace Testing {

public class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_contains_does_not_contain_notification_returns_false () {
        NotificationCache notification_cache;

        GLib.assert_true (!notification_cache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private void test_contains_does_contain_notification_return_true () {
        NotificationCache notification_cache;
        const NotificationCache.Notification notification = new NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);

        GLib.assert_true (notification_cache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_does_contain_notification_clear_cotifications () {
        NotificationCache notification_cache;
        const NotificationCache.Notification notification = new NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);
        notification_cache.clear ();

        GLib.assert_true (!notification_cache.contains (notification));
    }

}

} // namespace Testing
} // namespace Occ
