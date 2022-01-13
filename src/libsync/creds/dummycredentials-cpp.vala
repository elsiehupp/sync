/*
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

namespace Occ {

QString DummyCredentials.authType () {
    return QString.fromLatin1 ("dummy");
}

QString DummyCredentials.user () {
    return _user;
}

QString DummyCredentials.password () {
    Q_UNREACHABLE ();
    return QString ();
}

QNetworkAccessManager *DummyCredentials.createQNAM () {
    return new AccessManager;
}

bool DummyCredentials.ready () {
    return true;
}

bool DummyCredentials.stillValid (QNetworkReply *reply) {
    Q_UNUSED (reply)
    return true;
}

void DummyCredentials.fetchFromKeychain () {
    _wasFetched = true;
    Q_EMIT (fetched ());
}

void DummyCredentials.askFromUser () {
    Q_EMIT (asked ());
}

void DummyCredentials.persist () {
}

} // namespace Occ
