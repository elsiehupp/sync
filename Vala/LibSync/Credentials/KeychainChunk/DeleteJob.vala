/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {
namespace KeychainChunk {

/***********************************************************
@brief Simple wrapper class for QKeychain.DeletePasswordJob
***********************************************************/
public class DeleteJob : KeychainChunk.Job {

    signal void signal_finished (KeychainChunk.DeleteJob incoming_job);

    /***********************************************************
    ***********************************************************/
    public DeleteJob.for_account (Account account, string key, bool keychain_migration, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
        this.key = key;

        this.keychain_migration = keychain_migration;
    }


    /***********************************************************
    ***********************************************************/
    public DeleteJob (string key, GLib.Object parent = new GLib.Object ()) {
        base (null, key, false, parent);
    }


    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the signal_finished () signal first.

    @see QKeychain.Job.start ()
    ***********************************************************/
    public new void start () {
        this.chunk_count = 0;
        this.error = QKeychain.NoError;

        const string kck = this.account ? AbstractCredentials.keychain_key (
                this.account.url ().to_string (),
                this.key,
                this.keychain_migration ? "" : this.account.identifier ()
            ) : this.key;

        var job = new QKeychain.DeletePasswordJob (this.service_name, this);
    // #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (this.account, job);
    // #endif
        job.insecure_fallback (this.insecure_fallback);
        job.key (kck);
        connect (job, QKeychain.Job.on_signal_finished, this, KeychainChunk.DeleteJob.on_signal_delete_job_done);
        job.start ();
    }


    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the signal_finished () signal first.

    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    public bool exec () {
        start ();

        QEventLoop wait_loop;
        connect (this, DeleteJob.on_signal_finished, wait_loop, QEventLoop.quit);
        wait_loop.exec ();

        if (error () == NoError) {
            return true;
        }

        this.chunk_count = 0;
        if (error () != EntryNotFound) {
            GLib.warning ("DeletePasswordJob failed with " + error_string ());
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_done (QKeychain.Job incoming_job) {
        // Errors or next chunk?
        var delete_job = qobject_cast<QKeychain.DeletePasswordJob> (incoming_job);
        GLib.assert (delete_job);

        if (delete_job.error () == NoError) {
            this.chunk_count++;
        } else {
            if (delete_job.error () != QKeychain.EntryNotFound ||
                ( (delete_job.error () == QKeychain.EntryNotFound) && this.chunk_count == 0)) {
                this.error = delete_job.error ();
                this.error_string = delete_job.error_string ();
                GLib.warning ("Unable to delete " + delete_job.key () + " chunk " + this.chunk_count + delete_job.error_string ());
            }
        }

        delete_job.delete_later ();

        /* emit */ finished (this);

        if (this.auto_delete) {
            delete_later ();
        }
    }

} // class DeleteJob

} // namespace KeychainChunk
} // namespace LibSync
} // namespace Occ
