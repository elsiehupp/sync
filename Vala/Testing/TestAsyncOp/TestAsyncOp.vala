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
    // the test_cases maps a filename to a couple of callback.
    // When a file is uploaded, the fake server will always return the 202 code, and will set
    // the `perform` functor to what needs to be done to complete the transaction.
    // The testcase consist of the `poll_request` which will be called when the sync engine
    // calls the poll url.
    class TestCase {
        delegate Soup.Reply PollRequest_t (TestCase case, Soup.Request request);
        PollRequest_t poll_request;
        std.function<FileInfo> perform = null;
    }


    /***********************************************************
    ***********************************************************/
    private void async_upload_operations () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "dav", new QVariantMap ( { "chunking", "1.0" } ) } });
        // Reduce max chunk size a bit so we get more chunks
        SyncOptions options;
        options.max_chunk_size = 20 * 1000;
        fake_folder.sync_engine ().set_sync_options (options);
        int n_get = 0;

        GLib.HashMap<string, TestCase> test_cases;

        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) . Soup.Reply * {
            var path = request.url ().path ();

            if (operation == Soup.GetOperation && path.starts_with ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                GLib.assert_true (test_cases.contains (file));
                var test_case = test_cases[file];
                return test_case.poll_request (&test_case, request);
            }

            if (operation == Soup.PutOperation && !path.contains ("/uploads/")) {
                // Not chunking
                var file = get_file_path_from_url (request.url ());
                GLib.assert_true (test_cases.contains (file));
                var test_case = test_cases[file];
                GLib.assert_true (!test_case.perform);
                var put_payload = outgoing_data.read_all ();
                test_case.perform = [put_payload, request, fake_folder] {
                    return FakePutReply.perform (fake_folder.remote_modifier (), request, put_payload);
                }
                return new FakeAsyncReply ("/async-poll/" + file, operation, request, fake_folder.sync_engine ());
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                string file = get_file_path_from_url (GLib.Uri.from_encoded (request.raw_header ("Destination")));
                GLib.assert_true (test_cases.contains (file));
                var test_case = test_cases[file];
                GLib.assert_true (!test_case.perform);
                test_case.perform = [request, fake_folder] {
                    return FakeChunkMoveReply.perform (fake_folder.upload_state (), fake_folder.remote_modifier (), request);
                }
                return new FakeAsyncReply ("/async-poll/" + file, operation, request, fake_folder.sync_engine ());
            } else if (operation == Soup.GetOperation) {
                n_get++;
            }
            return null;
        });

        // Callback to be used to on_signal_finalize the transaction and return the on_signal_success
        var success_callback = [] (TestCase tc, Soup.Request request) {
            tc.poll_request = [] (TestCase *, Soup.Request &) . Soup.Reply * { std.on_signal_abort (); }; // shall no longer be called
            FileInfo info = tc.perform ();
            GLib.ByteArray body = R" ({ "status":"on_signal_finished", "ETag":"\")" + info.etag + R" (\"", "file_identifier":")" + info.file_identifier + "\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // Callback that never finishes
        var wait_forever_callback = [] (TestCase *, Soup.Request request) {
            GLib.ByteArray body = "{\"status\":\"started\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // Callback that simulate an error.
        var error_callback = [] (TestCase tc, Soup.Request request) {
            tc.poll_request = [] (TestCase *, Soup.Request &) . Soup.Reply * { std.on_signal_abort (); }; // shall no longer be called;
            GLib.ByteArray body = "{\"status\":\"error\",\"errorCode\":500,\"errorMessage\":\"TestingErrors\"}\n";
            return new FakePayloadReply (Soup.GetOperation, request, body, null);
        }
        // This lambda takes another functor as a parameter, and returns a callback that will
        // tell the client needs to poll again, and further call to the poll url will call the
        // given callback
        var wait_and_chain = [] (TestCase.PollRequest_t chain) {
            return [chain] (TestCase tc, Soup.Request request) {
                tc.poll_request = chain;
                GLib.ByteArray body = "{\"status\":\"started\"}\n";
                return new FakePayloadReply (Soup.GetOperation, request, body, null);
            }
        }

        // Create a testcase by creating a file of a given size locally and assigning it a callback
        var insert_file = [&] (string file, int64 size, TestCase.PollRequest_t cb) {
            fake_folder.local_modifier ().insert (file, size);
            test_cases[file] = { std.move (cb));
        }
        fake_folder.local_modifier ().mkdir ("on_signal_success");
        insert_file ("on_signal_success/chunked_success", options.max_chunk_size * 3, success_callback);
        insert_file ("on_signal_success/single_success", 300, success_callback);
        insert_file ("on_signal_success/chunked_patience", options.max_chunk_size * 3,
            wait_and_chain (wait_and_chain (success_callback)));
        insert_file ("on_signal_success/single_patience", 300,
            wait_and_chain (wait_and_chain (success_callback)));
        fake_folder.local_modifier ().mkdir ("err");
        insert_file ("err/chunked_error", options.max_chunk_size * 3, error_callback);
        insert_file ("err/single_error", 300, error_callback);
        insert_file ("err/chunked_error2", options.max_chunk_size * 3, wait_and_chain (error_callback));
        insert_file ("err/single_error2", 300, wait_and_chain (error_callback));

        // First sync should finish by itself.
        // All the things in "on_signal_success/" should be transfered, the things in "err/" not
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (n_get, 0);
        GLib.assert_cmp (*fake_folder.current_local_state ().find ("on_signal_success"),
            *fake_folder.current_remote_state ().find ("on_signal_success"));
        test_cases.clear ();
        test_cases["err/chunked_error"] = { success_callback };
        test_cases["err/chunked_error2"] = { success_callback };
        test_cases["err/single_error"] = { success_callback };
        test_cases["err/single_error2"] = { success_callback };

        fake_folder.local_modifier ().mkdir ("waiting");
        insert_file ("waiting/small", 300, wait_forever_callback);
        insert_file ("waiting/willNotConflict", 300, wait_forever_callback);
        insert_file ("waiting/big", options.max_chunk_size * 3,
            wait_and_chain (wait_and_chain ([&] (TestCase tc, Soup.Request request) {
                QTimer.single_shot (0, fake_folder.sync_engine (), &SyncEngine.on_signal_abort);
                return wait_and_chain (wait_forever_callback) (tc, request);
            })));

        fake_folder.sync_journal ().wipe_error_blocklist ();

        // This second sync will redo the files that had errors
        // But the waiting folder will not complete before it is aborted.
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (n_get, 0);
        GLib.assert_cmp (*fake_folder.current_local_state ().find ("err"),
            *fake_folder.current_remote_state ().find ("err"));

        test_cases["waiting/small"].poll_request = wait_and_chain (wait_and_chain (success_callback));
        test_cases["waiting/big"].poll_request = wait_and_chain (success_callback);
        test_cases["waiting/willNotConflict"].poll_request =
            [&fake_folder, success_callback] (TestCase tc, Soup.Request request) {
                var remote_modifier = fake_folder.remote_modifier (); // success_callback destroys the capture
                var reply = success_callback (tc, request);
                // This is going to succeed, and after we just change the file.
                // This should not be a conflict, but this should be downloaded in the
                // next sync
                remote_modifier.append_byte ("waiting/willNotConflict");
                return reply;
            }

        int number_of_put = 0;
        int number_of_move = 0;
        int number_of_delete = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            var path = request.url ().path ();
            if (operation == Soup.GetOperation && path.starts_with ("/async-poll/")) {
                var file = path.mid (sizeof ("/async-poll/") - 1);
                GLib.assert_true (test_cases.contains (file));
                var test_case = test_cases[file];
                return test_case.poll_request (&test_case, request);
            } else if (operation == Soup.PutOperation) {
                number_of_put++;
            } else if (operation == Soup.GetOperation) {
                n_get++;
            } else if (operation == Soup.DeleteOperation) {
                number_of_delete++;
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                number_of_move++;
            }
            return null;
        });

        // This last sync will do the waiting stuff
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (n_get, 1); // "waiting/willNotConflict"
        GLib.assert_cmp (number_of_put, 0);
        GLib.assert_cmp (number_of_move, 0);
        GLib.assert_cmp (number_of_delete, 0);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }

} // class TestAsyncOp
} // namespace Testing
