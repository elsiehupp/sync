/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #include <QVector>
// #include <string>
// #include <QDateTime>
// #include <QMetaType>
// #include <QSharedPointer>

// #include <csync.h>

// #include <owncloudlib.h>



namespace Occ {

using Sync_file_item_ptr = QSharedPointer<SyncFileItem>;

/***********************************************************
@brief The SyncFileItem class
@ingroup libsync
***********************************************************/
class SyncFileItem {
    Q_GADGET
public:
    enum Direction {
        None = 0,
        Up,
        Down
    };
    Q_ENUM (Direction)

    enum Status { // stored in 4 bits
        No_status,

        Fatal_error, ///< Error that causes the sync to stop
        Normal_error, ///< Error attached to a particular file
        Soft_error, ///< More like an information

        Success, ///< The file was properly synced

        /** Marks a conflict, old or new.
         *
         * With instruction:IGNORE : detected an old unresolved old conflict
         * With instruction:CONFLICT : a new conflict this sync run
         */
        Conflict,

        File_ignored, ///< The file is in the ignored list (or blacklisted with no retries left)
        File_locked, ///< The file is locked
        Restoration, ///< The file was restored because what should have been done was not allowed

        /***********************************************************
         * The filename is invalid on this platform and could not created.
         */
        File_name_invalid,

        /** For errors that should only appear in the error view.
         *
         * Some errors also produce a summary message. Usually displaying that message is
         * sufficient, but the individual errors should still appear in the issues tab.
         *
         * These errors do cause the sync to fail.
         *
         * A Normal_error that isn't as prominent.
         */
        Detail_error,

        /** For files whose errors were blacklisted
         *
         * If an file is blacklisted due to an error it isn't even reattempted. These
         * errors should appear in the issues tab but should be silent otherwise.
         *
         * A Soft_error caused by blacklisting.
         */
        Blacklisted_error
    };
    Q_ENUM (Status)

    SyncJournalFileRecord to_sync_journal_file_record_with_inode (string &local_file_name) const;

    /***********************************************************
    Creates a basic SyncFileItem from a DB record

    This is intended in particular for read-update-write cycles that need
    to go through a a SyncFileItem, like Poll_job.
    ***********************************************************/
    static Sync_file_item_ptr from_sync_journal_file_record (SyncJournalFileRecord &rec);

    SyncFileItem ()
        : _type (Item_type_skip)
        , _direction (None)
        , _server_has_ignored_files (false)
        , _has_blacklist_entry (false)
        , _error_may_be_blacklisted (false)
        , _status (No_status)
        , _is_restoration (false)
        , _is_selective_sync (false)
        , _is_encrypted (false) {
    }

    friend bool operator== (SyncFileItem &item1, SyncFileItem &item2) {
        return item1._original_file == item2._original_file;
    }

    friend bool operator< (SyncFileItem &item1, SyncFileItem &item2) {
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

    string destination () {
        if (!_rename_target.is_empty ()) {
            return _rename_target;
        }
        return _file;
    }

    bool is_empty () {
        return _file.is_empty ();
    }

    bool is_directory () {
        return _type == ItemTypeDirectory;
    }

    /***********************************************************
    True if the item had any kind of error.
    ***********************************************************/
    bool has_error_status () {
        return _status == SyncFileItem.Soft_error
            || _status == SyncFileItem.Normal_error
            || _status == SyncFileItem.Fatal_error
            || !_error_string.is_empty ();
    }

    /***********************************************************
    Whether this item should appear on the issues tab.
    ***********************************************************/
    bool show_in_issues_tab () {
        return has_error_status () || _status == SyncFileItem.Conflict;
    }

    /***********************************************************
    Whether this item should appear on the protocol tab.
    ***********************************************************/
    bool show_in_protocol_tab () {
        return (!show_in_issues_tab () || _status == SyncFileItem.Restoration)
            // Don't show conflicts that were resolved as "not a conflict after all"
            && ! (_instruction == CSYNC_INSTRUCTION_CONFLICT && _status == SyncFileItem.Success);
    }

    // Variables useful for everybody

    /***********************************************************
    The syncfolder-relative filesystem path that the operation is about

    For rename operation this is the rename source and the target is in _rename_target.
    ***********************************************************/
    string _file;

    /***********************************************************
    for renames : the name _file should be renamed to
    for dehydrations : the name _file should become after dehydration (like adding a suffix)
    otherwise empty. Use destination () to find the sync target.
    ***********************************************************/
    string _rename_target;

    /***********************************************************
    The db-path of this item.

    This can easily differ from _file and _rename_target if parts of the path were renamed.
    ***********************************************************/
    string _original_file;

    /// Whether there's end to end encryption on this file.
    /// If the file is encrypted, the _encrypted_filename is
    /// the encrypted name on the server.
    string _encrypted_file_name;

    ItemType _type BITFIELD (3);
    Direction _direction BITFIELD (3);
    bool _server_has_ignored_files BITFIELD (1);

    /// Whether there's an entry in the blacklist table.
    /// Note : that entry may have retries left, so this can be true
    /// without the status being File_ignored.
    bool _has_blacklist_entry BITFIELD (1);

    /***********************************************************
    If true and Normal_error, this error may be blacklisted

    Note that non-local errors (http_error_code!=0) may also be
    blacklisted independently of this flag.
    ***********************************************************/
    bool _error_may_be_blacklisted BITFIELD (1);

    // Variables useful to report to the user
    Status _status BITFIELD (4);
    bool _is_restoration BITFIELD (1); // The original operation was forbidden, and this is a restoration
    bool _is_selective_sync BITFIELD (1); // The file is removed or ignored because it is in the selective sync list
    bool _is_encrypted BITFIELD (1); // The file is E2EE or the content of the directory should be E2EE
    uint16 _http_error_code = 0;
    RemotePermissions _remote_perm;
    string _error_string; // Contains a string only in case of error
    QByteArray _response_time_stamp;
    QByteArray _request_id; // X-Request-Id of the failed request
    uint32 _affected_items = 1; // the number of affected items by the operation on this item.
    // usually this value is 1, but for removes on dirs, it might be much higher.

    // Variables used by the propagator
    Sync_instructions _instruction = CSYNC_INSTRUCTION_NONE;
    time_t _modtime = 0;
    QByteArray _etag;
    int64 _size = 0;
    uint64 _inode = 0;
    QByteArray _file_id;

    // This is the value for the 'new' side, matching with _size and _modtime.
    //
    // When is this set, and is it the local or the remote checksum?
    // - if mtime or size changed locally for *.eml files (local checksum)
    // - for potential renames of local files (local checksum)
    // - for conflicts (remote checksum)
    QByteArray _checksum_header;

    // The size and modtime of the file getting overwritten (on the disk for downloads, on the server for uploads).
    int64 _previous_size = 0;
    time_t _previous_modtime = 0;

    string _direct_download_url;
    string _direct_download_cookies;
};

inline bool operator< (Sync_file_item_ptr &item1, Sync_file_item_ptr &item2) {
    return *item1 < *item2;
}

using Sync_file_item_vector = QVector<Sync_file_item_ptr>;


    SyncJournalFileRecord SyncFileItem.to_sync_journal_file_record_with_inode (string &local_file_name) {
        SyncJournalFileRecord rec;
        rec._path = destination ().to_utf8 ();
        rec._modtime = _modtime;
    
        // Some types should never be written to the database when propagation completes
        rec._type = _type;
        if (rec._type == Item_type_virtual_file_download)
            rec._type = ItemTypeFile;
        if (rec._type == ItemTypeVirtualFileDehydration)
            rec._type = Item_type_virtual_file;
    
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
    
    Sync_file_item_ptr SyncFileItem.from_sync_journal_file_record (SyncJournalFileRecord &rec) {
        auto item = Sync_file_item_ptr.create ();
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
    