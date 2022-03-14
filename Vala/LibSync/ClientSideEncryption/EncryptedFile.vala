namespace Occ {
namespace LibSync {
    
/***********************************************************
Generates the Metadata for the folder
***********************************************************/
public class EncryptedFile : GLib.Object {
    string encryption_key;
    string mimetype;
    string initialization_vector;
    string authentication_tag;
    string encrypted_filename;
    string original_filename;
    int file_version;
    int metadata_key;
}

} // namespace LibSync
} // namespace Occ