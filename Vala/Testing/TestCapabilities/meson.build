srcs = files([
    'TestBulkUploadAvailable_UploadAvailableReturnTrue.vala',
    'TestPushNotificationsAvailable_PushNotificationsForActivitiesAvailableReturnTrue.vala',
    'TestPushNotificationsAvailable_PushNotificationsForActivitiesNotAvailableReturnTrue.vala',
    'TestPushNotificationsAvailable_PushNotificationsForFilesAvailableReturnTrue.vala',
    'TestPushNotificationsAvailable_PushNotificationsForFilesNotAvailableReturnFalse.vala',
    'TestPushNotificationsAvailable_PushNotificationsForNotificationsAvailableReturnTrue.vala',
    'TestPushNotificationsAvailable_PushNotificationsForNotificationsNotAvailableReturnFalse.vala',
    'TestPushNotificationsAvailable_PushNotificationsPushNotificationsNotAvailableReturnFalse.vala',
    'TestPushNotificationsWebSocketUrl_UrlAvailableReturnUrl.vala',
    'TestShareDefaultPermissions_DefaultShareAvailableReturnPermissions.vala',
    'TestShareDefaultPermissions_DefaultSharePermissionsNotInCapabilitiesReturnZero.vala',
    'TestUserStatusSupportsEmoji_SupportsEmojiAvailableReturnTrue.vala',
    'TestUserStatusSupportsEmoji_SupportsEmojiNotAvailableReturnFalse.vala',
    'TestUserStatusSupportsEmoji_SupportsEmojiNotInCapabilitiesReturnFalse.vala',
    'TestUserStatus_UserStatusAvailableReturnTrue.vala',
    'TestUserStatus_UserStatusNotAvailableReturnFalse.vala',
    'TestUserStatus_UserStatusNotInCapabilitiesReturnFalse.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)