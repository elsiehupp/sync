namespace Occ {
namespace LibSync {

/***********************************************************
@class LocalInfo

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class LocalInfo : GLib.Object {
    /***********************************************************
    FileName of the entry (this does not contains any directory
    or path, just the plain name)
    ***********************************************************/
    public string name;
    public string rename_name;
    public time_t modtime = 0;
    public int64 size = 0;
    public uint64 inode = 0;
    public ItemType type = ItemType.SKIP;
    public bool is_directory = false;
    public bool is_hidden = false;
    public bool is_virtual_file = false;
    public bool is_sym_link = false;

    public bool is_valid {
        public get {
            return name != null;
        }
    }

} // class LocalInfo

} // namespace LibSync
} // namespace Occ