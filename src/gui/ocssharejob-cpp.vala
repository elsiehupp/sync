/*
 * Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QBuffer>
// #include <QJsonDocument>

namespace OCC {

OcsShareJob::OcsShareJob (AccountPtr account)
    : OcsJob (account) {
    setPath ("ocs/v2.php/apps/files_sharing/api/v1/shares");
    connect (this, &OcsJob::jobFinished, this, &OcsShareJob::jobDone);
}

void OcsShareJob::getShares (QString &path) {
    setVerb ("GET");

    addParam (QString::fromLatin1 ("path"), path);
    addParam (QString::fromLatin1 ("reshares"), QString ("true"));
    addPassStatusCode (404);

    start ();
}

void OcsShareJob::deleteShare (QString &shareId) {
    appendPath (shareId);
    setVerb ("DELETE");

    start ();
}

void OcsShareJob::setExpireDate (QString &shareId, QDate &date) {
    appendPath (shareId);
    setVerb ("PUT");

    if (date.isValid ()) {
        addParam (QString::fromLatin1 ("expireDate"), date.toString ("yyyy-MM-dd"));
    } else {
        addParam (QString::fromLatin1 ("expireDate"), QString ());
    }
    _value = date;

    start ();
}

void OcsShareJob::setPassword (QString &shareId, QString &password) {
    appendPath (shareId);
    setVerb ("PUT");

    addParam (QString::fromLatin1 ("password"), password);
    _value = password;

    start ();
}

void OcsShareJob::setNote (QString &shareId, QString &note) {
    appendPath (shareId);
    setVerb ("PUT");

    addParam (QString::fromLatin1 ("note"), note);
    _value = note;

    start ();
}

void OcsShareJob::setPublicUpload (QString &shareId, bool publicUpload) {
    appendPath (shareId);
    setVerb ("PUT");

    const QString value = QString::fromLatin1 (publicUpload ? "true" : "false");
    addParam (QString::fromLatin1 ("publicUpload"), value);
    _value = publicUpload;

    start ();
}

void OcsShareJob::setName (QString &shareId, QString &name) {
    appendPath (shareId);
    setVerb ("PUT");
    addParam (QString::fromLatin1 ("name"), name);
    _value = name;

    start ();
}

void OcsShareJob::setPermissions (QString &shareId,
    const Share::Permissions permissions) {
    appendPath (shareId);
    setVerb ("PUT");

    addParam (QString::fromLatin1 ("permissions"), QString::number (permissions));
    _value = (int)permissions;

    start ();
}

void OcsShareJob::setLabel (QString &shareId, QString &label) {
    appendPath (shareId);
    setVerb ("PUT");

    addParam (QStringLiteral ("label"), label);
    _value = label;

    start ();
}

void OcsShareJob::createLinkShare (QString &path,
    const QString &name,
    const QString &password) {
    setVerb ("POST");

    addParam (QString::fromLatin1 ("path"), path);
    addParam (QString::fromLatin1 ("shareType"), QString::number (Share::TypeLink));

    if (!name.isEmpty ()) {
        addParam (QString::fromLatin1 ("name"), name);
    }
    if (!password.isEmpty ()) {
        addParam (QString::fromLatin1 ("password"), password);
    }

    addPassStatusCode (403);

    start ();
}

void OcsShareJob::createShare (QString &path,
    const Share::ShareType shareType,
    const QString &shareWith,
    const Share::Permissions permissions,
    const QString &password) {
    Q_UNUSED (permissions)
    setVerb ("POST");

    addParam (QString::fromLatin1 ("path"), path);
    addParam (QString::fromLatin1 ("shareType"), QString::number (shareType));
    addParam (QString::fromLatin1 ("shareWith"), shareWith);

    if (!password.isEmpty ()) {
        addParam (QString::fromLatin1 ("password"), password);
    }

    start ();
}

void OcsShareJob::getSharedWithMe () {
    setVerb ("GET");
    addParam (QLatin1String ("shared_with_me"), QLatin1String ("true"));
    start ();
}

void OcsShareJob::jobDone (QJsonDocument reply) {
    emit shareJobFinished (reply, _value);
}
}
