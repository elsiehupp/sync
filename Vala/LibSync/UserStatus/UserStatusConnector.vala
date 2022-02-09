/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


//  #include <QMetaType>
//  #include <QtGlobal>
//  #include <vector>

namespace Occ {

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

    signal void user_status_fetched (UserStatus user_status);
    signal void predefined_statuses_fetched (GLib.List<UserStatus> statuses);
    signal void user_status_set ();
    signal void message_cleared ();
    signal void error (Error error);

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

} // namespace Occ
