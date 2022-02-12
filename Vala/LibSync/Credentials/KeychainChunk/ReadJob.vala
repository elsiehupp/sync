/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace KeychainChunk {

/***********************************************************
@brief : Simple wrapper class for QKeychain.ReadPasswordJob,
splits too large keychain entry's data into chunks on Windows
***********************************************************/
class ReadJob : KeychainChunk.Job {

    /***********************************************************
    true if we haven't done yet any reading from keychain
    ***********************************************************/
    private bool retry_on_signal_key_chain_error = true;

    signal void signal_finished (KeychainChunk.ReadJob incoming_job);

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
    Call this method to on_signal_start the job (async).
    You should connect some slot to the signal_finished () signal first.

    @see QKeychain.Job.on_signal_start ()
    ***********************************************************/
    public void on_signal_start () {
        this.chunk_count = 0;
        this.chunk_buffer.clear ();
        this.error = QKeychain.NoError;

        const string kck = this.account ? AbstractCredentials.keychain_key (
                this.account.url ().to_string (),
                this.key,
                this.keychain_migration ? "" : this.account.identifier ()
            ) : this.key;

        var job = new QKeychain.ReadPasswordJob (this.service_name, this);
    // #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (this.account, job);
    // #endif
        job.insecure_fallback (this.insecure_fallback);
        job.key (kck);
        connect (job, QKeychain.Job.on_signal_finished, this, KeychainChunk.ReadJob.on_signal_read_job_done);
        job.on_signal_start ();
    }


    /***********************************************************
    Call this method to on_signal_start the job synchronously.
    Awaits completion with no need to connect some slot to the signal_finished () signal first.

    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    public bool exec () {
        on_signal_start ();

        QEventLoop wait_loop;
        connect (this, ReadJob.on_signal_finished, wait_loop, QEventLoop.quit);
        wait_loop.exec ();

        if (error () == NoError) {
            return true;
        }

        this.chunk_count = 0;
        this.chunk_buffer.clear ();
        if (error () != EntryNotFound) {
            GLib.warning ("ReadPasswordJob failed with " + error_string ());
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_job_done (QKeychain.Job incoming_job) {
        // Errors or next chunk?
        var read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming_job);
        //  Q_ASSERT (read_job);

        if (read_job.error () == NoError && !read_job.binary_data ().is_empty ()) {
            this.chunk_buffer.append (read_job.binary_data ());
            this.chunk_count++;
        } else {
            if (!read_job.insecure_fallback ()) { // If insecure_fallback is set, the next test would be pointless
                if (this.retry_on_signal_key_chain_error && (read_job.error () == QKeychain.NoBackendAvailable
                        || read_job.error () == QKeychain.OtherError)) {
                    // Could be that the backend was not yet available. Wait some extra seconds.
                    // (Issues #4274 and #6522)
                    // (For kwallet, the error is OtherError instead of NoBackendAvailable, maybe a bug in QtKeychain)
                    GLib.info ("Backend unavailable (yet?) Retrying in a few seconds. " + read_job.error_string ());
                    QTimer.single_shot (10000, this, ReadJob.on_signal_start);
                    this.retry_on_signal_key_chain_error = false;
                    read_job.delete_later ();
                    return;
                }
                this.retry_on_signal_key_chain_error = false;
            }
            if (read_job.error () != QKeychain.EntryNotFound ||
                ( (read_job.error () == QKeychain.EntryNotFound) && this.chunk_count == 0)) {
                this.error = read_job.error ();
                this.error_string = read_job.error_string ();
                GLib.warning ("Unable to read " + read_job.key () + " chunk " + string.number (this.chunk_count) + read_job.error_string ());
            }
        }

        read_job.delete_later ();

        /* emit */ finished (this);

        if (this.auto_delete) {
            delete_later ();
        }
    }

} // class ReadJob

} // namespace KeychainChunk
} // namespace Occ
