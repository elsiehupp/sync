namespace Occ {
namespace LibSync {

/***********************************************************
Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
class CipherContext : GLib.Object {

    //  Q_DISABLE_COPY (CipherContext)
    private EVP_CIPHER_CTX context;

    /***********************************************************
    ***********************************************************/
    public CipherContext () {
        this.context = new EVP_CIPHER_CTX_new ();
    }

    ~CipherContext () {
        EVP_CIPHER_CTX_free (this.context);
    }


    //  public operator EVP_CIPHER_CTX* () {
    //      return this.context;
    //  }

} // class CipherContext

} // namespace LibSync
} // namespace Occ
