namespace Occ {
namespace CSync {

/***********************************************************
@enum ItemType

@brief This enum is used with BITFIELD (3) and BITFIELD (4)
in several places. Also, this value is stored in the
database, so beware of value changes.

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/
public enum ItemType {
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

} // enum ItemType

} // namespace CSync
} // namespace Occ
