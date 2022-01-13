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

// #include <GLib.Object>
// #include <QNetworkProxy>
// #include <QRunnable>
// #include <QUrl>

// #include <csync.h>

namespace Occ {


/**
@brief The ClientProxy class
@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT ClientProxy : GLib.Object {
public:
    ClientProxy (GLib.Object *parent = nullptr);

    static bool isUsingSystemDefault ();
    static void lookupSystemProxyAsync (QUrl &url, GLib.Object *dst, char *slot);

    static QString printQNetworkProxy (QNetworkProxy &proxy);
    static const char *proxyTypeToCStr (QNetworkProxy.ProxyType type);

public slots:
    void setupQtProxyFromConfig ();
};

class OWNCLOUDSYNC_EXPORT SystemProxyRunnable : GLib.Object, public QRunnable {
public:
    SystemProxyRunnable (QUrl &url);
    void run () override;
signals:
    void systemProxyLookedUp (QNetworkProxy &url);

private:
    QUrl _url;
};

}
