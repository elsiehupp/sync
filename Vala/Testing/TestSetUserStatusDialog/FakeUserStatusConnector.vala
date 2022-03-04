/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

class FakeUserStatusConnector : Occ.UserStatusConnector {

    /***********************************************************
    ***********************************************************/
    public void fetchUserStatus () override {
        if (this.couldNotFetchUserStatus) {
            /* emit */ error (Error.CouldNotFetchUserStatus);
            return;
        } else if (this.userStatusNotSupported) {
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        } else if (this.emojisNotSupported) {
            /* emit */ error (Error.EmojisNotSupported);
            return;
        }

        /* emit */ userStatusFetched (this.userStatus);
    }


    /***********************************************************
    ***********************************************************/
    public void fetchPredefinedStatuses () override {
        if (this.couldNotFetchPredefinedUserStatuses) {
            /* emit */ error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        /* emit */ predefinedStatusesFetched (this.predefinedStatuses);
    }


    /***********************************************************
    ***********************************************************/
    public void setUserStatus (Occ.UserStatus userStatus) override {
        if (this.couldNotSetUserStatusMessage) {
            /* emit */ error (Error.CouldNotSetUserStatus);
            return;
        }

        this.userStatusSetByCallerOfSetUserStatus = userStatus;
        /* emit */ UserStatusConnector.userStatusSet ();
    }


    /***********************************************************
    ***********************************************************/
    public void clearMessage () override {
        if (this.couldNotClearUserStatusMessage) {
            /* emit */ error (Error.CouldNotClearMessage);
        } else {
            this.isMessageCleared = true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public Occ.UserStatus userStatus () override {
        return {}; // Not implemented
    }


    /***********************************************************
    ***********************************************************/
    public void setFakeUserStatus (Occ.UserStatus userStatus) {
        this.userStatus = userStatus;
    }


    /***********************************************************
    ***********************************************************/
    public void setFakePredefinedStatuses (
        const GLib.Vector<Occ.UserStatus> statuses) {
        this.predefinedStatuses = statuses;
    }


    /***********************************************************
    ***********************************************************/
    public Occ.UserStatus userStatusSetByCallerOfSetUserStatus () { return this.userStatusSetByCallerOfSetUserStatus; }


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void setErrorCouldNotFetchPredefinedUserStatuses (bool value) {
        this.couldNotFetchPredefinedUserStatuses = value;
    }


    /***********************************************************
    ***********************************************************/
    public void setErrorCouldNotFetchUserStatus (bool value) {
        this.couldNotFetchUserStatus = value;
    }


    /***********************************************************
    ***********************************************************/
    public void setErrorCouldNotSetUserStatusMessage (bool value) {
        this.couldNotSetUserStatusMessage = value;
    }


    /***********************************************************
    ***********************************************************/
    public void setErrorUserStatusNotSupported (bool value) {
        this.userStatusNotSupported = value;
    }


    /***********************************************************
    ***********************************************************/
    public void setErrorEmojisNotSupported (bool value) {
        this.emojisNotSupported = value;
    }


    /***********************************************************
    ***********************************************************/
    public void setErrorCouldNotClearUserStatusMessage (bool value) {
        this.couldNotClearUserStatusMessage = value;
    }


    /***********************************************************
    ***********************************************************/
    private Occ.UserStatus this.userStatusSetByCallerOfSetUserStatus;
    private Occ.UserStatus this.userStatus;
    private GLib.Vector<Occ.UserStatus> this.predefinedStatuses;
    private bool this.isMessageCleared = false;
    private bool this.couldNotFetchPredefinedUserStatuses = false;
    private bool this.couldNotFetchUserStatus = false;
    private bool this.couldNotSetUserStatusMessage = false;
    private bool this.userStatusNotSupported = false;
    private bool this.emojisNotSupported = false;
    private bool this.couldNotClearUserStatusMessage = false;
};