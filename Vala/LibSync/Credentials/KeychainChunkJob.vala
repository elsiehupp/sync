namespace Occ {
namespace LibSync {

/***********************************************************
@brief Abstract base class for KeychainChunk jobs.

Workaround for Windows:

Split the keychain entry's data into chunks of 2048 bytes,
to allow 4k (4096 bit) keys / large certificates to be saved (see
    limits in webflowcredentials.h)

@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/
public class KeychainChunkJob : GLib.Object {

    // We don't support insecure fallback
    // const bool KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK = true;

    const int ChunkSize = 2048;
    const int MaxChunks = 10;

    protected string service_name;
    protected Account account;
    protected string key;

    /***********************************************************
    If we use it but don't support insecure fallback, give us
    nice compilation errors ;p
    ***********************************************************/
    public bool insecure_fallback = false;


    /***********************************************************
    Whether this job autodeletes itself once signal_finished () has been emitted. Default is true.
    @see auto_delete ()
    ***********************************************************/
    public bool auto_delete = true;

    protected bool keychain_migration = false;

    public Secret.Collection.Error error { public get; protected set; }

    public string error_string { public get; protected set; }

    protected int chunk_count = 0;
    protected string chunk_buffer;

    /***********************************************************
    ***********************************************************/
    public KeychainChunkJob (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.error = Secret.Collection.NoError;
        this.service_name = Theme.app_name;
    }


    ~KeychainChunkJob () {
        this.chunk_count = 0;
        this.chunk_buffer.steal (); // to clear securely?
    }


    /***********************************************************
    ***********************************************************/
    public string binary_data () {
        return this.chunk_buffer;
    }


    /***********************************************************
    ***********************************************************/
    public string text_data () {
        return this.chunk_buffer.to_string ();
    }


    /***********************************************************
    ***********************************************************/
    protected static void add_settings_to_job (Account account, Secret.Collection.Job qkeychain_job) {
        //  Q_UNUSED (account)
        var settings = ConfigFile.settings_with_group (Theme.app_name);
        settings.parent (qkeychain_job); // make the qkeychain_job parent to make setting deleted properly
        qkeychain_job.settings (settings.release ());
    }

} // class Job

} // namespace LibSync
} // namespace Occ
