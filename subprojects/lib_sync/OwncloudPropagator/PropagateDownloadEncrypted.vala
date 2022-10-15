namespace Occ {
namespace LibSync {


/***********************************************************
***********************************************************/
public class PropagateDownloadEncrypted { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private OwncloudPropagator propagator;
    private string local_parent_path;
    private unowned SyncFileItem item;
    private GLib.FileInfo info;
    private EncryptedFile encrypted_info;

    /***********************************************************
    ***********************************************************/
    public string error_string { public get; protected set; }


    internal signal void signal_file_metadata_found ();
    internal signal void signal_failed ();
    internal signal void decryption_finished ();


    /***********************************************************
    ***********************************************************/
    public PropagateDownloadEncrypted (OwncloudPropagator propagator, string local_parent_path, SyncFileItem item, GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
        //  this.propagator = propagator;
        //  this.local_parent_path = local_parent_path;
        //  this.item = item;
        //  this.info = this.item.file;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  var remote_filename = this.item.encrypted_filename == "" ? this.item.file : this.item.encrypted_filename;
        //  var remote_path = root_path + remote_filename;
        //  var remote_parent_path = remote_path.left (remote_path.last_index_of ("/"));

        //  // Is encrypted Now we need the folder-identifier
        //  var lscol_job = new LscolJob (this.propagator.account, remote_parent_path, this);
        //  lscol_job.properties (
        //      {
        //          "resourcetype",
        //          "http://owncloud.org/ns:fileid"
        //      }
        //  );
        //  lscol_job.signal_directory_listing_subfolders.connect (
        //      this.on_signal_check_folder_id
        //  );
        //  lscol_job.signal_finished_with_error.connect (
        //      this.on_signal_folder_id_error
        //  );
        //  lscol_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private string root_path {
        private get {
            string result = this.propagator.remote_path;
            if (result.has_prefix ("/")) {
                return result.mid (1);
            } else {
                return result;
            }
        }
    }


    /***********************************************************
    TODO: Fix this. Exported in the wrong place.
    ***********************************************************/
    //  public string create_download_temporary_filename (string previous);


    /***********************************************************
    ***********************************************************/
    public bool decrypt_file (GLib.File temporary_file) {
        //      string temporary_filename = create_download_temporary_filename (this.item.file + "_dec");
        //      GLib.debug ("Content Checksum Computed starting decryption" + temporary_filename);

        //      temporary_file.close ();
        //      GLib.File temporary_output = GLib.File.new_for_path (this.propagator.full_local_path (temporary_filename), this);
        //      EncryptionHelper.file_decryption (this.encrypted_info.encryption_key,
        //                                                                      this.encrypted_info.initialization_vector,
        //                                                                      temporary_file,
        //                                                                      this.temporary_output);

        //      GLib.debug ("Decryption on_signal_finished" + temporary_file.filename () + temporary_output.filename ());

        //      temporary_file.close ();
        //      this.temporary_output.close ();

        //      // we decripted the temporary into another temporary, so good bye old one
        //      if (!temporary_file.remove ()) {
        //              GLib.debug ("Failed to remove temporary file" + temporary_file.error_string);
        //              this.error_string = temporary_file.error_string;
        //              return false;
        //      }

        //      // Let's fool the rest of the logic into thinking this was the actual download
        //      temporary_file.filename (this.temporary_output.filename ());

        //      return true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_check_folder_id (GLib.List<string> list) {
        //  var lscol_job = (LscolJob)sender ();
        //  string folder_identifier = list.nth_data (0);
        //  GLib.debug ("Received identifier of folder" + folder_identifier);

        //  ExtraFolderInfo folder_info = lscol_job.folder_infos.value (folder_identifier);

        //  // Now that we have the folder-identifier we need it's JSON metadata
        //  var get_metadata_api_job = new GetMetadataApiJob (this.propagator.account, folder_info.file_identifier);
        //  get_metadata_api_job.signal_json_received.connect (
        //      this.on_signal_check_folder_encrypted_metadata
        //  );
        //  get_metadata_api_job.signal_error.connect (
        //      this.on_signal_folder_encrypted_metadata_error
        //  );

        //  get_metadata_api_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_check_folder_encrypted_metadata (GLib.JsonDocument json) {
        //  GLib.debug ("Metadata Received reading: "
        //             + this.item.instruction
        //             + this.item.file
        //             + this.item.encrypted_filename);
        //  string filename = this.info.filename ();
        //  var meta = new FolderMetadata (this.propagator.account, json.to_json (GLib.JsonDocument.Compact));
        //  GLib.List<EncryptedFile> files = meta.files ();

        //  string encrypted_filename = this.item.encrypted_filename.section ("/", -1);
        //  foreach (EncryptedFile file in files) {
        //      if (encrypted_filename == file.encrypted_filename) {
        //          this.encrypted_info = file;

        //          GLib.debug ("Found matching encrypted metadata for file, starting download.");
        //          signal_file_metadata_found ();
        //          return;
        //      }
        //  }

        //  signal_failed ();
        //  GLib.critical ("Failed to find encrypted metadata information of remote file " + filename);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_folder_id_error () {
        //  GLib.debug ("Failed to get encrypted metadata of folder.");
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_folder_encrypted_metadata_error (string file_identifier, int http_return_code) {
        //  GLib.critical ("Failed to find encrypted metadata information of remote file " + this.info.filename ());
        //  signal_failed ();
    }

} // class PropagateDownloadEncrypted

} // namespace LibSync
} // namespace Occ
