
// #include <openssl/rsa.h>
// #include <openssl/evp.h>
// #include <openssl/pem.h>
// #include <openssl/err.h>
// #include <openssl/engine.h>
// #include <openssl/rand.h>

// #include <map>
// #include <string>
// #include <algorithm>

// #include <cstdio>

// #include <QDebug>
// #include <QLoggingCategory>
// #include <QFileInfo>
// #include <QDir>
// #include <QJsonObject>
// #include <QXmlStreamReader>
// #include <QXmlStreamNamespaceDeclaration>
// #include <QStack>
// #include <QInputDialog>
// #include <QLineEdit>
// #include <QIODevice>
// #include <QUuid>
// #include <QScopeGuard>
// #include <QRandomGenerator>

// #include <qt5keychain/keychain.h>
// #include <common/utility.h>
// #include <common/constants.h>

QDebug operator<< (QDebug out, std.string& str) {
    out << string.from_std_string (str);
    return out;
}

using namespace QKeychain;

// #include <string>
// #include <QJsonDocument>
// #include <QSslCertificate>
// #include <QSslKey>
// #include <QFile>
// #include <QVector>
// #include <QMap>

// #include <openssl/evp.h>

namespace QKeychain {
}

namespace Occ {

string e2ee_base_url ();

namespace EncryptionHelper {
    GLib.ByteArray generate_random_filename ();
    GLib.ByteArray generate_random (int size);
    GLib.ByteArray generate_password (string wordlist, GLib.ByteArray& salt);
    GLib.ByteArray encrypt_private_key (
            const GLib.ByteArray& key,
            const GLib.ByteArray& private_key,
            const GLib.ByteArray salt
    );
    GLib.ByteArray decrypt_private_key (
            const GLib.ByteArray& key,
            const GLib.ByteArray& data
    );
    GLib.ByteArray extract_private_key_salt (GLib.ByteArray data);
    GLib.ByteArray encrypt_string_symmetric (
            const GLib.ByteArray& key,
            const GLib.ByteArray& data
    );
    GLib.ByteArray decrypt_string_symmetric (
            const GLib.ByteArray& key,
            const GLib.ByteArray& data
    );

    GLib.ByteArray private_key_to_pem (GLib.ByteArray key);

    //TODO : change those two EVP_PKEY into QSslKey.
    GLib.ByteArray encrypt_string_asymmetric (
            EVP_PKEY *public_key,
            const GLib.ByteArray& data
    );
    GLib.ByteArray decrypt_string_asymmetric (
            EVP_PKEY *private_key,
            const GLib.ByteArray& data
    );

    bool file_encryption (GLib.ByteArray key, GLib.ByteArray iv,
                      QFile input, QFile output, GLib.ByteArray& return_tag);

    bool file_decryption (GLib.ByteArray key, GLib.ByteArray iv,
                               QFile input, QFile output);

//
// Simple classes for safe (RAII) handling of OpenSSL
// data structures
//
class CipherCtx {

    public CipherCtx () : _ctx (EVP_CIPHER_CTX_new ()) {
    }

    ~CipherCtx () {
        EVP_CIPHER_CTX_free (_ctx);
    }


    public operator EVP_CIPHER_CTX* () {
        return _ctx;
    }


    //  Q_DISABLE_COPY (CipherCtx)
    private EVP_CIPHER_CTX _ctx;
};

class StreamingDecryptor {

    public StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray iv, uint64 total_size);
    ~StreamingDecryptor () = default;

    public GLib.ByteArray chunk_decryption (char input, uint64 chunk_size);

    public bool is_initialized ();


    public bool is_finished ();


    //  Q_DISABLE_COPY (StreamingDecryptor)

    private CipherCtx _ctx;
    private bool _is_initialized = false;
    private bool _is_finished = false;
    private uint64 _decrypted_so_far = 0;
    private uint64 _total_size = 0;
};
}

class ClientSideEncryption : GLib.Object {

    public ClientSideEncryption ();


    public void initialize (AccountPtr &account);


    private void generate_key_pair (AccountPtr &account);
    private void generate_c_sR (AccountPtr &account, EVP_PKEY *key_pair);
    private void encrypt_private_key (AccountPtr &account);


    public void forget_sensitive_data (AccountPtr &account);

    public bool new_mnemonic_generated ();


    public void on_request_mnemonic ();


    private void on_public_key_fetched (QKeychain.Job incoming);
    private void on_private_key_fetched (QKeychain.Job incoming);
    private void on_mnemonic_key_fetched (QKeychain.Job incoming);

signals:
    void initialization_finished ();
    void mnemonic_generated (string& mnemonic);
    void show_mnemonic (string& mnemonic);


    private void get_private_key_from_server (AccountPtr &account);
    private void get_public_key_from_server (AccountPtr &account);
    private void fetch_and_validate_public_key_from_server (AccountPtr &account);
    private void decrypt_private_key (AccountPtr &account, GLib.ByteArray key);

    private void fetch_from_key_chain (AccountPtr &account);

    private bool check_public_key_validity (AccountPtr &account);
    private bool check_server_public_key_validity (GLib.ByteArray server_public_key_string);
    private void write_private_key (AccountPtr &account);
    private void write_certificate (AccountPtr &account);
    private void write_mnemonic (AccountPtr &account);

    private bool is_initialized = false;


    // public QSslKey _private_key;
    public GLib.ByteArray _private_key;
    public QSslKey _public_key;
    public QSslCertificate _certificate;
    public string _mnemonic;
    public bool _new_mnemonic_generated = false;
};

/***********************************************************
Generates the Metadata for the folder
***********************************************************/
struct EncryptedFile {
    GLib.ByteArray encryption_key;
    GLib.ByteArray mimetype;
    GLib.ByteArray initialization_vector;
    GLib.ByteArray authentication_tag;
    string encrypted_filename;
    string original_filename;
    int file_version;
    int metadata_key;
};

class FolderMetadata {

    public FolderMetadata (AccountPtr account, GLib.ByteArray& metadata = GLib.ByteArray (), int status_code = -1);


    public GLib.ByteArray encrypted_metadata ();


    public void add_encrypted_file (EncryptedFile& f);


    public void remove_encrypted_file (EncryptedFile& f);


    public void remove_all_encrypted_files ();


    public QVector<EncryptedFile> files ();


    /***********************************************************
    Use std.string and std.vector internally on this class
    to ease the port to Nlohmann Json API
    ***********************************************************/
    private void setup_empty_metadata ();
    private void setup_existing_metadata (GLib.ByteArray& metadata);

    private GLib.ByteArray encrypt_metadata_key (GLib.ByteArray& metadata_key);
    private GLib.ByteArray decrypt_metadata_key (GLib.ByteArray& encrypted_key);

    private GLib.ByteArray encrypt_json_object (GLib.ByteArray& obj, GLib.ByteArray pass);
    private GLib.ByteArray decrypt_json_object (GLib.ByteArray& encrypted_json_blob, GLib.ByteArray& pass);

    private QVector<EncryptedFile> _files;
    private QMap<int, GLib.ByteArray> _metadata_keys;
    private AccountPtr _account;
    private QVector<QPair<string, string>> _sharing;
};




string e2ee_base_url () {
    return QStringLiteral ("ocs/v2.php/apps/end_to_end_encryption/api/v1/");
}

namespace {
    constexpr char account_property[] = "account";

    const char e2e_cert[] = "_e2e-certificate";
    const char e2e_private[] = "_e2e-private";
    const char e2e_mnemonic[] = "_e2e-mnemonic";

    constexpr int64 block_size = 1024;

    GLib.List<GLib.ByteArray> old_cipher_format_split (GLib.ByteArray cipher) {
        const var separator = QByteArrayLiteral ("f_a=="); // BASE64 encoded '|'
        var result = GLib.List<GLib.ByteArray> ();

        var data = cipher;
        var index = data.index_of (separator);
        while (index >=0) {
            result.append (data.left (index));
            data = data.mid (index + separator.size ());
            index = data.index_of (separator);
        }

        result.append (data);
        return result;
    }

    GLib.List<GLib.ByteArray> split_cipher_parts (GLib.ByteArray data) {
        const var is_old_format = !data.contains ('|');
        const var parts = is_old_format ? old_cipher_format_split (data) : data.split ('|');
        q_c_info (lc_cse ()) << "found parts:" << parts << "old format?" << is_old_format;
        return parts;
    }
} // ns

namespace {
    unsigned char* unsigned_data (GLib.ByteArray& array) {
        return (unsigned char*)array.data ();
    }

    //
    // Simple classes for safe (RAII) handling of OpenSSL
    // data structures
    //

    class CipherCtx {

        public CipherCtx ()
            : _ctx (EVP_CIPHER_CTX_new ()) {
        }

        ~CipherCtx () {
            EVP_CIPHER_CTX_free (_ctx);
        }

        public operator EVP_CIPHER_CTX* () {
            return _ctx;
        }

        //  private Q_DISABLE_COPY (CipherCtx)

        private EVP_CIPHER_CTX* _ctx;
    };

    class Bio {

        public Bio ()
            : _bio (BIO_new (BIO_s_mem ())) {
        }

        ~Bio () {
            BIO_free_all (_bio);
        }

        public operator BIO* () {
            return _bio;
        }

        //  private Q_DISABLE_COPY (Bio)

        private BIO* _bio;
    };

    class PKeyCtx {

        public PKeyCtx (int id, ENGINE *e = nullptr)
            : _ctx (EVP_PKEY_CTX_new_id (id, e)) {
        }

        ~PKeyCtx () {
            EVP_PKEY_CTX_free (_ctx);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a `for_key` static function that returns
        // an instance of this class
        public PKeyCtx (PKeyCtx&& other) {
            std.swap (_ctx, other._ctx);
        }

        public PKeyCtx& operator= (PKeyCtx&& other) = delete;

        public static PKeyCtx for_key (EVP_PKEY *pkey, ENGINE *e = nullptr) {
            PKeyCtx ctx;
            ctx._ctx = EVP_PKEY_CTX_new (pkey, e);
            return ctx;
        }

        public operator EVP_PKEY_CTX* () {
            return _ctx;
        }

        //  private Q_DISABLE_COPY (PKeyCtx)

        private PKeyCtx () = default;

        private EVP_PKEY_CTX* _ctx = nullptr;
    };

    class PKey {

        ~PKey () {
            EVP_PKEY_free (_pkey);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a static functions that return
        // an instance of this class
        public PKey (PKey&& other) {
            std.swap (_pkey, other._pkey);
        }

        public PKey& operator= (PKey&& other) = delete;

        public static PKey read_public_key (Bio &bio) {
            PKey result;
            result._pkey = PEM_read_bio_PUBKEY (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public static PKey read_private_key (Bio &bio) {
            PKey result;
            result._pkey = PEM_read_bio_Private_key (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public static PKey generate (PKeyCtx& ctx) {
            PKey result;
            if (EVP_PKEY_keygen (ctx, &result._pkey) <= 0) {
                result._pkey = nullptr;
            }
            return result;
        }

        public operator EVP_PKEY* () {
            return _pkey;
        }

        public operator EVP_PKEY* () {
            return _pkey;
        }

        //  private Q_DISABLE_COPY (PKey)

        private PKey () = default;

        private EVP_PKEY* _pkey = nullptr;
    };

    class X509Certificate {

        ~X509Certificate () {
            X509_free (_certificate);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a static functions that return
        // an instance of this class
        public X509Certificate (X509Certificate&& other) {
            std.swap (_certificate, other._certificate);
        }

        public X509Certificate& operator= (X509Certificate&& other) = delete;

        public static X509Certificate read_certificate (Bio &bio) {
            X509Certificate result;
            result._certificate = PEM_read_bio_X509 (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public operator X509* () {
            return _certificate;
        }

        public operator X509* () {
            return _certificate;
        }

        //  private Q_DISABLE_COPY (X509Certificate)

        private X509Certificate () = default;

        private X509* _certificate = nullptr;
    };

    GLib.ByteArray BIO2Byte_array (Bio &b) {
        var pending = static_cast<int> (BIO_ctrl_pending (b));
        GLib.ByteArray res (pending, '\0');
        BIO_read (b, unsigned_data (res), pending);
        return res;
    }

    GLib.ByteArray handle_errors () {
        Bio bio_errors;
        ERR_print_errors (bio_errors); // This line is not printing anything.
        return BIO2Byte_array (bio_errors);
    }
}

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

GLib.ByteArray generate_password (string& wordlist, GLib.ByteArray& salt) {
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
        const GLib.ByteArray& key,
        const GLib.ByteArray& private_key,
        const GLib.ByteArray& salt
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
    if (!EVP_Encrypt_update (ctx, unsigned_data (ctext), &len, (unsigned char *)private_key_b64.const_data (), private_key_b64.size ())) {
        q_c_info (lc_cse ()) << "Error encrypting";
        handle_errors ();
    }

    int clen = len;


    /***********************************************************
    Finalise the encryption. Normally ciphertext bytes may be written at
    this stage, but this does not occur in GCM mode
    ***********************************************************/
    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (ctext) + len, &len)) {
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

GLib.ByteArray decrypt_private_key (GLib.ByteArray& key, GLib.ByteArray& data) {
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
    if (!EVP_Decrypt_update (ctx, unsigned_data (ptext), &plen, (unsigned char *)cipher_t_xT.const_data (), cipher_t_xT.size ())) {
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
    if (EVP_Decrypt_final_ex (ctx, unsigned_data (ptext) + plen, &len) == 0) {
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

GLib.ByteArray decrypt_string_symmetric (GLib.ByteArray& key, GLib.ByteArray& data) {
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
    if (!EVP_Decrypt_update (ctx, unsigned_data (ptext), &plen, (unsigned char *)cipher_t_xT.const_data (), cipher_t_xT.size ())) {
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
    if (EVP_Decrypt_final_ex (ctx, unsigned_data (ptext) + plen, &len) == 0) {
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

GLib.ByteArray encrypt_string_symmetric (GLib.ByteArray& key, GLib.ByteArray& data) {
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
    if (!EVP_Encrypt_update (ctx, unsigned_data (ctext), &len, (unsigned char *)data_b64.const_data (), data_b64.size ())) {
        q_c_info (lc_cse ()) << "Error encrypting";
        handle_errors ();
        return {};
    }

    int clen = len;


    /***********************************************************
    Finalise the encryption. Normally ciphertext bytes may be written at
    this stage, but this does not occur in GCM mode
    ***********************************************************/
    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (ctext) + len, &len)) {
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

GLib.ByteArray decrypt_string_asymmetric (EVP_PKEY *private_key, GLib.ByteArray& data) {
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
    err = EVP_PKEY_decrypt (ctx, nullptr, &outlen,  (unsigned char *)data.const_data (), data.size ());
    if (err <= 0) {
        q_c_info (lc_cse_decryption ()) << "Could not determine the buffer length";
        handle_errors ();
        return {};
    } else {
        q_c_info (lc_cse_decryption ()) << "Size of output is : " << outlen;
        q_c_info (lc_cse_decryption ()) << "Size of data is : " << data.size ();
    }

    GLib.ByteArray out (static_cast<int> (outlen), '\0');

    if (EVP_PKEY_decrypt (ctx, unsigned_data (out), &outlen, (unsigned char *)data.const_data (), data.size ()) <= 0) {
        const var error = handle_errors ();
        q_c_critical (lc_cse_decryption ()) << "Could not decrypt the data." << error;
        return {};
    } else {
        q_c_info (lc_cse_decryption ()) << "data decrypted successfully";
    }

    q_c_info (lc_cse ()) << out;
    return out;
}

GLib.ByteArray encrypt_string_asymmetric (EVP_PKEY *public_key, GLib.ByteArray& data) {
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
    if (EVP_PKEY_encrypt (ctx, nullptr, &out_len, (unsigned char *)data.const_data (), data.size ()) != 1) {
        q_c_info (lc_cse ()) << "Error retrieving the size of the encrypted data";
        exit (1);
    } else {
        q_c_info (lc_cse ()) << "Encryption Length:" << out_len;
    }

    GLib.ByteArray out (static_cast<int> (out_len), '\0');
    if (EVP_PKEY_encrypt (ctx, unsigned_data (out), &out_len, (unsigned char *)data.const_data (), data.size ()) != 1) {
        q_c_info (lc_cse ()) << "Could not encrypt key." << err;
        exit (1);
    }

    // Transform the encrypted data into base64.
    q_c_info (lc_cse ()) << out.to_base64 ();
    return out.to_base64 ();
}

}

ClientSideEncryption.ClientSideEncryption () = default;

void ClientSideEncryption.initialize (AccountPtr &account) {
    Q_ASSERT (account);

    q_c_info (lc_cse ()) << "Initializing";
    if (!account.capabilities ().client_side_encryption_available ()) {
        q_c_info (lc_cse ()) << "No Client side encryption available on server.";
        emit initialization_finished ();
        return;
    }

    fetch_from_key_chain (account);
}

void ClientSideEncryption.fetch_from_key_chain (AccountPtr &account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_cert,
                account.id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_property (account_property, QVariant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_public_key_fetched);
    job.on_start ();
}

bool ClientSideEncryption.check_public_key_validity (AccountPtr &account) {
    GLib.ByteArray data = EncryptionHelper.generate_random (64);

    Bio public_key_bio;
    GLib.ByteArray public_key_pem = account.e2e ()._public_key.to_pem ();
    BIO_write (public_key_bio, public_key_pem.const_data (), public_key_pem.size ());
    var public_key = PKey.read_public_key (public_key_bio);

    var encrypted_data = EncryptionHelper.encrypt_string_asymmetric (public_key, data.to_base64 ());

    Bio private_key_bio;
    GLib.ByteArray private_key_pem = account.e2e ()._private_key;
    BIO_write (private_key_bio, private_key_pem.const_data (), private_key_pem.size ());
    var key = PKey.read_private_key (private_key_bio);

    GLib.ByteArray decrypt_result = GLib.ByteArray.from_base64 (EncryptionHelper.decrypt_string_asymmetric ( key, GLib.ByteArray.from_base64 (encrypted_data)));

    if (data != decrypt_result) {
        q_c_info (lc_cse ()) << "invalid private key";
        return false;
    }

    return true;
}

bool ClientSideEncryption.check_server_public_key_validity (GLib.ByteArray server_public_key_string) {
    Bio server_public_key_bio;
    BIO_write (server_public_key_bio, server_public_key_string.const_data (), server_public_key_string.size ());
    const var server_public_key = PKey.read_private_key (server_public_key_bio);

    Bio certificate_bio;
    const var certificate_pem = _certificate.to_pem ();
    BIO_write (certificate_bio, certificate_pem.const_data (), certificate_pem.size ());
    const var x509Certificate = X509Certificate.read_certificate (certificate_bio);
    if (!x509Certificate) {
        q_c_info (lc_cse ()) << "Client certificate is invalid. Could not check it against the server public key";
        return false;
    }

    if (X509_verify (x509Certificate, server_public_key) == 0) {
        q_c_info (lc_cse ()) << "Client certificate is not valid against the server public key";
        return false;
    }

    q_c_debug (lc_cse ()) << "Client certificate is valid against server public key";
    return true;
}

void ClientSideEncryption.on_public_key_fetched (Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPtr> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.binary_data ().length () == 0) {
        get_public_key_from_server (account);
        return;
    }

    _certificate = QSslCertificate (read_job.binary_data (), QSsl.Pem);

    if (_certificate.is_null ()) {
        get_public_key_from_server (account);
        return;
    }

    _public_key = _certificate.public_key ();

    q_c_info (lc_cse ()) << "Public key fetched from keychain";

    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_private,
                account.id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_property (account_property, QVariant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_private_key_fetched);
    job.on_start ();
}

void ClientSideEncryption.on_private_key_fetched (Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPtr> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.binary_data ().length () == 0) {
        _certificate = QSslCertificate ();
        _public_key = QSslKey ();
        get_public_key_from_server (account);
        return;
    }

    //_private_key = QSslKey (read_job.binary_data (), QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
    _private_key = read_job.binary_data ();

    if (_private_key.is_null ()) {
        get_private_key_from_server (account);
        return;
    }

    q_c_info (lc_cse ()) << "Private key fetched from keychain";

    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_mnemonic,
                account.id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_property (account_property, QVariant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_mnemonic_key_fetched);
    job.on_start ();
}

void ClientSideEncryption.on_mnemonic_key_fetched (QKeychain.Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPtr> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.text_data ().length () == 0) {
        _certificate = QSslCertificate ();
        _public_key = QSslKey ();
        _private_key = GLib.ByteArray ();
        get_public_key_from_server (account);
        return;
    }

    _mnemonic = read_job.text_data ();

    q_c_info (lc_cse ()) << "Mnemonic key fetched from keychain : " << _mnemonic;

    emit initialization_finished ();
}

void ClientSideEncryption.write_private_key (AccountPtr &account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_private,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (_private_key);
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Private key stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.write_certificate (AccountPtr &account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_cert,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (_certificate.to_pem ());
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Certificate stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.write_mnemonic (AccountPtr &account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_mnemonic,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_text_data (_mnemonic);
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Mnemonic stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.forget_sensitive_data (AccountPtr &account) {
    _private_key = GLib.ByteArray ();
    _certificate = QSslCertificate ();
    _public_key = QSslKey ();
    _mnemonic = string ();

    var start_delete_job = [account] (string user) {
        var job = new DeletePasswordJob (Theme.instance ().app_name ());
        job.set_insecure_fallback (false);
        job.set_key (AbstractCredentials.keychain_key (account.url ().to_string (), user, account.id ()));
        job.on_start ();
    };

    var user = account.credentials ().user ();
    start_delete_job (user + e2e_private);
    start_delete_job (user + e2e_cert);
    start_delete_job (user + e2e_mnemonic);
}

void ClientSideEncryption.on_request_mnemonic () {
    emit show_mnemonic (_mnemonic);
}

void ClientSideEncryption.generate_key_pair (AccountPtr &account) {
    // AES/GCM/No_padding,
    // metadata_keys with RSA/ECB/OAEPWith_sHA-256And_mGF1Padding
    q_c_info (lc_cse ()) << "No public key, generating a pair.";
    const int rsa_key_len = 2048;

    // Init RSA
    PKeyCtx ctx (EVP_PKEY_RSA);

    if (EVP_PKEY_keygen_init (ctx) <= 0) {
        q_c_info (lc_cse ()) << "Couldn't initialize the key generator";
        return;
    }

    if (EVP_PKEY_CTX_set_rsa_keygen_bits (ctx, rsa_key_len) <= 0) {
        q_c_info (lc_cse ()) << "Couldn't initialize the key generator bits";
        return;
    }

    var local_key_pair = PKey.generate (ctx);
    if (!local_key_pair) {
        q_c_info (lc_cse ()) << "Could not generate the key";
        return;
    }

    q_c_info (lc_cse ()) << "Key correctly generated";
    q_c_info (lc_cse ()) << "Storing keys locally";

    Bio priv_key;
    if (PEM_write_bio_Private_key (priv_key, local_key_pair, nullptr, nullptr, 0, nullptr, nullptr) <= 0) {
        q_c_info (lc_cse ()) << "Could not read private key from bio.";
        return;
    }
    GLib.ByteArray key = BIO2Byte_array (priv_key);
    //_private_key = QSslKey (key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
    _private_key = key;

    q_c_info (lc_cse ()) << "Keys generated correctly, sending to server.";
    generate_c_sR (account, local_key_pair);
}

void ClientSideEncryption.generate_c_sR (AccountPtr &account, EVP_PKEY *key_pair) {
    // OpenSSL expects const char.
    var cn_array = account.dav_user ().to_local8Bit ();
    q_c_info (lc_cse ()) << "Getting the following array for the account Id" << cn_array;

    var cert_params = std.map<const char *, char> {
        {"C", "DE"},
        {"ST", "Baden-Wuerttemberg"},
        {"L", "Stuttgart"},
        {"O","Nextcloud"},
        {"CN", cn_array.const_data ()}
    };

    int ret = 0;
    int n_version = 1;

    // 2. set version of x509 req
    X509_REQ *x509_req = X509_REQ_new ();
    var release_on_exit_x509_req = q_scope_guard ([&] {
                X509_REQ_free (x509_req);
            });

    ret = X509_REQ_set_version (x509_req, n_version);

    // 3. set subject of x509 req
    var x509_name = X509_REQ_get_subject_name (x509_req);

    for (var& v : cert_params) {
        ret = X509_NAME_add_entry_by_txt (x509_name, v.first,  MBSTRING_ASC, (unsigned char*) v.second, -1, -1, 0);
        if (ret != 1) {
            q_c_info (lc_cse ()) << "Error Generating the Certificate while adding" << v.first << v.second;
            return;
        }
    }

    ret = X509_REQ_set_pubkey (x509_req, key_pair);
    if (ret != 1){
        q_c_info (lc_cse ()) << "Error setting the public key on the csr";
        return;
    }

    ret = X509_REQ_sign (x509_req, key_pair, EVP_sha1 ());    // return x509_req.signature.length
    if (ret <= 0){
        q_c_info (lc_cse ()) << "Error setting the public key on the csr";
        return;
    }

    Bio out;
    ret = PEM_write_bio_X509_REQ (out, x509_req);
    GLib.ByteArray output = BIO2Byte_array (out);

    q_c_info (lc_cse ()) << "Returning the certificate";
    q_c_info (lc_cse ()) << output;

    var job = new SignPublicKeyApiJob (account, e2ee_base_url () + "public-key", this);
    job.set_csr (output);

    connect (job, &SignPublicKeyApiJob.json_received, [this, account] (QJsonDocument& json, int ret_code) {
        if (ret_code == 200) {
            string cert = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("public-key").to_string ();
            _certificate = QSslCertificate (cert.to_local8Bit (), QSsl.Pem);
            _public_key = _certificate.public_key ();
            fetch_and_validate_public_key_from_server (account);
        }
        q_c_info (lc_cse ()) << ret_code;
    });
    job.on_start ();
}

void ClientSideEncryption.encrypt_private_key (AccountPtr &account) {
    string[] list = Word_list.get_random_words (12);
    _mnemonic = list.join (' ');
    _new_mnemonic_generated = true;
    q_c_info (lc_cse ()) << "mnemonic Generated:" << _mnemonic;

    emit mnemonic_generated (_mnemonic);

    string pass_phrase = list.join (string ()).to_lower ();
    q_c_info (lc_cse ()) << "Passphrase Generated:" << pass_phrase;

    var salt = EncryptionHelper.generate_random (40);
    var secret_key = EncryptionHelper.generate_password (pass_phrase, salt);
    var crypted_text = EncryptionHelper.encrypt_private_key (secret_key, EncryptionHelper.private_key_to_pem (_private_key), salt);

    // Send private key to the server
    var job = new StorePrivateKeyApiJob (account, e2ee_base_url () + "private-key", this);
    job.set_private_key (crypted_text);
    connect (job, &StorePrivateKeyApiJob.json_received, [this, account] (QJsonDocument& doc, int ret_code) {
        Q_UNUSED (doc);
        switch (ret_code) {
            case 200:
                q_c_info (lc_cse ()) << "Private key stored encrypted on server.";
                write_private_key (account);
                write_certificate (account);
                write_mnemonic (account);
                emit initialization_finished ();
                break;
            default:
                q_c_info (lc_cse ()) << "Store private key failed, return code:" << ret_code;
        }
    });
    job.on_start ();
}

bool ClientSideEncryption.new_mnemonic_generated () {
    return _new_mnemonic_generated;
}

void ClientSideEncryption.decrypt_private_key (AccountPtr &account, GLib.ByteArray key) {
    string msg = tr ("Please enter your end to end encryption passphrase:<br>"
                     "<br>"
                     "User : %2<br>"
                     "Account : %3<br>")
                      .arg (Utility.escape (account.credentials ().user ()),
                           Utility.escape (account.display_name ()));

    QInputDialog dialog;
    dialog.set_window_title (tr ("Enter E2E passphrase"));
    dialog.set_label_text (msg);
    dialog.set_text_echo_mode (QLineEdit.Normal);

    string prev;

    while (true) {
        if (!prev.is_empty ()) {
            dialog.set_text_value (prev);
        }
        bool ok = dialog.exec ();
        if (ok) {
            q_c_info (lc_cse ()) << "Got mnemonic:" << dialog.text_value ();
            prev = dialog.text_value ();

            _mnemonic = prev;
            string mnemonic = prev.split (" ").join (string ()).to_lower ();
            q_c_info (lc_cse ()) << "mnemonic:" << mnemonic;

            // split off salt
            const var salt = EncryptionHelper.extract_private_key_salt (key);

            var pass = EncryptionHelper.generate_password (mnemonic, salt);
            q_c_info (lc_cse ()) << "Generated key:" << pass;

            GLib.ByteArray private_key = EncryptionHelper.decrypt_private_key (pass, key);
            //_private_key = QSslKey (private_key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
            _private_key = private_key;

            q_c_info (lc_cse ()) << "Private key : " << _private_key;

            if (!_private_key.is_null () && check_public_key_validity (account)) {
                write_private_key (account);
                write_certificate (account);
                write_mnemonic (account);
                break;
            }
        } else {
            _mnemonic = string ();
            _private_key = GLib.ByteArray ();
            q_c_info (lc_cse ()) << "Cancelled";
            break;
        }
    }

    emit initialization_finished ();
}

void ClientSideEncryption.get_private_key_from_server (AccountPtr &account) {
    q_c_info (lc_cse ()) << "Retrieving private key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "private-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int ret_code) {
            if (ret_code == 200) {
                string key = doc.object ()["ocs"].to_object ()["data"].to_object ()["private-key"].to_string ();
                q_c_info (lc_cse ()) << key;
                q_c_info (lc_cse ()) << "Found private key, lets decrypt it!";
                decrypt_private_key (account, key.to_local8Bit ());
            } else if (ret_code == 404) {
                q_c_info (lc_cse ()) << "No private key on the server : setup is incomplete.";
            } else {
                q_c_info (lc_cse ()) << "Error while requesting public key : " << ret_code;
            }
    });
    job.on_start ();
}

void ClientSideEncryption.get_public_key_from_server (AccountPtr &account) {
    q_c_info (lc_cse ()) << "Retrieving public key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "public-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int ret_code) {
            if (ret_code == 200) {
                string public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-keys"].to_object ()[account.dav_user ()].to_string ();
                _certificate = QSslCertificate (public_key.to_local8Bit (), QSsl.Pem);
                _public_key = _certificate.public_key ();
                q_c_info (lc_cse ()) << "Found Public key, requesting Server Public Key. Public key:" << public_key;
                fetch_and_validate_public_key_from_server (account);
            } else if (ret_code == 404) {
                q_c_info (lc_cse ()) << "No public key on the server";
                generate_key_pair (account);
            } else {
                q_c_info (lc_cse ()) << "Error while requesting public key : " << ret_code;
            }
    });
    job.on_start ();
}

void ClientSideEncryption.fetch_and_validate_public_key_from_server (AccountPtr &account) {
    q_c_info (lc_cse ()) << "Retrieving public key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "server-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int ret_code) {
        if (ret_code == 200) {
            const var server_public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-key"].to_string ().to_latin1 ();
            q_c_info (lc_cse ()) << "Found Server Public key, checking it. Server public key:" << server_public_key;
            if (check_server_public_key_validity (server_public_key)) {
                if (_private_key.is_empty ()) {
                    q_c_info (lc_cse ()) << "Valid Server Public key, requesting Private Key.";
                    get_private_key_from_server (account);
                } else {
                    q_c_info (lc_cse ()) << "Certificate saved, Encrypting Private Key.";
                    encrypt_private_key (account);
                }
            } else {
                q_c_info (lc_cse ()) << "Error invalid server public key";
                _certificate = QSslCertificate ();
                _public_key = QSslKey ();
                _private_key = GLib.ByteArray ();
                get_public_key_from_server (account);
                return;
            }
        } else {
            q_c_info (lc_cse ()) << "Error while requesting server public key : " << ret_code;
        }
    });
    job.on_start ();
}

FolderMetadata.FolderMetadata (AccountPtr account, GLib.ByteArray& metadata, int status_code) : _account (account) {
    if (metadata.is_empty () || status_code == 404) {
        q_c_info (lc_cse_metadata ()) << "Setupping Empty Metadata";
        setup_empty_metadata ();
    } else {
        q_c_info (lc_cse_metadata ()) << "Setting up existing metadata";
        setup_existing_metadata (metadata);
    }
}

void FolderMetadata.setup_existing_metadata (GLib.ByteArray& metadata) {
/* This is the json response from the server, it contains two extra objects that we are not* interested.
* ocs and data.
*/
QJsonDocument doc = QJsonDocument.from_json (metadata);
q_c_info (lc_cse_metadata ()) << doc.to_json (QJsonDocument.Compact);

// The metadata is being retrieved as a string stored in a json.
// This seems* to be broken but the RFC doesn't explicits how it wants.
// I'm currently unsure if this is error on my side or in the server implementation.
// And because inside of the meta-data there's an object called metadata, without '-'
// make it really different.

string meta_data_str = doc.object ()["ocs"]
                        .to_object ()["data"]
                        .to_object ()["meta-data"]
                        .to_string ();

QJsonDocument meta_data_doc = QJsonDocument.from_json (meta_data_str.to_local8Bit ());
QJsonObject metadata_obj = meta_data_doc.object ()["metadata"].to_object ();
QJsonObject metadata_keys = metadata_obj["metadata_keys"].to_object ();
GLib.ByteArray sharing = metadata_obj["sharing"].to_string ().to_local8Bit ();
QJsonObject files = meta_data_doc.object ()["files"].to_object ();

QJsonDocument debug_helper;
debug_helper.set_object (metadata_keys);
q_c_debug (lc_cse) << "Keys : " << debug_helper.to_json (QJsonDocument.Compact);

// Iterate over the document to store the keys. I'm unsure that the keys are in order,
// perhaps it's better to store a map instead of a vector, perhaps this just doesn't matter.
for (var it = metadata_keys.const_begin (), end = metadata_keys.const_end (); it != end; it++) {
    GLib.ByteArray curr_b64Pass = it.value ().to_string ().to_local8Bit ();
    /***********************************************************
    We have to base64 decode the metadatakey here. This was a misunderstanding in the RFC
    Now we should be compatible with Android and IOS. Maybe we can fix it later.
    ***********************************************************/
    GLib.ByteArray b64Decrypted_key = decrypt_metadata_key (curr_b64Pass);
    if (b64Decrypted_key.is_empty ()) {
      q_c_debug (lc_cse ()) << "Could not decrypt metadata for key" << it.key ();
      continue;
    }

    GLib.ByteArray decrypted_key = GLib.ByteArray.from_base64 (b64Decrypted_key);
    _metadata_keys.insert (it.key ().to_int (), decrypted_key);
  }

  // Cool, We actually have the key, we can decrypt the rest of the metadata.
  q_c_debug (lc_cse) << "Sharing : " << sharing;
  if (sharing.size ()) {
      var sharing_decrypted = decrypt_json_object (sharing, _metadata_keys.last ());
      q_c_debug (lc_cse) << "Sharing Decrypted" << sharing_decrypted;

      //Sharing is also a JSON object, so extract it and populate.
      var sharing_doc = QJsonDocument.from_json (sharing_decrypted);
      var sharing_obj = sharing_doc.object ();
      for (var it = sharing_obj.const_begin (), end = sharing_obj.const_end (); it != end; it++) {
        _sharing.push_back ({it.key (), it.value ().to_string ()});
      }
  } else {
      q_c_debug (lc_cse) << "Skipping sharing section since it is empty";
  }

    for (var it = files.const_begin (), end = files.const_end (); it != end; it++) {
        EncryptedFile file;
        file.encrypted_filename = it.key ();

        var file_obj = it.value ().to_object ();
        file.metadata_key = file_obj["metadata_key"].to_int ();
        file.authentication_tag = GLib.ByteArray.from_base64 (file_obj["authentication_tag"].to_string ().to_local8Bit ());
        file.initialization_vector = GLib.ByteArray.from_base64 (file_obj["initialization_vector"].to_string ().to_local8Bit ());

        //Decrypt encrypted part
        GLib.ByteArray key = _metadata_keys[file.metadata_key];
        var encrypted_file = file_obj["encrypted"].to_string ().to_local8Bit ();
        var decrypted_file = decrypt_json_object (encrypted_file, key);
        var decrypted_file_doc = QJsonDocument.from_json (decrypted_file);
        var decrypted_file_obj = decrypted_file_doc.object ();

        file.original_filename = decrypted_file_obj["filename"].to_string ();
        file.encryption_key = GLib.ByteArray.from_base64 (decrypted_file_obj["key"].to_string ().to_local8Bit ());
        file.mimetype = decrypted_file_obj["mimetype"].to_string ().to_local8Bit ();
        file.file_version = decrypted_file_obj["version"].to_int ();

        // In case we wrongly stored "inode/directory" we try to recover from it
        if (file.mimetype == QByteArrayLiteral ("inode/directory")) {
            file.mimetype = QByteArrayLiteral ("httpd/unix-directory");
        }

        _files.push_back (file);
    }
}

// RSA/ECB/OAEPWith_sHA-256And_mGF1Padding using private / public key.
GLib.ByteArray FolderMetadata.encrypt_metadata_key (GLib.ByteArray& data) {
    Bio public_key_bio;
    GLib.ByteArray public_key_pem = _account.e2e ()._public_key.to_pem ();
    BIO_write (public_key_bio, public_key_pem.const_data (), public_key_pem.size ());
    var public_key = PKey.read_public_key (public_key_bio);

    // The metadata key is binary so base64 encode it first
    return EncryptionHelper.encrypt_string_asymmetric (public_key, data.to_base64 ());
}

GLib.ByteArray FolderMetadata.decrypt_metadata_key (GLib.ByteArray& encrypted_metadata) {
    Bio private_key_bio;
    GLib.ByteArray private_key_pem = _account.e2e ()._private_key;
    BIO_write (private_key_bio, private_key_pem.const_data (), private_key_pem.size ());
    var key = PKey.read_private_key (private_key_bio);

    // Also base64 decode the result
    GLib.ByteArray decrypt_result = EncryptionHelper.decrypt_string_asymmetric (
                    key, GLib.ByteArray.from_base64 (encrypted_metadata));

    if (decrypt_result.is_empty ()) {
      q_c_debug (lc_cse ()) << "ERROR. Could not decrypt the metadata key";
      return {};
    }
    return GLib.ByteArray.from_base64 (decrypt_result);
}

// AES/GCM/No_padding (128 bit key size)
GLib.ByteArray FolderMetadata.encrypt_json_object (GLib.ByteArray& obj, GLib.ByteArray pass) {
    return EncryptionHelper.encrypt_string_symmetric (pass, obj);
}

GLib.ByteArray FolderMetadata.decrypt_json_object (GLib.ByteArray& encrypted_metadata, GLib.ByteArray& pass) {
    return EncryptionHelper.decrypt_string_symmetric (pass, encrypted_metadata);
}

void FolderMetadata.setup_empty_metadata () {
    q_c_debug (lc_cse) << "Settint up empty metadata";
    GLib.ByteArray new_metadata_pass = EncryptionHelper.generate_random (16);
    _metadata_keys.insert (0, new_metadata_pass);

    string public_key = _account.e2e ()._public_key.to_pem ().to_base64 ();
    string display_name = _account.display_name ();

    _sharing.append ({display_name, public_key});
}

GLib.ByteArray FolderMetadata.encrypted_metadata () {
    q_c_debug (lc_cse) << "Generating metadata";

    QJsonObject metadata_keys;
    for (var it = _metadata_keys.const_begin (), end = _metadata_keys.const_end (); it != end; it++) {
        /***********************************************************
        We have to already base64 encode the metadatakey here. This was a misunderstanding in the RFC
        Now we should be compatible with Android and IOS. Maybe we can fix it later.
        ***********************************************************/
        const GLib.ByteArray encrypted_key = encrypt_metadata_key (it.value ().to_base64 ());
        metadata_keys.insert (string.number (it.key ()), string (encrypted_key));
    }


    /***********************************************************
    NO SHARING IN V1
    QJsonObject recepients;
    for (var it = _sharing.const_begin (), end = _sharing.const_end (); it != end; it++) {
        recepients.insert (it.first, it.second);
    }
    QJsonDocument recepient_doc;
    recepient_doc.set_object (recepients);
    string sharing_encrypted = encrypt_json_object (recepient_doc.to_json (QJsonDocument.Compact), _metadata_keys.last ());
    ***********************************************************/

    QJsonObject metadata = {
        {"metadata_keys", metadata_keys},
        {"sharing", sharing_encrypted},
        {"version", 1}
    };

    QJsonObject files;
    for (var it = _files.const_begin (), end = _files.const_end (); it != end; it++) {
        QJsonObject encrypted;
        encrypted.insert ("key", string (it.encryption_key.to_base64 ()));
        encrypted.insert ("filename", it.original_filename);
        encrypted.insert ("mimetype", string (it.mimetype));
        encrypted.insert ("version", it.file_version);
        QJsonDocument encrypted_doc;
        encrypted_doc.set_object (encrypted);

        string encrypted_encrypted = encrypt_json_object (encrypted_doc.to_json (QJsonDocument.Compact), _metadata_keys.last ());
        if (encrypted_encrypted.is_empty ()) {
          q_c_debug (lc_cse) << "Metadata generation failed!";
        }

        QJsonObject file;
        file.insert ("encrypted", encrypted_encrypted);
        file.insert ("initialization_vector", string (it.initialization_vector.to_base64 ()));
        file.insert ("authentication_tag", string (it.authentication_tag.to_base64 ()));
        file.insert ("metadata_key", _metadata_keys.last_key ());

        files.insert (it.encrypted_filename, file);
    }

    QJsonObject meta_object = {
        {"metadata", metadata},
        {"files", files}
    };

    QJsonDocument internal_metadata;
    internal_metadata.set_object (meta_object);
    return internal_metadata.to_json ();
}

void FolderMetadata.add_encrypted_file (EncryptedFile &f) {

    for (int i = 0; i < _files.size (); i++) {
        if (_files.at (i).original_filename == f.original_filename) {
            _files.remove_at (i);
            break;
        }
    }

    _files.append (f);
}

void FolderMetadata.remove_encrypted_file (EncryptedFile &f) {
    for (int i = 0; i < _files.size (); i++) {
        if (_files.at (i).original_filename == f.original_filename) {
            _files.remove_at (i);
            break;
        }
    }
}

void FolderMetadata.remove_all_encrypted_files () {
    _files.clear ();
}

QVector<EncryptedFile> FolderMetadata.files () {
    return _files;
}

bool EncryptionHelper.file_encryption (GLib.ByteArray key, GLib.ByteArray iv, QFile input, QFile output, GLib.ByteArray& return_tag) {
    if (!input.open (QIODevice.ReadOnly)) {
      q_c_debug (lc_cse) << "Could not open input file for reading" << input.error_string ();
    }
    if (!output.open (QIODevice.WriteOnly)) {
      q_c_debug (lc_cse) << "Could not oppen output file for writing" << output.error_string ();
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

    q_c_debug (lc_cse) << "Starting to encrypt the file" << input.file_name () << input.at_end ();
    while (!input.at_end ()) {
        const var data = input.read (block_size);

        if (data.size () == 0) {
            q_c_info (lc_cse ()) << "Could not read data from file";
            return false;
        }

        if (!EVP_Encrypt_update (ctx, unsigned_data (out), &len, (unsigned char *)data.const_data (), data.size ())) {
            q_c_info (lc_cse ()) << "Could not encrypt";
            return false;
        }

        output.write (out, len);
        total_len += len;
    }

    if (1 != EVP_Encrypt_final_ex (ctx, unsigned_data (out), &len)) {
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
    q_c_debug (lc_cse) << "File Encrypted Successfully";
    return true;
}

bool EncryptionHelper.file_decryption (GLib.ByteArray key, GLib.ByteArray& iv,
                               QFile input, QFile output) {
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

        if (!EVP_Decrypt_update (ctx, unsigned_data (out), &len, (unsigned char *)data.const_data (), data.size ())) {
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

    if (1 != EVP_Decrypt_final_ex (ctx, unsigned_data (out), &len)) {
        q_c_info (lc_cse ()) << "Could on_finalize decryption";
        return false;
    }
    output.write (out, len);

    input.close ();
    output.close ();
    return true;
}

EncryptionHelper.StreamingDecryptor.StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray iv, uint64 total_size) : _total_size (total_size) {
    if (_ctx && !key.is_empty () && !iv.is_empty () && total_size > 0) {
        _is_initialized = true;

        // Initialize the decryption operation.
        if (!EVP_Decrypt_init_ex (_ctx, EVP_aes_128_gcm (), nullptr, nullptr, nullptr)) {
            q_critical (lc_cse ()) << "Could not on_init cipher";
            _is_initialized = false;
        }

        EVP_CIPHER_CTX_set_padding (_ctx, 0);

        // Set IV length.
        if (!EVP_CIPHER_CTX_ctrl (_ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size (), nullptr)) {
            q_critical (lc_cse ()) << "Could not set iv length";
            _is_initialized = false;
        }

        // Initialize key and IV
        if (!EVP_Decrypt_init_ex (_ctx, nullptr, nullptr, reinterpret_cast<const unsigned char> (key.const_data ()), reinterpret_cast<const unsigned char> (iv.const_data ()))) {
            q_critical (lc_cse ()) << "Could not set key and iv";
            _is_initialized = false;
        }
    }
}

GLib.ByteArray EncryptionHelper.StreamingDecryptor.chunk_decryption (char input, uint64 chunk_size) {
    GLib.ByteArray byte_array;
    QBuffer buffer (&byte_array);
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

    if (_decrypted_so_far == 0) {
        q_c_debug (lc_cse ()) << "Decryption started";
    }

    Q_ASSERT (_decrypted_so_far + chunk_size <= _total_size);
    if (_decrypted_so_far + chunk_size > _total_size) {
        q_critical (lc_cse ()) << "Decryption failed. Chunk is out of range!";
        return GLib.ByteArray ();
    }

    Q_ASSERT (_decrypted_so_far + chunk_size < Occ.Constants.E2EE_TAG_SIZE || _total_size - Occ.Constants.E2EE_TAG_SIZE >= _decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE);
    if (_decrypted_so_far + chunk_size > Occ.Constants.E2EE_TAG_SIZE && _total_size - Occ.Constants.E2EE_TAG_SIZE < _decrypted_so_far + chunk_size - Occ.Constants.E2EE_TAG_SIZE) {
        q_critical (lc_cse ()) << "Decryption failed. Incorrect chunk!";
        return GLib.ByteArray ();
    }

    const bool is_last_chunk = _decrypted_so_far + chunk_size == _total_size;

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

        if (!EVP_Decrypt_update (_ctx, unsigned_data (decrypted_block), &out_len, reinterpret_cast<const unsigned char> (encrypted_block.data ()), encrypted_block.size ())) {
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

        _decrypted_so_far += encrypted_block.size ();
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
        if (!EVP_CIPHER_CTX_ctrl (_ctx, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), reinterpret_cast<unsigned char> (e2Ee_tag.data ()))) {
            q_critical (lc_cse ()) << "Could not set expected e2Ee_tag";
            return GLib.ByteArray ();
        }

        if (1 != EVP_Decrypt_final_ex (_ctx, unsigned_data (decrypted_block), &out_len)) {
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

        _decrypted_so_far += Occ.Constants.E2EE_TAG_SIZE;

        _is_finished = true;
    }

    if (is_finished ()) {
        q_c_debug (lc_cse ()) << "Decryption complete";
    }

    return byte_array;
}

bool EncryptionHelper.StreamingDecryptor.is_initialized () {
    return _is_initialized;
}

bool EncryptionHelper.StreamingDecryptor.is_finished () {
    return _is_finished;
}
}
