
namespace EncryptionHelper {

GLib.ByteArray generate_random_filename () {
    return QUuid.create_uuid ().to_rfc4122 ().to_hex ();
}

GLib.ByteArray generate_random (int size) {
    GLib.ByteArray result (size, '\0');

    int ret = RAND_bytes (unsigned_data (result), size);
    if (ret != 1) {
        q_c_info (lc_cse ()) << "Random byte generation failed!";
        // Error out?
    }

    return result;
}

GLib.ByteArray generate_password (string& wordlist, GLib.ByteArray salt) {
    q_c_info (lc_cse ()) << "Start encryption key generation!";

    const int iteration_count = 1024;
    const int key_strength = 256;
    const int key_length = key_strength/8;

    GLib.ByteArray secret_key (key_length, '\0');

    int ret = PKCS5_PBKDF2_HMAC_SHA1 (
        wordlist.to_local8Bit ().const_data (),     // const char password,
        wordlist.size (),                        // int password length,
        (unsigned char *)salt.const_data (),// const unsigned char salt,
        salt.size (),                            // int saltlen,
        iteration_count,                         // int iterations,
        key_length,                              // int keylen,
        unsigned_data (secret_key)                 // unsigned char out
    );

    if (ret != 1) {
        q_c_info (lc_cse ()) << "Failed to generate encryption key";
        // Error out?
    }

    q_c_info (lc_cse ()) << "Encryption key generated!";

    return secret_key;
}

GLib.ByteArray encrypt_private_key (
        const GLib.ByteArray key,
        const GLib.ByteArray private_key,
        const GLib.ByteArray salt
        ) {

    GLib.ByteArray iv = generate_random (12);

    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Error creating cipher";
        handle_errors ();
    }

    // Initialise the decryption operation.
    if (!EVP_Encrypt_init_ex (ctx, EVP_aes_256_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Error initializing context with aes_256";
        handle_errors ();
    }

    // No padding
    EVP_CIPHER_CTX_set_padding (ctx, 0);

    // Set IV length.
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Error setting iv length";
        handle_errors ();
    }

    // Initialise key and IV
    if (!EVP_Encrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *)key.const_data (), (unsigned char *)iv.const_data ())) {
        q_c_info (lc_cse ()) << "Error initialising key and iv";
        handle_errors ();
    }

    // We write the base64 encoded private key
    GLib.ByteArray private_key_b64 = private_key.to_base64 ();

    // Make sure we have enough room in the cipher text
    GLib.ByteArray ctext (private_key_b64.size () + 32, '\0');

    // Do the actual encryption
    int len = 0;
    if (!EVP_Encrypt_update (ctx, unsigned_data (ctext), len, (unsigned char *)private_key_b64.const_data (), private_key_b64.size ())) {
        q_c_info (lc_cse ()) << "Error encrypting";
        handle_errors ();
    }

    int clen = len;


    /***********************************************************
    Finalise the encryption. Normally ciphertext bytes may be written at
    this stage, but this does not occur in GCM mode
    ***********************************************************/
    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (ctext) + len, len)) {
        q_c_info (lc_cse ()) << "Error finalizing encryption";
        handle_errors ();
    }
    clen += len;

    // Get the e2Ee_tag
    GLib.ByteArray e2Ee_tag (Occ.Constants.E2EE_TAG_SIZE, '\0');
    if (1 != EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
        q_c_info (lc_cse ()) << "Error getting the e2Ee_tag";
        handle_errors ();
    }

    GLib.ByteArray cipher_t_xT;
    cipher_t_xT.reserve (clen + Occ.Constants.E2EE_TAG_SIZE);
    cipher_t_xT.append (ctext, clen);
    cipher_t_xT.append (e2Ee_tag);

    GLib.ByteArray result = cipher_t_xT.to_base64 ();
    result += '|';
    result += iv.to_base64 ();
    result += '|';
    result += salt.to_base64 ();

    return result;
}

GLib.ByteArray decrypt_private_key (GLib.ByteArray key, GLib.ByteArray data) {
    q_c_info (lc_cse ()) << "decrypt_string_symmetric key : " << key;
    q_c_info (lc_cse ()) << "decrypt_string_symmetric data : " << data;

    const var parts = split_cipher_parts (data);
    if (parts.size () < 2) {
        q_c_info (lc_cse ()) << "Not enough parts found";
        return GLib.ByteArray ();
    }

    GLib.ByteArray cipher_t_xT64 = parts.at (0);
    GLib.ByteArray iv_b64 = parts.at (1);

    q_c_info (lc_cse ()) << "decrypt_string_symmetric cipher_t_xT : " << cipher_t_xT64;
    q_c_info (lc_cse ()) << "decrypt_string_symmetric IV : " << iv_b64;

    GLib.ByteArray cipher_t_xT = GLib.ByteArray.from_base64 (cipher_t_xT64);
    GLib.ByteArray iv = GLib.ByteArray.from_base64 (iv_b64);

    const GLib.ByteArray e2Ee_tag = cipher_t_xT.right (Occ.Constants.E2EE_TAG_SIZE);
    cipher_t_xT.chop (Occ.Constants.E2EE_TAG_SIZE);

    // Init
    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Error creating cipher";
        return GLib.ByteArray ();
    }

    // Initialise the decryption operation.
    if (!EVP_Decrypt_init_ex (ctx, EVP_aes_256_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Error initialising context with aes 256";
        return GLib.ByteArray ();
    }

    // Set IV length. Not necessary if this is 12 bytes (96 bits)
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Error setting IV size";
        return GLib.ByteArray ();
    }

    // Initialise key and IV
    if (!EVP_Decrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *)key.const_data (), (unsigned char *)iv.const_data ())) {
        q_c_info (lc_cse ()) << "Error initialising key and iv";
        return GLib.ByteArray ();
    }

    GLib.ByteArray ptext (cipher_t_xT.size () + Occ.Constants.E2EE_TAG_SIZE, '\0');
    int plen = 0;


    /***********************************************************
    Provide the message to be decrypted, and obtain the plaintext output.
    EVP_Decrypt_update can be called multiple times if necessary
    ***********************************************************/
    if (!EVP_Decrypt_update (ctx, unsigned_data (ptext), plen, (unsigned char *)cipher_t_xT.const_data (), cipher_t_xT.size ())) {
        q_c_info (lc_cse ()) << "Could not decrypt";
        return GLib.ByteArray ();
    }

    // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (unsigned char *)e2Ee_tag.const_data ())) {
        q_c_info (lc_cse ()) << "Could not set e2Ee_tag";
        return GLib.ByteArray ();
    }


    /***********************************************************
    Finalise the decryption. A positive return value indicates on_success,
    anything else is a failure - the plaintext is not trustworthy.
    ***********************************************************/
    int len = plen;
    if (EVP_Decrypt_final_ex (ctx, unsigned_data (ptext) + plen, len) == 0) {
        q_c_info (lc_cse ()) << "Tag did not match!";
        return GLib.ByteArray ();
    }

    GLib.ByteArray result (ptext, plen);
    return GLib.ByteArray.from_base64 (result);
}

GLib.ByteArray extract_private_key_salt (GLib.ByteArray data) {
    const var parts = split_cipher_parts (data);
    if (parts.size () < 3) {
        q_c_info (lc_cse ()) << "Not enough parts found";
        return GLib.ByteArray ();
    }

    return GLib.ByteArray.from_base64 (parts.at (2));
}

GLib.ByteArray decrypt_string_symmetric (GLib.ByteArray key, GLib.ByteArray data) {
    q_c_info (lc_cse ()) << "decrypt_string_symmetric key : " << key;
    q_c_info (lc_cse ()) << "decrypt_string_symmetric data : " << data;

    const var parts = split_cipher_parts (data);
    if (parts.size () < 2) {
        q_c_info (lc_cse ()) << "Not enough parts found";
        return GLib.ByteArray ();
    }

    GLib.ByteArray cipher_t_xT64 = parts.at (0);
    GLib.ByteArray iv_b64 = parts.at (1);

    q_c_info (lc_cse ()) << "decrypt_string_symmetric cipher_t_xT : " << cipher_t_xT64;
    q_c_info (lc_cse ()) << "decrypt_string_symmetric IV : " << iv_b64;

    GLib.ByteArray cipher_t_xT = GLib.ByteArray.from_base64 (cipher_t_xT64);
    GLib.ByteArray iv = GLib.ByteArray.from_base64 (iv_b64);

    const GLib.ByteArray e2Ee_tag = cipher_t_xT.right (Occ.Constants.E2EE_TAG_SIZE);
    cipher_t_xT.chop (Occ.Constants.E2EE_TAG_SIZE);

    // Init
    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Error creating cipher";
        return GLib.ByteArray ();
    }

    // Initialise the decryption operation.
    if (!EVP_Decrypt_init_ex (ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Error initialising context with aes 128";
        return GLib.ByteArray ();
    }

    // Set IV length. Not necessary if this is 12 bytes (96 bits)
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Error setting IV size";
        return GLib.ByteArray ();
    }

    // Initialise key and IV
    if (!EVP_Decrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *)key.const_data (), (unsigned char *)iv.const_data ())) {
        q_c_info (lc_cse ()) << "Error initialising key and iv";
        return GLib.ByteArray ();
    }

    GLib.ByteArray ptext (cipher_t_xT.size () + Occ.Constants.E2EE_TAG_SIZE, '\0');
    int plen = 0;


    /***********************************************************
    Provide the message to be decrypted, and obtain the plaintext output.
    EVP_Decrypt_update can be called multiple times if necessary
    ***********************************************************/
    if (!EVP_Decrypt_update (ctx, unsigned_data (ptext), plen, (unsigned char *)cipher_t_xT.const_data (), cipher_t_xT.size ())) {
        q_c_info (lc_cse ()) << "Could not decrypt";
        return GLib.ByteArray ();
    }

    // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (unsigned char *)e2Ee_tag.const_data ())) {
        q_c_info (lc_cse ()) << "Could not set e2Ee_tag";
        return GLib.ByteArray ();
    }

    /* Finalise the decryption. A positive return value indicates on_success,
    anything else is a failure - the plaintext is not trustworthy.
    ***********************************************************/
    int len = plen;
    if (EVP_Decrypt_final_ex (ctx, unsigned_data (ptext) + plen, len) == 0) {
        q_c_info (lc_cse ()) << "Tag did not match!";
        return GLib.ByteArray ();
    }

    return GLib.ByteArray.from_base64 (GLib.ByteArray (ptext, plen));
}

GLib.ByteArray private_key_to_pem (GLib.ByteArray key) {
    Bio private_key_bio;
    BIO_write (private_key_bio, key.const_data (), key.size ());
    var pkey = PKey.read_private_key (private_key_bio);

    Bio pem_bio;
    PEM_write_bio_PKCS8Private_key (pem_bio, pkey, nullptr, nullptr, 0, nullptr, nullptr);
    GLib.ByteArray pem = BIO2Byte_array (pem_bio);

    return pem;
}

GLib.ByteArray encrypt_string_symmetric (GLib.ByteArray key, GLib.ByteArray data) {
    GLib.ByteArray iv = generate_random (16);

    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Error creating cipher";
        handle_errors ();
        return {};
    }

    // Initialise the decryption operation.
    if (!EVP_Encrypt_init_ex (ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Error initializing context with aes_128";
        handle_errors ();
        return {};
    }

    // No padding
    EVP_CIPHER_CTX_set_padding (ctx, 0);

    // Set IV length.
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Error setting iv length";
        handle_errors ();
        return {};
    }

    // Initialise key and IV
    if (!EVP_Encrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *)key.const_data (), (unsigned char *)iv.const_data ())) {
        q_c_info (lc_cse ()) << "Error initialising key and iv";
        handle_errors ();
        return {};
    }

    // We write the data base64 encoded
    GLib.ByteArray data_b64 = data.to_base64 ();

    // Make sure we have enough room in the cipher text
    GLib.ByteArray ctext (data_b64.size () + 16, '\0');

    // Do the actual encryption
    int len = 0;
    if (!EVP_Encrypt_update (ctx, unsigned_data (ctext), len, (unsigned char *)data_b64.const_data (), data_b64.size ())) {
        q_c_info (lc_cse ()) << "Error encrypting";
        handle_errors ();
        return {};
    }

    int clen = len;


    /***********************************************************
    Finalise the encryption. Normally ciphertext bytes may be written at
    this stage, but this does not occur in GCM mode
    ***********************************************************/
    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (ctext) + len, len)) {
        q_c_info (lc_cse ()) << "Error finalizing encryption";
        handle_errors ();
        return {};
    }
    clen += len;

    // Get the e2Ee_tag
    GLib.ByteArray e2Ee_tag (Occ.Constants.E2EE_TAG_SIZE, '\0');
    if (1 != EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
        q_c_info (lc_cse ()) << "Error getting the e2Ee_tag";
        handle_errors ();
        return {};
    }

    GLib.ByteArray cipher_t_xT;
    cipher_t_xT.reserve (clen + Occ.Constants.E2EE_TAG_SIZE);
    cipher_t_xT.append (ctext, clen);
    cipher_t_xT.append (e2Ee_tag);

    GLib.ByteArray result = cipher_t_xT.to_base64 ();
    result += '|';
    result += iv.to_base64 ();

    return result;
}

GLib.ByteArray decrypt_string_asymmetric (EVP_PKEY *private_key, GLib.ByteArray data) {
    int err = -1;

    q_c_info (lc_cse_decryption ()) << "Start to work the decryption.";
    var ctx = PKeyCtx.for_key (private_key, ENGINE_get_default_RSA ());
    if (!ctx) {
        q_c_info (lc_cse_decryption ()) << "Could not create the PKEY context.";
        handle_errors ();
        return {};
    }

    err = EVP_PKEY_decrypt_init (ctx);
    if (err <= 0) {
        q_c_info (lc_cse_decryption ()) << "Could not on_init the decryption of the metadata";
        handle_errors ();
        return {};
    }

    if (EVP_PKEY_CTX_set_rsa_padding (ctx, RSA_PKCS1_OAEP_PADDING) <= 0) {
        q_c_info (lc_cse_decryption ()) << "Error setting the encryption padding.";
        handle_errors ();
        return {};
    }

    if (EVP_PKEY_CTX_set_rsa_oaep_md (ctx, EVP_sha256 ()) <= 0) {
        q_c_info (lc_cse_decryption ()) << "Error setting OAEP SHA 256";
        handle_errors ();
        return {};
    }

    if (EVP_PKEY_CTX_set_rsa_mgf1_md (ctx, EVP_sha256 ()) <= 0) {
        q_c_info (lc_cse_decryption ()) << "Error setting MGF1 padding";
        handle_errors ();
        return {};
    }

    size_t outlen = 0;
    err = EVP_PKEY_decrypt (ctx, nullptr, outlen,  (unsigned char *)data.const_data (), data.size ());
    if (err <= 0) {
        q_c_info (lc_cse_decryption ()) << "Could not determine the buffer length";
        handle_errors ();
        return {};
    } else {
        q_c_info (lc_cse_decryption ()) << "Size of output is : " << outlen;
        q_c_info (lc_cse_decryption ()) << "Size of data is : " << data.size ();
    }

    GLib.ByteArray out (static_cast<int> (outlen), '\0');

    if (EVP_PKEY_decrypt (ctx, unsigned_data (out), outlen, (unsigned char *)data.const_data (), data.size ()) <= 0) {
        const var error = handle_errors ();
        q_c_critical (lc_cse_decryption ()) << "Could not decrypt the data." << error;
        return {};
    } else {
        q_c_info (lc_cse_decryption ()) << "data decrypted successfully";
    }

    q_c_info (lc_cse ()) << out;
    return out;
}

GLib.ByteArray encrypt_string_asymmetric (EVP_PKEY *public_key, GLib.ByteArray data) {
    int err = -1;

    var ctx = PKeyCtx.for_key (public_key, ENGINE_get_default_RSA ());
    if (!ctx) {
        q_c_info (lc_cse ()) << "Could not initialize the pkey context.";
        exit (1);
    }

    if (EVP_PKEY_encrypt_init (ctx) != 1) {
        q_c_info (lc_cse ()) << "Error initilaizing the encryption.";
        exit (1);
    }

    if (EVP_PKEY_CTX_set_rsa_padding (ctx, RSA_PKCS1_OAEP_PADDING) <= 0) {
        q_c_info (lc_cse ()) << "Error setting the encryption padding.";
        exit (1);
    }

    if (EVP_PKEY_CTX_set_rsa_oaep_md (ctx, EVP_sha256 ()) <= 0) {
        q_c_info (lc_cse ()) << "Error setting OAEP SHA 256";
        exit (1);
    }

    if (EVP_PKEY_CTX_set_rsa_mgf1_md (ctx, EVP_sha256 ()) <= 0) {
        q_c_info (lc_cse ()) << "Error setting MGF1 padding";
        exit (1);
    }

    size_t out_len = 0;
    if (EVP_PKEY_encrypt (ctx, nullptr, out_len, (unsigned char *)data.const_data (), data.size ()) != 1) {
        q_c_info (lc_cse ()) << "Error retrieving the size of the encrypted data";
        exit (1);
    } else {
        q_c_info (lc_cse ()) << "Encryption Length:" << out_len;
    }

    GLib.ByteArray out (static_cast<int> (out_len), '\0');
    if (EVP_PKEY_encrypt (ctx, unsigned_data (out), out_len, (unsigned char *)data.const_data (), data.size ()) != 1) {
        q_c_info (lc_cse ()) << "Could not encrypt key." << err;
        exit (1);
    }

    // Transform the encrypted data into base64.
    q_c_info (lc_cse ()) << out.to_base64 ();
    return out.to_base64 ();
}

}




bool EncryptionHelper.file_encryption (GLib.ByteArray key, GLib.ByteArray iv, GLib.File input, GLib.File output, GLib.ByteArray return_tag) {
    if (!input.open (QIODevice.ReadOnly)) {
      GLib.debug (lc_cse) << "Could not open input file for reading" << input.error_string ();
    }
    if (!output.open (QIODevice.WriteOnly)) {
      GLib.debug (lc_cse) << "Could not oppen output file for writing" << output.error_string ();
    }

    // Init
    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Could not create context";
        return false;
    }

    // Initialise the decryption operation.
    if (!EVP_Encrypt_init_ex (ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Could not on_init cipher";
        return false;
    }

    EVP_CIPHER_CTX_set_padding (ctx, 0);

    // Set IV length.
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Could not set iv length";
        return false;
    }

    // Initialise key and IV
    if (!EVP_Encrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *)key.const_data (), (unsigned char *)iv.const_data ())) {
        q_c_info (lc_cse ()) << "Could not set key and iv";
        return false;
    }

    GLib.ByteArray out (block_size + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');
    int len = 0;
    int total_len = 0;

    GLib.debug (lc_cse) << "Starting to encrypt the file" << input.filename () << input.at_end ();
    while (!input.at_end ()) {
        const var data = input.read (block_size);

        if (data.size () == 0) {
            q_c_info (lc_cse ()) << "Could not read data from file";
            return false;
        }

        if (!EVP_Encrypt_update (ctx, unsigned_data (out), len, (unsigned char *)data.const_data (), data.size ())) {
            q_c_info (lc_cse ()) << "Could not encrypt";
            return false;
        }

        output.write (out, len);
        total_len += len;
    }

    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (out), len)) {
        q_c_info (lc_cse ()) << "Could on_finalize encryption";
        return false;
    }
    output.write (out, len);
    total_len += len;

    // Get the e2Ee_tag
    GLib.ByteArray e2Ee_tag (Occ.Constants.E2EE_TAG_SIZE, '\0');
    if (1 != EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_GET_TAG, Occ.Constants.E2EE_TAG_SIZE, unsigned_data (e2Ee_tag))) {
        q_c_info (lc_cse ()) << "Could not get e2Ee_tag";
        return false;
    }

    return_tag = e2Ee_tag;
    output.write (e2Ee_tag, Occ.Constants.E2EE_TAG_SIZE);

    input.close ();
    output.close ();
    GLib.debug (lc_cse) << "File Encrypted Successfully";
    return true;
}

bool EncryptionHelper.file_decryption (GLib.ByteArray key, GLib.ByteArray iv,
                               GLib.File input, GLib.File output) {
    input.open (QIODevice.ReadOnly);
    output.open (QIODevice.WriteOnly);

    // Init
    CipherCtx ctx;

    // Create and initialise the context
    if (!ctx) {
        q_c_info (lc_cse ()) << "Could not create context";
        return false;
    }

    // Initialise the decryption operation.
    if (!EVP_Decrypt_init_ex (ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
        q_c_info (lc_cse ()) << "Could not on_init cipher";
        return false;
    }

    EVP_CIPHER_CTX_set_padding (ctx, 0);

    // Set IV length.
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_IVLEN,  iv.size (), nullptr)) {
        q_c_info (lc_cse ()) << "Could not set iv length";
        return false;
    }

    // Initialise key and IV
    if (!EVP_Decrypt_init_ex (ctx, nullptr, nullptr, (unsigned char *) key.const_data (), (unsigned char *) iv.const_data ())) {
        q_c_info (lc_cse ()) << "Could not set key and iv";
        return false;
    }

    int64 size = input.size () - Occ.Constants.E2EE_TAG_SIZE;

    GLib.ByteArray out (block_size + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');
    int len = 0;

    while (input.pos () < size) {

        var to_read = size - input.pos ();
        if (to_read > block_size) {
            to_read = block_size;
        }

        GLib.ByteArray data = input.read (to_read);

        if (data.size () == 0) {
            q_c_info (lc_cse ()) << "Could not read data from file";
            return false;
        }

        if (!EVP_Decrypt_update (ctx, unsigned_data (out), len, (unsigned char *)data.const_data (), data.size ())) {
            q_c_info (lc_cse ()) << "Could not decrypt";
            return false;
        }

        output.write (out, len);
    }

    const GLib.ByteArray e2Ee_tag = input.read (Occ.Constants.E2EE_TAG_SIZE);

    // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
    if (!EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (unsigned char *)e2Ee_tag.const_data ())) {
        q_c_info (lc_cse ()) << "Could not set expected e2Ee_tag";
        return false;
    }

    if (1 != EVP_Decrypt_final_ex (ctx, unsigned_data (out), len)) {
        q_c_info (lc_cse ()) << "Could on_finalize decryption";
        return false;
    }
    output.write (out, len);

    input.close ();
    output.close ();
    return true;
}

EncryptionHelper.StreamingDecryptor.StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray iv, uint64 total_size) : this.total_size (total_size) {
    if (this.ctx && !key.is_empty () && !iv.is_empty () && total_size > 0) {
        this.is_initialized = true;

        // Initialize the decryption operation.
        if (!EVP_Decrypt_init_ex (this.ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
            q_critical (lc_cse ()) << "Could not on_init cipher";
            this.is_initialized = false;
        }

        EVP_CIPHER_CTX_set_padding (this.ctx, 0);

        // Set IV length.
        if (!EVP_CIPHER_CTX_ctrl (this.ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
            q_critical (lc_cse ()) << "Could not set iv length";
            this.is_initialized = false;
        }

        // Initialize key and IV
        if (!EVP_Decrypt_init_ex (this.ctx, nullptr, nullptr, reinterpret_cast<const unsigned char> (key.const_data ()), reinterpret_cast<const unsigned char> (iv.const_data ()))) {
            q_critical (lc_cse ()) << "Could not set key and iv";
            this.is_initialized = false;
        }
    }
}

GLib.ByteArray EncryptionHelper.StreamingDecryptor.chunk_decryption (char input, uint64 chunk_size) {
    GLib.ByteArray byte_array;
    Soup.Buffer buffer (&byte_array);
    buffer.open (QIODevice.WriteOnly);

    Q_ASSERT (is_initialized ());
    if (!is_initialized ()) {
        q_critical (lc_cse ()) << "Decryption failed. Decryptor is not initialized!";
        return GLib.ByteArray ();
    }

    Q_ASSERT (buffer.is_open () && buffer.is_writable ());
    if (!buffer.is_open () || !buffer.is_writable ()) {
        q_critical (lc_cse ()) << "Decryption failed. Incorrect output device!";
        return GLib.ByteArray ();
    }

    Q_ASSERT (input);
    if (!input) {
        q_critical (lc_cse ()) << "Decryption failed. Incorrect input!";
        return GLib.ByteArray ();
    }

    Q_ASSERT (chunk_size > 0);
    if (chunk_size <= 0) {
        q_critical (lc_cse ()) << "Decryption failed. Incorrect chunk_size!";
        return GLib.ByteArray ();
    }

    if (this.decrypted_so_far == 0) {
        GLib.debug (lc_cse ()) << "Decryption started";
    }

    Q_ASSERT (this.decrypted_so_far + chunk_size <= this.total_size);
    if (this.decrypted_so_far + chunk_size > this.total_size) {
        q_critical (lc_cse ()) << "Decryption failed. Chunk is out of range!";
        return GLib.ByteArray ();
    }

    Q_ASSERT (this.decrypted_so_far + chunk_size < Occ.Constants.E2EE_TAG_SIZE || this.total_size - Occ.Constants.E2EE_TAG_SIZE >= this.decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE);
    if (this.decrypted_so_far + chunk_size > Occ.Constants.E2EE_TAG_SIZE && this.total_size - Occ.Constants.E2EE_TAG_SIZE < this.decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE) {
        q_critical (lc_cse ()) << "Decryption failed. Incorrect chunk!";
        return GLib.ByteArray ();
    }

    const bool is_last_chunk = this.decrypted_so_far + chunk_size == this.total_size;

    // last Occ.Constants.E2EE_TAG_SIZE bytes is ALWAYS a e2Ee_tag!!!
    const int64 size = is_last_chunk ? chunk_size - Occ.Constants.E2EE_TAG_SIZE : chunk_size;

    // either the size is more than 0 and an e2Ee_tag is at the end of chunk, or, chunk is the e2Ee_tag itself
    Q_ASSERT (size > 0 || chunk_size == Occ.Constants.E2EE_TAG_SIZE);
    if (size <= 0 && chunk_size != Occ.Constants.E2EE_TAG_SIZE) {
        q_critical (lc_cse ()) << "Decryption failed. Invalid input size : " << size << " !";
        return GLib.ByteArray ();
    }

    int64 bytes_written = 0;
    int64 input_pos = 0;

    GLib.ByteArray decrypted_block (block_size + Occ.Constants.E2EE_TAG_SIZE - 1, '\0');

    while (input_pos < size) {
        // read block_size or less bytes
        const GLib.ByteArray encrypted_block (input + input_pos, q_min (size - input_pos, block_size));

        if (encrypted_block.size () == 0) {
            q_critical (lc_cse ()) << "Could not read data from the input buffer.";
            return GLib.ByteArray ();
        }

        int out_len = 0;

        if (!EVP_Decrypt_update (this.ctx, unsigned_data (decrypted_block), out_len, reinterpret_cast<const unsigned char> (encrypted_block.data ()), encrypted_block.size ())) {
            q_critical (lc_cse ()) << "Could not decrypt";
            return GLib.ByteArray ();
        }

        const var written_to_output = buffer.write (decrypted_block, out_len);

        Q_ASSERT (written_to_output == out_len);
        if (written_to_output != out_len) {
            q_critical (lc_cse ()) << "Failed to write decrypted data to device.";
            return GLib.ByteArray ();
        }

        bytes_written += written_to_output;

        // advance input position for further read
        input_pos += encrypted_block.size ();

        this.decrypted_so_far += encrypted_block.size ();
    }

    if (is_last_chunk) {
        // if it's a last chunk, we'd need to read a e2Ee_tag at the end and on_finalize the decryption

        Q_ASSERT (chunk_size - input_pos == Occ.Constants.E2EE_TAG_SIZE);
        if (chunk_size - input_pos != Occ.Constants.E2EE_TAG_SIZE) {
            q_critical (lc_cse ()) << "Decryption failed. e2Ee_tag is missing!";
            return GLib.ByteArray ();
        }

        int out_len = 0;

        GLib.ByteArray e2Ee_tag = GLib.ByteArray (input + input_pos, Occ.Constants.E2EE_TAG_SIZE);

        // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        if (!EVP_CIPHER_CTX_ctrl (this.ctx, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), reinterpret_cast<unsigned char> (e2Ee_tag.data ()))) {
            q_critical (lc_cse ()) << "Could not set expected e2Ee_tag";
            return GLib.ByteArray ();
        }

        if (1 != EVP_Decrypt_final_ex (this.ctx, unsigned_data (decrypted_block), out_len)) {
            q_critical (lc_cse ()) << "Could on_finalize decryption";
            return GLib.ByteArray ();
        }

        const var written_to_output = buffer.write (decrypted_block, out_len);

        Q_ASSERT (written_to_output == out_len);
        if (written_to_output != out_len) {
            q_critical (lc_cse ()) << "Failed to write decrypted data to device.";
            return GLib.ByteArray ();
        }

        bytes_written += written_to_output;

        this.decrypted_so_far += Occ.Constants.E2EE_TAG_SIZE;

        this.is_finished = true;
    }

    if (is_finished ()) {
        GLib.debug (lc_cse ()) << "Decryption complete";
    }

    return byte_array;
}

bool EncryptionHelper.StreamingDecryptor.is_initialized () {
    return this.is_initialized;
}

bool EncryptionHelper.StreamingDecryptor.is_finished () {
    return this.is_finished;
}