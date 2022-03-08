/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QDir>

using Occ;
using Occ.Utility;

namespace Testing {

class TestChecksumValidator : GLib.Object {

    private QTemporaryDir root;
    private string testfile;
    private string expectedError;
    private GLib.ByteArray expected;
    private GLib.ByteArray expectedType;
    private bool successDown;
    private bool errorSeen;

    /***********************************************************
    ***********************************************************/
    public void slotUpValidated (GLib.ByteArray type, GLib.ByteArray checksum) {
        GLib.debug ("Checksum: " + checksum);
        //  QVERIFY (this.expected == checksum );
        //  QVERIFY (this.expectedType == type );
    }


    /***********************************************************
    ***********************************************************/
    public void slotDownValidated () {
        this.successDown = true;
    }


    /***********************************************************
    ***********************************************************/
    public void slotDownError (string errMsg) {
        //  QCOMPARE (this.expectedError, errMsg);
        this.errorSeen = true;
    }


    /***********************************************************
    ***********************************************************/
    static GLib.ByteArray shellSum (GLib.ByteArray command, string file) {
        QProcess md5;
        string[] args;
        args.append (file);
        md5.on_signal_start (command, args);
        GLib.ByteArray sumShell;
        GLib.debug ("File : " + file);

        if (md5.waitForFinished ()) {
            sumShell = md5.readAll ();
            sumShell = sumShell.left (sumShell.indexOf (' '));
        }
        return sumShell;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        this.testfile = this.root.path () + "/csFile";
        Utility.writeRandomFile ( this.testfile);
    }

    private void testMd5Calc () {
        string file = this.root.path () + "/file_a.bin";
        //  QVERIFY (writeRandomFile (file));
        GLib.FileInfo file_info = new GLib.FileInfo (file);
        //  QVERIFY (file_info.exists ());

        GLib.File file_device = new GLib.File (file);
        file_device.open (QIODevice.ReadOnly);
        GLib.ByteArray sum = calcMd5 (&file_device);
        file_device.close ();

        GLib.ByteArray sSum = shellSum ("md5sum", file);
        if (sSum.isEmpty ()) {
            //  QSKIP ("Couldn't execute md5sum to calculate checksum, executable missing?", SkipSingle);
        }

        //  QVERIFY (!sum.isEmpty ());
        //  QCOMPARE (sSum, sum);
    }

    private void testSha1Calc () {
        string file = this.root.path () + "/file_b.bin";
        writeRandomFile (file);
        GLib.FileInfo file_info = new GLib.FileInfo (file);
        //  QVERIFY (file_info.exists ());

        GLib.File file_device = new GLib.File (file);
        file_device.open (QIODevice.ReadOnly);
        GLib.ByteArray sum = calcSha1 (&file_device);
        file_device.close ();

        GLib.ByteArray sSum = shellSum ("sha1sum", file);
        if (sSum.isEmpty ()) {
            //  QSKIP ("Couldn't execute sha1sum to calculate checksum, executable missing?", SkipSingle);
        }

        //  QVERIFY (!sum.isEmpty ());
        //  QCOMPARE (sSum, sum);
    }

    private void testUploadChecksummingAdler () {
    //  #ifndef ZLIB_FOUND
        QSKIP ("ZLIB not found.", SkipSingle);
    //  #else
        var vali = new ComputeChecksum (this);
        this.expectedType = "Adler32";
        vali.setChecksumType (this.expectedType);

        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calcAdler32 (file);
        GLib.debug ("XX Expected Checksum: " + this.expected);
        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    //  #endif
    }

    private void testUploadChecksummingMd5 () {

        var vali = new ComputeChecksum (this);
        this.expectedType = Occ.checkSumMD5C;
        vali.setChecksumType (this.expectedType);
        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), this, SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calcMd5 (file);
        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    }

    private void testUploadChecksummingSha1 () {

        var vali = new ComputeChecksum (this);
        this.expectedType = Occ.checkSumSHA1C;
        vali.setChecksumType (this.expectedType);
        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), this, SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calcSha1 (file);

        vali.on_signal_start (this.testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_signal_done (GLib.ByteArray,GLib.ByteArray)), loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    }

    private void testDownloadChecksummingAdler () {
    //  #ifndef ZLIB_FOUND
        QSKIP ("ZLIB not found.", SkipSingle);
    //  #else
        var vali = new ValidateChecksumHeader (this);
        connect (vali, &ValidateChecksumHeader.validated, this, &TestChecksumValidator.slotDownValidated);
        connect (vali, &ValidateChecksumHeader.validationFailed, this, &TestChecksumValidator.slotDownError);

        var file = GLib.File.new_for_path (this.testfile, vali);
        file.open (QIODevice.ReadOnly);
        this.expected = calcAdler32 (file);

        GLib.ByteArray adler = checkSumAdlerC;
        adler.append (":");
        adler.append (this.expected);

        file.seek (0);
        this.successDown = false;
        vali.on_signal_start (this.testfile, adler);

        QTRY_VERIFY (this.successDown);

        this.expectedError = "The downloaded file does not match the checksum, it will be resumed. \"543345\" != \"%1\"".arg (string.fromUtf8 (this.expected));
        this.errorSeen = false;
        file.seek (0);
        vali.on_signal_start (this.testfile, "Adler32:543345");
        QTRY_VERIFY (this.errorSeen);

        this.expectedError = "The checksum header contained an unknown checksum type \"Klaas32\"";
        this.errorSeen = false;
        file.seek (0);
        vali.on_signal_start (this.testfile, "Klaas32:543345");
        QTRY_VERIFY (this.errorSeen);

        delete vali;
    //  #endif
    }

    private void on_signal_cleanup_test_case () {
    }

} // class TestChecksumValidator
} // namespace Testing
