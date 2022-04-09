namespace Occ {
namespace Testing {

/***********************************************************
@class
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestStreamingDecryptor : AbstractTestClientSideEncryption {

    /***********************************************************
    ***********************************************************/
    private TestStreamingDecryptor () {
        GLib.FETCH (int, total_bytes);

        GLib.TemporaryFile dummy_input_file;

        GLib.assert_true (dummy_input_file.open ());

        var dummy_file_random_contents = LibSync.EncryptionHelper.generate_random (total_bytes);

        GLib.assert_true (dummy_input_file.write (dummy_file_random_contents) == dummy_file_random_contents.size ());

        const string original_file_hash = hash_from_string (dummy_file_random_contents);

        GLib.assert_true (original_file_hash != "");

        dummy_input_file.close ();
        GLib.assert_true (!dummy_input_file.is_open);

        var encryption_key = LibSync.EncryptionHelper.generate_random (16);
        var initialization_vector = LibSync.EncryptionHelper.generate_random (16);

        // test normal file encryption/decryption
        GLib.TemporaryFile dummy_encryption_output_file;

        string tag;

        GLib.assert_true (LibSync.EncryptionHelper.file_encryption (encryption_key, initialization_vector, dummy_input_file, dummy_encryption_output_file, tag));
        dummy_input_file.close ();
        GLib.assert_true (!dummy_input_file.is_open);

        dummy_encryption_output_file.close ();
        GLib.assert_true (!dummy_encryption_output_file.is_open);

        GLib.TemporaryFile dummy_decryption_output_file;

        GLib.assert_true (LibSync.EncryptionHelper.file_decryption (encryption_key, initialization_vector, dummy_encryption_output_file, dummy_decryption_output_file));
        GLib.assert_true (dummy_decryption_output_file.open ());
        var dummy_decryption_output_file_hash = hash_from_string (dummy_decryption_output_file.read_all ());
        GLib.assert_true (dummy_decryption_output_file_hash == original_file_hash);

        // test streaming decryptor
        LibSync.EncryptionHelper.StreamingDecryptor streaming_decryptor = new LibSync.EncryptionHelper.StreamingDecryptor (encryption_key, initialization_vector, dummy_encryption_output_file.size ());
        GLib.assert_true (streaming_decryptor.is_initialized ());

        GLib.OutputStream chunked_output_decrypted;
        GLib.assert_true (chunked_output_decrypted.open (GLib.OutputStream.WriteOnly));

        GLib.assert_true (dummy_encryption_output_file.open ());

        string pending_bytes;

        GLib.FETCH (int, bytes_to_read);

        while (dummy_encryption_output_file.position () < dummy_encryption_output_file.size ()) {
            var bytes_remaining = dummy_encryption_output_file.size () - dummy_encryption_output_file.position ();
            var to_read = bytes_remaining > bytes_to_read ? bytes_to_read : bytes_remaining;

            if (dummy_encryption_output_file.position () + to_read > dummy_encryption_output_file.size ()) {
                to_read = dummy_encryption_output_file.size () - dummy_encryption_output_file.position ();
            }

            if (bytes_remaining - to_read != 0 && bytes_remaining - to_read < Constants.e2EeTagSize) {
                // decryption is going to fail if last chunk does not include or does not equal to Constants.e2EeTagSize bytes tag
                // since we are emulating random size of network packets, we may end up reading beyond Constants.e2EeTagSize bytes tag at the end
                // in that case, we don't want to try and decrypt less than Constants.e2EeTagSize ending bytes of tag, we will accumulate all the incoming data till the end
                // and then, we are going to decrypt the entire chunk containing Constants.e2EeTagSize bytes at the end
                pending_bytes += dummy_encryption_output_file.read (bytes_remaining);
                continue;
            }

            var decrypted_chunk = streaming_decryptor.chunk_decryption (dummy_encryption_output_file.read (to_read).const_data (), to_read);

            GLib.assert_true (decrypted_chunk.size () == to_read || streaming_decryptor.is_finished () || pending_bytes != "");

            chunked_output_decrypted.write (decrypted_chunk);
        }

        if (pending_bytes != "") {
            var decrypted_chunk = streaming_decryptor.chunk_decryption (pending_bytes.const_data (), pending_bytes.size ());

            GLib.assert_true (decrypted_chunk.size () == pending_bytes.size () || streaming_decryptor.is_finished ());

            chunked_output_decrypted.write (decrypted_chunk);
        }

        chunked_output_decrypted.close ();

        GLib.assert_true (chunked_output_decrypted.open (GLib.OutputStream.ReadOnly));
        GLib.assert_true (hash_from_string (chunked_output_decrypted.read_all ()) == original_file_hash);
        chunked_output_decrypted.close ();
    }

} // class TestStreamingDecryptor

} // namespace Testing
} // namespace Occ
