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

// #include <QBuffer>

namespace Occ {

Q_LOGGING_CATEGORY (lcNotificationsJob, "nextcloud.gui.notifications", QtInfoMsg)

NotificationConfirmJob.NotificationConfirmJob (AccountPtr account)
    : AbstractNetworkJob (account, "") {
    setIgnoreCredentialFailure (true);
}

void NotificationConfirmJob.setLinkAndVerb (QUrl &link, QByteArray &verb) {
    _link = link;
    _verb = verb;
}

void NotificationConfirmJob.start () {
    if (!_link.isValid ()) {
        qCWarning (lcNotificationsJob) << "Attempt to trigger invalid URL : " << _link.toString ();
        return;
    }
    QNetworkRequest req;
    req.setRawHeader ("Ocs-APIREQUEST", "true");
    req.setRawHeader ("Content-Type", "application/x-www-form-urlencoded");

    sendRequest (_verb, _link, req);

    AbstractNetworkJob.start ();
}

bool NotificationConfirmJob.finished () {
    int replyCode = 0;
    // FIXME : check for the reply code!
    const QString replyStr = reply ().readAll ();

    if (replyStr.contains ("<?xml version=\"1.0\"?>")) {
        const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
        const auto rexMatch = rex.match (replyStr);
        if (rexMatch.hasMatch ()) {
            // this is a error message coming back from ocs.
            replyCode = rexMatch.captured (1).toInt ();
        }
    }
    emit jobFinished (replyStr, replyCode);

    return true;
}
}
