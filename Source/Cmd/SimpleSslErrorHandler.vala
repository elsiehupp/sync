/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The Simple_sslErrorHandler class
@ingroup cmd
***********************************************************/
class Simple_sslErrorHandler : Occ.AbstractSslErrorHandler {

    /***********************************************************
    ***********************************************************/
    public bool handle_errors (GLib.List<QSslError> errors, QSslConfiguration &conf, GLib.List<QSslCertificate> *certs, Occ.AccountPointer) override;
};


    bool Simple_sslErrorHandler.handle_errors (GLib.List<QSslError> errors, QSslConfiguration &conf, GLib.List<QSslCertificate> *certs, Occ.AccountPointer account) {
        (void)account;
        (void)conf;

        if (!certs) {
            q_debug () << "Certs parameter required but is NULL!";
            return false;
        }

        for (var &error : q_as_const (errors)) {
            certs.append (error.certificate ());
        }
        return true;
    }
    }
    