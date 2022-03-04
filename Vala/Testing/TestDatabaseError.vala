/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

class TestDatabaseError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testDatabaseError () {
        /* This test will make many iteration, at each iteration, the iᵗʰ database access will fail.
         * The test ensure that if there is a failure, the next sync recovers. And if there was
         * no error, then everything was sync'ed properly.
         */

        FileInfo finalState;
        for (int count = 0; true; ++count) {
            qInfo ("Starting Iteration" + count;

            FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};

            // Do a couple of changes
            fakeFolder.remote_modifier ().insert ("A/a0");
            fakeFolder.remote_modifier ().append_byte ("A/a1");
            fakeFolder.remote_modifier ().remove ("A/a2");
            fakeFolder.remote_modifier ().rename ("S/s1", "S/s1_renamed");
            fakeFolder.remote_modifier ().mkdir ("D");
            fakeFolder.remote_modifier ().mkdir ("D/subdir");
            fakeFolder.remote_modifier ().insert ("D/subdir/file");
            fakeFolder.local_modifier ().insert ("B/b0");
            fakeFolder.local_modifier ().append_byte ("B/b1");
            fakeFolder.remote_modifier ().remove ("B/b2");
            fakeFolder.local_modifier ().mkdir ("NewDir");
            fakeFolder.local_modifier ().rename ("C", "NewDir/C");

            // Set the counter
            fakeFolder.sync_journal ().autotestFailCounter = count;

            // run the sync
            bool result = fakeFolder.sync_once ();

            qInfo ("Result of iteration" + count + "was" + result;

            if (fakeFolder.sync_journal ().autotestFailCounter >= 0) {
                // No error was thrown, we are on_signal_finished
                QVERIFY (result);
                QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
                QCOMPARE (fakeFolder.current_remote_state (), finalState);
                return;
            }

            if (!result) {
                fakeFolder.sync_journal ().autotestFailCounter = -1;
                // Try again
                QVERIFY (fakeFolder.sync_once ());
            }

            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            if (count == 0) {
                finalState = fakeFolder.current_remote_state ();
            } else {
                // the final state should be the same for every iteration
                QCOMPARE (fakeFolder.current_remote_state (), finalState);
            }
        }
    }
}

QTEST_GUILESS_MAIN (TestDatabaseError)
#include "testdatabaseerror.moc"
