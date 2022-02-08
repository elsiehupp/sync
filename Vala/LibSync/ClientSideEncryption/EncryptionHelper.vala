namespace Occ {

class EncryptionHelper {

    public static GLib.ByteArray generate_random_filename () {
        return QUuid.create_uuid ().to_rfc4122 ().to_hex ();
    }


    public static GLib.ByteArray generate_random (int size) {
        GLib.ByteArray result = new GLib.ByteArray (size, '\0');

        int ret = RAND_bytes (unsigned_data (result), size);
        if (ret != 1) {
            GLib.info ("Random byte generation failed!");
            // Error output?
        }

        return result;
    }


    public static GLib.ByteArray generate_password (string wordlist, GLib.ByteArray salt);


    public static GLib.ByteArray encrypt_private_key (
            GLib.ByteArray key,
            GLib.ByteArray private_key,
            GLib.ByteArray salt
    );


    public static GLib.ByteArray decrypt_private_key (
            GLib.ByteArray key,
            GLib.ByteArray data
    );


    public static GLib.ByteArray extract_private_key_salt (GLib.ByteArray data);


    public static GLib.ByteArray encrypt_string_symmetric (
            GLib.ByteArray key,
            GLib.ByteArray data
    );


    public static GLib.ByteArray decrypt_string_symmetric (
            GLib.ByteArray key,
            GLib.ByteArray data
    );


    public static GLib.ByteArray private_key_to_pem (GLib.ByteArray key);


    //TODO: change those two EVP_PKEY into QSslKey.
    public static GLib.ByteArray encrypt_string_asymmetric (
            EVP_PKEY *public_key,
            GLib.ByteArray data
    );


    public static GLib.ByteArray decrypt_string_asymmetric (
            EVP_PKEY *private_key,
            GLib.ByteArray data
    );


    public static bool file_encryption (GLib.ByteArray key, GLib.ByteArray initialization_vector,
                      GLib.File input, GLib.File output, GLib.ByteArray return_tag);


    public static bool file_decryption (GLib.ByteArray key, GLib.ByteArray initialization_vector,
                               GLib.File input, GLib.File output);






    public static GLib.ByteArray generate_password (string wordlist, GLib.ByteArray salt) {
        GLib.info ("Start encryption key generation!");

        const int iteration_count = 1024;
        const int key_strength = 256;
        const int key_length = key_strength/8;

        GLib.ByteArray secret_key = new GLib.ByteArray (key_length, '\0');

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

    public static GLib.ByteArray encrypt_private_key (
            GLib.ByteArray key,
            GLib.ByteArray private_key,
            GLib.ByteArray salt
            ) {

        GLib.ByteArray initialization_vector = generate_random (12);

        CipherContext context;

        // Create and initialise the context
        if (!context) {
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
        GLib.ByteArray private_key_b64 = private_key.to_base64 ();

        // Make sure we have enough room in the cipher text
        GLib.ByteArray cipher_text = new GLib.ByteArray (private_key_b64.size () + 32, '\0');

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
        GLib.ByteArray e2Ee_tag = new GLib.ByteArray (Occ.Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Error getting the e2Ee_tag.");
            handle_errors ();
        }

        GLib.ByteArray cipher_text2;
        cipher_text2.reserve (clen + Occ.Constants.E2EE_TAG_SIZE);
        cipher_text2.append (cipher_text, clen);
        cipher_text2.append (e2Ee_tag);

        GLib.ByteArray result = cipher_text2.to_base64 ();
        result += '|';
        result += initialization_vector.to_base64 ();
        result += '|';
        result += salt.to_base64 ();

        return result;
    }

    public static GLib.ByteArray decrypt_private_key (GLib.ByteArray key, GLib.ByteArray data) {
        GLib.info ("decrypt_string_symmetric key: " + key);
        GLib.info ("decrypt_string_symmetric data: " + data);

        var parts = split_cipher_parts (data);
        if (parts.size () < 2) {
            GLib.info ("Not enough parts found.");
            return new GLib.ByteArray ();
        }

        GLib.ByteArray cipher_t_xT64 = parts.at (0);
        GLib.ByteArray iv_b64 = parts.at (1);

        GLib.info ("decrypt_string_symmetric cipher text: " + cipher_t_xT64);
        GLib.info ("decrypt_string_symmetric initialization vector: " + iv_b64);

        GLib.ByteArray cipher_text2 = new GLib.ByteArray.from_base64 (cipher_t_xT64);
        GLib.ByteArray initialization_vector = new GLib.ByteArray.from_base64 (iv_b64);

        const GLib.ByteArray e2Ee_tag = cipher_text2.right (Occ.Constants.E2EE_TAG_SIZE);
        cipher_text2.chop (Occ.Constants.E2EE_TAG_SIZE);

        // Init
        CipherContext context;

        // Create and initialise the context
        if (!context) {
            GLib.info ("Error creating cipher.");
            return new GLib.ByteArray ();
        }

        // Initialise the decryption operation.
        if (!EVP_Decrypt_init_ex (context, EVP_aes_256_gcm (), null, null, null)) {
            GLib.info ("Error initialising context with aes 256");
            return new GLib.ByteArray ();
        }

        // Set Initialization Vector length. Not necessary if this is 12 bytes (96 bits)
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting Initialization Vector size");
            return new GLib.ByteArray ();
        }

        // Initialise key and Initialization Vector
        if (!EVP_Decrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization_vector");
            return new GLib.ByteArray ();
        }

        GLib.ByteArray ptext = new GLib.ByteArray (cipher_text2.size () + Occ.Constants.E2EE_TAG_SIZE, '\0');
        int plen = 0;


        /***********************************************************
        Provide the message to be decrypted, and obtain the plaintext output.
        EVP_Decrypt_update can be called multiple times if necessary
        ***********************************************************/
        if (!EVP_Decrypt_update (context, unsigned_data (ptext), plen, (uchar *)cipher_text2.const_data (), cipher_text2.size ())) {
            GLib.info ("Could not decrypt");
            return new GLib.ByteArray ();
        }

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar *)e2Ee_tag.const_data ())) {
            GLib.info ("Could not set e2Ee_tag");
            return new GLib.ByteArray ();
        }


        /***********************************************************
        Finalise the decryption. A positive return value indicates on_signal_success,
        anything else is a failure - the plaintext is not trustworthy.
        ***********************************************************/
        int len = plen;
        if (EVP_Decrypt_final_ex (context, unsigned_data (ptext) + plen, len) == 0) {
            GLib.info ("Tag did not match!");
            return new GLib.ByteArray ();
        }

        GLib.ByteArray result = new GLib.ByteArray (ptext, plen);
        return GLib.ByteArray.from_base64 (result);
    }

    public static GLib.ByteArray extract_private_key_salt (GLib.ByteArray data) {
        var parts = split_cipher_parts (data);
        if (parts.size () < 3) {
            GLib.info ("Not enough parts found.");
            return new GLib.ByteArray ();
        }

        return GLib.ByteArray.from_base64 (parts.at (2));
    }

    public static GLib.ByteArray decrypt_string_symmetric (GLib.ByteArray key, GLib.ByteArray data) {
        GLib.info ("decrypt_string_symmetric key: " + key);
        GLib.info ("decrypt_string_symmetric data: " + data);

        var parts = split_cipher_parts (data);
        if (parts.size () < 2) {
            GLib.info ("Not enough parts found.");
            return new GLib.ByteArray ();
        }

        GLib.ByteArray cipher_t_xT64 = parts.at (0);
        GLib.ByteArray iv_b64 = parts.at (1);

        GLib.info ("decrypt_string_symmetric cipher_text2: " + cipher_t_xT64);
        GLib.info ("decrypt_string_symmetric Initialization Vector: " + iv_b64);

        GLib.ByteArray cipher_text2 = new GLib.ByteArray.from_base64 (cipher_t_xT64);
        GLib.ByteArray initialization_vector = new GLib.ByteArray.from_base64 (iv_b64);

        const GLib.ByteArray e2Ee_tag = cipher_text2.right (Occ.Constants.E2EE_TAG_SIZE);
        cipher_text2.chop (Occ.Constants.E2EE_TAG_SIZE);

        // Init
        CipherContext context;

        // Create and initialise the context
        if (!context) {
            GLib.info ("Error creating cipher.");
            return new GLib.ByteArray ();
        }

        // Initialise the decryption operation.
        if (!EVP_Decrypt_init_ex (context, EVP_aes_128_gcm (), null, null, null)) {
            GLib.info ("Error initialising context with aes 128");
            return new GLib.ByteArray ();
        }

        // Set Initialization Vector length. Not necessary if this is 12 bytes (96 bits)
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
            GLib.info ("Error setting initialization vector size");
            return new GLib.ByteArray ();
        }

        // Initialise key and Initialization Vector
        if (!EVP_Decrypt_init_ex (context, null, null, (uchar *)key.const_data (), (uchar *)initialization_vector.const_data ())) {
            GLib.info ("Error initialising key and initialization vector");
            return new GLib.ByteArray ();
        }

        GLib.ByteArray ptext = new GLib.ByteArray (cipher_text2.size () + Occ.Constants.E2EE_TAG_SIZE, '\0');
        int plen = 0;


        /***********************************************************
        Provide the message to be decrypted, and obtain the plaintext output.
        EVP_Decrypt_update can be called multiple times if necessary
        ***********************************************************/
        if (!EVP_Decrypt_update (context, unsigned_data (ptext), plen, (uchar *)cipher_text2.const_data (), cipher_text2.size ())) {
            GLib.info ("Could not decrypt.");
            return new GLib.ByteArray ();
        }

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar *)e2Ee_tag.const_data ())) {
            GLib.info ("Could not set e2Ee_tag.");
            return new GLib.ByteArray ();
        }

        /* Finalise the decryption. A positive return value indicates on_signal_success,
        anything else is a failure - the plaintext is not trustworthy.
        ***********************************************************/
        int len = plen;
        if (EVP_Decrypt_final_ex (context, unsigned_data (ptext) + plen, len) == 0) {
            GLib.info ("Tag did not match!");
            return new GLib.ByteArray ();
        }

        return GLib.ByteArray.from_base64 (GLib.ByteArray (ptext, plen));
    }

    public static GLib.ByteArray private_key_to_pem (GLib.ByteArray key) {
        Biometric private_key_bio;
        BIO_write (private_key_bio, key.const_data (), key.size ());
        var pkey = PrivateKey.read_private_key (private_key_bio);

        Biometric pem_bio;
        PEM_write_bio_PKCS8Private_key (pem_bio, pkey, null, null, 0, null, null);
        GLib.ByteArray pem = BIO2Byte_array (pem_bio);

        return pem;
    }

    public static GLib.ByteArray encrypt_string_symmetric (GLib.ByteArray key, GLib.ByteArray data) {
        GLib.ByteArray initialization_vector = generate_random (16);

        CipherContext context;

        // Create and initialise the context
        if (!context) {
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
        GLib.ByteArray data_b64 = data.to_base64 ();

        // Make sure we have enough room in the cipher text
        GLib.ByteArray cipher_text = new GLib.ByteArray (data_b64.size () + 16, '\0');

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
        GLib.ByteArray e2Ee_tag = new GLib.ByteArray (Occ.Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Error getting the e2Ee_tag");
            handle_errors ();
            return {};
        }

        GLib.ByteArray cipher_text2;
        cipher_text2.reserve (clen + Occ.Constants.E2EE_TAG_SIZE);
        cipher_text2.append (cipher_text, clen);
        cipher_text2.append (e2Ee_tag);

        GLib.ByteArray result = cipher_text2.to_base64 ();
        result += '|';
        result += initialization_vector.to_base64 ();

        return result;
    }

    public static GLib.ByteArray decrypt_string_asymmetric (EVP_PKEY *private_key, GLib.ByteArray data) {
        int err = -1;

        GLib.info ("Start to work the decryption.");
        var context = PrivateKeyContext.for_key (private_key, ENGINE_get_default_RSA ());
        if (!context) {
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

        GLib.ByteArray output = new GLib.ByteArray (static_cast<int> (outlen), '\0');

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

    public static GLib.ByteArray encrypt_string_asymmetric (EVP_PKEY *public_key, GLib.ByteArray data) {
        int err = -1;

        var context = PrivateKeyContext.for_key (public_key, ENGINE_get_default_RSA ());
        if (!context) {
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

        GLib.ByteArray output = new GLib.ByteArray (static_cast<int> (out_len), '\0');
        if (EVP_PKEY_encrypt (context, unsigned_data (output), out_len, (uchar *)data.const_data (), data.size ()) != 1) {
            GLib.info ("Could not encrypt key. " + err);
            exit (1);
        }

        // Transform the encrypted data into base64.
        GLib.info (output.to_base64 ());
        return output.to_base64 ();
    }

    }




    public static bool EncryptionHelper.file_encryption (GLib.ByteArray key, GLib.ByteArray initialization_vector, GLib.File input, GLib.File output, GLib.ByteArray return_tag) {
        if (!input.open (QIODevice.ReadOnly)) {
            GLib.debug ("Could not open input file for reading " + input.error_string ());
        }
        if (!output.open (QIODevice.WriteOnly)) {
            GLib.debug ("Could not oppen output file for writing " + output.error_string ());
        }

        // Init
        CipherContext context;

        // Create and initialise the context
        if (!context) {
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

        GLib.ByteArray output = new GLib.ByteArray (BLOCK_SIZE + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');
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
        GLib.ByteArray e2Ee_tag = new GLib.ByteArray (Occ.Constants.E2EE_TAG_SIZE, '\0');
        if (1 != EVP_CIPHER_CTX_ctrl (context, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
            GLib.info ("Could not get e2Ee_tag");
            return false;
        }

        return_tag = e2Ee_tag;
        output.write (e2Ee_tag, Occ.Constants.E2EE_TAG_SIZE);

        input.close ();
        output.close ();
        GLib.debug ("File Encrypted Successfully");
        return true;
    }

    public static bool EncryptionHelper.file_decryption (GLib.ByteArray key, GLib.ByteArray initialization_vector,
                                GLib.File input, GLib.File output) {
        input.open (QIODevice.ReadOnly);
        output.open (QIODevice.WriteOnly);

        // Init
        CipherContext context;

        // Create and initialise the context
        if (!context) {
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

        int64 size = input.size () - Occ.Constants.E2EE_TAG_SIZE;

        GLib.ByteArray output = new GLib.ByteArray (BLOCK_SIZE + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');
        int len = 0;

        while (input.position () < size) {

            var to_read = size - input.position ();
            if (to_read > BLOCK_SIZE) {
                to_read = BLOCK_SIZE;
            }

            GLib.ByteArray data = input.read (to_read);

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

        const GLib.ByteArray e2Ee_tag = input.read (Occ.Constants.E2EE_TAG_SIZE);

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

    EncryptionHelper.StreamingDecryptor.StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray initialization_vector, uint64 total_size) : this.total_size (total_size) {
        if (this.context && !key.is_empty () && !initialization_vector.is_empty () && total_size > 0) {
            this.is_initialized = true;

            // Initialize the decryption operation.
            if (!EVP_Decrypt_init_ex (this.context, EVP_aes_128_gcm (), null, null, null)) {
                GLib.critical ("Could not on_signal_init cipher";
                this.is_initialized = false;
            }

            EVP_CIPHER_CTX_padding (this.context, 0);

            // Set Initialization Vector length.
            if (!EVP_CIPHER_CTX_ctrl (this.context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
                GLib.critical ("Could not set initialization_vector length";
                this.is_initialized = false;
            }

            // Initialize key and Initialization Vector
            if (!EVP_Decrypt_init_ex (this.context, null, null, reinterpret_cast<const uchar> (key.const_data ()), reinterpret_cast<const uchar> (initialization_vector.const_data ()))) {
                GLib.critical ("Could not set key and initialization_vector";
                this.is_initialized = false;
            }
        }
    }

    public GLib.ByteArray EncryptionHelper.StreamingDecryptor.chunk_decryption (char input, uint64 chunk_size) {
        GLib.ByteArray byte_array;
        Soup.Buffer buffer = new Soup.Buffer (&byte_array);
        buffer.open (QIODevice.WriteOnly);

        //  Q_ASSERT (is_initialized ());
        if (!is_initialized ()) {
            GLib.critical ("Decryption failed. Decryptor is not initialized!");
            return new GLib.ByteArray ();
        }

        //  Q_ASSERT (buffer.is_open () && buffer.is_writable ());
        if (!buffer.is_open () || !buffer.is_writable ()) {
            GLib.critical ("Decryption failed. Incorrect output device!");
            return new GLib.ByteArray ();
        }

        //  Q_ASSERT (input);
        if (!input) {
            GLib.critical ("Decryption failed. Incorrect input!");
            return new GLib.ByteArray ();
        }

        //  Q_ASSERT (chunk_size > 0);
        if (chunk_size <= 0) {
            GLib.critical ("Decryption failed. Incorrect chunk_size!");
            return new GLib.ByteArray ();
        }

        if (this.decrypted_so_far == 0) {
            GLib.debug ("Decryption started");
        }

        //  Q_ASSERT (this.decrypted_so_far + chunk_size <= this.total_size);
        if (this.decrypted_so_far + chunk_size > this.total_size) {
            GLib.critical ("Decryption failed. Chunk is output of range!");
            return new GLib.ByteArray ();
        }

        //  Q_ASSERT (this.decrypted_so_far + chunk_size < Occ.Constants.E2EE_TAG_SIZE || this.total_size - Occ.Constants.E2EE_TAG_SIZE >= this.decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE);
        if (this.decrypted_so_far + chunk_size > Occ.Constants.E2EE_TAG_SIZE && this.total_size - Occ.Constants.E2EE_TAG_SIZE < this.decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE) {
            GLib.critical ("Decryption failed. Incorrect chunk!");
            return new GLib.ByteArray ();
        }

        const bool is_last_chunk = this.decrypted_so_far + chunk_size == this.total_size;

        // last Occ.Constants.E2EE_TAG_SIZE bytes is ALWAYS a e2Ee_tag!!!
        const int64 size = is_last_chunk ? chunk_size - Occ.Constants.E2EE_TAG_SIZE : chunk_size;

        // either the size is more than 0 and an e2Ee_tag is at the end of chunk, or, chunk is the e2Ee_tag itself
        //  Q_ASSERT (size > 0 || chunk_size == Occ.Constants.E2EE_TAG_SIZE);
        if (size <= 0 && chunk_size != Occ.Constants.E2EE_TAG_SIZE) {
            GLib.critical ("Decryption failed. Invalid input size: " + size + " !");
            return new GLib.ByteArray ();
        }

        int64 bytes_written = 0;
        int64 input_pos = 0;

        GLib.ByteArray decrypted_block = new GLib.ByteArray (BLOCK_SIZE + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');

        while (input_pos < size) {
            // read BLOCK_SIZE or less bytes
            GLib.ByteArray encrypted_block = new GLib.ByteArray (input + input_pos, q_min (size - input_pos, BLOCK_SIZE));

            if (encrypted_block.size () == 0) {
                GLib.critical ("Could not read data from the input buffer.");
                return new GLib.ByteArray ();
            }

            int out_len = 0;

            if (!EVP_Decrypt_update (this.context, unsigned_data (decrypted_block), out_len, (uchar) (encrypted_block.data ()), encrypted_block.size ())) {
                GLib.critical ("Could not decrypt");
                return new GLib.ByteArray ();
            }

            var written_to_output = buffer.write (decrypted_block, out_len);

            //  Q_ASSERT (written_to_output == out_len);
            if (written_to_output != out_len) {
                GLib.critical ("Failed to write decrypted data to device.");
                return new GLib.ByteArray ();
            }

            bytes_written += written_to_output;

            // advance input position for further read
            input_pos += encrypted_block.size ();

            this.decrypted_so_far += encrypted_block.size ();
        }

        if (is_last_chunk) {
            // if it's a last chunk, we'd need to read a e2Ee_tag at the end and on_signal_finalize the decryption

            //  Q_ASSERT (chunk_size - input_pos == Occ.Constants.E2EE_TAG_SIZE);
            if (chunk_size - input_pos != Occ.Constants.E2EE_TAG_SIZE) {
                GLib.critical ("Decryption failed. e2Ee_tag is missing!");
                return new GLib.ByteArray ();
            }

            int out_len = 0;

            GLib.ByteArray e2Ee_tag = new GLib.ByteArray (input + input_pos, Occ.Constants.E2EE_TAG_SIZE);

            // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
            if (!EVP_CIPHER_CTX_ctrl (this.context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), reinterpret_cast<uchar> (e2Ee_tag.data ()))) {
                GLib.critical ("Could not set expected e2Ee_tag.");
                return new GLib.ByteArray ();
            }

            if (1 != EVP_Decrypt_final_ex (this.context, unsigned_data (decrypted_block), out_len)) {
                GLib.critical ("Could finalize decryption.");
                return new GLib.ByteArray ();
            }

            var written_to_output = buffer.write (decrypted_block, out_len);

            //  Q_ASSERT (written_to_output == out_len);
            if (written_to_output != out_len) {
                GLib.critical ("Failed to write decrypted data to device.");
                return new GLib.ByteArray ();
            }

            bytes_written += written_to_output;

            this.decrypted_so_far += Occ.Constants.E2EE_TAG_SIZE;

            this.is_finished = true;
        }

        if (is_finished ()) {
            GLib.debug ("Decryption complete.");
        }

        return byte_array;
    }

    public bool EncryptionHelper.StreamingDecryptor.is_initialized () {
        return this.is_initialized;
    }

    public bool EncryptionHelper.StreamingDecryptor.is_finished () {
        return this.is_finished;
    }

} // namespace EncryptionHelper
} // namespace Occ
