/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using CSync;

namespace Occ {
namespace LibSync {

/***********************************************************
Represent all the meta-data about a file in the server
***********************************************************/
public class RemoteInfo : Glib.Object {
    /***********************************************************
    FileName of the entry (this does not contains any directory
    or path, just the plain name).
    ***********************************************************/
    string name;
    string etag;
    string file_identifier;
    string checksum_header;
    RemotePermissions remote_perm;
    time_t modtime = 0;
    int64 size = 0;
    int64 size_of_folder = 0;
    bool is_directory = false;
    bool is_e2e_encrypted = false;
    string e2e_mangled_name;
    string direct_download_url;
    string direct_download_cookies;


    bool is_valid () {
        return !name.is_null ();
    }

} // class RemoteInfo

} // namespace LibSync
} // namespace Occ