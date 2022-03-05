/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <configfile.h>

using Occ;

namespace Testing {

static void changeAllFileId (FileInfo info) {
    info.file_identifier = generateFileId ();
    if (!info.isDir)
        return;
    info.etag = generateEtag ();
    for (var child : info.children) {
        changeAllFileId (child);
    }
}

/***********************************************************
This test ensure that the SyncEngine.aboutToRemoveAllFiles is correctly called and that when
we the user choose to remove all files SyncJournalDb.clearFileTable makes works as expected
***********************************************************/
class TestAllFilesDeleted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testAllFilesDeletedKeep_data () {
        QTest.addColumn<bool> ("deleteOnRemote");
        QTest.newRow ("local") + false;
        QTest.newRow ("remote") + true;

    }


    /***********************************************************
     * In this test, all files are deleted in the client, or the server, and we simulate
     * that the users press "keep"
     */
    private on_ void testAllFilesDeletedKeep () {
        //  QFETCH (bool, deleteOnRemote);
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ConfigFile config;
        config.setPromptDeleteFiles (true);

        //Just set a blocklist so we can check it is still there. This directory does not exists but
        // that does not matter for our purposes.
        string[] selectiveSyncBlockList = { "Q/" };
        fake_folder.sync_engine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                                                                selectiveSyncBlockList);

        var initialState = fake_folder.current_local_state ();
        int aboutToRemoveAllFilesCalled = 0;
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] (SyncFileItem.Direction directory, std.function<void (bool)> callback) {
                //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
                aboutToRemoveAllFilesCalled++;
                //  QCOMPARE (directory, deleteOnRemote ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP);
                callback (true);
                fake_folder.sync_engine ().journal ().clearFileTable (); // That's what Folder is doing
            });

        var modifier = deleteOnRemote ? fake_folder.remote_modifier () : fake_folder.local_modifier ();
        for (var s : fake_folder.current_remote_state ().children.keys ())
            modifier.remove (s);

        //  QVERIFY (!fake_folder.sync_once ()); // Should fail because we cancel the sync
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 1);

        // Next sync should recover all files
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), initialState);
        //  QCOMPARE (fake_folder.current_remote_state (), initialState);

        // The selective sync blocklist should be not have been deleted.
        bool ok = true;
        //  QCOMPARE (fake_folder.sync_engine ().journal ().getSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok),
                 selectiveSyncBlockList);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testAllFilesDeletedDelete_data () {
        testAllFilesDeletedKeep_data ();
    }


    /***********************************************************
     * This test is like the previous one but we simulate that the user presses "delete"
     */
    private on_ void testAllFilesDeletedDelete () {
        //  QFETCH (bool, deleteOnRemote);
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int aboutToRemoveAllFilesCalled = 0;
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] (SyncFileItem.Direction directory, std.function<void (bool)> callback) {
                //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
                aboutToRemoveAllFilesCalled++;
                //  QCOMPARE (directory, deleteOnRemote ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP);
                callback (false);
            });

        var modifier = deleteOnRemote ? fake_folder.remote_modifier () : fake_folder.local_modifier ();
        for (var s : fake_folder.current_remote_state ().children.keys ())
            modifier.remove (s);

        //  QVERIFY (fake_folder.sync_once ()); // Should succeed, and all files must then be deleted

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QCOMPARE (fake_folder.current_local_state ().children.count (), 0);

        // Try another sync to be sure.

        //  QVERIFY (fake_folder.sync_once ()); // Should succeed (doing nothing)
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 1); // should not have been called.

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QCOMPARE (fake_folder.current_local_state ().children.count (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testNotDeleteMetaDataChange () {
        /***********************************************************
         * This test make sure that we don't popup a file deleted message if all the metadata have
         * been updated (for example when the server is upgraded or something)
         **/

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        // We never remove all files.
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] { QVERIFY (false); });
        //  QVERIFY (fake_folder.sync_once ());

        for (var s : fake_folder.current_remote_state ().children.keys ())
            fake_folder.sync_journal ().avoidRenamesOnNextSync (s); // clears all the fileid and inodes.
        fake_folder.local_modifier ().remove ("A/a1");
        var expectedState = fake_folder.current_local_state ();
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), expectedState);
        //  QCOMPARE (fake_folder.current_remote_state (), expectedState);

        fake_folder.remote_modifier ().remove ("B/b1");
        changeAllFileId (fake_folder.remote_modifier ());
        expectedState = fake_folder.current_remote_state ();
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), expectedState);
        //  QCOMPARE (fake_folder.current_remote_state (), expectedState);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testResetServer () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int aboutToRemoveAllFilesCalled = 0;
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] (SyncFileItem.Direction directory, std.function<void (bool)> callback) {
                //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
                aboutToRemoveAllFilesCalled++;
                //  QCOMPARE (directory, SyncFileItem.Direction.DOWN);
                callback (false);
            });

        // Some small changes
        fake_folder.local_modifier ().mkdir ("Q");
        fake_folder.local_modifier ().insert ("Q/q1");
        fake_folder.local_modifier ().append_byte ("B/b1");
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);

        // Do some change localy
        fake_folder.local_modifier ().append_byte ("A/a1");

        // reset the server.
        fake_folder.remote_modifier () = FileInfo.A12_B12_C12_S12 ();

        // Now, aboutToRemoveAllFiles with down as a direction
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 1);

    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDataFingetPrint_data () {
        QTest.addColumn<bool> ("hasInitialFingerPrint");
        QTest.newRow ("initial finger print") + true;
        QTest.newRow ("no initial finger print") + false;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDataFingetPrint () {
        //  QFETCH (bool, hasInitialFingerPrint);
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().set_contents ("C/c1", 'N');
        fake_folder.remote_modifier ().set_modification_time ("C/c1", GLib.DateTime.currentDateTimeUtc ().addDays (-2));
        fake_folder.remote_modifier ().remove ("C/c2");
        if (hasInitialFingerPrint) {
            fake_folder.remote_modifier ().extraDavProperties = "<oc:data-fingerprint>initial_finger_print</oc:data-fingerprint>";
        } else {
            //Server support finger print, but none is set.
            fake_folder.remote_modifier ().extraDavProperties = "<oc:data-fingerprint></oc:data-fingerprint>";
        }

        int fingerprintRequests = 0;
        fake_folder.set_server_override ([&] (Soup.Operation, Soup.Request request, QIODevice stream) . Soup.Reply * {
            var verb = request.attribute (Soup.Request.CustomVerbAttribute);
            if (verb == "PROPFIND") {
                var data = stream.readAll ();
                if (data.contains ("data-fingerprint")) {
                    if (request.url ().path ().endsWith ("dav/files/admin/")) {
                        ++fingerprintRequests;
                    } else {
                        fingerprintRequests = -10000; // fingerprint queried on incorrect path
                    }
                }
            }
            return null;
        });

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fingerprintRequests, 1);
        // First sync, we did not change the finger print, so the file should be downloaded as normal
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QCOMPARE (fake_folder.current_remote_state ().find ("C/c1").content_char, 'N');
        //  QVERIFY (!fake_folder.current_remote_state ().find ("C/c2"));

        /* Simulate a backup restoration */

        // A/a1 is an old file
        fake_folder.remote_modifier ().set_contents ("A/a1", 'O');
        fake_folder.remote_modifier ().set_modification_time ("A/a1", GLib.DateTime.currentDateTimeUtc ().addDays (-2));
        // B/b1 did not exist at the time of the backup
        fake_folder.remote_modifier ().remove ("B/b1");
        // B/b2 was uploaded by another user in the mean time.
        fake_folder.remote_modifier ().set_contents ("B/b2", 'N');
        fake_folder.remote_modifier ().set_modification_time ("B/b2", GLib.DateTime.currentDateTimeUtc ().addDays (2));

        // C/c3 was removed since we made the backup
        fake_folder.remote_modifier ().insert ("C/c3_removed");
        // C/c4 was moved to A/a2 since we made the backup
        fake_folder.remote_modifier ().rename ("A/a2", "C/old_a2_location");

        // The admin sets the data-fingerprint property
        fake_folder.remote_modifier ().extraDavProperties = "<oc:data-fingerprint>new_finger_print</oc:data-fingerprint>";

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fingerprintRequests, 2);
        var currentState = fake_folder.current_local_state ();
        // Altough the local file is kept as a conflict, the server file is downloaded
        //  QCOMPARE (currentState.find ("A/a1").content_char, 'O');
        var conflict = findConflict (currentState, "A/a1");
        //  QVERIFY (conflict);
        //  QCOMPARE (conflict.content_char, 'W');
        fake_folder.local_modifier ().remove (conflict.path ());
        // b1 was restored (re-uploaded)
        //  QVERIFY (currentState.find ("B/b1"));

        // b2 has the new content (was not restored), since its mode time goes forward in time
        //  QCOMPARE (currentState.find ("B/b2").content_char, 'N');
        conflict = findConflict (currentState, "B/b2");
        //  QVERIFY (conflict); // Just to be sure, we kept the old file in a conflict
        //  QCOMPARE (conflict.content_char, 'W');
        fake_folder.local_modifier ().remove (conflict.path ());

        // We actually do not remove files that technically should have been removed (we don't want data-loss)
        //  QVERIFY (currentState.find ("C/c3_removed"));
        //  QVERIFY (currentState.find ("C/old_a2_location"));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSingleFileRenamed () {
        FakeFolder fake_folder = new FakeFolder (FileInfo{}};

        int aboutToRemoveAllFilesCalled = 0;
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] (SyncFileItem.Direction , std.function<void (bool)> ) {
                aboutToRemoveAllFilesCalled++;
                QFAIL ("should not be called");
            });

        // add a single file
        fake_folder.local_modifier ().insert ("hello.txt");
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // rename it
        fake_folder.local_modifier ().rename ("hello.txt", "goodbye.txt");

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSelectiveSyncNoPopup () {
        // Unselecting all folder should not cause the popup to be shown
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int aboutToRemoveAllFilesCalled = 0;
        GLib.Object.connect (&fake_folder.sync_engine (), &SyncEngine.aboutToRemoveAllFiles,
            [&] (SyncFileItem.Direction , std.function<void (bool)>) {
                aboutToRemoveAllFilesCalled++;
                QFAIL ("should not be called");
            });

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 0);
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.sync_engine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
            string[] ("A/" + "B/" + "C/" + "S/");

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), FileInfo{}); // all files should be one localy
        //  QCOMPARE (fake_folder.current_remote_state (), FileInfo.A12_B12_C12_S12 ()); // Server not changed
        //  QCOMPARE (aboutToRemoveAllFilesCalled, 0); // But we did not show the popup
    }

}

QTEST_GUILESS_MAIN (TestAllFilesDeleted)
#include "testallfilesdeleted.moc"
