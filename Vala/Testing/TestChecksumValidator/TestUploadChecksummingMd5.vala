/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestUploadChecksummingMd5 : AbstractTestChecksumValidator {

    private TestUploadChecksummingMd5 () {

        var compute_checksum = new ComputeChecksum (this);
        this.expected_type = checksum_md5c;
        compute_checksum.set_checksum_type (this.expected_type);
        compute_checksum.signal_finished.connect (
            this.on_signal_up_validated
        );

        var file = GLib.File.new_for_path (this.testfile, compute_checksum);
        file.open (GLib.IODevice.ReadOnly);
        this.expected = calc_md5 (file);
        compute_checksum.on_signal_start (this.testfile);

        GLib.MainLoop loop;
        compute_checksum.signal_finished.connect (
            loop.quit // GLib.QueuedConnection
        );
        loop.exec ();

        delete compute_checksum;
    }

} // class TestUploadChecksummingMd5

} // namespace Testing
} // namespace Occ
