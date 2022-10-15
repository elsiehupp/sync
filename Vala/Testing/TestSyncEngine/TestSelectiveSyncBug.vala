/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSelectiveSyncBug : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestSelectiveSyncBug () {
        //  // issue owncloud/enterprise#1965 : files from selective-sync ignored
        //  // folders are uploaded anyway is some circumstances.
        //  FakeFolder fake_folder = new FakeFolder (
        //      new FileInfo (
        //          "", {
        //              new FileInfo (
        //                  "parent_folder", {
        //                      new FileInfo (
        //                          "sub_folder_a", {
        //                              {
        //                                  "file_a.txt", 400
        //                              },
        //                              {
        //                                  "file_b.txt", 400, 'o'
        //                              },
        //                              {
        //                                  "???" // mangled?
        //                              }, new FileInfonfo (
        //                                  "subsub_folder", {
        //                                      {
        //                                          "file_c.txt", 400
        //                                      },
        //                                      {
        //                                          "file_d.txt", 400, 'o'
        //                                      }
        //                                  }
        //                              ),
        //                              new FileInfo (
        //                                  "another_folder", {
        //                                      new FileInfo (
        //                                          "empty_folder", { }
        //                                      ), new FileInfo (
        //                                          "subsub_folder", {
        //                                              {
        //                                                  "file_e.txt", 400
        //                                              },
        //                                              {
        //                                                  "file_f.txt", 400, 'o'
        //                                              }
        //                                          }
        //                                      )
        //                                  }
        //                              )
        //                          }
        //                      ), new FileInfo (
        //                          "sub_folder_b", {}
        //                      )
        //                  }
        //              )
        //          }
        //      )
        //  );

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  var expected_server_state = fake_folder.current_remote_state ();

        //  // Remove sub_folder_a with selective_sync:
        //  fake_folder.sync_engine.journal.set_selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, {"parent_folder/sub_folder_a/"});
        //  fake_folder.sync_engine.journal.schedule_path_for_remote_discovery ("parent_folder/sub_folder_a/");
        //  GLib.assert_true (get_etag ("parent_folder") == "this.invalid_");
        //  GLib.assert_true (get_etag ("parent_folder/sub_folder_a") == "this.invalid_");
        //  GLib.assert_true (get_etag ("parent_folder/sub_folder_a/subsub_folder") != "this.invalid_");

        //  // But touch local file before the next sync, such that the local folder
        //  // can't be removed
        //  fake_folder.local_modifier.set_contents ("parent_folder/sub_folder_a/file_b.txt", 'n');
        //  fake_folder.local_modifier.set_contents ("parent_folder/sub_folder_a/subsub_folder/file_d.txt", 'n');
        //  fake_folder.local_modifier.set_contents ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_f.txt", 'n');

        //  // Several follow-up syncs don't change the state at all,
        //  // in particular the remote state doesn't change and file_b.txt
        //  // isn't uploaded.

        //  for (int i = 0; i < 3; ++i) {
        //      fake_folder.sync_once ();
        //      {
        //          // Nothing changed on the server
        //          GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        //          // The local state should still have sub_folder_a
        //          var local = fake_folder.current_local_state ();
        //          GLib.assert_true (local.find ("parent_folder/sub_folder_a"));
        //          GLib.assert_true (!local.find ("parent_folder/sub_folder_a/file_a.txt"));
        //          GLib.assert_true (local.find ("parent_folder/sub_folder_a/file_b.txt"));
        //          GLib.assert_true (!local.find ("parent_folder/sub_folder_a/subsub_folder/file_c.txt"));
        //          GLib.assert_true (local.find ("parent_folder/sub_folder_a/subsub_folder/file_d.txt"));
        //          GLib.assert_true (!local.find ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_e.txt"));
        //          GLib.assert_true (local.find ("parent_folder/sub_folder_a/another_folder/subsub_folder/file_f.txt"));
        //          GLib.assert_true (!local.find ("parent_folder/sub_folder_a/another_folder/empty_folder"));
        //          GLib.assert_true (local.find ("parent_folder/sub_folder_b"));
        //      }
        //  }
    }


    private static string get_etag (FakeFoler fake_folder, string file) {
        //  Common.SyncJournalFileRecord record;
        //  fake_folder.sync_journal ().get_file_record (file, record);
        //  return record.etag;
    }

} // class TestSelectiveSyncBug

} // namespace Testing
} // namespace Occ
