namespace Occ {
namespace LibSync {

/***********************************************************
@brief Simple wrapper class for QKeychain.ReadPasswordJob,
splits too large keychain entry's data into chunks on Windows

@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/
public class KeychainChunkReadJob : KeychainChunkJob {

    /***********************************************************
    true if we haven't done yet any reading from keychain
    ***********************************************************/
    private bool retry_on_signal_key_chain_error = true;

    internal signal void signal_finished (KeychainChunkReadJob incoming_job);

    /***********************************************************
    ***********************************************************/
    public ReadJob.for_account (Account account, string key, bool keychain_migration, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
        this.key = key;

        this.keychain_migration = keychain_migration;

        this.chunk_count = 0;
        this.chunk_buffer.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public ReadJob (string key, GLib.Object parent = new GLib.Object ()) {
        base (null, key, false, parent);
    }


    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the signal_finished () signal first.

    @see QKeychain.Job.start ()
    ***********************************************************/
    public new void start () {
        this.chunk_count = 0;
        this.chunk_buffer.clear ();
        this.error = QKeychain.NoError;

        const string keychain_key = this.account ? AbstractCredentials.keychain_key (
                this.account.url.to_string (),
                this.key,
                this.keychain_migration ? "" : this.account.identifier
            ) : this.key;

        var qkeychain_read_password_job = new QKeychain.ReadPasswordJob (this.service_name, this);
    // #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (this.account, qkeychain_read_password_job);
    // #endif
        qkeychain_read_password_job.insecure_fallback (this.insecure_fallback);
        qkeychain_read_password_job.key (keychain_key);
        qkeychain_read_password_job.signal_finished.connect (
            this.on_signal_read_job_done
        );
        qkeychain_read_password_job.start ();
    }


    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the signal_finished () signal first.

    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    public bool exec () {
        start ();

        QEventLoop wait_loop;
        this.signal_finished.connect (
            wait_loop.quit
        );
        wait_loop.exec ();

        if (this.error == NoError) {
            return true;
        }

        this.chunk_count = 0;
        this.chunk_buffer.clear ();
        if (this.error != EntryNotFound) {
            GLib.warning ("ReadPasswordJob failed with " + this.error_string);
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_job_done (QKeychain.Job incoming_job) {
        // Errors or next chunk?
        var read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming_job);
        GLib.assert (read_job);

        if (read_job.error == NoError && !read_job.binary_data () == "") {
            this.chunk_buffer.append (read_job.binary_data ());
            this.chunk_count++;
        } else {
            if (!read_job.insecure_fallback ()) { // If insecure_fallback is set, the next test would be pointless
                if (this.retry_on_signal_key_chain_error && (read_job.error == QKeychain.NoBackendAvailable
                        || read_job.error == QKeychain.OtherError)) {
                    // Could be that the backend was not yet available. Wait some extra seconds.
                    // (Issues #4274 and #6522)
                    // (For kwallet, the error is OtherError instead of NoBackendAvailable, maybe a bug in QtKeychain)
                    GLib.info ("Backend unavailable (yet?) Retrying in a few seconds. " + read_job.error_string);
                    GLib.Timeout.single_shot (10000, this, ReadJob.start);
                    this.retry_on_signal_key_chain_error = false;
                    read_job.delete_later ();
                    return;
                }
                this.retry_on_signal_key_chain_error = false;
            }
            if (read_job.error != QKeychain.EntryNotFound ||
                ( (read_job.error == QKeychain.EntryNotFound) && this.chunk_count == 0)) {
                this.error = read_job.error;
                this.error_string = read_job.error_string;
                GLib.warning ("Unable to read " + read_job.key () + " chunk " + string.number (this.chunk_count) + read_job.error_string);
            }
        }

        read_job.delete_later ();

        /* emit */ signal_finished (this);

        if (this.auto_delete) {
            delete_later ();
        }
    }

} // class ReadJob

} // namespace LibSync
} // namespace Occ
