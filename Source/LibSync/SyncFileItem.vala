/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <GLib.Vector>
// #include <QMetaType>
// #include <owncloudlib.h>

using CSync;

namespace Occ {

/***********************************************************
@brief The SyncFileItem class
@ingroup libsync
***********************************************************/
class SyncFileItem {
    // Q_GADGET

    private class SyncFileItemPtr : unowned SyncFileItem { }
    private class SyncFileItemVector : GLib.Vector<SyncFileItemPtr> { }

    /***********************************************************
    ***********************************************************/
    public enum Direction {
        NONE = 0,
        UP,
        DOWN
    };

    /***********************************************************
    Stored in 4 bits
    ***********************************************************/
    public enum Status {

        /***********************************************************
        ***********************************************************/
        NO_STATUS,

        /***********************************************************
        Error that causes the sync to stop
        ***********************************************************/
        FATAL_ERROR,

        /***********************************************************
        Error attached to a particular file
        ***********************************************************/
        NORMAL_ERROR,

        /***********************************************************
        More like an information (which will likely resolve itself
        on its own)
        ***********************************************************/
        SOFT_ERROR,

        /***********************************************************
        The file was properly synced
        ***********************************************************/
        SUCCESS,

        /***********************************************************
        Marks a conflict, old or new.

        With instruction:IGNORE: detected an old unresolved old conflict
        With instruction:CONFLICT: a new conflict this sync run
        ***********************************************************/
        CONFLICT,

        /***********************************************************
        The file is in the ignored list (or blocklisted with no
        retries left).
        ***********************************************************/
        FILE_IGNORED,

        /***********************************************************
        The file is locked
        ***********************************************************/
        FILE_LOCKED,

        /***********************************************************
        The file was restored because what should have been done
        was not allowed.
        ***********************************************************/
        RESTORATION,

        /***********************************************************
        The filename is invalid on this platform and could not
        created.
        ***********************************************************/
        FILENAME_INVALID,

        /***********************************************************
        For errors that should only appear in the error view.

        Some errors also produce a summary message. Usually
        displaying that message is sufficient, but the individual
        errors should still appear in the issues tab.

        These errors do cause the sync to fail.

        A NormalError that isn't as prominent.
        ***********************************************************/
        DETAIL_ERROR,

        /***********************************************************
        For files whose errors were blocklisted

        If an file is blocklisted due to an error it isn't even
        reattempted. These errors should appear in the issues tab
        but should be silent otherwise.

        A SoftError caused by blocklisting.
        ***********************************************************/
        BLOCKLISTED_ERROR
    }


    /***********************************************************
    The syncfolder-relative filesystem path that the operation
    is about

    For rename operation this is the rename source and the
    target is in this.rename_target.

    Variable useful for everybody
    ***********************************************************/
    public string file;

    /***********************************************************
    For renames: the name this.file should be renamed to
    For dehydrations: the name this.file should become after
    dehydration (like adding a suffix)
    Otherwise empty. Use destination () to find the sync target.

    Variable useful for everybody
    ***********************************************************/
    public string rename_target;


    /***********************************************************
    The database-path of this item.

    This can easily differ from this.file and this.rename_target
    if parts of the path were renamed.

    Variable useful for everybody
    ***********************************************************/
    public string original_file;

    /***********************************************************
    Whether there's end to end encryption on this file.
    If the file is encrypted, the encrypted filename is
    the encrypted name on the server.

    Variable useful for everybody
    ***********************************************************/
    public string encrypted_filename;

    /***********************************************************
    Variable useful for everybody
    ***********************************************************/
    public ItemType type = BITFIELD (3);

    /***********************************************************
    Variable useful for everybody
    ***********************************************************/
    public bool server_has_ignored_files = BITFIELD (1);

    /***********************************************************
    Whether there's an entry in the blocklist table.

    Note: that entry may have retries left, so this can be true
    without the status being FileIgnored.

    Variable useful for everybody
    ***********************************************************/
    public bool has_blocklist_entry = BITFIELD (1);


    /***********************************************************
    If true and NormalError, this error may be blocklisted

    Note that non-local errors (http_error_code!=0) may also be
    blocklisted independently of this flag.

    Variable useful for everybody
    ***********************************************************/
    public bool error_may_be_blocklisted = BITFIELD (1);

    /***********************************************************
    Variable useful to report to the user
    ***********************************************************/
    public Status status = BITFIELD (4);

    /***********************************************************
    The original operation was forbidden, and this is a restoration

    Variable useful to report to the user
    ***********************************************************/
    public bool is_restoration = BITFIELD (1);

    /***********************************************************
    The file is removed or ignored because it is in the selective sync list

    Variable useful to report to the user
    ***********************************************************/
    public bool is_selective_sync = BITFIELD (1);

    /***********************************************************
    The file is E2EE or the content of the directory should be E2EE

    Variable useful to report to the user
    ***********************************************************/
    public bool is_encrypted = BITFIELD (1);

    /***********************************************************
    Variable useful to report to the user
    ***********************************************************/
    public uint16 http_error_code = 0;

    /***********************************************************
    Variable useful to report to the user
    ***********************************************************/
    public RemotePermissions remote_perm;

    /***********************************************************
    Contains a string only in case of error

    Variable useful to report to the user
    ***********************************************************/
    public string error_string;

    /***********************************************************
    Variable useful to report to the user
    ***********************************************************/
    public GLib.ByteArray response_time_stamp;

    /***********************************************************
    X-Request-Id of the failed request

    Variable useful to report to the user
    ***********************************************************/
    public GLib.ByteArray request_id;

    /***********************************************************
    The number of affected items by the operation on this item.

    Usually this value is 1, but for removes on directories, it
    might be much higher.

    Variable useful to report to the user
    ***********************************************************/
    public uint32 affected_items = 1;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public SyncInstructions instruction = CSYNC_INSTRUCTION_NONE;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public time_t modtime = 0;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public GLib.ByteArray etag;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public int64 size = 0;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public uint64 inode = 0;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public GLib.ByteArray file_id;


    /***********************************************************
    This is the value for the 'new' side, matching with
    this.size and this.modtime.

    When is this set, and is it the local or the remote checksum?
    - if mtime or size changed locally for *.eml files (local checksum)
    - for potential renames of local files (local checksum)
    - for conflicts (remote checksum)

    Variable used by the propagator
    ***********************************************************/
    public GLib.ByteArray checksum_header;


    /***********************************************************
    The size and modtime of the file getting overwritten (on
    the disk for downloads, on the server for uploads).

    Variable used by the propagator
    ***********************************************************/
    public int64 previous_size = 0;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public time_t previous_modtime = 0;


    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public string direct_download_url;

    /***********************************************************
    Variable used by the propagator
    ***********************************************************/
    public string direct_download_cookies;


    /***********************************************************
    ***********************************************************/
    public SyncJournalFileRecord to_sync_journal_file_record_with_inode (string local_filename) {
        SyncJournalFileRecord record;
        record._path = destination ().to_utf8 ();
        record._modtime = this.modtime;

        // Some types should never be written to the database when propagation completes
        record._type = this.type;
        if (record._type == ItemTypeVirtualFileDownload)
            record._type = ItemTypeFile;
        if (record._type == ItemTypeVirtualFileDehydration)
            record._type = ItemTypeVirtualFile;

        record._etag = this.etag;
        record._file_id = this.file_id;
        record._file_size = this.size;
        record._remote_perm = this.remote_perm;
        record._server_has_ignored_files = this.server_has_ignored_files;
        record._checksum_header = this.checksum_header;
        record._e2e_mangled_name = this.encrypted_filename.to_utf8 ();
        record._is_e2e_encrypted = this.is_encrypted;

        // Update the inode if possible
        record._inode = this.inode;
        if (FileSystem.get_inode (local_filename, record._inode)) {
            GLib.debug (lc_file_item) << local_filename << "Retrieved inode " << record._inode << " (previous item inode : " << this.inode << ")";
        } else {
            // use the "old" inode coming with the item for the case where the
            // filesystem stat fails. That can happen if the the file was removed
            // or renamed meanwhile. For the rename case we still need the inode to
            // detect the rename though.
            GLib.warn (lc_file_item) << "Failed to query the 'inode' for file " << local_filename;
        }
        return record;
    }


    /***********************************************************
    Creates a basic SyncFileItem from a DB record

    This is intended in particular for read-update-write cycles that need
    to go through a a SyncFileItem, like PollJob.
    ***********************************************************/
    public static SyncFileItemPtr from_sync_journal_file_record (SyncJournalFileRecord record) {
        var item = SyncFileItemPtr.create ();
        item._file = record.path ();
        item._inode = record._inode;
        item._modtime = record._modtime;
        item._type = record._type;
        item._etag = record._etag;
        item._file_id = record._file_id;
        item._size = record._file_size;
        item._remote_perm = record._remote_perm;
        item._server_has_ignored_files = record._server_has_ignored_files;
        item._checksum_header = record._checksum_header;
        item._encrypted_filename = record.e2e_mangled_name ();
        item._is_encrypted = record._is_e2e_encrypted;
        return item;
    }

    /***********************************************************
    ***********************************************************/
    public SyncFileItem () {
        this.type = ItemTypeSkip;
        this.direction = Direction.NONE;
        this.server_has_ignored_files = false;
        this.has_blocklist_entry = false;
        this.error_may_be_blocklisted = false;
        this.status = Status.NO_STATUS;
        this.is_restoration = false;
        this.is_selective_sync = false;
        this.is_encrypted = false;
    }


    /***********************************************************
    ***********************************************************/
    public string destination () {
        if (!this.rename_target.is_empty ()) {
            return this.rename_target;
        }
        return this.file;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_empty () {
        return this.file.is_empty ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_directory () {
        return this.type == ItemTypeDirectory;
    }


    /***********************************************************
    True if the item had any kind of error.
    ***********************************************************/
    public bool has_error_status () {
        return this.status == Status.SOFT_ERROR
            || this.status == Status.NORMAL_ERROR
            || this.status == Status.FATAL_ERROR
            || !this.error_string.is_empty ();
    }


    /***********************************************************
    Whether this item should appear on the issues tab.
    ***********************************************************/
    public bool show_in_issues_tab () {
        return has_error_status () || this.status == Status.CONFLICT;
    }


    /***********************************************************
    Whether this item should appear on the protocol tab.
    ***********************************************************/
    public bool show_in_protocol_tab () {
        return (!show_in_issues_tab () || this.status == Status.RESTORATION)
            // Don't show conflicts that were resolved as "not a conflict after all"
            && ! (this.instruction == CSYNC_INSTRUCTION_CONFLICT && this.status == Status.SUCCESS);
    }


    /***********************************************************
    ***********************************************************/
    //  inline bool operator< (SyncFileItemPtr item1, SyncFileItemPtr item2) {
    //      return item1 < *item2;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public friend bool operator== (SyncFileItem item1, SyncFileItem item2) {
    //      return item1._original_file == item2._original_file;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public friend bool operator< (SyncFileItem item1, SyncFileItem item2) {
    //      // Sort by destination
    //      var d1 = item1.destination ();
    //      var d2 = item2.destination ();

    //      // But this we need to order it so the slash come first. It should be this order:
    //      //  "foo", "foo/bar", "foo-bar"
    //      // This is important since we assume that the contents of a folder directly follows
    //      // its contents

    //      var data1 = d1.const_data ();
    //      var data2 = d2.const_data ();

    //      // Find the length of the largest prefix
    //      int prefix_l = 0;
    //      var min_size = std.min (d1.size (), d2.size ());
    //      while (prefix_l < min_size && data1[prefix_l] == data2[prefix_l]) {
    //          prefix_l++;
    //      }

    //      if (prefix_l == d2.size ())
    //          return false;
    //      if (prefix_l == d1.size ())
    //          return true;

    //      if (data1[prefix_l] == '/')
    //          return true;
    //      if (data2[prefix_l] == '/')
    //          return false;

    //      return data1[prefix_l] < data2[prefix_l];
    //  }
}

} // namespace Occ
    