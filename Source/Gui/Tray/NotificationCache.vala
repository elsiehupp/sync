#pragma once

// #include <QSet>

namespace Occ {

class Notification_cache {

    public struct Notification {
        string title;
        string message;
    };

    public bool contains (Notification &notification);

    public void insert (Notification &notification);

    public void clear ();


    private uint calculate_key (Notification &notification);

    private QSet<uint> _notifications;
};


    bool Notification_cache.contains (Notification &notification) {
        return _notifications.find (calculate_key (notification)) != _notifications.end ();
    }

    void Notification_cache.insert (Notification &notification) {
        _notifications.insert (calculate_key (notification));
    }

    void Notification_cache.clear () {
        _notifications.clear ();
    }

    uint Notification_cache.calculate_key (Notification &notification) {
        return q_hash (notification.title + notification.message);
    }
    }
    