/***********************************************************
This software is in the public domain, furnished "as is", without technical
support, and with no warranty, express or implied, as to its usefulness for
any purpose.
*/


namespace Occ {
namespace Testing {

public class TestNetrcParser : GLib.Object {

    const string testfile_c = "netrctest";
    const string testfile_with_default_c = "netrctest_default";
    const string testfile_empty_c = "netrctest_empty";

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        GLib.File netrc = new GLib.File (testfile_c);
        GLib.assert_true (netrc.open (QIODevice.WriteOnly));
        netrc.write ("machine foo login bar password baz\n");
        netrc.write ("machine broken login bar2 dontbelonghere password baz2 extratokens dontcare andanother\n");
        netrc.write ("machine\nfunnysplit\tlogin bar3 password baz3\n");
        netrc.write ("machine frob login \"user with spaces\" password 'space pwd'\n");
        GLib.File netrc_with_default = new GLib.File (testfile_with_default_c);
        GLib.assert_true (netrc_with_default.open (QIODevice.WriteOnly));
        netrc_with_default.write ("machine foo login bar password baz\n");
        netrc_with_default.write ("default login user password pass\n");
        GLib.File netrc_empty = new GLib.File (testfile_empty_c);
        GLib.assert_true (netrc_empty.open (QIODevice.WriteOnly));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        GLib.assert_true (GLib.File.remove (testfile_c));
        GLib.assert_true (GLib.File.remove (testfile_with_default_c));
        GLib.assert_true (GLib.File.remove (testfile_empty_c));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_valid_netrc () {
        NetrcParser parser = new NetrcParser (testfile_c);
        GLib.assert_true (parser.parse ());
        GLib.assert_true (parser.find ("foo") == new Pair<string, string> ("bar", "baz"));
        GLib.assert_true (parser.find ("broken") == new Pair<string, string> ("bar2", ""));
        GLib.assert_true (parser.find ("funnysplit") == new Pair<string, string> ("bar3", "baz3"));
        GLib.assert_true (parser.find ("frob") == new Pair<string, string> ("user with spaces", "space pwd"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_empty_netrc () {
        NetrcParser parser = new NetrcParser (testfile_empty_c);
        GLib.assert_true (!parser.parse ());
        GLib.assert_true (parser.find ("foo") == new Pair<string, string> ("", ""));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_valid_netrc_with_default () {
        NetrcParser parser = new NetrcParser (testfile_with_default_c);
        GLib.assert_true (parser.parse ());
        GLib.assert_true (parser.find ("foo") == new Pair<string, string> ("bar", "baz"));
        GLib.assert_true (parser.find ("dontknow") == new Pair<string, string> ("user", "pass"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_invalid_netrc () {
        NetrcParser parser = new NetrcParser ("/invalid");
        GLib.assert_true (!parser.parse ());
    }

} // class TestNetrcParser
} // namespace Testing
} // namespace Occ
