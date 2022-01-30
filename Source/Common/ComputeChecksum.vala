/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <qtconcurrentrun.h>
// #include <QCryptographicHash>

using ZLib;

// #pragma once
// #include <QFuture_watcher>
// #include <memory>

namespace Occ {

/***********************************************************
\file checksums

\brief Computing and validating file checksums

Overview
--------

Checksums are used in two

- to guard uploads and downloads against data corr
  (transmission checksum)
- to quickly check whether the content of a file has changed
  to avoid redundant uploads (content checksum)

In principle both are ind
algorithms can be used. To avoid redundant computations, it can
make sense to use the same checksum algorithm though.

Transmission Checksums
----------------------

The usage of transmission checksums is currently optional and need
to be explic
the '[General]' section of the config file.

When enabled, the
the server in the OC

On download, the header with the same name is read and if the
received data does not have the expected checksum, the download is
rejected.

Transmission checks
in the database.

Conte
------

Sometimes the metadata of a local file changes while the content stays
unchanged. Content checksums allow the sync client to avoid uploading
the same data again by comparing the file's actual checksum to the
checksum stored in the database.

Content checksums a

Checksum Algorithms
-----

- Adler3
- MD5
- SHA1
- SHA256
- SHA3-256 (requires Qt 5.9)

***********************************************************/
abstract class ComputeChecksumBase : GLib.Object {

    /***********************************************************
    Tags for checksum headers values.
    They are here for being shared between Upload- and Download Job
    ***********************************************************/
    const char[] CHECKSUM_MD5C = "MD5";
    const char[] CHECKSUM_SHA1C = "SHA1";
    const char[] CHECKSUM_SHA2C = "SHA256";
    const char[] CHECKSUM_SHA3C = "SHA3-256";
    const char[] CHECKSUM_ADLER_C = "Adler32";


    const int BUFSIZE int64 (500 * 1024) // 500 KiB


    /***********************************************************
    Returns the highest-quality checksum in a 'checksums'
    property retrieved from the server.

    Example: "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
        . "SHA1:ab124124"
    

    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray find_best_checksum (GLib.ByteArray _checksums) {
        if (_checksums.is_empty ()) {
            return {};
        }
        const var checksums = string.from_utf8 (_checksums);
        int i = 0;
        // The order of the searches here defines the preference ordering.
        if (-1 != (i = checksums.index_of (QLatin1String ("SHA3-256:"), 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of (QLatin1String ("SHA256:"), 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of (QLatin1String ("SHA1:"), 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of (QLatin1String ("MD5:"), 0, Qt.CaseInsensitive))
            || -1 != (i = checksums.index_of (QLatin1String ("ADLER32:"), 0, Qt.CaseInsensitive))) {
            // Now i is the on_start of the best checksum
            // Grab it until the next space or end of xml or end of string.
            int end = _checksums.index_of (' ', i);
            // workaround for https://github.com/owncloud/core/pull/38304
            if (end == -1) {
                end = _checksums.index_of ('<', i);
            }
            return _checksums.mid (i, end - i);
        }
        GLib.warn (lc_checksums) << "Failed to parse" << _checksums;
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

        const var idx = header.index_of (':');
        if (idx < 0) {
            return false;
        }

        *type = header.left (idx);
        *checksum = header.mid (idx + 1);
        return true;
    }


    /***********************************************************
    Convenience for getting the type from a checksum header, null if none
    OCSYNC_EXPORT
    ***********************************************************/
    GLib.ByteArray parse_checksum_header_type (GLib.ByteArray header) {
        const var idx = header.index_of (':');
        if (idx < 0) {
            return GLib.ByteArray ();
        }
        return header.left (idx);
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


/***********************************************************
Computes the checksum of a file.
\ingroup libsync
***********************************************************/
class ComputeChecksum : ComputeChecksumBase {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray _checksum_type;

    // watcher for the checksum calculation thread
    private QFuture_watcher<GLib.ByteArray> _watcher;

    /***********************************************************
    ***********************************************************/
    public ComputeChecksum (GLib.Object parent = new GLib.Object ()) {
        GLib.Object (parent);
    }


    ~ComputeChecksum () = default;


    /***********************************************************
    Sets the checksum type to be used. The default is empty.
    ***********************************************************/
    public void set_checksum_type (GLib.ByteArray type) {
        _checksum_type = type;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray checksum_type () {
        return _checksum_type;
    }


    /***********************************************************
    Computes the checksum for the given file path.

    on_done () is emitted when the calculation finishes.
    ***********************************************************/
    public void on_start (string file_path) {
        q_c_info (lc_checksums) << "Computing" << checksum_type () << "checksum of" << file_path << "in a thread";
        start_impl (std.make_unique<GLib.File> (file_path));
    }


    /***********************************************************
    Computes the checksum for the given device.

    on_done () is emitted when the calculation finishes.

    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void on_start (std.unique_ptr<QIODevice> device) {
        ENFORCE (device);
        q_c_info (lc_checksums) << "Computing" << checksum_type () << "checksum of device" << device.get () << "in a thread";
        ASSERT (!device.parent ());

        start_impl (std.move (device));
    }


    /***********************************************************
    Computes the checksum synchronously.
    ***********************************************************/
    public static GLib.ByteArray compute_now (QIODevice device, GLib.ByteArray checksum_type) {
        if (!checksum_computation_enabled ()) {
            GLib.warn (lc_checksums) << "Checksum computation disabled by environment variable";
            return GLib.ByteArray ();
        }

        if (checksum_type == CHECKSUM_MD5C) {
            return calc_md5 (device);
        } else if (checksum_type == CHECKSUM_SHA1C) {
            return calc_sha1 (device);
        } else if (checksum_type == CHECKSUM_SHA2C) {
            return calc_crypto_hash (device, QCryptographicHash.Sha256);
        }
    #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
        else if (checksum_type == CHECKSUM_SHA3C) {
            return calc_crypto_hash (device, QCryptographicHash.Sha3_256);
        }
    #endif
    #ifdef ZLIB_FOUND
        else if (checksum_type == CHECKSUM_ADLER_C) {
            return calc_adler32 (device);
        }
    #endif
        // for an unknown checksum or no checksum, we're done right now
        if (!checksum_type.is_empty ()) {
            GLib.warn (lc_checksums) << "Unknown checksum type:" << checksum_type;
        }
        return GLib.ByteArray ();
    }


    /***********************************************************
    Computes the checksum synchronously on file. Convenience wrapper for compute_now ().
    ***********************************************************/
    public static GLib.ByteArray compute_now_on_file (string file_path, GLib.ByteArray checksum_type) {
        GLib.File file = new GLib.File (file_path);
        if (!file.open (QIODevice.ReadOnly)) {
            GLib.warn (lc_checksums) << "Could not open file" << file_path << "for reading and computing checksum" << file.error_string ();
            return GLib.ByteArray ();
        }

        return compute_now (&file, checksum_type);
    }


    signal void done (GLib.ByteArray checksum_type, GLib.ByteArray checksum);


    /***********************************************************
    ***********************************************************/
    private void on_calculation_done () {
        GLib.ByteArray checksum = _watcher.future ().result ();
        if (!checksum.is_null ()) {
            emit done (_checksum_type, checksum);
        } else {
            emit done (GLib.ByteArray (), GLib.ByteArray ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_impl (std.unique_ptr<QIODevice> device) {
        connect (&_watcher, &QFuture_watcher_base.on_finished,
            this, &ComputeChecksum.on_calculation_done,
            Qt.UniqueConnection);

        // We'd prefer to move the unique_ptr into the lambda, but that's
        // awkward with the C++ standard we're on
        var shared_device = unowned<QIODevice> (device.release ());

        // Bug : The thread will keep running even if ComputeChecksum is deleted.
        var type = checksum_type ();
        _watcher.set_future (Qt_concurrent.run ([shared_device, type] () {
            if (!shared_device.open (QIODevice.ReadOnly)) {
                if (var file = qobject_cast<GLib.File> (shared_device.data ())) {
                    GLib.warn (lc_checksums) << "Could not open file" << file.file_name ()
                            << "for reading to compute a checksum" << file.error_string ();
                } else {
                    GLib.warn (lc_checksums) << "Could not open device" << shared_device.data ()
                            << "for reading to compute a checksum" << shared_device.error_string ();
                }
                return GLib.ByteArray ();
            }
            var result = ComputeChecksum.compute_now (shared_device.data (), type);
            shared_device.close ();
            return result;
        }));
    }
}

/***********************************************************
Checks whether a file's checksum matches the expected value.
@ingroup libsync
***********************************************************/
class ValidateChecksumHeader : ComputeChecksumBase {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray _expected_checksum_type;
    private GLib.ByteArray _expected_checksum;

    /***********************************************************
    ***********************************************************/
    public ValidateChecksumHeader (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    Check a file's actual checksum against the provided
    checksum_header

    If no checksum is there, or if a correct checksum is there,
    the signal validated () will be emitted. In case of any kind
    of error, the signal validation_failed () will be emitted.
    ***********************************************************/
    public void on_start (string file_path, GLib.ByteArray checksum_header) {
        if (var calculator = prepare_start (checksum_header))
            calculator.on_start (file_path);
    }


    /***********************************************************
    Check a device's actual checksum against the provided checksum_header

    Like the other on_start () but works on a device.

    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void on_start (std.unique_ptr<QIODevice> device, GLib.ByteArray checksum_header) {
        if (var calculator = prepare_start (checksum_header))
            calculator.on_start (std.move (device));
    }


    signal void validated (GLib.ByteArray checksum_type, GLib.ByteArray checksum);
    signal void validation_failed (string error_message);


    /***********************************************************
    ***********************************************************/
    private void on_checksum_calculated (GLib.ByteArray checksum_type, GLib.ByteArray checksum) {
        if (checksum_type != _expected_checksum_type) {
            emit validation_failed (_("The checksum header contained an unknown checksum type \"%1\"").arg (string.from_latin1 (_expected_checksum_type)));
            return;
        }
        if (checksum != _expected_checksum) {
            emit validation_failed (_(R" (The downloaded file does not match the checksum, it will be resumed. "%1" != "%2")").arg (string.from_utf8 (_expected_checksum), string.from_utf8 (checksum)));
            return;
        }
        emit validated (checksum_type, checksum);
    }


    /***********************************************************
    ***********************************************************/
    private ComputeChecksum prepare_start (GLib.ByteArray checksum_header) {
        // If the incoming header is empty no validation can happen. Just continue.
        if (checksum_header.is_empty ()) {
            emit validated (GLib.ByteArray (), GLib.ByteArray ());
            return nullptr;
        }

        if (!parse_checksum_header (checksum_header, &_expected_checksum_type, &_expected_checksum)) {
            GLib.warn (lc_checksums) << "Checksum header malformed:" << checksum_header;
            emit validation_failed (_("The checksum header is malformed."));
            return nullptr;
        }

        var calculator = new ComputeChecksum (this);
        calculator.set_checksum_type (_expected_checksum_type);
        connect (calculator, &ComputeChecksum.done,
            this, &ValidateChecksumHeader.on_checksum_calculated);
        return calculator;
    }
}

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
            return nullptr;

        q_c_info (lc_checksums) << "Computing" << type << "checksum of" << path << "in the csync hook";
        GLib.ByteArray checksum = ComputeChecksum.compute_now_on_file (string.from_utf8 (path), type);
        if (checksum.is_null ()) {
            GLib.warn (lc_checksums) << "Failed to compute checksum" << type << "for" << path;
            return nullptr;
        }

        return make_checksum_header (type, checksum);
    }
}

} // namespace Occ
