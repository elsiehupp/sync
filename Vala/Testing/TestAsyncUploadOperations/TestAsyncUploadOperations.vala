namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestAsyncOp

This test is made of several test case. The test case maps a
filename to a couple of callbacks. When a file is uploaded,
the fake server will always return the 202 code, and will set
the `perform` functor to what needs to be done to complete
the transaction. The test case consists of the `poll_request`
which will be called when the sync engine calls the poll url.

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class AbstractTestAsyncOp : GLib.Object {

    FakeFolder fake_folder;
    TestCase.PollRequestDelegate

    public delegate GLib.InputStream PollRequestDelegate (TestCase test_case, Soup.Request request);
    public PollRequestDelegate poll_request;
    public delegate void ToPerform (FileInfo file_info);
    ToPerform perform;


    /***********************************************************
    ***********************************************************/
    protected AbstractTestAsyncOp () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ( { "chunking", "1.0" } ) } });
        // Reduce max chunk size a bit so we get more chunks
        SyncOptions options;
        options.max_chunk_size = 20 * 1000;
        fake_folder.sync_engine.set_sync_options (options);
        int n_get = 0;

        GLib.HashTable<string, TestCase> test_cases;

        fake_folder.set_server_override (this.override_delegate_async_upload_operations1);

        fake_folder.local_modifier.mkdir ("success");
        insert_file ("success/chunked_success", options.max_chunk_size * 3, success_callback);
        insert_file ("success/single_success", 300, success_callback);
        insert_file ("success/chunked_patience", options.max_chunk_size * 3,
            wait_and_chain (wait_and_chain (success_callback)));
        insert_file ("success/single_patience", 300,
            wait_and_chain (wait_and_chain (success_callback)));
        fake_folder.local_modifier.mkdir ("err");
        insert_file ("err/chunked_error", options.max_chunk_size * 3, error_callback);
        insert_file ("err/single_error", 300, error_callback);
        insert_file ("err/chunked_error2", options.max_chunk_size * 3, wait_and_chain (error_callback));
        insert_file ("err/single_error2", 300, wait_and_chain (error_callback));

        // First sync should finish by itself.
        // All the things in "success/" should be transfered, the things in "err/" not
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (n_get == 0);
        GLib.assert_true (fake_folder.current_local_state ().find ("success") ==
            fake_folder.current_remote_state ().find ("success"));
        test_cases.clear ();
        test_cases["err/chunked_error"] = new TestCase (success_callback);
        test_cases["err/chunked_error2"] = new TestCase (success_callback);
        test_cases["err/single_error"] = new TestCase (success_callback);
        test_cases["err/single_error2"] = new TestCase (success_callback);

        fake_folder.local_modifier.mkdir ("waiting");
        insert_file ("waiting/small", 300, wait_forever_callback);
        insert_file ("waiting/willNotConflict", 300, wait_forever_callback);
        insert_file (
            "waiting/big",
            options.max_chunk_size * 3,
            wait_and_chain (
                wait_and_chain (
                    TestAsyncOp.big_wait_delegate
                )
            )
        );

        fake_folder.sync_journal ().wipe_error_blocklist ();

        // This second sync will redo the files that had errors
        // But the waiting folder will not complete before it is aborted.
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (n_get == 0);
        GLib.assert_true (fake_folder.current_local_state ().find ("err") ==
            fake_folder.current_remote_state ().find ("err"));

        test_cases["waiting/small"].poll_request = wait_and_chain (wait_and_chain (success_callback));
        test_cases["waiting/big"].poll_request = wait_and_chain (success_callback);
        test_cases["waiting/willNotConflict"].poll_request =
            TestAsyncOp.will_not_conflict_delegate;

        int number_of_put = 0;
        int number_of_move = 0;
        int number_of_delete = 0;
        fake_folder.set_server_override (this.override_delegate_async_upload_operations2);

        // This last sync will do the waiting stuff
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == 1); // "waiting/willNotConflict"
        GLib.assert_true (number_of_put == 0);
        GLib.assert_true (number_of_move == 0);
        GLib.assert_true (number_of_delete == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private FakePayloadReply big_wait_delegate (TestCase test_case, Soup.Request request) {
        GLib.Timeout.single_shot (0, fake_folder.sync_engine, &SyncEngine.on_signal_abort);
        return wait_and_chain (wait_forever_callback) (test_case, request);
    }


    /***********************************************************
    Needs passthrough of [fake_folder, success_callback]
    ***********************************************************/
    private FakePayloadReply will_not_conflict_delegate (TestCase test_case, Soup.Request request) {
        var remote_modifier = fake_folder.remote_modifier (); // success_callback destroys the capture
        var reply = success_callback (test_case, request);
        // This is going to succeed, and after we just change the file.
        // This should not be a conflict, but this should be downloaded in the
        // next sync
        remote_modifier.append_byte ("waiting/willNotConflict");
        return reply;
    }


    /***********************************************************
    Callback to be used to finalize the transaction and return
    the success
    ***********************************************************/
    private FakePayloadReply success_callback (TestCase test_case, Soup.Request request) {
        test_case.poll_request = FakePayloadReply.poll_request_delegate;
        FileInfo info = test_case.perform ();
        string body = " ({ \"status\":\"finished\", \"ETag\":\"\")" + info.etag + " (\"\", \"file_identifier\":\")" + info.file_identifier + "\"}\n";
        return new FakePayloadReply (Soup.GetOperation, request, body, null);
    }


    /***********************************************************
    Shall no longer be called
    ***********************************************************/
    private void poll_request_delegate (TestCase test_case, Soup.Request request) {
        std.abort ();
    }


    /***********************************************************
    Callback that never finishes
    ***********************************************************/
    private FakePayloadReply wait_forever_callback (TestCase test_case, Soup.Request request) {
        string body = "{\"status\":\"started\"}\n";
        return new FakePayloadReply (Soup.GetOperation, request, body, null);
    }


    /***********************************************************
    Callback that simulate an error.
    ***********************************************************/
    private FakePayloadReply error_callback (TestCase test_case, Soup.Request request) {
        test_case.poll_request = FakePayloadReply.error_callback_poll_request_delegate;
        string body = "{\"status\":\"error\",\"errorCode\":500,\"error_message\":\"TestingErrors\"}\n";
        return new FakePayloadReply (Soup.GetOperation, request, body, null);
    }


    /***********************************************************
    Shall no longer be called
    ***********************************************************/
    private FakePayloadReply error_callback_poll_request_delegate (TestCase test_case, Soup.Request request) {
        std.abort ();
    }


    /***********************************************************
    This function takes another function as a parameter, and
    returns a callback that will tell the client needs to poll
    again, and further call to the poll url will call the given
    callback.
    ***********************************************************/
    private FakePayloadReply wait_and_chain (TestCase.PollRequestDelegate chain) {
        return TestAsyncOp.wait_and_chain_delegate;
    }


    /***********************************************************
    Needs passthrough of [chain]
    ***********************************************************/
    private FakePayloadReply wait_and_chain_delegate (TestCase test_case, Soup.Request request) {
        test_case.poll_request = chain;
        string body = "{\"status\":\"started\"}\n";
        return new FakePayloadReply (Soup.GetOperation, request, body, null);
    }


    /***********************************************************
    Create a test case by creating a file of a given size
    locally and assigning it a callback
    ***********************************************************/
    private void insert_file (string file, int64 size, TestCase.PollRequestDelegate cb) {
        fake_folder.local_modifier.insert (file, size);
        test_cases[file] = () => { std.move (cb); };
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream override_delegate_async_upload_operations1 (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) {
        var path = request.url.path;

        if (operation == Soup.GetOperation && path.has_prefix ("/async-poll/")) {
            var file = path.mid ("/async-poll/".size () - 1);
            GLib.assert_true (test_cases.contains (file));
            var test_case = test_cases[file];
            return test_case.poll_request (&test_case, request);
        }

        if (operation == Soup.PutOperation && !path.contains ("/uploads/")) {
            // Not chunking
            var file = get_file_path_from_url (request.url);
            GLib.assert_true (test_cases.contains (file));
            var test_case = test_cases[file];
            GLib.assert_true (!test_case.perform);
            var put_payload = outgoing_data.read_all ();
            test_case.perform = (put_payload, request, fake_folder) => {
                return FakePutReply.perform (fake_folder.remote_modifier (), request, put_payload);
            };
            return new FakeAsyncReply ("/async-poll/" + file, operation, request, fake_folder.sync_engine);
        } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
            string file = get_file_path_from_url (GLib.Uri.from_encoded (request.raw_header ("Destination")));
            GLib.assert_true (test_cases.contains (file));
            var test_case = test_cases[file];
            GLib.assert_true (!test_case.perform);
            test_case.perform = (request, fake_folder) => {
                return FakeChunkMoveReply.perform (fake_folder.upload_state (), fake_folder.remote_modifier (), request);
            };
            return new FakeAsyncReply ("/async-poll/" + file, operation, request, fake_folder.sync_engine);
        } else if (operation == Soup.GetOperation) {
            n_get++;
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream override_delegate_async_upload_operations2 (Soup.Operation operation, Soup.Request request, QIODevice device) {
        var path = request.url.path;
        if (operation == Soup.GetOperation && path.has_prefix ("/async-poll/")) {
            var file = path.mid ("/async-poll/".size () - 1);
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
    }

} // class TestAsyncOp

} // namespace Testing
} // namespace Occ
