/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

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
// #include <GLib.Object>

class QUrlQuery;

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcUpdater)

class Updater : GLib.Object {
public:
    struct Helper {
        static int64 stringVersionToInt (QString &version);
        static int64 currentVersionToInt ();
        static int64 versionToInt (int64 major, int64 minor, int64 patch, int64 build);
    };

    static Updater *instance ();
    static QUrl updateUrl ();

    virtual void checkForUpdate () = 0;
    virtual void backgroundCheckForUpdate () = 0;
    virtual bool handleStartup () = 0;

protected:
    static QString clientVersion ();
    Updater ()
        : GLib.Object (nullptr) {
    }

private:
    static QString getSystemInfo ();
    static QUrlQuery getQueryParams ();
    static Updater *create ();
    static Updater *_instance;
};

} // namespace Occ
