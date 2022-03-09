// #include <QTest>

namespace Testing {

class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testContains_doesNotContainNotification_returnsFalse () {
        Occ.NotificationCache notificationCache;

        GLib.assert_true (!notificationCache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private void testContains_doesContainNotification_return_true () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notificationCache.insert (notification);

        GLib.assert_true (notificationCache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private void testClear_doesContainNotification_clearNotifications () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notificationCache.insert (notification);
        notificationCache.clear ();

        GLib.assert_true (!notificationCache.contains (notification));
    }

}
}
