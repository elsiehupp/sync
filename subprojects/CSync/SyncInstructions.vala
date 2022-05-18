namespace Occ {
namespace CSync {

/***********************************************************
@enum SyncInstructions

@brief Instruction enum. In the file traversal structure, it
describes the csync state of a file.

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/
public enum SyncInstructions {

    /***********************************************************
    Nothing to do (UPDATE|RECONCILE).
    ***********************************************************/
    NONE              = 0,
    
    /***********************************************************
    There was changed compared to the database (UPDATE).
    ***********************************************************/
    EVAL              = 1 << 0,
    
    /***********************************************************
    The file needs to be removed (RECONCILE).
    ***********************************************************/
    REMOVE            = 1 << 1,
    
    /***********************************************************
    The file needs to be renamed (RECONCILE).
    ***********************************************************/
    RENAME            = 1 << 2,
    
    /***********************************************************
    The file is new, and it is the destination of a rename
    (UPDATE).
    ***********************************************************/
    EVAL_RENAME       = 1 << 11,
    
    /***********************************************************
    The file is new compared to the database (UPDATE).
    ***********************************************************/
    NEW               = 1 << 3,
    
    /***********************************************************
    The file needs to be downloaded because it is a conflict
    (RECONCILE).
    ***********************************************************/
    CONFLICT          = 1 << 4,
    
    /***********************************************************
    The file is ignored (UPDATE|RECONCILE).
    ***********************************************************/
    IGNORE            = 1 << 5,
    
    /***********************************************************
    The file needs to be pushed to the other remote (RECONCILE).
    ***********************************************************/
    SYNC              = 1 << 6,
    
    /***********************************************************
    ***********************************************************/
    STAT_ERROR        = 1 << 7,


    /***********************************************************
    ***********************************************************/
    ERROR             = 1 << 8,

    /***********************************************************
    Like NEW, but deletes the old entity first (RECONCILE). Used
    when the type of something changes from directory to file
    or back.
    ***********************************************************/
    TYPE_CHANGE       = 1 << 9,
    
    /***********************************************************
    If the etag has been updated and needs to be writen to the
    database, but without any propagation (UPDATE|RECONCILE).
    ***********************************************************/
    UPDATE_METADATA   = 1 << 10,} // enum SyncInstructions

} // enum SyncInstructions

} // namespace CSync
} // namespace Occ
                            