/***********************************************************
This software is in the public domain, furnished "as is", without technical
support, and with no warranty, express or implied, as to its usefulness for
any purpose.

***********************************************************/

// #include <QtTest>
// #include <QDir>
// #include <string>

using namespace Occ;
using namespace Occ.Utility;

    class TestChecksumValidator : GLib.Object {

        private QTemporaryDir _root;
        private string _testfile;
        private string _expectedError;
        private GLib.ByteArray _expected;
        private GLib.ByteArray _expectedType;
        private bool _successDown;
        private bool _errorSeen;

    public slots:

    void slotUpValidated (GLib.ByteArray& type, GLib.ByteArray& checksum) {
         qDebug () << "Checksum : " << checksum;
         QVERIFY (_expected == checksum );
         QVERIFY (_expectedType == type );
    }

    void slotDownValidated () {
         _successDown = true;
    }

    void slotDownError (string errMsg) {
         QCOMPARE (_expectedError, errMsg);
         _errorSeen = true;
    }

    static GLib.ByteArray shellSum ( const GLib.ByteArray& cmd, string& file ) {
        QProcess md5;
        string[] args;
        args.append (file);
        md5.on_start (cmd, args);
        GLib.ByteArray sumShell;
        qDebug () << "File : "<< file;

        if ( md5.waitForFinished ()  ) {

            sumShell = md5.readAll ();
            sumShell = sumShell.left ( sumShell.indexOf (' '));
        }
        return sumShell;
    }

    private slots:

    void on_init_test_case () {
        _testfile = _root.path ()+"/csFile";
        Utility.writeRandomFile ( _testfile);
    }

    void testMd5Calc () {
        string file ( _root.path () + "/file_a.bin");
        QVERIFY (writeRandomFile (file));
        QFileInfo fi (file);
        QVERIFY (fi.exists ());

        GLib.File fileDevice (file);
        fileDevice.open (QIODevice.ReadOnly);
        GLib.ByteArray sum = calcMd5 (&fileDevice);
        fileDevice.close ();

        GLib.ByteArray sSum = shellSum ("md5sum", file);
        if (sSum.isEmpty ())
            QSKIP ("Couldn't execute md5sum to calculate checksum, executable missing?", SkipSingle);

        QVERIFY (!sum.isEmpty ());
        QCOMPARE (sSum, sum);
    }

    void testSha1Calc () {
        string file ( _root.path () + "/file_b.bin");
        writeRandomFile (file);
        QFileInfo fi (file);
        QVERIFY (fi.exists ());

        GLib.File fileDevice (file);
        fileDevice.open (QIODevice.ReadOnly);
        GLib.ByteArray sum = calcSha1 (&fileDevice);
        fileDevice.close ();

        GLib.ByteArray sSum = shellSum ("sha1sum", file);
        if (sSum.isEmpty ())
            QSKIP ("Couldn't execute sha1sum to calculate checksum, executable missing?", SkipSingle);

        QVERIFY (!sum.isEmpty ());
        QCOMPARE (sSum, sum);
    }

    void testUploadChecksummingAdler () {
#ifndef ZLIB_FOUND
        QSKIP ("ZLIB not found.", SkipSingle);
#else
        var vali = new ComputeChecksum (this);
        _expectedType = "Adler32";
        vali.setChecksumType (_expectedType);

        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = new GLib.File (_testfile, vali);
        file.open (QIODevice.ReadOnly);
        _expected = calcAdler32 (file);
        qDebug () << "XX Expected Checksum : " << _expected;
        vali.on_start (_testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), &loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
#endif
    }

    void testUploadChecksummingMd5 () {

        var vali = new ComputeChecksum (this);
        _expectedType = Occ.checkSumMD5C;
        vali.setChecksumType (_expectedType);
        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), this, SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = new GLib.File (_testfile, vali);
        file.open (QIODevice.ReadOnly);
        _expected = calcMd5 (file);
        vali.on_start (_testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), &loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    }

    void testUploadChecksummingSha1 () {

        var vali = new ComputeChecksum (this);
        _expectedType = Occ.checkSumSHA1C;
        vali.setChecksumType (_expectedType);
        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), this, SLOT (slotUpValidated (GLib.ByteArray,GLib.ByteArray)));

        var file = new GLib.File (_testfile, vali);
        file.open (QIODevice.ReadOnly);
        _expected = calcSha1 (file);

        vali.on_start (_testfile);

        QEventLoop loop;
        connect (vali, SIGNAL (on_done (GLib.ByteArray,GLib.ByteArray)), &loop, SLOT (quit ()), Qt.QueuedConnection);
        loop.exec ();

        delete vali;
    }

    void testDownloadChecksummingAdler () {
#ifndef ZLIB_FOUND
        QSKIP ("ZLIB not found.", SkipSingle);
#else
        var vali = new ValidateChecksumHeader (this);
        connect (vali, &ValidateChecksumHeader.validated, this, &TestChecksumValidator.slotDownValidated);
        connect (vali, &ValidateChecksumHeader.validationFailed, this, &TestChecksumValidator.slotDownError);

        var file = new GLib.File (_testfile, vali);
        file.open (QIODevice.ReadOnly);
        _expected = calcAdler32 (file);

        GLib.ByteArray adler = checkSumAdlerC;
        adler.append (":");
        adler.append (_expected);

        file.seek (0);
        _successDown = false;
        vali.on_start (_testfile, adler);

        QTRY_VERIFY (_successDown);

        _expectedError = QStringLiteral ("The downloaded file does not match the checksum, it will be resumed. \"543345\" != \"%1\"").arg (string.fromUtf8 (_expected));
        _errorSeen = false;
        file.seek (0);
        vali.on_start (_testfile, "Adler32:543345");
        QTRY_VERIFY (_errorSeen);

        _expectedError = QLatin1String ("The checksum header contained an unknown checksum type \"Klaas32\"");
        _errorSeen = false;
        file.seek (0);
        vali.on_start (_testfile, "Klaas32:543345");
        QTRY_VERIFY (_errorSeen);

        delete vali;
#endif
    }

    void on_cleanup_test_case () {
    }
};

    QTEST_GUILESS_MAIN (TestChecksumValidator)

#include "testchecksumvalidator.moc"
