/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMd5Calc : AbstractTestChecksumValidator {

    private TestMd5Calc () {
        string file = this.root.path + "/file_a.bin";
        GLib.assert_true (Utility.write_random_file (file));
        GLib.FileInfo file_info = new GLib.FileInfo (file);
        GLib.assert_true (file_info.exists ());

        GLib.File file_device = new GLib.File (file);
        file_device.open (GLib.IODevice.ReadOnly);
        string sum = calc_md5 (&file_device);
        file_device.close ();

        string s_sum = shell_sum ("md5sum", file);
        if (s_sum == "") {
            GLib.SKIP ("Couldn't execute md5sum to calculate checksum, executable missing?", SkipSingle);
        }

        GLib.assert_true (sum != "");
        GLib.assert_true (s_sum == sum);
    }

} // class TestMd5Calc

} // namespace Testing
} // namespace Occ
