/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestUploadChecksummingSha1 : AbstractTestChecksumValidator {

    private TestUploadChecksummingSha1 () {
        var compute_checksum = new ComputeChecksum (this);
        this.expected_type = CheckSumSHA1C;
        compute_checksum.set_checksum_type (this.expected_type);
        compute_checksum.signal_finished.connect (
            this.on_signal_up_validated
        );

        var file = GLib.File.new_for_path (this.testfile, compute_checksum);
        file.open (QIODevice.ReadOnly);
        this.expected = calc_sha1 (file);

        compute_checksum.on_signal_start (this.testfile);

        QEventLoop loop;
        compute_checksum.signal_finished.connect (
            loop.quit // Qt.QueuedConnection
        );
        loop.exec ();

        delete compute_checksum;
    }

} // class TestUploadChecksummingSha1

} // namespace Testing
} // namespace Occ
