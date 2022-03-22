namespace Occ {
namespace Common {

/***********************************************************
@class CSyncChecksumHook

@brief Hooks checksum computations into csync

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class CSyncChecksumHook : ComputeChecksumBase {

    using ZLib;

    /***********************************************************
    Returns the checksum value for \a path that is comparable to \a other_checksum.

    Called from csync, whe
    to be set as userdata.
    The return value will be owned by csync.
    ***********************************************************/
    public static string hook (string path, string other_checksum_header, void this_obj) {
        string type = parse_checksum_header_type (other_checksum_header);
        if (type == "") {
            return null;
        }

        GLib.info ("Computing " + type + " checksum of " + path + " in the csync hook.");
        string checksum = ComputeChecksum.compute_now_on_signal_file (string.from_utf8 (path), type);
        if (checksum == null) {
            GLib.warning ("Failed to compute checksum " + type + " for " + path);
            return null;
        }

        return make_checksum_header (type, checksum);
    }

} // class CSyncChecksumHook

} // namespace Common
} // namespace Occ
