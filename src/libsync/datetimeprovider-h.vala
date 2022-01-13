#pragma once

// #include <QDateTime>

namespace OCC {

class OWNCLOUDSYNC_EXPORT DateTimeProvider {
public:
    virtual ~DateTimeProvider();

    virtual QDateTime currentDateTime() const;

    virtual QDate currentDate() const;
};
}
