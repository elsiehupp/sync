/*
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
// #include <QUrl>

namespace Occ {

/**
Job that do the authorization grant and fetch the access token

Normal workfl

  -. start ()
      |
      +---. openBrowser () open the browser to the login page, redirects to http://localhost
      |
      +---. _ser
               |
               v
            requ
               |
               v
             emit result (...)

*/
class OAuth : GLib.Object {
public:
    OAuth (Account *account, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account) {
    }
    ~OAuth () override;

    enum Result { NotSupported,
        LoggedIn,
        Error };
    Q_ENUM (Result);
    void start ();
    bool openBrowser ();
    QUrl authorisationLink ();

signals:
    /**
     * The state has changed.
     * when logged in, token has the value of the token.
     */
    void result (OAuth.Result result, QString &user = QString (), QString &token = QString (), QString &refreshToken = QString ());

private:
    Account *_account;
    QTcpServer _server;

public:
    QString _expectedUser;
};

} // namespace Occ
