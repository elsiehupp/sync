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

    GLib.ByteArray convert_to_old_storage_format (GLib.ByteArray data) {
        return data.split ('|').join ("fA==");
    }


    /***********************************************************
    ***********************************************************/
    private void should_encrypt_private_keys () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var private_key = new GLib.ByteArray ("bar");
        var original_salt = new GLib.ByteArray ("baz");

        // WHEN
        var cipher = EncryptionHelper.encrypt_private_key (encryption_key, private_key, original_salt);

        // THEN
        var parts = cipher.split ('|');
        GLib.assert_cmp (parts.size (), 3);

        var encrypted_key = GLib.ByteArray.from_base64 (parts[0]);
        var iv = GLib.ByteArray.from_base64 (parts[1]);
        var salt = GLib.ByteArray.from_base64 (parts[2]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        GLib.assert_true (!encrypted_key.is_empty ());
        GLib.assert_true (encrypted_key != private_key);

        GLib.assert_true (!iv.is_empty ());
        GLib.assert_cmp (salt, original_salt);
    }


    /***********************************************************
    ***********************************************************/
    private void should_decrypt_private_keys () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var original_private_key = new GLib.ByteArray ("bar");
        var original_salt = new GLib.ByteArray ("baz");
        var cipher = EncryptionHelper.encrypt_private_key (encryption_key, original_private_key, original_salt);

        // WHEN
        var private_key = EncryptionHelper.decrypt_private_key (encryption_key, cipher);
        var salt = EncryptionHelper.extract_private_key_salt (cipher);

        // THEN
        GLib.assert_cmp (private_key, original_private_key);
        GLib.assert_cmp (salt, original_salt);
    }


    /***********************************************************
    ***********************************************************/
    private void should_decrypt_private_keys_in_old_storage_format () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var original_private_key = new GLib.ByteArray ("bar");
        var original_salt = new GLib.ByteArray ("baz");
        var cipher = convert_to_old_storage_format (EncryptionHelper.encrypt_private_key (encryption_key, original_private_key, original_salt));

        // WHEN
        var private_key = EncryptionHelper.decrypt_private_key (encryption_key, cipher);
        var salt = EncryptionHelper.extract_private_key_salt (cipher);

        // THEN
        GLib.assert_cmp (private_key, original_private_key);
        GLib.assert_cmp (salt, original_salt);
    }


    /***********************************************************
    ***********************************************************/
    private void should_symmetric_encrypt_strings () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var data = new GLib.ByteArray ("bar");

        // WHEN
        var cipher = EncryptionHelper.encrypt_string_symmetric (encryption_key, data);

        // THEN
        var parts = cipher.split ('|');
        GLib.assert_cmp (parts.size (), 2);

        var encrypted_data = GLib.ByteArray.from_base64 (parts[0]);
        var iv = GLib.ByteArray.from_base64 (parts[1]);

        // We're not here to check the merits of the encryption but at least make sure it's been
        // somewhat ciphered
        GLib.assert_true (!encrypted_data.is_empty ());
        GLib.assert_true (encrypted_data != data);

        GLib.assert_true (!iv.is_empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void should_symmetric_decrypt_strings () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var original_data = new GLib.ByteArray ("bar");
        var cipher = EncryptionHelper.encrypt_string_symmetric (encryption_key, original_data);

        // WHEN
        var data = EncryptionHelper.decrypt_string_symmetric (encryption_key, cipher);

        // THEN
        GLib.assert_cmp (data, original_data);
    }


    /***********************************************************
    ***********************************************************/
    private void should_symmetric_decrypt_strings_in_old_storage_format () {
        // GIVEN
        var encryption_key = new GLib.ByteArray ("foo");
        var original_data = new GLib.ByteArray ("bar");
        var cipher = convert_to_old_storage_format (EncryptionHelper.encrypt_string_symmetric (encryption_key, original_data));

        // WHEN
        var data = EncryptionHelper.decrypt_string_symmetric (encryption_key, cipher);

        // THEN
        GLib.assert_cmp (data, original_data);
    }


    /***********************************************************
    ***********************************************************/
    private void test_streaming_decryptor_data () {
        QTest.add_column<int> ("total_bytes");
        QTest.add_column<int> ("bytes_to_read");

        QTest.new_row ("data1") << 64  << 2;
        QTest.new_row ("data2") << 32  << 8;
        QTest.new_row ("data3") << 76  << 64;
        QTest.new_row ("data4") << 272 << 256;
    }


    /***********************************************************
    ***********************************************************/
    private void test_streaming_decryptor () {
        QFETCH (int, total_bytes);

        QTemporaryFile dummy_input_file;

        GLib.assert_true (dummy_input_file.open ());

        var dummy_file_random_contents = EncryptionHelper.generate_random (total_bytes);

        GLib.assert_cmp (dummy_input_file.write (dummy_file_random_contents), dummy_file_random_contents.size ());

        var generate_hash = [] (GLib.ByteArray data) => {
            QCryptographicHash hash = new QCryptographicHash (QCryptographicHash.Sha1);
            hash.add_data (data);
            return hash.result ();
        }

        const GLib.ByteArray original_file_hash = generate_hash (dummy_file_random_contents);

        GLib.assert_true (!original_file_hash.is_empty ());

        dummy_input_file.close ();
        GLib.assert_true (!dummy_input_file.is_open ());

        var encryption_key = EncryptionHelper.generate_random (16);
        var initialization_vector = EncryptionHelper.generate_random (16);

        // test normal file encryption/decryption
        QTemporaryFile dummy_encryption_output_file;

        GLib.ByteArray tag;

        GLib.assert_true (EncryptionHelper.file_encryption (encryption_key, initialization_vector, dummy_input_file, dummy_encryption_output_file, tag));
        dummy_input_file.close ();
        GLib.assert_true (!dummy_input_file.is_open ());

        dummy_encryption_output_file.close ();
        GLib.assert_true (!dummy_encryption_output_file.is_open ());

        QTemporaryFile dummy_decryption_output_file;

        GLib.assert_true (EncryptionHelper.file_decryption (encryption_key, initialization_vector, dummy_encryption_output_file, dummy_decryption_output_file));
        GLib.assert_true (dummy_decryption_output_file.open ());
        var dummy_decryption_output_file_hash = generate_hash (dummy_decryption_output_file.read_all ());
        GLib.assert_cmp (dummy_decryption_output_file_hash, original_file_hash);

        // test streaming decryptor
        EncryptionHelper.StreamingDecryptor streaming_decryptor (encryption_key, initialization_vector, dummy_encryption_output_file.size ());
        GLib.assert_true (streaming_decryptor.is_initialized ());

        QBuffer chunked_output_decrypted;
        GLib.assert_true (chunked_output_decrypted.open (QBuffer.WriteOnly));

        GLib.assert_true (dummy_encryption_output_file.open ());

        GLib.ByteArray pending_bytes;

        QFETCH (int, bytes_to_read);

        while (dummy_encryption_output_file.position () < dummy_encryption_output_file.size ()) {
            var bytes_remaining = dummy_encryption_output_file.size () - dummy_encryption_output_file.position ();
            var to_read = bytes_remaining > bytes_to_read ? bytes_to_read : bytes_remaining;

            if (dummy_encryption_output_file.position () + to_read > dummy_encryption_output_file.size ()) {
                to_read = dummy_encryption_output_file.size () - dummy_encryption_output_file.position ();
            }

            if (bytes_remaining - to_read != 0 && bytes_remaining - to_read < Occ.Constants.e2EeTagSize) {
                // decryption is going to fail if last chunk does not include or does not equal to Occ.Constants.e2EeTagSize bytes tag
                // since we are emulating random size of network packets, we may end up reading beyond Occ.Constants.e2EeTagSize bytes tag at the end
                // in that case, we don't want to try and decrypt less than Occ.Constants.e2EeTagSize ending bytes of tag, we will accumulate all the incoming data till the end
                // and then, we are going to decrypt the entire chunk containing Occ.Constants.e2EeTagSize bytes at the end
                pending_bytes += dummy_encryption_output_file.read (bytes_remaining);
                continue;
            }

            var decrypted_chunk = streaming_decryptor.chunk_decryption (dummy_encryption_output_file.read (to_read).const_data (), to_read);

            GLib.assert_true (decrypted_chunk.size () == to_read || streaming_decryptor.is_finished () || !pending_bytes.is_empty ());

            chunked_output_decrypted.write (decrypted_chunk);
        }

        if (!pending_bytes.is_empty ()) {
            var decrypted_chunk = streaming_decryptor.chunk_decryption (pending_bytes.const_data (), pending_bytes.size ());

            GLib.assert_true (decrypted_chunk.size () == pending_bytes.size () || streaming_decryptor.is_finished ());

            chunked_output_decrypted.write (decrypted_chunk);
        }

        chunked_output_decrypted.close ();

        GLib.assert_true (chunked_output_decrypted.open (QBuffer.ReadOnly));
        GLib.assert_cmp (generate_hash (chunked_output_decrypted.read_all ()), original_file_hash);
        chunked_output_decrypted.close ();
    }

}
}
