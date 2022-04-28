using ZLib;

namespace Occ {
namespace Common {

/***********************************************************
@class AbstractComputeChecksum

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public abstract class AbstractComputeChecksum : GLib.Object {

    /***********************************************************
    Tags for checksum headers values.
    They are here for being shared between Upload- and Download Job
    ***********************************************************/
    protected const string CHECKSUM_MD5C = "MD5";
    protected const string CHECKSUM_SHA1C = "SHA1";
    protected const string CHECKSUM_SHA2C = "SHA256";
    protected const string CHECKSUM_SHA3C = "SHA3-256";
    protected const string CHECKSUM_ADLER_C = "Adler32";

    protected const int64 BUFSIZE = 500 * 1024; // 500 KiB

    protected static bool enabled;

    protected AbstractComputeChecksum (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }

    /***********************************************************
    Returns the highest-quality checksum in a 'checksums'
    property retrieved from the server.

    Example: "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
        . "SHA1:ab124124"


    ***********************************************************/
    protected static string find_best_checksum (string checksums) {
        if (checksums == "") {
            return "";
        }
        int i = 0;
        // The order of the searches here defines the preference ordering.
        if (-1 != (i = checksums.index_of ("SHA3-256:", 0, GLib.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA256:", 0, GLib.CaseInsensitive))
            || -1 != (i = checksums.index_of ("SHA1:", 0, GLib.CaseInsensitive))
            || -1 != (i = checksums.index_of ("MD5:", 0, GLib.CaseInsensitive))
            || -1 != (i = checksums.index_of ("ADLER32:", 0, GLib.CaseInsensitive))) {
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
    protected static string make_checksum_header (string checksum_type, string checksum_string) {
        if (checksum_type == "" || checksum_string == "") {
            return "";
        }
        string header = checksum_type;
        header += ":";
        header += checksum_string;
        return header;
    }


    /***********************************************************
    Parses a checksum header
    ***********************************************************/
    protected static bool parse_checksum_header (string header, string type, string checksum_string) {
        if (header == "") {
            type == "";
            checksum_string == "";
            return true;
        }

        var index = header.index_of (":");
        if (index < 0) {
            return false;
        }

        *type = header.left (index);
        *checksum_string = header.mid (index + 1);
        return true;
    }


    /***********************************************************
    Convenience for getting the type from a checksum header, null if none
    ***********************************************************/
    protected static string parse_checksum_header_type (string header) {
        var index = header.index_of (":");
        if (index < 0) {
            return "";
        }
        return header.left (index);
    }


    /***********************************************************
    Checks OWNCLOUD_DISABLE_CHECKSUM_UPLOAD
    ***********************************************************/
    protected static bool upload_checksum_enabled () {
        string[]? envp;
        GLib.Environ.get_variable (envp, "OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
        AbstractComputeChecksum.enabled = envp.length == 0;
        return AbstractComputeChecksum.enabled;
    }



    /***********************************************************
    Exported functions for the tests.
    ***********************************************************/


    /***********************************************************
    ***********************************************************/
    protected static string calc_md5 (GLib.OutputStream device) {
        return calc_crypto_hash (device, GLib.ChecksumType.MD5);
    }


    /***********************************************************
    ***********************************************************/
    protected static string calc_sha1 (GLib.OutputStream device) {
        return calc_crypto_hash (device, GLib.ChecksumType.SHA1);
    }


    /***********************************************************
    ***********************************************************/
    protected static string calc_adler32 (GLib.OutputStream device) {
        if (device.length == 0) {
            return "";
        }
        string buf = new string (BUFSIZE, GLib.Uninitialized);

        uint32 adler = adler32 (0L, Z_NULL, 0);
        int64 size = 0;
        while (!device.at_end ()) {
            size = device.read (buf, BUFSIZE);
            if (size > 0) {
                adler = adler32 (adler, (Bytef *)buf, size);
            }
        }

        return string.number (adler, 16);
    }


    /***********************************************************
    ***********************************************************/
    protected static string calc_crypto_hash (GLib.OutputStream device, GLib.ChecksumType checksum_type) {
        string arr;
        GLib.Checksum checksum = new GLib.Checksum (checksum_type);

        if (checksum.add_data (device)) {
            arr = checksum.result ().to_hex ();
        }
        return arr;
    }


    /***********************************************************
    ***********************************************************/
    protected static bool checksum_computation_enabled () {
        string[]? envp;
        GLib.Environ.get_variable (envp, "OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
        AbstractComputeChecksum.enabled = envp.length == 0;
        return AbstractComputeChecksum.enabled;
    }

} // class AbstractComputeChecksum

} // namespace Common
} // namespace Occ
