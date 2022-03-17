/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <GLib.Dir>

using Occ;
using Occ.Utility;

namespace Testing {

public class TestChecksumValidator : GLib.Object {

    private QTemporaryDir root;
    private string testfile;
    private string expected_error;
    private string expected;
    private string expected_type;
    private bool success_down;
    private bool error_seen;

    /***********************************************************
    ***********************************************************/
    public void on_signal_up_validated (string type, string checksum) {
        GLib.debug ("Checksum: " + checksum.to_string ());
        GLib.assert_true (this.expected == checksum );
        GLib.assert_true (this.expected_type == type );
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_down_validated () {
        this.success_down = true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_down_error (string error_message) {
        GLib.assert_true (this.expected_error == error_message);
        this.error_seen = true;
    }


    /***********************************************************
    ***********************************************************/
    static string shell_sum (string command, string file) {
        QProcess md5;
        string[] args;
        args.append (file);
        md5.on_signal_start (command, args);
        string sum_shell;
        GLib.debug ("File: " + file);

        if (md5.wait_for_finished ()) {
            sum_shell = md5.read_all ();
            sum_shell = sum_shell.left (sum_shell.index_of (' '));
        }
        return sum_shell;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        this.testfile = this.root.path () + "/cs_file";
        Utility.write_random_file ( this.testfile);
    }

    private void test_md5_calc () {
        string file = this.root.path () + "/file_a.bin";
        GLib.assert_true (Utility.write_random_file (file));
        GLib.FileInfo file_info = new GLib.FileInfo (file);
        GLib.assert_true (file_info.exists ());

        GLib.File file_device = new GLib.File (file);
        file_device.open (QIODevice.ReadOnly);
        string sum = calc_md5 (&file_device);
        file_device.close ();

        string s_sum = shell_sum ("md5sum", file);
        if (s_sum == "") {
            QSKIP ("Couldn't execute md5sum to calculate checksum, executable missing?", SkipSingle);
        }

        GLib.assert_true (sum != "");
        GLib.assert_true (s_sum == sum);
    }

    private void test_sha1_calc () {
        string file = this.root.path () + "/file_b.bin";
        Utility.write_random_file (file);
        GLib.FileInfo file_info = new GLib.FileInfo (file);
        GLib.assert_true (file_info.exists ());

        GLib.File file_device = new GLib.File (file);
        file_device.open (QIODevice.ReadOnly);
        string sum = calc_sha1 (file_device);
        file_device.close ();

        string s_sum = shell_sum ("sha1sum", file);
        if (s_sum == "") {
            QSKIP ("Couldn't execute sha1sum to calculate checksum, executable missing?", SkipSingle);
        }

        GLib.assert_true (sum != "");
        GLib.assert_true (s_sum == sum);
    }

    private void test_upload_checksumming_adler () {
        var vali = new ComputeChecksum (this);
        this.expected_type = new Adler32 ();
        vali.set_checksum_type (this.expected_type);

        connect (
            vali,
            signal_done (string, string),
            on_signal_up_validated (string, string)
        );

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calc_adler32 (file);
        GLib.debug ("XX Expected Checksum: " + this.expected);
        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (
            vali,
            signal_done (string,string),
            loop,
            quit (),
            Qt.QueuedConnection
        );
        loop.exec ();

        delete vali;
    //  #endif
    }

    private void test_upload_checksumming_md5 () {

        var vali = new ComputeChecksum (this);
        this.expected_type = Occ.checksum_md5c;
        vali.set_checksum_type (this.expected_type);
        connect (
            vali,
            signal_done (string, string),
            this,
            on_signal_up_validated (string, string));

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calc_md5 (file);
        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (signal_done (string,string)), loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    }

    private void test_upload_checksumming_sha1 () {
        var vali = new ComputeChecksum (this);
        this.expected_type = Occ.CheckSumSHA1C;
        vali.set_checksum_type (this.expected_type);
        connect (
            vali,
            signal_done (string,string),
            this,
            on_signal_up_validated (string,string)
        );

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calc_sha1 (file);

        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (
            vali,
            signal_done (string,string),
            loop,
            quit (),
            Qt.QueuedConnection
        );
        loop.exec ();

        delete vali;
    }

    private void test_download_checksumming_adler () {
        var vali = new ValidateChecksumHeader (this);
        connect (
            vali,
            ValidateChecksumHeader.signal_validated,
            this,
            TestChecksumValidator.on_signal_down_validated
        );
        connect (
            vali,
            ValidateChecksumHeader.signal_validation_failed,
            this,
            TestChecksumValidator.on_signal_down_error
        );

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calc_adler32 (file);

        string adler = check_sum_adler_c;
        adler.append (":");
        adler.append (this.expected);

        file.seek (0);
        this.success_down = false;
        vali.on_signal_start (this.testfile, adler);

        QTRY_VERIFY (this.success_down);

        this.expected_error = "The downloaded file does not match the checksum, it will be resumed. \"543345\" != \"%1\"".printf (this.expected);
        this.error_seen = false;
        file.seek (0);
        vali.on_signal_start (this.testfile, "Adler32:543345");
        QTRY_VERIFY (this.error_seen);

        this.expected_error = "The checksum header contained an unknown checksum type \"Klaas32\"";
        this.error_seen = false;
        file.seek (0);
        vali.on_signal_start (this.testfile, "Klaas32:543345");
        QTRY_VERIFY (this.error_seen);

        delete vali;
    }

    private void on_signal_cleanup_test_case () {
    }

} // class TestChecksumValidator
} // namespace Testing
