namespace Occ {
namespace LibSync {

/***********************************************************
@class RemoteInfo

@brief Represent all the meta-data about a file in the server

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class RemoteInfo : GLib.Object {
    /***********************************************************
    FileName of the entry (this does not contains any directory
    or path, just the plain name).
    ***********************************************************/
    public string name;
    public string etag;
    public public string file_identifier;
    public string checksum_header;
    public RemotePermissions remote_permissions;
    public time_t modtime = 0;
    public int64 size = 0;
    public int64 size_of_folder = 0;
    public bool is_directory = false;
    public bool is_e2e_encrypted = false;
    public string e2e_mangled_name;
    public string direct_download_url;
    public string direct_download_cookies;

    public bool is_valid {
        public get {
            return name != null;
        }
    }

} // class RemoteInfo

} // namespace LibSync
} // namespace Occ