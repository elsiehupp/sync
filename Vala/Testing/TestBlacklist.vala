/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using namespace Occ;

SyncJournalFileRecord journalRecord (FakeFolder folder, GLib.ByteArray path) {
    SyncJournalFileRecord record;
    folder.syncJournal ().getFileRecord (path, record);
    return record;
}

class TestBlocklist : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testBlocklistBasic_data () {
        QTest.addColumn<bool> ("remote");
        QTest.newRow ("remote") + true;
        QTest.newRow ("local") + false;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testBlocklistBasic () {
        QFETCH (bool, remote);

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var modifier = remote ? fakeFolder.remoteModifier () : fakeFolder.localModifier ();

        int counter = 0;
        const GLib.ByteArray testFileName = QByteArrayLiteral ("A/new");
        GLib.ByteArray reqId;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest req, QIODevice *) . Soup.Reply * {
            if (req.url ().path ().endsWith (testFileName)) {
                reqId = req.rawHeader ("X-Request-ID");
            }
            if (!remote && op == QNetworkAccessManager.PutOperation)
                ++counter;
            if (remote && op == QNetworkAccessManager.GetOperation)
                ++counter;
            return null;
        });

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }

        var initialEtag = journalRecord (fakeFolder, "A").etag;
        QVERIFY (!initialEtag.isEmpty ());

        // The first sync and the download will fail - the item will be blocklisted
        modifier.insert (testFileName);
        fakeFolder.serverErrorPaths ().append (testFileName, 500); // will be blocklisted
        QVERIFY (!fakeFolder.syncOnce ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.NORMAL_ERROR); // initial error visible
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            QVERIFY (entry.isValid ());
            QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            QCOMPARE (entry.retryCount, 1);
            QCOMPARE (counter, 1);
            QVERIFY (entry.ignoreDuration > 0);
            QCOMPARE (entry.requestId, reqId);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // Ignored during the second run - but soft errors are also errors
        QVERIFY (!fakeFolder.syncOnce ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_IGNORE); // no retry happened!

            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            QVERIFY (entry.isValid ());
            QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            QCOMPARE (entry.retryCount, 1);
            QCOMPARE (counter, 1);
            QVERIFY (entry.ignoreDuration > 0);
            QCOMPARE (entry.requestId, reqId);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // Let's expire the blocklist entry to verify it gets retried {
            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fakeFolder.syncJournal ().setErrorBlocklistEntry (entry);
        }
        QVERIFY (!fakeFolder.syncOnce ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR); // blocklisted as it's just a retry
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            QVERIFY (entry.isValid ());
            QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            QCOMPARE (entry.retryCount, 2);
            QCOMPARE (counter, 2);
            QVERIFY (entry.ignoreDuration > 0);
            QCOMPARE (entry.requestId, reqId);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // When the file changes a retry happens immediately
        modifier.appendByte (testFileName);
        QVERIFY (!fakeFolder.syncOnce ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            QVERIFY (entry.isValid ());
            QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            QCOMPARE (entry.retryCount, 3);
            QCOMPARE (counter, 3);
            QVERIFY (entry.ignoreDuration > 0);
            QCOMPARE (entry.requestId, reqId);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // When the error goes away and the item is retried, the sync succeeds
        fakeFolder.serverErrorPaths ().clear (); {
            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fakeFolder.syncJournal ().setErrorBlocklistEntry (entry);
        }
        QVERIFY (fakeFolder.syncOnce ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.SUCCESS);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fakeFolder.syncJournal ().errorBlocklistEntry (testFileName);
            QVERIFY (!entry.isValid ());
            QCOMPARE (counter, 4);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, fakeFolder.currentRemoteState ().find ("A").etag);
        }
        on_signal_cleanup ();

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }
}

QTEST_GUILESS_MAIN (TestBlocklist)
#include "testblocklist.moc"