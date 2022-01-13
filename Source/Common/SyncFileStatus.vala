/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QMetaType>
// #include <GLib.Object>
// #include <string>

namespace Occ {

Q_DECLARE_METATYPE (Occ.SyncFileStatus)

/***********************************************************
@brief The SyncFileStatus class
@ingroup libsync
***********************************************************/
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

    string toSocketAPIString ();

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

    SyncFileStatus.SyncFileStatus () = default;
    
    SyncFileStatus.SyncFileStatus (SyncFileStatusTag tag)
        : _tag (tag) {
    }
    
    void SyncFileStatus.set (SyncFileStatusTag tag) {
        _tag = tag;
    }
    
    SyncFileStatus.SyncFileStatusTag SyncFileStatus.tag () {
        return _tag;
    }
    
    void SyncFileStatus.setShared (bool isShared) {
        _shared = isShared;
    }
    
    bool SyncFileStatus.shared () {
        return _shared;
    }
    
    string SyncFileStatus.toSocketAPIString () {
        string statusString;
        bool canBeShared = true;
    
        switch (_tag) {
        case StatusNone:
            statusString = QStringLiteral ("NOP");
            canBeShared = false;
            break;
        case StatusSync:
            statusString = QStringLiteral ("SYNC");
            break;
        case StatusWarning:
            // The protocol says IGNORE, but all implementations show a yellow warning sign.
            statusString = QStringLiteral ("IGNORE");
            break;
        case StatusUpToDate:
            statusString = QStringLiteral ("OK");
            break;
        case StatusError:
            statusString = QStringLiteral ("ERROR");
            break;
        case StatusExcluded:
            // The protocol says IGNORE, but all implementations show a yellow warning sign.
            statusString = QStringLiteral ("IGNORE");
            break;
        }
        if (canBeShared && _shared) {
            statusString += QLatin1String ("+SWM");
        }
    
        return statusString;
    }
    }
    