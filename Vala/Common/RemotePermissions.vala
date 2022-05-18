namespace Occ {
namespace Common {

/***********************************************************
@class RemotePermissions

@brief Class that store in a memory efficient way the remote
permission

@author Olivier Goffart <ogoffart@woboq.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class RemotePermissions : GLib.Object {

    // The first bit tells if the value is set or not
    // The remaining bits correspond to know if the value is set
    private uint16 value = 0;
    private const int not_null_mask = 0x1;

    /***********************************************************
    ***********************************************************/
    const string LETTERS = " WDNVCKRSMm";

    /***********************************************************
    ***********************************************************/
    //  private template <typename Char> // can be 'char' or 'ushort' if conversion from string
    private RemotePermissions.from_array (char[] remote_permissions) {
        this.value = (uint16)not_null_mask;
        if (remote_permissions == null) {
            return;
        }
        for (int i; i < remote_permissions.length; i++) {
            var res = std.strchr (LETTERS, (char)remote_permissions[i]);
            if (res) {
                this.value |= (1 << (res - LETTERS));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public enum Permissions {
        CAN_WRITE = 1,             // W
        CAN_DELETE = 2,            // D
        CAN_RENAME = 3,            // N
        CAN_MOVE = 4,              // V
        CAN_ADD_FILE = 5,           // C
        CAN_ADD_SUB_DIRECTORIES = 6, // K
        CAN_RESHARE = 7,           // R
        // Note: on the server, this means SHARED_WITH_ME, but in discoveryphase.cpp we also set
        // this permission when the server reports the any "share-types"
        IS_SHARED = 8,             // S
        IS_MOUNTED = 9,            // M
        IS_MOUNTED_SUB = 10,        // m (internal : set if the parent directory has Permissions.IS_MOUNTED)

        // Note: when adding support for more permissions, we need to invalid the cache in the database.
        // (by setting force_remote_discovery in SyncJournalDb.check_connect)
        PERMISSIONS_COUNT = Permissions.IS_MOUNTED_SUB
    }


    /***********************************************************
    null permissions
    ***********************************************************/
    //  public RemotePermissions () = default;


    /***********************************************************
    array with one character per permission, "" is null, " " is non-null but empty
    ***********************************************************/
    public string to_database_value () {
        string result;
        if (is_null ()) {
            return result;
        }
        //  result.reserve (Permissions.PERMISSIONS_COUNT);
        for (uint32 i = 1; i <= Permissions.PERMISSIONS_COUNT; ++i) {
            if ((this.value & (1 << i)) != 0) {
                result += LETTERS[i].to_string ();
            }
        }
        if (result == "") {
            // Make sure it is not empty so we can differentiate null and empty permissions
            result += " ";
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
    public RemotePermissions.from_database_value (string value) {
        if (value == "") {
            this = new RemotePermissions ();
        }
        this = new RemotePermissions.from_array (value.const_data ());
    }


    /***********************************************************
    Read a permissions string received from the server, never null
    ***********************************************************/
    public RemotePermissions.from_server_string (string value) {
        this = new RemotePermissions.from_array (value.utf16 ());
    }


    /***********************************************************
    ***********************************************************/
    public bool has_permission (Permissions permissions) {
        return this.value & (1 << (int)permissions);
    }


    /***********************************************************
    ***********************************************************/
    public void permission (Permissions permissions) {
        this.value |= (1 << (int)permissions) | not_null_mask;
    }


    /***********************************************************
    ***********************************************************/
    public void unset_permission (Permissions permissions) {
        this.value &= ~ (1 << (int)permissions);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_null () {
        return (this.value & not_null_mask) != 0;
    }


    /***********************************************************
    ***********************************************************/
    //  public friend bool operator== (RemotePermissions a, RemotePermissions b) {
    //      return a.value == b.value;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public friend bool operator!= (RemotePermissions a, RemotePermissions b) {
    //      return ! (a == b);
    //  }


    /***********************************************************
    ***********************************************************/
    //  public friend GLib.Debug operator<< (GLib.Debug dbg, RemotePermissions remote_permissions) {
    //      return dbg + remote_permissions.to_string ();
    //  }

} // class RemotePermissions

} // namespace Common
} // namespace Occ
