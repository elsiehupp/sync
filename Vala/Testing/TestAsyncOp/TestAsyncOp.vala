/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using namespace Occ;

class TestAsyncOp : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void asyncUploadOperations () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ { "chunking", "1.0" } } } });
        // Reduce max chunk size a bit so we get more chunks
        SyncOptions options;
        options.maxChunkSize = 20 * 1000;
        fakeFolder.syncEngine ().setSyncOptions (options);
        int nGET = 0;

        // This test is made of several testcases.
        // the testCases maps a filename to a couple of callback.
        // When a file is uploaded, the fake server will always return the 202 code, and will set
        // the `perform` functor to what needs to be done to complete the transaction.
        // The testcase consist of the `pollRequest` which will be called when the sync engine
        // calls the poll url.
        struct TestCase {
            using PollRequest_t = std.function<Soup.Reply * (TestCase *, QNetworkRequest request)>;
            PollRequest_t pollRequest;
            std.function<FileInfo * ()> perform = null;
        };
        GLib.HashMap<string, TestCase> testCases;

        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice outgoingData) . Soup.Reply * {
            var path = request.url ().path ();

            if (op == QNetworkAccessManager.GetOperation && path.startsWith ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                return testCase.pollRequest (&testCase, request);
            }

            if (op == QNetworkAccessManager.PutOperation && !path.contains ("/uploads/")) {
                // Not chunking
                var file = getFilePathFromUrl (request.url ());
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                //  Q_ASSERT (!testCase.perform);
                var putPayload = outgoingData.readAll ();
                testCase.perform = [putPayload, request, fakeFolder] {
                    return FakePutReply.perform (fakeFolder.remoteModifier (), request, putPayload);
                };
                return new FakeAsyncReply ("/async-poll/" + file.toUtf8 (), op, request, fakeFolder.syncEngine ());
            } else if (request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                string file = getFilePathFromUrl (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                //  Q_ASSERT (!testCase.perform);
                testCase.perform = [request, fakeFolder] {
                    return FakeChunkMoveReply.perform (fakeFolder.uploadState (), fakeFolder.remoteModifier (), request);
                };
                return new FakeAsyncReply ("/async-poll/" + file.toUtf8 (), op, request, fakeFolder.syncEngine ());
            } else if (op == QNetworkAccessManager.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Callback to be used to on_finalize the transaction and return the on_success
        var successCallback = [] (TestCase tc, QNetworkRequest request) {
            tc.pollRequest = [] (TestCase *, QNetworkRequest &) . Soup.Reply * { std.on_abort (); }; // shall no longer be called
            FileInfo info = tc.perform ();
            GLib.ByteArray body = R" ({ "status":"on_finished", "ETag":"\")" + info.etag + R" (\"", "fileId":")" + info.fileId + "\"}\n";
            return new FakePayloadReply (QNetworkAccessManager.GetOperation, request, body, null);
        };
        // Callback that never finishes
        var waitForeverCallback = [] (TestCase *, QNetworkRequest request) {
            GLib.ByteArray body = "{\"status\":\"started\"}\n";
            return new FakePayloadReply (QNetworkAccessManager.GetOperation, request, body, null);
        };
        // Callback that simulate an error.
        var errorCallback = [] (TestCase tc, QNetworkRequest request) {
            tc.pollRequest = [] (TestCase *, QNetworkRequest &) . Soup.Reply * { std.on_abort (); }; // shall no longer be called;
            GLib.ByteArray body = "{\"status\":\"error\",\"errorCode\":500,\"errorMessage\":\"TestingErrors\"}\n";
            return new FakePayloadReply (QNetworkAccessManager.GetOperation, request, body, null);
        };
        // This lambda takes another functor as a parameter, and returns a callback that will
        // tell the client needs to poll again, and further call to the poll url will call the
        // given callback
        var waitAndChain = [] (TestCase.PollRequest_t chain) {
            return [chain] (TestCase tc, QNetworkRequest request) {
                tc.pollRequest = chain;
                GLib.ByteArray body = "{\"status\":\"started\"}\n";
                return new FakePayloadReply (QNetworkAccessManager.GetOperation, request, body, null);
            };
        };

        // Create a testcase by creating a file of a given size locally and assigning it a callback
        var insertFile = [&] (string file, int64 size, TestCase.PollRequest_t cb) {
            fakeFolder.localModifier ().insert (file, size);
            testCases[file] = { std.move (cb) };
        };
        fakeFolder.localModifier ().mkdir ("on_success");
        insertFile ("on_success/chunked_success", options.maxChunkSize * 3, successCallback);
        insertFile ("on_success/single_success", 300, successCallback);
        insertFile ("on_success/chunked_patience", options.maxChunkSize * 3,
            waitAndChain (waitAndChain (successCallback)));
        insertFile ("on_success/single_patience", 300,
            waitAndChain (waitAndChain (successCallback)));
        fakeFolder.localModifier ().mkdir ("err");
        insertFile ("err/chunked_error", options.maxChunkSize * 3, errorCallback);
        insertFile ("err/single_error", 300, errorCallback);
        insertFile ("err/chunked_error2", options.maxChunkSize * 3, waitAndChain (errorCallback));
        insertFile ("err/single_error2", 300, waitAndChain (errorCallback));

        // First sync should finish by itself.
        // All the things in "on_success/" should be transfered, the things in "err/" not
        QVERIFY (!fakeFolder.syncOnce ());
        QCOMPARE (nGET, 0);
        QCOMPARE (*fakeFolder.currentLocalState ().find ("on_success"),
            *fakeFolder.currentRemoteState ().find ("on_success"));
        testCases.clear ();
        testCases["err/chunked_error"] = { successCallback };
        testCases["err/chunked_error2"] = { successCallback };
        testCases["err/single_error"] = { successCallback };
        testCases["err/single_error2"] = { successCallback };

        fakeFolder.localModifier ().mkdir ("waiting");
        insertFile ("waiting/small", 300, waitForeverCallback);
        insertFile ("waiting/willNotConflict", 300, waitForeverCallback);
        insertFile ("waiting/big", options.maxChunkSize * 3,
            waitAndChain (waitAndChain ([&] (TestCase tc, QNetworkRequest request) {
                QTimer.singleShot (0, fakeFolder.syncEngine (), &SyncEngine.on_abort);
                return waitAndChain (waitForeverCallback) (tc, request);
            })));

        fakeFolder.syncJournal ().wipeErrorBlocklist ();

        // This second sync will redo the files that had errors
        // But the waiting folder will not complete before it is aborted.
        QVERIFY (!fakeFolder.syncOnce ());
        QCOMPARE (nGET, 0);
        QCOMPARE (*fakeFolder.currentLocalState ().find ("err"),
            *fakeFolder.currentRemoteState ().find ("err"));

        testCases["waiting/small"].pollRequest = waitAndChain (waitAndChain (successCallback));
        testCases["waiting/big"].pollRequest = waitAndChain (successCallback);
        testCases["waiting/willNotConflict"].pollRequest =
            [&fakeFolder, successCallback] (TestCase tc, QNetworkRequest request) {
                var remoteModifier = fakeFolder.remoteModifier (); // successCallback destroys the capture
                var reply = successCallback (tc, request);
                // This is going to succeed, and after we just change the file.
                // This should not be a conflict, but this should be downloaded in the
                // next sync
                remoteModifier.appendByte ("waiting/willNotConflict");
                return reply;
            };

        int nPUT = 0;
        int nMOVE = 0;
        int nDELETE = 0;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice *) . Soup.Reply * {
            var path = request.url ().path ();
            if (op == QNetworkAccessManager.GetOperation && path.startsWith ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                return testCase.pollRequest (&testCase, request);
            } else if (op == QNetworkAccessManager.PutOperation) {
                nPUT++;
            } else if (op == QNetworkAccessManager.GetOperation) {
                nGET++;
            } else if (op == QNetworkAccessManager.DeleteOperation) {
                nDELETE++;
            } else if (request.attribute (QNetworkRequest.CustomVerbAttribute) == "MOVE") {
                nMOVE++;
            }
            return null;
        });

        // This last sync will do the waiting stuff
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (nGET, 1); // "waiting/willNotConflict"
        QCOMPARE (nPUT, 0);
        QCOMPARE (nMOVE, 0);
        QCOMPARE (nDELETE, 0);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }
}

QTEST_GUILESS_MAIN (TestAsyncOp)
#include "testasyncop.moc"
