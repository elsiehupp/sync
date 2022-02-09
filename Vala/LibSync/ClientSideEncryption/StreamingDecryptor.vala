namespace Occ {

/***********************************************************
Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
class StreamingDecryptor {

    //  Q_DISABLE_COPY (StreamingDecryptor)

    /***********************************************************
    ***********************************************************/
    private CipherContext context;
    private bool is_initialized = false;
    bool is_finished { public get; private set; }
    private uint64 decrypted_so_far = 0;
    private uint64 total_size = 0;

    /***********************************************************
    ***********************************************************/
    public StreamingDecryptor (GLib.ByteArray key, GLib.ByteArray iv, uint64 total_size) {
        this.is_finished = false;
    }

} // class StreamingDecryptor

} // namespace Occ
