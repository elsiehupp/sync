namespace Occ {

/***********************************************************
Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
class PrivateKeyContext {

    //  Q_DISABLE_COPY (PrivateKeyContext)

    private EVP_PKEY_CTX context = null;

    public PrivateKeyContext (int identifier, ENGINE e = null) {
        this.context = EVP_PKEY_CTX_new_id (identifier, e);
    }


    ~PrivateKeyContext () {
        EVP_PKEY_CTX_free (this.context);
    }


    // The move constructor is needed for pre-C++17 where
    // return-value optimization (RVO) is not obligatory
    // and we have a `for_key` static function that returns
    // an instance of this class
    //  public PrivateKeyContext (PrivateKeyContext&& other) {
    //      std.swap (this.context, other.ctx);
    //  }


    public static PrivateKeyContext for_key (EVP_PKEY *pkey, ENGINE *e = null) {
        PrivateKeyContext context;
        context.ctx = EVP_PKEY_CTX_new (pkey, e);
        return context;
    }


    //  public PrivateKeyContext& operator= (PrivateKeyContext&& other) = delete;


    //  public operator EVP_PKEY_CTX* () {
    //      return this.context;
    //  }

} // class PrivateKeyContext

} // namespace Occ
