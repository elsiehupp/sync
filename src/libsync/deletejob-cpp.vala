/*
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

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

namespace Occ {

Q_LOGGING_CATEGORY (lcDeleteJob, "nextcloud.sync.networkjob.delete", QtInfoMsg)

DeleteJob.DeleteJob (AccountPtr account, QString &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

DeleteJob.DeleteJob (AccountPtr account, QUrl &url, GLib.Object *parent)
    : AbstractNetworkJob (account, QString (), parent)
    , _url (url) {
}

void DeleteJob.start () {
    QNetworkRequest req;
    if (!_folderToken.isEmpty ()) {
        req.setRawHeader ("e2e-token", _folderToken);
    }

    if (_url.isValid ()) {
        sendRequest ("DELETE", _url, req);
    } else {
        sendRequest ("DELETE", makeDavUrl (path ()), req);
    }

    if (reply ().error () != QNetworkReply.NoError) {
        qCWarning (lcDeleteJob) << " Network error : " << reply ().errorString ();
    }
    AbstractNetworkJob.start ();
}

bool DeleteJob.finished () {
    qCInfo (lcDeleteJob) << "DELETE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << replyStatusString ();

    emit finishedSignal ();
    return true;
}

QByteArray DeleteJob.folderToken () {
    return _folderToken;
}

void DeleteJob.setFolderToken (QByteArray &folderToken) {
    _folderToken = folderToken;
}

} // namespace Occ
