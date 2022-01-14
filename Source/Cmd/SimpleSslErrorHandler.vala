/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The Simple_sslErrorHandler class
@ingroup cmd
***********************************************************/
class Simple_sslErrorHandler : Occ.Abstract_sslErrorHandler {

    public bool handle_errors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, Occ.AccountPtr) override;
};


    bool Simple_sslErrorHandler.handle_errors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, Occ.AccountPtr account) {
        (void)account;
        (void)conf;

        if (!certs) {
            q_debug () << "Certs parameter required but is NULL!";
            return false;
        }

        for (auto &error : q_as_const (errors)) {
            certs.append (error.certificate ());
        }
        return true;
    }
    }
    