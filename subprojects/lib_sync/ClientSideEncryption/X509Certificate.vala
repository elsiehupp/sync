namespace Occ {
namespace LibSync {

/***********************************************************
@class X509Certificate

Simple classes for safe (RAII) handling of OpenSSL
data structures
***********************************************************/
public class X509Certificate { //: GLib.Object {

    //  //  private Q_DISABLE_COPY (X509Certificate)

    //  private X509 certificate = null;

    //  // The move constructor is needed for pre-C++17 where
    //  // return-value optimization (RVO) is not obligatory
    //  // and we have a static functions that return
    //  // an instance of this class
    //  //  public X509Certificate (X509Certificate&& other) {
    //  //      std.swap (this.certificate, other.certificate);
    //  //  }

    //  ~X509Certificate () {
    //      X509_free (this.certificate);
    //  }


    //  public static X509Certificate read_certificate (Biometric bio) {
    //      X509Certificate result;
    //      result.certificate = PEM_read_bio_X509 (bio, null, null, null);
    //      return result;
    //  }


    //  //  public X509Certificate operator= (X509Certificate&& other) = delete;


    //  //  public operator X509* () {
    //  //      return this.certificate;
    //  //  }


    //  //  public operator X509* () {
    //  //      return this.certificate;
    //  //  }

} // class X509Certificate

} // namespace LibSync
} // namespace Occ
