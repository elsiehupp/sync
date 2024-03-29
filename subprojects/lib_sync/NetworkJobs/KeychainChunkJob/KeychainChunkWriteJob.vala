namespace Occ {
namespace LibSync {

/***********************************************************
@class KeychainChunkWriteJob

@brief Simple wrapper class for Secret.Collection.WritePasswordJob,
splits too large keychain entry's data into chunks on Windows

@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/
public class KeychainChunkWriteJob : AbstractKeychainChunkJob {

    internal signal void signal_finished (KeychainChunkWriteJob incoming_job);

    /***********************************************************
    KeychainChunkWriteJob
    ***********************************************************/
    public KeychainChunkWriteJob.for_account (Account account, string key, string data) {
        //  base ();
        //  this.account = account;
        //  this.key = key;

        //  // Windows workaround : Split the private key into chunks of 2048 bytes,
        //  // to allow 4k (4096 bit) keys to be saved (obey Windows's limits)
        //  this.chunk_buffer = data;
        //  this.chunk_count = 0;
    }

    /***********************************************************
    ***********************************************************/
    public KeychainChunkWriteJob (string key, string data) {
        //  base (null, key, data);
    }


    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the signal_finished () signal first.

    @see Secret.Collection.Job.start ()
    ***********************************************************/
    public new void start () {
        //  this.error = Secret.Collection.NoError;

        //  on_signal_write_job_done (null);
    }


    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the signal_finished () signal first.

    @return Returns true on succeess (Secret.Collection.NoError).
    ***********************************************************/
    public bool exec () {
        //  start ();

        //  GLib.MainLoop wait_loop;
        //  this.signal_finished.connect (
        //      wait_loop.quit
        //  );
        //  wait_loop.exec ();

        //  if (this.error != NoError) {
        //      GLib.warning ("WritePasswordJob failed with" + this.error_string);
        //      return false;
        //  }

        //  return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_job_done (Secret.Collection.Job incoming_job) {
        //  var write_job = (Secret.Collection.WritePasswordJob)incoming_job;

        //  // Errors? (write_job can be null here, see : KeychainChunkWriteJob.start)
        //  if (write_job) {
        //      this.error = write_job.error;
        //      this.error_string = write_job.error_string;

        //      if (write_job.error != NoError) {
        //          GLib.warning ("Error while writing " + write_job.key () + " chunk " + write_job.error_string);
        //          this.chunk_buffer = "";
        //      }
        //  }

        //  // write a chunk if there is any in the buffer
        //  if (!this.chunk_buffer == "") {
        //      // write full data in one chunk on non-Windows, as usual
        //      var chunk = this.chunk_buffer;

        //      this.chunk_buffer = "";

        //      var index = (this.chunk_count++);

        //      // keep the limit
        //      if (this.chunk_count > MaxChunks) {
        //          GLib.warning ("Maximum chunk count exceeded while writing " + write_job.key () + " chunk " + index + " cutting off after " + MaxChunks.to_string () + " chunks.");

        //          write_job.delete_later ();

        //          this.chunk_buffer = "";

        //          signal_finished (this);

        //          if (this.auto_delete) {
        //              delete_later ();
        //          }
        //          return;
        //      }

        //      string key_with_index = this.key + (index > 0) ? "." + index.to_string () : "";
        //      string keychain_key = this.account ? AbstractCredentials.keychain_key (
        //              this.account.url.to_string (),
        //              key_with_index,
        //              this.account.identifier
        //          ) : key_with_index;

        //      var qkeychain_write_password_job = new Secret.Collection.WritePasswordJob (this.service_name, this);
    // #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        //      add_settings_to_job (this.account, qkeychain_write_password_job);
    // #endif
        //      qkeychain_write_password_job.insecure_fallback (this.insecure_fallback);
        //      qkeychain_write_password_job.signal_finished.connect (
        //          this.on_signal_write_job_done
        //      );
        //      // only add the key's (sub)"index" after the first element, to stay compatible with older versions and non-Windows
        //      qkeychain_write_password_job.key (keychain_key);
        //      qkeychain_write_password_job.binary_data (chunk);
        //      qkeychain_write_password_job.start ();

        //      chunk = "";
        //  } else {
        //      signal_finished (this);

        //      if (this.auto_delete) {
        //          delete_later ();
        //      }
        //  }

        //  write_job.delete_later ();
    }

} // class KeychainChunkWriteJob

} // namespace LibSync
} // namespace Occ
