/*
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

This library is free software; you can redistribute it and
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later versi

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GN
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

// #include <cstring>

namespace Occ {

static const char letters[] = " WDNVCKRSMm";

template <typename Char>
void RemotePermissions.fromArray (Char *p) {
    _value = notNullMask;
    if (!p)
        return;
    while (*p) {
        if (auto res = std.strchr (letters, static_cast<char> (*p)))
            _value |= (1 << (res - letters));
        ++p;
    }
}

QByteArray RemotePermissions.toDbValue () {
    QByteArray result;
    if (isNull ())
        return result;
    result.reserve (PermissionsCount);
    for (uint i = 1; i <= PermissionsCount; ++i) {
        if (_value & (1 << i))
            result.append (letters[i]);
    }
    if (result.isEmpty ()) {
        // Make sure it is not empty so we can differentiate null and empty permissions
        result.append (' ');
    }
    return result;
}

QString RemotePermissions.toString () {
    return QString.fromUtf8 (toDbValue ());
}

RemotePermissions RemotePermissions.fromDbValue (QByteArray &value) {
    if (value.isEmpty ())
        return {};
    RemotePermissions perm;
    perm.fromArray (value.constData ());
    return perm;
}

RemotePermissions RemotePermissions.fromServerString (QString &value) {
    RemotePermissions perm;
    perm.fromArray (value.utf16 ());
    return perm;
}

} // namespace Occ
