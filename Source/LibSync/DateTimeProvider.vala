#pragma once

// #include <GLib.DateTime>

namespace Occ {

class DateTimeProvider {

    virtual ~DateTimeProvider ();

    /***********************************************************
    ***********************************************************/
    public virtual GLib.DateTime current_date_time ();

    /***********************************************************
    ***********************************************************/
    public virtual QDate current_date ();
};


    DateTimeProvider.~DateTimeProvider () = default;

    GLib.DateTime DateTimeProvider.current_date_time () {
        return GLib.DateTime.current_date_time ();
    }

    QDate DateTimeProvider.current_date () {
        return QDate.current_date ();
    }

}
