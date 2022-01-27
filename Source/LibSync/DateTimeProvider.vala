#pragma once

// #include <QDateTime>

namespace Occ {

class DateTimeProvider {

    virtual ~DateTimeProvider ();

    public virtual QDateTime current_date_time ();

    public virtual QDate current_date ();
};


    DateTimeProvider.~DateTimeProvider () = default;

    QDateTime DateTimeProvider.current_date_time () {
        return QDateTime.current_date_time ();
    }

    QDate DateTimeProvider.current_date () {
        return QDate.current_date ();
    }

}
