// #include <QTest>

namespace Testing {

public class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_contains_does_not_contain_notification_returns_false () {
        Occ.NotificationCache notification_cache;

        GLib.assert_true (!notification_cache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private void test_contains_does_contain_notification_return_true () {
        Occ.NotificationCache notification_cache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);

        GLib.assert_true (notification_cache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private void test_clear_does_contain_notification_clear_cotifications () {
        Occ.NotificationCache notification_cache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notification_cache.insert (notification);
        notification_cache.clear ();

        GLib.assert_true (!notification_cache.contains (notification));
    }

}
}
