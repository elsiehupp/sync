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
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};

        fakeFolder.sync_engine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"}, {"httpErrorCodesThatResetFailingChunkedUploads", QVariantList{500} } } } });

        const int size = 100 * 1000 * 1000; // 100 MB
        fakeFolder.local_modifier ().insert ("A/a0", size);
        GLib.DateTime modification_time = GLib.DateTime.currentDateTime ();
        fakeFolder.local_modifier ().set_modification_time ("A/a0", modification_time);

        // Create a transfer identifier, so we can make the final MOVE fail
        SyncJournalDb.UploadInfo uploadInfo;
        uploadInfo.transferid = 1;
        uploadInfo.valid = true;
        uploadInfo.modtime = Utility.qDateTimeToTime_t (modification_time);
        uploadInfo.size = size;
        fakeFolder.sync_engine ().journal ().setUploadInfo ("A/a0", uploadInfo);

        fakeFolder.upload_state ().mkdir ("1");
        fakeFolder.server_error_paths ().append ("1/.file");

        QVERIFY (!fakeFolder.sync_once ());

        uploadInfo = fakeFolder.sync_engine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 1);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.sync_engine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.sync_once ());

        uploadInfo = fakeFolder.sync_engine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 2);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.sync_engine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.sync_once ());

        uploadInfo = fakeFolder.sync_engine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 3);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.sync_engine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.sync_once ());

        uploadInfo = fakeFolder.sync_engine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 0);
        QCOMPARE (uploadInfo.transferid, 0U);
        QVERIFY (!uploadInfo.valid);
    }
}

QTEST_GUILESS_MAIN (TestUploadReset)
