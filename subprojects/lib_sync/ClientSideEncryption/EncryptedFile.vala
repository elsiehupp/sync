namespace Occ {
namespace LibSync {

/***********************************************************
@class EncryptedFile

@brief Generates the Metadata for the folder
***********************************************************/
public class EncryptedFile { //: GLib.Object {

    public string encryption_key;
    public string mimetype;
    public string initialization_vector;
    public string authentication_tag;
    public string encrypted_filename;
    public string original_filename;
    public int file_version;
    public int metadata_key;

} // class EncryptedFile

} // namespace LibSync
} // namespace Occ