namespace Occ {
namespace Common {

/***********************************************************
@class AbstractComputeChecksum

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
abstract class AbstractComputeChecksum : GLib.Object {

    using ZLib;

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

    private static bool enabled;

    /***********************************************************
    Returns the highest-quality checksum in a 'checksums'
    property retrieved from the server.

    Example: "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
        . "SHA1:ab124124"


    ***********************************************************/
    string find_best_checksum (string checksums) {
        if (checksums == "") {
            return "";
        }
        int i = 0;
        // The order of the searches here defines the preference ordering.
        if (-1 != (i = checksums.index_of ("SHA3-256:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA256:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA1:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("MD5:", 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of ("ADLER32:", 0, Qt.CaseInsensitive))) {
            // Now i is the on_signal_start of the best checksum
            // Grab it until the next space or end of xml or end of string.
            int end = checksums.index_of (' ', i);
            // workaround for https://github.com/owncloud/core/pull/38304
            if (end == -1) {
                end = checksums.index_of ('<', i);
            }
            return checksums.mid (i, end - i);
        }
        GLib.warning ("Failed to parse " + checksums);
        return "";
    }


    /***********************************************************
    Creates a checksum header from type and value.
    ***********************************************************/
    string make_checksum_header (string checksum_type, string checksum) {
        if (checksum_type == "" || checksum == "") {
            return "";
        }
        string header = checksum_type;
        header += ":";
        header += checksum;
        return header;
    }


    /***********************************************************
    Parses a checksum header
    ***********************************************************/
    bool parse_checksum_header (string header, string type, string checksum) {
        if (header == "") {
            type == "";
            checksum == "";
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
    ***********************************************************/
    string parse_checksum_header_type (string header) {
        const var index = header.index_of (':');
        if (index < 0) {
            return "";
        }
        return header.left (index);
    }


    /***********************************************************
    Checks OWNCLOUD_DISABLE_CHECKSUM_UPLOAD
    ***********************************************************/
    bool upload_checksum_enabled () {
        AbstractComputeChecksum.enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
        return AbstractComputeChecksum.enabled;
    }



    /***********************************************************
    Exported functions for the tests.
    ***********************************************************/


    /***********************************************************
    ***********************************************************/
    string calc_md5 (QIODevice device) {
        return calc_crypto_hash (device, QCryptographicHash.Md5);
    }


    /***********************************************************
    ***********************************************************/
    string calc_sha1 (QIODevice device) {
        return calc_crypto_hash (device, QCryptographicHash.Sha1);
    }


    /***********************************************************
    ***********************************************************/
    string calc_adler32 (QIODevice device) {
        if (device.length == 0) {
            return "";
        }
        string buf = string (BUFSIZE, Qt.Uninitialized);

        uint32 adler = adler32 (0L, Z_NULL, 0);
        int64 size = 0;
        while (!device.at_end ()) {
            size = device.read (buf, BUFSIZE);
            if (size > 0)
                adler = adler32 (adler, (Bytef *)buf, size);
        }

        return string.number (adler, 16);
    }


    /***********************************************************
    ***********************************************************/
    static string calc_crypto_hash (QIODevice device, QCryptographicHash.Algorithm algo) {
        string arr;
        QCryptographicHash crypto = new QCryptographicHash (algo);

        if (crypto.add_data (device)) {
            arr = crypto.result ().to_hex ();
        }
        return arr;
    }


    /***********************************************************
    ***********************************************************/
    static bool checksum_computation_enabled () {
        AbstractComputeChecksum.enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_COMPUTATIONS");
        return AbstractComputeChecksum.enabled;
    }

} // class AbstractComputeChecksum

} // namespace Common
} // namespace Occ
