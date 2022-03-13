namespace Occ {
namespace LibSync {
    
/***********************************************************
Generates the Metadata for the folder
***********************************************************/
public class EncryptedFile : GLib.Object {
    GLib.ByteArray encryption_key;
    GLib.ByteArray mimetype;
    GLib.ByteArray initialization_vector;
    GLib.ByteArray authentication_tag;
    string encrypted_filename;
    string original_filename;
    int file_version;
    int metadata_key;
}

} // namespace LibSync
} // namespace Occ