/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #include <sys/xattr.h>

Q_LOGGING_CATEGORY (lcXAttrWrapper, "nextcloud.sync.vfs.xattr.wrapper", QtInfoMsg)

namespace {
constexpr auto hydrateExecAttributeName = "user.nextcloud.hydrate_exec";

Occ.Optional<QByteArray> xattrGet (QByteArray &path, QByteArray &name) {
    constexpr auto bufferSize = 256;
    QByteArray result;
    result.resize (bufferSize);
    const auto count = getxattr (path.constData (), name.constData (), result.data (), bufferSize);
    if (count >= 0) {
        result.resize (static_cast<int> (count) - 1);
        return result;
    } else {
        return {};
    }
}

bool xattrSet (QByteArray &path, QByteArray &name, QByteArray &value) {
    const auto returnCode = setxattr (path.constData (), name.constData (), value.constData (), value.size () + 1, 0);
    return returnCode == 0;
}

}

bool Occ.XAttrWrapper.hasNextcloudPlaceholderAttributes (string &path) {
    const auto value = xattrGet (path.toUtf8 (), hydrateExecAttributeName);
    if (value) {
        return *value == QByteArrayLiteral (APPLICATION_EXECUTABLE);
    } else {
        return false;
    }
}

Occ.Result<void, string> Occ.XAttrWrapper.addNextcloudPlaceholderAttributes (string &path) {
    const auto success = xattrSet (path.toUtf8 (), hydrateExecAttributeName, APPLICATION_EXECUTABLE);
    if (!success) {
        return QStringLiteral ("Failed to set the extended attribute");
    } else {
        return {};
    }
}
