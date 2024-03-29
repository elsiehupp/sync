/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <ocsuserstatusconnector.h>
//  #include <access_managerespace.h>
//  #include <userstatusconnector.h>
//  #include <theme.h>
//  #include <GLib.LoggingCa
//  #include <algorithm>
//  #include <cmath>
//  #include <cstddef>
//  #include <userstatusconnector.h>
//  #include <datetimeprovider.h>
//  #include <GLib.MetaType>
//  #include <Qt_numer
//  #include <cstddef>
//  #include <memory>
//  #include <vector>

namespace Occ {
namespace Ui {

public class UserStatusSelectorModel { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private enum ClearStageType {
        DO_NOT_CLEAR,
        HALF_HOUR,
        ONE_HOUR,
        FOUR_HOUR,
        TODAY,
        WEEK;

        /***********************************************************
        Q_REQUIRED_RESULT
        ***********************************************************/
        public static string to_string (ClearStageType stage) {
            switch (stage) {
            case ClearStageType.DO_NOT_CLEAR:
                return _("Do not clear");

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
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.List<ClearStageType> clear_stages;
    public static GLib.List<string> clear_at_stages { public get; private set; }

    static construct {
        //  clear_stages = new GLib.List<ClearStageType> ();
        //  clear_stages.append (ClearStageType.DO_NOT_CLEAR);
        //  clear_stages.append (ClearStageType.HALF_HOUR);
        //  clear_stages.append (ClearStageType.ONE_HOUR);
        //  clear_stages.append (ClearStageType.FOUR_HOUR);
        //  clear_stages.append (ClearStageType.TODAY);
        //  clear_stages.append (ClearStageType.WEEK);

        //  clear_at_stages = new GLib.List<string> ();
        //  foreach (ClearStageType stage_type in clear_stages) {
        //      clear_at_stages.append (ClearStageType.to_string (stage_type));
        //  }
    }

    /***********************************************************
    ***********************************************************/
    private LibSync.AbstractUserStatusConnector user_status_connector = new LibSync.AbstractUserStatusConnector ();
    private GLib.List<LibSync.UserStatus> predefined_statuses;
    private LibSync.UserStatus user_status;
    private GLib.DateTime date_time_provider = new GLib.DateTime ();

    /***********************************************************
    ***********************************************************/
    string error_message { public get; private set; }


    internal signal void signal_error_message_changed ();
    internal signal void signal_user_status_changed ();
    internal signal void signal_online_status_changed ();
    internal signal void signal_clear_at_changed ();
    internal signal void predefined_statuses_changed ();
    internal signal void signal_finished ();


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel () {
        //  base ();
        //  this.date_time_provider = new GLib.DateTime ();
        //  this.user_status.icon ("😀");
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_connector (
        //  LibSync.AbstractUserStatusConnector user_status_connector
    ) {
        //  base ();
        //  this.user_status_connector = user_status_connector;
        //  this.user_status = new LibSync.UserStatus ("no-identifier", "", "😀", LibSync.UserStatus.OnlineStatus.ONLINE, false, {});
        //  this.date_time_provider = new GLib.DateTime ();
        //  this.user_status.icon ("😀");
        //  on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_connector_and_provider (
        //  LibSync.AbstractUserStatusConnector user_status_connector,
        //  GLib.DateTime date_time_provider = new GLib.DateTime ()
    ) {
        //  base ();
        //  this.user_status_connector = user_status_connector;
        //  this.date_time_provider = std.move (date_time_provider);
        //  this.user_status = new LibSync.UserStatus ();
        //  this.user_status.icon ("😀");
        //  on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_user_status_and_provider (
        //  LibSync.UserStatus user_status,
        //  GLib.DateTime date_time_provider
    ) {
        //  base ();
        //  this.user_status = user_status;
        //  this.date_time_provider = std.move (date_time_provider);
        //  this.user_status.icon ("😀");
    }


    /***********************************************************
    ***********************************************************/
    public UserStatusSelectorModel.with_user_status (
        //  LibSync.UserStatus user_status
    ) {
        //  base ();
        //  this.user_status = user_status;
        //  this.user_status.icon ("😀");
    }


    LibSync.UserStatus.OnlineStatus online_status {
        public get {
            return this.user_status.state;
        }
        public set {
            if (value == this.user_status.state) {
                return;
            }
            this.user_status.state (value);
            signal_online_status_changed ();
        }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri online_icon {
        public get {
            return LibSync.Theme.status_online_image_source;
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri away_icon {
        public get {
            return LibSync.Theme.status_away_image_source;
        }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Uri dnd_icon {
        public get {
            return LibSync.Theme.status_do_not_disturb_image_source;
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri invisible_icon {
        public get {
            return LibSync.Theme.status_invisible_image_source;
        }
    }


    public string user_status_message {
        public get {
            return this.user_status.message ();
        }
        public set {
            this.user_status.message (value);
            this.user_status.message_predefined (false);
            signal_user_status_changed ();
        }
    }


    public string user_status_emoji {
        public get {
            return this.user_status.icon ();
        }
        public set {
            this.user_status.icon (value);
            this.user_status.message_predefined (false);
            signal_user_status_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void update_user_status () {
        //  //  GLib.assert_true (this.user_status_connector);
        //  if (!this.user_status_connector) {
        //      return;
        //  }

        //  clear_error ();
        //  this.user_status_connector.user_status (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    public void clear_user_status () {
        //  //  GLib.assert_true (this.user_status_connector);
        //  if (!this.user_status_connector) {
        //      return;
        //  }

        //  clear_error ();
        //  this.user_status_connector.clear_message ();
    }


    /***********************************************************
    ***********************************************************/
    public int predefined_statuses_count () {
        //  return (int)this.predefined_statuses.length ();
    }


    /***********************************************************
    ***********************************************************/
    public LibSync.UserStatus predefined_status_for_index (int index) {
        //  //  GLib.assert_true (0 <= index && index < (int)this.predefined_statuses.size ());
        //  return this.predefined_statuses.nth_data (index);
    }


    /***********************************************************
    ***********************************************************/
    public string predefined_status_clear_at (int index) {
        //  return clear_at_readable (this.predefined_statuses.nth_data (index).clear_at ());
    }


    /***********************************************************
    ***********************************************************/
    public void predefined_status (int index) {
        //  //  GLib.assert_true (0 <= index && index < (int)this.predefined_statuses.size ());

        //  this.user_status.message_predefined (true);
        //  var predefined_status = this.predefined_statuses[index];
        //  this.user_status.id (predefined_status.identifier);
        //  this.user_status.message (predefined_status.message ());
        //  this.user_status.icon (predefined_status.icon ());
        //  this.user_status.clear_at (predefined_status.clear_at ());

        //  signal_user_status_changed ();
        //  signal_clear_at_changed ();
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string clear_at () {
        //  return clear_at_readable (this.user_status.clear_at ());
    }


    /***********************************************************
    ***********************************************************/
    public void clear_at_for_index (int index) {
        //  //  GLib.assert_true (0 <= index && index < (int)clear_stages.size ());
        //  this.user_status.clear_at (clear_stage_type_to_date_time (clear_stages.get (index)));
        //  signal_clear_at_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init () {
        //  if (!this.user_status_connector) {
        //      return;
        //  }

        //  this.user_status_connector.signal_user_status_fetched.connect (
        //      this.on_signal_user_status_fetched
        //  );
        //  this.user_status_connector.signal_predefined_statuses_fetched.connect (
        //      this.on_signal_predefined_statuses_fetched
        //  );
        //  this.user_status_connector.signal_error.connect (
        //      this.on_signal_error
        //  );
        //  this.user_status_connector.signal_user_status_set.connect (
        //      this.on_signal_user_status_set
        //  );
        //  this.user_status_connector.signal_message_cleared.connect (
        //      this.on_signal_message_cleared
        //  );

        //  this.user_status_connector.fetch_user_status ();
        //  this.user_status_connector.fetch_predefined_statuses ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_load (int identifier) {
        //  reset ();
        //  this.user_status_connector = UserModel.instance.user_status_connector (identifier);
        //  on_signal_init ();
    }


    /***********************************************************
    ***********************************************************/
    private void reset () {
        //  if (this.user_status_connector) {
        //      this.user_status_connector.signal_user_status_fetched.disconnect (
        //          this.on_signal_user_status_fetched
        //      );
        //      this.user_status_connector.signal_predefined_statuses_fetched.disconnect (
        //          this.on_signal_predefined_statuses_fetched
        //      );
        //      this.user_status_connector.signal_error.disconnect (
        //          this.on_signal_error
        //      );
        //      this.user_status_connector.signal_user_status_set.disconnect (
        //          this.on_signal_user_status_set
        //      );
        //      this.user_status_connector.signal_message_cleared.disconnect (
        //          this.on_signal_message_cleared
        //      );
        //  }
        //  this.user_status_connector = null;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_fetched (LibSync.UserStatus user_status) {
        //  if (user_status.state != LibSync.UserStatus.OnlineStatus.OFFLINE) {
        //      this.user_status.state (user_status.state);
        //  }
        //  this.user_status.message (user_status.message ());
        //  this.user_status.message_predefined (user_status.message_predefined ());
        //  this.user_status.id (user_status.identifier);
        //  this.user_status.clear_at (user_status.clear_at ());

        //  if (!user_status.icon () == "") {
        //      this.user_status.icon (user_status.icon ());
        //  }

        //  signal_user_status_changed ();
        //  signal_online_status_changed ();
        //  signal_clear_at_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_predefined_statuses_fetched (GLib.List<LibSync.UserStatus> statuses) {
        //  this.predefined_statuses = statuses;
        //  predefined_statuses_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_set () {
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_message_cleared () {
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_error (LibSync.AbstractUserStatusConnector.Error error) {
        //  GLib.warning ("Error: " + LibSync.AbstractUserStatusConnector.Error.to_string (error));

        //  switch (error) {
        //  case LibSync.AbstractUserStatusConnector.Error.COULD_NOT_FETCH_PREDEFINED_USER_STATUSES:
        //      error (_("Could not fetch predefined statuses. Make sure you are connected to the server."));
        //      return;

        //  case LibSync.AbstractUserStatusConnector.Error.COULD_NOT_FETCH_USER_STATUS:
        //      error (_("Could not fetch user status. Make sure you are connected to the server."));
        //      return;

        //  case LibSync.AbstractUserStatusConnector.Error.UserStatusResult.NOT_SUPPORTED:
        //      error (_("User status feature is not supported. You will not be able to set your user status."));
        //      return;

        //  case LibSync.AbstractUserStatusConnector.Error.EmojisResult.NOT_SUPPORTED:
        //      error (_("Emojis feature is not supported. Some user status functionality may not work."));
        //      return;

        //  case LibSync.AbstractUserStatusConnector.Error.COULD_NOT_SET_USER_STATUS:
        //      error (_("Could not set user status. Make sure you are connected to the server."));
        //      return;

        //  case LibSync.AbstractUserStatusConnector.Error.COULD_NOT_CLEAR_MESSAGE:
        //      error (_("Could not clear user status message. Make sure you are connected to the server."));
        //      return;
        //  }

        //  GLib.assert_not_reached ();
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private string clear_at_readable (Gpseq.Optional<ClearAt> clear_at) {
        //  if (clear_at != null) {
        //      switch (clear_at.type) {
        //      case ClearAtType.PERIOD: {
        //          return time_difference_to_string (clear_at.period);
        //      }

        //      case ClearAtType.TIMESTAMP: {
        //          int difference = (int)(clear_at.timestamp - this.date_time_provider.current_date_time ().to_time_t ());
        //          return time_difference_to_string (difference);
        //      }

        //      case ClearAtType.END_OF: {
        //          if (clear_at.endof == "day") {
        //              return _("Today");
        //          } else if (clear_at.endof == "week") {
        //              return _("This week");
        //          }
        //          GLib.assert_not_reached ();
        //      }

        //      default:
        //          GLib.assert_not_reached ();
        //      }
        //  }
        //  return _("Don't clear");
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private static string time_difference_to_string (int difference_secs) {
        //  if (difference_secs < 60) {
        //      return _("Less than a minute");
        //  } else if (difference_secs < 60 * 60) {
        //      var minutes_left = std.ceil (difference_secs / 60.0);
        //      if (minutes_left == 1) {
        //          return _("1 minute");
        //      } else {
        //          return _("%1 minutes").printf (minutes_left);
        //      }
        //  } else if (difference_secs < 60 * 60 * 24) {
        //      var hours_left = std.ceil (difference_secs / 60.0 / 60.0);
        //      if (hours_left == 1) {
        //          return _("1 hour");
        //      } else {
        //          return _("%1 hours").printf (hours_left);
        //      }
        //  } else {
        //      var days_left = std.ceil (difference_secs / 60.0 / 60.0 / 24.0);
        //      if (days_left == 1) {
        //          return _("1 day");
        //      } else {
        //          return _("%1 days").printf (days_left);
        //      }
        //  }
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    private static Gpseq.Optional<ClearAt> clear_stage_type_to_date_time (ClearStageType type) {
        //  switch (type) {
        //  case ClearStageType.DO_NOT_CLEAR:
        //      return {};

        //  case ClearStageType.HALF_HOUR: {
        //      ClearAt clear_at;
        //      clear_at.type = ClearAtType.PERIOD;
        //      clear_at.period = 60 * 30;
        //      return clear_at;
        //  }

        //  case ClearStageType.ONE_HOUR: {
        //      ClearAt clear_at;
        //      clear_at.type = ClearAtType.PERIOD;
        //      clear_at.period = 60 * 60;
        //      return clear_at;
        //  }

        //  case ClearStageType.FOUR_HOUR: {
        //      ClearAt clear_at;
        //      clear_at.type = ClearAtType.PERIOD;
        //      clear_at.period = 60 * 60 * 4;
        //      return clear_at;
        //  }

        //  case ClearStageType.TODAY: {
        //      ClearAt clear_at;
        //      clear_at.type = ClearAtType.END_OF;
        //      clear_at.endof = "day";
        //      return clear_at;
        //  }

        //  case ClearStageType.WEEK: {
        //      ClearAt clear_at;
        //      clear_at.type = ClearAtType.END_OF;
        //      clear_at.endof = "week";
        //      return clear_at;
        //  }

        //  default:
        //      GLib.assert_not_reached ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void error (string reason) {
        //  this.error_message = reason;
        //  signal_error_message_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void clear_error () {
        //  error ("");
    }

} // class UserStatusSelectorModel

} // namespace Ui
} // namespace Occ
