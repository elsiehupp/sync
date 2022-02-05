/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class UserStatus {
    // Q_GADGET

    //  Q_PROPERTY (string identifier MEMBER this.identifier)
    //  Q_PROPERTY (string message MEMBER this.message)
    //  Q_PROPERTY (string icon MEMBER this.icon)
    //  Q_PROPERTY (OnlineStatus state MEMBER this.state)


    /***********************************************************
    ***********************************************************/
    public enum OnlineStatus : uint8 {
        Online,
        DoNotDisturb,
        Away,
        Offline,
        Invisible
    }

    /***********************************************************
    ***********************************************************/
    public UserStatus ();

    /***********************************************************
    ***********************************************************/
    public UserStatus (string identifier, string message, string icon,
        OnlineStatus state, bool message_predefined, Optional<ClearAt> clear_at = {});


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string identifier ();


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
    public void id (string identifier) {
        this.identifier = identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void UserStatus.message (string message) {
        this.message = message;
    }


    /***********************************************************
    ***********************************************************/
    public void state (OnlineStatus state) {
        this.state = state;
    }



    /***********************************************************
    ***********************************************************/
    public void icon (string icon) {
        this.icon = icon;
    }


    /***********************************************************
    ***********************************************************/
    public void message_predefined (bool value) {
        this.message_predefined = value;
    }


    /***********************************************************
    ***********************************************************/
    public void clear_at (Optional<ClearAt> date_time) {
        this.clear_at = date_time;
    }

    //  Q_REQUIRED_RESULT
    public bool message_predefined ();

    //  Q_REQUIRED_RESULT
    public GLib.Uri state_icon ();


    /***********************************************************
    ***********************************************************/
    private string this.identifier;
    private string this.message;
    private string this.icon;
    private OnlineStatus this.state = OnlineStatus.Online;
    private bool this.message_predefined;
    private Optional<ClearAt> this.clear_at;
}




UserStatus.UserStatus () = default;

UserStatus.UserStatus (
    const string identifier, string message, string icon,
    OnlineStatus state, bool message_predefined, Optional<ClearAt> clear_at)
    : this.identifier (identifier)
    this.message (message)
    this.icon (icon)
    this.state (state)
    this.message_predefined (message_predefined)
    this.clear_at (clear_at) {
}

string UserStatus.identifier () {
    return this.identifier;
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