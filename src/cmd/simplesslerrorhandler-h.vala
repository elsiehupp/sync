/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

class QSslCertificate;

namespace Occ {

/**
@brief The SimpleSslErrorHandler class
@ingroup cmd
*/
class SimpleSslErrorHandler : Occ.AbstractSslErrorHandler {
public:
    bool handleErrors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, Occ.AccountPtr) override;
};
}
