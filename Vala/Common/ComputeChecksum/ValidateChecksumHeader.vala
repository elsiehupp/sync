/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using ZLib;
namespace Occ {

/***********************************************************
Checks whether a file's checksum matches the expected value.
@ingroup libsync
***********************************************************/
class ValidateChecksumHeader : ComputeChecksumBase {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.expected_checksum_type;
    private GLib.ByteArray this.expected_checksum;

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
        if (checksum_type != this.expected_checksum_type) {
            /* emit */ validation_failed (_("The checksum header contained an unknown checksum type \"%1\"").arg (string.from_latin1 (this.expected_checksum_type)));
            return;
        }
        if (checksum != this.expected_checksum) {
            /* emit */ validation_failed (_(R" (The downloaded file does not match the checksum, it will be resumed. "%1" != "%2")").arg (string.from_utf8 (this.expected_checksum), string.from_utf8 (checksum)));
            return;
        }
        /* emit */ validated (checksum_type, checksum);
    }


    /***********************************************************
    ***********************************************************/
    private ComputeChecksum prepare_start (GLib.ByteArray checksum_header) {
        // If the incoming header is empty no validation can happen. Just continue.
        if (checksum_header.is_empty ()) {
            /* emit */ validated (GLib.ByteArray (), GLib.ByteArray ());
            return nullptr;
        }

        if (!parse_checksum_header (checksum_header, this.expected_checksum_type, this.expected_checksum)) {
            GLib.warn (lc_checksums) << "Checksum header malformed:" << checksum_header;
            /* emit */ validation_failed (_("The checksum header is malformed."));
            return nullptr;
        }

        var calculator = new ComputeChecksum (this);
        calculator.set_checksum_type (this.expected_checksum_type);
        connect (calculator, &ComputeChecksum.done,
            this, &ValidateChecksumHeader.on_checksum_calculated);
        return calculator;
    }
}