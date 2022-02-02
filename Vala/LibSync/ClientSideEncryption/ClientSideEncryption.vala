
// #include <openssl/rsa.h>
// #include <openssl/evp.h>
// #include <openssl/pem.h>
// #include <openssl/err.h>
// #include <openssl/engine.h>
// #include <openssl/rand.h>

// #include <map>
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

QDebug operator<< (QDebug out, std.string& string_value) {
    out << string.from_std_string (string_value);
    return out;
}

using namespace QKeychain;

// #include <QJsonDocument>
// #include <QSslCertificate>
// #include <QSslKey>

// #include <openssl/evp.h>

namespace QKeychain {
}

namespace Occ {

string e2ee_base_url ();

namespace EncryptionHelper {
    GLib.ByteArray generate_random_filename ();
    GLib.ByteArray generate_random (int size);
    GLib.ByteArray generate_password (string wordlist, GLib.ByteArray salt);
    GLib.ByteArray encrypt_private_key (
            const GLib.ByteArray key,
            const GLib.ByteArray private_key,
            const GLib.ByteArray salt
    );
    GLib.ByteArray decrypt_private_key (
            const GLib.ByteArray key,
            const GLib.ByteArray data
    );
    GLib.ByteArray extract_private_key_salt (GLib.ByteArray data);
    GLib.ByteArray encrypt_string_symmetric (
            const GLib.ByteArray key,
            const GLib.ByteArray data
    );
    GLib.ByteArray decrypt_string_symmetric (
            const GLib.ByteArray key,
            const GLib.ByteArray data
    );

    GLib.ByteArray private_key_to_pem (GLib.ByteArray key);

    //TODO : change those two EVP_PKEY into QSslKey.
    GLib.ByteArray encrypt_string_asymmetric (
            EVP_PKEY *public_key,
            const GLib.ByteArray data
    );
    GLib.ByteArray decrypt_string_asymmetric (
            EVP_PKEY *private_key,
            const GLib.ByteArray data
    );

    bool file_encryption (GLib.ByteArray key, GLib.ByteArray iv,
                      GLib.File input, GLib.File output, GLib.ByteArray return_tag);

    bool file_decryption (GLib.ByteArray key, GLib.ByteArray iv,
                               GLib.File input, GLib.File output);


}

class ClientSideEncryption : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public ClientSideEncryption ();

    /***********************************************************
    ***********************************************************/
    public 
    public void initialize (AccountPointer account);


    /***********************************************************
    ***********************************************************/
    private void generate_key_pair (AccountPointer account);
    private void generate_c_sR (AccountPointer account, EVP_PKEY *key_pair);
    private void encrypt_private_key (AccountPointer account);


    /***********************************************************
    ***********************************************************/
    public void forget_sensitive_data (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    public bool new_mnemonic_generated ();

    /***********************************************************
    ***********************************************************/
    public 
    public void on_request_mnemonic ();


    /***********************************************************
    ***********************************************************/
    private void on_public_key_fetched (QKeychain.Job incoming);
    private void on_private_key_fetched (QKeychain.Job incoming);
    private void on_mnemonic_key_fetched (QKeychain.Job incoming);

signals:
    void initialization_finished ();
    void mnemonic_generated (string& mnemonic);
    void show_mnemonic (string& mnemonic);


    /***********************************************************
    ***********************************************************/
    private void get_private_key_from_server (AccountPointer account);
    private void get_public_key_from_server (AccountPointer account);
    private void fetch_and_validate_public_key_from_server (AccountPointer account);
    private void decrypt_private_key (AccountPointer account, GLib.ByteArray key);

    /***********************************************************
    ***********************************************************/
    private void fetch_from_key_chain (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    private bool check_public_key_validity (AccountPointer account);
    private bool check_server_public_key_validity (GLib.ByteArray server_public_key_string);
    private void write_private_key (AccountPointer account);
    private void write_certificate (AccountPointer account);
    private void write_mnemonic (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    private bool is_initialized = false;


    // public QSslKey this.private_key;
    public GLib.ByteArray this.private_key;
    public QSslKey this.public_key;
    public QSslCertificate this.certificate;
    public string this.mnemonic;
    public bool this.new_mnemonic_generated = false;
}

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
}





string e2ee_base_url () {
    return QStringLiteral ("ocs/v2.php/apps/end_to_end_encryption/api/v1/");
}

namespace {
    constexpr char account_property[] = "account";

    const char e2e_cert[] = "this.e2e-certificate";
    const char e2e_private[] = "this.e2e-private";
    const char e2e_mnemonic[] = "this.e2e-mnemonic";

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
    unsigned char* unsigned_data (GLib.ByteArray array) {
        return (unsigned char*)array.data ();
    }

    //
    // Simple classes for safe (RAII) handling of OpenSSL
    // data structures
    //






    GLib.ByteArray BIO2Byte_array (Bio b) {
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


ClientSideEncryption.ClientSideEncryption () = default;

void ClientSideEncryption.initialize (AccountPointer account) {
    Q_ASSERT (account);

    q_c_info (lc_cse ()) << "Initializing";
    if (!account.capabilities ().client_side_encryption_available ()) {
        q_c_info (lc_cse ()) << "No Client side encryption available on server.";
        /* emit */ initialization_finished ();
        return;
    }

    fetch_from_key_chain (account);
}

void ClientSideEncryption.fetch_from_key_chain (AccountPointer account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_cert,
                account.id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_property (account_property, GLib.Variant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_public_key_fetched);
    job.on_start ();
}

bool ClientSideEncryption.check_public_key_validity (AccountPointer account) {
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
    const var certificate_pem = this.certificate.to_pem ();
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

    GLib.debug (lc_cse ()) << "Client certificate is valid against server public key";
    return true;
}

void ClientSideEncryption.on_public_key_fetched (Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPointer> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.binary_data ().length () == 0) {
        get_public_key_from_server (account);
        return;
    }

    this.certificate = QSslCertificate (read_job.binary_data (), QSsl.Pem);

    if (this.certificate.is_null ()) {
        get_public_key_from_server (account);
        return;
    }

    this.public_key = this.certificate.public_key ();

    q_c_info (lc_cse ()) << "Public key fetched from keychain";

    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_private,
                account.id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_property (account_property, GLib.Variant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_private_key_fetched);
    job.on_start ();
}

void ClientSideEncryption.on_private_key_fetched (Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPointer> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.binary_data ().length () == 0) {
        this.certificate = QSslCertificate ();
        this.public_key = QSslKey ();
        get_public_key_from_server (account);
        return;
    }

    //this.private_key = QSslKey (read_job.binary_data (), QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
    this.private_key = read_job.binary_data ();

    if (this.private_key.is_null ()) {
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
    job.set_property (account_property, GLib.Variant.from_value (account));
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, this, &ClientSideEncryption.on_mnemonic_key_fetched);
    job.on_start ();
}

void ClientSideEncryption.on_mnemonic_key_fetched (QKeychain.Job incoming) {
    var read_job = static_cast<ReadPasswordJob> (incoming);
    var account = read_job.property (account_property).value<AccountPointer> ();
    Q_ASSERT (account);

    // Error or no valid public key error out
    if (read_job.error () != NoError || read_job.text_data ().length () == 0) {
        this.certificate = QSslCertificate ();
        this.public_key = QSslKey ();
        this.private_key = GLib.ByteArray ();
        get_public_key_from_server (account);
        return;
    }

    this.mnemonic = read_job.text_data ();

    q_c_info (lc_cse ()) << "Mnemonic key fetched from keychain : " << this.mnemonic;

    /* emit */ initialization_finished ();
}

void ClientSideEncryption.write_private_key (AccountPointer account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_private,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (this.private_key);
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Private key stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.write_certificate (AccountPointer account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_cert,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (this.certificate.to_pem ());
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Certificate stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.write_mnemonic (AccountPointer account) {
    const string kck = AbstractCredentials.keychain_key (
                account.url ().to_string (),
                account.credentials ().user () + e2e_mnemonic,
                account.id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_text_data (this.mnemonic);
    connect (job, &WritePasswordJob.on_finished, [] (Job incoming) {
        Q_UNUSED (incoming);
        q_c_info (lc_cse ()) << "Mnemonic stored in keychain";
    });
    job.on_start ();
}

void ClientSideEncryption.forget_sensitive_data (AccountPointer account) {
    this.private_key = GLib.ByteArray ();
    this.certificate = QSslCertificate ();
    this.public_key = QSslKey ();
    this.mnemonic = "";

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
    /* emit */ show_mnemonic (this.mnemonic);
}

void ClientSideEncryption.generate_key_pair (AccountPointer account) {
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
    //this.private_key = QSslKey (key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
    this.private_key = key;

    q_c_info (lc_cse ()) << "Keys generated correctly, sending to server.";
    generate_c_sR (account, local_key_pair);
}

void ClientSideEncryption.generate_c_sR (AccountPointer account, EVP_PKEY *key_pair) {
    // OpenSSL expects const char.
    var cn_array = account.dav_user ().to_local8Bit ();
    q_c_info (lc_cse ()) << "Getting the following array for the account Id" << cn_array;

    var cert_params = GLib.HashMap<const char *, char> {
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

    connect (job, &SignPublicKeyApiJob.json_received, [this, account] (QJsonDocument& json, int return_code) {
        if (return_code == 200) {
            string cert = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("public-key").to_string ();
            this.certificate = QSslCertificate (cert.to_local8Bit (), QSsl.Pem);
            this.public_key = this.certificate.public_key ();
            fetch_and_validate_public_key_from_server (account);
        }
        q_c_info (lc_cse ()) << return_code;
    });
    job.on_start ();
}

void ClientSideEncryption.encrypt_private_key (AccountPointer account) {
    string[] list = Word_list.get_random_words (12);
    this.mnemonic = list.join (' ');
    this.new_mnemonic_generated = true;
    q_c_info (lc_cse ()) << "mnemonic Generated:" << this.mnemonic;

    /* emit */ mnemonic_generated (this.mnemonic);

    string pass_phrase = list.join ("").to_lower ();
    q_c_info (lc_cse ()) << "Passphrase Generated:" << pass_phrase;

    var salt = EncryptionHelper.generate_random (40);
    var secret_key = EncryptionHelper.generate_password (pass_phrase, salt);
    var crypted_text = EncryptionHelper.encrypt_private_key (secret_key, EncryptionHelper.private_key_to_pem (this.private_key), salt);

    // Send private key to the server
    var job = new StorePrivateKeyApiJob (account, e2ee_base_url () + "private-key", this);
    job.set_private_key (crypted_text);
    connect (job, &StorePrivateKeyApiJob.json_received, [this, account] (QJsonDocument& doc, int return_code) {
        Q_UNUSED (doc);
        switch (return_code) {
            case 200:
                q_c_info (lc_cse ()) << "Private key stored encrypted on server.";
                write_private_key (account);
                write_certificate (account);
                write_mnemonic (account);
                /* emit */ initialization_finished ();
                break;
            default:
                q_c_info (lc_cse ()) << "Store private key failed, return code:" << return_code;
        }
    });
    job.on_start ();
}

bool ClientSideEncryption.new_mnemonic_generated () {
    return this.new_mnemonic_generated;
}

void ClientSideEncryption.decrypt_private_key (AccountPointer account, GLib.ByteArray key) {
    string msg = _("Please enter your end to end encryption passphrase:<br>"
                     "<br>"
                     "User : %2<br>"
                     "Account : %3<br>")
                      .arg (Utility.escape (account.credentials ().user ()),
                           Utility.escape (account.display_name ()));

    QInputDialog dialog;
    dialog.set_window_title (_("Enter E2E passphrase"));
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

            this.mnemonic = prev;
            string mnemonic = prev.split (" ").join ("").to_lower ();
            q_c_info (lc_cse ()) << "mnemonic:" << mnemonic;

            // split off salt
            const var salt = EncryptionHelper.extract_private_key_salt (key);

            var pass = EncryptionHelper.generate_password (mnemonic, salt);
            q_c_info (lc_cse ()) << "Generated key:" << pass;

            GLib.ByteArray private_key = EncryptionHelper.decrypt_private_key (pass, key);
            //this.private_key = QSslKey (private_key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
            this.private_key = private_key;

            q_c_info (lc_cse ()) << "Private key : " << this.private_key;

            if (!this.private_key.is_null () && check_public_key_validity (account)) {
                write_private_key (account);
                write_certificate (account);
                write_mnemonic (account);
                break;
            }
        } else {
            this.mnemonic = "";
            this.private_key = GLib.ByteArray ();
            q_c_info (lc_cse ()) << "Cancelled";
            break;
        }
    }

    /* emit */ initialization_finished ();
}

void ClientSideEncryption.get_private_key_from_server (AccountPointer account) {
    q_c_info (lc_cse ()) << "Retrieving private key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "private-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int return_code) {
            if (return_code == 200) {
                string key = doc.object ()["ocs"].to_object ()["data"].to_object ()["private-key"].to_string ();
                q_c_info (lc_cse ()) << key;
                q_c_info (lc_cse ()) << "Found private key, lets decrypt it!";
                decrypt_private_key (account, key.to_local8Bit ());
            } else if (return_code == 404) {
                q_c_info (lc_cse ()) << "No private key on the server : setup is incomplete.";
            } else {
                q_c_info (lc_cse ()) << "Error while requesting public key : " << return_code;
            }
    });
    job.on_start ();
}

void ClientSideEncryption.get_public_key_from_server (AccountPointer account) {
    q_c_info (lc_cse ()) << "Retrieving public key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "public-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int return_code) {
            if (return_code == 200) {
                string public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-keys"].to_object ()[account.dav_user ()].to_string ();
                this.certificate = QSslCertificate (public_key.to_local8Bit (), QSsl.Pem);
                this.public_key = this.certificate.public_key ();
                q_c_info (lc_cse ()) << "Found Public key, requesting Server Public Key. Public key:" << public_key;
                fetch_and_validate_public_key_from_server (account);
            } else if (return_code == 404) {
                q_c_info (lc_cse ()) << "No public key on the server";
                generate_key_pair (account);
            } else {
                q_c_info (lc_cse ()) << "Error while requesting public key : " << return_code;
            }
    });
    job.on_start ();
}

void ClientSideEncryption.fetch_and_validate_public_key_from_server (AccountPointer account) {
    q_c_info (lc_cse ()) << "Retrieving public key from server";
    var job = new JsonApiJob (account, e2ee_base_url () + "server-key", this);
    connect (job, &JsonApiJob.json_received, [this, account] (QJsonDocument& doc, int return_code) {
        if (return_code == 200) {
            const var server_public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-key"].to_string ().to_latin1 ();
            q_c_info (lc_cse ()) << "Found Server Public key, checking it. Server public key:" << server_public_key;
            if (check_server_public_key_validity (server_public_key)) {
                if (this.private_key.is_empty ()) {
                    q_c_info (lc_cse ()) << "Valid Server Public key, requesting Private Key.";
                    get_private_key_from_server (account);
                } else {
                    q_c_info (lc_cse ()) << "Certificate saved, Encrypting Private Key.";
                    encrypt_private_key (account);
                }
            } else {
                q_c_info (lc_cse ()) << "Error invalid server public key";
                this.certificate = QSslCertificate ();
                this.public_key = QSslKey ();
                this.private_key = GLib.ByteArray ();
                get_public_key_from_server (account);
                return;
            }
        } else {
            q_c_info (lc_cse ()) << "Error while requesting server public key : " << return_code;
        }
    });
    job.on_start ();
}

}
