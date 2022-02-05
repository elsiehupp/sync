/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/
/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <cstring>

//  #pragma once

//  #include <QMetaType>
//  #include <QDebug>

namespace Occ {

/***********************************************************
Class that store in a memory efficient way the remote permission
***********************************************************/
class RemotePermissions {

    // The first bit tells if the value is set or not
    // The remaining bits correspond to know if the value is set
    private uint16 this.value = 0;
    private const int not_null_mask = 0x1;

    /***********************************************************
    ***********************************************************/
    const string letters = " WDNVCKRSMm";

    /***********************************************************
    ***********************************************************/
    private template <typename Char> // can be 'char' or 'ushort' if conversion from string
    private void from_array (Char remote_permissions) {
        this.value = not_null_mask;
        if (!remote_permissions)
            return;
        while (*remote_permissions) {
            if (var res = std.strchr (letters, static_cast<char> (*remote_permissions)))
                this.value |= (1 << (res - letters));
            ++remote_permissions;
        }
    }


    /***********************************************************
    ***********************************************************/
    public enum Permissions {
        Can_write = 1,             // W
        Can_delete = 2,            // D
        Can_rename = 3,            // N
        Can_move = 4,              // V
        Can_add_file = 5,           // C
        Can_add_sub_directories = 6, // K
        Can_reshare = 7,           // R
        // Note: on the server, this means Shared_with_me, but in discoveryphase.cpp we also set
        // this permission when the server reports the any "share-types"
        IsShared = 8,             // S
        IsMounted = 9,            // M
        IsMountedSub = 10,        // m (internal : set if the parent dir has IsMounted)

        // Note: when adding support for more permissions, we need to invalid the cache in the database.
        // (by setting force_remote_discovery in SyncJournalDb.check_connect)
        PermissionsCount = IsMountedSub
    }


    /***********************************************************
    null permissions
    ***********************************************************/
    public RemotePermissions () = default;


    /***********************************************************
    array with one character per permission, "" is null, " " is non-null but empty
    ***********************************************************/
    public GLib.ByteArray to_database_value () {
        GLib.ByteArray result;
        if (is_null ())
            return result;
        result.reserve (PermissionsCount);
        for (uint32 i = 1; i <= PermissionsCount; ++i) {
            if (this.value & (1 << i))
                result.append (letters[i]);
        }
        if (result.is_empty ()) {
            // Make sure it is not empty so we can differentiate null and empty permissions
            result.append (' ');
        }
        return result;
    }


    /***********************************************************
    output for display purposes, no defined format (same as to_database_value in practice)
    ***********************************************************/
    public string to_string () {
        return string.from_utf8 (to_database_value ());
    }


    /***********************************************************
    read value that was written with to_database_value ()
    ***********************************************************/
    public static RemotePermissions from_database_value (GLib.ByteArray value) {
        if (value.is_empty ())
            return {};
        RemotePermissions perm;
        perm.from_array (value.const_data ());
        return perm;
    }


    /***********************************************************
    read a permissions string received from the server, never null
    ***********************************************************/
    public static RemotePermissions from_server_string (string ) {
        RemotePermissions perm;
        perm.from_array (value.utf16 ());
        return perm;
    }


    /***********************************************************
    ***********************************************************/
    public bool has_permission (Permissions permissions) {
        return this.value & (1 << static_cast<int> (permissions));
    }


    /***********************************************************
    ***********************************************************/
    public void set_permission (Permissions permissions) {
        this.value |= (1 << static_cast<int> (permissions)) | not_null_mask;
    }


    /***********************************************************
    ***********************************************************/
    public void unset_permission (Permissions permissions) {
        this.value &= ~ (1 << static_cast<int> (permissions));
    }


    /***********************************************************
    ***********************************************************/
    public bool is_null () {
        return ! (this.value & not_null_mask);
    }


    /***********************************************************
    ***********************************************************/
    public friend bool operator== (RemotePermissions a, RemotePermissions b) {
        return a.value == b.value;
    }


    /***********************************************************
    ***********************************************************/
    public friend bool operator!= (RemotePermissions a, RemotePermissions b) {
        return ! (a == b);
    }


    /***********************************************************
    ***********************************************************/
    public friend QDebug operator<< (QDebug dbg, RemotePermissions remote_permissions) {
        return dbg << remote_permissions.to_string ();
    }
}

} // namespace Occ
    