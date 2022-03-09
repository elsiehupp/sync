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
    var item = spy.find_item (path);
    if (item) {
        return item.instruction != CSYNC_INSTRUCTION_NONE && item.instruction != CSYNC_INSTRUCTION_UPDATE_METADATA;
    }
    return false;
}

bool itemInstruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.find_item (path);
    return item.instruction == instr;
}

bool itemDidCompleteSuccessfully (ItemCompletedSpy spy, string path) {
    var item = spy.find_item (path);
    if (item) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

bool itemDidCompleteSuccessfullyWithExpectedRank (ItemCompletedSpy spy, string path, int rank) {
    var item = spy.find_item_with_expected_rank (path, rank);
    if (item) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

int itemSuccessfullyCompletedGetRank (ItemCompletedSpy spy, string path) {
    var itItem = std.find_if (spy.begin (), spy.end (), (currentItem) => {
        var item = currentItem[0].template_value<Occ.SyncFileItemPtr> ();
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
    private void on_testFileDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.remote_modifier ().insert ("A/a0");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "A/a0"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_file_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.local_modifier ().insert ("A/a0");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "A/a0"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testDirDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.remote_modifier ().mkdir ("Y");
        fake_folder.remote_modifier ().mkdir ("Z");
        fake_folder.remote_modifier ().insert ("Z/d0");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Y"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Z"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Z/d0"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testDirUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.local_modifier ().mkdir ("Y");
        fake_folder.local_modifier ().mkdir ("Z");
        fake_folder.local_modifier ().insert ("Z/d0");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Y"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Z"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Z/d0"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testDirUploadWithDelayedAlgorithm () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "dav", QVariantMap{ {"bulkupload", "1.0"} } } });

        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.local_modifier ().mkdir ("Y");
        fake_folder.local_modifier ().insert ("Y/d0");
        fake_folder.local_modifier ().mkdir ("Z");
        fake_folder.local_modifier ().insert ("Z/d0");
        fake_folder.local_modifier ().insert ("A/a0");
        fake_folder.local_modifier ().insert ("B/b0");
        fake_folder.local_modifier ().insert ("r0");
        fake_folder.local_modifier ().insert ("r1");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfullyWithExpectedRank (complete_spy, "Y", 0));
        GLib.assert_true (itemDidCompleteSuccessfullyWithExpectedRank (complete_spy, "Z", 1));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Y/d0"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "Y/d0") > 1);
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "Z/d0"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "Z/d0") > 1);
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "A/a0"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "A/a0") > 1);
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "B/b0"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "B/b0") > 1);
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "r0"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "r0") > 1);
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "r1"));
        GLib.assert_true (itemSuccessfullyCompletedGetRank (complete_spy, "r1") > 1);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testLocalDelete () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.remote_modifier ().remove ("A/a1");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "A/a1"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testRemoteDelete () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.local_modifier ().remove ("A/a1");
        fake_folder.sync_once ();
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "A/a1"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testEmlLocalChecksum () {
        FakeFolder fake_folder = new FakeFolder (FileInfo{}};
        fake_folder.local_modifier ().insert ("a1.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("a2.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("a3.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("b3.txt", 64, 'A');
        // Upload and calculate the checksums
        // fake_folder.sync_once ();
        fake_folder.sync_once ();

        var getDbChecksum = [&] (string path) {
            SyncJournalFileRecord record;
            fake_folder.sync_journal ().get_file_record (path, record);
            return record.checksum_header;
        }

        // printf 'A%.0s' {1..64} | sha1sum -
        GLib.ByteArray referenceChecksum ("SHA1:30b86e44e6001403827a62c58b08893e77cf121f");
        GLib.assert_cmp (getDbChecksum ("a1.eml"), referenceChecksum);
        GLib.assert_cmp (getDbChecksum ("a2.eml"), referenceChecksum);
        GLib.assert_cmp (getDbChecksum ("a3.eml"), referenceChecksum);
        GLib.assert_cmp (getDbChecksum ("b3.txt"), referenceChecksum);

        ItemCompletedSpy complete_spy (fake_folder);
        // Touch the file without changing the content, shouldn't upload
        fake_folder.local_modifier ().set_contents ("a1.eml", 'A');
        // Change the content/size
        fake_folder.local_modifier ().set_contents ("a2.eml", 'B');
        fake_folder.local_modifier ().append_byte ("a3.eml");
        fake_folder.local_modifier ().append_byte ("b3.txt");
        fake_folder.sync_once ();

        GLib.assert_cmp (getDbChecksum ("a1.eml"), referenceChecksum);
        GLib.assert_cmp (getDbChecksum ("a2.eml"), GLib.ByteArray ("SHA1:84951fc23a4dafd10020ac349da1f5530fa65949"));
        GLib.assert_cmp (getDbChecksum ("a3.eml"), GLib.ByteArray ("SHA1:826b7e7a7af8a529ae1c7443c23bf185c0ad440c"));
        GLib.assert_cmp (getDbChecksum ("b3.eml"), getDbChecksum ("a3.txt"));

        GLib.assert_true (!itemDidComplete (complete_spy, "a1.eml"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "a2.eml"));
        GLib.assert_true (itemDidCompleteSuccessfully (complete_spy, "a3.eml"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_testSelectiveSyncBug () {
        // issue owncloud/enterprise#1965 : files from selective-sync ignored
        // folders are uploaded anyway is some circumstances.
        FakeFolder fake_folder = new FakeFolder (new FileInfo ("", {
            new FileInfo ( "parentFolder", {
                new FileInfo ("subFolderA", {
                    { "fileA.txt", 400 },
                    { "fileB.txt", 400, 'o' },
                    { ??? },
                    new FileInfonfo ( "subsubFolder", {
                        { "fileC.txt", 400 },
                        { "fileD.txt", 400, 'o' }
                    }),
                    new FileInfo ("anotherFolder", {
                        new FileInfo ( "emptyFolder", { } ),
                        new FileInfo ( "subsubFolder", {
                            { "fileE.txt", 400 },
                            { "fileF.txt", 400, 'o' }
                        })
                    })
                }),
                new FileInfo ("subFolderB", {})
            })
        }));

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        var expectedServerState = fake_folder.current_remote_state ();

        // Remove subFolderA with selectiveSync:
        fake_folder.sync_engine ().journal ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {"parentFolder/subFolderA/"});
        fake_folder.sync_engine ().journal ().schedulePathForRemoteDiscovery (QByteArrayLiteral ("parentFolder/subFolderA/"));
        var getEtag = (GLib.ByteArray file) => {
            SyncJournalFileRecord record;
            fake_folder.sync_journal ().get_file_record (file, record);
            return record.etag;
        }
        GLib.assert_true (getEtag ("parentFolder") == "this.invalid_");
        GLib.assert_true (getEtag ("parentFolder/subFolderA") == "this.invalid_");
        GLib.assert_true (getEtag ("parentFolder/subFolderA/subsubFolder") != "this.invalid_");

        // But touch local file before the next sync, such that the local folder
        // can't be removed
        fake_folder.local_modifier ().set_contents ("parentFolder/subFolderA/fileB.txt", 'n');
        fake_folder.local_modifier ().set_contents ("parentFolder/subFolderA/subsubFolder/fileD.txt", 'n');
        fake_folder.local_modifier ().set_contents ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileF.txt", 'n');

        // Several follow-up syncs don't change the state at all,
        // in particular the remote state doesn't change and fileB.txt
        // isn't uploaded.

        for (int i = 0; i < 3; ++i) {
            fake_folder.sync_once ();
 {
                // Nothing changed on the server
                GLib.assert_cmp (fake_folder.current_remote_state (), expectedServerState);
                // The local state should still have subFolderA
                var local = fake_folder.current_local_state ();
                GLib.assert_true (local.find ("parentFolder/subFolderA"));
                GLib.assert_true (!local.find ("parentFolder/subFolderA/fileA.txt"));
                GLib.assert_true (local.find ("parentFolder/subFolderA/fileB.txt"));
                GLib.assert_true (!local.find ("parentFolder/subFolderA/subsubFolder/fileC.txt"));
                GLib.assert_true (local.find ("parentFolder/subFolderA/subsubFolder/fileD.txt"));
                GLib.assert_true (!local.find ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileE.txt"));
                GLib.assert_true (local.find ("parentFolder/subFolderA/anotherFolder/subsubFolder/fileF.txt"));
                GLib.assert_true (!local.find ("parentFolder/subFolderA/anotherFolder/emptyFolder"));
                GLib.assert_true (local.find ("parentFolder/subFolderB"));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void abortAfterFailedMkdir () {
        FakeFolder fake_folder = new FakeFolder (FileInfo{}};
        QSignalSpy finishedSpy (&fake_folder.sync_engine (), SIGNAL (on_signal_finished (bool)));
        fake_folder.server_error_paths ().append ("NewFolder");
        fake_folder.local_modifier ().mkdir ("NewFolder");
        // This should be aborted and would otherwise fail in FileInfo.create.
        fake_folder.local_modifier ().insert ("NewFolder/NewFile");
        fake_folder.sync_once ();
        GLib.assert_cmp (finishedSpy.size (), 1);
        GLib.assert_cmp (finishedSpy.first ().first ().to_bool (), false);
    }

    /** Verify that an incompletely propagated directory doesn't have the server's
     * etag stored in the database yet. */
    private void testDirEtagAfterIncompleteSync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo{}};
        QSignalSpy finishedSpy (&fake_folder.sync_engine (), SIGNAL (on_signal_finished (bool)));
        fake_folder.server_error_paths ().append ("NewFolder/foo");
        fake_folder.remote_modifier ().mkdir ("NewFolder");
        fake_folder.remote_modifier ().insert ("NewFolder/foo");
        GLib.assert_true (!fake_folder.sync_once ());

        SyncJournalFileRecord record;
        fake_folder.sync_journal ().get_file_record (QByteArrayLiteral ("NewFolder"), record);
        GLib.assert_true (record.is_valid ());
        GLib.assert_cmp (record.etag, QByteArrayLiteral ("this.invalid_"));
        GLib.assert_true (!record.file_identifier.is_empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void testDirDownloadWithError () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);
        fake_folder.remote_modifier ().mkdir ("Y");
        fake_folder.remote_modifier ().mkdir ("Y/Z");
        fake_folder.remote_modifier ().insert ("Y/Z/d0");
        fake_folder.remote_modifier ().insert ("Y/Z/d1");
        fake_folder.remote_modifier ().insert ("Y/Z/d2");
        fake_folder.remote_modifier ().insert ("Y/Z/d3");
        fake_folder.remote_modifier ().insert ("Y/Z/d4");
        fake_folder.remote_modifier ().insert ("Y/Z/d5");
        fake_folder.remote_modifier ().insert ("Y/Z/d6");
        fake_folder.remote_modifier ().insert ("Y/Z/d7");
        fake_folder.remote_modifier ().insert ("Y/Z/d8");
        fake_folder.remote_modifier ().insert ("Y/Z/d9");
        fake_folder.server_error_paths ().append ("Y/Z/d2", 503);
        fake_folder.server_error_paths ().append ("Y/Z/d3", 503);
        GLib.assert_true (!fake_folder.sync_once ());
        QCoreApplication.processEvents (); // should not crash

        GLib.Set<string> seen;
        for (GLib.List<GLib.Variant> args : complete_spy) {
            var item = args[0].value<SyncFileItemPtr> ();
            GLib.debug () + item.file + item.isDirectory () + item.status;
            GLib.assert_true (!seen.contains (item.file)); // signal only sent once per item
            seen.insert (item.file);
            if (item.file == "Y/Z/d2") {
                GLib.assert_true (item.status == SyncFileItem.Status.NORMAL_ERROR);
            } else if (item.file == "Y/Z/d3") {
                GLib.assert_true (item.status != SyncFileItem.Status.SUCCESS);
            } else if (!item.isDirectory ()) {
                GLib.assert_true (item.status == SyncFileItem.Status.SUCCESS);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testFakeConflict_data () {
        QTest.add_column<bool> ("sameMtime");
        QTest.add_column<GLib.ByteArray> ("checksums");

        QTest.add_column<int> ("expectedGET");

        QTest.new_row ("Same mtime, but no server checksum . ignored in reconcile")
            + true + GLib.ByteArray ()
            << 0;

        QTest.new_row ("Same mtime, weak server checksum differ . downloaded")
            + true + GLib.ByteArray ("Adler32:bad")
            << 1;

        QTest.new_row ("Same mtime, matching weak checksum . skipped")
            + true + GLib.ByteArray ("Adler32:2a2010d")
            << 0;

        QTest.new_row ("Same mtime, strong server checksum differ . downloaded")
            + true + GLib.ByteArray ("SHA1:bad")
            << 1;

        QTest.new_row ("Same mtime, matching strong checksum . skipped")
            + true + GLib.ByteArray ("SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427")
            << 0;

        QTest.new_row ("mtime changed, but no server checksum . download")
            + false + GLib.ByteArray ()
            << 1;

        QTest.new_row ("mtime changed, weak checksum match . download anyway")
            + false + GLib.ByteArray ("Adler32:2a2010d")
            << 1;

        QTest.new_row ("mtime changed, strong checksum match . skip")
            + false + GLib.ByteArray ("SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427")
            << 0;
    }


    /***********************************************************
    ***********************************************************/
    private void testFakeConflict () {
        QFETCH (bool, sameMtime);
        QFETCH (GLib.ByteArray, checksums);
        QFETCH (int, expectedGET);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int n_get = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request &, QIODevice *) {
            if (operation == Soup.GetOperation)
                ++n_get;
            return null;
        });

        // For directly editing the remote checksum
        var remoteInfo = fake_folder.remote_modifier ();

        // Base mtime with no ms content (filesystem is seconds only)
        var mtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        mtime.setMSecsSinceEpoch (mtime.to_m_secs_since_epoch () / 1000 * 1000);

        fake_folder.local_modifier ().set_contents ("A/a1", 'C');
        fake_folder.local_modifier ().set_modification_time ("A/a1", mtime);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'C');
        if (!sameMtime)
            mtime = mtime.add_days (1);
        fake_folder.remote_modifier ().set_modification_time ("A/a1", mtime);
        remoteInfo.find ("A/a1").checksums = checksums;
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (n_get, expectedGET);

        // check that mtime in journal and filesystem agree
        string a1path = fake_folder.local_path () + "A/a1";
        SyncJournalFileRecord a1record;
        fake_folder.sync_journal ().get_file_record (GLib.ByteArray ("A/a1"), a1record);
        GLib.assert_cmp (a1record.modtime, (int64)FileSystem.getModTime (a1path));

        // Extra sync reads from database, no difference
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (n_get, expectedGET);
    }


    /***********************************************************
     * Checks whether SyncFileItems have the expected properties before on_signal_start
     * of propagation.
     */
    private void testSyncFileItemProperties () {
        var initialMtime = GLib.DateTime.current_date_time_utc ().add_days (-7);
        var changedMtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        var changedMtime2 = GLib.DateTime.current_date_time_utc ().add_days (-3);

        // Base mtime with no ms content (filesystem is seconds only)
        initialMtime.setMSecsSinceEpoch (initialMtime.to_m_secs_since_epoch () / 1000 * 1000);
        changedMtime.setMSecsSinceEpoch (changedMtime.to_m_secs_since_epoch () / 1000 * 1000);
        changedMtime2.setMSecsSinceEpoch (changedMtime2.to_m_secs_since_epoch () / 1000 * 1000);

        // Ensure the initial mtimes are as expected
        var initialFileInfo = FileInfo.A12_B12_C12_S12 ();
        initialFileInfo.set_modification_time ("A/a1", initialMtime);
        initialFileInfo.set_modification_time ("B/b1", initialMtime);
        initialFileInfo.set_modification_time ("C/c1", initialMtime);

        FakeFolder fake_folder = new FakeFolder ( initialFileInfo };

        // upload a
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().set_modification_time ("A/a1", changedMtime);
        // download b
        fake_folder.remote_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().set_modification_time ("B/b1", changedMtime);
        // conflict c
        fake_folder.local_modifier ().append_byte ("C/c1");
        fake_folder.local_modifier ().append_byte ("C/c1");
        fake_folder.local_modifier ().set_modification_time ("C/c1", changedMtime);
        fake_folder.remote_modifier ().append_byte ("C/c1");
        fake_folder.remote_modifier ().set_modification_time ("C/c1", changedMtime2);

        connect (&fake_folder.sync_engine (), &SyncEngine.about_to_propagate, [&] (SyncFileItemVector items) {
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
            GLib.assert_true (a1);
            GLib.assert_cmp (a1.instruction, CSYNC_INSTRUCTION_SYNC);
            GLib.assert_cmp (a1.direction, SyncFileItem.Direction.UP);
            GLib.assert_cmp (a1.size, int64 (5));

            GLib.assert_cmp (Utility.date_time_from_time_t (a1.modtime), changedMtime);
            GLib.assert_cmp (a1.previousSize, int64 (4));
            GLib.assert_cmp (Utility.date_time_from_time_t (a1.previousModtime), initialMtime);

            // b2 : should have remote size and modtime
            GLib.assert_true (b1);
            GLib.assert_cmp (b1.instruction, CSYNC_INSTRUCTION_SYNC);
            GLib.assert_cmp (b1.direction, SyncFileItem.Direction.DOWN);
            GLib.assert_cmp (b1.size, int64 (17));
            GLib.assert_cmp (Utility.date_time_from_time_t (b1.modtime), changedMtime);
            GLib.assert_cmp (b1.previousSize, int64 (16));
            GLib.assert_cmp (Utility.date_time_from_time_t (b1.previousModtime), initialMtime);

            // c1 : conflicts are downloads, so remote size and modtime
            GLib.assert_true (c1);
            GLib.assert_cmp (c1.instruction, CSYNC_INSTRUCTION_CONFLICT);
            GLib.assert_cmp (c1.direction, SyncFileItem.Direction.NONE);
            GLib.assert_cmp (c1.size, int64 (25));
            GLib.assert_cmp (Utility.date_time_from_time_t (c1.modtime), changedMtime2);
            GLib.assert_cmp (c1.previousSize, int64 (26));
            GLib.assert_cmp (Utility.date_time_from_time_t (c1.previousModtime), changedMtime);
        });

        GLib.assert_true (fake_folder.sync_once ());
    }


    /***********************************************************
     * Checks whether subsequent large uploads are skipped after a 507 error
     */
     private void testInsufficientRemoteStorage () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Disable parallel uploads
        SyncOptions sync_options;
        sync_options.parallelNetworkJobs = 0;
        fake_folder.sync_engine ().set_sync_options (sync_options);

        // Produce an error based on upload size
        int remoteQuota = 1000;
        int n507 = 0, number_of_put = 0;
        GLib.Object parent;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) . Soup.Reply * {
            Q_UNUSED (outgoing_data)

            if (operation == Soup.PutOperation) {
                number_of_put++;
                if (request.raw_header ("OC-Total-Length").to_int () > remoteQuota) {
                    n507++;
                    return new FakeErrorReply (operation, request, parent, 507);
                }
            }
            return null;
        });

        fake_folder.local_modifier ().insert ("A/big", 800);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 1);
        GLib.assert_cmp (n507, 0);

        number_of_put = 0;
        fake_folder.local_modifier ().insert ("A/big1", 500); // ok
        fake_folder.local_modifier ().insert ("A/big2", 1200); // 507 (quota guess now 1199)
        fake_folder.local_modifier ().insert ("A/big3", 1200); // skipped
        fake_folder.local_modifier ().insert ("A/big4", 1500); // skipped
        fake_folder.local_modifier ().insert ("A/big5", 1100); // 507 (quota guess now 1099)
        fake_folder.local_modifier ().insert ("A/big6", 900); // ok (quota guess now 199)
        fake_folder.local_modifier ().insert ("A/big7", 200); // skipped
        fake_folder.local_modifier ().insert ("A/big8", 199); // ok (quota guess now 0)

        fake_folder.local_modifier ().insert ("B/big8", 1150); // 507
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 6);
        GLib.assert_cmp (n507, 3);
    }

    // Checks whether downloads with bad checksums are accepted
    private void testChecksumValidation () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.Object parent;

        GLib.ByteArray checksumValue;
        GLib.ByteArray contentMd5Value;

        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation) {
                var reply = new FakeGetReply (fake_folder.remote_modifier (), operation, request, parent);
                if (!checksumValue.is_null ())
                    reply.set_raw_header ("OC-Checksum", checksumValue);
                if (!contentMd5Value.is_null ())
                    reply.set_raw_header ("Content-MD5", contentMd5Value);
                return reply;
            }
            return null;
        });

        // Basic case
        fake_folder.remote_modifier ().create ("A/a3", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Bad OC-Checksum
        checksumValue = "SHA1:bad";
        fake_folder.remote_modifier ().create ("A/a4", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good OC-Checksum
        checksumValue = "SHA1:19b1928d58a2030d08023f3d7054516dbc186f20"; // printf 'A%.0s' {1..16} | sha1sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        checksumValue = GLib.ByteArray ();

        // Bad Content-MD5
        contentMd5Value = "bad";
        fake_folder.remote_modifier ().create ("A/a5", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good Content-MD5
        contentMd5Value = "d8a73157ce10cd94a91c2079fc9a92c8"; // printf 'A%.0s' {1..16} | md5sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Invalid OC-Checksum is ignored
        checksumValue = "garbage";
        // contentMd5Value is still good
        fake_folder.remote_modifier ().create ("A/a6", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        contentMd5Value = "bad";
        fake_folder.remote_modifier ().create ("A/a7", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());
        contentMd5Value.clear ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // OC-Checksum contains Unsupported checksums
        checksumValue = "Unsupported:XXXX SHA1:invalid Invalid:XxX";
        fake_folder.remote_modifier ().create ("A/a8", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ()); // Since the supported SHA1 checksum is invalid, no download
        checksumValue =  "Unsupported:XXXX SHA1:19b1928d58a2030d08023f3d7054516dbc186f20 Invalid:XxX";
        GLib.assert_true (fake_folder.sync_once ()); // The supported SHA1 checksum is valid now, so the file are downloaded
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }

    // Tests the behavior of invalid filename detection
    private void testInvalidFilenameRegex () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // For current servers, no characters are forbidden
        fake_folder.sync_engine ().account ().set_server_version ("10.0.0");
        fake_folder.local_modifier ().insert ("A/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // For legacy servers, some characters were forbidden by the client
        fake_folder.sync_engine ().account ().set_server_version ("8.0.0");
        fake_folder.local_modifier ().insert ("B/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/\\:?*\"<>|.txt"));

        // We can override that by setting the capability
        fake_folder.sync_engine ().account ().set_capabilities ({ { "dav", QVariantMap{ { "invalidFilenameRegex", "" } } } });
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Check that new servers also accept the capability
        fake_folder.sync_engine ().account ().set_server_version ("10.0.0");
        fake_folder.sync_engine ().account ().set_capabilities ({ { "dav", QVariantMap{ { "invalidFilenameRegex", "my[fgh]ile" } } } });
        fake_folder.local_modifier ().insert ("C/myfile.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/myfile.txt"));
    }


    /***********************************************************
    ***********************************************************/
    private void testDiscoveryHiddenFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // We can't depend on current_local_state for hidden files since
        // it should rightfully skip things like download temporaries
        var localFileExists = [&] (string name) {
            return GLib.new FileInfo (fake_folder.local_path () + name).exists ();
        }

        fake_folder.sync_engine ().setIgnoreHiddenFiles (true);
        fake_folder.remote_modifier ().insert ("A/.hidden");
        fake_folder.local_modifier ().insert ("B/.hidden");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!localFileExists ("A/.hidden"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/.hidden"));

        fake_folder.sync_engine ().setIgnoreHiddenFiles (false);
        fake_folder.sync_journal ().forceRemoteDiscoveryNextSync ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (localFileExists ("A/.hidden"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/.hidden"));
    }


    /***********************************************************
    ***********************************************************/
    private void testNoLocalEncoding () {
        var utf8Locale = QTextCodec.codecForLocale ();
        if (utf8Locale.mibEnum () != 106) {
            QSKIP ("Test only works for UTF8 locale");
        }

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Utf8 locale can sync both
        fake_folder.remote_modifier ().insert ("A/tößt");
        fake_folder.remote_modifier ().insert ("A/t𠜎t");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/tößt"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/t𠜎t"));

        // Try again with a locale that can represent ö but not 𠜎 (4-byte utf8).
        QTextCodec.setCodecForLocale (QTextCodec.codecForName ("ISO-8859-15"));
        GLib.assert_true (QTextCodec.codecForLocale ().mibEnum () == 111);

        fake_folder.remote_modifier ().insert ("B/tößt");
        fake_folder.remote_modifier ().insert ("B/t𠜎t");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("B/tößt"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t𠜎t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t?t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t??t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t???t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t????t"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/tößt"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/t𠜎t"));

        // Try again with plain ascii
        QTextCodec.setCodecForLocale (QTextCodec.codecForName ("ASCII"));
        GLib.assert_true (QTextCodec.codecForLocale ().mibEnum () == 3);

        fake_folder.remote_modifier ().insert ("C/tößt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/tößt"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/t??t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/t????t"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/tößt"));

        QTextCodec.setCodecForLocale (utf8Locale);
    }

    // Aborting has had bugs when there are parallel upload jobs
    private void testUploadV1Multiabort () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo{} };
        SyncOptions options;
        options.initial_chunk_size = 10;
        options.max_chunk_size = 10;
        options.min_chunk_size = 10;
        fake_folder.sync_engine ().set_sync_options (options);

        GLib.Object parent;
        int number_of_put = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.PutOperation) {
                ++number_of_put;
                return new FakeHangingReply (operation, request, parent);
            }
            return null;
        });

        fake_folder.local_modifier ().insert ("file", 100, 'W');
        QTimer.single_shot (100, fake_folder.sync_engine (), [&] () { fake_folder.sync_engine ().on_signal_abort (); });
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_cmp (number_of_put, 3);
    }


    /***********************************************************
    ***********************************************************/
    private void testPropagatePermissions () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var perm = QFileDevice.Permission (0x7704); // user/owner : rwx, group : r, other : -
        GLib.File.setPermissions (fake_folder.local_path () + "A/a1", perm);
        GLib.File.setPermissions (fake_folder.local_path () + "A/a2", perm);
        fake_folder.sync_once (); // get the metadata-only change out of the way
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.sync_once (); // perms should be preserved
        GLib.assert_cmp (GLib.new FileInfo (fake_folder.local_path () + "A/a1").permissions (), perm);
        GLib.assert_cmp (GLib.new FileInfo (fake_folder.local_path () + "A/a2").permissions (), perm);

        var conflictName = fake_folder.sync_journal ().conflictRecord (fake_folder.sync_journal ().conflictRecordPaths ().first ()).path;
        GLib.assert_true (conflictName.contains ("A/a2"));
        GLib.assert_cmp (GLib.new FileInfo (fake_folder.local_path () + conflictName).permissions (), perm);
    }


    /***********************************************************
    ***********************************************************/
    private void testEmptyLocalButHasRemote () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo{} };
        fake_folder.remote_modifier ().mkdir ("foo");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        GLib.assert_true (fake_folder.current_local_state ().find ("foo"));

    }

    // Check that server mtime is set on directories on initial propagation
    private void testDirectoryInitialMtime () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo{} };
        fake_folder.remote_modifier ().mkdir ("foo");
        fake_folder.remote_modifier ().insert ("foo/bar");
        var datetime = GLib.DateTime.currentDateTime ();
        datetime.setSecsSinceEpoch (datetime.to_seconds_since_epoch ()); // wipe ms
        fake_folder.remote_modifier ().find ("foo").last_modified = datetime;

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        GLib.assert_cmp (GLib.new FileInfo (fake_folder.local_path () + "foo").last_modified (), datetime);
    }


    /***********************************************************
     * Checks whether subsequent large uploads are skipped after a 507 error
     */
     private void testErrorsWithBulkUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "dav", QVariantMap{ {"bulkupload", "1.0"} } } });

        // Disable parallel uploads
        SyncOptions sync_options;
        sync_options.parallelNetworkJobs = 0;
        fake_folder.sync_engine ().set_sync_options (sync_options);

        int number_of_put = 0;
        int nPOST = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) . Soup.Reply * {
            var content_type = request.header (Soup.Request.ContentTypeHeader).to_string ();
            if (operation == Soup.PostOperation) {
                ++nPOST;
                if (content_type.starts_with ("multipart/related; boundary=")) {
                    var jsonReplyObject = fake_folder.for_each_reply_part (outgoing_data, content_type, [] (GLib.HashMap<string, GLib.ByteArray> all_headers) . QJsonObject {
                        var reply = QJsonObject{};
                        var filename = all_headers["X-File-Path"];
                        if (filename.ends_with ("A/big2") ||
                                filename.ends_with ("A/big3") ||
                                filename.ends_with ("A/big4") ||
                                filename.ends_with ("A/big5") ||
                                filename.ends_with ("A/big7") ||
                                filename.ends_with ("B/big8")) {
                            reply.insert ("error", true);
                            reply.insert ("etag", {});
                            return reply;
                        } else {
                            reply.insert ("error", false);
                            reply.insert ("etag", {});
                        }
                        return reply;
                    });
                    if (jsonReplyObject.size ()) {
                        var jsonReply = QJsonDocument{};
                        jsonReply.set_object (jsonReplyObject);
                        return new FakeJsonErrorReply{operation, request, this, 200, jsonReply};
                    }
                    return  null;
                }
            } else if (operation == Soup.PutOperation) {
                ++number_of_put;
                var filename = get_file_path_from_url (request.url ());
                if (filename.ends_with ("A/big2") ||
                        filename.ends_with ("A/big3") ||
                        filename.ends_with ("A/big4") ||
                        filename.ends_with ("A/big5") ||
                        filename.ends_with ("A/big7") ||
                        filename.ends_with ("B/big8")) {
                    return new FakeErrorReply (operation, request, this, 412);
                }
                return  null;
            }
            return  null;
        });

        fake_folder.local_modifier ().insert ("A/big", 1);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 0);
        GLib.assert_cmp (nPOST, 1);
        number_of_put = 0;
        nPOST = 0;

        fake_folder.local_modifier ().insert ("A/big1", 1); // ok
        fake_folder.local_modifier ().insert ("A/big2", 1); // ko
        fake_folder.local_modifier ().insert ("A/big3", 1); // ko
        fake_folder.local_modifier ().insert ("A/big4", 1); // ko
        fake_folder.local_modifier ().insert ("A/big5", 1); // ko
        fake_folder.local_modifier ().insert ("A/big6", 1); // ok
        fake_folder.local_modifier ().insert ("A/big7", 1); // ko
        fake_folder.local_modifier ().insert ("A/big8", 1); // ok
        fake_folder.local_modifier ().insert ("B/big8", 1); // ko

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 0);
        GLib.assert_cmp (nPOST, 1);
        number_of_put = 0;
        nPOST = 0;

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 6);
        GLib.assert_cmp (nPOST, 0);
    }
}

QTEST_GUILESS_MAIN (TestSyncEngine)
