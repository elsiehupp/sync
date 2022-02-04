namespace Occ {

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

} // namespace Occ