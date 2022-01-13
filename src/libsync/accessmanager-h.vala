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

// #include <QNetworkAccessManager>

class QUrl;

namespace Occ {

/**
@brief The AccessManager class
@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT AccessManager : QNetworkAccessManager {

public:
    static QByteArray generateRequestId ();

    AccessManager (GLib.Object *parent = nullptr);

protected:
    QNetworkReply *createRequest (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoingData = nullptr) override;
};

} // namespace Occ

#endif
