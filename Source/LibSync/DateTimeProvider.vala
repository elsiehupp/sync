#pragma once

// #include <QDateTime>

namespace Occ {

class DateTimeProvider {
public:
    virtual ~DateTimeProvider ();

    virtual QDateTime current_date_time ();

    virtual QDate current_date ();
};


    DateTimeProvider.~DateTimeProvider () = default;

    QDateTime DateTimeProvider.current_date_time () {
        return QDateTime.current_date_time ();
    }

    QDate DateTimeProvider.current_date () {
        return QDate.current_date ();
    }

}
