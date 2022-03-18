/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

bool item_did_complete (ItemCompletedSpy spy, string path) {
    var item = spy.find_item (path);
    if (item) {
        return item.instruction != SyncInstructions.NONE && item.instruction != SyncInstructions.UPDATE_METADATA;
    }
    return false;
}

bool item_instruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.find_item (path);
    return item.instruction == instr;
}

bool item_did_complete_successfully (ItemCompletedSpy spy, string path) {
    var item = spy.find_item (path);
    if (item) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

bool item_did_complete_successfully_with_expected_rank (ItemCompletedSpy spy, string path, int rank) {
    var item = spy.find_item_with_expected_rank (path, rank);
    if (item) {
        return item.status == SyncFileItem.Status.SUCCESS;
    }
    return false;
}

int item_successfully_completed_get_rank (ItemCompletedSpy spy, string path) {
    var it_item = std.find_if (spy.begin (), spy.end (), (current_item) => {
        var item = current_item[0].template_value<SyncFileItemPtr> ();
        return item.destination () == path;
    });
    if (it_item != spy.end ()) {
        return it_item - spy.begin ();
    }
    return -1;
}

public class TestSyncEngine : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_test_file_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().insert ("A/a0");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a0"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_file_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.local_modifier ().insert ("A/a0");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a0"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_dir_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().mkdir ("Y");
        fake_folder.remote_modifier ().mkdir ("Z");
        fake_folder.remote_modifier ().insert ("Z/d0");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Y"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z/d0"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_dir_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.local_modifier ().mkdir ("Y");
        fake_folder.local_modifier ().mkdir ("Z");
        fake_folder.local_modifier ().insert ("Z/d0");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Y"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z/d0"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_dir_upload_with_delayed_algorithm () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities (
            {
                {
                    "dav", new QVariantMap (
                        {
                            "bulkupload", "1.0"
                        }
                    )
                }
            }
        );

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.local_modifier ().mkdir ("Y");
        fake_folder.local_modifier ().insert ("Y/d0");
        fake_folder.local_modifier ().mkdir ("Z");
        fake_folder.local_modifier ().insert ("Z/d0");
        fake_folder.local_modifier ().insert ("A/a0");
        fake_folder.local_modifier ().insert ("B/b0");
        fake_folder.local_modifier ().insert ("r0");
        fake_folder.local_modifier ().insert ("r1");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully_with_expected_rank (complete_spy, "Y", 0));
        GLib.assert_true (item_did_complete_successfully_with_expected_rank (complete_spy, "Z", 1));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Y/d0"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "Y/d0") > 1);
        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z/d0"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "Z/d0") > 1);
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a0"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "A/a0") > 1);
        GLib.assert_true (item_did_complete_successfully (complete_spy, "B/b0"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "B/b0") > 1);
        GLib.assert_true (item_did_complete_successfully (complete_spy, "r0"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "r0") > 1);
        GLib.assert_true (item_did_complete_successfully (complete_spy, "r1"));
        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "r1") > 1);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_local_delete () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().remove ("A/a1");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a1"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_remote_delete () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.local_modifier ().remove ("A/a1");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a1"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_eml_local_checksum () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        fake_folder.local_modifier ().insert ("a1.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("a2.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("a3.eml", 64, 'A');
        fake_folder.local_modifier ().insert ("b3.txt", 64, 'A');
        // Upload and calculate the checksums
        // fake_folder.sync_once ();
        fake_folder.sync_once ();

        // printf 'A%.0s' {1..64} | sha1sum -
        string reference_checksum = "SHA1:30b86e44e6001403827a62c58b08893e77cf121f";
        GLib.assert_true (get_database_checksum (fake_folder, "a1.eml") == reference_checksum);
        GLib.assert_true (get_database_checksum (fake_folder, "a2.eml") == reference_checksum);
        GLib.assert_true (get_database_checksum (fake_folder, "a3.eml") == reference_checksum);
        GLib.assert_true (get_database_checksum (fake_folder, "b3.txt") == reference_checksum);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        // Touch the file without changing the content, shouldn't upload
        fake_folder.local_modifier ().set_contents ("a1.eml", 'A');
        // Change the content/size
        fake_folder.local_modifier ().set_contents ("a2.eml", 'B');
        fake_folder.local_modifier ().append_byte ("a3.eml");
        fake_folder.local_modifier ().append_byte ("b3.txt");
        fake_folder.sync_once ();

        GLib.assert_true (get_database_checksum ("a1.eml") == reference_checksum);
        GLib.assert_true (get_database_checksum ("a2.eml") == "SHA1:84951fc23a4dafd10020ac349da1f5530fa65949");
        GLib.assert_true (get_database_checksum ("a3.eml") == "SHA1:826b7e7a7af8a529ae1c7443c23bf185c0ad440c");
        GLib.assert_true (get_database_checksum ("b3.eml") == get_database_checksum ("a3.txt"));

        GLib.assert_true (!item_did_complete (complete_spy, "a1.eml"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "a2.eml"));
        GLib.assert_true (item_did_complete_successfully (complete_spy, "a3.eml"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private static string get_database_checksum (FakeFolder fake_folder, string path) {
        SyncJournalFileRecord record;
        fake_folder.sync_journal ().get_file_record (path, record);
        return record.checksum_header;
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_selective_sync_bug () {
        // issue owncloud/enterprise#1965 : files from selective-sync ignored
        // folders are uploaded anyway is some circumstances.
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo (
                "", {
                    new FileInfo (
                        "parent_folder", {
                            new FileInfo (
                                "sub_folder_a", {
                                    {
                                        "file_a.txt", 400
                                    },
                                    {
                                        "file_b.txt", 400, 'o'
                                    },
                                    {
                                        "???" // mangled?
                                    }, new FileInfonfo (
                                        "subsub_folder", {
                                            {
                                                "file_c.txt", 400
                                            },
                                            {
                                                "file_d.txt", 400, 'o'
                                            }
                                        }
                                    ),
                                    new FileInfo (
                                        "another_folder", {
                                            new FileInfo (
                                                "empty_folder", { }
                                            ), new FileInfo (
                                                "subsub_folder", {
                                                    {
                                                        "file_e.txt", 400
                                                    },
                                                    {
                                                        "file_f.txt", 400, 'o'
                                                    }
                                                }
                                            )
                                        }
                                    )
                                }
                            ), new FileInfo (
                                "sub_folder_b", {}
                            )
                        }
                    )
                }
            )
        );

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var expected_server_state = fake_folder.current_remote_state ();

        // Remove sub_folder_a with selective_sync:
        fake_folder.sync_engine.journal ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {"parent_folder/sub_folder_a/"});
        fake_folder.sync_engine.journal ().schedule_path_for_remote_discovery ("parent_folder/sub_folder_a/");
        GLib.assert_true (get_etag ("parent_folder") == "this.invalid_");
        GLib.assert_true (get_etag ("parent_folder/sub_folder_a") == "this.invalid_");
        GLib.assert_true (get_etag ("parent_folder/sub_folder_a/subsub_folder") != "this.invalid_");

        // But touch local file before the next sync, such that the local folder
        // can't be removed
        fake_folder.local_modifier ().set_contents ("parent_folder/sub_folder_a/file_b.txt", 'n');
        fake_folder.local_modifier ().set_contents ("parent_folder/sub_folder_a/subsub_folder/file_d.txt", 'n');
        fake_folder.local_modifier ().set_contents ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_f.txt", 'n');

        // Several follow-up syncs don't change the state at all,
        // in particular the remote state doesn't change and file_b.txt
        // isn't uploaded.

        for (int i = 0; i < 3; ++i) {
            fake_folder.sync_once ();
            {
                // Nothing changed on the server
                GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
                // The local state should still have sub_folder_a
                var local = fake_folder.current_local_state ();
                GLib.assert_true (local.find ("parent_folder/sub_folder_a"));
                GLib.assert_true (!local.find ("parent_folder/sub_folder_a/file_a.txt"));
                GLib.assert_true (local.find ("parent_folder/sub_folder_a/file_b.txt"));
                GLib.assert_true (!local.find ("parent_folder/sub_folder_a/subsub_folder/file_c.txt"));
                GLib.assert_true (local.find ("parent_folder/sub_folder_a/subsub_folder/file_d.txt"));
                GLib.assert_true (!local.find ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_e.txt"));
                GLib.assert_true (local.find ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_f.txt"));
                GLib.assert_true (!local.find ("parent_folder/sub_folder_a/another_folder/empty_folder"));
                GLib.assert_true (local.find ("parent_folder/sub_folder_b"));
            }
        }
    }


    private static string get_etag (FakeFoler fake_folder, string file) {
        SyncJournalFileRecord record;
        fake_folder.sync_journal ().get_file_record (file, record);
        return record.etag;
    }


    /***********************************************************
    ***********************************************************/
    private void abort_after_failed_mkdir () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        QSignalSpy finished_spy = new QSignalSpy (
            fake_folder.sync_engine,
            SIGNAL (on_signal_finished (bool))
        );
        fake_folder.server_error_paths ().append ("NewFolder");
        fake_folder.local_modifier ().mkdir ("NewFolder");
        // This should be aborted and would otherwise fail in FileInfo.create.
        fake_folder.local_modifier ().insert ("NewFolder/NewFile");
        fake_folder.sync_once ();
        GLib.assert_true (finished_spy.size () == 1);
        GLib.assert_true (finished_spy.first ().first ().to_bool () == false);
    }


    /***********************************************************
    Verify that an incompletely propagated directory doesn't
    have the server's etag stored in the database yet.
    ***********************************************************/
    private void test_dir_etag_after_incomplete_sync () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        QSignalSpy finished_spy = new QSignalSpy (
            fake_folder.sync_engine,
            SIGNAL (on_signal_finished (bool))
        );
        fake_folder.server_error_paths ().append ("NewFolder/foo");
        fake_folder.remote_modifier ().mkdir ("NewFolder");
        fake_folder.remote_modifier ().insert ("NewFolder/foo");
        GLib.assert_true (!fake_folder.sync_once ());

        SyncJournalFileRecord record;
        fake_folder.sync_journal ().get_file_record ("NewFolder", record);
        GLib.assert_true (record.is_valid ());
        GLib.assert_true (record.etag == "this.invalid_");
        GLib.assert_true (!record.file_identifier == "");
    }


    /***********************************************************
    ***********************************************************/
    private void test_dir_download_with_error () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().mkdir ("Y");
        fake_folder.remote_modifier ().mkdir ("Y/Z");
        fake_folder.remote_modifier ().insert ("Y/Z/d0");
        fake_folder.remote_modifier ().insert ("Y/Z/d1");
        fake_folder.remote_modifier ().insert ("Y/Z/d2");
        fake_folder.remote_modifier ().insert ("Y/Z/d3");
        fake_folder.remote_modifier ().insert ("Y/Z/d4");
        fake_folder.remote_modifier ().insert ("Y/Z/d5");
        fake_folder.remote_modifier ().insert ("Y/Z/d6");
        fake_folder.remote_modifier ().insert ("Y/Z/d7");
        fake_folder.remote_modifier ().insert ("Y/Z/d8");
        fake_folder.remote_modifier ().insert ("Y/Z/d9");
        fake_folder.server_error_paths ().append ("Y/Z/d2", 503);
        fake_folder.server_error_paths ().append ("Y/Z/d3", 503);
        GLib.assert_true (!fake_folder.sync_once ());
        Gtk.Application.process_events (); // should not crash

        GLib.Set<string> seen;
        foreach (GLib.List<GLib.Variant> args in complete_spy) {
            var item = args[0].value<SyncFileItemPtr> ();
            GLib.debug () + item.file + item.is_directory () + item.status;
            GLib.assert_true (!seen.contains (item.file)); // signal only sent once per item
            seen.insert (item.file);
            if (item.file == "Y/Z/d2") {
                GLib.assert_true (item.status == SyncFileItem.Status.NORMAL_ERROR);
            } else if (item.file == "Y/Z/d3") {
                GLib.assert_true (item.status != SyncFileItem.Status.SUCCESS);
            } else if (!item.is_directory ()) {
                GLib.assert_true (item.status == SyncFileItem.Status.SUCCESS);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_fake_conflict_data () {
        QTest.add_column<bool> ("same_mtime");
        QTest.add_column<string> ("checksums");

        QTest.add_column<int> ("expected_get");

        QTest.new_row ("Same mtime, but no server checksum . ignored in reconcile")
            + true + ""
            << 0;

        QTest.new_row ("Same mtime, weak server checksum differ . downloaded")
            + true + "Adler32:bad"
            << 1;

        QTest.new_row ("Same mtime, matching weak checksum . skipped")
            + true + "Adler32:2a2010d"
            << 0;

        QTest.new_row ("Same mtime, strong server checksum differ . downloaded")
            + true + "SHA1:bad"
            << 1;

        QTest.new_row ("Same mtime, matching strong checksum . skipped")
            + true + "SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427"
            << 0;

        QTest.new_row ("mtime changed, but no server checksum . download")
            + false + ""
            << 1;

        QTest.new_row ("mtime changed, weak checksum match . download anyway")
            + false + "Adler32:2a2010d"
            << 1;

        QTest.new_row ("mtime changed, strong checksum match . skip")
            + false + "SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427"
            << 0;
    }


    /***********************************************************
    ***********************************************************/
    private void test_fake_conflict () {
        QFETCH (bool, same_mtime);
        QFETCH (string, checksums);
        QFETCH (int, expected_get);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int n_get = 0;
        fake_folder.set_server_override (this.override_delegate_fake_conflict);

        // For directly editing the remote checksum
        var remote_info = fake_folder.remote_modifier ();

        // Base mtime with no ms content (filesystem is seconds only)
        var mtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        mtime.set_msecs_since_epoch (mtime.to_m_secs_since_epoch () / 1000 * 1000);

        fake_folder.local_modifier ().set_contents ("A/a1", 'C');
        fake_folder.local_modifier ().set_modification_time ("A/a1", mtime);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'C');
        if (!same_mtime)
            mtime = mtime.add_days (1);
        fake_folder.remote_modifier ().set_modification_time ("A/a1", mtime);
        remote_info.find ("A/a1").checksums = checksums;
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == expected_get);

        // check that mtime in journal and filesystem agree
        string a1path = fake_folder.local_path () + "A/a1";
        SyncJournalFileRecord a1record;
        fake_folder.sync_journal ().get_file_record ("A/a1", a1record);
        GLib.assert_true (a1record.modtime == (int64)FileSystem.get_mod_time (a1path));

        // Extra sync reads from database, no difference
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == expected_get);
    }


    private Soup.Reply override_delegate_fake_conflict (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation)
            ++n_get;
        return null;
    }


    /***********************************************************
    Checks whether SyncFileItems have the expected properties
    before start of propagation.
    ***********************************************************/
    private void test_sync_file_item_properties () {
        var initial_mtime = GLib.DateTime.current_date_time_utc ().add_days (-7);
        var changed_mtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        var changed_mtime2 = GLib.DateTime.current_date_time_utc ().add_days (-3);

        // Base mtime with no ms content (filesystem is seconds only)
        initial_mtime.set_msecs_since_epoch (initial_mtime.to_m_secs_since_epoch () / 1000 * 1000);
        changed_mtime.set_msecs_since_epoch (changed_mtime.to_m_secs_since_epoch () / 1000 * 1000);
        changed_mtime2.set_msecs_since_epoch (changed_mtime2.to_m_secs_since_epoch () / 1000 * 1000);

        // Ensure the initial mtimes are as expected
        var initial_file_info = FileInfo.A12_B12_C12_S12 ();
        initial_file_info.set_modification_time ("A/a1", initial_mtime);
        initial_file_info.set_modification_time ("B/b1", initial_mtime);
        initial_file_info.set_modification_time ("C/c1", initial_mtime);

        FakeFolder fake_folder = new FakeFolder (initial_file_info);

        // upload a
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().set_modification_time ("A/a1", changed_mtime);
        // download b
        fake_folder.remote_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().set_modification_time ("B/b1", changed_mtime);
        // conflict c
        fake_folder.local_modifier ().append_byte ("C/c1");
        fake_folder.local_modifier ().append_byte ("C/c1");
        fake_folder.local_modifier ().set_modification_time ("C/c1", changed_mtime);
        fake_folder.remote_modifier ().append_byte ("C/c1");
        fake_folder.remote_modifier ().set_modification_time ("C/c1", changed_mtime2);

        fake_folder.sync_engine.signal_about_to_propagate.connect (
            this.on_signal_sync_engine_about_to_propagate
        );

        GLib.assert_true (fake_folder.sync_once ());
    }


    private void on_signal_sync_engine_about_to_propagate (SyncFileItemVector items) {
        SyncFileItemPtr a1, b1, c1;
        foreach (var item in items) {
            if (item.file == "A/a1") {
                a1 = item;
            }
            if (item.file == "B/b1") {
                b1 = item;
            }
            if (item.file == "C/c1") {
                c1 = item;
            }
        }

        // a1 : should have local size and modtime
        GLib.assert_true (a1);
        GLib.assert_true (a1.instruction == SyncInstructions.SYNC);
        GLib.assert_true (a1.direction == SyncFileItem.Direction.UP);
        GLib.assert_true (a1.size == (int64) 5);

        GLib.assert_true (Utility.date_time_from_time_t (a1.modtime) == changed_mtime);
        GLib.assert_true (a1.previous_size == (int64) 4);
        GLib.assert_true (Utility.date_time_from_time_t (a1.previous_modtime) == initial_mtime);

        // b2 : should have remote size and modtime
        GLib.assert_true (b1);
        GLib.assert_true (b1.instruction == SyncInstructions.SYNC);
        GLib.assert_true (b1.direction == SyncFileItem.Direction.DOWN);
        GLib.assert_true (b1.size == (int64) 17);
        GLib.assert_true (Utility.date_time_from_time_t (b1.modtime) == changed_mtime);
        GLib.assert_true (b1.previous_size == (int64) 16);
        GLib.assert_true (Utility.date_time_from_time_t (b1.previous_modtime) == initial_mtime);

        // c1 : conflicts are downloads, so remote size and modtime
        GLib.assert_true (c1);
        GLib.assert_true (c1.instruction == SyncInstructions.CONFLICT);
        GLib.assert_true (c1.direction == SyncFileItem.Direction.NONE);
        GLib.assert_true (c1.size == (int64) 25);
        GLib.assert_true (Utility.date_time_from_time_t (c1.modtime) == changed_mtime2);
        GLib.assert_true (c1.previous_size == (int64) 26);
        GLib.assert_true (Utility.date_time_from_time_t (c1.previous_modtime) == changed_mtime);
    }


    /***********************************************************
    Checks whether subsequent large uploads are skipped after a
    507 error
    ***********************************************************/
    private void test_insufficient_remote_storage () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Disable parallel uploads
        SyncOptions sync_options;
        sync_options.parallel_network_jobs = 0;
        fake_folder.sync_engine.set_sync_options (sync_options);

        // Produce an error based on upload size
        int remote_quota = 1000;
        int n507 = 0, number_of_put = 0;
        GLib.Object parent;
        fake_folder.set_server_override (this.override_delegate_insufficient_remote_storage);

        fake_folder.local_modifier ().insert ("A/big", 800);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 1);
        GLib.assert_true (n507 == 0);

        number_of_put = 0;
        fake_folder.local_modifier ().insert ("A/big1", 500); // ok
        fake_folder.local_modifier ().insert ("A/big2", 1200); // 507 (quota guess now 1199)
        fake_folder.local_modifier ().insert ("A/big3", 1200); // skipped
        fake_folder.local_modifier ().insert ("A/big4", 1500); // skipped
        fake_folder.local_modifier ().insert ("A/big5", 1100); // 507 (quota guess now 1099)
        fake_folder.local_modifier ().insert ("A/big6", 900); // ok (quota guess now 199)
        fake_folder.local_modifier ().insert ("A/big7", 200); // skipped
        fake_folder.local_modifier ().insert ("A/big8", 199); // ok (quota guess now 0)

        fake_folder.local_modifier ().insert ("B/big8", 1150); // 507
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 6);
        GLib.assert_true (n507 == 3);
    }


    private Soup.Reply override_delegate_insufficient_remote_storage (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) {

        if (operation == Soup.PutOperation) {
            number_of_put++;
            if (request.raw_header ("OC-Total-Length").to_int () > remote_quota) {
                n507++;
                return new FakeErrorReply (operation, request, parent, 507);
            }
        }
        return null;
    }


    /***********************************************************
    Checks whether downloads with bad checksums are accepted
    ***********************************************************/
    private void test_checksum_validation () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.Object parent;

        string checksum_value;
        string content_md5_value;

        fake_folder.set_server_override (this.override_delegate_checksum_validation);

        // Basic case
        fake_folder.remote_modifier ().create ("A/a3", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Bad OC-Checksum
        checksum_value = "SHA1:bad";
        fake_folder.remote_modifier ().create ("A/a4", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good OC-Checksum
        checksum_value = "SHA1:19b1928d58a2030d08023f3d7054516dbc186f20"; // printf 'A%.0s' {1..16} | sha1sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        checksum_value = "";

        // Bad Content-MD5
        content_md5_value = "bad";
        fake_folder.remote_modifier ().create ("A/a5", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good Content-MD5
        content_md5_value = "d8a73157ce10cd94a91c2079fc9a92c8"; // printf 'A%.0s' {1..16} | md5sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Invalid OC-Checksum is ignored
        checksum_value = "garbage";
        // content_md5_value is still good
        fake_folder.remote_modifier ().create ("A/a6", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        content_md5_value = "bad";
        fake_folder.remote_modifier ().create ("A/a7", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());
        content_md5_value.clear ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // OC-Checksum contains Unsupported checksums
        checksum_value = "Unsupported:XXXX SHA1:invalid Invalid:XxX";
        fake_folder.remote_modifier ().create ("A/a8", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ()); // Since the supported SHA1 checksum is invalid, no download
        checksum_value =  "Unsupported:XXXX SHA1:19b1928d58a2030d08023f3d7054516dbc186f20 Invalid:XxX";
        GLib.assert_true (fake_folder.sync_once ()); // The supported SHA1 checksum is valid now, so the file are downloaded
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private Soup.Reply override_delegate_checksum_validation (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation) {
            var reply = new FakeGetReply (fake_folder.remote_modifier (), operation, request, parent);
            if (!checksum_value.is_null ())
                reply.set_raw_header ("OC-Checksum", checksum_value);
            if (!content_md5_value.is_null ())
                reply.set_raw_header ("Content-MD5", content_md5_value);
            return reply;
        }
        return null;
    }


    /***********************************************************
    Tests the behavior of invalid filename detection
    ***********************************************************/
    private void test_invalid_filename_regex () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // For current servers, no characters are forbidden
        fake_folder.sync_engine.account.set_server_version ("10.0.0");
        fake_folder.local_modifier ().insert ("A/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // For legacy servers, some characters were forbidden by the client
        fake_folder.sync_engine.account.set_server_version ("8.0.0");
        fake_folder.local_modifier ().insert ("B/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/\\:?*\"<>|.txt"));

        // We can override that by setting the capability
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "invalid_filename_regex", "" } ) } });
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Check that new servers also accept the capability
        fake_folder.sync_engine.account.set_server_version ("10.0.0");
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "invalid_filename_regex", "my[fgh]ile" } ) } });
        fake_folder.local_modifier ().insert ("C/myfile.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/myfile.txt"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_discovery_hidden_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.sync_engine.set_ignore_hidden_files (true);
        fake_folder.remote_modifier ().insert ("A/.hidden");
        fake_folder.local_modifier ().insert ("B/.hidden");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!local_file_exists ("A/.hidden"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/.hidden"));

        fake_folder.sync_engine.set_ignore_hidden_files (false);
        fake_folder.sync_journal ().force_remote_discovery_next_sync ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (local_file_exists ("A/.hidden"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/.hidden"));
    }


    /***********************************************************
    We can't depend on current_local_state for hidden files since
    it should rightfully skip things like download temporaries
    ***********************************************************/
    private static FileInfo local_file_exists (FakeFolder fake_folder, string name) {
        return new FileInfo (fake_folder.local_path () + name).exists ();
    }


    /***********************************************************
    ***********************************************************/
    private void test_no_local_encoding () {
        var utf8Locale = QTextCodec.codec_for_locale ();
        if (utf8Locale.mib_enum () != 106) {
            QSKIP ("Test only works for UTF8 locale");
        }

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Utf8 locale can sync both
        fake_folder.remote_modifier ().insert ("A/tößt");
        fake_folder.remote_modifier ().insert ("A/t𠜎t");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/tößt"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/t𠜎t"));

        // Try again with a locale that can represent ö but not 𠜎 (4-byte utf8).
        QTextCodec.set_codec_for_locale (QTextCodec.codec_for_name ("ISO-8859-15"));
        GLib.assert_true (QTextCodec.codec_for_locale ().mib_enum () == 111);

        fake_folder.remote_modifier ().insert ("B/tößt");
        fake_folder.remote_modifier ().insert ("B/t𠜎t");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("B/tößt"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t𠜎t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t?t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t??t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t???t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/t????t"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/tößt"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/t𠜎t"));

        // Try again with plain ascii
        QTextCodec.set_codec_for_locale (QTextCodec.codec_for_name ("ASCII"));
        GLib.assert_true (QTextCodec.codec_for_locale ().mib_enum () == 3);

        fake_folder.remote_modifier ().insert ("C/tößt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/tößt"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/t??t"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/t????t"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/tößt"));

        QTextCodec.set_codec_for_locale (utf8Locale);
    }


    /***********************************************************
    Aborting has had bugs when there are parallel upload jobs
    ***********************************************************/
    private void test_upload_v1_multiabort () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        SyncOptions options;
        options.initial_chunk_size = 10;
        options.max_chunk_size = 10;
        options.min_chunk_size = 10;
        fake_folder.sync_engine.set_sync_options (options);

        GLib.Object parent;
        int number_of_put = 0;
        fake_folder.set_server_override (this.override_delegate);

        fake_folder.local_modifier ().insert ("file", 100, 'W');
        GLib.Timeout.single_shot (100, fake_folder.sync_engine, () => { fake_folder.sync_engine.on_signal_abort (); });
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (number_of_put == 3);
    }


    private Soup.Reply override_delegate (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation) {
            ++number_of_put;
            return new FakeHangingReply (operation, request, parent);
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void test_propagate_permissions () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var perm = QFileDevice.Permission (0x7704); // user/owner : rwx, group : r, other : -
        GLib.File.set_permissions (fake_folder.local_path () + "A/a1", perm);
        GLib.File.set_permissions (fake_folder.local_path () + "A/a2", perm);
        fake_folder.sync_once (); // get the metadata-only change out of the way
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.sync_once (); // perms should be preserved
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").permissions () == perm);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a2").permissions () == perm);

        var conflict_name = fake_folder.sync_journal ().conflict_record (fake_folder.sync_journal ().conflict_record_paths ().first ()).path;
        GLib.assert_true (conflict_name.contains ("A/a2"));
        GLib.assert_true (new FileInfo (fake_folder.local_path () + conflict_name).permissions () == perm);
    }


    /***********************************************************
    ***********************************************************/
    private void test_empty_local_but_has_remote () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        fake_folder.remote_modifier ().mkdir ("foo");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.assert_true (fake_folder.current_local_state ().find ("foo"));

    }


    /***********************************************************
    Check that server mtime is set on directories on initial
    propagation
    ***********************************************************/
    private void test_directory_initial_mtime () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        fake_folder.remote_modifier ().mkdir ("foo");
        fake_folder.remote_modifier ().insert ("foo/bar");
        var datetime = GLib.DateTime.current_date_time ();
        datetime.set_secs_since_epoch (datetime.to_seconds_since_epoch ()); // wipe ms
        fake_folder.remote_modifier ().find ("foo").last_modified = datetime;

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.assert_true (new FileInfo (fake_folder.local_path () + "foo").last_modified () == datetime);
    }


    /***********************************************************
    Checks whether subsequent large uploads are skipped after a
    507 error
    ***********************************************************/
    private void test_errors_with_bulk_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "bulkupload", "1.0" } ) } });

        // Disable parallel uploads
        SyncOptions sync_options;
        sync_options.parallel_network_jobs = 0;
        fake_folder.sync_engine.set_sync_options (sync_options);

        int number_of_put = 0;
        int number_of_post = 0;
        fake_folder.set_server_override (this.override_delegate_with_bulk_upload);

        fake_folder.local_modifier ().insert ("A/big", 1);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 0);
        GLib.assert_true (number_of_post == 1);
        number_of_put = 0;
        number_of_post = 0;

        fake_folder.local_modifier ().insert ("A/big1", 1); // ok
        fake_folder.local_modifier ().insert ("A/big2", 1); // ko
        fake_folder.local_modifier ().insert ("A/big3", 1); // ko
        fake_folder.local_modifier ().insert ("A/big4", 1); // ko
        fake_folder.local_modifier ().insert ("A/big5", 1); // ko
        fake_folder.local_modifier ().insert ("A/big6", 1); // ok
        fake_folder.local_modifier ().insert ("A/big7", 1); // ko
        fake_folder.local_modifier ().insert ("A/big8", 1); // ok
        fake_folder.local_modifier ().insert ("B/big8", 1); // ko

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 0);
        GLib.assert_true (number_of_post == 1);
        number_of_put = 0;
        number_of_post = 0;

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 6);
        GLib.assert_true (number_of_post == 0);
    }


    private Soup.Reply override_delegate_with_bulk_upload (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) {
        var content_type = request.header (Soup.Request.ContentTypeHeader).to_string ();
        if (operation == Soup.PostOperation) {
            ++number_of_post;
            if (content_type.starts_with ("multipart/related; boundary=")) {
                var json_reply_object = fake_folder.for_each_reply_part (outgoing_data, content_type, fake_folder_for_each_reply_part_delegate
                );
                if (json_reply_object.size ()) {
                    var json_reply = new QJsonDocument ();
                    json_reply.set_object (json_reply_object);
                    return new FakeJsonErrorReply (operation, request, this, 200, json_reply);
                }
                return  null;
            }
        } else if (operation == Soup.PutOperation) {
            ++number_of_put;
            var filename = get_file_path_from_url (request.url);
            if (filename.ends_with ("A/big2") ||
                    filename.ends_with ("A/big3") ||
                    filename.ends_with ("A/big4") ||
                    filename.ends_with ("A/big5") ||
                    filename.ends_with ("A/big7") ||
                    filename.ends_with ("B/big8")) {
                return new FakeErrorReply (operation, request, this, 412);
            }
            return null;
        }
        return null;
    }


    private QJsonObject fake_folder_for_each_reply_part_delegate (GLib.HashTable<string, string> all_headers) {
        var reply = new QJsonObject ();
        var filename = all_headers["X-File-Path"];
        if (filename.ends_with ("A/big2") ||
                filename.ends_with ("A/big3") ||
                filename.ends_with ("A/big4") ||
                filename.ends_with ("A/big5") ||
                filename.ends_with ("A/big7") ||
                filename.ends_with ("B/big8")) {
            reply.insert ("error", true);
            reply.insert ("etag", {});
            return reply;
        } else {
            reply.insert ("error", false);
            reply.insert ("etag", {});
        }
        return reply;
    }

}
}
