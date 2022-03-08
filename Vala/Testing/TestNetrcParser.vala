/***********************************************************
This software is in the public domain, furnished "as is", without technical
support, and with no warranty, express or implied, as to its usefulness for
any purpose.
*/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestNetrcParser : GLib.Object {

    const string testfileC = "netrctest";
    const string testfileWithDefaultC = "netrctestDefault";
    const string testfileEmptyC = "netrctestEmpty";

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        GLib.File netrc = new GLib.File (testfileC);
        //  QVERIFY (netrc.open (QIODevice.WriteOnly));
        netrc.write ("machine foo login bar password baz\n");
        netrc.write ("machine broken login bar2 dontbelonghere password baz2 extratokens dontcare andanother\n");
        netrc.write ("machine\nfunnysplit\tlogin bar3 password baz3\n");
        netrc.write ("machine frob login \"user with spaces\" password 'space pwd'\n");
        GLib.File netrcWithDefault = new GLib.File (testfileWithDefaultC);
        //  QVERIFY (netrcWithDefault.open (QIODevice.WriteOnly));
        netrcWithDefault.write ("machine foo login bar password baz\n");
        netrcWithDefault.write ("default login user password pass\n");
        GLib.File netrcEmpty = new GLib.File (testfileEmptyC);
        //  QVERIFY (netrcEmpty.open (QIODevice.WriteOnly));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        //  QVERIFY (GLib.File.remove (testfileC));
        //  QVERIFY (GLib.File.remove (testfileWithDefaultC));
        //  QVERIFY (GLib.File.remove (testfileEmptyC));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_valid_netrc () {
        NetrcParser parser = new NetrcParser (testfileC);
        //  QVERIFY (parser.parse ());
        //  QCOMPARE (parser.find ("foo"), qMakePair (string ("bar"), string ("baz")));
        //  QCOMPARE (parser.find ("broken"), qMakePair (string ("bar2"), ""));
        //  QCOMPARE (parser.find ("funnysplit"), qMakePair (string ("bar3"), string ("baz3")));
        //  QCOMPARE (parser.find ("frob"), qMakePair (string ("user with spaces"), string ("space pwd")));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_empty_netrc () {
        NetrcParser parser = new NetrcParser (testfileEmptyC);
        //  QVERIFY (!parser.parse ());
        //  QCOMPARE (parser.find ("foo"), qMakePair ("", ""));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_valid_netrcWithDefault () {
        NetrcParser parser = new NetrcParser (testfileWithDefaultC);
        //  QVERIFY (parser.parse ());
        //  QCOMPARE (parser.find ("foo"), qMakePair (string ("bar"), string ("baz")));
        //  QCOMPARE (parser.find ("dontknow"), qMakePair (string ("user"), string ("pass")));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_invalid_netrc () {
        NetrcParser parser = new NetrcParser ("/invalid");
        //  QVERIFY (!parser.parse ());
    }

} // class TestNetrcParser
} // namespace Testing
