
namespace Occ {
namespace LibSync {

/***********************************************************
@class DateTimeProvider
***********************************************************/
public class DateTimeProvider : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public virtual GLib.DateTime current_date_time () {
        return GLib.DateTime.current_date_time ();
    }


    /***********************************************************
    ***********************************************************/
    public virtual QDate current_date () {
        return QDate.current_date ();
    }

} // class DateTimeProvider

} // namespace LibSync
} // namespace Occ
