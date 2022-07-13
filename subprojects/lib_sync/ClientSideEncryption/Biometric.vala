namespace Occ {
namespace LibSync {

/***********************************************************
@class Biometric

Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
public class Biometric : GLib.Object {

    /***********************************************************
    private Q_DISABLE_COPY (Biometric)
    ***********************************************************/

    private BIO bio;

    public Biometric () {
        this.bio = new BIO_new (BIO_s_mem ());
    }


    ~Biometric () {
        BIO_free_all (this.bio);
    }


    /***********************************************************
    public operator BIO* () {
        return this.bio;
    }
    ***********************************************************/

} // class Biometric

} // namespace LibSync
} // namespace Occ
