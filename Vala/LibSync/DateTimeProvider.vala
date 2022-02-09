//  #pragma once

namespace Occ {

class DateTimeProvider {

    ~DateTimeProvider () = default;

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

} // namespace Occ