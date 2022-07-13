namespace Occ {
namespace CSync {

/***********************************************************
@brief CSync public API

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/

/***********************************************************
Codes for file individual status
***********************************************************/
public enum IndividualFileStatus {
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

} // enum IndividualFileStatus

} // namespace CSync
} // namespace Occ
