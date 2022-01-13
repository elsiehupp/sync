/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QLoggingCategory>
// #include <QString>
// #include <QCoreApplication>

namespace Occ {

Q_LOGGING_CATEGORY (lcCredentials, "nextcloud.sync.credentials", QtInfoMsg)

AbstractCredentials.AbstractCredentials () = default;

void AbstractCredentials.setAccount (Account *account) {
    ENFORCE (!_account, "should only setAccount once");
    _account = account;
}

QString AbstractCredentials.keychainKey (QString &url, QString &user, QString &accountId) {
    QString u (url);
    if (u.isEmpty ()) {
        qCWarning (lcCredentials) << "Empty url in keyChain, error!";
        return QString ();
    }
    if (user.isEmpty ()) {
        qCWarning (lcCredentials) << "Error : User is empty!";
        return QString ();
    }

    if (!u.endsWith (QChar ('/'))) {
        u.append (QChar ('/'));
    }

    QString key = user + QLatin1Char (':') + u;
    if (!accountId.isEmpty ()) {
        key += QLatin1Char (':') + accountId;
    }
    return key;
}
} // namespace Occ
