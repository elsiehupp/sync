namespace Occ {
namespace LibSync {

/***********************************************************
@class EncryptionHelper
***********************************************************/
public class EncryptionHelper : GLib.Object {

    public static string generate_random_filename () {
        return QUuid.create_uuid ().to_rfc4122 ().to_hex ();
    }


    public static string generate_random (int size) {
        string result = new string (size, '\0');

        int ret = RAND_bytes (unsigned_data (result), size);
        if (ret != 1) {
            GLib.info ("Random byte generation failed!");
            // Error output?
        }

        return result;
    }


    public static string generate_password (string wordlist, string salt) {
        GLib.info ("Start encryption key generation!");

        const int iteration_count = 1024;
        const int key_strength = 256;
        const int key_length = key_strength/8;

        string secret_key = new string (key_length, '\0');

        int ret = PKCS5_PBKDF2_HMAC_SHA1 (
            wordlist.to_local8Bit ().const_data (),     // const char password,
            wordlist.size (),                           // int password length,
            (uchar *)salt.const_data (),                // const uchar salt,
            salt.size (),                               // int saltlen,
            iteration_count,                            // int iterations,
            key_length,                                 // int keylen,
            unsigned_data (secret_key)                  // uchar output
        );

        if (ret != 1) {
            GLib.info ("Failed to generate encryption key");
            // Error output?
        }

        GLib.info ("Encryption key generated!");

        return secret_key;
    }


    public static string encrypt_private_key (
        string key,
        string private_key,
        string salt) {

        string initialization_vector = generate_random (12);

        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Error creating cipher");
            handle_errors ();
        }

        // Initialise the decryption operation.
        if (!EVP_Encrypt_init_ex (context, EVP_aes_256_gcm (), null, null, null)) {
            GLib.info ("Error initializing context with aes_256");
            handle_errors ();
        }

        // No padding
        EVP_CIPHER_CTX_padding (context, 0);

        // Set Initialization Vector length.
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting initialization vector length");
            handle_errors ();
        }

        // Initialise key and Initialization Vector
        if (!EVP_Encrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization vector");
            handle_errors ();
        }

        // We write the base64 encoded private key
        string private_key_b64 = private_key.to_base64 ();

        // Make sure we have enough room in the cipher text
        string cipher_text = new string (private_key_b64.size () + 32, '\0');

        // Do the actual encryption
        int len = 0;
        if (!EVP_Encrypt_update (context, unsigned_data (cipher_text), len, (uchar *)private_key_b64.const_data (), private_key_b64.size ())) {
            GLib.info ("Error encrypting");
            handle_errors ();
        }

        int clen = len;


        /***********************************************************
        Finalise the encryption. Normally ciphertext bytes may be written at
        this stage, but this does not occur in GCM mode
        ***********************************************************/
        if (1 != EVP_Encrypt_final_ex (context, unsigned_data (cipher_text) + len, len)) {
            GLib.info ("Error finalizing encryption,");
            handle_errors ();
        }
        clen += len;

        // Get the e2Ee_tag
        string e2Ee_tag = new string (Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Error getting the e2Ee_tag.");
            handle_errors ();
        }

        string cipher_text2;
        cipher_text2.reserve (clen + Constants.E2EE_TAG_SIZE);
        cipher_text2.append (cipher_text, clen);
        cipher_text2.append (e2Ee_tag);

        string result = cipher_text2.to_base64 ();
        result += '|';
        result += initialization_vector.to_base64 ();
        result += '|';
        result += salt.to_base64 ();

        return result;
    }


    public static string decrypt_private_key (
        string key,
        string data) {
        GLib.info ("decrypt_string_symmetric key: " + key);
        GLib.info ("decrypt_string_symmetric data: " + data);

        var parts = split_cipher_parts (data);
        if (parts.size () < 2) {
            GLib.info ("Not enough parts found.");
            return "";
        }

        string cipher_t_xT64 = parts.at (0);
        string iv_b64 = parts.at (1);

        GLib.info ("decrypt_string_symmetric cipher text: " + cipher_t_xT64);
        GLib.info ("decrypt_string_symmetric initialization vector: " + iv_b64);

        string cipher_text2 = new string.from_base64 (cipher_t_xT64);
        string initialization_vector = new string.from_base64 (iv_b64);

        const string e2Ee_tag = cipher_text2.right (Constants.E2EE_TAG_SIZE);
        cipher_text2.chop (Constants.E2EE_TAG_SIZE);

        // Init
        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Error creating cipher.");
            return "";
        }

        // Initialise the decryption operation.
        if (!EVP_Decrypt_init_ex (context, EVP_aes_256_gcm (), null, null, null)) {
            GLib.info ("Error initialising context with aes 256");
            return "";
        }

        // Set Initialization Vector length. Not necessary if this is 12 bytes (96 bits)
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting Initialization Vector size");
            return "";
        }

        // Initialise key and Initialization Vector
        if (!EVP_Decrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization_vector");
            return "";
        }

        string ptext = new string (cipher_text2.size () + Constants.E2EE_TAG_SIZE, '\0');
        int plen = 0;


        /***********************************************************
        Provide the message to be decrypted, and obtain the plaintext output.
        EVP_Decrypt_update can be called multiple times if necessary
        ***********************************************************/
        if (!EVP_Decrypt_update (context, unsigned_data (ptext), plen, (uchar *)cipher_text2.const_data (), cipher_text2.size ())) {
            GLib.info ("Could not decrypt");
            return "";
        }

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar *)e2Ee_tag.const_data ())) {
            GLib.info ("Could not set e2Ee_tag");
            return "";
        }


        /***********************************************************
        Finalise the decryption. A positive return value indicates on_signal_success,
        anything else is a failure - the plaintext is not trustworthy.
        ***********************************************************/
        int len = plen;
        if (EVP_Decrypt_final_ex (context, unsigned_data (ptext) + plen, len) == 0) {
            GLib.info ("Tag did not match!");
            return "";
        }

        string result = new string (ptext, plen);
        return string.from_base64 (result);
    }


    public static string extract_private_key_salt (string data) {
        var parts = split_cipher_parts (data);
        if (parts.size () < 3) {
            GLib.info ("Not enough parts found.");
            return "";
        }

        return string.from_base64 (parts.at (2));
    }


    public static string encrypt_string_symmetric (
        string key,
        string data) {
        string initialization_vector = generate_random (16);

        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Error creating cipher");
            handle_errors ();
            return {};
        }

        // Initialise the decryption operation.
        if (!EVP_Encrypt_init_ex (context, EVP_aes_128_gcm (), null, null, null)) {
            GLib.info ("Error initializing context with aes_128");
            handle_errors ();
            return {};
        }

        // No padding
        EVP_CIPHER_CTX_padding (context, 0);

        // Set Initialization Vector length.
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting initialization_vector length");
            handle_errors ();
            return {};
        }

        // Initialise key and Initialization Vector
        if (!EVP_Encrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization_vector");
            handle_errors ();
            return {};
        }

        // We write the data base64 encoded
        string data_b64 = data.to_base64 ();

        // Make sure we have enough room in the cipher text
        string cipher_text = new string (data_b64.size () + 16, '\0');

        // Do the actual encryption
        int len = 0;
        if (!EVP_Encrypt_update (context, unsigned_data (cipher_text), len, (uchar *)data_b64.const_data (), data_b64.size ())) {
            GLib.info ("Error encrypting");
            handle_errors ();
            return {};
        }

        int clen = len;


        /***********************************************************
        Finalise the encryption. Normally ciphertext bytes may be written at
        this stage, but this does not occur in GCM mode
        ***********************************************************/
        if (1 != EVP_Encrypt_final_ex (context, unsigned_data (cipher_text) + len, len)) {
            GLib.info ("Error finalizing encryption");
            handle_errors ();
            return {};
        }
        clen += len;

        // Get the e2Ee_tag
        string e2Ee_tag = new string (Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Error getting the e2Ee_tag");
            handle_errors ();
            return {};
        }

        string cipher_text2;
        cipher_text2.reserve (clen + Constants.E2EE_TAG_SIZE);
        cipher_text2.append (cipher_text, clen);
        cipher_text2.append (e2Ee_tag);

        string result = cipher_text2.to_base64 ();
        result += '|';
        result += initialization_vector.to_base64 ();

        return result;
    }


    public static string decrypt_string_symmetric (
        string key,
        string data) {
        GLib.info ("decrypt_string_symmetric key: " + key);
        GLib.info ("decrypt_string_symmetric data: " + data);

        var parts = split_cipher_parts (data);
        if (parts.size () < 2) {
            GLib.info ("Not enough parts found.");
            return "";
        }

        string cipher_t_xT64 = parts.at (0);
        string iv_b64 = parts.at (1);

        GLib.info ("decrypt_string_symmetric cipher_text2: " + cipher_t_xT64);
        GLib.info ("decrypt_string_symmetric Initialization Vector: " + iv_b64);

        string cipher_text2 = new string.from_base64 (cipher_t_xT64);
        string initialization_vector = new string.from_base64 (iv_b64);

        const string e2Ee_tag = cipher_text2.right (Constants.E2EE_TAG_SIZE);
        cipher_text2.chop (Constants.E2EE_TAG_SIZE);

        // Init
        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Error creating cipher.");
            return "";
        }

        // Initialise the decryption operation.
        if (!EVP_Decrypt_init_ex (context, EVP_aes_128_gcm (), null, null, null)) {
            GLib.info ("Error initialising context with aes 128");
            return "";
        }

        // Set Initialization Vector length. Not necessary if this is 12 bytes (96 bits)
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting initialization vector size");
            return "";
        }

        // Initialise key and Initialization Vector
        if (!EVP_Decrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization vector");
            return "";
        }

        string ptext = new string (cipher_text2.size () + Constants.E2EE_TAG_SIZE, '\0');
        int plen = 0;


        /***********************************************************
        Provide the message to be decrypted, and obtain the plaintext output.
        EVP_Decrypt_update can be called multiple times if necessary
        ***********************************************************/
        if (!EVP_Decrypt_update (context, unsigned_data (ptext), plen, (uchar *)cipher_text2.const_data (), cipher_text2.size ())) {
            GLib.info ("Could not decrypt.");
            return "";
        }

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar *)e2Ee_tag.const_data ())) {
            GLib.info ("Could not set e2Ee_tag.");
            return "";
        }

        /* Finalise the decryption. A positive return value indicates on_signal_success,
        anything else is a failure - the plaintext is not trustworthy.
        ***********************************************************/
        int len = plen;
        if (EVP_Decrypt_final_ex (context, unsigned_data (ptext) + plen, len) == 0) {
            GLib.info ("Tag did not match!");
            return "";
        }

        return string.from_base64 (string (ptext, plen));
    }


    public static string private_key_to_pem (string key) {
        Biometric private_key_bio;
        BIO_write (private_key_bio, key.const_data (), key.size ());
        var pkey = PrivateKey.read_private_key (private_key_bio);

        Biometric pem_bio;
        PEM_write_bio_PKCS8Private_key (pem_bio, pkey, null, null, 0, null, null);
        string pem = BIO2Byte_array (pem_bio);

        return pem;
    }


    /***********************************************************
    TODO: change those two EVP_PKEY into QSslKey.
    ***********************************************************/
    public static string encrypt_string_asymmetric (
        EVP_PKEY public_key,
        string data) {
        int err = -1;

        var context = PrivateKeyContext.for_key (public_key, ENGINE_get_default_RSA ());
        if (context == null) {
            GLib.info ("Could not initialize the pkey context.");
            exit (1);
        }

        if (EVP_PKEY_encrypt_init (context) != 1) {
            GLib.info ("Error initilaizing the encryption.");
            exit (1);
        }

        if (EVP_PKEY_CTX_rsa_padding (context, RSA_PKCS1_OAEP_PADDING) <= 0) {
            GLib.info ("Error setting the encryption padding.");
            exit (1);
        }

        if (EVP_PKEY_CTX_rsa_oaep_md (context, EVP_sha256 ()) <= 0) {
            GLib.info ("Error setting OAEP SHA 256.");
            exit (1);
        }

        if (EVP_PKEY_CTX_rsa_mgf1_md (context, EVP_sha256 ()) <= 0) {
            GLib.info ("Error setting MGF1 padding.");
            exit (1);
        }

        size_t out_len = 0;
        if (EVP_PKEY_encrypt (context, null, out_len, (uchar *)data.const_data (), data.size ()) != 1) {
            GLib.info ("Error retrieving the size of the encrypted data.");
            exit (1);
        } else {
            GLib.info ("Encryption Length: " + out_len);
        }

        string output = new string (static_cast<int> (out_len), '\0');
        if (EVP_PKEY_encrypt (context, unsigned_data (output), out_len, (uchar *)data.const_data (), data.size ()) != 1) {
            GLib.info ("Could not encrypt key. " + err);
            exit (1);
        }

        // Transform the encrypted data into base64.
        GLib.info (output.to_base64 ());
        return output.to_base64 ();
    }


    public static string decrypt_string_asymmetric (
        EVP_PKEY private_key,
        string data) {
        int err = -1;

        GLib.info ("Start to work the decryption.");
        var context = PrivateKeyContext.for_key (private_key, ENGINE_get_default_RSA ());
        if (context == null) {
            GLib.info ("Could not create the PKEY context.");
            handle_errors ();
            return {};
        }

        err = EVP_PKEY_decrypt_init (context);
        if (err <= 0) {
            GLib.info ("Could not on_signal_init the decryption of the metadata.");
            handle_errors ();
            return {};
        }

        if (EVP_PKEY_CTX_rsa_padding (context, RSA_PKCS1_OAEP_PADDING) <= 0) {
            GLib.info ("Error setting the encryption padding.");
            handle_errors ();
            return {};
        }

        if (EVP_PKEY_CTX_rsa_oaep_md (context, EVP_sha256 ()) <= 0) {
            GLib.info ("Error setting OAEP SHA 256.");
            handle_errors ();
            return {};
        }

        if (EVP_PKEY_CTX_rsa_mgf1_md (context, EVP_sha256 ()) <= 0) {
            GLib.info ("Error setting MGF1 padding.");
            handle_errors ();
            return {};
        }

        size_t outlen = 0;
        err = EVP_PKEY_decrypt (context, null, outlen,  (uchar *)data.const_data (), data.size ());
        if (err <= 0) {
            GLib.info ("Could not determine the buffer length.");
            handle_errors ();
            return {};
        } else {
            GLib.info ("Size of output is: " + outlen);
            GLib.info ("Size of data is: " + data.size ());
        }

        string output = new string (static_cast<int> (outlen), '\0');

        if (EVP_PKEY_decrypt (context, unsigned_data (output), outlen, (uchar *)data.const_data (), data.size ()) <= 0) {
            var error = handle_errors ();
            GLib.critical ("Could not decrypt the data. " + error);
            return {};
        } else {
            GLib.info ("data decrypted successfully");
        }

        GLib.info (output);
        return output;
    }


    public static bool file_encryption (
        string key, string initialization_vector,
        GLib.File input, GLib.File output, string return_tag) {
        if (!input.open (QIODevice.ReadOnly)) {
            GLib.debug ("Could not open input file for reading " + input.error_string);
        }
        if (!output.open (QIODevice.WriteOnly)) {
            GLib.debug ("Could not oppen output file for writing " + output.error_string);
        }

        // Init
        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Could not create context");
            return false;
        }

        // Initialise the decryption operation.
        if (!EVP_Encrypt_init_ex (context, EVP_aes_128_gcm (), null, null, null)) {
            GLib.info ("Could not initialize cipher");
            return false;
        }

        EVP_CIPHER_CTX_padding (context, 0);

        // Set Initialization Vector length.
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Could not set initialization_vector length");
            return false;
        }

        // Initialise key and Initialization Vector
        if (!EVP_Encrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Could not set key and initialization_vector");
            return false;
        }

        string output = new string (BLOCK_SIZE + Constants.E2EE_TAG_SIZE - 1, '\0');
        int len = 0;
        int total_len = 0;

        GLib.debug ("Starting to encrypt the file" + input.filename () + input.at_end ());
        while (!input.at_end ()) {
            var data = input.read (BLOCK_SIZE);

            if (data.size () == 0) {
                GLib.info ("Could not read data from file");
                return false;
            }

            if (!EVP_Encrypt_update (context, unsigned_data (output), len, (uchar *)data.const_data (), data.size ())) {
                GLib.info ("Could not encrypt");
                return false;
            }

            output.write (output, len);
            total_len += len;
        }

        if (1 != EVP_Encrypt_final_ex (context, unsigned_data (output), len)) {
            GLib.info ("Could on_signal_finalize encryption");
            return false;
        }
        output.write (output, len);
        total_len += len;

        // Get the e2Ee_tag
        string e2Ee_tag = new string (Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Could not get e2Ee_tag");
            return false;
        }

        return_tag = e2Ee_tag;
        output.write (e2Ee_tag, Constants.E2EE_TAG_SIZE);

        input.close ();
        output.close ();
        GLib.debug ("File Encrypted Successfully");
        return true;
    }


    public static bool file_decryption (
        string key, string initialization_vector,
        GLib.File input, GLib.File output) {
        input.open (QIODevice.ReadOnly);
        output.open (QIODevice.WriteOnly);

        // Init
        CipherContext context = new CipherContext ();

        // Create and initialise the context
        if (context == null) {
            GLib.info ("Could not create context");
            return false;
        }

        // Initialise the decryption operation.
        if (!EVP_Decrypt_init_ex (context, EVP_aes_128_gcm (), null, null, null)) {
            GLib.info ("Could not initialize cipher");
            return false;
        }

        EVP_CIPHER_CTX_padding (context, 0);

        // Set Initialization Vector length.
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN,  initialization_vector.size (), null)) {
            GLib.info ("Could not set initialization_vector length");
            return false;
        }

        // Initialise key and Initialization Vector
        if (!EVP_Decrypt_init_ex (context, null, null, (uchar *) key.const_data (), (uchar *) initialization_vector.const_data ())) {
            GLib.info ("Could not set key and initialization_vector");
            return false;
        }

        int64 size = input.size () - Constants.E2EE_TAG_SIZE;

        string output = new string (BLOCK_SIZE + Constants.E2EE_TAG_SIZE - 1, '\0');
        int len = 0;

        while (input.position () < size) {

            var to_read = size - input.position ();
            if (to_read > BLOCK_SIZE) {
                to_read = BLOCK_SIZE;
            }

            string data = input.read (to_read);

            if (data.size () == 0) {
                GLib.info ("Could not read data from file");
                return false;
            }

            if (!EVP_Decrypt_update (context, unsigned_data (output), len, (uchar *)data.const_data (), data.size ())) {
                GLib.info ("Could not decrypt");
                return false;
            }

            output.write (output, len);
        }

        const string e2Ee_tag = input.read (Constants.E2EE_TAG_SIZE);

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar *)e2Ee_tag.const_data ())) {
            GLib.info ("Could not set expected e2Ee_tag.");
            return false;
        }

        if (1 != EVP_Decrypt_final_ex (context, unsigned_data (output), len)) {
            GLib.info ("Could on_signal_finalize decryption");
            return false;
        }
        output.write (output, len);

        input.close ();
        output.close ();
        return true;
    }

} // class EncryptionHelper

} // namespace LibSync
} // namespace Occ
