/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using namespace Occ;

/***********************************************************
Upload a 1/3 of a file of given size.
fakeFolder needs to be synchronized */
static void partialUpload (FakeFolder fakeFolder, string name, int64 size) {
    QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    QCOMPARE (fakeFolder.uploadState ().children.count (), 0); // The state should be clean

    fakeFolder.localModifier ().insert (name, size);
    // Abort when the upload is at 1/3
    int64 sizeWhenAbort = -1;
    var con = GLib.Object.connect (&fakeFolder.syncEngine (),  &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () /3 )) {
                    sizeWhenAbort = progress.completedSize ();
                    fakeFolder.syncEngine ().on_signal_abort ();
                }
    });

    QVERIFY (!fakeFolder.syncOnce ()); // there should have been an error
    GLib.Object.disconnect (con);
    QVERIFY (sizeWhenAbort > 0);
    QVERIFY (sizeWhenAbort < size);

    QCOMPARE (fakeFolder.uploadState ().children.count (), 1); // the transfer was done with chunking
    var upStateChildren = fakeFolder.uploadState ().children.first ().children;
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
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);
        const int size = 10 * 1000 * 1000; // 10 MB

        fakeFolder.localModifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1); // the transfer was done with chunking
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);

        // Check that another upload of the same file also work.
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.uploadState ().children.count (), 2); // the transfer was done with chunking
    }

    // Test resuming when there's a confusing chunk added
    private on_ void testResume1 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;
        const var chunkMap = fakeFolder.uploadState ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 2 * 1000 * 1000); // at least 2 MB

        // Add a fake chunk to make sure it gets deleted
        fakeFolder.uploadState ().children.first ().insert ("10000", size);

        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            if (op == QNetworkAccessManager.PutOperation) {
                // Test that we properly resuming and are not sending past data again.
                //  Q_ASSERT (request.rawHeader ("OC-Chunk-Offset").toLongLong () >= uploadedSize);
            } else if (op == QNetworkAccessManager.DeleteOperation) {
                //  Q_ASSERT (request.url ().path ().endsWith ("/10000"));
            }
            return null;
        });

        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QCOMPARE (fakeFolder.uploadState ().children.first ().name, chunkingId);
    }

    // Test resuming when one of the uploaded chunks got removed
    private on_ void testResume2 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);
        const int size = 30 * 1000 * 1000; // 30 MB
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;
        const var chunkMap = fakeFolder.uploadState ().children.first ().children;
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
        fakeFolder.uploadState ().children.first ().remove (secondChunk.name);

        string[] deletedPaths;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            if (op == QNetworkAccessManager.PutOperation) {
                // Test that we properly resuming, not resending the first chunk
                //  Q_ASSERT (request.rawHeader ("OC-Chunk-Offset").toLongLong () >= firstChunk.size);
            } else if (op == QNetworkAccessManager.DeleteOperation) {
                deletedPaths.append (request.url ().path ());
            }
            return null;
        });

        QVERIFY (fakeFolder.syncOnce ());

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

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QCOMPARE (fakeFolder.uploadState ().children.first ().name, chunkingId);
    }

    // Test resuming when all chunks are already present
    private on_ void testResume3 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;
        const var chunkMap = fakeFolder.uploadState ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 5 * 1000 * 1000); // at least 5 MB

        // Add a chunk that makes the file completely uploaded
        fakeFolder.uploadState ().children.first ().insert (
            string.number (chunkMap.size ()).rightJustified (16, '0'), size - uploadedSize);

        bool sawPut = false;
        bool sawDelete = false;
        bool sawMove = false;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            if (op == QNetworkAccessManager.PutOperation) {
                sawPut = true;
            } else if (op == QNetworkAccessManager.DeleteOperation) {
                sawDelete = true;
            } else if (request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                sawMove = true;
            }
            return null;
        });

        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (sawMove);
        QVERIFY (!sawPut);
        QVERIFY (!sawDelete);

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);
        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QCOMPARE (fakeFolder.uploadState ().children.first ().name, chunkingId);
    }

    // Test resuming (or rather not resuming!) for the error case of the sum of
    // chunk sizes being larger than the file size
    private on_ void testResume4 () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;
        const var chunkMap = fakeFolder.uploadState ().children.first ().children;
        int64 uploadedSize = std.accumulate (chunkMap.begin (), chunkMap.end (), 0LL, [] (int64 s, FileInfo f) { return s + f.size; });
        QVERIFY (uploadedSize > 5 * 1000 * 1000); // at least 5 MB

        // Add a chunk that makes the file more than completely uploaded
        fakeFolder.uploadState ().children.first ().insert (
            string.number (chunkMap.size ()).rightJustified (16, '0'), size - uploadedSize + 100);

        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);
        // Used a new transfer identifier but wiped the old one
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QVERIFY (fakeFolder.uploadState ().children.first ().name != chunkingId);
    }

    // Check what happens when we on_signal_abort during the final MOVE and the
    // the final MOVE takes longer than the on_signal_abort-delay
    private on_ void testLateAbortHard () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = 15 * 1000 * 1000; // 15 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.Object parent;
        GLib.ByteArray moveChecksumHeader;
        int nGET = 0;
        int responseDelay = 100000; // bigger than on_signal_abort-wait timeout
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            if (request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                QTimer.singleShot (50, parent, [&] () { fakeFolder.syncEngine ().on_signal_abort (); });
                moveChecksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.uploadState (), fakeFolder.remoteModifier (), op, request, parent);
            } else if (op == QNetworkAccessManager.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Test 1 : NEW file aborted
        fakeFolder.localModifier ().insert ("A/a0", size);
        QVERIFY (!fakeFolder.syncOnce ()); // error : on_signal_abort!

        // Now the next sync gets a NEW/NEW conflict and since there's no checksum
        // it just becomes a UPDATE_METADATA
        var checkEtagUpdated = [&] (SyncFileItemVector items) {
            QCOMPARE (items.size (), 1);
            QCOMPARE (items[0].file, QLatin1String ("A"));
            SyncJournalFileRecord record;
            QVERIFY (fakeFolder.syncJournal ().getFileRecord (GLib.ByteArray ("A/a0"), record));
            QCOMPARE (record.etag, fakeFolder.remoteModifier ().find ("A/a0").etag);
        }
        var connection = connect (&fakeFolder.syncEngine (), &SyncEngine.aboutToPropagate, checkEtagUpdated);
        QVERIFY (fakeFolder.syncOnce ());
        disconnect (connection);
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Test 2 : modified file upload aborted
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (!fakeFolder.syncOnce ()); // error : on_signal_abort!

        // An EVAL/EVAL conflict is also UPDATE_METADATA when there's no checksums
        connection = connect (&fakeFolder.syncEngine (), &SyncEngine.aboutToPropagate, checkEtagUpdated);
        QVERIFY (fakeFolder.syncOnce ());
        disconnect (connection);
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Test 3 : modified file upload aborted, with good checksums
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (!fakeFolder.syncOnce ()); // error : on_signal_abort!

        // Set the remote checksum -- the test setup doesn't do it automatically
        QVERIFY (!moveChecksumHeader.isEmpty ());
        fakeFolder.remoteModifier ().find ("A/a0").checksums = moveChecksumHeader;

        QVERIFY (fakeFolder.syncOnce ());
        disconnect (connection);
        QCOMPARE (nGET, 0); // no new download, just a metadata update!
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Test 4 : New file, that gets deleted locally before the next sync
        fakeFolder.localModifier ().insert ("A/a3", size);
        QVERIFY (!fakeFolder.syncOnce ()); // error : on_signal_abort!
        fakeFolder.localModifier ().remove ("A/a3");

        // bug : in this case we must expect a re-download of A/A3
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (nGET, 1);
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3"));
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }

    // Check what happens when we on_signal_abort during the final MOVE and the
    // the final MOVE is short enough for the on_signal_abort-delay to help
    private on_ void testLateAbortRecoverable () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = 15 * 1000 * 1000; // 15 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.Object parent;
        int responseDelay = 200; // smaller than on_signal_abort-wait timeout
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            if (request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                QTimer.singleShot (50, parent, [&] () { fakeFolder.syncEngine ().on_signal_abort (); });
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.uploadState (), fakeFolder.remoteModifier (), op, request, parent);
            }
            return null;
        });

        // Test 1 : NEW file aborted
        fakeFolder.localModifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Test 2 : modified file upload aborted
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }

    // We modify the file locally after it has been partially uploaded
    private on_ void testRemoveStale1 () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;

        fakeFolder.localModifier ().setContents ("A/a0", 'B');
        fakeFolder.localModifier ().appendByte ("A/a0");

        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size + 1);
        // A different chunk identifier was used, and the previous one is removed
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QVERIFY (fakeFolder.uploadState ().children.first ().name != chunkingId);
    }

    // We remove the file locally after it has been partially uploaded
    private on_ void testRemoveStale2 () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);

        fakeFolder.localModifier ().remove ("A/a0");

        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.uploadState ().children.count (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateConflictWhileSyncing () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        // Put a file on the server and download it.
        fakeFolder.remoteModifier ().insert ("A/a0", size);
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Modify the file localy and on_signal_start the upload
        fakeFolder.localModifier ().setContents ("A/a0", 'B');
        fakeFolder.localModifier ().appendByte ("A/a0");

        // But in the middle of the sync, modify the file on the server
        QMetaObject.Connection con = GLib.Object.connect (&fakeFolder.syncEngine (), &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () / 2 )) {
                    fakeFolder.remoteModifier ().setContents ("A/a0", 'C');
                    GLib.Object.disconnect (con);
                }
        });

        QVERIFY (!fakeFolder.syncOnce ());
        // There was a precondition failed error, this means wen need to sync again
        QCOMPARE (fakeFolder.syncEngine ().isAnotherSyncNeeded (), ImmediateFollowUp);

        QCOMPARE (fakeFolder.uploadState ().children.count (), 1); // We did not clean the chunks at this point

        // Now we will download the server file and create a conflict
        QVERIFY (fakeFolder.syncOnce ());
        var localState = fakeFolder.currentLocalState ();

        // A0 is the one from the server
        QCOMPARE (localState.find ("A/a0").size, size);
        QCOMPARE (localState.find ("A/a0").contentChar, 'C');

        // There is a conflict file with our version
        var stateAChildren = localState.find ("A").children;
        var it = std.find_if (stateAChildren.cbegin (), stateAChildren.cend (), [&] (FileInfo fi) {
            return fi.name.startsWith ("a0 (conflicted copy");
        });
        QVERIFY (it != stateAChildren.cend ());
        QCOMPARE (it.contentChar, 'B');
        QCOMPARE (it.size, size+1);

        // Remove the conflict file so the comparison works!
        fakeFolder.localModifier ().remove ("A/" + it.name);

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        QCOMPARE (fakeFolder.uploadState ().children.count (), 0); // The last sync cleaned the chunks
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testModifyLocalFileWhileUploading () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 10 * 1000 * 1000; // 10 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        fakeFolder.localModifier ().insert ("A/a0", size);

        // middle of the sync, modify the file
        QMetaObject.Connection con = GLib.Object.connect (&fakeFolder.syncEngine (), &SyncEngine.transmissionProgress,
                                    [&] (ProgressInfo progress) {
                if (progress.completedSize () > (progress.totalSize () / 2 )) {
                    fakeFolder.localModifier ().setContents ("A/a0", 'B');
                    fakeFolder.localModifier ().appendByte ("A/a0");
                    GLib.Object.disconnect (con);
                }
        });

        QVERIFY (!fakeFolder.syncOnce ());

        // There should be a followup sync
        QCOMPARE (fakeFolder.syncEngine ().isAnotherSyncNeeded (), ImmediateFollowUp);

        QCOMPARE (fakeFolder.uploadState ().children.count (), 1); // We did not clean the chunks at this point
        var chunkingId = fakeFolder.uploadState ().children.first ().name;

        // Now we make a new sync which should upload the file for good.
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size+1);

        // A different chunk identifier was used, and the previous one is removed
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QVERIFY (fakeFolder.uploadState ().children.first ().name != chunkingId);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testResumeServerDeletedChunks () {

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 30 * 1000 * 1000; // 30 MB
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;

        // Delete the chunks on the server
        fakeFolder.uploadState ().children.clear ();
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);

        // A different chunk identifier was used
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QVERIFY (fakeFolder.uploadState ().children.first ().name != chunkingId);
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
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } }, { "checksums", QVariantMap{ { "supportedTypes", string[] ("SHA1" } } } });
        const int size = chunking ? 1 * 1000 * 1000 : 300;
        setChunkSize (fakeFolder.syncEngine (), 300 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.ByteArray checksumHeader;
        int nGET = 0;
        QScopedValueRollback<int> setHttpTimeout (AbstractNetworkJob.httpTimeout, 1);
        int responseDelay = AbstractNetworkJob.httpTimeout * 1000 * 1000; // much bigger than http timeout (so a timeout will occur)
        // This will perform the operation on the server, but the reply will not come to the client
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice outgoingData) . Soup.Reply * {
            if (!chunking) {
                //  Q_ASSERT (!request.url ().path ().contains ("/uploads/")
                    && "Should not touch uploads endpoint when not chunking");
            }
            if (!chunking && op == QNetworkAccessManager.PutOperation) {
                checksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakePutReply> (responseDelay, fakeFolder.remoteModifier (), op, request, outgoingData.readAll (), fakeFolder.syncEngine ());
            } else if (chunking && request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                checksumHeader = request.rawHeader ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (responseDelay, fakeFolder.uploadState (), fakeFolder.remoteModifier (), op, request, fakeFolder.syncEngine ());
            } else if (op == QNetworkAccessManager.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Test 1 : a NEW file
        fakeFolder.localModifier ().insert ("A/a0", size);
        QVERIFY (!fakeFolder.syncOnce ()); // timeout!
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ()); // but the upload succeeded
        QVERIFY (!checksumHeader.isEmpty ());
        fakeFolder.remoteModifier ().find ("A/a0").checksums = checksumHeader; // The test system don't do that automatically
        // Should be resolved properly
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (nGET, 0);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Test 2 : Modify the file further
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (!fakeFolder.syncOnce ()); // timeout!
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ()); // but the upload succeeded
        fakeFolder.remoteModifier ().find ("A/a0").checksums = checksumHeader;
        // modify again, should not cause conflict
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (!fakeFolder.syncOnce ()); // now it's trying to upload the modified file
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        fakeFolder.remoteModifier ().find ("A/a0").checksums = checksumHeader;
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (nGET, 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPercentEncoding () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int size = 5 * 1000 * 1000;
        setChunkSize (fakeFolder.syncEngine (), 1 * 1000 * 1000);

        fakeFolder.localModifier ().insert ("A/file % \u20ac", size);
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Only the second upload contains an "If" header
        fakeFolder.localModifier ().appendByte ("A/file % \u20ac");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }

    // Test uploading large files (2.5GiB)
    private on_ void testVeryBigFiles () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"} } } });
        const int64 size = 2.5 * 1024 * 1024 * 1024; // 2.5 GiB

        // Partial upload of big files
        partialUpload (fakeFolder, "A/a0", size);
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        var chunkingId = fakeFolder.uploadState ().children.first ().name;

        // Now resume
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size);

        // The same chunk identifier was re-used
        QCOMPARE (fakeFolder.uploadState ().children.count (), 1);
        QCOMPARE (fakeFolder.uploadState ().children.first ().name, chunkingId);

        // Upload another file again, this time without interruption
        fakeFolder.localModifier ().appendByte ("A/a0");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a0").size, size + 1);
    }

}

QTEST_GUILESS_MAIN (TestChunkingNG)
#include "testchunkingng.moc"
