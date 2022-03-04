/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

/***********************************************************
Upload a 1/3 of a file of given size.
fakeFolder needs to be synchronized */
static void partialUpload (FakeFolder fakeFolder, string name, int64 size) {
    QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    QCOMPARE (fakeFolder.upload_state ().children.count (), 0); // The state should be clean

    fakeFolder.local_modifier ().insert (name, size);
    // Abort when the upload is at 1/3
    int64 sizeWhenAbort = -1;
    var con = GLib.Object.connect (&fakeFolder.sync_engine (),  &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () /3 )) {
                    sizeWhenAbort = progress.completedSize ();
                    fakeFolder.sync_engine ().on_signal_abort ();
                }
    });

    QVERIFY (!fakeFolder.sync_once ()); // there should have been an error
    GLib.Object.disconnect (con);
    QVERIFY (sizeWhenAbort > 0);
    QVERIFY (sizeWhenAbort < size);

    QCOMPARE (fakeFolder.upload_state ().children.count (), 1); // the transfer was done with chunking
    var upStateChildren = fakeFolder.upload_state ().children.first ().children;
    QCOMPARE (sizeWhenAbort, std.accumulate (upStateChildren.cbegin (), upStateChildren.cend (), 0,
                                            [] (int s, FileInfo i) { return s + i.size; }));
}

// Reduce max chunk size a bit so we get more chunks
static void setChunkSize (SyncEngine engine, int64 size) {
    SyncOptions options;
    options.maxChunkSize = size;
    options.initialChunkSize = size;
    options.minChunkSize = size;
    engine.setSyncOptions (options);
}

class TestChunkingNG : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testFileUpload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);
        const int size = 10 * 1000 * 1000; // 10 MB

        fakeFolder.local_modifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1); // the transfer was done with chunking
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);

        // Check that another upload of the same file also work.
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.upload_state ().children.count (), 2); // the transfer was done with chunking
    }

    // Test resuming when there's a confusing chunk added
    private on_ void testResume1 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;
        const var chunkMap = fakeFolder.upload_state ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 2 * 1000 * 1000); // at least 2 MB

        // Add a fake chunk to make sure it gets deleted
        fakeFolder.upload_state ().children.first ().insert ("10000", size);

        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                // Test that we properly resuming and are not sending past data again.
                //  Q_ASSERT (request.rawHeader ("OC-Chunk-Offset").toLongLong () >= uploadedSize);
            } else if (operation == QNetworkAccessManager.DeleteOperation) {
                //  Q_ASSERT (request.url ().path ().endsWith ("/10000"));
            }
            return null;
        });

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QCOMPARE (fakeFolder.upload_state ().children.first ().name, chunkingId);
    }

    // Test resuming when one of the uploaded chunks got removed
    private on_ void testResume2 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);
        const int size = 30 * 1000 * 1000; // 30 MB
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;
        const var chunkMap = fakeFolder.upload_state ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 2 * 1000 * 1000); // at least 50 MB
        QVERIFY (chunkMap.size () >= 3); // at least three chunks

        string[] chunksToDelete;

        // Remove the second chunk, so all further chunks will be deleted and resent
        var firstChunk = chunkMap.first ();
        var secondChunk = * (chunkMap.begin () + 1);
        for (var& name : chunkMap.keys ().mid (2)) {
            chunksToDelete.append (name);
        }
        fakeFolder.upload_state ().children.first ().remove (secondChunk.name);

        string[] deletedPaths;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                // Test that we properly resuming, not resending the first chunk
                //  Q_ASSERT (request.rawHeader ("OC-Chunk-Offset").toLongLong () >= firstChunk.size);
            } else if (operation == QNetworkAccessManager.DeleteOperation) {
                deletedPaths.append (request.url ().path ());
            }
            return null;
        });

        QVERIFY (fakeFolder.sync_once ());

        for (var& toDelete : chunksToDelete) {
            bool wasDeleted = false;
            for (var& deleted : deletedPaths) {
                if (deleted.mid (deleted.lastIndexOf ('/') + 1) == toDelete) {
                    wasDeleted = true;
                    break;
                }
            }
            QVERIFY (wasDeleted);
        }

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QCOMPARE (fakeFolder.upload_state ().children.first ().name, chunkingId);
    }

    // Test resuming when all chunks are already present
    private on_ void testResume3 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;
        const var chunkMap = fakeFolder.upload_state ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 5 * 1000 * 1000); // at least 5 MB

        // Add a chunk that makes the file completely uploaded
        fakeFolder.upload_state ().children.first ().insert (
            string.number (chunkMap.size ()).rightJustified (16, '0'), size - uploadedSize);

        bool sawPut = false;
        bool sawDelete = false;
        bool sawMove = false;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                sawPut = true;
            } else if (operation == QNetworkAccessManager.DeleteOperation) {
                sawDelete = true;
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                sawMove = true;
            }
            return null;
        });

        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (sawMove);
        QVERIFY (!sawPut);
        QVERIFY (!sawDelete);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QCOMPARE (fakeFolder.upload_state ().children.first ().name, chunkingId);
    }

    // Test resuming (or rather not resuming!) for the error case of the sum of
    // chunk sizes being larger than the file size
    private on_ void testResume4 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;
        const var chunkMap = fakeFolder.upload_state ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 5 * 1000 * 1000); // at least 5 MB

        // Add a chunk that makes the file more than completely uploaded
        fakeFolder.upload_state ().children.first ().insert (
            string.number (chunkMap.size ()).rightJustified (16, '0'), size - uploadedSize + 100);

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);
        // Used a new transfer identifier but wiped the old one
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QVERIFY (fakeFolder.upload_state ().children.first ().name != chunkingId);
    }

    // Check what happens when we on_signal_abort during the final MOVE and the
    // the final MOVE takes longer than the on_signal_abort-delay
    private on_ void testLateAbortHard () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = 15 * 1000 * 1000; // 15 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.Object parent;
        GLib.ByteArray moveChecksumHeader;
        int nGET = 0;
        int responseDelay = 100000; // bigger than on_signal_abort-wait timeout
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                QTimer.singleShot (50, parent, [&] () { fakeFolder.sync_engine ().on_signal_abort (); });
                moveChecksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.upload_state (), fakeFolder.remote_modifier (), operation, request, parent);
            } else if (operation == QNetworkAccessManager.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Test 1 : NEW file aborted
        fakeFolder.local_modifier ().insert ("A/a0", size);
        QVERIFY (!fakeFolder.sync_once ()); // error : on_signal_abort!

        // Now the next sync gets a NEW/NEW conflict and since there's no checksum
        // it just becomes a UPDATE_METADATA
        var checkEtagUpdated = [&] (SyncFileItemVector items) {
            QCOMPARE (items.size (), 1);
            QCOMPARE (items[0].file, QLatin1String ("A"));
            SyncJournalFileRecord record;
            QVERIFY (fakeFolder.sync_journal ().getFileRecord (GLib.ByteArray ("A/a0"), record));
            QCOMPARE (record.etag, fakeFolder.remote_modifier ().find ("A/a0").etag);
        }
        var connection = connect (&fakeFolder.sync_engine (), &SyncEngine.aboutToPropagate, checkEtagUpdated);
        QVERIFY (fakeFolder.sync_once ());
        disconnect (connection);
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Test 2 : modified file upload aborted
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (!fakeFolder.sync_once ()); // error : on_signal_abort!

        // An EVAL/EVAL conflict is also UPDATE_METADATA when there's no checksums
        connection = connect (&fakeFolder.sync_engine (), &SyncEngine.aboutToPropagate, checkEtagUpdated);
        QVERIFY (fakeFolder.sync_once ());
        disconnect (connection);
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Test 3 : modified file upload aborted, with good checksums
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (!fakeFolder.sync_once ()); // error : on_signal_abort!

        // Set the remote checksum -- the test setup doesn't do it automatically
        QVERIFY (!moveChecksumHeader.isEmpty ());
        fakeFolder.remote_modifier ().find ("A/a0").checksums = moveChecksumHeader;

        QVERIFY (fakeFolder.sync_once ());
        disconnect (connection);
        QCOMPARE (nGET, 0); // no new download, just a metadata update!
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Test 4 : New file, that gets deleted locally before the next sync
        fakeFolder.local_modifier ().insert ("A/a3", size);
        QVERIFY (!fakeFolder.sync_once ()); // error : on_signal_abort!
        fakeFolder.local_modifier ().remove ("A/a3");

        // bug : in this case we must expect a re-download of A/A3
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nGET, 1);
        QVERIFY (fakeFolder.current_local_state ().find ("A/a3"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // Check what happens when we on_signal_abort during the final MOVE and the
    // the final MOVE is short enough for the on_signal_abort-delay to help
    private on_ void testLateAbortRecoverable () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = 15 * 1000 * 1000; // 15 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.Object parent;
        int responseDelay = 200; // smaller than on_signal_abort-wait timeout
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                QTimer.singleShot (50, parent, [&] () { fakeFolder.sync_engine ().on_signal_abort (); });
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.upload_state (), fakeFolder.remote_modifier (), operation, request, parent);
            }
            return null;
        });

        // Test 1 : NEW file aborted
        fakeFolder.local_modifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Test 2 : modified file upload aborted
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // We modify the file locally after it has been partially uploaded
    private on_ void testRemoveStale1 () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;

        fakeFolder.local_modifier ().set_contents ("A/a0", 'B');
        fakeFolder.local_modifier ().append_byte ("A/a0");

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size + 1);
        // A different chunk identifier was used, and the previous one is removed
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QVERIFY (fakeFolder.upload_state ().children.first ().name != chunkingId);
    }

    // We remove the file locally after it has been partially uploaded
    private on_ void testRemoveStale2 () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);

        fakeFolder.local_modifier ().remove ("A/a0");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.upload_state ().children.count (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateConflictWhileSyncing () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        // Put a file on the server and download it.
        fakeFolder.remote_modifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Modify the file localy and on_signal_start the upload
        fakeFolder.local_modifier ().set_contents ("A/a0", 'B');
        fakeFolder.local_modifier ().append_byte ("A/a0");

        // But in the middle of the sync, modify the file on the server
        QMetaObject.Connection con = GLib.Object.connect (&fakeFolder.sync_engine (), &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () / 2 )) {
                    fakeFolder.remote_modifier ().set_contents ("A/a0", 'C');
                    GLib.Object.disconnect (con);
                }
        });

        QVERIFY (!fakeFolder.sync_once ());
        // There was a precondition failed error, this means wen need to sync again
        QCOMPARE (fakeFolder.sync_engine ().isAnotherSyncNeeded (), ImmediateFollowUp);

        QCOMPARE (fakeFolder.upload_state ().children.count (), 1); // We did not clean the chunks at this point

        // Now we will download the server file and create a conflict
        QVERIFY (fakeFolder.sync_once ());
        var localState = fakeFolder.current_local_state ();

        // A0 is the one from the server
        QCOMPARE (localState.find ("A/a0").size, size);
        QCOMPARE (localState.find ("A/a0").content_char, 'C');

        // There is a conflict file with our version
        var stateAChildren = localState.find ("A").children;
        var it = std.find_if (stateAChildren.cbegin (), stateAChildren.cend (), [&] (FileInfo fi) {
            return fi.name.startsWith ("a0 (conflicted copy");
        });
        QVERIFY (it != stateAChildren.cend ());
        QCOMPARE (it.content_char, 'B');
        QCOMPARE (it.size, size+1);

        // Remove the conflict file so the comparison works!
        fakeFolder.local_modifier ().remove ("A/" + it.name);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        QCOMPARE (fakeFolder.upload_state ().children.count (), 0); // The last sync cleaned the chunks
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testModifyLocalFileWhileUploading () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        fakeFolder.local_modifier ().insert ("A/a0", size);

        // middle of the sync, modify the file
        QMetaObject.Connection con = GLib.Object.connect (&fakeFolder.sync_engine (), &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () / 2 )) {
                    fakeFolder.local_modifier ().set_contents ("A/a0", 'B');
                    fakeFolder.local_modifier ().append_byte ("A/a0");
                    GLib.Object.disconnect (con);
                }
        });

        QVERIFY (!fakeFolder.sync_once ());

        // There should be a followup sync
        QCOMPARE (fakeFolder.sync_engine ().isAnotherSyncNeeded (), ImmediateFollowUp);

        QCOMPARE (fakeFolder.upload_state ().children.count (), 1); // We did not clean the chunks at this point
        var chunkingId = fakeFolder.upload_state ().children.first ().name;

        // Now we make a new sync which should upload the file for good.
        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size+1);

        // A different chunk identifier was used, and the previous one is removed
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QVERIFY (fakeFolder.upload_state ().children.first ().name != chunkingId);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testResumeServerDeletedChunks () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;

        // Delete the chunks on the server
        fakeFolder.upload_state ().children.clear ();
        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);

        // A different chunk identifier was used
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QVERIFY (fakeFolder.upload_state ().children.first ().name != chunkingId);
    }

    // Check what happens when the connection is dropped on the PUT (non-chunking) or MOVE (chunking)
    // for on the issue #5106
    private on_ void connectionDroppedBeforeEtagRecieved_data () {
        QTest.addColumn<bool> ("chunking");
        QTest.newRow ("big file") + true;
        QTest.newRow ("small file") + false;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void connectionDroppedBeforeEtagRecieved () {
        QFETCH (bool, chunking);
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = chunking ? 1 * 1000 * 1000 : 300;
        setChunkSize (fakeFolder.sync_engine (), 300 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.ByteArray checksumHeader;
        int nGET = 0;
        QScopedValueRollback<int> setHttpTimeout (AbstractNetworkJob.httpTimeout, 1);
        int responseDelay = AbstractNetworkJob.httpTimeout * 1000 * 1000; // much bigger than http timeout (so a timeout will occur)
        // This will perform the operation on the server, but the reply will not come to the client
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice outgoingData) . Soup.Reply * {
            if (!chunking) {
                //  Q_ASSERT (!request.url ().path ().contains ("/uploads/")
                    && "Should not touch uploads endpoint when not chunking");
            }
            if (!chunking && operation == QNetworkAccessManager.PutOperation) {
                checksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakePutReply> (responseDelay, fakeFolder.remote_modifier (), operation, request, outgoingData.readAll (), fakeFolder.sync_engine ());
            } else if (chunking && request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                checksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.upload_state (), fakeFolder.remote_modifier (), operation, request, fakeFolder.sync_engine ());
            } else if (operation == QNetworkAccessManager.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Test 1 : a NEW file
        fakeFolder.local_modifier ().insert ("A/a0", size);
        QVERIFY (!fakeFolder.sync_once ()); // timeout!
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ()); // but the upload succeeded
        QVERIFY (!checksumHeader.isEmpty ());
        fakeFolder.remote_modifier ().find ("A/a0").checksums = checksumHeader; // The test system don't do that automatically
        // Should be resolved properly
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Test 2 : Modify the file further
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (!fakeFolder.sync_once ()); // timeout!
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ()); // but the upload succeeded
        fakeFolder.remote_modifier ().find ("A/a0").checksums = checksumHeader;
        // modify again, should not cause conflict
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (!fakeFolder.sync_once ()); // now it's trying to upload the modified file
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        fakeFolder.remote_modifier ().find ("A/a0").checksums = checksumHeader;
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nGET, 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPercentEncoding () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 5 * 1000 * 1000;
        setChunkSize (fakeFolder.sync_engine (), 1 * 1000 * 1000);

        fakeFolder.local_modifier ().insert ("A/file % \u20ac", size);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Only the second upload contains an "If" header
        fakeFolder.local_modifier ().append_byte ("A/file % \u20ac");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // Test uploading large files (2.5GiB)
    private on_ void testVeryBigFiles () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int64 size = 2.5 * 1024 * 1024 * 1024; // 2.5 GiB

        // Partial upload of big files
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        var chunkingId = fakeFolder.upload_state ().children.first ().name;

        // Now resume
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size);

        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.upload_state ().children.count (), 1);
        QCOMPARE (fakeFolder.upload_state ().children.first ().name, chunkingId);

        // Upload another file again, this time without interruption
        fakeFolder.local_modifier ().append_byte ("A/a0");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a0").size, size + 1);
    }

}

QTEST_GUILESS_MAIN (TestChunkingNG)
#include "testchunkingng.moc"
