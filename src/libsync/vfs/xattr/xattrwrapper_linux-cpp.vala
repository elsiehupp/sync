/*
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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

bool Occ.XAttrWrapper.hasNextcloudPlaceholderAttributes (QString &path) {
    const auto value = xattrGet (path.toUtf8 (), hydrateExecAttributeName);
    if (value) {
        return *value == QByteArrayLiteral (APPLICATION_EXECUTABLE);
    } else {
        return false;
    }
}

Occ.Result<void, QString> Occ.XAttrWrapper.addNextcloudPlaceholderAttributes (QString &path) {
    const auto success = xattrSet (path.toUtf8 (), hydrateExecAttributeName, APPLICATION_EXECUTABLE);
    if (!success) {
        return QStringLiteral ("Failed to set the extended attribute");
    } else {
        return {};
    }
}
