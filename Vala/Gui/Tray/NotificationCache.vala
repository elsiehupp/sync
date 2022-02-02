#pragma once


namespace Occ {

class Notification_cache {

    /***********************************************************
    ***********************************************************/
    public struct Notification {
        string title;
        string message;
    };

    /***********************************************************
    ***********************************************************/
    public bool contains (Notification notification);

    /***********************************************************
    ***********************************************************/
    public void insert (Notification notification);

    /***********************************************************
    ***********************************************************/
    public void clear ();


    /***********************************************************
    ***********************************************************/
    private uint32 calculate_key (Notification notification);

    /***********************************************************
    ***********************************************************/
    private GLib.Set<uint32> this.notifications;
}


    bool Notification_cache.contains (Notification notification) {
        return this.notifications.find (calculate_key (notification)) != this.notifications.end ();
    }

    void Notification_cache.insert (Notification notification) {
        this.notifications.insert (calculate_key (notification));
    }

    void Notification_cache.clear () {
        this.notifications.clear ();
    }

    uint32 Notification_cache.calculate_key (Notification notification) {
        return q_hash (notification.title + notification.message);
    }
    }
    