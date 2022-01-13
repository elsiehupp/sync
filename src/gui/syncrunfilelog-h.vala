/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QFile>
// #include <QTextStream>
// #include <QScopedPointer>
// #include <QElapsedTimer>
// #include <QStandardPaths>
// #include <QDir>

namespace Occ {

/**
@brief The SyncRunFileLog class
@ingroup gui
*/
class SyncRunFileLog {
public:
    SyncRunFileLog ();
    void start (QString &folderPath);
    void logItem (SyncFileItem &item);
    void logLap (QString &name);
    void finish ();

protected:
private:
    QString dateTimeStr (QDateTime &dt);

    QScopedPointer<QFile> _file;
    QTextStream _out;
    QElapsedTimer _totalDuration;
    QElapsedTimer _lapDuration;
};
}
