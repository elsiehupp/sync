#pragma once

// #include <QDateTime>

namespace Occ {

class Date_time_provider {
public:
    virtual ~Date_time_provider ();

    virtual QDateTime current_date_time ();

    virtual QDate current_date ();
};


    Date_time_provider.~Date_time_provider () = default;
    
    QDateTime Date_time_provider.current_date_time () {
        return QDateTime.current_date_time ();
    }
    
    QDate Date_time_provider.current_date () {
        return QDate.current_date ();
    }
    
}
