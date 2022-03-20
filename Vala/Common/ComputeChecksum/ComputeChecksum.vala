namespace Occ {

/***********************************************************
@class ComputeChecksum

@brief Computing and validating file checksums

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

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class ComputeChecksum : ComputeChecksumBase {

    using ZLib;

    /***********************************************************
    ***********************************************************/
    public string checksum_type;

    /***********************************************************
    Watcher for the checksum calculation thread
    ***********************************************************/
    private QFutureWatcher<string> watcher;

    /***********************************************************
    ***********************************************************/
    public ComputeChecksum (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    Computes the checksum for the given file path.

    on_signal_done () is emitted when the calculation finishes.
    ***********************************************************/
    public void start_for_path (string file_path) {
        GLib.info ("Computing " + this.checksum_type + " checksum of " + file_path + " in a thread.");
        start_impl (std.make_unique<GLib.File> (file_path));
    }


    /***********************************************************
    Computes the checksum for the given device.

    on_signal_done () is emitted when the calculation finishes.

    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void start_for_device (std.unique_ptr<QIODevice> device) {
        //  ENFORCE (device);
        GLib.info ("Computing " + this.checksum_type + " checksum of device " + device.get () + " in a thread.");
        //  ASSERT (!device.parent ());

        start_impl (std.move (device));
    }


    /***********************************************************
    Computes the checksum synchronously.
    ***********************************************************/
    public static string compute_now (QIODevice device, string checksum_type) {
        if (!checksum_computation_enabled ()) {
            GLib.warning ("Checksum computation disabled by environment variable.");
            return "";
        }

        if (checksum_type == CHECKSUM_MD5C) {
            return calc_md5 (device);
        } else if (checksum_type == CHECKSUM_SHA1C) {
            return calc_sha1 (device);
        } else if (checksum_type == CHECKSUM_SHA2C) {
            return calc_crypto_hash (device, QCryptographicHash.Sha256);
        }
    //  #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
        else if (checksum_type == CHECKSUM_SHA3C) {
            return calc_crypto_hash (device, QCryptographicHash.Sha3_256);
        }
    //  #endif
    //  #ifdef ZLIB_FOUND
        else if (checksum_type == CHECKSUM_ADLER_C) {
            return calc_adler32 (device);
        }
    //  #endif
        // for an unknown checksum or no checksum, we're done right now
        if (!checksum_type == "") {
            GLib.warning ("Unknown checksum type: " + checksum_type);
        }
        return "";
    }


    /***********************************************************
    Computes the checksum synchronously on file. Convenience wrapper for compute_now ().
    ***********************************************************/
    public static string compute_now_on_signal_file (string file_path, string checksum_type) {
        GLib.File file = GLib.File.new_for_path (file_path);
        if (!file.open (QIODevice.ReadOnly)) {
            GLib.warning ("Could not open file " + file_path + " for reading and computing checksum " + file.error_string);
            return "";
        }

        return compute_now (&file, checksum_type);
    }


    internal signal void signal_finished (string checksum_type, string checksum);


    /***********************************************************
    ***********************************************************/
    private void on_signal_calculation_done () {
        string checksum = this.watcher.future ().result ();
        if (!checksum == null) {
            /* emit */ done (this.checksum_type, checksum);
        } else {
            /* emit */ done ("", "");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_impl (std.unique_ptr<QIODevice> device) {
        this.watcher.signal_finished.connect (
            this.on_signal_calculation_done
        ); // Qt.UniqueConnection

        // We'd prefer to move the unique_ptr into the lambda, but that's
        // awkward with the C++ standard we're on
        var shared_device = unowned<QIODevice> (device.release ());

        // Bug: The thread will keep running even if ComputeChecksum is deleted.
        string type = this.checksum_type;
        this.watcher.future (QtConcurrent.run (
            ComputeChecksum.on_watcher_run
        ));
    }


    private static void on_watcher_run (QIODevice shared_device, string type) {
        if (!shared_device.open (QIODevice.ReadOnly)) {
            var file = qobject_cast<GLib.File> (shared_device);
            if (file) {
                GLib.warning ("Could not open file " + file.filename ()
                        + " for reading to compute a checksum " + file.error_string);
            } else {
                GLib.warning ("Could not open device " + shared_device
                        + " for reading to compute a checksum " + shared_device.error_string);
            }
            return "";
        }
        var result = ComputeChecksum.compute_now (shared_device, type);
        shared_device.close ();
        return result;
    }
}

} // namespace Occ
