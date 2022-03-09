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
        } else if (this.user_statusNotSupported) {
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        } else if (this.emojisNotSupported) {
            /* emit */ error (Error.EmojisNotSupported);
            return;
        }

        /* emit */ user_statusFetched (this.user_status);
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
    public void setUserStatus (Occ.UserStatus user_status) override {
        if (this.couldNotSetUserStatusMessage) {
            /* emit */ error (Error.CouldNotSetUserStatus);
            return;
        }

        this.user_statusSetByCallerOfSetUserStatus = user_status;
        /* emit */ UserStatusConnector.user_statusSet ();
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
    public Occ.UserStatus user_status () override {
        return {}; // Not implemented
    }


    /***********************************************************
    ***********************************************************/
    public void setFakeUserStatus (Occ.UserStatus user_status) {
        this.user_status = user_status;
    }


    /***********************************************************
    ***********************************************************/
    public void setFakePredefinedStatuses (
        const GLib.Vector<Occ.UserStatus> statuses) {
        this.predefinedStatuses = statuses;
    }


    /***********************************************************
    ***********************************************************/
    public Occ.UserStatus user_statusSetByCallerOfSetUserStatus () { return this.user_statusSetByCallerOfSetUserStatus; }


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
        this.user_statusNotSupported = value;
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
    private Occ.UserStatus this.user_statusSetByCallerOfSetUserStatus;
    private Occ.UserStatus this.user_status;
    private GLib.Vector<Occ.UserStatus> this.predefinedStatuses;
    private bool this.isMessageCleared = false;
    private bool this.couldNotFetchPredefinedUserStatuses = false;
    private bool this.couldNotFetchUserStatus = false;
    private bool this.couldNotSetUserStatusMessage = false;
    private bool this.user_statusNotSupported = false;
    private bool this.emojisNotSupported = false;
    private bool this.couldNotClearUserStatusMessage = false;
};