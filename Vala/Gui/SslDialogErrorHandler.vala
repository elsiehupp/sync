/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The SslDialogErrorHandler class
@ingroup gui
***********************************************************/
class SslDialogErrorHandler : AbstractSslErrorHandler {

    /***********************************************************
    ***********************************************************/
    public bool handle_errors (GLib.List<QSslError> errors, QSslConfiguration conf, GLib.List<QSslCertificate> *certificates, AccountPointer) override;
};