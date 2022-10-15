    using ZLib;

namespace Occ {
namespace Common {

/***********************************************************
@class ValidateChecksumHeader

@brief Checks whether a file's checksum matches the expected
value.

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class ValidateChecksumHeader : AbstractComputeChecksum {

    /***********************************************************
    ***********************************************************/
    private string expected_checksum_type;
    private string expected_checksum;


    internal signal void signal_validated (string checksum_type, string checksum);
    internal signal void signal_validation_failed (string error_message);


    /***********************************************************
    ***********************************************************/
    public ValidateChecksumHeader (GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
    }


    /***********************************************************
    Check a file's actual checksum against the provided
    checksum_header

    If no checksum is there, or if a correct checksum is there,
    the signal signal_validated () will be emitted. In case of any kind
    of error, the signal signal_validation_failed () will be emitted.
    ***********************************************************/
    public void start_for_path (string file_path, string checksum_header) {
        //  var calculator = prepare_start (checksum_header);
        //  if (calculator) {
        //      calculator.on_signal_start (file_path);
        //  }
    }


    /***********************************************************
    Check a device's actual checksum against the provided checksum_header

    Like the other on_signal_start () but works on a device.

    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void start_for_device (GLib.OutputStream device, string checksum_header) {
        //  var calculator = prepare_start (checksum_header);
        //  if (calculator) {
        //      calculator.on_signal_start (std.move (device));
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_checksum_calculated (string checksum_type, string checksum) {
        //  if (checksum_type != this.expected_checksum_type) {
        //      signal_validation_failed (_("The checksum header contained an unknown checksum type \"%1\"").printf (this.expected_checksum_type));
        //      return;
        //  }
        //  if (checksum != this.expected_checksum) {
        //      signal_validation_failed (_(" (The downloaded file does not match the checksum, it will be resumed. \"%1\" != \"%2\")").printf (this.expected_checksum, checksum));
        //      return;
        //  }
        //  signal_validated (checksum_type, checksum);
    }


    /***********************************************************
    ***********************************************************/
    private ComputeChecksum prepare_start (string checksum_header) {
        //  /***********************************************************
        //  If the incoming header is empty no validation can happen.
        //  Just continue.
        //  ***********************************************************/
        //  if (checksum_header == "") {
        //      signal_validated ("", "");
        //      return null;
        //  }

        //  if (!parse_checksum_header (checksum_header, this.expected_checksum_type, this.expected_checksum)) {
        //      GLib.warning ("Checksum header malformed: " + checksum_header);
        //      signal_validation_failed (_("The checksum header is malformed."));
        //      return null;
        //  }

        //  var calculator = new ComputeChecksum (this);
        //  calculator.checksum_type = this.expected_checksum_type;
        //  calculator.done.connect (
        //      this.on_signal_checksum_calculated
        //  );
        //  return calculator;
    }

} // class ValidateChecksumHeader

} // namespace Common
} // namespace Occ
