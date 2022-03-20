namespace Occ {
namespace Cmd {

/***********************************************************
@class SimpleSslErrorHandler

@brief The SimpleSslErrorHandler class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SimpleSslErrorHandler : AbstractSslErrorHandler {

    /***********************************************************
    ***********************************************************/
    public override bool handle_errors (GLib.List<QSslError> errors, QSslConfiguration conf, GLib.List<QSslCertificate> certificates, Account account) {
        (void)account;
        (void)conf;

        if (!certificates) {
            GLib.debug ("Certs parameter required but is NULL!");
            return false;
        }

        foreach (var error in errors) {
            certificates.append (error.certificate ());
        }
        return true;
    }

} // class SimpleSslErrorHandler

} // namespace Cmd
} // namespace Occ
