/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The SyncJournalFileRecord class
@ingroup libsync
***********************************************************/
class SyncJournalFileRecord {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray path;
    public uint64 inode = 0;
    public int64 modtime = 0;
    public ItemType type = ItemTypeSkip;
    public GLib.ByteArray etag;
    public GLib.ByteArray file_id;
    public int64 file_size = 0;
    public RemotePermissions remote_perm;
    public bool server_has_ignored_files = false;
    public GLib.ByteArray checksum_header;
    public GLib.ByteArray e2e_mangled_name;
    public bool is_e2e_encrypted = false;

    /***********************************************************
    ***********************************************************/
    public bool is_valid () {
        return !this.path.is_empty ()
            && (!this.last_try_etag.is_empty () || this.last_try_modtime != 0)
            && this.last_try_time > 0;
    }


    /***********************************************************
    Returns the numeric part of the full identifier in this.file_id.

    On the server this is sometimes known as the internal file identifier.

    It is used in the construction of private links.
    ***********************************************************/
    public GLib.ByteArray numeric_file_id () {
        // Use the identifier up until the first non-numeric character
        for (int i = 0; i < this.file_id.size (); ++i) {
            if (this.file_id[i] < '0' || this.file_id[i] > '9') {
                return this.file_id.left (i);
            }
        }
        return this.file_id;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.DateTime mod_date_time () {
        return Utility.q_date_time_from_time_t (this.modtime);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_directory () {
        return this.type == ItemTypeDirectory;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_file () {
        return this.type == ItemTypeFile || this.type == ItemTypeVirtualFileDehydration;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_virtual_file () {
        return this.type == ItemTypeVirtualFile || this.type == ItemTypeVirtualFileDownload;
    }


    //  OCSYNC_EXPORT
    //  bool operator== (SyncJournalFileRecord lhs,
    //      SyncJournalFileRecord rhs) {
    //      return lhs.path == rhs.path
    //          && lhs.inode == rhs.inode
    //          && lhs.modtime == rhs.modtime
    //          && lhs.type == rhs.type
    //          && lhs.etag == rhs.etag
    //          && lhs.file_id == rhs.file_id
    //          && lhs.file_size == rhs.file_size
    //          && lhs.remote_perm == rhs.remote_perm
    //          && lhs.server_has_ignored_files == rhs.server_has_ignored_files
    //          && lhs.checksum_header == rhs.checksum_header;
    //  }

} // class SyncJournalFileRecord

} // namespace Occ
    