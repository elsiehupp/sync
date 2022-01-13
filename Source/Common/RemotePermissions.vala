/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <string>
// #include <QMetaType>
// #include <QDebug>

namespace Occ {

/***********************************************************
Class that store in a memory efficient way the remote permission
***********************************************************/
class RemotePermissions {
private:
    // The first bit tells if the value is set or not
    // The remaining bits correspond to know if the value is set
    uint16 _value = 0;
    static constexpr int notNullMask = 0x1;

    template <typename Char> // can be 'char' or 'ushort' if conversion from string
    void fromArray (Char *p);

public:
    enum Permissions {
        CanWrite = 1,             // W
        CanDelete = 2,            // D
        CanRename = 3,            // N
        CanMove = 4,              // V
        CanAddFile = 5,           // C
        CanAddSubDirectories = 6, // K
        CanReshare = 7,           // R
        // Note : on the server, this means SharedWithMe, but in discoveryphase.cpp we also set
        // this permission when the server reports the any "share-types"
        IsShared = 8,             // S
        IsMounted = 9,            // M
        IsMountedSub = 10,        // m (internal : set if the parent dir has IsMounted)

        // Note : when adding support for more permissions, we need to invalid the cache in the database.
        // (by setting forceRemoteDiscovery in SyncJournalDb.checkConnect)
        PermissionsCount = IsMountedSub
    };

    /// null permissions
    RemotePermissions () = default;

    /// array with one character per permission, "" is null, " " is non-null but empty
    QByteArray toDbValue ();

    /// output for display purposes, no defined format (same as toDbValue in practice)
    string toString ();

    /// read value that was written with toDbValue ()
    static RemotePermissions fromDbValue (QByteArray &);

    /// read a permissions string received from the server, never null
    static RemotePermissions fromServerString (string &);

    bool hasPermission (Permissions p) {
        return _value & (1 << static_cast<int> (p));
    }
    void setPermission (Permissions p) {
        _value |= (1 << static_cast<int> (p)) | notNullMask;
    }
    void unsetPermission (Permissions p) {
        _value &= ~ (1 << static_cast<int> (p));
    }

    bool isNull () { return ! (_value & notNullMask); }
    friend bool operator== (RemotePermissions a, RemotePermissions b) {
        return a._value == b._value;
    }
    friend bool operator!= (RemotePermissions a, RemotePermissions b) {
        return ! (a == b);
    }

    friend QDebug operator<< (QDebug &dbg, RemotePermissions p) {
        return dbg << p.toString ();
    }
};

} // namespace Occ

Q_DECLARE_METATYPE (Occ.RemotePermissions)




/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

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
    
    string RemotePermissions.toString () {
        return string.fromUtf8 (toDbValue ());
    }
    
    RemotePermissions RemotePermissions.fromDbValue (QByteArray &value) {
        if (value.isEmpty ())
            return {};
        RemotePermissions perm;
        perm.fromArray (value.constData ());
        return perm;
    }
    
    RemotePermissions RemotePermissions.fromServerString (string &value) {
        RemotePermissions perm;
        perm.fromArray (value.utf16 ());
        return perm;
    }
    
    } // namespace Occ
    