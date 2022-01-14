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

// #include <GLib.Object>
// #include <QMetaType>
// #include <Qt_numeric>

// #include <cstddef>
// #include <memory>
// #include <vector>

namespace Occ {

class User_status_selector_model : GLib.Object {

    Q_PROPERTY (string user_status_message READ user_status_message NOTIFY user_status_changed)
    Q_PROPERTY (string user_status_emoji READ user_status_emoji WRITE set_user_status_emoji NOTIFY user_status_changed)
    Q_PROPERTY (Occ.User_status.Online_status online_status READ online_status WRITE set_online_status NOTIFY online_status_changed)
    Q_PROPERTY (int predefined_statuses_count READ predefined_statuses_count NOTIFY predefined_statuses_changed)
    Q_PROPERTY (QStringList clear_at_values READ clear_at_values CONSTANT)
    Q_PROPERTY (string clear_at READ clear_at NOTIFY clear_at_changed)
    Q_PROPERTY (string error_message READ error_message NOTIFY error_message_changed)
    Q_PROPERTY (QUrl online_icon READ online_icon CONSTANT)
    Q_PROPERTY (QUrl away_icon READ away_icon CONSTANT)
    Q_PROPERTY (QUrl dnd_icon READ dnd_icon CONSTANT)
    Q_PROPERTY (QUrl invisible_icon READ invisible_icon CONSTANT)

    public User_status_selector_model (GLib.Object *parent = nullptr);

    public User_status_selector_model (std.shared_ptr<User_status_connector> user_status_connector,
        GLib.Object *parent = nullptr);

    public User_status_selector_model (std.shared_ptr<User_status_connector> user_status_connector,
        std.unique_ptr<Date_time_provider> date_time_provider,
        GLib.Object *parent = nullptr);

    public User_status_selector_model (User_status &user_status,
        std.unique_ptr<Date_time_provider> date_time_provider,
        GLib.Object *parent = nullptr);

    public User_status_selector_model (User_status &user_status,
        GLib.Object *parent = nullptr);

    public Q_INVOKABLE void load (int id);

    public Q_REQUIRED_RESULT User_status.Online_status online_status ();
    public Q_INVOKABLE void set_online_status (Occ.User_status.Online_status status);

    public Q_REQUIRED_RESULT QUrl online_icon ();
    public Q_REQUIRED_RESULT QUrl away_icon ();
    public Q_REQUIRED_RESULT QUrl dnd_icon ();
    public Q_REQUIRED_RESULT QUrl invisible_icon ();

    public Q_REQUIRED_RESULT string user_status_message ();
    public Q_INVOKABLE void set_user_status_message (string &message);
    public void set_user_status_emoji (string &emoji);
    public Q_REQUIRED_RESULT string user_status_emoji ();

    public Q_INVOKABLE void set_user_status ();
    public Q_INVOKABLE void clear_user_status ();

    public Q_REQUIRED_RESULT int predefined_statuses_count ();
    public Q_INVOKABLE User_status predefined_status (int index) const;
    public Q_INVOKABLE string predefined_status_clear_at (int index) const;
    public Q_INVOKABLE void set_predefined_status (int index);

    public Q_REQUIRED_RESULT QStringList clear_at_values ();
    public Q_REQUIRED_RESULT string clear_at ();
    public Q_INVOKABLE void set_clear_at (int index);

    public Q_REQUIRED_RESULT string error_message ();

signals:
    void error_message_changed ();
    void user_status_changed ();
    void online_status_changed ();
    void clear_at_changed ();
    void predefined_statuses_changed ();
    void finished ();

private:
    enum class Clear_stage_type {
        Dont_clear,
        Half_hour,
        One_hour,
        Four_hour,
        Today,
        Week
    };

    void init ();
    void reset ();
    void on_user_status_fetched (User_status &user_status);
    void on_predefined_statuses_fetched (std.vector<User_status> &statuses);
    void on_user_status_set ();
    void on_message_cleared ();
    void on_error (User_status_connector.Error error);

    Q_REQUIRED_RESULT string clear_at_stage_to_string (Clear_stage_type stage) const;
    Q_REQUIRED_RESULT string clear_at_readable (Optional<Clear_at> &clear_at) const;
    Q_REQUIRED_RESULT string time_difference_to_string (int difference_secs) const;
    Q_REQUIRED_RESULT Optional<Clear_at> clear_stage_type_to_date_time (Clear_stage_type type) const;
    void set_error (string &reason);
    void clear_error ();

    std.shared_ptr<User_status_connector> _user_status_connector {};
    std.vector<User_status> _predefined_statuses;
    User_status _user_status;
    std.unique_ptr<Date_time_provider> _date_time_provider;

    string _error_message;

    std.vector<Clear_stage_type> _clear_stages = {
        Clear_stage_type.Dont_clear,
        Clear_stage_type.Half_hour,
        Clear_stage_type.One_hour,
        Clear_stage_type.Four_hour,
        Clear_stage_type.Today,
        Clear_stage_type.Week
    };
};

    User_status_selector_model.User_status_selector_model (GLib.Object *parent)
        : GLib.Object (parent)
        , _date_time_provider (new Date_time_provider) {
        _user_status.set_icon ("😀");
    }

    User_status_selector_model.User_status_selector_model (std.shared_ptr<User_status_connector> user_status_connector, GLib.Object *parent)
        : GLib.Object (parent)
        , _user_status_connector (user_status_connector)
        , _user_status ("no-id", "", "😀", User_status.Online_status.Online, false, {})
        , _date_time_provider (new Date_time_provider) {
        _user_status.set_icon ("😀");
        init ();
    }

    User_status_selector_model.User_status_selector_model (std.shared_ptr<User_status_connector> user_status_connector,
        std.unique_ptr<Date_time_provider> date_time_provider,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _user_status_connector (user_status_connector)
        , _date_time_provider (std.move (date_time_provider)) {
        _user_status.set_icon ("😀");
        init ();
    }

    User_status_selector_model.User_status_selector_model (User_status &user_status,
        std.unique_ptr<Date_time_provider> date_time_provider, GLib.Object *parent)
        : GLib.Object (parent)
        , _user_status (user_status)
        , _date_time_provider (std.move (date_time_provider)) {
        _user_status.set_icon ("😀");
    }

    User_status_selector_model.User_status_selector_model (User_status &user_status,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _user_status (user_status) {
        _user_status.set_icon ("😀");
    }

    void User_status_selector_model.load (int id) {
        reset ();
        _user_status_connector = User_model.instance ().user_status_connector (id);
        init ();
    }

    void User_status_selector_model.reset () {
        if (_user_status_connector) {
            disconnect (_user_status_connector.get (), &User_status_connector.user_status_fetched, this,
                &User_status_selector_model.on_user_status_fetched);
            disconnect (_user_status_connector.get (), &User_status_connector.predefined_statuses_fetched, this,
                &User_status_selector_model.on_predefined_statuses_fetched);
            disconnect (_user_status_connector.get (), &User_status_connector.error, this,
                &User_status_selector_model.on_error);
            disconnect (_user_status_connector.get (), &User_status_connector.user_status_set, this,
                &User_status_selector_model.on_user_status_set);
            disconnect (_user_status_connector.get (), &User_status_connector.message_cleared, this,
                &User_status_selector_model.on_message_cleared);
        }
        _user_status_connector = nullptr;
    }

    void User_status_selector_model.init () {
        if (!_user_status_connector) {
            return;
        }

        connect (_user_status_connector.get (), &User_status_connector.user_status_fetched, this,
            &User_status_selector_model.on_user_status_fetched);
        connect (_user_status_connector.get (), &User_status_connector.predefined_statuses_fetched, this,
            &User_status_selector_model.on_predefined_statuses_fetched);
        connect (_user_status_connector.get (), &User_status_connector.error, this,
            &User_status_selector_model.on_error);
        connect (_user_status_connector.get (), &User_status_connector.user_status_set, this,
            &User_status_selector_model.on_user_status_set);
        connect (_user_status_connector.get (), &User_status_connector.message_cleared, this,
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

    void User_status_selector_model.on_error (User_status_connector.Error error) {
        q_c_warning (lc_user_status_dialog_model) << "Error:" << error;

        switch (error) {
        case User_status_connector.Error.Could_not_fetch_predefined_user_statuses:
            set_error (tr ("Could not fetch predefined statuses. Make sure you are connected to the server."));
            return;

        case User_status_connector.Error.Could_not_fetch_user_status:
            set_error (tr ("Could not fetch user status. Make sure you are connected to the server."));
            return;

        case User_status_connector.Error.User_status_not_supported:
            set_error (tr ("User status feature is not supported. You will not be able to set your user status."));
            return;

        case User_status_connector.Error.Emojis_not_supported:
            set_error (tr ("Emojis feature is not supported. Some user status functionality may not work."));
            return;

        case User_status_connector.Error.Could_not_set_user_status:
            set_error (tr ("Could not set user status. Make sure you are connected to the server."));
            return;

        case User_status_connector.Error.Could_not_clear_message:
            set_error (tr ("Could not clear user status message. Make sure you are connected to the server."));
            return;
        }

        Q_UNREACHABLE ();
    }

    void User_status_selector_model.set_error (string &reason) {
        _error_message = reason;
        emit error_message_changed ();
    }

    void User_status_selector_model.clear_error () {
        set_error ("");
    }

    void User_status_selector_model.set_online_status (User_status.Online_status status) {
        if (status == _user_status.state ()) {
            return;
        }

        _user_status.set_state (status);
        emit online_status_changed ();
    }

    QUrl User_status_selector_model.online_icon () {
        return Theme.instance ().status_online_image_source ();
    }

    QUrl User_status_selector_model.away_icon () {
        return Theme.instance ().status_away_image_source ();
    }
    QUrl User_status_selector_model.dnd_icon () {
        return Theme.instance ().status_do_not_disturb_image_source ();
    }
    QUrl User_status_selector_model.invisible_icon () {
        return Theme.instance ().status_invisible_image_source ();
    }

    User_status.Online_status User_status_selector_model.online_status () {
        return _user_status.state ();
    }

    string User_status_selector_model.user_status_message () {
        return _user_status.message ();
    }

    void User_status_selector_model.set_user_status_message (string &message) {
        _user_status.set_message (message);
        _user_status.set_message_predefined (false);
        emit user_status_changed ();
    }

    void User_status_selector_model.set_user_status_emoji (string &emoji) {
        _user_status.set_icon (emoji);
        _user_status.set_message_predefined (false);
        emit user_status_changed ();
    }

    string User_status_selector_model.user_status_emoji () {
        return _user_status.icon ();
    }

    void User_status_selector_model.on_user_status_fetched (User_status &user_status) {
        if (user_status.state () != User_status.Online_status.Offline) {
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

    Optional<Clear_at> User_status_selector_model.clear_stage_type_to_date_time (Clear_stage_type type) {
        switch (type) {
        case Clear_stage_type.Dont_clear:
            return {};

        case Clear_stage_type.Half_hour : {
            Clear_at clear_at;
            clear_at._type = Clear_at_type.Period;
            clear_at._period = 60 * 30;
            return clear_at;
        }

        case Clear_stage_type.One_hour : {
            Clear_at clear_at;
            clear_at._type = Clear_at_type.Period;
            clear_at._period = 60 * 60;
            return clear_at;
        }

        case Clear_stage_type.Four_hour : {
            Clear_at clear_at;
            clear_at._type = Clear_at_type.Period;
            clear_at._period = 60 * 60 * 4;
            return clear_at;
        }

        case Clear_stage_type.Today : {
            Clear_at clear_at;
            clear_at._type = Clear_at_type.End_of;
            clear_at._endof = "day";
            return clear_at;
        }

        case Clear_stage_type.Week : {
            Clear_at clear_at;
            clear_at._type = Clear_at_type.End_of;
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

    void User_status_selector_model.on_predefined_statuses_fetched (std.vector<User_status> &statuses) {
        _predefined_statuses = statuses;
        emit predefined_statuses_changed ();
    }

    User_status User_status_selector_model.predefined_status (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefined_statuses.size ()));
        return _predefined_statuses[index];
    }

    int User_status_selector_model.predefined_statuses_count () {
        return static_cast<int> (_predefined_statuses.size ());
    }

    void User_status_selector_model.set_predefined_status (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefined_statuses.size ()));

        _user_status.set_message_predefined (true);
        const auto predefined_status = _predefined_statuses[index];
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
            return tr ("Don't clear");

        case Clear_stage_type.Half_hour:
            return tr ("30 minutes");

        case Clear_stage_type.One_hour:
            return tr ("1 hour");

        case Clear_stage_type.Four_hour:
            return tr ("4 hours");

        case Clear_stage_type.Today:
            return tr ("Today");

        case Clear_stage_type.Week:
            return tr ("This week");

        default:
            Q_UNREACHABLE ();
        }
    }

    QStringList User_status_selector_model.clear_at_values () {
        QStringList clear_at_stages;
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
            return tr ("Less than a minute");
        } else if (difference_secs < 60 * 60) {
            const auto minutes_left = std.ceil (difference_secs / 60.0);
            if (minutes_left == 1) {
                return tr ("1 minute");
            } else {
                return tr ("%1 minutes").arg (minutes_left);
            }
        } else if (difference_secs < 60 * 60 * 24) {
            const auto hours_left = std.ceil (difference_secs / 60.0 / 60.0);
            if (hours_left == 1) {
                return tr ("1 hour");
            } else {
                return tr ("%1 hours").arg (hours_left);
            }
        } else {
            const auto days_left = std.ceil (difference_secs / 60.0 / 60.0 / 24.0);
            if (days_left == 1) {
                return tr ("1 day");
            } else {
                return tr ("%1 days").arg (days_left);
            }
        }
    }

    string User_status_selector_model.clear_at_readable (Optional<Clear_at> &clear_at) {
        if (clear_at) {
            switch (clear_at._type) {
            case Clear_at_type.Period : {
                return time_difference_to_string (clear_at._period);
            }

            case Clear_at_type.Timestamp : {
                const int difference = static_cast<int> (clear_at._timestamp - _date_time_provider.current_date_time ().to_time_t ());
                return time_difference_to_string (difference);
            }

            case Clear_at_type.End_of : {
                if (clear_at._endof == "day") {
                    return tr ("Today");
                } else if (clear_at._endof == "week") {
                    return tr ("This week");
                }
                Q_UNREACHABLE ();
            }

            default:
                Q_UNREACHABLE ();
            }
        }
        return tr ("Don't clear");
    }

    string User_status_selector_model.predefined_status_clear_at (int index) {
        return clear_at_readable (predefined_status (index).clear_at ());
    }

    string User_status_selector_model.clear_at () {
        return clear_at_readable (_user_status.clear_at ());
    }
    }
    