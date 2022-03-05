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

class TestUploadReset : GLib.Object {

    // Verify that the chunked transfer eventually gets reset with the new chunking
    private void on_signal_test_file_upload_ng () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.sync_engine ().account ().setCapabilities ({
            { "dav", new QVariantMap (
                {"chunking", "1.0"},
                {"httpErrorCodesThatResetFailingChunkedUploads", new QVariantList (500)
            })}
        });

        const int size = 100 * 1000 * 1000; // 100 MB
        fake_folder.local_modifier ().insert ("A/a0", size);
        GLib.DateTime modification_time = GLib.DateTime.currentDateTime ();
        fake_folder.local_modifier ().set_modification_time ("A/a0", modification_time);

        // Create a transfer identifier, so we can make the final MOVE fail
        SyncJournalDb.UploadInfo uploadInfo;
        uploadInfo.transferid = 1;
        uploadInfo.valid = true;
        uploadInfo.modtime = Utility.qDateTimeToTime_t (modification_time);
        uploadInfo.size = size;
        fake_folder.sync_engine ().journal ().setUploadInfo ("A/a0", uploadInfo);

        fake_folder.upload_state ().mkdir ("1");
        fake_folder.server_error_paths ().append ("1/.file");

        //  QVERIFY (!fake_folder.sync_once ());

        uploadInfo = fake_folder.sync_engine ().journal ().getUploadInfo ("A/a0");
        //  QCOMPARE (uploadInfo.errorCount, 1);
        //  QCOMPARE (uploadInfo.transferid, 1U);

        fake_folder.sync_engine ().journal ().wipeErrorBlocklist ();
        //  QVERIFY (!fake_folder.sync_once ());

        uploadInfo = fake_folder.sync_engine ().journal ().getUploadInfo ("A/a0");
        //  QCOMPARE (uploadInfo.errorCount, 2);
        //  QCOMPARE (uploadInfo.transferid, 1U);

        fake_folder.sync_engine ().journal ().wipeErrorBlocklist ();
        //  QVERIFY (!fake_folder.sync_once ());

        uploadInfo = fake_folder.sync_engine ().journal ().getUploadInfo ("A/a0");
        //  QCOMPARE (uploadInfo.errorCount, 3);
        //  QCOMPARE (uploadInfo.transferid, 1U);

        fake_folder.sync_engine ().journal ().wipeErrorBlocklist ();
        //  QVERIFY (!fake_folder.sync_once ());

        uploadInfo = fake_folder.sync_engine ().journal ().getUploadInfo ("A/a0");
        //  QCOMPARE (uploadInfo.errorCount, 0);
        //  QCOMPARE (uploadInfo.transferid, 0U);
        //  QVERIFY (!uploadInfo.valid);
    }

}
}
