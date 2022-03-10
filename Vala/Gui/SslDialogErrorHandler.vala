/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SslDialogErrorHandler class
@ingroup gui
***********************************************************/
class SslDialogErrorHandler : AbstractSslErrorHandler {

    /***********************************************************
    ***********************************************************/
    public override bool handle_errors (GLib.List<QSslError> errors, QSslConfiguration conf, GLib.List<QSslCertificate> certificates, AccountPointer account) {
        //  (void)conf;
        if (!certificates) {
            GLib.critical ("Certs parameter required but is NULL!";
            return false;
        }

        SslErrorDialog dialog (account);
        // whether the failing certificates have previously been accepted
        if (dialog.check_failing_certificates_known (errors)) {
            *certificates = dialog.unknown_certificates ();
            return true;
        }
        // whether the user accepted the certificates
        if (dialog.exec () == Gtk.Dialog.Accepted) {
            if (dialog.trust_connection ()) {
                *certificates = dialog.unknown_certificates ();
                return true;
            }
        }
        return false;
    }

} // class SslDialogErrorHandler

} // namespace Ui
} // namespace Occ
