/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestChecksumValidator : GLib.Object {

    protected GLib.TemporaryDir root;
    protected string testfile;
    protected string expected_error;
    protected string expected;
    protected string expected_type;
    protected bool success_down;
    protected bool error_seen;

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
        GLib.Process md5;
        GLib.List<string> args = new GLib.List<string> ()
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
    protected void clean_up () {
        return;
    }

} // class AbstractTestChecksumValidator

} // namespace Testing
} // namespace Occ
