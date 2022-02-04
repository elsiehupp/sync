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
class CSyncChecksumHook : ComputeChecksumBase {

    /***********************************************************
    ***********************************************************/
    public CSyncChecksumHook () = default;

    /***********************************************************
    Returns the checksum value for \a path that is comparable to \a other_checksum.

    Called from csync, whe
    to be set as userdata.
    The return value will be owned by csync.
    ***********************************************************/
    public static GLib.ByteArray hook (GLib.ByteArray path, GLib.ByteArray other_checksum_header, void this_obj) {
        GLib.ByteArray type = parse_checksum_header_type (GLib.ByteArray (other_checksum_header));
        if (type.is_empty ())
            return null;

        GLib.Info (lc_checksums) << "Computing" << type << "checksum of" << path << "in the csync hook";
        GLib.ByteArray checksum = ComputeChecksum.compute_now_on_file (string.from_utf8 (path), type);
        if (checksum.is_null ()) {
            GLib.warn (lc_checksums) << "Failed to compute checksum" << type << "for" << path;
            return null;
        }

        return make_checksum_header (type, checksum);
    }
}