namespace Occ {
namespace CSync {

/***********************************************************
@enum SyncStatus

@brief

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/
public enum SyncStatus {
    OK               = 0,

    // don't use this code
    ERROR            = 1024,

    // Unspecific problem happend
    UNSUCCESSFUL,          // Statedatabase can not be loaded.
    STATEDB_LOAD_ERROR,    // general update or discovery error
    UPDATE_ERROR,          // UNUSED
    TIMEOUT,               // UNUSED
    HTTP_ERROR,                 PERMISSION_DENIED,
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

} // enum SyncStatus

} // namespace CSync
} // namespace Occ
