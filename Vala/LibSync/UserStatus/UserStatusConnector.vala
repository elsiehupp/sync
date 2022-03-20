/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/


//  #include <QMetaType>
//  #include <QtGlobal>
//  #include <vector>

namespace Occ {
namespace LibSync {

abstract class UserStatusConnector : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Error {
        CouldNotFetchUserStatus,
        CouldNotFetchPredefinedUserStatuses,
        UserStatusNotSupported,
        EmojisNotSupported,
        CouldNotSetUserStatus,
        CouldNotClearMessage
    }

    UserStatus user_status { public get; public set; }

    internal signal void signal_user_status_fetched (UserStatus user_status);
    internal signal void signal_predefined_statuses_fetched (GLib.List<UserStatus> statuses);
    internal signal void signal_user_status_set ();
    internal signal void signal_message_cleared ();
    internal signal void signal_error (Error error);

    /***********************************************************
    ***********************************************************/
    protected UserStatusConnector (GLib.Object parent = new GLib.Object ()) {
        base (parent);
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

} // class UserStatusConnector

} // namespace LibSync
} // namespace Occ
