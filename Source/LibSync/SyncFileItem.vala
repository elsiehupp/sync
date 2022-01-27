/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #include <QVector>
// #include <string>
// #include <QDateTime>
// #include <QMetaType>


// #include <csync.h>

// #include <owncloudlib.h>



namespace Occ {

using SyncFileItemPtr = unowned<SyncFileItem>;

/***********************************************************
@brief The SyncFileItem class
@ingroup libsync
***********************************************************/
class SyncFileItem {
    Q_GADGET

    public enum Direction {
        None = 0,
        Up,
        Down
    };

    public enum Status { // stored in 4 bits
        NoStatus,

        FatalError, ///< Error that causes the sync to stop
        NormalError, ///< Error attached to a particular file
        SoftError, ///< More like an information

        Success, ///< The file was properly synced

        /***********************************************************
        Marks a conflict, old or new.

        With instruction:IGNORE : detected an old unresolved old conflict
        With instruction:CONFLICT : a new conflict this sync run
        ***********************************************************/
        Conflict,

        FileIgnored, ///< The file is in the ignored list (or blacklisted with no retries left)
        FileLocked, ///< The file is locked
        Restoration, ///< The file was restored because what should have been done was not allowed

        /***********************************************************
        The filename is invalid on this platform and could not created.
        ***********************************************************/
        FileNameInvalid,

        /***********************************************************
        For errors that should only appear in the error view.

        Some errors also produce a summary message. Usually displaying that message is
        sufficient, but the individual errors should still appear in the issues tab.

        These errors do cause the sync to fail.

        A NormalError that isn't as prominent.
        ***********************************************************/
        DetailError,

        /***********************************************************
        For files whose errors were blacklisted

        If an file is blacklisted due to an error it isn't even reattempted. These
        errors should appear in the issues tab but should be silent otherwise.

        A SoftError caused by blacklisting.
        ***********************************************************/
        BlacklistedError
    };

    public SyncJournalFileRecord to_sync_journal_file_record_with_inode (string local_file_name);

    /***********************************************************
    Creates a basic SyncFileItem from a DB record

    This is intended in particular for read-update-write cycles that need
    to go through a a SyncFileItem, like PollJob.
    ***********************************************************/
    public static SyncFileItemPtr from_sync_journal_file_record (SyncJournalFileRecord &rec);

    public SyncFileItem ()
        : _type (ItemTypeSkip)
        , _direction (None)
        , _server_has_ignored_files (false)
        , _has_blacklist_entry (false)
        , _error_may_be_blacklisted (false)
        , _status (NoStatus)
        , _is_restoration (false)
        , _is_selective_sync (false)
        , _is_encrypted (false) {
    }

    public friend bool operator== (SyncFileItem &item1, SyncFileItem &item2) {
        return item1._original_file == item2._original_file;
    }

    public friend bool operator< (SyncFileItem &item1, SyncFileItem &item2) {
        // Sort by destination
        auto d1 = item1.destination ();
        auto d2 = item2.destination ();

        // But this we need to order it so the slash come first. It should be this order:
        //  "foo", "foo/bar", "foo-bar"
        // This is important since we assume that the contents of a folder directly follows
        // its contents

        auto data1 = d1.const_data ();
        auto data2 = d2.const_data ();

        // Find the length of the largest prefix
        int prefix_l = 0;
        auto min_size = std.min (d1.size (), d2.size ());
        while (prefix_l < min_size && data1[prefix_l] == data2[prefix_l]) {
            prefix_l++;
        }

        if (prefix_l == d2.size ())
            return false;
        if (prefix_l == d1.size ())
            return true;

        if (data1[prefix_l] == '/')
            return true;
        if (data2[prefix_l] == '/')
            return false;

        return data1[prefix_l] < data2[prefix_l];
    }

    public string destination () {
        if (!_rename_target.is_empty ()) {
            return _rename_target;
        }
        return _file;
    }

    public bool is_empty () {
        return _file.is_empty ();
    }

    public bool is_directory () {
        return _type == ItemTypeDirectory;
    }

    /***********************************************************
    True if the item had any kind of error.
    ***********************************************************/
    public bool has_error_status () {
        return _status == SyncFileItem.SoftError
            || _status == SyncFileItem.NormalError
            || _status == SyncFileItem.FatalError
            || !_error_string.is_empty ();
    }

    /***********************************************************
    Whether this item should appear on the issues tab.
    ***********************************************************/
    public bool show_in_issues_tab () {
        return has_error_status () || _status == SyncFileItem.Conflict;
    }

    /***********************************************************
    Whether this item should appear on the protocol tab.
    ***********************************************************/
    public bool show_in_protocol_tab () {
        return (!show_in_issues_tab () || _status == SyncFileItem.Restoration)
            // Don't show conflicts that were resolved as "not a conflict after all"
            && ! (_instruction == CSYNC_INSTRUCTION_CONFLICT && _status == SyncFileItem.Success);
    }

    // Variables useful for everybody

    /***********************************************************
    The syncfolder-relative filesystem path that the operation is about

    For rename operation this is the rename source and the target is in _rename_target.
    ***********************************************************/
    public string _file;

    /***********************************************************
    for renames : the name _file should be renamed to
    for dehydrations : the name _file should become after dehydration (like adding a suffix)
    otherwise empty. Use destination () to find the sync target.
    ***********************************************************/
    public string _rename_target;

    /***********************************************************
    The db-path of this item.

    This can easily differ from _file and _rename_target if parts of the path were renamed.
    ***********************************************************/
    public string _original_file;

    /// Whether there's end to end encryption on this file.
    /// If the file is encrypted, the _encrypted_filename is
    /// the encrypted name on the server.
    public string _encrypted_file_name;

    public ItemType _type BITFIELD (3);
    public Direction _direction BITFIELD (3);
    public bool _server_has_ignored_files BITFIELD (1);

    /// Whether there's an entry in the blacklist table.
    /// Note : that entry may have retries left, so this can be true
    /// without the status being FileIgnored.
    public bool _has_blacklist_entry BITFIELD (1);

    /***********************************************************
    If true and NormalError, this error may be blacklisted

    Note that non-local errors (http_error_code!=0) may also be
    blacklisted independently of this flag.
    ***********************************************************/
    public bool _error_may_be_blacklisted BITFIELD (1);

    // Variables useful to report to the user
    public Status _status BITFIELD (4);
    public bool _is_restoration BITFIELD (1); // The original operation was forbidden, and this is a restoration
    public bool _is_selective_sync BITFIELD (1); // The file is removed or ignored because it is in the selective sync list
    public bool _is_encrypted BITFIELD (1); // The file is E2EE or the content of the directory should be E2EE
    public uint16 _http_error_code = 0;
    public RemotePermissions _remote_perm;
    public string _error_string; // Contains a string only in case of error
    public GLib.ByteArray _response_time_stamp;
    public GLib.ByteArray _request_id; // X-Request-Id of the failed request
    public uint32 _affected_items = 1; // the number of affected items by the operation on this item.
    // usually this value is 1, but for removes on dirs, it might be much higher.

    // Variables used by the propagator
    public SyncInstructions _instruction = CSYNC_INSTRUCTION_NONE;
    public time_t _modtime = 0;
    public GLib.ByteArray _etag;
    public int64 _size = 0;
    public uint64 _inode = 0;
    public GLib.ByteArray _file_id;

    // This is the value for the 'new' side, matching with _size and _modtime.
    //
    // When is this set, and is it the local or the remote checksum?
    // - if mtime or size changed locally for *.eml files (local checksum)
    // - for potential renames of local files (local checksum)
    // - for conflicts (remote checksum)
    public GLib.ByteArray _checksum_header;

    // The size and modtime of the file getting overwritten (on the disk for downloads, on the server for uploads).
    public int64 _previous_size = 0;
    public time_t _previous_modtime = 0;

    public string _direct_download_url;
    public string _direct_download_cookies;
};

inline bool operator< (SyncFileItemPtr &item1, SyncFileItemPtr &item2) {
    return *item1 < *item2;
}

using SyncFileItemVector = QVector<SyncFileItemPtr>;


    SyncJournalFileRecord SyncFileItem.to_sync_journal_file_record_with_inode (string local_file_name) {
        SyncJournalFileRecord rec;
        rec._path = destination ().to_utf8 ();
        rec._modtime = _modtime;

        // Some types should never be written to the database when propagation completes
        rec._type = _type;
        if (rec._type == ItemTypeVirtualFileDownload)
            rec._type = ItemTypeFile;
        if (rec._type == ItemTypeVirtualFileDehydration)
            rec._type = ItemTypeVirtualFile;

        rec._etag = _etag;
        rec._file_id = _file_id;
        rec._file_size = _size;
        rec._remote_perm = _remote_perm;
        rec._server_has_ignored_files = _server_has_ignored_files;
        rec._checksum_header = _checksum_header;
        rec._e2e_mangled_name = _encrypted_file_name.to_utf8 ();
        rec._is_e2e_encrypted = _is_encrypted;

        // Update the inode if possible
        rec._inode = _inode;
        if (FileSystem.get_inode (local_file_name, &rec._inode)) {
            q_c_debug (lc_file_item) << local_file_name << "Retrieved inode " << rec._inode << " (previous item inode : " << _inode << ")";
        } else {
            // use the "old" inode coming with the item for the case where the
            // filesystem stat fails. That can happen if the the file was removed
            // or renamed meanwhile. For the rename case we still need the inode to
            // detect the rename though.
            q_c_warning (lc_file_item) << "Failed to query the 'inode' for file " << local_file_name;
        }
        return rec;
    }

    SyncFileItemPtr SyncFileItem.from_sync_journal_file_record (SyncJournalFileRecord &rec) {
        auto item = SyncFileItemPtr.create ();
        item._file = rec.path ();
        item._inode = rec._inode;
        item._modtime = rec._modtime;
        item._type = rec._type;
        item._etag = rec._etag;
        item._file_id = rec._file_id;
        item._size = rec._file_size;
        item._remote_perm = rec._remote_perm;
        item._server_has_ignored_files = rec._server_has_ignored_files;
        item._checksum_header = rec._checksum_header;
        item._encrypted_file_name = rec.e2e_mangled_name ();
        item._is_encrypted = rec._is_e2e_encrypted;
        return item;
    }

    }
    