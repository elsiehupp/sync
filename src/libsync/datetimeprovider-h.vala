#pragma once

// #include <QDateTime>

namespace Occ {

class OWNCLOUDSYNC_EXPORT DateTimeProvider {
public:
    virtual ~DateTimeProvider ();

    virtual QDateTime currentDateTime ();

    virtual QDate currentDate ();
};
}
