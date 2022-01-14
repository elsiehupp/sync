/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QMetaType>
// #include <GLib.Object>
// #include <string>

namespace Occ {

/***********************************************************
@brief The SyncFileStatus class
@ingroup libsync
***********************************************************/
class SyncFileStatus {

    public enum SyncFileStatusTag {
        SyncFileStatusTag.STATUS_NONE,
        SyncFileStatusTag.STATUS_SYNC,
        SyncFileStatusTag.STATUS_WARNING,
        SyncFileStatusTag.STATUS_UP_TO_DATE,
        SyncFileStatusTag.STATUS_ERROR,
        SyncFileStatusTag.STATUS_EXCLUDED,
    };

    public SyncFileStatus ();
    public SyncFileStatus (SyncFileStatusTag);

    public void set (SyncFileStatusTag tag);
    public SyncFileStatusTag tag ();

    public void set_shared (bool is_shared);
    public bool shared ();

    public string to_socket_api_string ();

private:
    SyncFileStatusTag _tag = SyncFileStatusTag.STATUS_NONE;
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
    
    void SyncFileStatus.set_shared (bool is_shared) {
        _shared = is_shared;
    }
    
    bool SyncFileStatus.shared () {
        return _shared;
    }
    
    string SyncFileStatus.to_socket_api_string () {
        string status_string;
        bool can_be_shared = true;
    
        switch (_tag) {
        case SyncFileStatusTag.STATUS_NONE:
            status_string = QStringLiteral ("NOP");
            can_be_shared = false;
            break;
        case SyncFileStatusTag.STATUS_SYNC:
            status_string = QStringLiteral ("SYNC");
            break;
        case SyncFileStatusTag.STATUS_WARNING:
            // The protocol says IGNORE, but all implementations show a yellow warning sign.
            status_string = QStringLiteral ("IGNORE");
            break;
        case SyncFileStatusTag.STATUS_UP_TO_DATE:
            status_string = QStringLiteral ("OK");
            break;
        case SyncFileStatusTag.STATUS_ERROR:
            status_string = QStringLiteral ("ERROR");
            break;
        case SyncFileStatusTag.STATUS_EXCLUDED:
            // The protocol says IGNORE, but all implementations show a yellow warning sign.
            status_string = QStringLiteral ("IGNORE");
            break;
        }
        if (can_be_shared && _shared) {
            status_string += QLatin1String ("+SWM");
        }
    
        return status_string;
    }
    }
    