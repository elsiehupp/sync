/*
Copyright (C) by Klaas Freitag <freitag@kde.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QtCore>
// #include <QDialog>
// #include <QSslCertificate>
// #include <QList>

class QSslCertificate;

namespace Occ {

namespace Ui {
    class SslErrorDialog;
}

/**
@brief The SslDialogErrorHandler class
@ingroup gui
*/
class SslDialogErrorHandler : AbstractSslErrorHandler {
public:
    bool handleErrors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, AccountPtr) override;
};

/**
@brief The SslErrorDialog class
@ingroup gui
*/
class SslErrorDialog : QDialog {
public:
    SslErrorDialog (AccountPtr account, QWidget *parent = nullptr);
    ~SslErrorDialog () override;
    bool checkFailingCertsKnown (QList<QSslError> &errors);
    bool trustConnection ();
    QList<QSslCertificate> unknownCerts () { return _unknownCerts; }

private:
    QString styleSheet ();
    bool _allTrusted;

    QString certDiv (QSslCertificate) const;

    QList<QSslCertificate> _unknownCerts;
    QString _customConfigHandle;
    Ui.SslErrorDialog *_ui;
    AccountPtr _account;
};
} // end namespace
