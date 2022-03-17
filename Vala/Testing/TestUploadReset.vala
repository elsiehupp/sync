/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <common/syncjournaldatabase.h>

using Occ;

namespace Testing {

public class TestUploadReset : GLib.Object {

    // Verify that the chunked transfer eventually gets reset with the new chunking
    private void on_signal_test_file_upload_ng () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.sync_engine ().account ().set_capabilities ({
            {
                "dav", new QVariantMap (
                    {
                        "chunking", "1.0"
                    },
                    {
                        "httpErrorCodesThatResetFailingChunkedUploads", new QVariantList (500)
                    }
                )
            }
        });

        const int size = 100 * 1000 * 1000; // 100 MB
        fake_folder.local_modifier ().insert ("A/a0", size);
        GLib.DateTime modification_time = GLib.DateTime.current_date_time ();
        fake_folder.local_modifier ().set_modification_time ("A/a0", modification_time);

        // Create a transfer identifier, so we can make the final MOVE fail
        SyncJournalDb.UploadInfo upload_info;
        upload_info.transferid = 1;
        upload_info.valid = true;
        upload_info.modtime = Utility.date_time_to_time_t (modification_time);
        upload_info.size = size;
        fake_folder.sync_engine ().journal ().set_upload_info ("A/a0", upload_info);

        fake_folder.upload_state ().mkdir ("1");
        fake_folder.server_error_paths ().append ("1/.file");

        GLib.assert_true (!fake_folder.sync_once ());

        upload_info = fake_folder.sync_engine ().journal ().get_upload_info ("A/a0");
        GLib.assert_true (upload_info.error_count == 1);
        GLib.assert_true (upload_info.transferid == 1U);

        fake_folder.sync_engine ().journal ().wipe_error_blocklist ();
        GLib.assert_true (!fake_folder.sync_once ());

        upload_info = fake_folder.sync_engine ().journal ().get_upload_info ("A/a0");
        GLib.assert_true (upload_info.error_count == 2);
        GLib.assert_true (upload_info.transferid == 1U);

        fake_folder.sync_engine ().journal ().wipe_error_blocklist ();
        GLib.assert_true (!fake_folder.sync_once ());

        upload_info = fake_folder.sync_engine ().journal ().get_upload_info ("A/a0");
        GLib.assert_true (upload_info.error_count == 3);
        GLib.assert_true (upload_info.transferid == 1U);

        fake_folder.sync_engine ().journal ().wipe_error_blocklist ();
        GLib.assert_true (!fake_folder.sync_once ());

        upload_info = fake_folder.sync_engine ().journal ().get_upload_info ("A/a0");
        GLib.assert_true (upload_info.error_count == 0);
        GLib.assert_true (upload_info.transferid == 0U);
        GLib.assert_true (!upload_info.valid);
    }

}
}
