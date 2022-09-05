/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {


namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractDateTimeProvider
***********************************************************/
public class AbstractDateTimeProvider { //: GLib.Object {

    //  /***********************************************************
    //  ***********************************************************/
    //  public virtual GLib.DateTime current_date_time () {
    //      return GLib.DateTime.current_date_time ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public virtual GLib.Date current_date () {
    //      return GLib.Date.current_date ();
    //  }

} // class GLib.DateTime

} // namespace LibSync
} // namespace Occ
    //      

public class FakeDateTimeProvider : AbstractDateTimeProvider {

    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.DateTime date_time;

    //  /***********************************************************
    //  ***********************************************************/
    //  public void set_current_date_time (GLib.DateTime date_time) {
    //      this.date_time = date_time;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public override GLib.Date current_date () {
    //      return this.date_time.date ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  static GLib.List<LibSync.UserStatus> create_fake_predefined_statuses (GLib.DateTime current_time) {
    //      GLib.List<LibSync.UserStatus> statuses;

    //      string user_status_id = "fake-identifier";
    //      string user_status_message = "Predefined status";
    //      string user_status_icon = "🏖";
    //      LibSync.UserStatus.OnlineStatus user_status_state = LibSync.UserStatus.OnlineStatus.ONLINE;
    //      bool user_status_message_predefined = true;
    //      Gpseq.Optional<ClearAt> user_status_clear_at;
    //      ClearAt clear_at;
    //      clear_at.type = ClearAtType.TIMESTAMP;
    //      clear_at.timestamp = current_time.add_secs (60 * 60).to_time_t ();
    //      user_status_clear_at = clear_at;

    //      statuses.emplace_back (user_status_id, user_status_message, user_status_icon,
    //          user_status_state, user_status_message_predefined, user_status_clear_at);

    //      return statuses;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  static GLib.DateTime create_date_time (
    //      int year = 2021, int month = 7, int day = 27,
    //      int hour = 12, int minute = 0, int second = 0) {
    //      GLib.Date fake_date = new GLib.Date (year, month, day);
    //      GLib.Time fake_time = new GLib.Time (hour, minute, second);
    //      GLib.DateTime fake_date_time;

    //      fake_date_time.set_date (fake_date);
    //      fake_date_time.set_time (fake_time);

    //      return fake_date_time;
    //  }

} // class FakeDateTimeProvider

} // namespace Testing
} // namespace Occ
