namespace Occ {
namespace Common {

/***********************************************************
@class RemotePermissions

@brief Class that store in a memory efficient way the remote
permission

@author Olivier Goffart <ogoffart@woboq.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class RemotePermissions { //: GLib.Object {

    //  /***********************************************************
    //  The first bit tells if the value is set or not
    //  The remaining bits correspond to know if the value is set
    //  ***********************************************************/
    //  private uint16 value = 0;
    //  private const int not_null_mask = 0x1;

    //  /***********************************************************
    //  ***********************************************************/
    //  const string LETTERS = " WDNVCKRSMm";

    //  /***********************************************************
    //  Template typename Char can be 'char' or 'ushort' if
    //  conversion from string.
    //  ***********************************************************/
    //  private RemotePermissions.from_array (char[] remote_permissions) {
    //      this.value = (uint16)not_null_mask;
    //      if (remote_permissions == null) {
    //          return;
    //      }
    //      for (int i; i < remote_permissions.length; i++) {
    //          var res = Posix.strchr (LETTERS, (char)remote_permissions[i]);
    //          if (res != null) {
    //              this.value |= (1 << (res - LETTERS));
    //          }
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public enum Permissions {
    //      /***********************************************************
    //      W
    //      ***********************************************************/
    //      CAN_WRITE = 1,
    //      /***********************************************************
    //      D
    //      ***********************************************************/
    //      CAN_DELETE = 2,
    //      /***********************************************************
    //      N
    //      ***********************************************************/
    //      CAN_RENAME = 3,
    //      /***********************************************************
    //      V
    //      ***********************************************************/
    //      CAN_MOVE = 4,
    //      /***********************************************************
    //      C
    //      ***********************************************************/
    //      CAN_ADD_FILE = 5,
    //      /***********************************************************
    //      K
    //      ***********************************************************/
    //      CAN_ADD_SUB_DIRECTORIES = 6,
    //      /***********************************************************
    //      R
    //      ***********************************************************/
    //      CAN_RESHARE = 7,
    //      /***********************************************************
    //      S

    //      Note: on the server, this means SHARED_WITH_ME, but in
    //      DiscoveryPhase we also set this permission when the server
    //      reports the any "share-types".
    //      ***********************************************************/
    //      IS_SHARED = 8,
    //      /***********************************************************
    //      M
    //      ***********************************************************/
    //      IS_MOUNTED = 9,
    //      /***********************************************************
    //      m (internal: set if the parent directory has
    //      Permissions.IS_MOUNTED)
    //      ***********************************************************/
    //      IS_MOUNTED_SUB = 10,

    //      /***********************************************************
    //      Note: when adding support for more permissions, we need to
    //      invalid the cache in the database (by setting
    //      force_remote_discovery in SyncJournalDb.check_connect).
    //      ***********************************************************/
    //      PERMISSIONS_COUNT = Permissions.IS_MOUNTED_SUB
    //  }


    //  /***********************************************************
    //  array with one character per permission, "" is null, " " is non-null but empty
    //  ***********************************************************/
    //  public char[] to_database_value () {
    //      char[] result;
    //      if (is_null ()) {
    //          return result;
    //      }
    //      result = new char[Permissions.PERMISSIONS_COUNT];
    //      int position = 0;
    //      for (uint32 index = 1; index <= Permissions.PERMISSIONS_COUNT; index++) {
    //          if ((this.value & (1 << index)) != 0) {
    //              result[position] = LETTERS[index];
    //              position++;
    //          }
    //      }
    //      result[position] = '\0';
    //      if (result[0] == '\0') {
    //          /***********************************************************
    //          Make sure it is not empty so we can differentiate null and
    //          empty permissions.
    //          ***********************************************************/
    //          result[0] = ' ';
    //          result[1] = '\0';
    //      }
    //      return result;
    //  }


    //  /***********************************************************
    //  Output for display purposes, no defined format (same as
    //  to_database_value in practice).
    //  ***********************************************************/
    //  public string to_string () {
    //      string database_string = "";
    //      char[] char_array = to_database_value ();
    //      for (int i = 0; i < char_array.length; i++) {
    //          database_string += char_array[i].to_string ();
    //      }
    //      return database_string;
    //  }


    //  /***********************************************************
    //  read value that was written with to_database_value ()
    //  ***********************************************************/
    //  public RemotePermissions.from_database_value (string value) {
    //      if (value != "") {
    //          new RemotePermissions.from_array (value.to_utf8 ());
    //      }
    //  }


    //  /***********************************************************
    //  Read a permissions string received from the server, never null
    //  ***********************************************************/
    //  public RemotePermissions.from_server_string (string value) {
    //      new RemotePermissions.from_array (value.to_utf8 ());
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool has_permission (Permissions permissions) {
    //      return (this.value & (1 << (uint16)permissions)) != 0;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void permission (Permissions permissions) {
    //      this.value |= (1 << (int)permissions) | not_null_mask;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void unset_permission (Permissions permissions) {
    //      this.value &= ~ (1 << (int)permissions);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool is_null () {
    //      return (this.value & not_null_mask) != 0;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool equal (RemotePermissions a, RemotePermissions b) {
    //      return a.value == b.value;
    //  }

} // class RemotePermissions

} // namespace Common
} // namespace Occ
