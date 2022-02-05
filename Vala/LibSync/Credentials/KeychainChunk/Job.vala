/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
Workaround for Windows:

Split the keychain entry's data into chunks of 2048 bytes,
to allow 4k (4096 bit) keys / large certificates to be saved (see
    limits in webflowcredentials.h)
***********************************************************/
namespace KeychainChunk {

/***********************************************************
@brief : Abstract base class for KeychainChunk jobs.
***********************************************************/
class Job : GLib.Object {

    // We don't support insecure fallback
    // const bool KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK = true;

    const int ChunkSize = 2048;
    const int MaxChunks = 10;


    protected string service_name;
    protected Account account;
    protected string key;
    protected bool insecure_fallback = false;
    protected bool auto_delete = true;
    protected bool keychain_migration = false;

    protected QKeychain.Error error = QKeychain.NoError;
    protected string error_string;

    protected int chunk_count = 0;
    protected GLib.ByteArray chunk_buffer;

    /***********************************************************
    ***********************************************************/
    public Job (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.service_name = Theme.instance ().app_name ();
    }

    ~Job () override {
        this.chunk_count = 0;
        this.chunk_buffer.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public QKeychain.Error error () {
        return this.error;
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () {
        return this.error_string;
    }


    /***********************************************************
    ***********************************************************/
    public  GLib.ByteArray binary_data () {
        return this.chunk_buffer;
    }


    /***********************************************************
    ***********************************************************/
    public string text_data () {
        return this.chunk_buffer;
    }


    /***********************************************************
    ***********************************************************/
    public bool insecure_fallback () {
        return this.insecure_fallback;
    }


#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    /***********************************************************
    If we use it but don't support insecure fallback, give us
    nice compilation errors ;p
    ***********************************************************/
    public void set_insecure_fallback (bool insecure_fallback) {
        this.insecure_fallback = insecure_fallback;
    }


    /***********************************************************
    ***********************************************************/
    private static void add_settings_to_job (Account account, QKeychain.Job job) {
        //  Q_UNUSED (account)
        var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
        settings.set_parent (job); // make the job parent to make setting deleted properly
        job.set_settings (settings.release ());
    }
#endif

    /***********************************************************
    @return Whether this job autodeletes itself once on_finished () has been emitted. Default is true.
    @see set_auto_delete ()
    ***********************************************************/
    public bool auto_delete () {
        return this.auto_delete;
    }


    /***********************************************************
    Set whether this job should autodelete itself once on_finished () has been emitted.
    @see auto_delete ()
    ***********************************************************/
    public void set_auto_delete (bool auto_delete) {
        this.auto_delete = auto_delete;
    }

} // class Job

} // namespace KeychainChunk
} // namespace Occ
