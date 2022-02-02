
class StreamingDecryptor {

    /***********************************************************
    ***********************************************************/
    public StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray iv, uint64 total_size);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public bool is_finished ();


    //  Q_DISABLE_COPY (StreamingDecryptor)

    /***********************************************************
    ***********************************************************/
    private CipherCtx this.ctx;
    private bool this.is_initialized = false;
    private bool this.is_finished = false;
    private uint64 this.decrypted_so_far = 0;
    private uint64 this.total_size = 0;
};