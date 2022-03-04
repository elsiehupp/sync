/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

bool itemDidComplete (ItemCompletedSpy spy, string path) {
    if (var item = spy.findItem (path)) {
        return item.instruction != CSYNC_INSTRUCTION_NONE && item.instruction != CSYNC_INSTRUCTION_UPDATE_METADATA;
    }
    return false;
}

bool itemInstruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.findItem (path);
    return item.instruction == instr;
}

bool itemDidCompleteSuccessfully (ItemCompletedSpy spy, string path) {
    if (var item = spy.findItem (path)) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

bool itemDidCompleteSuccessfullyWithExpectedRank (ItemCompletedSpy spy, string path, int rank) {
    if (var item = spy.findItemWithExpectedRank (path, rank)) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

int itemSuccessfullyCompletedGetRank (ItemCompletedSpy spy, string path) {
    var itItem = std.find_if (spy.begin (), spy.end (), [&path] (var currentItem) {
        var item = currentItem[0].template value<Occ.SyncFileItemPtr> ();
        return item.destination () == path;
    });
    if (itItem != spy.end ()) {
        return itItem - spy.begin ();
    }
    return -1;
}

class TestSyncEngine : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testFileDownload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.remote_modifier ().insert ("A/a0");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "A/a0"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testFileUpload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.local_modifier ().insert ("A/a0");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "A/a0"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirDownload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.remote_modifier ().mkdir ("Y");
        fakeFolder.remote_modifier ().mkdir ("Z");
        fakeFolder.remote_modifier ().insert ("Z/d0");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Y"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Z"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Z/d0"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirUpload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.local_modifier ().mkdir ("Y");
        fakeFolder.local_modifier ().mkdir ("Z");
        fakeFolder.local_modifier ().insert ("Z/d0");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Y"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Z"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Z/d0"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirUploadWithDelayedAlgorithm () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"bulkupload", "1.0"} } } });

        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.local_modifier ().mkdir ("Y");
        fakeFolder.local_modifier ().insert ("Y/d0");
        fakeFolder.local_modifier ().mkdir ("Z");
        fakeFolder.local_modifier ().insert ("Z/d0");
        fakeFolder.local_modifier ().insert ("A/a0");
        fakeFolder.local_modifier ().insert ("B/b0");
        fakeFolder.local_modifier ().insert ("r0");
        fakeFolder.local_modifier ().insert ("r1");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfullyWithExpectedRank (completeSpy, "Y", 0));
        QVERIFY (itemDidCompleteSuccessfullyWithExpectedRank (completeSpy, "Z", 1));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Y/d0"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "Y/d0") > 1);
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "Z/d0"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "Z/d0") > 1);
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "A/a0"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "A/a0") > 1);
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "B/b0"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "B/b0") > 1);
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "r0"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "r0") > 1);
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "r1"));
        QVERIFY (itemSuccessfullyCompletedGetRank (completeSpy, "r1") > 1);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalDelete () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.remote_modifier ().remove ("A/a1");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "A/a1"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRemoteDelete () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.local_modifier ().remove ("A/a1");
        fakeFolder.sync_once ();
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "A/a1"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testEmlLocalChecksum () {
        FakeFolder fakeFolder{FileInfo{}};
        fakeFolder.local_modifier ().insert ("a1.eml", 64, 'A');
        fakeFolder.local_modifier ().insert ("a2.eml", 64, 'A');
        fakeFolder.local_modifier ().insert ("a3.eml", 64, 'A');
        fakeFolder.local_modifier ().insert ("b3.txt", 64, 'A');
        // Upload and calculate the checksums
        // fakeFolder.sync_once ();
        fakeFolder.sync_once ();

        var getDbChecksum = [&] (string path) {
            SyncJournalFileRecord record;
            fakeFolder.sync_journal ().getFileRecord (path, record);
            return record.checksumHeader;
        }

        // printf 'A%.0s' {1..64} | sha1sum -
        GLib.ByteArray referenceChecksum ("SHA1:30b86e44e6001403827a62c58b08893e77cf121f");
        QCOMPARE (getDbChecksum ("a1.eml"), referenceChecksum);
        QCOMPARE (getDbChecksum ("a2.eml"), referenceChecksum);
        QCOMPARE (getDbChecksum ("a3.eml"), referenceChecksum);
        QCOMPARE (getDbChecksum ("b3.txt"), referenceChecksum);

        ItemCompletedSpy completeSpy (fakeFolder);
        // Touch the file without changing the content, shouldn't upload
        fakeFolder.local_modifier ().set_contents ("a1.eml", 'A');
        // Change the content/size
        fakeFolder.local_modifier ().set_contents ("a2.eml", 'B');
        fakeFolder.local_modifier ().append_byte ("a3.eml");
        fakeFolder.local_modifier ().append_byte ("b3.txt");
        fakeFolder.sync_once ();

        QCOMPARE (getDbChecksum ("a1.eml"), referenceChecksum);
        QCOMPARE (getDbChecksum ("a2.eml"), GLib.ByteArray ("SHA1:84951fc23a4dafd10020ac349da1f5530fa65949"));
        QCOMPARE (getDbChecksum ("a3.eml"), GLib.ByteArray ("SHA1:826b7e7a7af8a529ae1c7443c23bf185c0ad440c"));
        QCOMPARE (getDbChecksum ("b3.eml"), getDbChecksum ("a3.txt"));

        QVERIFY (!itemDidComplete (completeSpy, "a1.eml"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "a2.eml"));
        QVERIFY (itemDidCompleteSuccessfully (completeSpy, "a3.eml"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSelectiveSyncBug () {
        // issue owncloud/enterprise#1965 : files from selective-sync ignored
        // folders are uploaded anyway is some circumstances.
        FakeFolder fakeFolder{FileInfo{ "", {
            FileInfo { QStringLiteral ("parentFolder"), {
                FileInfo{ QStringLiteral ("subFolderA"), { { QStringLiteral ("fileA.txt"), 400 }, { QStringLiteral ("fileB.txt"), 400, 'o' }, {nfo { QStringLiteral ("subsubFolder") { QStringLiteral ("fileC.txt"), 400 },
                        { QStringLiteral ("fileD.txt"), 400, 'o' }
                    }},
                    FileInfo{ QStringLiteral ("anotherFolder"), {
                        FileInfo { QStringLiteral ("emptyFolder"), { } },
                        FileInfo { QStringLiteral ("subsubFolder"), { { QStringLiteral ("fileE.txt"), 400 }, { QStringLiteral ("fileF.txt"), 400, 'o' }
                        }}
                    }}
                }},
                FileInfo{ QStringLiteral ("subFolderB"), {} }
            }}
        }}};

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        var expectedServerState = fakeFolder.current_remote_state ();

        // Remove subFolderA with selectiveSync:
        fakeFolder.sync_engine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {"parentFolder/subFolderA/"});
        fakeFolder.sync_engine ().journal ().schedulePathForRemoteDiscovery (QByteArrayLiteral ("parentFolder/subFolderA/"));
        var getEtag = [&] (GLib.ByteArray file) {
            SyncJournalFileRecord record;
            fakeFolder.sync_journal ().getFileRecord (file, record);
            return record.etag;
        }
        QVERIFY (getEtag ("parentFolder") == "this.invalid_");
        QVERIFY (getEtag ("parentFolder/subFolderA") == "this.invalid_");
        QVERIFY (getEtag ("parentFolder/subFolderA/subsubFolder") != "this.invalid_");

        // But touch local file before the next sync, such that the local folder
        // can't be removed
        fakeFolder.local_modifier ().set_contents ("parentFolder/subFolderA/fileB.txt", 'n');
        fakeFolder.local_modifier ().set_contents ("parentFolder/subFolderA/subsubFolder/fileD.txt", 'n');
        fakeFolder.local_modifier ().set_contents ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileF.txt", 'n');

        // Several follow-up syncs don't change the state at all,
        // in particular the remote state doesn't change and fileB.txt
        // isn't uploaded.

        for (int i = 0; i < 3; ++i) {
            fakeFolder.sync_once ();
 {
                // Nothing changed on the server
                QCOMPARE (fakeFolder.current_remote_state (), expectedServerState);
                // The local state should still have subFolderA
                var local = fakeFolder.current_local_state ();
                QVERIFY (local.find ("parentFolder/subFolderA"));
                QVERIFY (!local.find ("parentFolder/subFolderA/fileA.txt"));
                QVERIFY (local.find ("parentFolder/subFolderA/fileB.txt"));
                QVERIFY (!local.find ("parentFolder/subFolderA/subsubFolder/fileC.txt"));
                QVERIFY (local.find ("parentFolder/subFolderA/subsubFolder/fileD.txt"));
                QVERIFY (!local.find ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileE.txt"));
                QVERIFY (local.find ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileF.txt"));
                QVERIFY (!local.find ("parentFolder/subFolderA/anotherFolder/emptyFolder"));
                QVERIFY (local.find ("parentFolder/subFolderB"));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void abortAfterFailedMkdir () {
        FakeFolder fakeFolder{FileInfo{}};
        QSignalSpy finishedSpy (&fakeFolder.sync_engine (), SIGNAL (on_signal_finished (bool)));
        fakeFolder.server_error_paths ().append ("NewFolder");
        fakeFolder.local_modifier ().mkdir ("NewFolder");
        // This should be aborted and would otherwise fail in FileInfo.create.
        fakeFolder.local_modifier ().insert ("NewFolder/NewFile");
        fakeFolder.sync_once ();
        QCOMPARE (finishedSpy.size (), 1);
        QCOMPARE (finishedSpy.first ().first ().to_bool (), false);
    }

    /** Verify that an incompletely propagated directory doesn't have the server's
     * etag stored in the database yet. */
    private on_ void testDirEtagAfterIncompleteSync () {
        FakeFolder fakeFolder{FileInfo{}};
        QSignalSpy finishedSpy (&fakeFolder.sync_engine (), SIGNAL (on_signal_finished (bool)));
        fakeFolder.server_error_paths ().append ("NewFolder/foo");
        fakeFolder.remote_modifier ().mkdir ("NewFolder");
        fakeFolder.remote_modifier ().insert ("NewFolder/foo");
        QVERIFY (!fakeFolder.sync_once ());

        SyncJournalFileRecord record;
        fakeFolder.sync_journal ().getFileRecord (QByteArrayLiteral ("NewFolder"), record);
        QVERIFY (record.isValid ());
        QCOMPARE (record.etag, QByteArrayLiteral ("this.invalid_"));
        QVERIFY (!record.file_identifier.isEmpty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirDownloadWithError () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        ItemCompletedSpy completeSpy (fakeFolder);
        fakeFolder.remote_modifier ().mkdir ("Y");
        fakeFolder.remote_modifier ().mkdir ("Y/Z");
        fakeFolder.remote_modifier ().insert ("Y/Z/d0");
        fakeFolder.remote_modifier ().insert ("Y/Z/d1");
        fakeFolder.remote_modifier ().insert ("Y/Z/d2");
        fakeFolder.remote_modifier ().insert ("Y/Z/d3");
        fakeFolder.remote_modifier ().insert ("Y/Z/d4");
        fakeFolder.remote_modifier ().insert ("Y/Z/d5");
        fakeFolder.remote_modifier ().insert ("Y/Z/d6");
        fakeFolder.remote_modifier ().insert ("Y/Z/d7");
        fakeFolder.remote_modifier ().insert ("Y/Z/d8");
        fakeFolder.remote_modifier ().insert ("Y/Z/d9");
        fakeFolder.server_error_paths ().append ("Y/Z/d2", 503);
        fakeFolder.server_error_paths ().append ("Y/Z/d3", 503);
        QVERIFY (!fakeFolder.sync_once ());
        QCoreApplication.processEvents (); // should not crash

        GLib.Set<string> seen;
        for (GLib.List<GLib.Variant> args : completeSpy) {
            var item = args[0].value<SyncFileItemPtr> ();
            GLib.debug () + item.file + item.isDirectory () + item.status;
            QVERIFY (!seen.contains (item.file)); // signal only sent once per item
            seen.insert (item.file);
            if (item.file == "Y/Z/d2") {
                QVERIFY (item.status == SyncFileItem.Status.NORMAL_ERROR);
            } else if (item.file == "Y/Z/d3") {
                QVERIFY (item.status != SyncFileItem.Status.SUCCESS);
            } else if (!item.isDirectory ()) {
                QVERIFY (item.status == SyncFileItem.Status.SUCCESS);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testFakeConflict_data () {
        QTest.addColumn<bool> ("sameMtime");
        QTest.addColumn<GLib.ByteArray> ("checksums");

        QTest.addColumn<int> ("expectedGET");

        QTest.newRow ("Same mtime, but no server checksum . ignored in reconcile")
            + true + GLib.ByteArray ()
            << 0;

        QTest.newRow ("Same mtime, weak server checksum differ . downloaded")
            + true + GLib.ByteArray ("Adler32:bad")
            << 1;

        QTest.newRow ("Same mtime, matching weak checksum . skipped")
            + true + GLib.ByteArray ("Adler32:2a2010d")
            << 0;

        QTest.newRow ("Same mtime, strong server checksum differ . downloaded")
            + true + GLib.ByteArray ("SHA1:bad")
            << 1;

        QTest.newRow ("Same mtime, matching strong checksum . skipped")
            + true + GLib.ByteArray ("SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427")
            << 0;

        QTest.newRow ("mtime changed, but no server checksum . download")
            + false + GLib.ByteArray ()
            << 1;

        QTest.newRow ("mtime changed, weak checksum match . download anyway")
            + false + GLib.ByteArray ("Adler32:2a2010d")
            << 1;

        QTest.newRow ("mtime changed, strong checksum match . skip")
            + false + GLib.ByteArray ("SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427")
            << 0;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testFakeConflict () {
        QFETCH (bool, sameMtime);
        QFETCH (GLib.ByteArray, checksums);
        QFETCH (int, expectedGET);

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        int nGET = 0;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request &, QIODevice *) {
            if (operation == QNetworkAccessManager.GetOperation)
                ++nGET;
            return null;
        });

        // For directly editing the remote checksum
        var remoteInfo = fakeFolder.remote_modifier ();

        // Base mtime with no ms content (filesystem is seconds only)
        var mtime = GLib.DateTime.currentDateTimeUtc ().addDays (-4);
        mtime.setMSecsSinceEpoch (mtime.toMSecsSinceEpoch () / 1000 * 1000);

        fakeFolder.local_modifier ().set_contents ("A/a1", 'C');
        fakeFolder.local_modifier ().set_modification_time ("A/a1", mtime);
        fakeFolder.remote_modifier ().set_contents ("A/a1", 'C');
        if (!sameMtime)
            mtime = mtime.addDays (1);
        fakeFolder.remote_modifier ().set_modification_time ("A/a1", mtime);
        remoteInfo.find ("A/a1").checksums = checksums;
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nGET, expectedGET);

        // check that mtime in journal and filesystem agree
        string a1path = fakeFolder.local_path () + "A/a1";
        SyncJournalFileRecord a1record;
        fakeFolder.sync_journal ().getFileRecord (GLib.ByteArray ("A/a1"), a1record);
        QCOMPARE (a1record.modtime, (int64)FileSystem.getModTime (a1path));

        // Extra sync reads from database, no difference
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nGET, expectedGET);
    }


    /***********************************************************
     * Checks whether SyncFileItems have the expected properties before on_signal_start
     * of propagation.
     */
    private on_ void testSyncFileItemProperties () {
        var initialMtime = GLib.DateTime.currentDateTimeUtc ().addDays (-7);
        var changedMtime = GLib.DateTime.currentDateTimeUtc ().addDays (-4);
        var changedMtime2 = GLib.DateTime.currentDateTimeUtc ().addDays (-3);

        // Base mtime with no ms content (filesystem is seconds only)
        initialMtime.setMSecsSinceEpoch (initialMtime.toMSecsSinceEpoch () / 1000 * 1000);
        changedMtime.setMSecsSinceEpoch (changedMtime.toMSecsSinceEpoch () / 1000 * 1000);
        changedMtime2.setMSecsSinceEpoch (changedMtime2.toMSecsSinceEpoch () / 1000 * 1000);

        // Ensure the initial mtimes are as expected
        var initialFileInfo = FileInfo.A12_B12_C12_S12 ();
        initialFileInfo.set_modification_time ("A/a1", initialMtime);
        initialFileInfo.set_modification_time ("B/b1", initialMtime);
        initialFileInfo.set_modification_time ("C/c1", initialMtime);

        FakeFolder fakeFolder{ initialFileInfo };

        // upload a
        fakeFolder.local_modifier ().append_byte ("A/a1");
        fakeFolder.local_modifier ().set_modification_time ("A/a1", changedMtime);
        // download b
        fakeFolder.remote_modifier ().append_byte ("B/b1");
        fakeFolder.remote_modifier ().set_modification_time ("B/b1", changedMtime);
        // conflict c
        fakeFolder.local_modifier ().append_byte ("C/c1");
        fakeFolder.local_modifier ().append_byte ("C/c1");
        fakeFolder.local_modifier ().set_modification_time ("C/c1", changedMtime);
        fakeFolder.remote_modifier ().append_byte ("C/c1");
        fakeFolder.remote_modifier ().set_modification_time ("C/c1", changedMtime2);

        connect (&fakeFolder.sync_engine (), &SyncEngine.aboutToPropagate, [&] (SyncFileItemVector items) {
            SyncFileItemPtr a1, b1, c1;
            for (var item : items) {
                if (item.file == "A/a1")
                    a1 = item;
                if (item.file == "B/b1")
                    b1 = item;
                if (item.file == "C/c1")
                    c1 = item;
            }

            // a1 : should have local size and modtime
            QVERIFY (a1);
            QCOMPARE (a1.instruction, CSYNC_INSTRUCTION_SYNC);
            QCOMPARE (a1.direction, SyncFileItem.Direction.UP);
            QCOMPARE (a1.size, int64 (5));

            QCOMPARE (Utility.qDateTimeFromTime_t (a1.modtime), changedMtime);
            QCOMPARE (a1.previousSize, int64 (4));
            QCOMPARE (Utility.qDateTimeFromTime_t (a1.previousModtime), initialMtime);

            // b2 : should have remote size and modtime
            QVERIFY (b1);
            QCOMPARE (b1.instruction, CSYNC_INSTRUCTION_SYNC);
            QCOMPARE (b1.direction, SyncFileItem.Direction.DOWN);
            QCOMPARE (b1.size, int64 (17));
            QCOMPARE (Utility.qDateTimeFromTime_t (b1.modtime), changedMtime);
            QCOMPARE (b1.previousSize, int64 (16));
            QCOMPARE (Utility.qDateTimeFromTime_t (b1.previousModtime), initialMtime);

            // c1 : conflicts are downloads, so remote size and modtime
            QVERIFY (c1);
            QCOMPARE (c1.instruction, CSYNC_INSTRUCTION_CONFLICT);
            QCOMPARE (c1.direction, SyncFileItem.Direction.NONE);
            QCOMPARE (c1.size, int64 (25));
            QCOMPARE (Utility.qDateTimeFromTime_t (c1.modtime), changedMtime2);
            QCOMPARE (c1.previousSize, int64 (26));
            QCOMPARE (Utility.qDateTimeFromTime_t (c1.previousModtime), changedMtime);
        });

        QVERIFY (fakeFolder.sync_once ());
    }


    /***********************************************************
     * Checks whether subsequent large uploads are skipped after a 507 error
     */
     private on_ void testInsufficientRemoteStorage () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        // Disable parallel uploads
        SyncOptions syncOptions;
        syncOptions.parallelNetworkJobs = 0;
        fakeFolder.sync_engine ().setSyncOptions (syncOptions);

        // Produce an error based on upload size
        int remoteQuota = 1000;
        int n507 = 0, nPUT = 0;
        GLib.Object parent;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice outgoingData) . Soup.Reply * {
            //  Q_UNUSED (outgoingData)

            if (operation == QNetworkAccessManager.PutOperation) {
                nPUT++;
                if (request.rawHeader ("OC-Total-Length").toInt () > remoteQuota) {
                    n507++;
                    return new FakeErrorReply (operation, request, parent, 507);
                }
            }
            return null;
        });

        fakeFolder.local_modifier ().insert ("A/big", 800);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nPUT, 1);
        QCOMPARE (n507, 0);

        nPUT = 0;
        fakeFolder.local_modifier ().insert ("A/big1", 500); // ok
        fakeFolder.local_modifier ().insert ("A/big2", 1200); // 507 (quota guess now 1199)
        fakeFolder.local_modifier ().insert ("A/big3", 1200); // skipped
        fakeFolder.local_modifier ().insert ("A/big4", 1500); // skipped
        fakeFolder.local_modifier ().insert ("A/big5", 1100); // 507 (quota guess now 1099)
        fakeFolder.local_modifier ().insert ("A/big6", 900); // ok (quota guess now 199)
        fakeFolder.local_modifier ().insert ("A/big7", 200); // skipped
        fakeFolder.local_modifier ().insert ("A/big8", 199); // ok (quota guess now 0)

        fakeFolder.local_modifier ().insert ("B/big8", 1150); // 507
        QVERIFY (!fakeFolder.sync_once ());
        QCOMPARE (nPUT, 6);
        QCOMPARE (n507, 3);
    }

    // Checks whether downloads with bad checksums are accepted
    private on_ void testChecksumValidation () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        GLib.Object parent;

        GLib.ByteArray checksumValue;
        GLib.ByteArray contentMd5Value;

        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation) {
                var reply = new FakeGetReply (fakeFolder.remote_modifier (), operation, request, parent);
                if (!checksumValue.isNull ())
                    reply.setRawHeader ("OC-Checksum", checksumValue);
                if (!contentMd5Value.isNull ())
                    reply.setRawHeader ("Content-MD5", contentMd5Value);
                return reply;
            }
            return null;
        });

        // Basic case
        fakeFolder.remote_modifier ().create ("A/a3", 16, 'A');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Bad OC-Checksum
        checksumValue = "SHA1:bad";
        fakeFolder.remote_modifier ().create ("A/a4", 16, 'A');
        QVERIFY (!fakeFolder.sync_once ());

        // Good OC-Checksum
        checksumValue = "SHA1:19b1928d58a2030d08023f3d7054516dbc186f20"; // printf 'A%.0s' {1..16} | sha1sum -
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        checksumValue = GLib.ByteArray ();

        // Bad Content-MD5
        contentMd5Value = "bad";
        fakeFolder.remote_modifier ().create ("A/a5", 16, 'A');
        QVERIFY (!fakeFolder.sync_once ());

        // Good Content-MD5
        contentMd5Value = "d8a73157ce10cd94a91c2079fc9a92c8"; // printf 'A%.0s' {1..16} | md5sum -
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Invalid OC-Checksum is ignored
        checksumValue = "garbage";
        // contentMd5Value is still good
        fakeFolder.remote_modifier ().create ("A/a6", 16, 'A');
        QVERIFY (fakeFolder.sync_once ());
        contentMd5Value = "bad";
        fakeFolder.remote_modifier ().create ("A/a7", 16, 'A');
        QVERIFY (!fakeFolder.sync_once ());
        contentMd5Value.clear ();
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // OC-Checksum contains Unsupported checksums
        checksumValue = "Unsupported:XXXX SHA1:invalid Invalid:XxX";
        fakeFolder.remote_modifier ().create ("A/a8", 16, 'A');
        QVERIFY (!fakeFolder.sync_once ()); // Since the supported SHA1 checksum is invalid, no download
        checksumValue =  "Unsupported:XXXX SHA1:19b1928d58a2030d08023f3d7054516dbc186f20 Invalid:XxX";
        QVERIFY (fakeFolder.sync_once ()); // The supported SHA1 checksum is valid now, so the file are downloaded
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // Tests the behavior of invalid filename detection
    private on_ void testInvalidFilenameRegex () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        // For current servers, no characters are forbidden
        fakeFolder.sync_engine ().account ().setServerVersion ("10.0.0");
        fakeFolder.local_modifier ().insert ("A/\\:?*\"<>|.txt");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // For legacy servers, some characters were forbidden by the client
        fakeFolder.sync_engine ().account ().setServerVersion ("8.0.0");
        fakeFolder.local_modifier ().insert ("B/\\:?*\"<>|.txt");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (!fakeFolder.current_remote_state ().find ("B/\\:?*\"<>|.txt"));

        // We can override that by setting the capability
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "invalidFilenameRegex", "" } } } });
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Check that new servers also accept the capability
        fakeFolder.sync_engine ().account ().setServerVersion ("10.0.0");
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "invalidFilenameRegex", "my[fgh]ile" } } } });
        fakeFolder.local_modifier ().insert ("C/myfile.txt");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (!fakeFolder.current_remote_state ().find ("C/myfile.txt"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDiscoveryHiddenFile () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // We can't depend on current_local_state for hidden files since
        // it should rightfully skip things like download temporaries
        var localFileExists = [&] (string name) {
            return GLib.FileInfo (fakeFolder.local_path () + name).exists ();
        }

        fakeFolder.sync_engine ().setIgnoreHiddenFiles (true);
        fakeFolder.remote_modifier ().insert ("A/.hidden");
        fakeFolder.local_modifier ().insert ("B/.hidden");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (!localFileExists ("A/.hidden"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("B/.hidden"));

        fakeFolder.sync_engine ().setIgnoreHiddenFiles (false);
        fakeFolder.sync_journal ().forceRemoteDiscoveryNextSync ();
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (localFileExists ("A/.hidden"));
        QVERIFY (fakeFolder.current_remote_state ().find ("B/.hidden"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testNoLocalEncoding () {
        var utf8Locale = QTextCodec.codecForLocale ();
        if (utf8Locale.mibEnum () != 106) {
            QSKIP ("Test only works for UTF8 locale");
        }

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Utf8 locale can sync both
        fakeFolder.remote_modifier ().insert ("A/tößt");
        fakeFolder.remote_modifier ().insert ("A/t𠜎t");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_local_state ().find ("A/tößt"));
        QVERIFY (fakeFolder.current_local_state ().find ("A/t𠜎t"));

        // Try again with a locale that can represent ö but not 𠜎 (4-byte utf8).
        QTextCodec.setCodecForLocale (QTextCodec.codecForName ("ISO-8859-15"));
        QVERIFY (QTextCodec.codecForLocale ().mibEnum () == 111);

        fakeFolder.remote_modifier ().insert ("B/tößt");
        fakeFolder.remote_modifier ().insert ("B/t𠜎t");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_local_state ().find ("B/tößt"));
        QVERIFY (!fakeFolder.current_local_state ().find ("B/t𠜎t"));
        QVERIFY (!fakeFolder.current_local_state ().find ("B/t?t"));
        QVERIFY (!fakeFolder.current_local_state ().find ("B/t??t"));
        QVERIFY (!fakeFolder.current_local_state ().find ("B/t???t"));
        QVERIFY (!fakeFolder.current_local_state ().find ("B/t????t"));
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_remote_state ().find ("B/tößt"));
        QVERIFY (fakeFolder.current_remote_state ().find ("B/t𠜎t"));

        // Try again with plain ascii
        QTextCodec.setCodecForLocale (QTextCodec.codecForName ("ASCII"));
        QVERIFY (QTextCodec.codecForLocale ().mibEnum () == 3);

        fakeFolder.remote_modifier ().insert ("C/tößt");
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (!fakeFolder.current_local_state ().find ("C/tößt"));
        QVERIFY (!fakeFolder.current_local_state ().find ("C/t??t"));
        QVERIFY (!fakeFolder.current_local_state ().find ("C/t????t"));
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_remote_state ().find ("C/tößt"));

        QTextCodec.setCodecForLocale (utf8Locale);
    }

    // Aborting has had bugs when there are parallel upload jobs
    private on_ void testUploadV1Multiabort () {
        FakeFolder fakeFolder{ FileInfo{} };
        SyncOptions options;
        options.initialChunkSize = 10;
        options.maxChunkSize = 10;
        options.minChunkSize = 10;
        fakeFolder.sync_engine ().setSyncOptions (options);

        GLib.Object parent;
        int nPUT = 0;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                ++nPUT;
                return new FakeHangingReply (operation, request, parent);
            }
            return null;
        });

        fakeFolder.local_modifier ().insert ("file", 100, 'W');
        QTimer.singleShot (100, fakeFolder.sync_engine (), [&] () { fakeFolder.sync_engine ().on_signal_abort (); });
        QVERIFY (!fakeFolder.sync_once ());

        QCOMPARE (nPUT, 3);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPropagatePermissions () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        var perm = QFileDevice.Permission (0x7704); // user/owner : rwx, group : r, other : -
        GLib.File.setPermissions (fakeFolder.local_path () + "A/a1", perm);
        GLib.File.setPermissions (fakeFolder.local_path () + "A/a2", perm);
        fakeFolder.sync_once (); // get the metadata-only change out of the way
        fakeFolder.remote_modifier ().append_byte ("A/a1");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.sync_once (); // perms should be preserved
        QCOMPARE (GLib.FileInfo (fakeFolder.local_path () + "A/a1").permissions (), perm);
        QCOMPARE (GLib.FileInfo (fakeFolder.local_path () + "A/a2").permissions (), perm);

        var conflictName = fakeFolder.sync_journal ().conflictRecord (fakeFolder.sync_journal ().conflictRecordPaths ().first ()).path;
        QVERIFY (conflictName.contains ("A/a2"));
        QCOMPARE (GLib.FileInfo (fakeFolder.local_path () + conflictName).permissions (), perm);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testEmptyLocalButHasRemote () {
        FakeFolder fakeFolder{ FileInfo{} };
        fakeFolder.remote_modifier ().mkdir ("foo");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        QVERIFY (fakeFolder.current_local_state ().find ("foo"));

    }

    // Check that server mtime is set on directories on initial propagation
    private on_ void testDirectoryInitialMtime () {
        FakeFolder fakeFolder{ FileInfo{} };
        fakeFolder.remote_modifier ().mkdir ("foo");
        fakeFolder.remote_modifier ().insert ("foo/bar");
        var datetime = GLib.DateTime.currentDateTime ();
        datetime.setSecsSinceEpoch (datetime.toSecsSinceEpoch ()); // wipe ms
        fakeFolder.remote_modifier ().find ("foo").lastModified = datetime;

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        QCOMPARE (GLib.FileInfo (fakeFolder.local_path () + "foo").lastModified (), datetime);
    }


    /***********************************************************
     * Checks whether subsequent large uploads are skipped after a 507 error
     */
     private on_ void testErrorsWithBulkUpload () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"bulkupload", "1.0"} } } });

        // Disable parallel uploads
        SyncOptions syncOptions;
        syncOptions.parallelNetworkJobs = 0;
        fakeFolder.sync_engine ().setSyncOptions (syncOptions);

        int nPUT = 0;
        int nPOST = 0;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice outgoingData) . Soup.Reply * {
            var contentType = request.header (Soup.Request.ContentTypeHeader).toString ();
            if (operation == QNetworkAccessManager.PostOperation) {
                ++nPOST;
                if (contentType.startsWith (QStringLiteral ("multipart/related; boundary="))) {
                    var jsonReplyObject = fakeFolder.for_each_reply_part (outgoingData, contentType, [] (GLib.HashMap<string, GLib.ByteArray> allHeaders) . QJsonObject {
                        var reply = QJsonObject{};
                        const var fileName = allHeaders[QStringLiteral ("X-File-Path")];
                        if (fileName.endsWith ("A/big2") ||
                                fileName.endsWith ("A/big3") ||
                                fileName.endsWith ("A/big4") ||
                                fileName.endsWith ("A/big5") ||
                                fileName.endsWith ("A/big7") ||
                                fileName.endsWith ("B/big8")) {
                            reply.insert (QStringLiteral ("error"), true);
                            reply.insert (QStringLiteral ("etag"), {});
                            return reply;
                        } else {
                            reply.insert (QStringLiteral ("error"), false);
                            reply.insert (QStringLiteral ("etag"), {});
                        }
                        return reply;
                    });
                    if (jsonReplyObject.size ()) {
                        var jsonReply = QJsonDocument{};
                        jsonReply.setObject (jsonReplyObject);
                        return new FakeJsonErrorReply{operation, request, this, 200, jsonReply};
                    }
                    return  null;
                }
            } else if (operation == QNetworkAccessManager.PutOperation) {
                ++nPUT;
                const var fileName = getFilePathFromUrl (request.url ());
                if (fileName.endsWith ("A/big2") ||
                        fileName.endsWith ("A/big3") ||
                        fileName.endsWith ("A/big4") ||
                        fileName.endsWith ("A/big5") ||
                        fileName.endsWith ("A/big7") ||
                        fileName.endsWith ("B/big8")) {
                    return new FakeErrorReply (operation, request, this, 412);
                }
                return  null;
            }
            return  null;
        });

        fakeFolder.local_modifier ().insert ("A/big", 1);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nPUT, 0);
        QCOMPARE (nPOST, 1);
        nPUT = 0;
        nPOST = 0;

        fakeFolder.local_modifier ().insert ("A/big1", 1); // ok
        fakeFolder.local_modifier ().insert ("A/big2", 1); // ko
        fakeFolder.local_modifier ().insert ("A/big3", 1); // ko
        fakeFolder.local_modifier ().insert ("A/big4", 1); // ko
        fakeFolder.local_modifier ().insert ("A/big5", 1); // ko
        fakeFolder.local_modifier ().insert ("A/big6", 1); // ok
        fakeFolder.local_modifier ().insert ("A/big7", 1); // ko
        fakeFolder.local_modifier ().insert ("A/big8", 1); // ok
        fakeFolder.local_modifier ().insert ("B/big8", 1); // ko

        QVERIFY (!fakeFolder.sync_once ());
        QCOMPARE (nPUT, 0);
        QCOMPARE (nPOST, 1);
        nPUT = 0;
        nPOST = 0;

        QVERIFY (!fakeFolder.sync_once ());
        QCOMPARE (nPUT, 6);
        QCOMPARE (nPOST, 0);
    }
}

QTEST_GUILESS_MAIN (TestSyncEngine)
