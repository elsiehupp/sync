/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSha1Calc : AbstractTestChecksumValidator {

//    private TestSha1Calc () {
//        string file = this.root.path + "/file_b.bin";
//        Utility.write_random_file (file);
//        GLib.FileInfo file_info = new GLib.FileInfo (file);
//        GLib.assert_true (file_info.exists ());

//        GLib.File file_device = new GLib.File (file);
//        file_device.open (GLib.IODevice.ReadOnly);
//        string sum = calc_sha1 (file_device);
//        file_device.close ();

//        string s_sum = shell_sum ("sha1sum", file);
//        if (s_sum == "") {
//            GLib.SKIP ("Couldn't execute sha1sum to calculate checksum, executable missing?", SkipSingle);
//        }

//        GLib.assert_true (sum != "");
//        GLib.assert_true (s_sum == sum);
//    }

} // class TestSha1Calc

} // namespace Testing
} // namespace Occ
