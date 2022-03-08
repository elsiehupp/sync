/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

class TestAsyncOp : GLib.Object {

    // This test is made of several testcases.
    // the testCases maps a filename to a couple of callback.
    // When a file is uploaded, the fake server will always return the 202 code, and will set
    // the `perform` functor to what needs to be done to complete the transaction.
    // The testcase consist of the `pollRequest` which will be called when the sync engine
    // calls the poll url.
    class TestCase {
        delegate Soup.Reply PollRequest_t (TestCase case, Soup.Request request);
        PollRequest_t pollRequest;
        std.function<FileInfo> perform = null;
    }


    /***********************************************************
    ***********************************************************/
    private void asyncUploadOperations () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().setCapabilities ({ { "dav", new QVariantMap ( { "chunking", "1.0" } ) } });
        // Reduce max chunk size a bit so we get more chunks
        SyncOptions options;
        options.maxChunkSize = 20 * 1000;
        fake_folder.sync_engine ().setSyncOptions (options);
        int nGET = 0;

        GLib.HashMap<string, TestCase> testCases;

        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) . Soup.Reply * {
            var path = request.url ().path ();

            if (operation == Soup.GetOperation && path.startsWith ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                return testCase.pollRequest (&testCase, request);
            }

            if (operation == Soup.PutOperation && !path.contains ("/uploads/")) {
                // Not chunking
                var file = get_file_path_from_url (request.url ());
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                //  Q_ASSERT (!testCase.perform);
                var put_payload = outgoing_data.readAll ();
                testCase.perform = [put_payload, request, fake_folder] {
                    return FakePutReply.perform (fake_folder.remote_modifier (), request, put_payload);
                }
                return new FakeAsyncReply ("/async-poll/" + file.toUtf8 (), operation, request, fake_folder.sync_engine ());
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                string file = get_file_path_from_url (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                //  Q_ASSERT (!testCase.perform);
                testCase.perform = [request, fake_folder] {
                    return FakeChunkMoveReply.perform (fake_folder.upload_state (), fake_folder.remote_modifier (), request);
                }
                return new FakeAsyncReply ("/async-poll/" + file.toUtf8 (), operation, request, fake_folder.sync_engine ());
            } else if (operation == Soup.GetOperation) {
                nGET++;
            }
            return null;
        });

        // Callback to be used to on_signal_finalize the transaction and return the on_signal_success
        var successCallback = [] (TestCase tc, Soup.Request request) {
            tc.pollRequest = [] (TestCase *, Soup.Request &) . Soup.Reply * { std.on_signal_abort (); }; // shall no longer be called
            FileInfo info = tc.perform ();
            GLib.ByteArray body = R" ({ "status":"on_signal_finished", "ETag":"\")" + info.etag + R" (\"", "file_identifier":")" + info.file_identifier + "\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // Callback that never finishes
        var waitForeverCallback = [] (TestCase *, Soup.Request request) {
            GLib.ByteArray body = "{\"status\":\"started\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // Callback that simulate an error.
        var errorCallback = [] (TestCase tc, Soup.Request request) {
            tc.pollRequest = [] (TestCase *, Soup.Request &) . Soup.Reply * { std.on_signal_abort (); }; // shall no longer be called;
            GLib.ByteArray body = "{\"status\":\"error\",\"errorCode\":500,\"errorMessage\":\"TestingErrors\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // This lambda takes another functor as a parameter, and returns a callback that will
        // tell the client needs to poll again, and further call to the poll url will call the
        // given callback
        var waitAndChain = [] (TestCase.PollRequest_t chain) {
            return [chain] (TestCase tc, Soup.Request request) {
                tc.pollRequest = chain;
                GLib.ByteArray body = "{\"status\":\"started\"}\n";
                return new FakePayloadReply (Soup.GetOperation, request, body, null);
            }
        }

        // Create a testcase by creating a file of a given size locally and assigning it a callback
        var insertFile = [&] (string file, int64 size, TestCase.PollRequest_t cb) {
            fake_folder.local_modifier ().insert (file, size);
            testCases[file] = { std.move (cb));
        }
        fake_folder.local_modifier ().mkdir ("on_signal_success");
        insertFile ("on_signal_success/chunked_success", options.maxChunkSize * 3, successCallback);
        insertFile ("on_signal_success/single_success", 300, successCallback);
        insertFile ("on_signal_success/chunked_patience", options.maxChunkSize * 3,
            waitAndChain (waitAndChain (successCallback)));
        insertFile ("on_signal_success/single_patience", 300,
            waitAndChain (waitAndChain (successCallback)));
        fake_folder.local_modifier ().mkdir ("err");
        insertFile ("err/chunked_error", options.maxChunkSize * 3, errorCallback);
        insertFile ("err/single_error", 300, errorCallback);
        insertFile ("err/chunked_error2", options.maxChunkSize * 3, waitAndChain (errorCallback));
        insertFile ("err/single_error2", 300, waitAndChain (errorCallback));

        // First sync should finish by itself.
        // All the things in "on_signal_success/" should be transfered, the things in "err/" not
        //  QVERIFY (!fake_folder.sync_once ());
        //  QCOMPARE (nGET, 0);
        //  QCOMPARE (*fake_folder.current_local_state ().find ("on_signal_success"),
            *fake_folder.current_remote_state ().find ("on_signal_success"));
        testCases.clear ();
        testCases["err/chunked_error"] = { successCallback };
        testCases["err/chunked_error2"] = { successCallback };
        testCases["err/single_error"] = { successCallback };
        testCases["err/single_error2"] = { successCallback };

        fake_folder.local_modifier ().mkdir ("waiting");
        insertFile ("waiting/small", 300, waitForeverCallback);
        insertFile ("waiting/willNotConflict", 300, waitForeverCallback);
        insertFile ("waiting/big", options.maxChunkSize * 3,
            waitAndChain (waitAndChain ([&] (TestCase tc, Soup.Request request) {
                QTimer.singleShot (0, fake_folder.sync_engine (), &SyncEngine.on_signal_abort);
                return waitAndChain (waitForeverCallback) (tc, request);
            })));

        fake_folder.sync_journal ().wipeErrorBlocklist ();

        // This second sync will redo the files that had errors
        // But the waiting folder will not complete before it is aborted.
        //  QVERIFY (!fake_folder.sync_once ());
        //  QCOMPARE (nGET, 0);
        //  QCOMPARE (*fake_folder.current_local_state ().find ("err"),
            *fake_folder.current_remote_state ().find ("err"));

        testCases["waiting/small"].pollRequest = waitAndChain (waitAndChain (successCallback));
        testCases["waiting/big"].pollRequest = waitAndChain (successCallback);
        testCases["waiting/willNotConflict"].pollRequest =
            [&fake_folder, successCallback] (TestCase tc, Soup.Request request) {
                var remote_modifier = fake_folder.remote_modifier (); // successCallback destroys the capture
                var reply = successCallback (tc, request);
                // This is going to succeed, and after we just change the file.
                // This should not be a conflict, but this should be downloaded in the
                // next sync
                remote_modifier.append_byte ("waiting/willNotConflict");
                return reply;
            }

        int nPUT = 0;
        int nMOVE = 0;
        int nDELETE = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            var path = request.url ().path ();
            if (operation == Soup.GetOperation && path.startsWith ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                //  Q_ASSERT (testCases.contains (file));
                var testCase = testCases[file];
                return testCase.pollRequest (&testCase, request);
            } else if (operation == Soup.PutOperation) {
                nPUT++;
            } else if (operation == Soup.GetOperation) {
                nGET++;
            } else if (operation == Soup.DeleteOperation) {
                nDELETE++;
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                nMOVE++;
            }
            return null;
        });

        // This last sync will do the waiting stuff
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (nGET, 1); // "waiting/willNotConflict"
        //  QCOMPARE (nPUT, 0);
        //  QCOMPARE (nMOVE, 0);
        //  QCOMPARE (nDELETE, 0);
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }

} // class TestAsyncOp
} // namespace Testing
