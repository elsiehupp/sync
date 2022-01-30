// #include <QTest>

class TestNotificationCache : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testContains_doesNotContainNotification_returnsFalse () {
        Occ.NotificationCache notificationCache;

        QVERIFY (!notificationCache.contains ({ "Title", { "Message" } }));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testContains_doesContainNotification_returnTrue () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification { "Title", "message" };

        notificationCache.insert (notification);

        QVERIFY (notificationCache.contains (notification));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testClear_doesContainNotification_clearNotifications () {
        Occ.NotificationCache notificationCache;
        const Occ.NotificationCache.Notification notification { "Title", "message" };

        notificationCache.insert (notification);
        notificationCache.clear ();

        QVERIFY (!notificationCache.contains (notification));
    }
};

QTEST_GUILESS_MAIN (TestNotificationCache)
