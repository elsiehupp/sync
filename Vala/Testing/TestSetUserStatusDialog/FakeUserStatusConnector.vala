/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeUserStatusConnector : AbstractUserStatusConnector {

    /***********************************************************
    ***********************************************************/
    private UserStatus user_status_set_by_caller_of_set_user_status;
    public UserStatus user_status {
        // get Not implemented
        public set {
            /* emit */ signal_error (Error.COULD_NOT_SET_USER_STATUS);
            return;
        }

        this.user_status_set_by_caller_of_set_user_status = value;
        /* emit */ AbstractUserStatusConnector.signal_user_status_set ();}
    }
    private GLib.List<UserStatus> predefined_statuses;
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
            /* emit */ signal_error (Error.COULD_NOT_FETCH_USER_STATUS);
            return;
        } else if (this.user_status_not_supported) {
            /* emit */ signal_error (Error.USER_STATUS_NOT_SUPPORTED);
            return;
        } else if (this.emojis_not_supported) {
            /* emit */ signal_error (Error.EMOJIS_NOT_SUPPORTED);
            return;
        }

        /* emit */ signal_user_status_fetched (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_predefined_statuses () {
        if (this.could_not_fetch_predefined_user_statuses) {
            /* emit */ signal_error (Error.COULD_NOT_FETCH_PREDEFINED_USER_STATUSES);
            return;
        }
        /* emit */ signal_predefined_statuses_fetched (this.predefined_statuses);
    }


    /***********************************************************
    ***********************************************************/
    public override void clear_message () {
        if (this.could_not_clear_user_status_message) {
            /* emit */ signal_error (Error.COULD_NOT_CLEAR_MESSAGE);
        } else {
            this.is_message_cleared = true;
        }
    }

} // class FakeUserStatusConnector

} // namespace Testing
} // namespace Occ
