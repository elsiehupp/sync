/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestEmlLocalChecksum : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestEmlLocalChecksum () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  fake_folder.local_modifier.insert ("a1.eml", 64, 'A');
        //  fake_folder.local_modifier.insert ("a2.eml", 64, 'A');
        //  fake_folder.local_modifier.insert ("a3.eml", 64, 'A');
        //  fake_folder.local_modifier.insert ("b3.txt", 64, 'A');
        //  // Upload and calculate the checksums
        //  // fake_folder.sync_once ();
        //  fake_folder.sync_once ();

        //  // printf 'A%.0s' {1..64} | sha1sum -
        //  string reference_checksum = "SHA1:30b86e44e6001403827a62c58b08893e77cf121f";
        //  GLib.assert_true (get_database_checksum (fake_folder, "a1.eml") == reference_checksum);
        //  GLib.assert_true (get_database_checksum (fake_folder, "a2.eml") == reference_checksum);
        //  GLib.assert_true (get_database_checksum (fake_folder, "a3.eml") == reference_checksum);
        //  GLib.assert_true (get_database_checksum (fake_folder, "b3.txt") == reference_checksum);

        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        //  // Touch the file without changing the content, shouldn't upload
        //  fake_folder.local_modifier.set_contents ("a1.eml", 'A');
        //  // Change the content/size
        //  fake_folder.local_modifier.set_contents ("a2.eml", 'B');
        //  fake_folder.local_modifier.append_byte ("a3.eml");
        //  fake_folder.local_modifier.append_byte ("b3.txt");
        //  fake_folder.sync_once ();

        //  GLib.assert_true (get_database_checksum ("a1.eml") == reference_checksum);
        //  GLib.assert_true (get_database_checksum ("a2.eml") == "SHA1:84951fc23a4dafd10020ac349da1f5530fa65949");
        //  GLib.assert_true (get_database_checksum ("a3.eml") == "SHA1:826b7e7a7af8a529ae1c7443c23bf185c0ad440c");
        //  GLib.assert_true (get_database_checksum ("b3.eml") == get_database_checksum ("a3.txt"));

        //  GLib.assert_true (!item_did_complete (complete_spy, "a1.eml"));
        //  GLib.assert_true (item_did_complete_successfully (complete_spy, "a2.eml"));
        //  GLib.assert_true (item_did_complete_successfully (complete_spy, "a3.eml"));
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private static string get_database_checksum (FakeFolder fake_folder, string path) {
        //  Common.SyncJournalFileRecord record;
        //  fake_folder.sync_journal ().get_file_record (path, record);
        //  return record.checksum_header;
    }

} // class TestEmlLocalChecksum

} // namespace Testing
} // namespace Occ
