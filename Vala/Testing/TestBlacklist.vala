/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

SyncJournalFileRecord journalRecord (FakeFolder folder, GLib.ByteArray path) {
    SyncJournalFileRecord record;
    folder.sync_journal ().getFileRecord (path, record);
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

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var modifier = remote ? fakeFolder.remote_modifier () : fakeFolder.local_modifier ();

        int counter = 0;
        const GLib.ByteArray testFileName = QByteArrayLiteral ("A/new");
        GLib.ByteArray reqId;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request req, QIODevice *) . Soup.Reply * {
            if (req.url ().path ().endsWith (testFileName)) {
                reqId = req.rawHeader ("X-Request-ID");
            }
            if (!remote && operation == QNetworkAccessManager.PutOperation)
                ++counter;
            if (remote && operation == QNetworkAccessManager.GetOperation)
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
        fakeFolder.server_error_paths ().append (testFileName, 500); // will be blocklisted
        QVERIFY (!fakeFolder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.NORMAL_ERROR); // initial error visible
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
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
        QVERIFY (!fakeFolder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_IGNORE); // no retry happened!

            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
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
            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fakeFolder.sync_journal ().setErrorBlocklistEntry (entry);
        }
        QVERIFY (!fakeFolder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR); // blocklisted as it's just a retry
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
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
        modifier.append_byte (testFileName);
        QVERIFY (!fakeFolder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
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
        fakeFolder.server_error_paths ().clear (); {
            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fakeFolder.sync_journal ().setErrorBlocklistEntry (entry);
        }
        QVERIFY (fakeFolder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            QVERIFY (it);
            QCOMPARE (it.status, SyncFileItem.Status.SUCCESS);
            QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fakeFolder.sync_journal ().errorBlocklistEntry (testFileName);
            QVERIFY (!entry.isValid ());
            QCOMPARE (counter, 4);

            if (remote)
                QCOMPARE (journalRecord (fakeFolder, "A").etag, fakeFolder.current_remote_state ().find ("A").etag);
        }
        on_signal_cleanup ();

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }
}

QTEST_GUILESS_MAIN (TestBlocklist)
#include "testblocklist.moc"
