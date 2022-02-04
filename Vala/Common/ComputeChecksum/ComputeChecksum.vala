/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <qtconcurrentrun.h>
//  #include <QCryptographicHash>


//  #pragma once
//  #include <QFuture_watcher>
//  #include <memory>

using ZLib;
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


/***********************************************************
Computes the checksum of a file.
\ingroup libsync
***********************************************************/
class ComputeChecksum : ComputeChecksumBase {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.checksum_type;

    // watcher for the checksum calculation thread
    private QFuture_watcher<GLib.ByteArray> this.watcher;

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
        this.checksum_type = type;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray checksum_type () {
        return this.checksum_type;
    }


    /***********************************************************
    Computes the checksum for the given file path.

    on_done () is emitted when the calculation finishes.
    ***********************************************************/
    public void on_start (string file_path) {
        GLib.Info (lc_checksums) << "Computing" << checksum_type () << "checksum of" << file_path << "in a thread";
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
        GLib.Info (lc_checksums) << "Computing" << checksum_type () << "checksum of device" << device.get () << "in a thread";
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
        GLib.ByteArray checksum = this.watcher.future ().result ();
        if (!checksum.is_null ()) {
            /* emit */ done (this.checksum_type, checksum);
        } else {
            /* emit */ done (GLib.ByteArray (), GLib.ByteArray ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_impl (std.unique_ptr<QIODevice> device) {
        connect (&this.watcher, &QFuture_watcher_base.on_finished,
            this, &ComputeChecksum.on_calculation_done,
            Qt.UniqueConnection);

        // We'd prefer to move the unique_ptr into the lambda, but that's
        // awkward with the C++ standard we're on
        var shared_device = unowned<QIODevice> (device.release ());

        // Bug : The thread will keep running even if ComputeChecksum is deleted.
        var type = checksum_type ();
        this.watcher.set_future (Qt_concurrent.run ([shared_device, type] () {
            if (!shared_device.open (QIODevice.ReadOnly)) {
                if (var file = qobject_cast<GLib.File> (shared_device.data ())) {
                    GLib.warn (lc_checksums) << "Could not open file" << file.filename ()
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

} // namespace Occ
