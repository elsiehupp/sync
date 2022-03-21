/***********************************************************
@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <sys/xattr.h>

namespace Occ {
namespace LibSync {

public class XAttrWrapper : GLib.Object {

    const string HYDRATE_EXEC_ATTRIBUT_NAME = "user.nextcloud.hydrate_exec";

    public static bool has_nextcloud_placeholder_attributes (string path) {
        var value = xattr_get (path.to_utf8 (), HYDRATE_EXEC_ATTRIBUT_NAME);
        if (value) {
            return value == APPLICATION_EXECUTABLE;
        } else {
            return false;
        }
    }


    public static Result<void, string> add_nextcloud_placeholder_attributes (string path) {
        var on_signal_success = xattr_set (path.to_utf8 (), HYDRATE_EXEC_ATTRIBUT_NAME, APPLICATION_EXECUTABLE);
        if (!on_signal_success) {
            return new Result<void, string> ("Failed to set the extended attribute");
        } else {
            return new Result<void, string> ();
        }
    }


    public static Optional<string> xattr_get (string path, string name) {
        const int BUFFER_SIZE = 256;
        string result;
        result.resize (BUFFER_SIZE);
        var count = getxattr (path.const_data (), name.const_data (), result, BUFFER_SIZE);
        if (count >= 0) {
            result.resize (static_cast<int> (count) - 1);
            return result;
        } else {
            return {};
        }
    }


    public static bool xattr_set (string path, string name, string value) {
        var return_code = setxattr (path.const_data (), name.const_data (), value.const_data (), value.size () + 1, 0);
        return return_code == 0;
    }

} // class XAttrWrapper

} // namespace LibSync
} // namespace Occ
