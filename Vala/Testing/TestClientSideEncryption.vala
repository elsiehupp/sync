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
        var encryptionKey = QByteArrayLiteral ("foo");
        var privateKey = QByteArrayLiteral ("bar");
        var originalSalt = QByteArrayLiteral ("baz");

        // WHEN
        var cipher = EncryptionHelper.encryptPrivateKey (encryptionKey, privateKey, originalSalt);

        // THEN
        var parts = cipher.split ('|');
        GLib.assert_cmp (parts.size (), 3);

        var encryptedKey = GLib.ByteArray.fromBase64 (parts[0]);
        var iv = GLib.ByteArray.fromBase64 (parts[1]);
        var salt = GLib.ByteArray.fromBase64 (parts[2]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        GLib.assert_true (!encryptedKey.is_empty ());
        GLib.assert_true (encryptedKey != privateKey);

        GLib.assert_true (!iv.is_empty ());
        GLib.assert_cmp (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldDecryptPrivateKeys () {
        // GIVEN
        var encryptionKey = QByteArrayLiteral ("foo");
        var originalPrivateKey = QByteArrayLiteral ("bar");
        var originalSalt = QByteArrayLiteral ("baz");
        var cipher = EncryptionHelper.encryptPrivateKey (encryptionKey, originalPrivateKey, originalSalt);

        // WHEN
        var privateKey = EncryptionHelper.decryptPrivateKey (encryptionKey, cipher);
        var salt = EncryptionHelper.extractPrivateKeySalt (cipher);

        // THEN
        GLib.assert_cmp (privateKey, originalPrivateKey);
        GLib.assert_cmp (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldDecryptPrivateKeysInOldStorageFormat () {
        // GIVEN
        var encryptionKey = QByteArrayLiteral ("foo");
        var originalPrivateKey = QByteArrayLiteral ("bar");
        var originalSalt = QByteArrayLiteral ("baz");
        var cipher = convertToOldStorageFormat (EncryptionHelper.encryptPrivateKey (encryptionKey, originalPrivateKey, originalSalt));

        // WHEN
        var privateKey = EncryptionHelper.decryptPrivateKey (encryptionKey, cipher);
        var salt = EncryptionHelper.extractPrivateKeySalt (cipher);

        // THEN
        GLib.assert_cmp (privateKey, originalPrivateKey);
        GLib.assert_cmp (salt, originalSalt);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricEncryptStrings () {
        // GIVEN
        var encryptionKey = QByteArrayLiteral ("foo");
        var data = QByteArrayLiteral ("bar");

        // WHEN
        var cipher = EncryptionHelper.encryptStringSymmetric (encryptionKey, data);

        // THEN
        var parts = cipher.split ('|');
        GLib.assert_cmp (parts.size (), 2);

        var encryptedData = GLib.ByteArray.fromBase64 (parts[0]);
        var iv = GLib.ByteArray.fromBase64 (parts[1]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        GLib.assert_true (!encryptedData.is_empty ());
        GLib.assert_true (encryptedData != data);

        GLib.assert_true (!iv.is_empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricDecryptStrings () {
        // GIVEN
        var encryptionKey = QByteArrayLiteral ("foo");
        var originalData = QByteArrayLiteral ("bar");
        var cipher = EncryptionHelper.encryptStringSymmetric (encryptionKey, originalData);

        // WHEN
        var data = EncryptionHelper.decryptStringSymmetric (encryptionKey, cipher);

        // THEN
        GLib.assert_cmp (data, originalData);
    }


    /***********************************************************
    ***********************************************************/
    private void shouldSymmetricDecryptStringsInOldStorageFormat () {
        // GIVEN
        var encryptionKey = QByteArrayLiteral ("foo");
        var originalData = QByteArrayLiteral ("bar");
        var cipher = convertToOldStorageFormat (EncryptionHelper.encryptStringSymmetric (encryptionKey, originalData));

        // WHEN
        var data = EncryptionHelper.decryptStringSymmetric (encryptionKey, cipher);

        // THEN
        GLib.assert_cmp (data, originalData);
    }


    /***********************************************************
    ***********************************************************/
    private void testStreamingDecryptor_data () {
        QTest.add_column<int> ("totalBytes");
        QTest.add_column<int> ("bytesToRead");

        QTest.new_row ("data1") << 64  << 2;
        QTest.new_row ("data2") << 32  << 8;
        QTest.new_row ("data3") << 76  << 64;
        QTest.new_row ("data4") << 272 << 256;
    }


    /***********************************************************
    ***********************************************************/
    private void testStreamingDecryptor () {
        QFETCH (int, totalBytes);

        QTemporaryFile dummyInputFile;

        GLib.assert_true (dummyInputFile.open ());

        var dummyFileRandomContents = EncryptionHelper.generateRandom (totalBytes);

        GLib.assert_cmp (dummyInputFile.write (dummyFileRandomContents), dummyFileRandomContents.size ());

        var generateHash = [] (GLib.ByteArray data) => {
            QCryptographicHash hash (QCryptographicHash.Sha1);
            hash.addData (data);
            return hash.result ();
        }

        const GLib.ByteArray originalFileHash = generateHash (dummyFileRandomContents);

        GLib.assert_true (!originalFileHash.is_empty ());

        dummyInputFile.close ();
        GLib.assert_true (!dummyInputFile.isOpen ());

        var encryptionKey = EncryptionHelper.generateRandom (16);
        var initializationVector = EncryptionHelper.generateRandom (16);

        // test normal file encryption/decryption
        QTemporaryFile dummyEncryptionOutputFile;

        GLib.ByteArray tag;

        GLib.assert_true (EncryptionHelper.fileEncryption (encryptionKey, initializationVector, dummyInputFile, dummyEncryptionOutputFile, tag));
        dummyInputFile.close ();
        GLib.assert_true (!dummyInputFile.isOpen ());

        dummyEncryptionOutputFile.close ();
        GLib.assert_true (!dummyEncryptionOutputFile.isOpen ());

        QTemporaryFile dummyDecryptionOutputFile;

        GLib.assert_true (EncryptionHelper.fileDecryption (encryptionKey, initializationVector, dummyEncryptionOutputFile, dummyDecryptionOutputFile));
        GLib.assert_true (dummyDecryptionOutputFile.open ());
        var dummyDecryptionOutputFileHash = generateHash (dummyDecryptionOutputFile.read_all ());
        GLib.assert_cmp (dummyDecryptionOutputFileHash, originalFileHash);

        // test streaming decryptor
        EncryptionHelper.StreamingDecryptor streamingDecryptor (encryptionKey, initializationVector, dummyEncryptionOutputFile.size ());
        GLib.assert_true (streamingDecryptor.isInitialized ());

        QBuffer chunkedOutputDecrypted;
        GLib.assert_true (chunkedOutputDecrypted.open (QBuffer.WriteOnly));

        GLib.assert_true (dummyEncryptionOutputFile.open ());

        GLib.ByteArray pendingBytes;

        QFETCH (int, bytesToRead);

        while (dummyEncryptionOutputFile.position () < dummyEncryptionOutputFile.size ()) {
            var bytesRemaining = dummyEncryptionOutputFile.size () - dummyEncryptionOutputFile.position ();
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

            var decryptedChunk = streamingDecryptor.chunkDecryption (dummyEncryptionOutputFile.read (toRead).const_data (), toRead);

            GLib.assert_true (decryptedChunk.size () == toRead || streamingDecryptor.isFinished () || !pendingBytes.is_empty ());

            chunkedOutputDecrypted.write (decryptedChunk);
        }

        if (!pendingBytes.is_empty ()) {
            var decryptedChunk = streamingDecryptor.chunkDecryption (pendingBytes.const_data (), pendingBytes.size ());

            GLib.assert_true (decryptedChunk.size () == pendingBytes.size () || streamingDecryptor.isFinished ());

            chunkedOutputDecrypted.write (decryptedChunk);
        }

        chunkedOutputDecrypted.close ();

        GLib.assert_true (chunkedOutputDecrypted.open (QBuffer.ReadOnly));
        GLib.assert_cmp (generateHash (chunkedOutputDecrypted.read_all ()), originalFileHash);
        chunkedOutputDecrypted.close ();
    }
}

QTEST_APPLESS_MAIN (TestClientSideEncryption)
#include "testclientsideencryption.moc"
