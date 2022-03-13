namespace Occ {
namespace LibSync {

/***********************************************************
Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
class PrivateKey : GLib.Object {

    //  private Q_DISABLE_COPY (PrivateKey)

    private EVP_PKEY pkey = null;

    /***********************************************************
    The move constructor is needed for pre-C++17 where
    return-value optimization (RVO) is not obligatory
    and we have a static functions that return
    an instance of this class
    ***********************************************************/
    public PrivateKey (PrivateKey&& other) {
        std.swap (this.pkey, other.pkey);
    }


    ~PrivateKey () {
        EVP_PKEY_free (this.pkey);
    }


    public static PrivateKey read_public_key (Biometric bio) {
        PrivateKey result;
        result.pkey = PEM_read_bio_PUBKEY (bio, null, null, null);
        return result;
    }


    public static PrivateKey read_private_key (Biometric bio) {
        PrivateKey result;
        result.pkey = PEM_read_bio_Private_key (bio, null, null, null);
        return result;
    }


    public static PrivateKey generate (PrivateKeyContext& context) {
        PrivateKey result;
        if (EVP_PKEY_keygen (context, result.pkey) <= 0) {
            result.pkey = null;
        }
        return result;
    }


    //  public PrivateKey& operator= (PrivateKey&& other) = delete;


    //  public operator EVP_PKEY* () {
    //      return this.pkey;
    //  }


    //  public operator EVP_PKEY* () {
    //      return this.pkey;
    //  }

} // class PrivateKey

} // namespace LibSync
} // namespace Occ
