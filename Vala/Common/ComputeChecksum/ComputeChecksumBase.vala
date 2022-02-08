/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using ZLib;
namespace Occ {

abstract class ComputeChecksumBase : GLib.Object {

    /***********************************************************
    Tags for checksum headers values.
    They are here for being shared between Upload- and Download Job
    ***********************************************************/
    const string CHECKSUM_MD5C = "MD5";
    const string CHECKSUM_SHA1C = "SHA1";
    const string CHECKSUM_SHA2C = "SHA256";
    const string CHECKSUM_SHA3C = "SHA3-256";
    const string CHECKSUM_ADLER_C = "Adler32";


    const int64 BUFSIZE = 500 * 1024; // 500 KiB


    /***********************************************************
    Returns the highest-quality checksum in a 'checksums'
    property retrieved from the server.

    Example: "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
        . "SHA1:ab124124"
    

    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray find_best_checksum (GLib.ByteArray this.checksums) {
        if (this.checksums.is_empty ()) {
            return {};
        }
        const var checksums = string.from_utf8 (this.checksums);
        int i = 0;
        // The order of the searches here defines the preference ordering.
        if (-1 != (i = checksums.index_of ("SHA3-256:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA256:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA1:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("MD5:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("ADLER32:", 0, Qt.CaseInsensitive))) {
            // Now i is the on_signal_start of the best checksum
            // Grab it until the next space or end of xml or end of string.
            int end = this.checksums.index_of (' ', i);
            // workaround for https://github.com/owncloud/core/pull/38304
            if (end == -1) {
                end = this.checksums.index_of ('<', i);
            }
            return this.checksums.mid (i, end - i);
        }
        GLib.warn ("Failed to parse" + this.checksums;
        return {};
    }


    /***********************************************************
    Creates a checksum header from type and value.
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray make_checksum_header (GLib.ByteArray checksum_type, GLib.ByteArray checksum) {
        if (checksum_type.is_empty () || checksum.is_empty ())
            return GLib.ByteArray ();
        GLib.ByteArray header = checksum_type;
        header.append (':');
        header.append (checksum);
        return header;
    }


    /***********************************************************
    Parses a checksum header
    OCSYNC_EXPORT
    ***********************************************************/
    bool parse_checksum_header (GLib.ByteArray header, GLib.ByteArray type, GLib.ByteArray checksum) {
        if (header.is_empty ()) {
            type.clear ();
            checksum.clear ();
            return true;
        }

        const var index = header.index_of (':');
        if (index < 0) {
            return false;
        }

        *type = header.left (index);
        *checksum = header.mid (index + 1);
        return true;
    }


    /***********************************************************
    Convenience for getting the type from a checksum header, null if none
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray parse_checksum_header_type (GLib.ByteArray header) {
        const var index = header.index_of (':');
        if (index < 0) {
            return GLib.ByteArray ();
        }
        return header.left (index);
    }


    /***********************************************************
    Checks OWNCLOUD_DISABLE_CHECKSUM_UPLOAD
    OCSYNC_EXPORT
    ***********************************************************/
    bool upload_checksum_enabled () {
        static bool enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
        return enabled;
    }



    /***********************************************************
    Exported functions for the tests.
    ***********************************************************/


    /***********************************************************
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray calc_md5 (QIODevice device) {
        return calc_crypto_hash (device, QCryptographicHash.Md5);
    }


    /***********************************************************
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray calc_sha1 (QIODevice device) {
        return calc_crypto_hash (device, QCryptographicHash.Sha1);
    }


    /***********************************************************
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray calc_adler32 (QIODevice device) {
        if (device.size () == 0) {
            return GLib.ByteArray ();
        }
        GLib.ByteArray buf (BUFSIZE, Qt.Uninitialized);

        uint32 adler = adler32 (0L, Z_NULL, 0);
        int64 size = 0;
        while (!device.at_end ()) {
            size = device.read (buf.data (), BUFSIZE);
            if (size > 0)
                adler = adler32 (adler, (Bytef *)buf.data (), size);
        }

        return GLib.ByteArray.number (adler, 16);
    }


    /***********************************************************
    ***********************************************************/
    static GLib.ByteArray calc_crypto_hash (QIODevice device, QCryptographicHash.Algorithm algo) {
        GLib.ByteArray arr;
        QCryptographicHash crypto ( algo );

        if (crypto.add_data (device)) {
            arr = crypto.result ().to_hex ();
        }
        return arr;
    }
    

    /***********************************************************
    ***********************************************************/
    static bool checksum_computation_enabled () {
        static bool enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_COMPUTATIONS");
        return enabled;
    }
}