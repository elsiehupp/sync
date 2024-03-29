namespace Occ {
namespace LibSync {

/***********************************************************
@class FolderMetadata
***********************************************************/
public class FolderMetadata { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public GLib.List<EncryptedFile> files { public get; private set; }

    private GLib.HashTable<int, string> metadata_keys;
    private unowned Account account;
    private GLib.List<GLib.Pair<string, string>> sharing;


    /***********************************************************
    ***********************************************************/
    public FolderMetadata.for_account (Account account, string metadata = "", int status_code = -1) {
        //  this.account = account;
        //  if (metadata == "" || status_code == 404) {
        //      GLib.info ("Setting up empty metadata.");
        //      up_empty_metadata ();
        //  } else {
        //      GLib.info ("Setting up existing metadata.");
        //      up_existing_metadata (metadata);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public string decrypt_metadata_key (string encrypted_metadata) {
        //  Biometric private_key_bio;
        //  string private_key_pem = this.account.e2e.private_key;
        //  BIO_write (private_key_bio, private_key_pem.const_data (), private_key_pem.size ());
        //  var key = PrivateKey.read_private_key (private_key_bio);

        //  // Also base64 decode the result
        //  string decrypt_result = EncryptionHelper.decrypt_string_asymmetric (
        //                  key, string.from_base64 (encrypted_metadata));

        //  if (decrypt_result == "") {
        //  GLib.debug ("ERROR. Could not decrypt the metadata key.");
        //  return "";
        //  }
        //  return string.from_base64 (decrypt_result);
    }


    /***********************************************************
    ***********************************************************/
    public void add_encrypted_file (EncryptedFile encrypted_file) {

        //  for (int i = 0; i < this.files.size (); i++) {
        //      if (this.files.at (i).original_filename == encrypted_file.original_filename) {
        //          this.files.remove_at (i);
        //          break;
        //      }
        //  }

        //  this.files.append (encrypted_file);
    }


    /***********************************************************
    ***********************************************************/
    public string encrypted_metadata () {
        //  GLib.debug ("Generating metadata.");

        //  Json.Object metadata_keys;
        //  foreach (var key in this.metadata_keys) {
        //      /***********************************************************
        //      We have to already base64 encode the metadatakey here. This was a misunderstanding in the RFC
        //      Now we should be compatible with Android and IOS. Maybe we can fix it later.
        //      ***********************************************************/
        //      string encrypted_key = encrypt_metadata_key (it.value ().to_base64 ());
        //      metadata_keys.insert (key.key ().to_string (), encrypted_key);
        //  }


        //  /***********************************************************
        //  NO SHARING IN V1
        //  Json.Object recepients;
        //  for (var it = this.sharing.const_begin (), end = this.sharing.const_end (); it != end; it++) {
        //      recepients.insert (it.first, it.second);
        //  }
        //  GLib.JsonDocument recepient_doc;
        //  recepient_doc.object (recepients);
        //  string sharing_encrypted = encrypt_json_object (recepient_doc.to_json (GLib.JsonDocument.Compact), this.metadata_keys.last ());
        //  ***********************************************************/

        //  Json.Object metadata = new Json.Object (
        //      {
        //          "metadata_keys",
        //          metadata_keys
        //      },
        //      {
        //          "sharing",
        //          sharing_encrypted
        //      },
        //      {
        //          "version",
        //          1
        //      }
        //  );

        //  Json.Object files;
        //  foreach (var each_file in this.files) {
        //      Json.Object encrypted;
        //      encrypted.insert ("key", each_file.encryption_key.to_base64 ().to_string ());
        //      encrypted.insert ("filename", each_file.original_filename);
        //      encrypted.insert ("mimetype", each_file.mimetype.to_string ());
        //      encrypted.insert ("version", each_file.file_version);
        //      GLib.JsonDocument encrypted_doc;
        //      encrypted_doc.object (encrypted);

        //      string encrypted_encrypted = encrypt_json_object (encrypted_doc.to_json (GLib.JsonDocument.Compact), this.metadata_keys.last ());
        //      if (encrypted_encrypted == "") {
        //          GLib.debug ("Metadata generation failed!");
        //      }

        //      Json.Object file;
        //      file.insert ("encrypted", encrypted_encrypted);
        //      file.insert ("initialization_vector", each_file.initialization_vector.to_base64 ().to_string ());
        //      file.insert ("authentication_tag", each_file.authentication_tag.to_base64 ().to_string ());
        //      file.insert ("metadata_key", this.metadata_keys.last_key ());

        //      files.insert (it.encrypted_filename, file);
        //  }

        //  Json.Object meta_object = new Json.Object (
        //      {
        //          "metadata",
        //          metadata
        //      },
        //      {
        //          "files",
        //          files
        //      }
        //  );

        //  GLib.JsonDocument internal_metadata;
        //  internal_metadata.object (meta_object);
        //  return internal_metadata.to_json ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_encrypted_file (EncryptedFile encrypted_file) {
        //  foreach (var file in this.files) {
        //      if (file.original_filename == encrypted_file.original_filename) {
        //          this.files.remove (file);
        //          break;
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void remove_all_encrypted_files () {
        //  foreach(var file in this.files) {
        //      this.files.remove (file);
        //  }
    }


    /***********************************************************
    Use string and GLib.List internally on this class
    to ease the port to Nlohmann Json API
    ***********************************************************/
    private void up_empty_metadata () {
        //  GLib.debug ("Setting up empty metadata.");
        //  string new_metadata_pass = EncryptionHelper.generate_random (16);
        //  this.metadata_keys.insert (0, new_metadata_pass);

        //  string public_key = this.account.e2e.public_key.to_pem ().to_base64 ();
        //  string display_name = this.account.display_name;

        //  this.sharing.append ({display_name, public_key});
    }


    /***********************************************************
    ***********************************************************/
    private void up_existing_metadata (string metadata) {
        //  /***********************************************************
        //  This is the json response from the server, it contains two
        //  extra objects that we are *not* interested in, ocs and data.
        //  ***********************************************************/
        //  GLib.JsonDocument doc = GLib.JsonDocument.from_json (metadata);
        //  GLib.info (doc.to_json (GLib.JsonDocument.Compact));

        //  // The metadata is being retrieved as a string stored in a json.
        //  // This seems* to be broken but the RFC doesn't explicits how it wants.
        //  // I'm currently unsure if this is error on my side or in the server implementation.
        //  // And because inside of the meta-data there's an object called metadata, without '-'
        //  // make it really different.

        //  string meta_data_str = doc.object ()["ocs"]
        //                          .to_object ()["data"]
        //                          .to_object ()["meta-data"]
        //                          .to_string ();

        //  GLib.JsonDocument meta_data_doc = GLib.JsonDocument.from_json (meta_data_str.to_local8Bit ());
        //  Json.Object metadata_obj = meta_data_doc.object ()["metadata"].to_object ();
        //  Json.Object metadata_keys = metadata_obj["metadata_keys"].to_object ();
        //  string sharing = metadata_obj["sharing"].to_string ().to_local8Bit ();
        //  Json.Object files = meta_data_doc.object ()["files"].to_object ();

        //  GLib.JsonDocument debug_helper;
        //  debug_helper.object (metadata_keys);
        //  GLib.debug ("Keys: " + debug_helper.to_json (GLib.JsonDocument.Compact));

        //  // Iterate over the document to store the keys. I'm unsure that the keys are in order,
        //  // perhaps it's better to store a map instead of a vector, perhaps this just doesn't matter.
        //  for (var it = metadata_keys.const_begin (), end = metadata_keys.const_end (); it != end; it++) {
        //      string curr_b64Pass = it.value ().to_string ().to_local8Bit ();
        //      /***********************************************************
        //      We have to base64 decode the metadatakey here. This was a misunderstanding in the RFC
        //      Now we should be compatible with Android and IOS. Maybe we can fix it later.
        //      ***********************************************************/
        //      string b64Decrypted_key = decrypt_metadata_key (curr_b64Pass);
        //      if (b64Decrypted_key == "") {
        //          GLib.debug ("Could not decrypt metadata for key " + it.key ());
        //          continue;
        //      }

        //      string decrypted_key = new string.from_base64 (b64Decrypted_key);
        //      this.metadata_keys.insert (it.key ().to_int (), decrypted_key);
        //  }

        //  // Cool, We actually have the key, we can decrypt the rest of the metadata.
        //  GLib.debug ("Sharing: " + sharing);
        //  if (sharing.size ()) {
        //      var sharing_decrypted = decrypt_json_object (sharing, this.metadata_keys.last ());
        //      GLib.debug ("Sharing Decrypted " + sharing_decrypted);

        //      //  Sharing is also a JSON object, so extract it and populate.
        //      var sharing_doc = GLib.JsonDocument.from_json (sharing_decrypted);
        //      var sharing_obj = sharing_doc.object ();
        //      for (var it = sharing_obj.const_begin (), end = sharing_obj.const_end (); it != end; it++) {
        //          this.sharing.push_back ({it.key (), it.value ().to_string ()});
        //      }
        //  } else {
        //      GLib.debug ("Skipping sharing section since it is empty.");
        //  }

        //  for (var it = files.const_begin (), end = files.const_end (); it != end; it++) {
        //      EncryptedFile file;
        //      file.encrypted_filename = it.key ();

        //      var file_obj = it.value ().to_object ();
        //      file.metadata_key = file_obj["metadata_key"].to_int ();
        //      file.authentication_tag = new string.from_base64 (file_obj["authentication_tag"].to_string ().to_local8Bit ());
        //      file.initialization_vector = new string.from_base64 (file_obj["initialization_vector"].to_string ().to_local8Bit ());

        //      //  Decrypt encrypted part
        //      string key = this.metadata_keys[file.metadata_key];
        //      var encrypted_file = file_obj["encrypted"].to_string ().to_local8Bit ();
        //      var decrypted_file = decrypt_json_object (encrypted_file, key);
        //      var decrypted_file_doc = GLib.JsonDocument.from_json (decrypted_file);
        //      var decrypted_file_obj = decrypted_file_doc.object ();

        //      file.original_filename = decrypted_file_obj["filename"].to_string ();
        //      file.encryption_key = new string.from_base64 (decrypted_file_obj["key"].to_string ().to_local8Bit ());
        //      file.mimetype = decrypted_file_obj["mimetype"].to_string ().to_local8Bit ();
        //      file.file_version = decrypted_file_obj["version"].to_int ();

        //      // In case we wrongly stored "inode/directory" we try to recover from it
        //      if (file.mimetype == "inode/directory") {
        //          file.mimetype = "httpd/unix-directory";
        //      }

        //      this.files.push_back (file);
        //  }
    }


    /***********************************************************
    RSA/ECB/OAEPWithSHA-256AndMGF1Padding using private / public key.
    ***********************************************************/
    private string encrypt_metadata_key (string data) {
        //  Biometric public_key_bio;
        //  string public_key_pem = this.account.e2e.public_key.to_pem ();
        //  BIO_write (public_key_bio, public_key_pem.const_data (), public_key_pem.size ());
        //  var public_key = PrivateKey.read_public_key (public_key_bio);

        //  // The metadata key is binary so base64 encode it first
        //  return EncryptionHelper.encrypt_string_asymmetric (public_key, data.to_base64 ());
    }


    /***********************************************************
    AES/GCM/No_padding (128 bit key size)
    ***********************************************************/
    private string encrypt_json_object (string object, string pass) {
        //  return EncryptionHelper.encrypt_string_symmetric (pass, object);
    }


    /***********************************************************
    ***********************************************************/
    private string decrypt_json_object (string encrypted_metadata, string pass) {
        //  return EncryptionHelper.decrypt_string_symmetric (pass, encrypted_metadata);
    }

} // class FolderMetadata

} // namespace LibSync
} // namespace Occ
