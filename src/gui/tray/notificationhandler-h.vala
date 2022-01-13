#ifndef NOTIFICATIONHANDLER_H
#define NOTIFICATIONHANDLER_H

// #include <QtCore>

class QJsonDocument;

namespace OCC {

class ServerNotificationHandler : public QObject {
public:
    explicit ServerNotificationHandler (AccountState *accountState, QObject *parent = nullptr);

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

#endif // NOTIFICATIONHANDLER_H
