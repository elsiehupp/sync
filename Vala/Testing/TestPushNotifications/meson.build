srcs = files([
    'AbstractTestPushNotifications.vala',
    'CredentialsStub.vala',
    'FakeWebSocketServer.vala',
    'TestAccountWebSocketAuthenticationFailedEmitNotificationsDisabled.vala',
    'TestAccountWebSocketConnectionLostEmitNotificationsDisabled.vala',
    'TestOnWebSocketErrorConnectionLostEmitConnectionLost.vala',
    'TestOnWebSocketSslErrorSslErrorDisablePushNotifications.vala',
    'TestOnWebSocketTextMessageReceivedInvalidCredentialsMessageReconnectWebSocket.vala',
    'TestOnWebSocketTextMessageReceivedNotifyActivityMessageEmitNotification.vala',
    'TestOnWebSocketTextMessageReceivedNotifyFileMessageEmitFilesChanged.vala',
    'TestOnWebSocketTextMessageReceivedNotifyNotificationMessageEmitNotification.vala',
    'TestPingTimeoutPingTimeoutReconnect.vala',
    'TestSetUpCorrectCredentialsAuthenticateAndEmitReady.vala',
    'TestSetUpMaxConnectionAttemptsReachedDisablePushNotifications.vala',
    'TestTryReconnectCapabilitiesReportPushNotificationsAvailableReconnectForever.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk4'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)