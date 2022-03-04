/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

class TestSyncDelete : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testDeleteDirectoryWithNewFile () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        // Remove a directory on the server with new files on the client
        fakeFolder.remote_modifier ().remove ("A");
        fakeFolder.local_modifier ().insert ("A/hello.txt");

        // Symetry
        fakeFolder.local_modifier ().remove ("B");
        fakeFolder.remote_modifier ().insert ("B/hello.txt");

        QVERIFY (fakeFolder.sync_once ());

        // A/a1 must be gone because the directory was removed on the server, but hello.txt must be there
        QVERIFY (!fakeFolder.current_remote_state ().find ("A/a1"));
        QVERIFY (fakeFolder.current_remote_state ().find ("A/hello.txt"));

        // Symetry
        QVERIFY (!fakeFolder.current_remote_state ().find ("B/b1"));
        QVERIFY (fakeFolder.current_remote_state ().find ("B/hello.txt"));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void issue1329 () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        fakeFolder.local_modifier ().remove ("B");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Add a directory that was just removed in the previous sync:
        fakeFolder.local_modifier ().mkdir ("B");
        fakeFolder.local_modifier ().insert ("B/b1");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_remote_state ().find ("B/b1"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }
}

QTEST_GUILESS_MAIN (TestSyncDelete)
