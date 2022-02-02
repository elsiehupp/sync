/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QMetaType>
// #include <GLib.Uri>
// #include <QtGlobal>
// #include <GLib.Variant>

// #include <vector>

namespace Occ {

enum class ClearAtType {
    Period,
    EndOf,
    Timestamp
};

// TODO: If we can use C++17 make it a std.variant
struct ClearAt {
    ClearAtType this.type = ClearAtType.Period;

    uint64 this.timestamp;
    int this.period;
    string this.endof;
};

class UserStatus {
    // Q_GADGET

    Q_PROPERTY (string id MEMBER this.id)
    Q_PROPERTY (string message MEMBER this.message)
    Q_PROPERTY (string icon MEMBER this.icon)
    Q_PROPERTY (OnlineStatus state MEMBER this.state)


    /***********************************************************
    ***********************************************************/
    public enum OnlineStatus : uint8 {
        Online,
        DoNotDisturb,
        Away,
        Offline,
        Invisible
    };

    /***********************************************************
    ***********************************************************/
    public UserStatus ();

    /***********************************************************
    ***********************************************************/
    public UserStatus (string id, string message, string icon,
        OnlineStatus state, bool message_predefined, Optional<ClearAt> clear_at = {});


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string id ();


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string message ();


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string icon ();


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public OnlineStatus state ();


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public Optional<ClearAt> clear_at () {
        return this.clear_at;
    }

    /***********************************************************
    ***********************************************************/
    public void set_id (string id) {
        this.id = id;
    }


    /***********************************************************
    ***********************************************************/
    public void UserStatus.set_message (string message) {
        this.message = message;
    }


    /***********************************************************
    ***********************************************************/
    public void set_state (OnlineStatus state) {
        this.state = state;
    }



    /***********************************************************
    ***********************************************************/
    public void set_icon (string icon) {
        this.icon = icon;
    }


    /***********************************************************
    ***********************************************************/
    public void set_message_predefined (bool value) {
        this.message_predefined = value;
    }


    /***********************************************************
    ***********************************************************/
    public void set_clear_at (Optional<ClearAt> date_time) {
        this.clear_at = date_time;
    }

    //  Q_REQUIRED_RESULT
    public bool message_predefined ();

    //  Q_REQUIRED_RESULT
    public GLib.Uri state_icon ();


    /***********************************************************
    ***********************************************************/
    private string this.id;
    private string this.message;
    private string this.icon;
    private OnlineStatus this.state = OnlineStatus.Online;
    private bool this.message_predefined;
    private Optional<ClearAt> this.clear_at;
};

class UserStatusConnector : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum class Error {
        CouldNotFetchUserStatus,
        CouldNotFetchPredefinedUserStatuses,
        UserStatusNotSupported,
        EmojisNotSupported,
        CouldNotSetUserStatus,
        CouldNotClearMessage
    };

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
    public virtual void set_user_status (UserStatus user_status);

    /***********************************************************
    ***********************************************************/
    public virtual void clear_message ();

    /***********************************************************
    ***********************************************************/
    public virtual UserStatus user_status ();

signals:
    void user_status_fetched (UserStatus user_status);
    void predefined_statuses_fetched (std.vector<UserStatus> statuses);
    void user_status_set ();
    void message_cleared ();
    void error (Error error);
};


    UserStatus.UserStatus () = default;

    UserStatus.UserStatus (
        const string id, string message, string icon,
        OnlineStatus state, bool message_predefined, Optional<ClearAt> clear_at)
        : this.id (id)
        , this.message (message)
        , this.icon (icon)
        , this.state (state)
        , this.message_predefined (message_predefined)
        , this.clear_at (clear_at) {
    }

    string UserStatus.id () {
        return this.id;
    }

    string UserStatus.message () {
        return this.message;
    }

    string UserStatus.icon () {
        return this.icon;
    }

    var UserStatus.state () . OnlineStatus {
        return this.state;
    }

    bool UserStatus.message_predefined () {
        return this.message_predefined;
    }

    GLib.Uri UserStatus.state_icon () {
        switch (this.state) {
        case UserStatus.OnlineStatus.Away:
            return Theme.instance ().status_away_image_source ();

        case UserStatus.OnlineStatus.DoNotDisturb:
            return Theme.instance ().status_do_not_disturb_image_source ();

        case UserStatus.OnlineStatus.Invisible:
        case UserStatus.OnlineStatus.Offline:
            return Theme.instance ().status_invisible_image_source ();

        case UserStatus.OnlineStatus.Online:
            return Theme.instance ().status_online_image_source ();
        }

        Q_UNREACHABLE ();
    }


    UserStatusConnector.UserStatusConnector (GLib.Object parent) {
        base (parent);
    }

    UserStatusConnector.~UserStatusConnector () = default;
    }
    