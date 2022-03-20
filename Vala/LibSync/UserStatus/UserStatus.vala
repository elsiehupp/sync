/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

public class UserStatus : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum OnlineStatus {
        Online,
        DoNotDisturb,
        Away,
        Offline,
        Invisible
    }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    string identifier { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    string message { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    string icon { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    OnlineStatus state { public get; public set; }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    bool message_predefined { public get; public set; }

    /***********************************************************
    Optional<ClearAt> date_time
    Q_REQUIRED_RESULT
    ***********************************************************/
    Optional<ClearAt> clear_at { public get; public set; }

    /***********************************************************
    ***********************************************************/
    public UserStatus (string identifier, string message, string icon,
        OnlineStatus state = OnlineStatus.Online, bool message_predefined, Optional<ClearAt> clear_at = new Optional<ClearAt> ()) {
        this.identifier = identifier;
        this.message = message;
        this.icon = icon;
        this.state = state;
        this.message_predefined = message_predefined;
        this.clear_at = clear_at;
    }

    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri state_icon () {
        switch (this.state) {
        case UserStatus.OnlineStatus.Away:
            return Theme.status_away_image_source;

        case UserStatus.OnlineStatus.DoNotDisturb:
            return Theme.status_do_not_disturb_image_source;

        case UserStatus.OnlineStatus.Invisible:
        case UserStatus.OnlineStatus.Offline:
            return Theme.status_invisible_image_source;

        case UserStatus.OnlineStatus.Online:
            return Theme.status_online_image_source;
        }

        //  Q_UNREACHABLE ();
    }

} // class UserStatus

} // namespace LibSync
} // namespace Occ
