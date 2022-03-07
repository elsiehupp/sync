/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>
//  #include <sqlite3.h>

using Occ;

namespace Testing {

class TestSyncJournalDB : GLib.Object {

    QTemporaryDir this.temporary_directory;


    /***********************************************************
    ***********************************************************/
    public TestSyncJournalDB ()
        : this.database ( (this.temporary_directory.path () + "/sync.db")) {
        //  QVERIFY (this.temporary_directory.isValid ());
    }


    /***********************************************************
    ***********************************************************/
    public int64 dropMsecs (GLib.DateTime time) {
        return Utility.qDateTimeToTime_t (time);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {}


    private
    private void on_signal_cleanup_test_case () {
        const string file = this.database.databaseFilePath ();
        GLib.File.remove (file);
    }


    /***********************************************************
    ***********************************************************/
    private void testFileRecord () {
        SyncJournalFileRecord record;
        //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("nonexistant"), record));
        //  QVERIFY (!record.isValid ());

        record.path = "foo";
        // Use a value that exceeds uint32 and isn't representable by the
        // signed int being cast to uint64 either (like uint64.max would be)
        record.inode = std.numeric_limits<uint32>.max () + 12ull;
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ());
        record.type = ItemTypeDirectory;
        record.etag = "789789";
        record.file_identifier = "abcd";
        record.remotePerm = RemotePermissions.fromDbValue ("RW");
        record.fileSize = 213089055;
        record.checksumHeader = "MD5:mychecksum";
        //  QVERIFY (this.database.setFileRecord (record));

        SyncJournalFileRecord storedRecord;
        //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo"), storedRecord));
        //  QVERIFY (storedRecord == record);

        // Update checksum
        record.checksumHeader = "Adler32:newchecksum";
        this.database.updateFileRecordChecksum ("foo", "newchecksum", "Adler32");
        //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo"), storedRecord));
        //  QVERIFY (storedRecord == record);

        // Update metadata
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ().addDays (1));
        // try a value that only fits uint64, not int64
        record.inode = std.numeric_limits<uint64>.max () - std.numeric_limits<uint32>.max () - 1;
        record.type = ItemTypeFile;
        record.etag = "789FFF";
        record.file_identifier = "efg";
        record.remotePerm = RemotePermissions.fromDbValue ("NV");
        record.fileSize = 289055;
        this.database.setFileRecord (record);
        //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo"), storedRecord));
        //  QVERIFY (storedRecord == record);

        //  QVERIFY (this.database.deleteFileRecord ("foo"));
        //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo"), record));
        //  QVERIFY (!record.isValid ());
    }


    /***********************************************************
    ***********************************************************/
    private void testFileRecordChecksum () { {// Try with and without a checksum
        {
            SyncJournalFileRecord record;
            record.path = "foo-checksum";
            record.remotePerm = RemotePermissions.fromDbValue (" ");
            record.checksumHeader = "MD5:mychecksum";
            record.modtime = Utility.qDateTimeToTime_t (GLib.DateTime.currentDateTimeUtc ());
            //  QVERIFY (this.database.setFileRecord (record));

            SyncJournalFileRecord storedRecord;
            //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo-checksum"), storedRecord));
            //  QVERIFY (storedRecord.path == record.path);
            //  QVERIFY (storedRecord.remotePerm == record.remotePerm);
            //  QVERIFY (storedRecord.checksumHeader == record.checksumHeader);

            // GLib.debug ()<< "OOOOO " + storedRecord.modtime.toTime_t () + record.modtime.toTime_t ();

            // Attention : compare time_t types here, as GLib.DateTime seem to maintain
            // milliseconds internally, which disappear in sqlite. Go for full seconds here.
            //  QVERIFY (storedRecord.modtime == record.modtime);
            //  QVERIFY (storedRecord == record);
        } {
            SyncJournalFileRecord record;
            record.path = "foo-nochecksum";
            record.remotePerm = RemotePermissions.fromDbValue ("RW");
            record.modtime = Utility.qDateTimeToTime_t (GLib.DateTime.currentDateTimeUtc ());

            //  QVERIFY (this.database.setFileRecord (record));

            SyncJournalFileRecord storedRecord;
            //  QVERIFY (this.database.getFileRecord (QByteArrayLiteral ("foo-nochecksum"), storedRecord));
            //  QVERIFY (storedRecord == record);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testDownloadInfo () {
        using Info = SyncJournalDb.DownloadInfo;
        Info record = this.database.getDownloadInfo ("nonexistant");
        //  QVERIFY (!record.valid);

        record.errorCount = 5;
        record.etag = "ABCDEF";
        record.valid = true;
        record.tmpfile = "/tmp/foo";
        this.database.setDownloadInfo ("foo", record);

        Info storedRecord = this.database.getDownloadInfo ("foo");
        //  QVERIFY (storedRecord == record);

        this.database.setDownloadInfo ("foo", Info ());
        Info wipedRecord = this.database.getDownloadInfo ("foo");
        //  QVERIFY (!wipedRecord.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void testUploadInfo () {
        using Info = SyncJournalDb.UploadInfo;
        Info record = this.database.getUploadInfo ("nonexistant");
        //  QVERIFY (!record.valid);

        record.errorCount = 5;
        record.chunk = 12;
        record.transferid = 812974891;
        record.size = 12894789147;
        record.modtime = dropMsecs (GLib.DateTime.currentDateTime ());
        record.valid = true;
        this.database.setUploadInfo ("foo", record);

        Info storedRecord = this.database.getUploadInfo ("foo");
        //  QVERIFY (storedRecord == record);

        this.database.setUploadInfo ("foo", Info ());
        Info wipedRecord = this.database.getUploadInfo ("foo");
        //  QVERIFY (!wipedRecord.valid);
    }


    /***********************************************************
    ***********************************************************/
    private void testNumericId () {
        SyncJournalFileRecord record;

        // Typical 8-digit padded identifier
        record.file_identifier = "00000001abcd";
        //  QCOMPARE (record.numericFileId (), GLib.ByteArray ("00000001"));

        // When the numeric identifier overflows the 8-digit boundary
        record.file_identifier = "123456789ocidblaabcd";
        //  QCOMPARE (record.numericFileId (), GLib.ByteArray ("123456789"));
    }


    /***********************************************************
    ***********************************************************/
    private void testConflictRecord () {
        ConflictRecord record;
        record.path = "abc";
        record.baseFileId = "def";
        record.baseModtime = 1234;
        record.baseEtag = "ghi";

        //  QVERIFY (!this.database.conflictRecord (record.path).isValid ());

        this.database.setConflictRecord (record);
        var newRecord = this.database.conflictRecord (record.path);
        //  QVERIFY (newRecord.isValid ());
        //  QCOMPARE (newRecord.path, record.path);
        //  QCOMPARE (newRecord.baseFileId, record.baseFileId);
        //  QCOMPARE (newRecord.baseModtime, record.baseModtime);
        //  QCOMPARE (newRecord.baseEtag, record.baseEtag);

        this.database.deleteConflictRecord (record.path);
        //  QVERIFY (!this.database.conflictRecord (record.path).isValid ());
    }


    /***********************************************************
    ***********************************************************/
    private void testAvoidReadFromDbOnNextSync () {
        var invalidEtag = GLib.ByteArray ("this.invalid_");
        var initialEtag = GLib.ByteArray ("etag");
        var makeEntry = [&] (GLib.ByteArray path, ItemType type) {
            SyncJournalFileRecord record;
            record.path = path;
            record.type = type;
            record.etag = initialEtag;
            record.remotePerm = RemotePermissions.fromDbValue ("RW");
            this.database.setFileRecord (record);
        }
        var getEtag = [&] (GLib.ByteArray path) {
            SyncJournalFileRecord record;
            this.database.getFileRecord (path, record);
            return record.etag;
        }

        makeEntry ("foodir", ItemTypeDirectory);
        makeEntry ("otherdir", ItemTypeDirectory);
        makeEntry ("foo%", ItemTypeDirectory); // wildcards don't apply
        makeEntry ("foodi_", ItemTypeDirectory); // wildcards don't apply
        makeEntry ("foodir/file", ItemTypeFile);
        makeEntry ("foodir/subdir", ItemTypeDirectory);
        makeEntry ("foodir/subdir/file", ItemTypeFile);
        makeEntry ("foodir/otherdir", ItemTypeDirectory);
        makeEntry ("fo", ItemTypeDirectory); // prefix, but does not match
        makeEntry ("foodir/sub", ItemTypeDirectory); // prefix, but does not match
        makeEntry ("foodir/subdir/subsubdir", ItemTypeDirectory);
        makeEntry ("foodir/subdir/subsubdir/file", ItemTypeFile);
        makeEntry ("foodir/subdir/otherdir", ItemTypeDirectory);

        this.database.schedulePathForRemoteDiscovery (GLib.ByteArray ("foodir/subdir"));

        // Direct effects of parent directories being set to this.invalid_
        //  QCOMPARE (getEtag ("foodir"), invalidEtag);
        //  QCOMPARE (getEtag ("foodir/subdir"), invalidEtag);
        //  QCOMPARE (getEtag ("foodir/subdir/subsubdir"), initialEtag);

        //  QCOMPARE (getEtag ("foodir/file"), initialEtag);
        //  QCOMPARE (getEtag ("foodir/subdir/file"), initialEtag);
        //  QCOMPARE (getEtag ("foodir/subdir/subsubdir/file"), initialEtag);

        //  QCOMPARE (getEtag ("fo"), initialEtag);
        //  QCOMPARE (getEtag ("foo%"), initialEtag);
        //  QCOMPARE (getEtag ("foodi_"), initialEtag);
        //  QCOMPARE (getEtag ("otherdir"), initialEtag);
        //  QCOMPARE (getEtag ("foodir/otherdir"), initialEtag);
        //  QCOMPARE (getEtag ("foodir/sub"), initialEtag);
        //  QCOMPARE (getEtag ("foodir/subdir/otherdir"), initialEtag);

        // Indirect effects : setFileRecord () calls filter etags
        initialEtag = "etag2";

        makeEntry ("foodir", ItemTypeDirectory);
        //  QCOMPARE (getEtag ("foodir"), invalidEtag);
        makeEntry ("foodir/subdir", ItemTypeDirectory);
        //  QCOMPARE (getEtag ("foodir/subdir"), invalidEtag);
        makeEntry ("foodir/subdir/subsubdir", ItemTypeDirectory);
        //  QCOMPARE (getEtag ("foodir/subdir/subsubdir"), initialEtag);
        makeEntry ("fo", ItemTypeDirectory);
        //  QCOMPARE (getEtag ("fo"), initialEtag);
        makeEntry ("foodir/sub", ItemTypeDirectory);
        //  QCOMPARE (getEtag ("foodir/sub"), initialEtag);
    }


    /***********************************************************
    ***********************************************************/
    private void testRecursiveDelete () {
        var makeEntry = [&] (GLib.ByteArray path) {
            SyncJournalFileRecord record;
            record.path = path;
            record.remotePerm = RemotePermissions.fromDbValue ("RW");
            this.database.setFileRecord (record);
        }

        QByteArrayList elements;
        elements
            + "foo"
            + "foo/file"
            + "bar"
            + "moo"
            + "moo/file"
            + "foo%bar"
            + "foo bla bar/file"
            + "fo_"
            + "fo_/file";
        for (var& elem : elements)
            makeEntry (elem);

        var checkElements = [&] () {
            bool ok = true;
            for (var& elem : elements) {
                SyncJournalFileRecord record;
                this.database.getFileRecord (elem, record);
                if (!record.isValid ()) {
                    qWarning ("Missing record : " + elem;
                    ok = false;
                }
            }
            return ok;
        }

        this.database.deleteFileRecord ("moo", true);
        elements.removeAll ("moo");
        elements.removeAll ("moo/file");
        //  QVERIFY (checkElements ());

        this.database.deleteFileRecord ("fo_", true);
        elements.removeAll ("fo_");
        elements.removeAll ("fo_/file");
        //  QVERIFY (checkElements ());

        this.database.deleteFileRecord ("foo%bar", true);
        elements.removeAll ("foo%bar");
        //  QVERIFY (checkElements ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPinState () {
        var make = [&] (GLib.ByteArray path, PinState state) {
            this.database.internalPinStates ().setForPath (path, state);
            var pinState = this.database.internalPinStates ().rawForPath (path);
            //  QVERIFY (pinState);
            //  QCOMPARE (*pinState, state);
        }
        var get = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().effectiveForPath (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }
        var getRecursive = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().effectiveForPathRecursive (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }
        var getRaw = [&] (GLib.ByteArray path) . PinState {
            var state = this.database.internalPinStates ().rawForPath (path);
            if (!state) {
                QTest.qFail ("couldn't read pin state", __FILE__, __LINE__);
                return PinState.PinState.INHERITED;
            }
            return state;
        }

        this.database.internalPinStates ().wipeForPathAndBelow ("");
        var list = this.database.internalPinStates ().rawList ();
        //  QCOMPARE (list.size (), 0);

        // Make a thrice-nested setup
        make ("", PinState.PinState.ALWAYS_LOCAL);
        make ("local", PinState.PinState.ALWAYS_LOCAL);
        make ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        make ("inherit", PinState.PinState.INHERITED);
        for (var base: {"local/", "online/", "inherit/"}) {
            make (GLib.ByteArray (base) + "inherit", PinState.PinState.INHERITED);
            make (GLib.ByteArray (base) + "local", PinState.PinState.ALWAYS_LOCAL);
            make (GLib.ByteArray (base) + "online", PinState.VfsItemAvailability.ONLINE_ONLY);

            for (var base2: {"local/", "online/", "inherit/"}) {
                make (GLib.ByteArray (base) + base2 + "inherit", PinState.PinState.INHERITED);
                make (GLib.ByteArray (base) + base2 + "local", PinState.PinState.ALWAYS_LOCAL);
                make (GLib.ByteArray (base) + base2 + "online", PinState.VfsItemAvailability.ONLINE_ONLY);
            }
        }

        list = this.database.internalPinStates ().rawList ();
        //  QCOMPARE (list.size (), 4 + 9 + 27);

        // Baseline direct checks (the fallback for unset root pinstate is PinState.ALWAYS_LOCAL)
        //  QCOMPARE (get (""), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online/local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local/online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("inherit/local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("inherit/online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("inherit/nonexistant"), PinState.PinState.ALWAYS_LOCAL);

        // Inheriting checks, level 1
        //  QCOMPARE (get ("local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);

        // Inheriting checks, level 2
        //  QCOMPARE (get ("local/inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local/local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("local/online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("online/inherit/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("online/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online/local/nonexistant"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("online/online/nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);

        // Spot check the recursive variant
        //  QCOMPARE (getRecursive (""), PinState.PinState.INHERITED);
        //  QCOMPARE (getRecursive ("local"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRecursive ("online"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRecursive ("inherit"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRecursive ("online/local"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRecursive ("online/local/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (getRecursive ("inherit/inherit/inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (getRecursive ("inherit/online/inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (getRecursive ("inherit/online/local"), PinState.PinState.ALWAYS_LOCAL);
        make ("local/local/local/local", PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (getRecursive ("local/local/local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (getRecursive ("local/local/local/local"), PinState.PinState.ALWAYS_LOCAL);

        // Check changing the root pin state
        make ("", PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("inherit"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("nonexistant"), PinState.VfsItemAvailability.ONLINE_ONLY);
        make ("", PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("online"), PinState.VfsItemAvailability.ONLINE_ONLY);
        //  QCOMPARE (get ("inherit"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (get ("nonexistant"), PinState.PinState.ALWAYS_LOCAL);

        // Wiping
        //  QCOMPARE (getRaw ("local/local"), PinState.PinState.ALWAYS_LOCAL);
        this.database.internalPinStates ().wipeForPathAndBelow ("local/local");
        //  QCOMPARE (getRaw ("local"), PinState.PinState.ALWAYS_LOCAL);
        //  QCOMPARE (getRaw ("local/local"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRaw ("local/local/local"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRaw ("local/local/online"), PinState.PinState.INHERITED);
        list = this.database.internalPinStates ().rawList ();
        //  QCOMPARE (list.size (), 4 + 9 + 27 - 4);

        // Wiping everything
        this.database.internalPinStates ().wipeForPathAndBelow ("");
        //  QCOMPARE (getRaw (""), PinState.PinState.INHERITED);
        //  QCOMPARE (getRaw ("local"), PinState.PinState.INHERITED);
        //  QCOMPARE (getRaw ("online"), PinState.PinState.INHERITED);
        list = this.database.internalPinStates ().rawList ();
        //  QCOMPARE (list.size (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private SyncJournalDb this.database;
}

QTEST_APPLESS_MAIN (TestSyncJournalDB)
