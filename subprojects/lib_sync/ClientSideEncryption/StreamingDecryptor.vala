namespace Occ {
namespace LibSync {

/***********************************************************
@class StreamingDecryptor

Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
public class StreamingDecryptor { //: GLib.Object {

    //  Q_DISABLE_COPY (StreamingDecryptor)

    /***********************************************************
    ***********************************************************/
    private CipherContext context;
    bool is_initialized { public get; private set; }
    bool is_finished { public get; private set; }
    private uint64 decrypted_so_far = 0;
    private uint64 total_size = 0;

    /***********************************************************
    ***********************************************************/
    //  public StreamingDecryptor (string key, string iv, uint64 total_size) {
        //  this.is_finished = false;
    //  }

    public StreamingDecryptor (string key, string initialization_vector, uint64 total_size) {
        //  this.is_initialized = false;
        //  this.total_size = total_size;
        //  if (this.context != null && key != "" && initialization_vector != "" && total_size > 0) {
        //      this.is_initialized = true;

        //      // Initialize the decryption operation.
        //      if (!EVP_Decrypt_init_ex (this.context, EVP_aes_128_gcm (), null, null, null)) {
        //          GLib.critical ("Could not initialize cipher.");
        //          this.is_initialized = false;
        //      }

        //      EVP_CIPHER_CTX_padding (this.context, 0);

        //      // Set Initialization Vector length.
        //      if (!EVP_CIPHER_CTX_ctrl (this.context, EVP_CTRL_GCM_SET_IVLEN, initialization_vector.size (), null)) {
        //          GLib.critical ("Could not set initialization vector length.");
        //          this.is_initialized = false;
        //      }

        //      // Initialize key and Initialization Vector
        //      if (!EVP_Decrypt_init_ex (this.context, null, null, (uchar)key.const_data (), (uchar)initialization_vector.const_data ())) {
        //          GLib.critical ("Could not set key and initialization vector.");
        //          this.is_initialized = false;
        //      }
        //  }
    }

    public string chunk_decryption (GLib.InputStream input_stream, uint64 chunk_size) {
        //  string byte_array;
        //  Soup.Buffer buffer = new Soup.Buffer (byte_array);
        //  buffer.open (GLib.IODevice.WriteOnly);

        //  GLib.assert (this.is_initialized);
        //  if (!this.is_initialized) {
        //      GLib.critical ("Decryption failed. Decryptor is not initialized!");
        //      return "";
        //  }

        //  GLib.assert (buffer.is_open && buffer.is_writable ());
        //  if (!buffer.is_open || !buffer.is_writable ()) {
        //      GLib.critical ("Decryption failed. Incorrect output device!");
        //      return "";
        //  }

        //  GLib.assert (input_stream);
        //  if (input_stream == null) {
        //      GLib.critical ("Decryption failed. Incorrect input_stream!");
        //      return "";
        //  }

        //  GLib.assert (chunk_size > 0);
        //  if (chunk_size <= 0) {
        //      GLib.critical ("Decryption failed. Incorrect chunk_size!");
        //      return "";
        //  }

        //  if (this.decrypted_so_far == 0) {
        //      GLib.debug ("Decryption started");
        //  }

        //  GLib.assert (this.decrypted_so_far + chunk_size <= this.total_size);
        //  if (this.decrypted_so_far + chunk_size > this.total_size) {
        //      GLib.critical ("Decryption failed. Chunk is output of range!");
        //      return "";
        //  }

        //  GLib.assert (this.decrypted_so_far + chunk_size < Constants.E2EE_TAG_SIZE || this.total_size - Constants.E2EE_TAG_SIZE >= this.decrypted_so_far + chunk_size - Constants.E2EE_TAG_SIZE);
        //  if (this.decrypted_so_far + chunk_size > Constants.E2EE_TAG_SIZE && this.total_size - Constants.E2EE_TAG_SIZE < this.decrypted_so_far + chunk_size - Constants.E2EE_TAG_SIZE) {
        //      GLib.critical ("Decryption failed. Incorrect chunk!");
        //      return "";
        //  }

        //  bool is_last_chunk = this.decrypted_so_far + chunk_size == this.total_size;

        //  // last Constants.E2EE_TAG_SIZE bytes is ALWAYS a e2Ee_tag!!!
        //  int64 size = is_last_chunk ? chunk_size - Constants.E2EE_TAG_SIZE : chunk_size;

        //  // either the size is more than 0 and an e2Ee_tag is at the end of chunk, or, chunk is the e2Ee_tag itself
        //  GLib.assert (size > 0 || chunk_size == Constants.E2EE_TAG_SIZE);
        //  if (size <= 0 && chunk_size != Constants.E2EE_TAG_SIZE) {
        //      GLib.critical ("Decryption failed. Invalid input_stream size: " + size + " !");
        //      return "";
        //  }

        //  int64 bytes_written = 0;
        //  int64 input_pos = 0;

        //  string decrypted_block = new string (BLOCK_SIZE + Constants.E2EE_TAG_SIZE - 1, '\0');

        //  while (input_pos < size) {
        //      // read BLOCK_SIZE or less bytes
        //      string encrypted_block = new string (input_stream + input_pos, int64.min (size - input_pos, BLOCK_SIZE));

        //      if (encrypted_block.size () == 0) {
        //          GLib.critical ("Could not read data from the input_stream buffer.");
        //          return "";
        //      }

        //      int out_len = 0;

        //      if (!EVP_Decrypt_update (this.context, unsigned_data (decrypted_block), out_len, (uchar) (encrypted_block), encrypted_block.size ())) {
        //          GLib.critical ("Could not decrypt");
        //          return "";
        //      }

        //      var written_to_output = buffer.write (decrypted_block, out_len);

        //      GLib.assert (written_to_output == out_len);
        //      if (written_to_output != out_len) {
        //          GLib.critical ("Failed to write decrypted data to device.");
        //          return "";
        //      }

        //      bytes_written += written_to_output;

        //      // advance input_stream position for further read
        //      input_pos += encrypted_block.size ();

        //      this.decrypted_so_far += encrypted_block.size ();
        //  }

        //  if (is_last_chunk) {
        //      // if it's a last chunk, we'd need to read a e2Ee_tag at the end and on_signal_finalize the decryption

        //      GLib.assert (chunk_size - input_pos == Constants.E2EE_TAG_SIZE);
        //      if (chunk_size - input_pos != Constants.E2EE_TAG_SIZE) {
        //          GLib.critical ("Decryption failed. e2Ee_tag is missing!");
        //          return "";
        //      }

        //      int out_len = 0;

        //      string e2Ee_tag = new string (input_stream + input_pos, Constants.E2EE_TAG_SIZE);

        //      // Set expected e2Ee_tag value. Works in OpenSSL 1.0.1d and later
        //      if (!EVP_CIPHER_CTX_ctrl (this.context, EVP_CTRL_GCM_SET_TAG, e2Ee_tag.size (), (uchar)e2Ee_tag)) {
        //          GLib.critical ("Could not set expected e2Ee_tag.");
        //          return "";
        //      }

        //      if (1 != EVP_Decrypt_final_ex (this.context, unsigned_data (decrypted_block), out_len)) {
        //          GLib.critical ("Could finalize decryption.");
        //          return "";
        //      }

        //      var written_to_output = buffer.write (decrypted_block, out_len);

        //      GLib.assert (written_to_output == out_len);
        //      if (written_to_output != out_len) {
        //          GLib.critical ("Failed to write decrypted data to device.");
        //          return "";
        //      }

        //      bytes_written += written_to_output;

        //      this.decrypted_so_far += Constants.E2EE_TAG_SIZE;

        //      this.is_finished = true;
        //  }

        //  if (this.is_finished) {
        //      GLib.debug ("Decryption complete.");
        //  }

        //  return byte_array;
    }

} // class StreamingDecryptor

} // namespace LibSync
} // namespace Occ
