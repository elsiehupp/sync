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

// #include <QMetaType>
// #include <GLib.Object>
// #include <QString>

namespace Occ {

/**
@brief The SyncFileStatus class
@ingroup libsync
*/
class SyncFileStatus {
public:
    enum SyncFileStatusTag {
        StatusNone,
        StatusSync,
        StatusWarning,
        StatusUpToDate,
        StatusError,
        StatusExcluded,
    };

    SyncFileStatus ();
    SyncFileStatus (SyncFileStatusTag);

    void set (SyncFileStatusTag tag);
    SyncFileStatusTag tag ();

    void setShared (bool isShared);
    bool shared ();

    QString toSocketAPIString ();

private:
    SyncFileStatusTag _tag = StatusNone;
    bool _shared = false;
};

inline bool operator== (SyncFileStatus &a, SyncFileStatus &b) {
    return a.tag () == b.tag () && a.shared () == b.shared ();
}

inline bool operator!= (SyncFileStatus &a, SyncFileStatus &b) {
    return ! (a == b);
}
}

Q_DECLARE_METATYPE (Occ.SyncFileStatus)
