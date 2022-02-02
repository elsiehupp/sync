/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using CSync;
namespace Occ {

struct LocalInfo {
    /***********************************************************
    FileName of the entry (this does not contains any directory or path, just the plain name
    ***********************************************************/
    string name;
    string rename_name;
    time_t modtime = 0;
    int64_t size = 0;
    uint64_t inode = 0;
    ItemType type = ItemTypeSkip;
    bool is_directory = false;
    bool is_hidden = false;
    bool is_virtual_file = false;
    bool is_sym_link = false;
    bool is_valid () {
        return !name.is_null ();
    }
};