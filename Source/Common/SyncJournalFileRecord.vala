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
    public bool is_valid () {
        return !this.path.is_empty ();
    }


    /***********************************************************
    Returns the numeric part of the full id in this.file_id.

    On the server this is sometimes known as the internal file id.

    It is used in the construction of private links.
    ***********************************************************/
    public GLib.ByteArray numeric_file_id ();


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


    /***********************************************************
    ***********************************************************/
    public string path () {
        return string.from_utf8 (this.path);
    }


    /***********************************************************
    ***********************************************************/
    public string e2e_mangled_name () {
        return string.from_utf8 (this.e2e_mangled_name);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.path;
    public uint64 this.inode = 0;
    public int64 this.modtime = 0;
    public ItemType this.type = ItemTypeSkip;
    public GLib.ByteArray this.etag;
    public GLib.ByteArray this.file_id;
    public int64 this.file_size = 0;
    public RemotePermissions this.remote_perm;
    public bool this.server_has_ignored_files = false;
    public GLib.ByteArray this.checksum_header;
    public GLib.ByteArray this.e2e_mangled_name;
    public bool this.is_e2e_encrypted = false;
};

bool OCSYNC_EXPORT
operator== (SyncJournalFileRecord lhs,
    const SyncJournalFileRecord rhs);

class SyncJournalErrorBlocklistRecord {

    /***********************************************************
    ***********************************************************/
    public enum Category {
        /***********************************************************
        Normal errors have no special behavior
        ***********************************************************/
        Normal = 0,

        /***********************************************************
        These get a special summary message
        ***********************************************************/
        InsufficientRemoteStorage
    };


    /***********************************************************
    The number of times the operation was unsuccessful so far.
    ***********************************************************/
    public int this.retry_count = 0;


    /***********************************************************
    The last error string.
    ***********************************************************/
    public string this.error_string;


    /***********************************************************
    The error category. Sometimes used for special actions.
    ***********************************************************/
    public Category this.error_category = Category.Normal;

    /***********************************************************
    ***********************************************************/
    public int64 this.last_try_modtime = 0;


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.last_try_etag;


    /***********************************************************
    The last time the operation was attempted (in s since epoch).
    ***********************************************************/
    public int64 this.last_try_time = 0;


    /***********************************************************
    The number of seconds the file shall be ignored.
    ***********************************************************/
    public int64 this.ignore_duration = 0;

    /***********************************************************
    ***********************************************************/
    public string this.file;


    /***********************************************************
    ***********************************************************/
    public string this.rename_target;


    /***********************************************************
    The last X-Request-ID of the request that failled
    ***********************************************************/
    public GLib.ByteArray this.request_id;

    /***********************************************************
    ***********************************************************/
    public bool is_valid ();
};

/***********************************************************
Represents a conflict in the conflicts table.

In the following the "conflict file" is the file that has the conflict
tag in the filename, and the base file is the file that it's a conflict for.
So if "a/foo.txt" is the base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".
***********************************************************/
class ConflictRecord {

    /***********************************************************
    Path to the file with the conflict tag in the name

    The path is sync-folder relative.
    ***********************************************************/
    public GLib.ByteArray path;


    /***********************************************************
    File id of the base file
    ***********************************************************/
    public GLib.ByteArray base_file_id;


    /***********************************************************
    Modtime of the base file

    may not be available and be -1
    ***********************************************************/
    public int64 base_modtime = -1;


    /***********************************************************
    Etag of the base file

    may not be available and empty
    ***********************************************************/
    public GLib.ByteArray base_etag;


    /***********************************************************
    The path of the original file at the time the conflict was created

    Note that in nearly all cases one should query
    thus retrieve the current* base path instead!

    maybe be empty if not available
    ***********************************************************/
    public GLib.ByteArray initial_base_path;

    /***********************************************************
    ***********************************************************/
    public bool is_valid () {
        return !path.is_empty ();
    }
};


    GLib.ByteArray SyncJournalFileRecord.numeric_file_id () {
        // Use the id up until the first non-numeric character
        for (int i = 0; i < this.file_id.size (); ++i) {
            if (this.file_id[i] < '0' || this.file_id[i] > '9') {
                return this.file_id.left (i);
            }
        }
        return this.file_id;
    }

    bool SyncJournalErrorBlocklistRecord.is_valid () {
        return !this.file.is_empty ()
            && (!this.last_try_etag.is_empty () || this.last_try_modtime != 0)
            && this.last_try_time > 0;
    }

    bool operator== (SyncJournalFileRecord lhs,
        const SyncJournalFileRecord rhs) {
        return lhs._path == rhs._path
            && lhs._inode == rhs._inode
            && lhs._modtime == rhs._modtime
            && lhs._type == rhs._type
            && lhs._etag == rhs._etag
            && lhs._file_id == rhs._file_id
            && lhs._file_size == rhs._file_size
            && lhs._remote_perm == rhs._remote_perm
            && lhs._server_has_ignored_files == rhs._server_has_ignored_files
            && lhs._checksum_header == rhs._checksum_header;
    }
    }
    