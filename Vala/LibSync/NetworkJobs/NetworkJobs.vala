namespace Occ {
namespace LibSync {

/***********************************************************
@brief Strips quotes and gzip annotations

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
string parse_etag (char *header) {
    if (header == null) {
        return "";
    }
    string arr = header.to_string ();

    // Weak E-Tags can appear when gzip compression is on, see #3946
    if (arr.starts_with ("W/"))
        arr = arr.mid (2);

    // https://github.com/owncloud/client/issues/1195
    arr.replace ("-gzip", "");

    if (arr.length >= 2 && arr.starts_with ('"') && arr.has_suffix ('"')) {
        arr = arr.mid (1, arr.length - 2);
    }
    return arr;
}

struct HttpError {
    int code; // HTTP error code
    string message;
}


struct HttpResult : Result<T, HttpError> { }


struct ExtraFolderInfo {
    string file_identifier;
    int64 size = -1;
}

} // namespace LibSync
} // namespace Occ
