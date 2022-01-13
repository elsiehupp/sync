#ifndef NOTIFICATIONHANDLER_H
const int NOTIFICATIONHANDLER_H

// #include <QtCore>


namespace Occ {

class ServerNotificationHandler : GLib.Object {
public:
    ServerNotificationHandler (AccountState *accountState, GLib.Object *parent = nullptr);

signals:
    void newNotificationList (ActivityList);

public slots:
    void slotFetchNotifications ();

private slots:
    void slotNotificationsReceived (QJsonDocument &json, int statusCode);
    void slotEtagResponseHeaderReceived (QByteArray &value, int statusCode);
    void slotAllowDesktopNotificationsChanged (bool isAllowed);

private:
    QPointer<JsonApiJob> _notificationJob;
    AccountState *_accountState;
};
}
