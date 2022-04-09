/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestUploadChecksummingAdler : AbstractTestChecksumValidator {

    private TestUploadChecksummingAdler () {
        var compute_checksum = new ComputeChecksum (this);
        this.expected_type = new Adler32 ();
        compute_checksum.set_checksum_type (this.expected_type);

        compute_checksum.signal_finished.connect (
            this.on_signal_up_validated
        );

        var file = GLib.File.new_for_path (this.testfile, compute_checksum);
        file.open (GLib.IODevice.ReadOnly);
        this.expected = calc_adler32 (file);
        GLib.debug ("XX Expected Checksum: " + this.expected);
        compute_checksum.on_signal_start (this.testfile);

        GLib.MainLoop loop;
        compute_checksum.signal_finished.connect (
            loop.quit // Qt.QueuedConnection
        );
        loop.exec ();

        delete compute_checksum;
    //  #endif
    }

} // class TestUploadChecksummingAdler

} // namespace Testing
} // namespace Occ
