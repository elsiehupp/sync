/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDownloadChecksummingAdler : AbstractTestChecksumValidator {

//    private TestDownloadChecksummingAdler () {
//        var compute_checksum = new ValidateChecksumHeader (this);
//        compute_checksum.signal_validated.connect (
//            this.on_signal_down_validated
//        );
//        compute_checksum.signal_validation_failed.connect (
//            this.on_signal_down_error
//        );

//        var file = GLib.File.new_for_path (this.testfile, compute_checksum);
//        file.open (GLib.IODevice.ReadOnly);
//        this.expected = calc_adler32 (file);

//        string adler = check_sum_adler_c;
//        adler.append (":");
//        adler.append (this.expected);

//        file.seek (0);
//        this.success_down = false;
//        compute_checksum.on_signal_start (this.testfile, adler);

//        GLib.TRY_VERIFY (this.success_down);

//        this.expected_error = "The downloaded file does not match the checksum, it will be resumed. \"543345\" != \"%1\"".printf (this.expected);
//        this.error_seen = false;
//        file.seek (0);
//        compute_checksum.on_signal_start (this.testfile, "Adler32:543345");
//        GLib.TRY_VERIFY (this.error_seen);

//        this.expected_error = "The checksum header contained an unknown checksum type \"Klaas32\"";
//        this.error_seen = false;
//        file.seek (0);
//        compute_checksum.on_signal_start (this.testfile, "Klaas32:543345");
//        GLib.TRY_VERIFY (this.error_seen);

//        delete compute_checksum;
//    }

} // class TestDownloadChecksummingAdler

} // namespace Testing
} // namespace Occ
