
//  #include <openssl/rsa.h>
//  #include <openssl/evp.h>
//  #include <openssl/pem.h>
//  #include <openssl/err.h>
//  #include <openssl/engine.h>
//  #include <openssl/rand.h>

//  #include <map>
//  #include <algorithm>

//  #include <cstdio>

//  #include <QDebug>
//  #include <QLoggingCategory>
//  #include <GLib.FileInfo>
//  #include <QDir>
//  #include <QJsonObject>
//  #include <QXmlStreamReader>
//  #include <QXmlStreamNamespaceDeclaration>
//  #include <GLib.List>
//  #include <QInputDialog>
//  #include <QLineEdit>
//  #include <QIODevice>
//  #include <QUuid>
//  #include <QScopeGuard>
//  #include <QRandomGenerator>

//  #include <qt5keychain/keychain.h>
//  #include <common/utility.h>
//  #include <common/constants.h>

//  QDebug operator<< (QDebug out, std.string string_value) {
//      out + string.from_std_string (string_value);
//      return out;
//  }

//  #include <QJsonDocument>
//  #include <QSslCertificate>
//  #include <QSslKey>

//  #include <openssl/evp.h>

namespace Occ {
namespace LibSync {

public class ClientSideEncryption : GLib.Object {

    const string E2EE_BASE_URL = "ocs/v2.php/apps/end_to_end_encryption/api/v1/";

    const string ACCOUNT_PROPERTY = "account";

    const string E2E_CERTIFICATE = "e2e-certificate";
    const string E2E_PRIVATE = "e2e-private";
    const string E2E_MNEMONIC = "e2e-mnemonic";

    const int64 BLOCK_SIZE = 1024;

    /***********************************************************
    ***********************************************************/
    private bool is_initialized = false;

    /***********************************************************
    ***********************************************************/
    // public QSslKey private_key;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray private_key;

    /***********************************************************
    ***********************************************************/
    public QSslKey public_key;

    /***********************************************************
    ***********************************************************/
    public QSslCertificate certificate;

    /***********************************************************
    ***********************************************************/
    public string mnemonic;

    /***********************************************************
    ***********************************************************/
    public bool new_mnemonic_generated = false;

    /***********************************************************
    ***********************************************************/
    signal void initialization_finished ();


    /***********************************************************
    ***********************************************************/
    signal void mnemonic_generated (string mnemonic);


    /***********************************************************
    ***********************************************************/
    signal void show_mnemonic (string mnemonic);


    /***********************************************************
    ***********************************************************/
    //  public ClientSideEncryption () = default;

    /***********************************************************
    ***********************************************************/
    public void initialize (unowned Account account) {
        //  Q_ASSERT (account);

        GLib.info ("Initializing");
        if (!account.capabilities ().client_side_encryption_available ()) {
            GLib.info ("No Client side encryption available on server.");
            /* emit */ initialization_finished ();
            return;
        }

        fetch_from_key_chain (account);
    }


    /***********************************************************
    ***********************************************************/
    private void generate_key_pair (unowned Account account) {
        // AES/GCM/No_padding,
        // metadata_keys with RSA/ECB/OAEPWith_sHA-256And_mGF1Padding
        GLib.info ("No public key, generating a pair.");
        const int rsa_key_len = 2048;

        // Init RSA
        PrivateKeyContext context = new PrivateKeyContext (EVP_PKEY_RSA);

        if (EVP_PKEY_keygen_init (context) <= 0) {
            GLib.info ("Couldn't initialize the key generator");
            return;
        }

        if (EVP_PKEY_CTX_rsa_keygen_bits (context, rsa_key_len) <= 0) {
            GLib.info ("Couldn't initialize the key generator bits");
            return;
        }

        var local_key_pair = PrivateKey.generate (context);
        if (!local_key_pair) {
            GLib.info ("Could not generate the key");
            return;
        }

        GLib.info ("Key correctly generated");
        GLib.info ("Storing keys locally");

        Biometric private_key;
        if (PEM_write_bio_Private_key (private_key, local_key_pair, null, null, 0, null, null) <= 0) {
            GLib.info ("Could not read private key from bio.");
            return;
        }
        GLib.ByteArray key = BIO2Byte_array (private_key);
        //this.private_key = QSslKey (key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
        this.private_key = key;

        GLib.info ("Keys generated correctly, sending to server.");
        generate_csr (account, local_key_pair);
    }


    /***********************************************************
    ***********************************************************/
    private void generate_csr.for_account (unowned Account account, EVP_PKEY key_pair) {
        // OpenSSL expects const char.
        var cn_array = account.dav_user ().to_local8Bit ();
        GLib.info ("Getting the following array for the account identifier " + cn_array);

        var cert_params = new GLib.HashTable<string, char> ();
        cert_params.set ("C", "DE");
        cert_params.set ("ST", "Baden-Wuerttemberg");
        cert_params.set ("L", "Stuttgart");
        cert_params.set ("O","Nextcloud");
        cert_params.set ("CN", cn_array.const_data ());

        int ret = 0;
        int n_version = 1;

        // 2. set version of x509 request
        X509_REQ *x509_req = X509_REQ_new ();
        var release_on_signal_exit_x509_req = q_scope_guard (() => {
                    X509_REQ_free (x509_req);
                });

        ret = X509_REQ_version (x509_req, n_version);

        // 3. set subject of x509 request
        var x509_name = X509_REQ_get_subject_name (x509_req);

        foreach (var v in cert_params) {
            ret = X509_NAME_add_entry_by_txt (x509_name, v.first,  MBSTRING_ASC, (uchar) v.second, -1, -1, 0);
            if (ret != 1) {
                GLib.info ("Error Generating the Certificate while adding " + v.first + v.second);
                return;
            }
        }

        ret = X509_REQ_pubkey (x509_req, key_pair);
        if (ret != 1) {
            GLib.info ("Error setting the public key on the csr.");
            return;
        }

        ret = X509_REQ_sign (x509_req, key_pair, EVP_sha1 ());    // return x509_req.signature.length
        if (ret <= 0) {
            GLib.info ("Error setting the public key on the csr.");
            return;
        }

        Biometric bio_out;
        ret = PEM_write_bio_X509_REQ (bio_out, x509_req);
        GLib.ByteArray output = BIO2Byte_array (bio_out);

        GLib.info ("Returning the certificate:");
        GLib.info (output);

        var sign_public_key_api_job = new SignPublicKeyApiJob (account, E2EE_BASE_URL + "public-key", this);
        sign_public_key_api_job.csr (output);

        SignPublicKeyApiJob.signal_json_received.connect ((sign_public_key_api_job, json, return_code) => {
            if (return_code == 200) {
                string cert = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("public-key").to_string ();
                this.certificate = QSslCertificate (cert.to_local8Bit (), QSsl.Pem);
                this.public_key = this.certificate.public_key ();
                fetch_and_validate_public_key_from_server (account);
            }
            GLib.info ("Return code: " + return_code);
        });
        sign_public_key_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void encrypt_private_key (unowned Account account) {
        string[] list = WordList.get_random_words (12);
        this.mnemonic = string.joinv (" ", list);
        this.new_mnemonic_generated = true;
        GLib.info ("Generated mnemonic: " + this.mnemonic);

        /* emit */ mnemonic_generated (this.mnemonic);

        string pass_phrase = string.joinv ("", list).down ();
        GLib.info ("Generated passphrase: " + pass_phrase);

        var salt = EncryptionHelper.generate_random (40);
        var secret_key = EncryptionHelper.generate_password (pass_phrase, salt);
        var crypted_text = EncryptionHelper.encrypt_private_key (secret_key, EncryptionHelper.private_key_to_pem (this.private_key), salt);

        // Send private key to the server
        var store_private_key_api_job = new StorePrivateKeyApiJob (account, E2EE_BASE_URL + "private-key", this);
        store_private_key_api_job.private_key (crypted_text);
        StorePrivateKeyApiJob.signal_json_received.connect ((store_private_key_api_job, doc, return_code) => {
            //  Q_UNUSED (doc);
            switch (return_code) {
                case 200:
                    GLib.info ("Private key stored encrypted on server.");
                    write_private_key (account);
                    write_certificate (account);
                    write_mnemonic (account);
                    /* emit */ initialization_finished ();
                    break;
                default:
                    GLib.info ("Store private key failed, return code: " + return_code);
            }
        });
        store_private_key_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void forget_sensitive_data (unowned Account account) {
        this.private_key = new GLib.ByteArray ();
        this.certificate = new QSslCertificate ();
        this.public_key = new QSslKey ();
        this.mnemonic = "";

        var user = account.credentials ().user ();
        start_delete_job (account, user + E2E_PRIVATE);
        start_delete_job (account, user + E2E_CERTIFICATE);
        start_delete_job (account, user + E2E_MNEMONIC);
    }


    private void start_delete_job (Account account, string user) {
        var delete_password_job = new DeletePasswordJob (Theme.instance ().app_name ());
        delete_password_job.insecure_fallback (false);
        delete_password_job.key (AbstractCredentials.keychain_key (account.url ().to_string (), user, account.identifier ()));
        delete_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_request_mnemonic () {
        /* emit */ show_mnemonic (this.mnemonic);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_public_key_fetched (Job incoming) {
        var read_job = static_cast<ReadPasswordJob> (incoming);
        var account = read_job.property (ACCOUNT_PROPERTY).value<unowned Account> ();
        //  Q_ASSERT (account);

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

        GLib.info ("Public key fetched from keychain.");

        const string kck = AbstractCredentials.keychain_key (
            account.url ().to_string (),
            account.credentials ().user () + E2E_PRIVATE,
            account.identifier ()
        );

        var read_password_job = new ReadPasswordJob (Theme.instance ().app_name ());
        read_password_job.property (ACCOUNT_PROPERTY, GLib.Variant.from_value (account));
        read_password_job.insecure_fallback (false);
        read_password_job.key (kck);
        connect (read_password_job, ReadPasswordJob.on_signal_finished, this, ClientSideEncryption.on_signal_private_key_fetched);
        read_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_private_key_fetched (QKeychain.Job incoming) {
        var read_job = static_cast<ReadPasswordJob> (incoming);
        var account = read_job.property (ACCOUNT_PROPERTY).value<unowned Account> ();
        //  Q_ASSERT (account);

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

        GLib.info ("Private key fetched from keychain.");

        const string kck = AbstractCredentials.keychain_key (
                    account.url ().to_string (),
                    account.credentials ().user () + E2E_MNEMONIC,
                    account.identifier ()
        );

        var read_password_job = new ReadPasswordJob (Theme.instance ().app_name ());
        read_password_job.property (ACCOUNT_PROPERTY, GLib.Variant.from_value (account));
        read_password_job.insecure_fallback (false);
        read_password_job.key (kck);
        connect (read_password_job, ReadPasswordJob.on_signal_finished, this, ClientSideEncryption.on_signal_mnemonic_key_fetched);
        read_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_mnemonic_key_fetched (QKeychain.Job incoming) {
        var read_job = static_cast<ReadPasswordJob> (incoming);
        var account = read_job.property (ACCOUNT_PROPERTY).value<unowned Account> ();
        //  Q_ASSERT (account);

        // Error or no valid public key error out
        if (read_job.error () != NoError || read_job.text_data ().length () == 0) {
            this.certificate = QSslCertificate ();
            this.public_key = QSslKey ();
            this.private_key = new GLib.ByteArray ();
            get_public_key_from_server (account);
            return;
        }

        this.mnemonic = read_job.text_data ();

        GLib.info ("Mnemonic key fetched from keychain: " + this.mnemonic);

        /* emit */ initialization_finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void get_private_key_from_server (unowned Account account) {
        GLib.info ("Retrieving private key from server.");
        var json_api_job = new JsonApiJob (account, E2EE_BASE_URL + "private-key", this);
        JsonApiJob.signal_json_received.connect ((json_api_job, doc, return_code) => {
            if (return_code == 200) {
                string key = doc.object ()["ocs"].to_object ()["data"].to_object ()["private-key"].to_string ();
                GLib.info (key);
                GLib.info ("Found private key, lets decrypt it!");
                decrypt_private_key (account, key.to_local8Bit ());
            } else if (return_code == 404) {
                GLib.info ("No private key on the server: setup is incomplete.");
            } else {
                GLib.info ("Error while requesting public key: " + return_code);
            }
        });
        json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void get_public_key_from_server (Account account) {
        GLib.info ("Retrieving public key from server.");
        var json_api_job = new JsonApiJob (account, E2EE_BASE_URL + "public-key", this);
        JsonApiJob.signal_json_received.connect ((json_api_job, doc, return_code) => {
                if (return_code == 200) {
                    string public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-keys"].to_object ()[account.dav_user ()].to_string ();
                    this.certificate = QSslCertificate (public_key.to_local8Bit (), QSsl.Pem);
                    this.public_key = this.certificate.public_key ();
                    GLib.info ("Found Public key, requesting Server Public Key. Public key: " + public_key);
                    fetch_and_validate_public_key_from_server (account);
                } else if (return_code == 404) {
                    GLib.info ("No public key on the server.");
                    generate_key_pair (account);
                } else {
                    GLib.info ("Error while requesting public key: " + return_code);
                }
        });
        json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void fetch_and_validate_public_key_from_server (Account account) {
        GLib.info ("Retrieving public key from server.");
        var json_api_job = new JsonApiJob (account, E2EE_BASE_URL + "server-key", this);
        JsonApiJob.signal_json_received.connect (
            (json_api_job, doc, return_code) => {
            if (return_code == 200) {
                var server_public_key = doc.object ()["ocs"].to_object ()["data"].to_object ()["public-key"].to_string ().to_latin1 ();
                GLib.info ("Found Server Public key, checking it. Server public key: " + server_public_key);
                if (check_server_public_key_validity (server_public_key)) {
                    if (this.private_key.is_empty ()) {
                        GLib.info ("Valid Server Public key, requesting Private Key.");
                        get_private_key_from_server (account);
                    } else {
                        GLib.info ("Certificate saved, Encrypting Private Key.");
                        encrypt_private_key (account);
                    }
                } else {
                    GLib.info ("Error invalid server public key.");
                    this.certificate = QSslCertificate ();
                    this.public_key = QSslKey ();
                    this.private_key = new GLib.ByteArray ();
                    get_public_key_from_server (account);
                    return;
                }
            } else {
                GLib.info ("Error while requesting server public key: " + return_code);
            }
        });
        json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void decrypt_private_key.for_account (unowned Account account, GLib.ByteArray key) {
        string message = _("Please enter your end to end encryption passphrase:<br>"
                        + "<br>"
                        + "User : %2<br>"
                        + "Account : %3<br>")
                        .arg (Utility.escape (account.credentials ().user ()),
                            Utility.escape (account.display_name ()));

        QInputDialog dialog;
        dialog.window_title (_("Enter E2E passphrase"));
        dialog.label_text (message);
        dialog.text_echo_mode (QLineEdit.Normal);

        string prev;

        while (true) {
            if (!prev.is_empty ()) {
                dialog.text_value (prev);
            }
            bool ok = dialog.exec ();
            if (ok) {
                GLib.info ("Got mnemonic: " + dialog.text_value ());
                prev = dialog.text_value ();

                this.mnemonic = prev;
                string[] split = prev.split (" ");
                string mnemonic = string.joinv ("", split).down ();
                GLib.info ("Mnemonic: " + mnemonic);

                // split off salt
                var salt = EncryptionHelper.extract_private_key_salt (key);

                var pass = EncryptionHelper.generate_password (mnemonic, salt);
                GLib.info ("Generated key: " + pass);

                GLib.ByteArray private_key = EncryptionHelper.decrypt_private_key (pass, key);
                //this.private_key = QSslKey (private_key, QSsl.Rsa, QSsl.Pem, QSsl.PrivateKey);
                this.private_key = private_key;

                GLib.info ("Private key: " + this.private_key.to_string ());

                if (!this.private_key.is_null () && check_public_key_validity (account)) {
                    write_private_key (account);
                    write_certificate (account);
                    write_mnemonic (account);
                    break;
                }
            } else {
                this.mnemonic = "";
                this.private_key = new GLib.ByteArray ();
                GLib.info ("Cancelled.");
                break;
            }
        }

        /* emit */ initialization_finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void fetch_from_key_chain (unowned Account account) {
        const string kck = AbstractCredentials.keychain_key (
                    account.url ().to_string (),
                    account.credentials ().user () + E2E_CERTIFICATE,
                    account.identifier ()
        );

        var read_password_job = new ReadPasswordJob (Theme.instance ().app_name ());
        read_password_job.property (ACCOUNT_PROPERTY, GLib.Variant.from_value (account));
        read_password_job.insecure_fallback (false);
        read_password_job.key (kck);
        connect (read_password_job, ReadPasswordJob.on_signal_finished, this, ClientSideEncryption.on_signal_public_key_fetched);
        read_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool check_public_key_validity (unowned Account account) {
        GLib.ByteArray data = EncryptionHelper.generate_random (64);

        Biometric public_key_bio;
        GLib.ByteArray public_key_pem = account.e2e ().public_key.to_pem ();
        BIO_write (public_key_bio, public_key_pem.const_data (), public_key_pem.size ());
        var public_key = PrivateKey.read_public_key (public_key_bio);

        var encrypted_data = EncryptionHelper.encrypt_string_asymmetric (public_key, data.to_base64 ());

        Biometric private_key_bio;
        GLib.ByteArray private_key_pem = account.e2e ().private_key;
        BIO_write (private_key_bio, private_key_pem.const_data (), private_key_pem.size ());
        var key = PrivateKey.read_private_key (private_key_bio);

        GLib.ByteArray decrypt_result = new GLib.ByteArray.from_base64 (EncryptionHelper.decrypt_string_asymmetric ( key, GLib.ByteArray.from_base64 (encrypted_data)));

        if (data != decrypt_result) {
            GLib.info ("Invalid private key.");
            return false;
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private bool check_server_public_key_validity (GLib.ByteArray server_public_key_string) {
        Biometric server_public_key_bio;
        BIO_write (server_public_key_bio, server_public_key_string.const_data (), server_public_key_string.size ());
        var server_public_key = PrivateKey.read_private_key (server_public_key_bio);

        Biometric certificate_bio;
        var certificate_pem = this.certificate.to_pem ();
        BIO_write (certificate_bio, certificate_pem.const_data (), certificate_pem.size ());
        var x509Certificate = X509Certificate.read_certificate (certificate_bio);
        if (!x509Certificate) {
            GLib.info ("Client certificate is invalid. Could not check it against the server public key.");
            return false;
        }

        if (X509_verify (x509Certificate, server_public_key) == 0) {
            GLib.info ("Client certificate is not valid against the server public key.");
            return false;
        }

        GLib.debug ("Client certificate is valid against server public key.");
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void write_private_key (unowned Account account) {
        const string kck = AbstractCredentials.keychain_key (
                    account.url ().to_string (),
                    account.credentials ().user () + E2E_PRIVATE,
                    account.identifier ()
        );

        var write_password_job = new WritePasswordJob (Theme.instance ().app_name ());
        write_password_job.insecure_fallback (false);
        write_password_job.key (kck);
        write_password_job.binary_data (this.private_key);
        WritePasswordJob.on_signal_finished.connect ((write_password_job, incoming) => {
            //  Q_UNUSED (incoming);
            GLib.info ("Private key stored in keychain.");
        });
        write_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void write_certificate (unowned Account account) {
        const string kck = AbstractCredentials.keychain_key (
                    account.url ().to_string (),
                    account.credentials ().user () + E2E_CERTIFICATE,
                    account.identifier ()
        );

        var write_password_job = new WritePasswordJob (Theme.instance ().app_name ());
        write_password_job.insecure_fallback (false);
        write_password_job.key (kck);
        write_password_job.binary_data (this.certificate.to_pem ());
        WritePasswordJob.on_signal_finished.connect ((write_password_job, incoming) => {
            //  Q_UNUSED (incoming);
            GLib.info ("Certificate stored in keychain.");
        });
        write_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void write_mnemonic (unowned Account account) {
        const string kck = AbstractCredentials.keychain_key (
            account.url ().to_string (),
            account.credentials ().user () + E2E_MNEMONIC,
            account.identifier ()
        );

        var write_password_job = new WritePasswordJob (Theme.instance ().app_name ());
        write_password_job.insecure_fallback (false);
        write_password_job.key (kck);
        write_password_job.text_data (this.mnemonic);
        WritePasswordJob.on_signal_finished.connect ((write_password_job, incoming) => {
            //  Q_UNUSED (incoming);
            GLib.info ("Mnemonic stored in keychain.");
        });
        write_password_job.on_signal_start ();
    }

    GLib.List<GLib.ByteArray> old_cipher_format_split (GLib.ByteArray cipher) {
        var separator = new GLib.ByteArray ("f_a=="); // BASE64 encoded '|'
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
        var is_old_format = !data.contains ("|");
        var parts = is_old_format ? old_cipher_format_split (data) : data.split ("|");
        GLib.info ("Found parts: " + parts + " Is old format? " + is_old_format);
        return parts;
    }

    uchar unsigned_data (GLib.ByteArray array) {
        return (uchar)array.data ();
    }

    //
    // Simple classes for safe (RAII) handling of OpenSSL
    // data structures
    //

    GLib.ByteArray BIO2Byte_array (Biometric b) {
        var pending = (int)BIO_ctrl_pending (b);
        GLib.ByteArray res = new GLib.ByteArray (pending, '\0');
        BIO_read (b, unsigned_data (res), pending);
        return res;
    }

    GLib.ByteArray handle_errors () {
        Biometric bio_errors;
        ERR_print_errors (bio_errors); // This line is not printing anything.
        return BIO2Byte_array (bio_errors);
    }

} // class ClientSideEncryption

} // namespace LibSync
} // namespace Occ
