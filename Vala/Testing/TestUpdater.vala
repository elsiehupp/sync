/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestUpdater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_version_to_int () {
        int64 lowVersion = Updater.Helper.versionToInt (1,2,80,3000);
        //  QCOMPARE (Updater.Helper.stringVersionToInt ("1.2.80.3000"), lowVersion);

        int64 highVersion = Updater.Helper.versionToInt (99,2,80,3000);
        int64 currVersion = Updater.Helper.currentVersionToInt ();
        //  QVERIFY (currVersion > 0);
        //  QVERIFY (currVersion > lowVersion);
        //  QVERIFY (currVersion < highVersion);
    }

}
}
