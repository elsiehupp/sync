/***********************************************************
@brief CSync public API

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/

//  #include <sys/stat.h>
//  #include <cstdint>
//  #include <sys/types.h>
//  #include <config_csyn
//  #include <functional>
//  #include <memory>

//  #if defined (Q_CC_GNU) && !defined (Q_CC_INTEL) && !defined (Q_CC_CLANG) && (__GNUC__ * 100 + __GNUC_MINOR__ < 408)
// open_suse 12.3 didn't like enum bitfields.
//  const int BITFIELD (size)
//  #elif defined (Q_CC_MSVC)
// MSVC stores enum and bool as signed, so we need to add a bit for the sign
//  const int BITFIELD (size) : (size+1)
//  #else
//  const int BITFIELD (size) : size
//  #endif

namespace CSync {

enum CsyncStatus {
    OK               = 0,

    ERROR            = 1024, // don't use this code
    UNSUCCESSFUL,            // Unspecific problem happend
    STATEDB_LOAD_ERROR,      // Statedatabase can not be loaded.
    UPDATE_ERROR,            // general update or discovery error
    TIMEOUT,                 // UNUSED
    HTTP_ERROR,              // UNUSED
    PERMISSION_DENIED,
    NOT_FOUND,
    FILE_EXISTS,
    OUT_OF_SPACE,
    SERVICE_UNAVAILABLE,
    STORAGE_UNAVAILABLE,
    FILE_SIZE_ERROR,
    OPENDIR_ERROR,
    READDIR_ERROR,
    OPEN_ERROR,
    ABORTED
}

/***********************************************************
Codes for file individual status
***********************************************************/
enum IndividualFileStatus {
    IS_SYMLINK,
    IGNORE_LIST,
    IS_INVALID_CHARS,
    TRAILING_SPACE,
    EXCLUDE_LONG_FILENAME,
    EXCLUDE_HIDDEN,
    INVALID_CHARACTERS,
    STAT_FAILED,
    FORBIDDEN,
    TOO_DEEP,
    IS_CONFLICT_FILE,
    CANNOT_ENCODE
}

/***********************************************************
Instruction enum. In the file traversal structure, it
describes the csync state of a file.
***********************************************************/
enum SyncInstructions {
    NONE              = 0,          // Nothing to do (UPDATE|RECONCILE)
    EVAL              = 1 << 0,     // There was changed compared to the DB (UPDATE)
    REMOVE            = 1 << 1,     // The file need to be removed (RECONCILE)
    RENAME            = 1 << 2,     // The file need to be renamed (RECONCILE)
    EVAL_RENAME       = 1 << 11,    // The file is new, it is the destination of a rename (UPDATE)
    NEW               = 1 << 3,     // The file is new compared to the database (UPDATE)
    CONFLICT          = 1 << 4,     // The file need to be downloaded because it is a conflict (RECONCILE)
    IGNORE            = 1 << 5,     // The file is ignored (UPDATE|RECONCILE)
    SYNC              = 1 << 6,     // The file need to be pushed to the other remote (RECONCILE)
    STAT_ERROR        = 1 << 7,
    ERROR             = 1 << 8,
    TYPE_CHANGE       = 1 << 9,     /* Like NEW, but deletes the old entity first (RECONCILE)
                                    Used when the type of something changes from directory to file
                                    or back. */
    UPDATE_METADATA   = 1 << 10,    /* If the etag has been updated and need to be writen to the database,
                                    but without any propagation (UPDATE|RECONCILE) */
}
//  Q_ENUM_NS (SyncInstructions)

/***********************************************************
This enum is used with BITFIELD (3) and BITFIELD (4) in
several places. Also, this value is stored in the database,
so beware of value changes.
***********************************************************/
enum ItemType {
    FILE = 0,
    SOFT_LINK = 1,
    DIRECTORY = 2,
    SKIP = 3,

    /***********************************************************
    The file is a dehydrated placeholder, meaning data isn't
    available locally
    ***********************************************************/
    VIRTUAL_FILE = 4,

    /***********************************************************
    A ItemType.VIRTUAL_FILE that wants to be hydrated.

    Actions may put this in the database as a request to a
    future sync, such as implicit hydration (when the user wants
    to access file data) when using suffix vfs. For pin-state
    driven hydrations changing the database is not necessary.

    For some vfs plugins the placeholder files on disk may be
    marked for (de-)hydration (like with a
    will return this item type.

    The discovery will also use this item type to mark entries
    for hydration if an item's pin state mandates it, such as
    when encountering a PinState.ALWAYS_LOCAL file that is
    dehydrated.
    ***********************************************************/
    VIRTUAL_FILE_DOWNLOAD = 5,

    /***********************************************************
    A ItemType.FILE that wants to be dehydrated.

    Similar to ItemType.VIRTUAL_FILE_DOWNLOAD, but there's
    currently no situation where it's stored in the database
    since there is no action that triggers a file dehydration
    without changing the pin state.
    ***********************************************************/
    VIRTUAL_FILE_DEHYDRATION = 6,
}

//  struct CSyncFileStatS : CSyncFileStatT {}

// OCSYNC_EXPORT
public class CSyncFileStatS : CSyncFileStatT {
    time_t modtime = 0;
    int64 size = 0;
    uint64 inode = 0;

    RemotePermissions remote_perm;
    ItemType type = BITFIELD (4);
    bool child_modified = BITFIELD (1);
    bool has_ignored_files = BITFIELD (1); // Specify that a directory, or child directory contains ignored files.
    bool is_hidden = BITFIELD (1); // Not saved in the DB, only used during discovery for local files.
    bool is_e2e_encrypted = BITFIELD (1);

    string path;
    string rename_path;
    string etag;
    string file_id;
    string direct_download_url;
    string direct_download_cookies;
    string original_path; // only set if locale conversion fails

    // In the local tree, this can hold a checksum and its type if it is
    //   computed during discovery for some reason.
    // In the remote tree, this will have the server checksum, if available.
    // In both cases, the format is "SHA1:baff".
    string checksum_header;
    string e2e_mangled_name;

    CSyncEnums.CsyncStatus error_status = CsyncStatus.OK;

    SyncInstructions instruction = SyncInstructions.NONE; // u32

    CSyncFileStatS () {
        type = ItemType.SKIP;
        child_modified = false;
        has_ignored_files = false;
        is_hidden = false;
        is_e2e_encrypted = false;
    }
}

} // namespace CSync
