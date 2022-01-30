/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <ocsuserstatusconnector.h>
// #include <qnamespace.h>
// #include <userstatusconnector.h>
// #include <theme.h>

// #include <QDateTime>
// #include <QLoggingCategory>

// #include <algorithm>
// #include <cmath>
// #include <cstddef>

// #pragma once

// #include <userstatusconnector.h>
// #include <datetimeprovider.h>

// #include <QMetaType>
// #include <Qt_numeric>

// #include <cstddef>
// #include <memory>
// #include <vector>

namespace Occ {

class User_status_selector_model : GLib.Object {

    Q_PROPERTY (string user_status_message READ user_status_message NOTIFY user_status_changed)
    Q_PROPERTY (string user_status_emoji READ user_status_emoji WRITE set_user_status_emoji NOTIFY user_status_changed)
    Q_PROPERTY (Occ.UserStatus.OnlineStatus online_status READ online_status WRITE set_online_status NOTIFY online_status_changed)
    Q_PROPERTY (int predefined_statuses_count READ predefined_statuses_count NOTIFY predefined_statuses_changed)
    Q_PROPERTY (string[] clear_at_values READ clear_at_values CONSTANT)
    Q_PROPERTY (string clear_at READ clear_at NOTIFY clear_at_changed)
    Q_PROPERTY (string error_message READ error_message NOTIFY error_message_changed)
    Q_PROPERTY (GLib.Uri online_icon READ online_icon CONSTANT)
    Q_PROPERTY (GLib.Uri away_icon READ away_icon CONSTANT)
    Q_PROPERTY (GLib.Uri dnd_icon READ dnd_icon CONSTANT)
    Q_PROPERTY (GLib.Uri invisible_icon READ invisible_icon CONSTANT)

    /***********************************************************
    ***********************************************************/
    public User_status_selector_model (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public User_status_selector_model (std.shared_ptr<UserStatusConnector> user_status_connector,

    /***********************************************************
    ***********************************************************/
    public 
    public User_status_selector_model (std.shared_ptr<UserStatusConnector> user_status_connector,
        std.unique_ptr<DateTimeProvider> date_time_provider,
        GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public User_status_selector_model (UserStatus &user_status,
        std.unique_ptr<DateTimeProvider> date_time_provider,
        GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public User_status_selector_model (UserStatus &user_status,

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Q_INVOKABLE void set_online_status (Occ.Use

    /***********************************************************
    ***********************************************************/
    public Q_REQUIRED_RESULT GLib.Uri online_icon ()

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Q_REQUIRED_RESULT GLib.Uri dnd_icon ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Q_INVOKABLE void set_user_status_mess

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Q_REQUIRED_RESULT string user_status_emoji ();

    /***********************************************************
    ***********************************************************/
    public Q_INVOKABLE void set_user_status ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public Q_INVOKABLE UserStatus predefined_status (

    /***********************************************************
    ***********************************************************/
    public 
    public Q_INVOKABLE string predefined_status_clear_at (int index);


    public Q_INVOKABLE void set_predefined_status (int index);

    public Q_REQUIRED_RESULT string[] clear_at_values ();


    public Q_REQUIRED_RESULT string clear_at ();


    public Q_INVOKABLE void set_clear_at (int index);

    public Q_REQUIRED_RESULT string error_message ();

signals:
    void error_message_changed ();
    void user_status_changed ();
    void online_status_changed ();
    void clear_at_changed ();
    void predefined_statuses_changed ();
    void on_finished ();


    /***********************************************************
    ***********************************************************/
    private enum class Clear_stage_type {
        Dont_clear,
        Half_hour,
        One_hour,
        Four_hour,
        Today,
        Week
    };

    /***********************************************************
    ***********************************************************/
    private void on_init ();
    private void on_reset ();
    private void on_user_status_fetched (UserStatus &user_status);
    private void on_predefined_statuses_fetched (std.vector<UserStatus> &statuses);
    private void on_user_status_set ();
    private void on_message_cleared ();
    private void on_error (UserStatusConnector.Error error);

    //  Q_REQUIRED_RESULT
    private string clear_at_stage_to_string (Clear_stage_type stage);
    //  Q_REQUIRED_RESULT
    private string clear_at_readable (Optional<ClearAt> &clear_at);
    //  Q_REQUIRED_RESULT
    private string time_difference_to_string (int difference_secs);
    //  Q_REQUIRED_RESULT
    private Optional<ClearAt> clear_stage_type_to_date_time (Clear_stage_type type);
    private void set_error (string reason);
    private void clear_error ();

    /***********************************************************
    ***********************************************************/
    private std.shared_ptr<UserStatusConnector> _user_status_connector {};
    private std.vector<UserStatus> _predefined_statuses;
    private UserStatus _user_status;
    private std.unique_ptr<DateTimeProvider> _date_time_provider;

    /***********************************************************
    ***********************************************************/
    private string _error_message;

    /***********************************************************
    ***********************************************************/
    private std.vector<Clear_stage_type> _clear_stages = {
        Clear_stage_type.Dont_clear,
        Clear_stage_type.Half_hour,
        Clear_stage_type.One_hour,
        Clear_stage_type.Four_hour,
        Clear_stage_type.Today,
        Clear_stage_type.Week
    };
};

    User_status_selector_model.User_status_selector_model (GLib.Object parent)
        : GLib.Object (parent)
        , _date_time_provider (new DateTimeProvider) {
        _user_status.set_icon ("😀");
    }

    User_status_selector_model.User_status_selector_model (std.shared_ptr<UserStatusConnector> user_status_connector, GLib.Object parent)
        : GLib.Object (parent)
        , _user_status_connector (user_status_connector)
        , _user_status ("no-id", "", "😀", UserStatus.OnlineStatus.Online, false, {})
        , _date_time_provider (new DateTimeProvider) {
        _user_status.set_icon ("😀");
        on_init ();
    }

    User_status_selector_model.User_status_selector_model (std.shared_ptr<UserStatusConnector> user_status_connector,
        std.unique_ptr<DateTimeProvider> date_time_provider,
        GLib.Object parent)
        : GLib.Object (parent)
        , _user_status_connector (user_status_connector)
        , _date_time_provider (std.move (date_time_provider)) {
        _user_status.set_icon ("😀");
        on_init ();
    }

    User_status_selector_model.User_status_selector_model (UserStatus &user_status,
        std.unique_ptr<DateTimeProvider> date_time_provider, GLib.Object parent)
        : GLib.Object (parent)
        , _user_status (user_status)
        , _date_time_provider (std.move (date_time_provider)) {
        _user_status.set_icon ("😀");
    }

    User_status_selector_model.User_status_selector_model (UserStatus &user_status,
        GLib.Object parent)
        : GLib.Object (parent)
        , _user_status (user_status) {
        _user_status.set_icon ("😀");
    }

    void User_status_selector_model.on_load (int id) {
        on_reset ();
        _user_status_connector = User_model.instance ().user_status_connector (id);
        on_init ();
    }

    void User_status_selector_model.on_reset () {
        if (_user_status_connector) {
            disconnect (_user_status_connector.get (), &UserStatusConnector.user_status_fetched, this,
                &User_status_selector_model.on_user_status_fetched);
            disconnect (_user_status_connector.get (), &UserStatusConnector.predefined_statuses_fetched, this,
                &User_status_selector_model.on_predefined_statuses_fetched);
            disconnect (_user_status_connector.get (), &UserStatusConnector.error, this,
                &User_status_selector_model.on_error);
            disconnect (_user_status_connector.get (), &UserStatusConnector.user_status_set, this,
                &User_status_selector_model.on_user_status_set);
            disconnect (_user_status_connector.get (), &UserStatusConnector.message_cleared, this,
                &User_status_selector_model.on_message_cleared);
        }
        _user_status_connector = nullptr;
    }

    void User_status_selector_model.on_init () {
        if (!_user_status_connector) {
            return;
        }

        connect (_user_status_connector.get (), &UserStatusConnector.user_status_fetched, this,
            &User_status_selector_model.on_user_status_fetched);
        connect (_user_status_connector.get (), &UserStatusConnector.predefined_statuses_fetched, this,
            &User_status_selector_model.on_predefined_statuses_fetched);
        connect (_user_status_connector.get (), &UserStatusConnector.error, this,
            &User_status_selector_model.on_error);
        connect (_user_status_connector.get (), &UserStatusConnector.user_status_set, this,
            &User_status_selector_model.on_user_status_set);
        connect (_user_status_connector.get (), &UserStatusConnector.message_cleared, this,
            &User_status_selector_model.on_message_cleared);

        _user_status_connector.fetch_user_status ();
        _user_status_connector.fetch_predefined_statuses ();
    }

    void User_status_selector_model.on_user_status_set () {
        emit finished ();
    }

    void User_status_selector_model.on_message_cleared () {
        emit finished ();
    }

    void User_status_selector_model.on_error (UserStatusConnector.Error error) {
        GLib.warn (lc_user_status_dialog_model) << "Error:" << error;

        switch (error) {
        case UserStatusConnector.Error.CouldNotFetchPredefinedUserStatuses:
            set_error (_("Could not fetch predefined statuses. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.CouldNotFetchUserStatus:
            set_error (_("Could not fetch user status. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.UserStatusNotSupported:
            set_error (_("User status feature is not supported. You will not be able to set your user status."));
            return;

        case UserStatusConnector.Error.EmojisNotSupported:
            set_error (_("Emojis feature is not supported. Some user status functionality may not work."));
            return;

        case UserStatusConnector.Error.CouldNotSetUserStatus:
            set_error (_("Could not set user status. Make sure you are connected to the server."));
            return;

        case UserStatusConnector.Error.CouldNotClearMessage:
            set_error (_("Could not clear user status message. Make sure you are connected to the server."));
            return;
        }

        Q_UNREACHABLE ();
    }

    void User_status_selector_model.set_error (string reason) {
        _error_message = reason;
        emit error_message_changed ();
    }

    void User_status_selector_model.clear_error () {
        set_error ("");
    }

    void User_status_selector_model.set_online_status (UserStatus.OnlineStatus status) {
        if (status == _user_status.state ()) {
            return;
        }

        _user_status.set_state (status);
        emit online_status_changed ();
    }

    GLib.Uri User_status_selector_model.online_icon () {
        return Theme.instance ().status_online_image_source ();
    }

    GLib.Uri User_status_selector_model.away_icon () {
        return Theme.instance ().status_away_image_source ();
    }
    GLib.Uri User_status_selector_model.dnd_icon () {
        return Theme.instance ().status_do_not_disturb_image_source ();
    }
    GLib.Uri User_status_selector_model.invisible_icon () {
        return Theme.instance ().status_invisible_image_source ();
    }

    UserStatus.OnlineStatus User_status_selector_model.online_status () {
        return _user_status.state ();
    }

    string User_status_selector_model.user_status_message () {
        return _user_status.message ();
    }

    void User_status_selector_model.set_user_status_message (string message) {
        _user_status.set_message (message);
        _user_status.set_message_predefined (false);
        emit user_status_changed ();
    }

    void User_status_selector_model.set_user_status_emoji (string emoji) {
        _user_status.set_icon (emoji);
        _user_status.set_message_predefined (false);
        emit user_status_changed ();
    }

    string User_status_selector_model.user_status_emoji () {
        return _user_status.icon ();
    }

    void User_status_selector_model.on_user_status_fetched (UserStatus &user_status) {
        if (user_status.state () != UserStatus.OnlineStatus.Offline) {
            _user_status.set_state (user_status.state ());
        }
        _user_status.set_message (user_status.message ());
        _user_status.set_message_predefined (user_status.message_predefined ());
        _user_status.set_id (user_status.id ());
        _user_status.set_clear_at (user_status.clear_at ());

        if (!user_status.icon ().is_empty ()) {
            _user_status.set_icon (user_status.icon ());
        }

        emit user_status_changed ();
        emit online_status_changed ();
        emit clear_at_changed ();
    }

    Optional<ClearAt> User_status_selector_model.clear_stage_type_to_date_time (Clear_stage_type type) {
        switch (type) {
        case Clear_stage_type.Dont_clear:
            return {};

        case Clear_stage_type.Half_hour: {
            ClearAt clear_at;
            clear_at._type = ClearAtType.Period;
            clear_at._period = 60 * 30;
            return clear_at;
        }

        case Clear_stage_type.One_hour: {
            ClearAt clear_at;
            clear_at._type = ClearAtType.Period;
            clear_at._period = 60 * 60;
            return clear_at;
        }

        case Clear_stage_type.Four_hour: {
            ClearAt clear_at;
            clear_at._type = ClearAtType.Period;
            clear_at._period = 60 * 60 * 4;
            return clear_at;
        }

        case Clear_stage_type.Today: {
            ClearAt clear_at;
            clear_at._type = ClearAtType.EndOf;
            clear_at._endof = "day";
            return clear_at;
        }

        case Clear_stage_type.Week: {
            ClearAt clear_at;
            clear_at._type = ClearAtType.EndOf;
            clear_at._endof = "week";
            return clear_at;
        }

        default:
            Q_UNREACHABLE ();
        }
    }

    void User_status_selector_model.set_user_status () {
        Q_ASSERT (_user_status_connector);
        if (!_user_status_connector) {
            return;
        }

        clear_error ();
        _user_status_connector.set_user_status (_user_status);
    }

    void User_status_selector_model.clear_user_status () {
        Q_ASSERT (_user_status_connector);
        if (!_user_status_connector) {
            return;
        }

        clear_error ();
        _user_status_connector.clear_message ();
    }

    void User_status_selector_model.on_predefined_statuses_fetched (std.vector<UserStatus> &statuses) {
        _predefined_statuses = statuses;
        emit predefined_statuses_changed ();
    }

    UserStatus User_status_selector_model.predefined_status (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefined_statuses.size ()));
        return _predefined_statuses[index];
    }

    int User_status_selector_model.predefined_statuses_count () {
        return static_cast<int> (_predefined_statuses.size ());
    }

    void User_status_selector_model.set_predefined_status (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefined_statuses.size ()));

        _user_status.set_message_predefined (true);
        const var predefined_status = _predefined_statuses[index];
        _user_status.set_id (predefined_status.id ());
        _user_status.set_message (predefined_status.message ());
        _user_status.set_icon (predefined_status.icon ());
        _user_status.set_clear_at (predefined_status.clear_at ());

        emit user_status_changed ();
        emit clear_at_changed ();
    }

    string User_status_selector_model.clear_at_stage_to_string (Clear_stage_type stage) {
        switch (stage) {
        case Clear_stage_type.Dont_clear:
            return _("Don't clear");

        case Clear_stage_type.Half_hour:
            return _("30 minutes");

        case Clear_stage_type.One_hour:
            return _("1 hour");

        case Clear_stage_type.Four_hour:
            return _("4 hours");

        case Clear_stage_type.Today:
            return _("Today");

        case Clear_stage_type.Week:
            return _("This week");

        default:
            Q_UNREACHABLE ();
        }
    }

    string[] User_status_selector_model.clear_at_values () {
        string[] clear_at_stages;
        std.transform (_clear_stages.begin (), _clear_stages.end (),
            std.back_inserter (clear_at_stages),
            [this] (Clear_stage_type &stage) {
                return clear_at_stage_to_string (stage);
            });

        return clear_at_stages;
    }

    void User_status_selector_model.set_clear_at (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_clear_stages.size ()));
        _user_status.set_clear_at (clear_stage_type_to_date_time (_clear_stages[index]));
        emit clear_at_changed ();
    }

    string User_status_selector_model.error_message () {
        return _error_message;
    }

    string User_status_selector_model.time_difference_to_string (int difference_secs) {
        if (difference_secs < 60) {
            return _("Less than a minute");
        } else if (difference_secs < 60 * 60) {
            const var minutes_left = std.ceil (difference_secs / 60.0);
            if (minutes_left == 1) {
                return _("1 minute");
            } else {
                return _("%1 minutes").arg (minutes_left);
            }
        } else if (difference_secs < 60 * 60 * 24) {
            const var hours_left = std.ceil (difference_secs / 60.0 / 60.0);
            if (hours_left == 1) {
                return _("1 hour");
            } else {
                return _("%1 hours").arg (hours_left);
            }
        } else {
            const var days_left = std.ceil (difference_secs / 60.0 / 60.0 / 24.0);
            if (days_left == 1) {
                return _("1 day");
            } else {
                return _("%1 days").arg (days_left);
            }
        }
    }

    string User_status_selector_model.clear_at_readable (Optional<ClearAt> &clear_at) {
        if (clear_at) {
            switch (clear_at._type) {
            case ClearAtType.Period: {
                return time_difference_to_string (clear_at._period);
            }

            case ClearAtType.Timestamp: {
                const int difference = static_cast<int> (clear_at._timestamp - _date_time_provider.current_date_time ().to_time_t ());
                return time_difference_to_string (difference);
            }

            case ClearAtType.EndOf: {
                if (clear_at._endof == "day") {
                    return _("Today");
                } else if (clear_at._endof == "week") {
                    return _("This week");
                }
                Q_UNREACHABLE ();
            }

            default:
                Q_UNREACHABLE ();
            }
        }
        return _("Don't clear");
    }

    string User_status_selector_model.predefined_status_clear_at (int index) {
        return clear_at_readable (predefined_status (index).clear_at ());
    }

    string User_status_selector_model.clear_at () {
        return clear_at_readable (_user_status.clear_at ());
    }
    }
    