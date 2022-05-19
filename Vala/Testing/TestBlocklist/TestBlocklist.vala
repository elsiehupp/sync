/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestBlocklist : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestBlocklistBasicData () {
        GLib.Test.add_column<bool> ("remote");
        GLib.Test.new_row ("remote") + true;
        GLib.Test.new_row ("local") + false;
    }


    /***********************************************************
    ***********************************************************/
    private TestBlocklist () {
        GLib.FETCH (bool, remote);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var modifier = remote ? fake_folder.remote_modifier () : fake_folder.local_modifier;

        int counter = 0;
        string test_filename = "A/new";
        string request_identifier;
        fake_folder.set_server_override (this.override_delegate);

        var initial_etag = journal_record (fake_folder, "A").etag;
        GLib.assert_true (!initial_etag == "");

        // The first sync and the download will fail - the item will be blocklisted
        modifier.insert (test_filename);
        fake_folder.server_error_paths ().append (test_filename, 500); // will be blocklisted
        GLib.assert_true (!fake_folder.sync_once ()); {
            var it = complete_spy.find_item (test_filename);
            GLib.assert_true (it);
            GLib.assert_true (it.status == LibSync.SyncFileItem.Status.NORMAL_ERROR); // initial error visible
            GLib.assert_true (it.instruction == CSync.SyncInstructions.NEW);

            var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
            GLib.assert_true (entry.is_valid);
            GLib.assert_true (entry.error_category == SyncJournalErrorBlocklistRecord.Normal);
            GLib.assert_true (entry.retry_count == 1);
            GLib.assert_true (counter == 1);
            GLib.assert_true (entry.ignore_duration > 0);
            GLib.assert_true (entry.request_identifier == request_identifier);

            if (remote) {
                GLib.assert_true (journal_record (fake_folder, "A").etag == initial_etag);
            }
        }
        clean_up_complete_spy ();

        // Ignored during the second run - but soft errors are also errors
        GLib.assert_true (!fake_folder.sync_once ()); {
            var it = complete_spy.find_item (test_filename);
            GLib.assert_true (it);
            GLib.assert_true (it.status == LibSync.SyncFileItem.Status.BLOCKLISTED_ERROR);
            GLib.assert_true (it.instruction == CSync.SyncInstructions.IGNORE); // no retry happened!

            var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
            GLib.assert_true (entry.is_valid);
            GLib.assert_true (entry.error_category == SyncJournalErrorBlocklistRecord.Normal);
            GLib.assert_true (entry.retry_count == 1);
            GLib.assert_true (counter == 1);
            GLib.assert_true (entry.ignore_duration > 0);
            GLib.assert_true (entry.request_identifier == request_identifier);

            if (remote)
                GLib.assert_true (journal_record (fake_folder, "A").etag == initial_etag);
        }
        clean_up_complete_spy ();

        // Let's expire the blocklist entry to verify it gets retried {
        var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
        entry.ignore_duration = 1;
        entry.last_try_time -= 1;
        fake_folder.sync_journal ().set_error_blocklist_entry (entry);

        GLib.assert_true (!fake_folder.sync_once ());
        var it = complete_spy.find_item (test_filename);
        GLib.assert_true (it);
        GLib.assert_true (it.status == LibSync.SyncFileItem.Status.BLOCKLISTED_ERROR); // blocklisted as it's just a retry
        GLib.assert_true (it.instruction == CSync.SyncInstructions.NEW); // retry!

        entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
        GLib.assert_true (entry.is_valid);
        GLib.assert_true (entry.error_category == SyncJournalErrorBlocklistRecord.Normal);
        GLib.assert_true (entry.retry_count == 2);
        GLib.assert_true (counter == 2);
        GLib.assert_true (entry.ignore_duration > 0);
        GLib.assert_true (entry.request_identifier == request_identifier);

        if (remote) {
            GLib.assert_true (journal_record (fake_folder, "A").etag == initial_etag);
        }
        clean_up_complete_spy ();

        // When the file changes a retry happens immediately
        modifier.append_byte (test_filename);
        GLib.assert_true (!fake_folder.sync_once ()); {
            var it = complete_spy.find_item (test_filename);
            GLib.assert_true (it);
            GLib.assert_true (it.status == LibSync.SyncFileItem.Status.BLOCKLISTED_ERROR);
            GLib.assert_true (it.instruction == CSync.SyncInstructions.NEW); // retry!

            var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
            GLib.assert_true (entry.is_valid);
            GLib.assert_true (entry.error_category == SyncJournalErrorBlocklistRecord.Normal);
            GLib.assert_true (entry.retry_count == 3);
            GLib.assert_true (counter == 3);
            GLib.assert_true (entry.ignore_duration > 0);
            GLib.assert_true (entry.request_identifier == request_identifier);

            if (remote)
                GLib.assert_true (journal_record (fake_folder, "A").etag == initial_etag);
        }
        clean_up_complete_spy ();

        // When the error goes away and the item is retried, the sync succeeds
        fake_folder.server_error_paths () = ""; {
            var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
            entry.ignore_duration = 1;
            entry.last_try_time -= 1;
            fake_folder.sync_journal ().set_error_blocklist_entry (entry);
        }
        GLib.assert_true (fake_folder.sync_once ()); {
            var it = complete_spy.find_item (test_filename);
            GLib.assert_true (it);
            GLib.assert_true (it.status == LibSync.SyncFileItem.Status.SUCCESS);
            GLib.assert_true (it.instruction == CSync.SyncInstructions.NEW);

            var entry = fake_folder.sync_journal ().error_blocklist_entry (test_filename);
            GLib.assert_true (!entry.is_valid);
            GLib.assert_true (counter == 4);

            if (remote) {
                GLib.assert_true (journal_record (fake_folder, "A").etag == fake_folder.current_remote_state ().find ("A").etag);
            }
        }
        clean_up_complete_spy ();

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private void clean_up_complete_spy (ItemCompletedSpy complete_spy) {
        complete_spy = "";
    }


    private GLib.InputStream override_delegate (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (request.url.path.has_suffix (test_filename)) {
            request_identifier = request.raw_header ("X-Request-ID");
        }
        if (!remote && operation == Soup.PutOperation) {
            ++counter;
        }
        if (remote && operation == Soup.GetOperation) {
            ++counter;
        }
        return;
    }


    Common.SyncJournalFileRecord journal_record (FakeFolder folder, string path) {
        Common.SyncJournalFileRecord record;
        folder.sync_journal ().get_file_record (path, record);
        return record;
    }

} // class TestBlocklist

} // namespace Testing
} // namespace Occ
