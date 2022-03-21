namespace Occ {
namespace Testing {

public class TestContainsDoesNotContainNotificationReturnsFalse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestContainsDoesNotContainNotificationReturnsFalse () {
        NotificationCache notification_cache;

        GLib.assert_true (!notification_cache.contains ({ "Title", { "Message" } }));
    }

} // class TestContainsDoesNotContainNotificationReturnsFalse

} // namespace Testing
} // namespace Occ
