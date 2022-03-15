/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <ocsuserstatusconnector.h>
//  #include <qnamespace.h>
//  #include <userstatusconnector.h>
//  #include <theme.h>
//  #include <QLoggingCa
//  #include <algorithm>
//  #include <cmath>
//  #include <cstddef>
//  #include <userstatusconnector.h>
//  #include <datetimeprovider.h>
//  #include <QMetaType>
//  #include <Qt_numer
//  #include <cstddef>
//  #include <memory>
//  #include <vector>

namespace Occ {
namespace Ui {

public class UserStatusSelectorModel : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private enum ClearStageType {
        DO_NOT_CLEAR,
        HALF_HOUR,
        ONE_HOUR,
        FOUR_HOUR,
        TODAY,
        WEEK
    }

    /***********************************************************
    ***********************************************************/
    private std.shared_ptr<UserStatusConnector> user_status_connector = new UserStatusConnector ();
    private GLib.Vector<UserStatus> predefined_statuses;
    private UserStatus user_status;
    private std.unique_ptr<DateTimeProvider> date_time_provider = new DateTimeProvider ();

    /***********************************************************
    ***********************************************************/
    string error_message { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private GLib.Vector<ClearStageType> clear_stages = {
        ClearStageType.DO_NOT_CLEAR,
        ClearStageType.HALF_HOUR,
        ClearStageType.ONE_HOUR,
        ClearStageType.FOUR_HOUR,
        ClearStageType.TODAY,
        ClearStageType.WEEK
    };


    signal void error_message_changed ();
    signal void user_status_changed ();
    signal void online_status_changed ();
    signal void clear_at_changed ();
    signal void predefined_statuses_changed ();
    signal void on_signal_finished ();
        

    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.date_time_provider = new DateTimeProvider ();
        this.user_status.icon ("😀");
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_connector (
        std.shared_ptr<UserStatusConnector> user_status_connector,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.user_status_connector = user_status_connector;
        this.user_status = new UserStatus ("no-identifier", "", "😀", UserStatus.OnlineStatus.Online, false, {});
        this.date_time_provider = new DateTimeProvider ();
        this.user_status.icon ("😀");
        on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_connector_and_provider (
        std.shared_ptr<UserStatusConnector> user_status_connector,
        std.unique_ptr<DateTimeProvider> date_time_provider = new DateTimeProvider (),
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.user_status_connector = user_status_connector;
        this.date_time_provider = std.move (date_time_provider);
        this.user_status = new UserStatus ();
        this.user_status.icon ("😀");
        on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_user_status_and_provider (
        UserStatus user_status,
        std.unique_ptr<DateTimeProvider> date_time_provider,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.user_status = user_status;
        this.date_time_provider = std.move (date_time_provider);
        this.user_status.icon ("😀");
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_user_status (
        UserStatus user_status,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.user_status = user_status;
        this.user_status.icon ("😀");
    }


    UserStatus.OnlineStatus online_status {
        public get {
            return this.user_status.state ();
        }
        public set {
            if (value == this.user_status.state ()) {
                return;
            }
    
            this.user_status.state (value);
            /* emit */ online_status_changed ();
        }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri online_icon () {
        return Theme.instance ().status_online_image_source ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri away_icon () {
        return Theme.instance ().status_away_image_source ();
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri dnd_icon () {
        return Theme.instance ().status_do_not_disturb_image_source ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri invisible_icon () {
        return Theme.instance ().status_invisible_image_source ();
    }


    string user_status_message {
        public get {
            return this.user_status.message ();
        }
        public set {
            this.user_status.message (value);
            this.user_status.message_predefined (false);
            /* emit */ user_status_changed ();
        }
    }


    string user_status_emoji {
        public get {
            return this.user_status.icon ();
        }
        public set {
            this.user_status.icon (value);
            this.user_status.message_predefined (false);
            /* emit */ user_status_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void update_user_status () {
        //  Q_ASSERT (this.user_status_connector);
        if (!this.user_status_connector) {
            return;
        }

        clear_error ();
        this.user_status_connector.user_status (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    public void clear_user_status () {
        //  Q_ASSERT (this.user_status_connector);
        if (!this.user_status_connector) {
            return;
        }

        clear_error ();
        this.user_status_connector.clear_message ();
    }


    /***********************************************************
    ***********************************************************/
    public int predefined_statuses_count () {
        return static_cast<int> (this.predefined_statuses.size ());
    }


    /***********************************************************
    ***********************************************************/
    public UserStatus predefined_status_for_index (int index) {
        //  Q_ASSERT (0 <= index && index < static_cast<int> (this.predefined_statuses.size ()));
        return this.predefined_statuses[index];
    }


    /***********************************************************
    ***********************************************************/
    public string predefined_status_clear_at (int index) {
        return clear_at_readable (predefined_status (index).clear_at ());
    }


    /***********************************************************
    ***********************************************************/
    public void predefined_status (int index) {
        //  Q_ASSERT (0 <= index && index < static_cast<int> (this.predefined_statuses.size ()));

        this.user_status.message_predefined (true);
        const var predefined_status = this.predefined_statuses[index];
        this.user_status.id (predefined_status.identifier ());
        this.user_status.message (predefined_status.message ());
        this.user_status.icon (predefined_status.icon ());
        this.user_status.clear_at (predefined_status.clear_at ());

        /* emit */ user_status_changed ();
        /* emit */ clear_at_changed ();
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string[] clear_at_values () {
        string[] clear_at_stages;
        std.transform (
            this.clear_stages.begin (),
            this.clear_stages.end (),
            std.back_inserter (clear_at_stages)
            //  [this] (ClearStageType stage) => {
            //      return clear_at_stage_to_string (stage);
            //  }
        );

        return clear_at_stages;
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string clear_at () {
        return clear_at_readable (this.user_status.clear_at ());
    }


    /***********************************************************
    ***********************************************************/
    public void clear_at_for_index (int index) {
        //  Q_ASSERT (0 <= index && index < static_cast<int> (this.clear_stages.size ()));
        this.user_status.clear_at (clear_stage_type_to_date_time (this.clear_stages[index]));
        /* emit */ clear_at_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init () {
        if (!this.user_status_connector) {
            return;
        }

        connect (
            this.user_status_connector.get (),
            UserStatusConnector.user_status_fetched,
            this,
            UserStatusSelectorModel.on_signal_user_status_fetched
        );
        connect (
            this.user_status_connector.get (),
            UserStatusConnector.predefined_statuses_fetched,
            this,
            UserStatusSelectorModel.on_signal_predefined_statuses_fetched
        );
        connect (
            this.user_status_connector.get (),
            UserStatusConnector.error,
            this,
            UserStatusSelectorModel.on_signal_error
        );
        connect (
            this.user_status_connector.get (),
            UserStatusConnector.user_status_set,
            this,
            UserStatusSelectorModel.on_signal_user_status_set
        );
        connect (
            this.user_status_connector.get (),
            UserStatusConnector.message_cleared,
            this,
            UserStatusSelectorModel.on_signal_message_cleared
        );

        this.user_status_connector.fetch_user_status ();
        this.user_status_connector.fetch_predefined_statuses ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_load (int identifier) {
        on_signal_reset ();
        this.user_status_connector = UserModel.instance ().user_status_connector (identifier);
        on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_reset () {
        if (this.user_status_connector) {
            disconnect (this.user_status_connector.get (), UserStatusConnector.user_status_fetched, this,
                &UserStatusSelectorModel.on_signal_user_status_fetched);
            disconnect (this.user_status_connector.get (), UserStatusConnector.predefined_statuses_fetched, this,
                &UserStatusSelectorModel.on_signal_predefined_statuses_fetched);
            disconnect (this.user_status_connector.get (), UserStatusConnector.error, this,
                &UserStatusSelectorModel.on_signal_error);
            disconnect (this.user_status_connector.get (), UserStatusConnector.user_status_set, this,
                &UserStatusSelectorModel.on_signal_user_status_set);
            disconnect (this.user_status_connector.get (), UserStatusConnector.message_cleared, this,
                &UserStatusSelectorModel.on_signal_message_cleared);
        }
        this.user_status_connector = null;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_fetched (UserStatus user_status) {
        if (user_status.state () != UserStatus.OnlineStatus.Offline) {
            this.user_status.state (user_status.state ());
        }
        this.user_status.message (user_status.message ());
        this.user_status.message_predefined (user_status.message_predefined ());
        this.user_status.id (user_status.identifier ());
        this.user_status.clear_at (user_status.clear_at ());

        if (!user_status.icon () == "") {
            this.user_status.icon (user_status.icon ());
        }

        /* emit */ user_status_changed ();
        /* emit */ online_status_changed ();
        /* emit */ clear_at_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_predefined_statuses_fetched (GLib.Vector<UserStatus> statuses) {
        this.predefined_statuses = statuses;
        /* emit */ predefined_statuses_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_set () {
        /* emit */ finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_message_cleared () {
        /* emit */ finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_error (UserStatusConnector.Error error) {
        GLib.warning ("Error: " + error);

        switch (error) {
        case UserStatusConnector.Error.CouldNotFetchPredefinedUserStatuses:
            error (_("Could not fetch predefined statuses. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.CouldNotFetchUserStatus:
            error (_("Could not fetch user status. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.UserStatusResult.NOT_SUPPORTED:
            error (_("User status feature is not supported. You will not be able to set your user status."));
            return;

        case UserStatusConnector.Error.EmojisResult.NOT_SUPPORTED:
            error (_("Emojis feature is not supported. Some user status functionality may not work."));
            return;

        case UserStatusConnector.Error.CouldNotSetUserStatus:
            error (_("Could not set user status. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.CouldNotClearMessage:
            error (_("Could not clear user status message. Make sure you are connected to the server."));
            return;
        }

        GLib.assert_not_reached ();
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private string clear_at_stage_to_string (ClearStageType stage) {
        switch (stage) {
        case ClearStageType.DO_NOT_CLEAR:
            return _("Don't clear");

        case ClearStageType.HALF_HOUR:
            return _("30 minutes");

        case ClearStageType.ONE_HOUR:
            return _("1 hour");

        case ClearStageType.FOUR_HOUR:
            return _("4 hours");

        case ClearStageType.TODAY:
            return _("Today");

        case ClearStageType.WEEK:
            return _("This week");

        default:
            GLib.assert_not_reached ();
        }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private string clear_at_readable (Optional<ClearAt> clear_at) {
        if (clear_at) {
            switch (clear_at.type) {
            case ClearAtType.Period: {
                return time_difference_to_string (clear_at.period);
            }

            case ClearAtType.Timestamp: {
                const int difference = static_cast<int> (clear_at.timestamp - this.date_time_provider.current_date_time ().to_time_t ());
                return time_difference_to_string (difference);
            }

            case ClearAtType.EndOf: {
                if (clear_at.endof == "day") {
                    return _("Today");
                } else if (clear_at.endof == "week") {
                    return _("This week");
                }
                GLib.assert_not_reached ();
            }

            default:
                GLib.assert_not_reached ();
            }
        }
        return _("Don't clear");
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private static string time_difference_to_string (int difference_secs) {
        if (difference_secs < 60) {
            return _("Less than a minute");
        } else if (difference_secs < 60 * 60) {
            const var minutes_left = std.ceil (difference_secs / 60.0);
            if (minutes_left == 1) {
                return _("1 minute");
            } else {
                return _("%1 minutes").printf (minutes_left);
            }
        } else if (difference_secs < 60 * 60 * 24) {
            const var hours_left = std.ceil (difference_secs / 60.0 / 60.0);
            if (hours_left == 1) {
                return _("1 hour");
            } else {
                return _("%1 hours").printf (hours_left);
            }
        } else {
            const var days_left = std.ceil (difference_secs / 60.0 / 60.0 / 24.0);
            if (days_left == 1) {
                return _("1 day");
            } else {
                return _("%1 days").printf (days_left);
            }
        }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private static Optional<ClearAt> clear_stage_type_to_date_time (ClearStageType type) {
        switch (type) {
        case ClearStageType.DO_NOT_CLEAR:
            return {};

        case ClearStageType.HALF_HOUR: {
            ClearAt clear_at;
            clear_at.type = ClearAtType.Period;
            clear_at.period = 60 * 30;
            return clear_at;
        }

        case ClearStageType.ONE_HOUR: {
            ClearAt clear_at;
            clear_at.type = ClearAtType.Period;
            clear_at.period = 60 * 60;
            return clear_at;
        }

        case ClearStageType.FOUR_HOUR: {
            ClearAt clear_at;
            clear_at.type = ClearAtType.Period;
            clear_at.period = 60 * 60 * 4;
            return clear_at;
        }

        case ClearStageType.TODAY: {
            ClearAt clear_at;
            clear_at.type = ClearAtType.EndOf;
            clear_at.endof = "day";
            return clear_at;
        }

        case ClearStageType.WEEK: {
            ClearAt clear_at;
            clear_at.type = ClearAtType.EndOf;
            clear_at.endof = "week";
            return clear_at;
        }

        default:
            GLib.assert_not_reached ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void error (string reason) {
        this.error_message = reason;
        /* emit */ error_message_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void clear_error () {
        error ("");
    }

} // class UserStatusSelectorModel

} // namespace Ui
} // namespace Occ
