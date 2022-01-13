#pragma once

// #include <QSet>

namespace OCC {

class NotificationCache {
public:
    struct Notification {
        QString title;
        QString message;
    };

    bool contains (Notification &notification) const;

    void insert (Notification &notification);

    void clear ();

private:
    uint calculateKey (Notification &notification) const;

    QSet<uint> _notifications;
};
}
