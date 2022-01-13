/*
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #pragma once
// #include <QPointer>
// #include <QTcpServer>

namespace Occ {

/**
@brief The HttpCredentialsGui class
@ingroup gui
*/
class HttpCredentialsGui : HttpCredentials {
public:
    HttpCredentialsGui ()
        : HttpCredentials () {
    }
    HttpCredentialsGui (QString &user, QString &password,
            const QByteArray &clientCertBundle, QByteArray &clientCertPassword)
        : HttpCredentials (user, password, clientCertBundle, clientCertPassword) {
    }
    HttpCredentialsGui (QString &user, QString &password, QString &refreshToken,
            const QByteArray &clientCertBundle, QByteArray &clientCertPassword)
        : HttpCredentials (user, password, clientCertBundle, clientCertPassword) {
        _refreshToken = refreshToken;
    }

    /**
     * This will query the server and either uses OAuth via _asyncAuth.start ()
     * or call showDialog to ask the password
     */
    void askFromUser () override;
    /**
     * In case of oauth, return an URL to the link to open the browser.
     * An invalid URL otherwise
     */
    QUrl authorisationLink () { return _asyncAuth ? _asyncAuth.authorisationLink () : QUrl (); }

    static QString requestAppPasswordText (Account *account);
private slots:
    void asyncAuthResult (OAuth.Result, QString &user, QString &accessToken, QString &refreshToken);
    void showDialog ();
    void askFromUserAsync ();

signals:
    void authorisationLinkChanged ();

private:

    QScopedPointer<OAuth, QScopedPointerObjectDeleteLater<OAuth>> _asyncAuth;
};

} // namespace Occ
