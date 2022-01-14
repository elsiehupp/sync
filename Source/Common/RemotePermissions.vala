/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/
/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <cstring>

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
    static constexpr int not_null_mask = 0x1;

    template <typename Char> // can be 'char' or 'ushort' if conversion from string
    void from_array (Char *p);

    public enum Permissions {
        Can_write = 1,             // W
        Can_delete = 2,            // D
        Can_rename = 3,            // N
        Can_move = 4,              // V
        Can_add_file = 5,           // C
        Can_add_sub_directories = 6, // K
        Can_reshare = 7,           // R
        // Note : on the server, this means Shared_with_me, but in discoveryphase.cpp we also set
        // this permission when the server reports the any "share-types"
        Is_shared = 8,             // S
        Is_mounted = 9,            // M
        Is_mounted_sub = 10,        // m (internal : set if the parent dir has Is_mounted)

        // Note : when adding support for more permissions, we need to invalid the cache in the database.
        // (by setting force_remote_discovery in SyncJournalDb.check_connect)
        PermissionsCount = Is_mounted_sub
    };

    /// null permissions
    public RemotePermissions () = default;

    /// array with one character per permission, "" is null, " " is non-null but empty
    public QByteArray to_db_value ();

    /// output for display purposes, no defined format (same as to_db_value in practice)
    public string to_string ();

    /// read value that was written with to_db_value ()
    public static RemotePermissions from_db_value (QByteArray &);

    /// read a permissions string received from the server, never null
    public static RemotePermissions from_server_string (string &);

    public bool has_permission (Permissions p) {
        return _value & (1 << static_cast<int> (p));
    }
    public void set_permission (Permissions p) {
        _value |= (1 << static_cast<int> (p)) | not_null_mask;
    }
    public void unset_permission (Permissions p) {
        _value &= ~ (1 << static_cast<int> (p));
    }

    public bool is_null () {
        return ! (_value & not_null_mask);
    }
    public friend bool operator== (RemotePermissions a, RemotePermissions b) {
        return a._value == b._value;
    }
    public friend bool operator!= (RemotePermissions a, RemotePermissions b) {
        return ! (a == b);
    }

    public friend QDebug operator<< (QDebug &dbg, RemotePermissions p) {
        return dbg << p.to_string ();
    }
};



    static const char letters[] = " WDNVCKRSMm";

    template <typename Char>
    void RemotePermissions.from_array (Char *p) {
        _value = not_null_mask;
        if (!p)
            return;
        while (*p) {
            if (auto res = std.strchr (letters, static_cast<char> (*p)))
                _value |= (1 << (res - letters));
            ++p;
        }
    }

    QByteArray RemotePermissions.to_db_value () {
        QByteArray result;
        if (is_null ())
            return result;
        result.reserve (PermissionsCount);
        for (uint i = 1; i <= PermissionsCount; ++i) {
            if (_value & (1 << i))
                result.append (letters[i]);
        }
        if (result.is_empty ()) {
            // Make sure it is not empty so we can differentiate null and empty permissions
            result.append (' ');
        }
        return result;
    }

    string RemotePermissions.to_string () {
        return string.from_utf8 (to_db_value ());
    }

    RemotePermissions RemotePermissions.from_db_value (QByteArray &value) {
        if (value.is_empty ())
            return {};
        RemotePermissions perm;
        perm.from_array (value.const_data ());
        return perm;
    }

    RemotePermissions RemotePermissions.from_server_string (string &value) {
        RemotePermissions perm;
        perm.from_array (value.utf16 ());
        return perm;
    }

    } // namespace Occ
    