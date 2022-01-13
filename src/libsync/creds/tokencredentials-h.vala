/*
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (c) by Markus Goetz <guruz@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QMap>

class QAuthenticator;

namespace QKeychain {
}

namespace Occ {

class OWNCLOUDSYNC_EXPORT TokenCredentials : AbstractCredentials {

public:
    friend class TokenCredentialsAccessManager;
    TokenCredentials ();
    TokenCredentials (QString &user, QString &password, QString &token);

    QString authType () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    void askFromUser () override;
    void fetchFromKeychain () override;
    bool stillValid (QNetworkReply *reply) override;
    void persist () override;
    QString user () const override;
    void invalidateToken () override;
    void forgetSensitiveData () override;

    QString password ();
private slots:
    void slotAuthentication (QNetworkReply *, QAuthenticator *);

private:
    QString _user;
    QString _password;
    QString _token; // the cookies
    bool _ready;
};

} // namespace Occ

#endif
