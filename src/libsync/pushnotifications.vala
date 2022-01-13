/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QWebSocket>
// #include <QTimer>

namespace Occ {


class PushNotifications : GLib.Object {

public:
    PushNotifications (Account *account, GLib.Object *parent = nullptr);

    ~PushNotifications () override;

    /***********************************************************
     * Setup push notifications
     *
     * This method needs to be called before push notifications can be used.
     */
    void setup ();

    /***********************************************************
     * Set the interval for reconnection attempts
     *
     * @param interval Interval in milliseconds.
     */
    void setReconnectTimerInterval (uint32_t interval);

    /***********************************************************
     * Indicates if push notifications ready to use
     *
     * Ready to use means connected and authenticated.
     */
    bool isReady ();

    /***********************************************************
     * Set the interval in which the websocket will ping the server if it is still alive.
     *
     * If the websocket does not respond in timeoutInterval, the connection will be terminated.
     *
     * @param interval Interval in milliseconds.
     */
    void setPingInterval (int interval);

signals:
    /***********************************************************
     * Will be emitted after a successful connection and authentication
     */
    void ready ();

    /***********************************************************
     * Will be emitted if files on the server changed
     */
    void filesChanged (Account *account);

    /***********************************************************
     * Will be emitted if activities have been changed on the server
     */
    void activitiesChanged (Account *account);

    /***********************************************************
     * Will be emitted if notifications have been changed on the server
     */
    void notificationsChanged (Account *account);

    /***********************************************************
     * Will be emitted if push notifications are unable to authenticate
     *
     * It's save to call #PushNotifications.setup () after this signal has been emitted.
     */
    void authenticationFailed ();

    /***********************************************************
     * Will be emitted if push notifications are unable to connect or the connection timed out
     *
     * It's save to call #PushNotifications.setup () after this signal has been emitted.
     */
    void connectionLost ();

private slots:
    void onWebSocketConnected ();
    void onWebSocketDisconnected ();
    void onWebSocketTextMessageReceived (string &message);
    void onWebSocketError (QAbstractSocket.SocketError error);
    void onWebSocketSslErrors (QList<QSslError> &errors);
    void onWebSocketPongReceived (uint64 elapsedTime, QByteArray &payload);
    void onPingTimedOut ();

private:
    void openWebSocket ();
    void reconnectToWebSocket ();
    void closeWebSocket ();
    void authenticateOnWebSocket ();
    bool tryReconnectToWebSocket ();
    void initReconnectTimer ();
    void pingWebSocketServer ();
    void startPingTimer ();
    void startPingTimedOutTimer ();

    void handleAuthenticated ();
    void handleNotifyFile ();
    void handleInvalidCredentials ();
    void handleNotifyNotification ();
    void handleNotifyActivity ();

    void emitFilesChanged ();
    void emitNotificationsChanged ();
    void emitActivitiesChanged ();

    Account *_account = nullptr;
    QWebSocket *_webSocket;
    uint8_t _failedAuthenticationAttemptsCount = 0;
    QTimer *_reconnectTimer = nullptr;
    uint32_t _reconnectTimerInterval = 20 * 1000;
    bool _isReady = false;

    QTimer _pingTimer;
    QTimer _pingTimedOutTimer;
    bool _pongReceivedFromWebSocketServer = false;
};
}
