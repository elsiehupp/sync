/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

class FakeUserStatusConnector : Occ.UserStatusConnector {


    /***********************************************************
    ***********************************************************/
    private Occ.UserStatus user_status_set_by_caller_of_set_user_status;
    private Occ.UserStatus user_status;
    private GLib.Vector<Occ.UserStatus> predefined_statuses;
    private bool is_message_cleared = false;
    private bool could_not_fetch_predefined_user_statuses = false;
    private bool could_not_fetch_user_status = false;
    private bool could_not_set_user_status_message = false;
    private bool user_status_not_supported = false;
    private bool emojis_not_supported = false;
    private bool could_not_clear_user_status_message = false;

    /***********************************************************
    ***********************************************************/
    public override void fetch_user_status () {
        if (this.could_not_fetch_user_status) {
            /* emit */ error (Error.CouldNotFetchUserStatus);
            return;
        } else if (this.user_status_not_supported) {
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        } else if (this.emojis_not_supported) {
            /* emit */ error (Error.EmojisNotSupported);
            return;
        }

        /* emit */ user_status_fetched (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_predefined_statuses () {
        if (this.could_not_fetch_predefined_user_statuses) {
            /* emit */ error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        /* emit */ predefined_statuses_fetched (this.predefined_statuses);
    }


    /***********************************************************
    ***********************************************************/
    public override void set_user_status (Occ.UserStatus user_status) {
        if (this.could_not_set_user_status_message) {
            /* emit */ error (Error.CouldNotSetUserStatus);
            return;
        }

        this.user_status_set_by_caller_of_set_user_status = user_status;
        /* emit */ UserStatusConnector.user_status_set ();
    }


    /***********************************************************
    ***********************************************************/
    public override void clear_message () {
        if (this.could_not_clear_user_status_message) {
            /* emit */ error (Error.CouldNotClearMessage);
        } else {
            this.is_message_cleared = true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public override Occ.UserStatus user_status () {
        return {}; // Not implemented
    }


    /***********************************************************
    ***********************************************************/
    public void set_fake_user_status (Occ.UserStatus user_status) {
        this.user_status = user_status;
    }


    /***********************************************************
    ***********************************************************/
    public void set_fake_predefined_statuses (
        const GLib.Vector<Occ.UserStatus> statuses) {
        this.predefined_statuses = statuses;
    }


    /***********************************************************
    ***********************************************************/
    public Occ.UserStatus user_status_set_by_caller_of_set_user_status () {
        return this.user_status_set_by_caller_of_set_user_status;
    }


    //  /***********************************************************
    //  ***********************************************************/
    //  public 

    //  /***********************************************************
    //  ***********************************************************/
    //  public 

    /***********************************************************
    ***********************************************************/
    public void set_error_could_not_fetch_predefined_user_statuses (bool value) {
        this.could_not_fetch_predefined_user_statuses = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_could_not_fetch_user_status (bool value) {
        this.could_not_fetch_user_status = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_could_not_set_user_status_message (bool value) {
        this.could_not_set_user_status_message = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_user_status_not_supported (bool value) {
        this.user_status_not_supported = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_emojis_not_supported (bool value) {
        this.emojis_not_supported = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_could_not_clear_user_status_message (bool value) {
        this.could_not_clear_user_status_message = value;
    }

}
}
