#pragma once

// #include <QDateTime>

namespace Occ {

class DateTimeProvider {
public:
    virtual ~DateTimeProvider ();

    virtual QDateTime currentDateTime ();

    virtual QDate currentDate ();
};
}







namespace Occ {

    DateTimeProvider.~DateTimeProvider () = default;
    
    QDateTime DateTimeProvider.currentDateTime () {
        return QDateTime.currentDateTime ();
    }
    
    QDate DateTimeProvider.currentDate () {
        return QDate.currentDate ();
    }
    
    }
    