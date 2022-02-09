/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <common/syncjournaldatabase.h>

using namespace Occ;

class TestUploadReset : GLib.Object {

    // Verify that the chunked transfer eventually gets reset with the new chunking
    private void on_signal_test_file_upload_ng () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};

        fakeFolder.syncEngine ().account ().setCapabilities ({ { "dav", QVariantMap{ {"chunking", "1.0"}, {"httpErrorCodesThatResetFailingChunkedUploads", QVariantList{500} } } } });

        const int size = 100 * 1000 * 1000; // 100 MB
        fakeFolder.localModifier ().insert ("A/a0", size);
        GLib.DateTime modTime = GLib.DateTime.currentDateTime ();
        fakeFolder.localModifier ().setModTime ("A/a0", modTime);

        // Create a transfer identifier, so we can make the final MOVE fail
        SyncJournalDb.UploadInfo uploadInfo;
        uploadInfo.transferid = 1;
        uploadInfo.valid = true;
        uploadInfo.modtime = Utility.qDateTimeToTime_t (modTime);
        uploadInfo.size = size;
        fakeFolder.syncEngine ().journal ().setUploadInfo ("A/a0", uploadInfo);

        fakeFolder.uploadState ().mkdir ("1");
        fakeFolder.serverErrorPaths ().append ("1/.file");

        QVERIFY (!fakeFolder.syncOnce ());

        uploadInfo = fakeFolder.syncEngine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 1);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.syncEngine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.syncOnce ());

        uploadInfo = fakeFolder.syncEngine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 2);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.syncEngine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.syncOnce ());

        uploadInfo = fakeFolder.syncEngine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 3);
        QCOMPARE (uploadInfo.transferid, 1U);

        fakeFolder.syncEngine ().journal ().wipeErrorBlocklist ();
        QVERIFY (!fakeFolder.syncOnce ());

        uploadInfo = fakeFolder.syncEngine ().journal ().getUploadInfo ("A/a0");
        QCOMPARE (uploadInfo.errorCount, 0);
        QCOMPARE (uploadInfo.transferid, 0U);
        QVERIFY (!uploadInfo.valid);
    }
}

QTEST_GUILESS_MAIN (TestUploadReset)