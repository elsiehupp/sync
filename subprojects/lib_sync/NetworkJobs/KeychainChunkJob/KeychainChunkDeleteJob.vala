namespace Occ {
namespace LibSync {

/***********************************************************
@class KeychainChunkDeleteJob

@brief Simple wrapper class for Secret.Collection.DeletePasswordJob

@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/
public class KeychainChunkDeleteJob : AbstractKeychainChunkJob {

    internal signal void signal_finished (KeychainChunkDeleteJob incoming_job);

    /***********************************************************
    ***********************************************************/
    public KeychainChunkDeleteJob.for_account (Account account, string key, bool keychain_migration) {
        //  base ();
        //  this.account = account;
        //  this.key = key;

        //  this.keychain_migration = keychain_migration;
    }


    /***********************************************************
    ***********************************************************/
    public KeychainChunkDeleteJob (string key) {
        //  base (null, key, false);
    }


    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the signal_finished () signal first.

    @see Secret.Collection.Job.start ()
    ***********************************************************/
    public new void start () {
        //  this.chunk_count = 0;
        //  this.error = Secret.Collection.NoError;

        //  string keychain_key = this.account != null
        //      ? AbstractCredentials.keychain_key (
        //          this.account.url.to_string (),
        //          this.key,
        //          this.keychain_migration ? "" : this.account.identifier
        //      ) : this.key;

        //  var qkeychain_delete_password_job = new Secret.Collection.DeletePasswordJob (this.service_name, this);
    // #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        //  add_settings_to_job (this.account, qkeychain_delete_password_job);
    // #endif
        //  qkeychain_delete_password_job.insecure_fallback (this.insecure_fallback);
        //  qkeychain_delete_password_job.key (keychain_key);
        //  qkeychain_delete_password_job.signal_finished.connect (
        //      this.on_signal_delete_job_done
        //  );
        //  qkeychain_delete_password_job.start ();
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

        //  if (this.error == NoError) {
        //      return true;
        //  }

        //  this.chunk_count = 0;
        //  if (this.error != EntryNotFound) {
        //      GLib.warning ("DeletePasswordJob failed with " + this.error_string);
        //  }
        //  return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_done (Secret.Collection.Job incoming_job) {
        //  // Errors or next chunk?
        //  var delete_job = Secret.Collection.DeletePasswordJob)incoming_job;
        //  GLib.assert (delete_job);

        //  if (delete_job.error == NoError) {
        //      this.chunk_count++;
        //  } else {
        //      if (delete_job.error != Secret.Collection.EntryNotFound ||
        //          ( (delete_job.error == Secret.Collection.EntryNotFound) && this.chunk_count == 0)) {
        //          this.error = delete_job.error;
        //          this.error_string = delete_job.error_string;
        //          GLib.warning ("Unable to delete " + delete_job.key () + " chunk " + this.chunk_count + delete_job.error_string);
        //      }
        //  }

        //  delete_job.delete_later ();

        //  signal_finished (this);

        //  if (this.auto_delete) {
        //      delete_later ();
        //  }
    }

} // class KeychainChunkDeleteJob

} // namespace LibSync
} // namespace Occ
