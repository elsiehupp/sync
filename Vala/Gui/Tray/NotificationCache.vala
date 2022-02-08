
namespace Occ {
namespace Ui {

class NotificationCache {

    /***********************************************************
    ***********************************************************/
    public struct Notification {
        string title;
        string message;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Set<uint32> notifications;


    /***********************************************************
    ***********************************************************/
    public bool contains (Notification notification) {
        return this.notifications.find (calculate_key (notification)) != this.notifications.end ();
    }


    /***********************************************************
    ***********************************************************/
    public void insert (Notification notification) {
        this.notifications.insert (calculate_key (notification));
    }


    /***********************************************************
    ***********************************************************/
    public void clear () {
        this.notifications.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private uint32 calculate_key (Notification notification) {
        return q_hash (notification.title + notification.message);
    }

} // class NotificationCache

} // namespace Ui
} // namespace Occ
