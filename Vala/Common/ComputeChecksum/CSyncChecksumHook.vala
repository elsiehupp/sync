/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using ZLib;

namespace Occ {

/***********************************************************
Hooks checksum computations into csync.
@ingroup libsync
***********************************************************/
public class CSyncChecksumHook : ComputeChecksumBase {

    /***********************************************************
    Returns the checksum value for \a path that is comparable to \a other_checksum.

    Called from csync, whe
    to be set as userdata.
    The return value will be owned by csync.
    ***********************************************************/
    public static string hook (string path, string other_checksum_header, void this_obj) {
        string type = parse_checksum_header_type (string (other_checksum_header));
        if (type == "") {
            return null;
        }

        GLib.info ("Computing " + type + " checksum of " + path + " in the csync hook.");
        string checksum = ComputeChecksum.compute_now_on_signal_file (string.from_utf8 (path), type);
        if (checksum.is_null ()) {
            GLib.warning ("Failed to compute checksum " + type + " for " + path);
            return null;
        }

        return make_checksum_header (type, checksum);
    }

}

} // namespace Occ