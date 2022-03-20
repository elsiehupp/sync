/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {

/***********************************************************
@brief The SimpleSslErrorHandler class
@ingroup cmd
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

}

}
