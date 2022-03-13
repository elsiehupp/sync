/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The SimpleSslErrorHandler class
@ingroup cmd
***********************************************************/
public class SimpleSslErrorHandler : Occ.AbstractSslErrorHandler {

    /***********************************************************
    ***********************************************************/
    public bool handle_errors (GLib.List<QSslError> errors, QSslConfiguration conf, GLib.List<QSslCertificate> *certificates, Occ.unowned Account) override;
}


    bool SimpleSslErrorHandler.handle_errors (GLib.List<QSslError> errors, QSslConfiguration conf, GLib.List<QSslCertificate> *certificates, Occ.unowned Account account) {
        (void)account;
        (void)conf;

        if (!certificates) {
            GLib.debug ("Certs parameter required but is NULL!";
            return false;
        }

        for (var error : q_as_const (errors)) {
            certificates.append (error.certificate ());
        }
        return true;
    }
    }
    