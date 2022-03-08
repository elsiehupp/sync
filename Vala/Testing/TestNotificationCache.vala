// #include <QTest>

namespace Testing {

class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testContains_doesNotContainNotification_returnsFalse () {
        Occ.NotificationCache notificationCache;

        //  QVERIFY (!notificationCache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private void testContains_doesContainNotification_returnTrue () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notificationCache.insert (notification);

        //  QVERIFY (notificationCache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private void testClear_doesContainNotification_clearNotifications () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification = new Occ.NotificationCache.Notification ("Title", "message");

        notificationCache.insert (notification);
        notificationCache.clear ();

        //  QVERIFY (!notificationCache.contains (notification));
    }

}
}
