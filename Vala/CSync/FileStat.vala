namespace Occ {
namespace CSync {

/***********************************************************
@class CSyncFileStatS

@brief CSync public API

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2012-2013 by Klaas Freitag <freitag@owncloud.co

@copyright LGPL 2.1 or later
***********************************************************/
public class CSyncFileStatS : GLib.Object {

    //  struct CSyncFileStatS : CSyncFileStatT {}

    //  #if defined (Q_CC_GNU) && !defined (Q_CC_INTEL) && !defined (Q_CC_CLANG) && (__GNUC__ * 100 + __GNUC_MINOR__ < 408)
    // open_suse 12.3 didn't like enum bitfields.
    //  const int BITFIELD (size)
    //  #elif defined (Q_CC_MSVC)
    // MSVC stores enum and bool as signed, so we need to add a bit for the sign
    //  const int BITFIELD (size) : (size+1)
    //  #else
    //  const int BITFIELD (size) : size
    //  #endif

    public time_t modtime = 0;
    public int64 size = 0;
    public uint64 inode = 0;

    public RemotePermissions remote_perm;
    public ItemType type = BITFIELD (4);
    public bool child_modified = BITFIELD (1);
    public bool has_ignored_files = BITFIELD (1); // Specify that a directory, or child directory contains ignored files.
    public bool is_hidden = BITFIELD (1); // Not saved in the DB, only used during discovery for local files.
    public bool is_e2e_encrypted = BITFIELD (1);

    public string path;
    public string rename_path;
    public string etag;
    public string file_id;
    public string direct_download_url;
    public string direct_download_cookies;
    public string original_path; // only set if locale conversion fails

    // In the local tree, this can hold a checksum and its type if it is
    //   computed during discovery for some reason.
    // In the remote tree, this will have the server checksum, if available.
    // In both cases, the format is "SHA1:baff".
    public string checksum_header;
    public string e2e_mangled_name;

    public CSyncEnums.SyncStatus error_status = SyncStatus.OK;

    public SyncInstructions instruction = SyncInstructions.NONE; // u32

    public CSyncFileStatS () {
        this.type = ItemType.SKIP;
        this.child_modified = false;
        this.has_ignored_files = false;
        this.is_hidden = false;
        this.is_e2e_encrypted = false;
    }

} // class CSyncFileStatS

} // namespace CSync
} // namespace Occ
