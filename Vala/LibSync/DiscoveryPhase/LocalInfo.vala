/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using CSync;

namespace Occ {
namespace LibSync {

public class LocalInfo : GLib.Object {
    /***********************************************************
    FileName of the entry (this does not contains any directory
    or path, just the plain name)
    ***********************************************************/
    string name;
    string rename_name;
    time_t modtime = 0;
    int64 size = 0;
    uint64 inode = 0;
    ItemType type = ItemType.SKIP;
    bool is_directory = false;
    bool is_hidden = false;
    bool is_virtual_file = false;
    bool is_sym_link = false;


    bool is_valid () {
        return !name.is_null ();
    }

} // class LocalInfo

} // namespace LibSync
} // namespace Occ