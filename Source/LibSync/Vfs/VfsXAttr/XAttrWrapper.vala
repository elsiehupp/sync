/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #include <sys/xattr.h>

// #pragma once

// #include <string>

namespace Occ {

namespace XAttr_wrapper {

bool has_nextcloud_placeholder_attributes (string &path);
Result<void, string> add_nextcloud_placeholder_attributes (string &path);

}

} // namespace Occ

namespace {

constexpr auto hydrate_exec_attribute_name = "user.nextcloud.hydrate_exec";

Occ.Optional<QByteArray> xattr_get (QByteArray &path, QByteArray &name) {
    constexpr auto buffer_size = 256;
    QByteArray result;
    result.resize (buffer_size);
    const auto count = getxattr (path.const_data (), name.const_data (), result.data (), buffer_size);
    if (count >= 0) {
        result.resize (static_cast<int> (count) - 1);
        return result;
    } else {
        return {};
    }
}

bool xattr_set (QByteArray &path, QByteArray &name, QByteArray &value) {
    const auto return_code = setxattr (path.const_data (), name.const_data (), value.const_data (), value.size () + 1, 0);
    return return_code == 0;
}

}

bool Occ.XAttr_wrapper.has_nextcloud_placeholder_attributes (string &path) {
    const auto value = xattr_get (path.to_utf8 (), hydrate_exec_attribute_name);
    if (value) {
        return *value == QByteArrayLiteral (APPLICATION_EXECUTABLE);
    } else {
        return false;
    }
}

Occ.Result<void, string> Occ.XAttr_wrapper.add_nextcloud_placeholder_attributes (string &path) {
    const auto success = xattr_set (path.to_utf8 (), hydrate_exec_attribute_name, APPLICATION_EXECUTABLE);
    if (!success) {
        return QStringLiteral ("Failed to set the extended attribute");
    } else {
        return {};
    }
}
