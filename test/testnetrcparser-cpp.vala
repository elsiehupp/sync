/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

// #include <QtTest>

using namespace Occ;

namespace {

const char testfileC[] = "netrctest";
const char testfileWithDefaultC[] = "netrctestDefault";
const char testfileEmptyC[] = "netrctestEmpty";

}

class TestNetrcParser : GLib.Object {

private slots:
    void initTestCase () {
       QFile netrc (testfileC);
       QVERIFY (netrc.open (QIODevice.WriteOnly));
       netrc.write ("machine foo login bar password baz\n");
       netrc.write ("machine broken login bar2 dontbelonghere password baz2 extratokens dontcare andanother\n");
       netrc.write ("machine\nfunnysplit\tlogin bar3 password baz3\n");
       netrc.write ("machine frob login \"user with spaces\" password 'space pwd'\n");
       QFile netrcWithDefault (testfileWithDefaultC);
       QVERIFY (netrcWithDefault.open (QIODevice.WriteOnly));
       netrcWithDefault.write ("machine foo login bar password baz\n");
       netrcWithDefault.write ("default login user password pass\n");
       QFile netrcEmpty (testfileEmptyC);
       QVERIFY (netrcEmpty.open (QIODevice.WriteOnly));
    }

    void cleanupTestCase () {
       QVERIFY (QFile.remove (testfileC));
       QVERIFY (QFile.remove (testfileWithDefaultC));
       QVERIFY (QFile.remove (testfileEmptyC));
    }

    void testValidNetrc () {
       NetrcParser parser (testfileC);
       QVERIFY (parser.parse ());
       QCOMPARE (parser.find ("foo"), qMakePair (string ("bar"), string ("baz")));
       QCOMPARE (parser.find ("broken"), qMakePair (string ("bar2"), string ()));
       QCOMPARE (parser.find ("funnysplit"), qMakePair (string ("bar3"), string ("baz3")));
       QCOMPARE (parser.find ("frob"), qMakePair (string ("user with spaces"), string ("space pwd")));
    }

    void testEmptyNetrc () {
       NetrcParser parser (testfileEmptyC);
       QVERIFY (!parser.parse ());
       QCOMPARE (parser.find ("foo"), qMakePair (string (), string ()));
    }

    void testValidNetrcWithDefault () {
       NetrcParser parser (testfileWithDefaultC);
       QVERIFY (parser.parse ());
       QCOMPARE (parser.find ("foo"), qMakePair (string ("bar"), string ("baz")));
       QCOMPARE (parser.find ("dontknow"), qMakePair (string ("user"), string ("pass")));
    }

    void testInvalidNetrc () {
       NetrcParser parser ("/invalid");
       QVERIFY (!parser.parse ());
    }
};

QTEST_APPLESS_MAIN (TestNetrcParser)
#include "testnetrcparser.moc"
