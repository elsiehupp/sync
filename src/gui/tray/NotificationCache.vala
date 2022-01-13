#pragma once

// #include <QSet>

namespace Occ {

class NotificationCache {
public:
    struct Notification {
        string title;
        string message;
    };

    bool contains (Notification &notification) const;

    void insert (Notification &notification);

    void clear ();

private:
    uint calculateKey (Notification &notification) const;

    QSet<uint> _notifications;
};
}










namespace Occ {

    bool NotificationCache.contains (Notification &notification) {
        return _notifications.find (calculateKey (notification)) != _notifications.end ();
    }
    
    void NotificationCache.insert (Notification &notification) {
        _notifications.insert (calculateKey (notification));
    }
    
    void NotificationCache.clear () {
        _notifications.clear ();
    }
    
    uint NotificationCache.calculateKey (Notification &notification) {
        return qHash (notification.title + notification.message);
    }
    }
    