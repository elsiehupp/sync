/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <configfile.h>

using Occ;

namespace Testing {

/***********************************************************
This test ensure that the SyncEngine.signal_about_to_remove_all_files
is correctly called and that when we the user choose to
remove all files SyncJournalDb.clear_file_table makes works
as expected
***********************************************************/
public class TestAllFilesDeleted : GLib.Object {

    private delegate void Callback (bool value);

    /***********************************************************
    ***********************************************************/
    private void test_all_files_deleted_keep_data () {
        QTest.add_column<bool> ("delete_on_remote");
        QTest.new_row ("local") + false;
        QTest.new_row ("remote") + true;
    }


    /***********************************************************
    In this test, all files are deleted in the client, or the
    server, and we simulate that the users press "keep"
    ***********************************************************/
    private void test_all_files_deleted_keep () {
        QFETCH (
            bool,
            delete_on_remote
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ConfigFile config;
        config.set_prompt_delete_files (true);

        //Just set a blocklist so we can check it is still there. This directory does not exists but
        // that does not matter for our purposes.
        string[] selective_sync_blocklist = { "Q/" };
        fake_folder.sync_engine.journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                                                                selective_sync_blocklist);

        var initial_state = fake_folder.current_local_state ();
        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_all_files_deleted_keep
        );

        var modifier = delete_on_remote ? fake_folder.remote_modifier () : fake_folder.local_modifier;
        foreach (var state in fake_folder.current_remote_state ().children.keys ()) {
            modifier.remove (state);
        }

        GLib.assert_true (!fake_folder.sync_once ()); // Should fail because we cancel the sync
        GLib.assert_true (about_to_remove_all_files_called == 1);

        // Next sync should recover all files
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fake_folder.current_local_state () ==
            initial_state
        );
        GLib.assert_true (
            fake_folder.current_remote_state () ==
            initial_state
        );

        // The selective sync blocklist should be not have been deleted.
        bool ok = true;
        GLib.assert_true (
            fake_folder.sync_engine.journal.get_gelective_sync_list (
                SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                ok
            ) ==
            selective_sync_blocklist
        );
    }


    private void on_signal_about_to_remove_all_files_all_files_deleted_keep (SyncFileItem.Direction directory, Callback callback) {
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );
        about_to_remove_all_files_called++;
        GLib.assert_true (
            directory ==
            delete_on_remote ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP
        );
        callback (true);
        fake_folder.sync_engine.journal.clear_file_table (); // That's what Folder is doing
    }


    /***********************************************************
    ***********************************************************/
    private void test_all_files_deleted_delete_data () {
        test_all_files_deleted_keep_data ();
    }


    /***********************************************************
    This test is like the previous one but we simulate that the user presses "delete"
    ***********************************************************/
    private void test_all_files_deleted_delete () {
        QFETCH (
            bool,
            delete_on_remote
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_all_files_deleted_delete
        );

        var modifier = delete_on_remote ? fake_folder.remote_modifier () : fake_folder.local_modifier;
        foreach (var s in fake_folder.current_remote_state ().children.keys ())
            modifier.remove (s);

        GLib.assert_true (
            fake_folder.sync_once ()
        ); // Should succeed and all files must then be deleted

        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_local_state ().children.count () ==
            0
        );

        // Try another sync to be sure.

        GLib.assert_true (fake_folder.sync_once ()); // Should succeed (doing nothing)
        GLib.assert_true (
            about_to_remove_all_files_called ==
            1
        ); // should not have been called.

        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_local_state ().children.count () ==
            0
        );
    }


    private void on_signal_about_to_remove_all_files_all_files_deleted_delete (
        SyncFileItem.Direction directory,
        Callback callback
    ) {
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );
        about_to_remove_all_files_called++;
        GLib.assert_true (
            directory ==
            delete_on_remote ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP
        );
        callback (false);
    }


    /***********************************************************
    This test make sure that we don't popup a file deleted
    message if all the metadata have been updated (for example
    when the server is upgraded or something)
    ***********************************************************/
    private void test_not_delete_metadata_change () {

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        // We never remove all files.
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_not_delete_metadata_change
        );
        GLib.assert_true (fake_folder.sync_once ());

        foreach (var s in fake_folder.current_remote_state ().children.keys ()) {
            fake_folder.sync_journal ().avoid_renames_on_next_sync (s); // clears all the fileid and inodes.
        }
        fake_folder.local_modifier.remove ("A/a1");
        var expected_state = fake_folder.current_local_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fake_folder.current_local_state () ==
            expected_state
        );
        GLib.assert_true (
            fake_folder.current_remote_state () ==
            expected_state
        );

        fake_folder.remote_modifier ().remove ("B/b1");
        change_all_file_id (fake_folder.remote_modifier ());
        expected_state = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fake_folder.current_local_state () ==
            expected_state
        );
        GLib.assert_true (
            fake_folder.current_remote_state () ==
            expected_state
        );
    }


    private void on_signal_about_to_remove_all_files_not_delete_metadata_change () {
        GLib.assert_true (false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_reset_server () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_reset_server
        );

        // Some small changes
        fake_folder.local_modifier.mkdir ("Q");
        fake_folder.local_modifier.insert ("Q/q1");
        fake_folder.local_modifier.append_byte ("B/b1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );

        // Do some change localy
        fake_folder.local_modifier.append_byte ("A/a1");

        // reset the server.
        fake_folder.remote_modifier () = FileInfo.A12_B12_C12_S12 ();

        // Now, signal_about_to_remove_all_files with down as a direction
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            about_to_remove_all_files_called ==
            1
        );
    }


    private void on_signal_about_to_remove_all_files_reset_server (
        SyncFileItem.Direction directory,
        Callback callback
    ) {
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );
        about_to_remove_all_files_called++;
        GLib.assert_true (
            directory ==
            SyncFileItem.Direction.DOWN
        );
        callback (false);
    }


    /***********************************************************
    ***********************************************************/
    private void test_data_fingerprint_data () {
        QTest.add_column<bool> ("has_initial_finger_print");
        QTest.new_row ("initial finger print") + true;
        QTest.new_row ("no initial finger print") + false;
    }


    /***********************************************************
    ***********************************************************/
    private void test_data_fingerprint () {
        QFETCH (
            bool,
            has_initial_finger_print
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().set_contents (
            "C/c1",
            'N'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "C/c1",
            GLib.DateTime.current_date_time_utc ().add_days (-2)
        );
        fake_folder.remote_modifier ().remove ("C/c2");
        if (has_initial_finger_print) {
            fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint>initial_finger_print</oc:data-fingerprint>";
        } else {
            // Server support finger print but none is set.
            fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint></oc:data-fingerprint>";
        }

        int fingerprint_requests = 0;
        fake_folder.set_server_override (this.override_delegate);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fingerprint_requests ==
            1
        );
        // First sync, we did not change the finger print, so the file should be downloaded as normal
        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_remote_state ().find ("C/c1").content_char ==
            'N'
        );
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/c2"));

        /* Simulate a backup restoration */

        // A/a1 is an old file
        fake_folder.remote_modifier ().set_contents (
            "A/a1",
            'O'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "A/a1",
            GLib.DateTime.current_date_time_utc ().add_days (-2)
        );
        // B/b1 did not exist at the time of the backup
        fake_folder.remote_modifier ().remove ("B/b1");
        // B/b2 was uploaded by another user in the mean time.
        fake_folder.remote_modifier ().set_contents (
            "B/b2",
            'N'
        );
        fake_folder.remote_modifier ().set_modification_time (
            "B/b2",
            GLib.DateTime.current_date_time_utc ().add_days (2)
        );

        // C/c3 was removed since we made the backup
        fake_folder.remote_modifier ().insert ("C/c3_removed");
        // C/c4 was moved to A/a2 since we made the backup
        fake_folder.remote_modifier ().rename (
            "A/a2",
            "C/old_a2_location"
        );

        // The admin sets the data-fingerprint property
        fake_folder.remote_modifier ().extra_dav_properties = "<oc:data-fingerprint>new_finger_print</oc:data-fingerprint>";

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fingerprint_requests ==
            2
        );
        var current_state = fake_folder.current_local_state ();
        // Altough the local file is kept as a conflict, the server file is downloaded
        GLib.assert_true (
            current_state.find ("A/a1").content_char ==
            'O'
        );
        var conflict = find_conflict (
            current_state,
            "A/a1"
        );
        GLib.assert_true (conflict);
        GLib.assert_true (
            conflict.content_char ==
            'W'
        );
        fake_folder.local_modifier.remove (conflict.path);
        // b1 was restored (re-uploaded)
        GLib.assert_true (current_state.find ("B/b1"));

        // b2 has the new content (was not restored), since its mode time goes forward in time
        GLib.assert_true (
            current_state.find ("B/b2").content_char ==
            'N'
        );
        conflict = find_conflict (
            current_state,
            "B/b2"
        );
        GLib.assert_true (conflict); // Just to be sure, we kept the old file in a conflict
        GLib.assert_true (
            conflict.content_char ==
            'W'
        );
        fake_folder.local_modifier.remove (conflict.path);

        // We actually do not remove files that technically should have been removed (we don't want data-loss)
        GLib.assert_true (current_state.find ("C/c3_removed"));
        GLib.assert_true (current_state.find ("C/old_a2_location"));

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private Soup.Reply override_delegate (
        Soup.Operation operation,
        Soup.Request request,
        QIODevice stream
    ) {
        var verb = request.attribute (Soup.Request.CustomVerbAttribute);
        if (verb == "PROPFIND") {
            var data = stream.read_all ();
            if (data.contains ("data-fingerprint")) {
                if (request.url.path.ends_with ("dav/files/admin/")) {
                    ++fingerprint_requests;
                } else {
                    fingerprint_requests = -10000; // fingerprint queried on incorrect path
                }
            }
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void test_single_file_renamed () {
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo ()
        );

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_single_file_renamed
        );

        // add a single file
        fake_folder.local_modifier.insert ("hello.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (about_to_remove_all_files_called == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // rename it
        fake_folder.local_modifier.rename ("hello.txt", "goodbye.txt");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (about_to_remove_all_files_called == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private void on_signal_about_to_remove_all_files_single_file_renamed (
        SyncFileItem.Direction direction,
        Callback callback
    ) {
        about_to_remove_all_files_called++;
        GLib.assert_not_reached ("should not be called");
    }


    /***********************************************************
    ***********************************************************/
    private void test_selective_sync_o_popup () {
        // Unselecting all folder should not cause the popup to be shown
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_selective_sync_o_popup
        );

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (about_to_remove_all_files_called == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.sync_engine.journal.set_selective_sync_list (
            SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
            {
                "A/", "B/", "C/", "S/"
            }
        );

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == new FileInfo ()); // all files should be one localy
        GLib.assert_true (fake_folder.current_remote_state () == FileInfo.A12_B12_C12_S12 ()); // Server not changed
        GLib.assert_true (about_to_remove_all_files_called == 0); // But we did not show the popup
    }


    private void on_signal_about_to_remove_all_files_selective_sync_o_popup (
        SyncFileItem.Direction direction,
        Callback callback
    ) {
        about_to_remove_all_files_called++;
        GLib.assert_not_reached ("should not be called");
    }


    static void change_all_file_id (FileInfo info) {
        info.file_identifier = generate_file_id ();
        if (!info.is_directory) {
            return;
        }
        info.etag = generate_etag ();
        foreach (var child in info.children) {
            change_all_file_id (child);
        }
    }

} // class TestAllFilesDeleted
} // namespace Testing
