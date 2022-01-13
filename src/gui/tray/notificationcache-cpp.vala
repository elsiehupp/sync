
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
