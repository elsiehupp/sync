/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


//  #include <QMetaType>
//  #include <QtGlobal>
//  #include <vector>

namespace Occ {




class UserStatusConnector : GLib.Object {

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

    /***********************************************************
    ***********************************************************/
    public UserStatusConnector (GLib.Object parent = new GLib.Object ());

    ~UserStatusConnector () override;

    /***********************************************************
    ***********************************************************/
    public virtual void fetch_user_status ();

    /***********************************************************
    ***********************************************************/
    public virtual void fetch_predefined_statuses ();

    /***********************************************************
    ***********************************************************/
    public virtual void user_status (UserStatus user_status);

    /***********************************************************
    ***********************************************************/
    public virtual void clear_message ();

    /***********************************************************
    ***********************************************************/
    public virtual UserStatus user_status ();

signals:
    void user_status_fetched (UserStatus user_status);
    void predefined_statuses_fetched (GLib.Vector<UserStatus> statuses);
    void user_status_set ();
    void message_cleared ();
    void error (Error error);
}




    UserStatusConnector.UserStatusConnector (GLib.Object parent) {
        base (parent);
    }

    UserStatusConnector.~UserStatusConnector () = default;
    }
    