/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QTemporaryFile>
//  #include <QRandomGenerator>

//  #include <common/constants.h>

using Occ;

namespace Testing {

class TestClientSideEncryption : GLib.Object {

    GLib.ByteArray convertToOldStorageFormat (GLib.ByteArray data) {
        return data.split ('|').join ("fA==");
    }


    /***********************************************************
    ***********************************************************/
    private void shouldEncryptPrivateKeys () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var privateKey = QByteArrayLiteral ("bar");
        const var originalSalt = QByteArrayLiteral ("baz");

        // WHEN
        const var cipher = EncryptionHelper.encryptPrivateKey (encryptionKey, privateKey, originalSalt);

        // THEN
        const var parts = cipher.split ('|');
        //  QCOMPARE (parts.size (), 3);

        const var encryptedKey = GLib.ByteArray.fromBase64 (parts[0]);
        const var iv = GLib.ByteArray.fromBase64 (parts[1]);
        const var salt = GLib.ByteArray.fromBase64 (parts[2]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        //  QVERIFY (!encryptedKey.isEmpty ());
        //  QVERIFY (encryptedKey != privateKey);

        //  QVERIFY (!iv.isEmpty ());
        //  QCOMPARE (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldDecryptPrivateKeys () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var originalPrivateKey = QByteArrayLiteral ("bar");
        const var originalSalt = QByteArrayLiteral ("baz");
        const var cipher = EncryptionHelper.encryptPrivateKey (encryptionKey, originalPrivateKey, originalSalt);

        // WHEN
        const var privateKey = EncryptionHelper.decryptPrivateKey (encryptionKey, cipher);
        const var salt = EncryptionHelper.extractPrivateKeySalt (cipher);

        // THEN
        //  QCOMPARE (privateKey, originalPrivateKey);
        //  QCOMPARE (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldDecryptPrivateKeysInOldStorageFormat () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var originalPrivateKey = QByteArrayLiteral ("bar");
        const var originalSalt = QByteArrayLiteral ("baz");
        const var cipher = convertToOldStorageFormat (EncryptionHelper.encryptPrivateKey (encryptionKey, originalPrivateKey, originalSalt));

        // WHEN
        const var privateKey = EncryptionHelper.decryptPrivateKey (encryptionKey, cipher);
        const var salt = EncryptionHelper.extractPrivateKeySalt (cipher);

        // THEN
        //  QCOMPARE (privateKey, originalPrivateKey);
        //  QCOMPARE (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricEncryptStrings () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var data = QByteArrayLiteral ("bar");

        // WHEN
        const var cipher = EncryptionHelper.encryptStringSymmetric (encryptionKey, data);

        // THEN
        const var parts = cipher.split ('|');
        //  QCOMPARE (parts.size (), 2);

        const var encryptedData = GLib.ByteArray.fromBase64 (parts[0]);
        const var iv = GLib.ByteArray.fromBase64 (parts[1]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        //  QVERIFY (!encryptedData.isEmpty ());
        //  QVERIFY (encryptedData != data);

        //  QVERIFY (!iv.isEmpty ());
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricDecryptStrings () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var originalData = QByteArrayLiteral ("bar");
        const var cipher = EncryptionHelper.encryptStringSymmetric (encryptionKey, originalData);

        // WHEN
        const var data = EncryptionHelper.decryptStringSymmetric (encryptionKey, cipher);

        // THEN
        //  QCOMPARE (data, originalData);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricDecryptStringsInOldStorageFormat () {
        // GIVEN
        const var encryptionKey = QByteArrayLiteral ("foo");
        const var originalData = QByteArrayLiteral ("bar");
        const var cipher = convertToOldStorageFormat (EncryptionHelper.encryptStringSymmetric (encryptionKey, originalData));

        // WHEN
        const var data = EncryptionHelper.decryptStringSymmetric (encryptionKey, cipher);

        // THEN
        //  QCOMPARE (data, originalData);
    }


    /***********************************************************
    ***********************************************************/
    private void testStreamingDecryptor_data () {
        QTest.addColumn<int> ("totalBytes");
        QTest.addColumn<int> ("bytesToRead");

        QTest.newRow ("data1") << 64  << 2;
        QTest.newRow ("data2") << 32  << 8;
        QTest.newRow ("data3") << 76  << 64;
        QTest.newRow ("data4") << 272 << 256;
    }


    /***********************************************************
    ***********************************************************/
    private void testStreamingDecryptor () {
        //  QFETCH (int, totalBytes);

        QTemporaryFile dummyInputFile;

        //  QVERIFY (dummyInputFile.open ());

        const var dummyFileRandomContents = EncryptionHelper.generateRandom (totalBytes);

        //  QCOMPARE (dummyInputFile.write (dummyFileRandomContents), dummyFileRandomContents.size ());

        const var generateHash = [] (GLib.ByteArray data) => {
            QCryptographicHash hash (QCryptographicHash.Sha1);
            hash.addData (data);
            return hash.result ();
        }

        const GLib.ByteArray originalFileHash = generateHash (dummyFileRandomContents);

        //  QVERIFY (!originalFileHash.isEmpty ());

        dummyInputFile.close ();
        //  QVERIFY (!dummyInputFile.isOpen ());

        const var encryptionKey = EncryptionHelper.generateRandom (16);
        const var initializationVector = EncryptionHelper.generateRandom (16);

        // test normal file encryption/decryption
        QTemporaryFile dummyEncryptionOutputFile;

        GLib.ByteArray tag;

        //  QVERIFY (EncryptionHelper.fileEncryption (encryptionKey, initializationVector, dummyInputFile, dummyEncryptionOutputFile, tag));
        dummyInputFile.close ();
        //  QVERIFY (!dummyInputFile.isOpen ());

        dummyEncryptionOutputFile.close ();
        //  QVERIFY (!dummyEncryptionOutputFile.isOpen ());

        QTemporaryFile dummyDecryptionOutputFile;

        //  QVERIFY (EncryptionHelper.fileDecryption (encryptionKey, initializationVector, dummyEncryptionOutputFile, dummyDecryptionOutputFile));
        //  QVERIFY (dummyDecryptionOutputFile.open ());
        const var dummyDecryptionOutputFileHash = generateHash (dummyDecryptionOutputFile.readAll ());
        //  QCOMPARE (dummyDecryptionOutputFileHash, originalFileHash);

        // test streaming decryptor
        EncryptionHelper.StreamingDecryptor streamingDecryptor (encryptionKey, initializationVector, dummyEncryptionOutputFile.size ());
        //  QVERIFY (streamingDecryptor.isInitialized ());

        QBuffer chunkedOutputDecrypted;
        //  QVERIFY (chunkedOutputDecrypted.open (QBuffer.WriteOnly));

        //  QVERIFY (dummyEncryptionOutputFile.open ());

        GLib.ByteArray pendingBytes;

        //  QFETCH (int, bytesToRead);

        while (dummyEncryptionOutputFile.position () < dummyEncryptionOutputFile.size ()) {
            const var bytesRemaining = dummyEncryptionOutputFile.size () - dummyEncryptionOutputFile.position ();
            var toRead = bytesRemaining > bytesToRead ? bytesToRead : bytesRemaining;

            if (dummyEncryptionOutputFile.position () + toRead > dummyEncryptionOutputFile.size ()) {
                toRead = dummyEncryptionOutputFile.size () - dummyEncryptionOutputFile.position ();
            }

            if (bytesRemaining - toRead != 0 && bytesRemaining - toRead < Occ.Constants.e2EeTagSize) {
                // decryption is going to fail if last chunk does not include or does not equal to Occ.Constants.e2EeTagSize bytes tag
                // since we are emulating random size of network packets, we may end up reading beyond Occ.Constants.e2EeTagSize bytes tag at the end
                // in that case, we don't want to try and decrypt less than Occ.Constants.e2EeTagSize ending bytes of tag, we will accumulate all the incoming data till the end
                // and then, we are going to decrypt the entire chunk containing Occ.Constants.e2EeTagSize bytes at the end
                pendingBytes += dummyEncryptionOutputFile.read (bytesRemaining);
                continue;
            }

            const var decryptedChunk = streamingDecryptor.chunkDecryption (dummyEncryptionOutputFile.read (toRead).constData (), toRead);

            //  QVERIFY (decryptedChunk.size () == toRead || streamingDecryptor.isFinished () || !pendingBytes.isEmpty ());

            chunkedOutputDecrypted.write (decryptedChunk);
        }

        if (!pendingBytes.isEmpty ()) {
            const var decryptedChunk = streamingDecryptor.chunkDecryption (pendingBytes.constData (), pendingBytes.size ());

            //  QVERIFY (decryptedChunk.size () == pendingBytes.size () || streamingDecryptor.isFinished ());

            chunkedOutputDecrypted.write (decryptedChunk);
        }

        chunkedOutputDecrypted.close ();

        //  QVERIFY (chunkedOutputDecrypted.open (QBuffer.ReadOnly));
        //  QCOMPARE (generateHash (chunkedOutputDecrypted.readAll ()), originalFileHash);
        chunkedOutputDecrypted.close ();
    }
}

QTEST_APPLESS_MAIN (TestClientSideEncryption)
#include "testclientsideencryption.moc"
