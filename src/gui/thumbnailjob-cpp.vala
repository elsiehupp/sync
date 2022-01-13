/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

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

ThumbnailJob.ThumbnailJob (QString &path, AccountPtr account, GLib.Object *parent)
    : AbstractNetworkJob (account, QLatin1String ("index.php/apps/files/api/v1/thumbnail/150/150/") + path, parent) {
    setIgnoreCredentialFailure (true);
}

void ThumbnailJob.start () {
    sendRequest ("GET", makeAccountUrl (path ()));
    AbstractNetworkJob.start ();
}

bool ThumbnailJob.finished () {
    emit jobFinished (reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt (), reply ().readAll ());
    return true;
}
}
