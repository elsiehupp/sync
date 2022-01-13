/*
Copyright (C) by Camila Ayres <hello@camila.codes>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QByteArray>
// #include <QNetworkAccessManager>
// #include <QNetworkRequest>
// #include <QNetworkReply>

namespace Occ {

/**
@brief Job to fetch a icon
@ingroup gui
*/
class OWNCLOUDSYNC_EXPORT IconJob : GLib.Object {
public:
    IconJob (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);

signals:
    void jobFinished (QByteArray iconData);
    void error (QNetworkReply.NetworkError errorType);

private slots:
    void finished ();
};
}
