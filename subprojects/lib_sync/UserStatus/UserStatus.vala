namespace Occ {
namespace LibSync {

/***********************************************************
@class UserStatus

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class UserStatus { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum OnlineStatus {
        ONLINE,
        DO_NOT_DISTURB,
        AWAY,
        OFFLINE,
        INVISIBLE
    }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string identifier { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string message { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string icon { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public OnlineStatus state { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public bool message_predefined { public get; public set; }

    /***********************************************************
    Gpseq.Optional<ClearAt> date_time
    Q_REQUIRED_RESULT
    ***********************************************************/
    public Gpseq.Optional<ClearAt> clear_at { public get; public set; }

    /***********************************************************
    ***********************************************************/
    public UserStatus (
        string identifier,
        string message,
        string icon,
        OnlineStatus state = OnlineStatus.ONLINE,
        bool message_predefined,
        Gpseq.Optional<ClearAt> clear_at = new Gpseq.Optional<ClearAt> ()
    ) {
        //  this.identifier = identifier;
        //  this.message = message;
        //  this.icon = icon;
        //  this.state = state;
        //  this.message_predefined = message_predefined;
        //  this.clear_at = clear_at;
    }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri state_icon () {
        //  switch (this.state) {
        //  case UserStatus.OnlineStatus.AWAY:
        //      return Theme.status_away_image_source;

        //  case UserStatus.OnlineStatus.DO_NOT_DISTURB:
        //      return Theme.status_do_not_disturb_image_source;

        //  case UserStatus.OnlineStatus.INVISIBLE:
        //  case UserStatus.OnlineStatus.OFFLINE:
        //      return Theme.status_invisible_image_source;

        //  case UserStatus.OnlineStatus.ONLINE:
        //      return Theme.status_online_image_source;
        //  }

        //  //  Q_UNREACHABLE ();
    }

} // class UserStatus

} // namespace LibSync
} // namespace Occ
