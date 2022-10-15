namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractUserStatusConnector

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public abstract class AbstractUserStatusConnector { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Error {
        COULD_NOT_FETCH_USER_STATUS,
        COULD_NOT_FETCH_PREDEFINED_USER_STATUSES,
        USER_STATUS_NOT_SUPPORTED,
        EMOJIS_NOT_SUPPORTED,
        COULD_NOT_SET_USER_STATUS,
        COULD_NOT_CLEAR_MESSAGE
    }

    UserStatus user_status { public get; public set; }

    internal signal void signal_user_status_fetched (UserStatus user_status);
    internal signal void signal_predefined_statuses_fetched (GLib.List<UserStatus> statuses);
    internal signal void signal_user_status_set ();
    internal signal void signal_message_cleared ();
    internal signal void signal_error (Error error);

    /***********************************************************
    ***********************************************************/
    protected AbstractUserStatusConnector (GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
    }

    /***********************************************************
    ***********************************************************/
    public abstract void fetch_user_status ();

    /***********************************************************
    ***********************************************************/
    public abstract void fetch_predefined_statuses ();

    /***********************************************************
    ***********************************************************/
    public abstract void clear_message ();

} // class AbstractUserStatusConnector

} // namespace LibSync
} // namespace Occ
