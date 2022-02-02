
//
// Simple classes for safe (RAII) handling of OpenSSL
// data structures
//
class CipherCtx {

    /***********************************************************
    ***********************************************************/
    public CipherCtx () : this.ctx (EVP_CIPHER_CTX_new ()) {
    }

    ~CipherCtx () {
        EVP_CIPHER_CTX_free (this.ctx);
    }


    /***********************************************************
    ***********************************************************/
    public operator EVP_CIPHER_CTX* () {
        return this.ctx;
    }


    //  Q_DISABLE_COPY (CipherCtx)
    private EVP_CIPHER_CTX this.ctx;
}



class CipherCtx {

    public CipherCtx ()
        : this.ctx (EVP_CIPHER_CTX_new ()) {
    }

    ~CipherCtx () {
        EVP_CIPHER_CTX_free (this.ctx);
    }

    public operator EVP_CIPHER_CTX* () {
        return this.ctx;
    }

    //  private Q_DISABLE_COPY (CipherCtx)

    private EVP_CIPHER_CTX* this.ctx;
};