/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestChecksumValidator : GLib.Object {

    private QTemporaryDir root;
    private string testfile;
    private string expected_error;
    private string expected;
    private string expected_type;
    private bool success_down;
    private bool error_seen;

    /***********************************************************
    ***********************************************************/
    protected void on_signal_up_validated (string type, string checksum) {
        GLib.debug ("Checksum: " + checksum.to_string ());
        GLib.assert_true (this.expected == checksum );
        GLib.assert_true (this.expected_type == type );
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_down_validated () {
        this.success_down = true;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_down_error (string error_message) {
        GLib.assert_true (this.expected_error == error_message);
        this.error_seen = true;
    }


    /***********************************************************
    ***********************************************************/
    protected static string shell_sum (string command, string file) {
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
    protected void on_signal_init_test_case () {
        this.testfile = this.root.path + "/cs_file";
        Utility.write_random_file (this.testfile);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_cleanup_test_case () {
        return;
    }

} // class AbstractTestChecksumValidator

} // namespace Testing
} // namespace Occ
