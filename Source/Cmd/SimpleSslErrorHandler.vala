/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The SimpleSslErrorHandler class
@ingroup cmd
***********************************************************/
class SimpleSslErrorHandler : Occ.AbstractSslErrorHandler {

    public bool handleErrors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, Occ.AccountPtr) override;
};


    bool SimpleSslErrorHandler.handleErrors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, Occ.AccountPtr account) {
        (void)account;
        (void)conf;
    
        if (!certs) {
            qDebug () << "Certs parameter required but is NULL!";
            return false;
        }
    
        for (auto &error : qAsConst (errors)) {
            certs.append (error.certificate ());
        }
        return true;
    }
    }
    