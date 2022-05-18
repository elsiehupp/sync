namespace Occ {
namespace Common {

/***********************************************************
@class SyncFileStatus

@brief The SyncFileStatus class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SyncFileStatus : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum SyncFileStatusTag {
        STATUS_NONE,
        STATUS_SYNC,
        STATUS_WARNING,
        STATUS_UP_TO_DATE,
        STATUS_ERROR,
        STATUS_EXCLUDED,
    }


    /***********************************************************
    ***********************************************************/
    SyncFileStatusTag tag { public get; public set; }
    bool shared { public get; public set; }


    /***********************************************************
    ***********************************************************/
    public SyncFileStatus (SyncFileStatusTag tag = SyncFileStatusTag.STATUS_NONE) {
        this.tag = tag;
        this.shared = false;
    }


    /***********************************************************
    ***********************************************************/
    public string to_socket_api_string () {
        string status_string = "";
        bool can_be_shared = true;

        switch (this.tag) {
        case SyncFileStatusTag.STATUS_NONE:
            status_string = "NOP";
            can_be_shared = false;
            break;
        case SyncFileStatusTag.STATUS_SYNC:
            status_string = "SYNC";
            break;
        case SyncFileStatusTag.STATUS_WARNING:
            /***********************************************************
            The protocol says IGNORE, but all implementations show a
            yellow warning sign.
            ***********************************************************/
            status_string = "IGNORE";
            break;
        case SyncFileStatusTag.STATUS_UP_TO_DATE:
            status_string = "OK";
            break;
        case SyncFileStatusTag.STATUS_ERROR:
            status_string = "ERROR";
            break;
        case SyncFileStatusTag.STATUS_EXCLUDED:
            /***********************************************************
            The protocol says IGNORE, but all implementations show a
            yellow warning sign.
            ***********************************************************/
            status_string = "IGNORE";
            break;
        }
        if (can_be_shared && this.shared) {
            status_string += "+SWM";
        }

        return status_string;
    }


    public bool equal (SyncFileStatus a, SyncFileStatus b) {
        return a.tag == b.tag && a.shared == b.shared;
    }

} // class SyncFileStatus

} // namespace Common
} // namespace Occ
