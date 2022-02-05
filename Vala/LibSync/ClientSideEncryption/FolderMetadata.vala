namespace Occ {

class FolderMetadata {

    /***********************************************************
    ***********************************************************/
    private GLib.Vector<EncryptedFile> files;
    private GLib.HashMap<int, GLib.ByteArray> metadata_keys;
    private AccountPointer account;
    private GLib.Vector<QPair<string, string>> sharing;


    /***********************************************************
    ***********************************************************/
    public FolderMetadata (AccountPointer account, GLib.ByteArray metadata = GLib.ByteArray (), int status_code = -1) {
        this.account = account;
        if (metadata.is_empty () || status_code == 404) {
            GLib.info (lc_cse_metadata ()) << "Setupping Empty Metadata";
            set_up_empty_metadata ();
        } else {
            GLib.info (lc_cse_metadata ()) << "Setting up existing metadata";
            set_up_existing_metadata (metadata);
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray decrypt_metadata_key (GLib.ByteArray encrypted_metadata) {
        Biometric private_key_bio;
        GLib.ByteArray private_key_pem = this.account.e2e ().private_key;
        BIO_write (private_key_bio, private_key_pem.const_data (), private_key_pem.size ());
        var key = PrivateKey.read_private_key (private_key_bio);

        // Also base64 decode the result
        GLib.ByteArray decrypt_result = EncryptionHelper.decrypt_string_asymmetric (
                        key, GLib.ByteArray.from_base64 (encrypted_metadata));

        if (decrypt_result.is_empty ()) {
        GLib.debug (lc_cse ()) << "ERROR. Could not decrypt the metadata key";
        return {};
        }
        return GLib.ByteArray.from_base64 (decrypt_result);
    }


    /***********************************************************
    ***********************************************************/
    public void add_encrypted_file (EncryptedFile f) {

        for (int i = 0; i < this.files.size (); i++) {
            if (this.files.at (i).original_filename == f.original_filename) {
                this.files.remove_at (i);
                break;
            }
        }

        this.files.append (f);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray encrypted_metadata () {
        GLib.debug (lc_cse) << "Generating metadata";

        QJsonObject metadata_keys;
        for (var it = this.metadata_keys.const_begin (), end = this.metadata_keys.const_end (); it != end; it++) {
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
        for (var it = this.sharing.const_begin (), end = this.sharing.const_end (); it != end; it++) {
            recepients.insert (it.first, it.second);
        }
        QJsonDocument recepient_doc;
        recepient_doc.set_object (recepients);
        string sharing_encrypted = encrypt_json_object (recepient_doc.to_json (QJsonDocument.Compact), this.metadata_keys.last ());
        ***********************************************************/

        QJsonObject metadata = {
            {"metadata_keys", metadata_keys},
            {"sharing", sharing_encrypted},
            {"version", 1}
        };

        QJsonObject files;
        for (var it = this.files.const_begin (), end = this.files.const_end (); it != end; it++) {
            QJsonObject encrypted;
            encrypted.insert ("key", string (it.encryption_key.to_base64 ()));
            encrypted.insert ("filename", it.original_filename);
            encrypted.insert ("mimetype", string (it.mimetype));
            encrypted.insert ("version", it.file_version);
            QJsonDocument encrypted_doc;
            encrypted_doc.set_object (encrypted);

            string encrypted_encrypted = encrypt_json_object (encrypted_doc.to_json (QJsonDocument.Compact), this.metadata_keys.last ());
            if (encrypted_encrypted.is_empty ()) {
            GLib.debug (lc_cse) << "Metadata generation failed!";
            }

            QJsonObject file;
            file.insert ("encrypted", encrypted_encrypted);
            file.insert ("initialization_vector", string (it.initialization_vector.to_base64 ()));
            file.insert ("authentication_tag", string (it.authentication_tag.to_base64 ()));
            file.insert ("metadata_key", this.metadata_keys.last_key ());

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


    /***********************************************************
    ***********************************************************/
    public void remove_encrypted_file (EncryptedFile f) {
        for (int i = 0; i < this.files.size (); i++) {
            if (this.files.at (i).original_filename == f.original_filename) {
                this.files.remove_at (i);
                break;
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void remove_all_encrypted_files () {
        this.files.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Vector<EncryptedFile> files () {
        return this.files;
    }


    /***********************************************************
    Use std.string and GLib.Vector internally on this class
    to ease the port to Nlohmann Json API
    ***********************************************************/
    private void set_up_empty_metadata () {
        GLib.debug (lc_cse) << "Settint up empty metadata";
        GLib.ByteArray new_metadata_pass = EncryptionHelper.generate_random (16);
        this.metadata_keys.insert (0, new_metadata_pass);

        string public_key = this.account.e2e ().public_key.to_pem ().to_base64 ();
        string display_name = this.account.display_name ();

        this.sharing.append ({display_name, public_key});
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_existing_metadata (GLib.ByteArray metadata) {
        /***********************************************************
        This is the json response from the server, it contains two extra objects that we are not* interested.
        * ocs and data.
        */
        QJsonDocument doc = QJsonDocument.from_json (metadata);
        GLib.info (lc_cse_metadata ()) << doc.to_json (QJsonDocument.Compact);

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
        GLib.debug (lc_cse) << "Keys : " << debug_helper.to_json (QJsonDocument.Compact);

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
            GLib.debug (lc_cse ()) << "Could not decrypt metadata for key" << it.key ();
            continue;
            }

            GLib.ByteArray decrypted_key = GLib.ByteArray.from_base64 (b64Decrypted_key);
            this.metadata_keys.insert (it.key ().to_int (), decrypted_key);
        }

        // Cool, We actually have the key, we can decrypt the rest of the metadata.
        GLib.debug (lc_cse) << "Sharing : " << sharing;
        if (sharing.size ()) {
            var sharing_decrypted = decrypt_json_object (sharing, this.metadata_keys.last ());
            GLib.debug (lc_cse) << "Sharing Decrypted" << sharing_decrypted;

            //Sharing is also a JSON object, so extract it and populate.
            var sharing_doc = QJsonDocument.from_json (sharing_decrypted);
            var sharing_obj = sharing_doc.object ();
            for (var it = sharing_obj.const_begin (), end = sharing_obj.const_end (); it != end; it++) {
                this.sharing.push_back ({it.key (), it.value ().to_string ()});
            }
        } else {
            GLib.debug (lc_cse) << "Skipping sharing section since it is empty";
        }

        for (var it = files.const_begin (), end = files.const_end (); it != end; it++) {
            EncryptedFile file;
            file.encrypted_filename = it.key ();

            var file_obj = it.value ().to_object ();
            file.metadata_key = file_obj["metadata_key"].to_int ();
            file.authentication_tag = GLib.ByteArray.from_base64 (file_obj["authentication_tag"].to_string ().to_local8Bit ());
            file.initialization_vector = GLib.ByteArray.from_base64 (file_obj["initialization_vector"].to_string ().to_local8Bit ());

            //Decrypt encrypted part
            GLib.ByteArray key = this.metadata_keys[file.metadata_key];
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

            this.files.push_back (file);
        }
    }


    /***********************************************************
    RSA/ECB/OAEPWithSHA-256AndMGF1Padding using private / public key.
    ***********************************************************/
    private GLib.ByteArray encrypt_metadata_key (GLib.ByteArray data) {
        Biometric public_key_bio;
        GLib.ByteArray public_key_pem = this.account.e2e ().public_key.to_pem ();
        BIO_write (public_key_bio, public_key_pem.const_data (), public_key_pem.size ());
        var public_key = PrivateKey.read_public_key (public_key_bio);

        // The metadata key is binary so base64 encode it first
        return EncryptionHelper.encrypt_string_asymmetric (public_key, data.to_base64 ());
    }


    /***********************************************************
    AES/GCM/No_padding (128 bit key size)
    ***********************************************************/
    private GLib.ByteArray encrypt_json_object (GLib.ByteArray obj, GLib.ByteArray pass) {
        return EncryptionHelper.encrypt_string_symmetric (pass, obj);
    }


    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray decrypt_json_object (GLib.ByteArray encrypted_metadata, GLib.ByteArray pass) {
        return EncryptionHelper.decrypt_string_symmetric (pass, encrypted_metadata);
    }

} // class FolderMetadata

} // namespace Occ
