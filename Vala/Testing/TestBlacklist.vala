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
    private void on_test_blocklist_basic_data () {
        QTest.addColumn<bool> ("remote");
        QTest.newRow ("remote") + true;
        QTest.newRow ("local") + false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_blocklist_basic () {
        //  QFETCH (bool, remote);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy completeSpy = new ItemCompletedSpy (fake_folder);

        var modifier = remote ? fake_folder.remote_modifier () : fake_folder.local_modifier ();

        int counter = 0;
        const GLib.ByteArray testFileName = "A/new";
        GLib.ByteArray reqId;
        fake_folder.set_server_override ((Soup.Operation operation, Soup.Request request, QIODevice device) => { // Soup.Reply
            if (request.url ().path ().endsWith (testFileName)) {
                reqId = request.rawHeader ("X-Request-ID");
            }
            if (!remote && operation == Soup.PutOperation) {
                ++counter;
            }
            if (remote && operation == Soup.GetOperation) {
                ++counter;
            }
            return;
        });

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }

        var initialEtag = journalRecord (fake_folder, "A").etag;
        //  QVERIFY (!initialEtag.isEmpty ());

        // The first sync and the download will fail - the item will be blocklisted
        modifier.insert (testFileName);
        fake_folder.server_error_paths ().append (testFileName, 500); // will be blocklisted
        //  QVERIFY (!fake_folder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            //  QVERIFY (it);
            //  QCOMPARE (it.status, SyncFileItem.Status.NORMAL_ERROR); // initial error visible
            //  QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            //  QVERIFY (entry.isValid ());
            //  QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            //  QCOMPARE (entry.retryCount, 1);
            //  QCOMPARE (counter, 1);
            //  QVERIFY (entry.ignoreDuration > 0);
            //  QCOMPARE (entry.requestId, reqId);

            if (remote)
                //  QCOMPARE (journalRecord (fake_folder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // Ignored during the second run - but soft errors are also errors
        //  QVERIFY (!fake_folder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            //  QVERIFY (it);
            //  QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            //  QCOMPARE (it.instruction, CSYNC_INSTRUCTION_IGNORE); // no retry happened!

            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            //  QVERIFY (entry.isValid ());
            //  QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            //  QCOMPARE (entry.retryCount, 1);
            //  QCOMPARE (counter, 1);
            //  QVERIFY (entry.ignoreDuration > 0);
            //  QCOMPARE (entry.requestId, reqId);

            if (remote)
                //  QCOMPARE (journalRecord (fake_folder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // Let's expire the blocklist entry to verify it gets retried {
            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fake_folder.sync_journal ().setErrorBlocklistEntry (entry);
        }
        //  QVERIFY (!fake_folder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            //  QVERIFY (it);
            //  QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR); // blocklisted as it's just a retry
            //  QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            //  QVERIFY (entry.isValid ());
            //  QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            //  QCOMPARE (entry.retryCount, 2);
            //  QCOMPARE (counter, 2);
            //  QVERIFY (entry.ignoreDuration > 0);
            //  QCOMPARE (entry.requestId, reqId);

            if (remote)
                //  QCOMPARE (journalRecord (fake_folder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // When the file changes a retry happens immediately
        modifier.append_byte (testFileName);
        //  QVERIFY (!fake_folder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            //  QVERIFY (it);
            //  QCOMPARE (it.status, SyncFileItem.Status.BLOCKLISTED_ERROR);
            //  QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW); // retry!

            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            //  QVERIFY (entry.isValid ());
            //  QCOMPARE (entry.errorCategory, SyncJournalErrorBlocklistRecord.Normal);
            //  QCOMPARE (entry.retryCount, 3);
            //  QCOMPARE (counter, 3);
            //  QVERIFY (entry.ignoreDuration > 0);
            //  QCOMPARE (entry.requestId, reqId);

            if (remote)
                //  QCOMPARE (journalRecord (fake_folder, "A").etag, initialEtag);
        }
        on_signal_cleanup ();

        // When the error goes away and the item is retried, the sync succeeds
        fake_folder.server_error_paths ().clear (); {
            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            entry.ignoreDuration = 1;
            entry.lastTryTime -= 1;
            fake_folder.sync_journal ().setErrorBlocklistEntry (entry);
        }
        //  QVERIFY (fake_folder.sync_once ()); {
            var it = completeSpy.findItem (testFileName);
            //  QVERIFY (it);
            //  QCOMPARE (it.status, SyncFileItem.Status.SUCCESS);
            //  QCOMPARE (it.instruction, CSYNC_INSTRUCTION_NEW);

            var entry = fake_folder.sync_journal ().errorBlocklistEntry (testFileName);
            //  QVERIFY (!entry.isValid ());
            //  QCOMPARE (counter, 4);

            if (remote)
                //  QCOMPARE (journalRecord (fake_folder, "A").etag, fake_folder.current_remote_state ().find ("A").etag);
        }
        on_signal_cleanup ();

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }
}

QTEST_GUILESS_MAIN (TestBlocklist)
#include "testblocklist.moc"
