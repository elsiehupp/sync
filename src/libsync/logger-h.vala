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

// #include <GLib.Object>
// #include <QList>
// #include <QDateTime>
// #include <QFile>
// #include <QTextStream>
// #include <qmutex.h>

namespace Occ {

/**
@brief The Logger class
@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT Logger : GLib.Object {
public:
    bool isLoggingToFile ();

    void doLog (QtMsgType type, QMessageLogContext &ctx, QString &message);

    static Logger *instance ();

    void postGuiLog (QString &title, QString &message);
    void postOptionalGuiLog (QString &title, QString &message);
    void postGuiMessage (QString &title, QString &message);

    QString logFile ();
    void setLogFile (QString &name);

    void setLogExpire (int expire);

    QString logDir ();
    void setLogDir (QString &dir);

    void setLogFlush (bool flush);

    bool logDebug () { return _logDebug; }
    void setLogDebug (bool debug);

    /** Returns where the automatic logdir would be */
    QString temporaryFolderLogDirPath ();

    /** Sets up default dir log setup.
     *
     * logdir : a temporary folder
     * logexpire : 4 hours
     * logdebug : true
     *
     * Used in conjunction with ConfigFile.automaticLogDir
     */
    void setupTemporaryFolderLogDir ();

    /** For switching off via logwindow */
    void disableTemporaryFolderLogDir ();

    void addLogRule (QSet<QString> &rules) {
        setLogRules (_logRules + rules);
    }
    void removeLogRule (QSet<QString> &rules) {
        setLogRules (_logRules - rules);
    }
    void setLogRules (QSet<QString> &rules);

signals:
    void logWindowLog (QString &);

    void guiLog (QString &, QString &);
    void guiMessage (QString &, QString &);
    void optionalGuiLog (QString &, QString &);

public slots:
    void enterNextLogFile ();

private:
    Logger (GLib.Object *parent = nullptr);
    ~Logger () override;

    void close ();
    void dumpCrashLog ();

    QFile _logFile;
    bool _doFileFlush = false;
    int _logExpire = 0;
    bool _logDebug = false;
    QScopedPointer<QTextStream> _logstream;
    mutable QMutex _mutex;
    QString _logDirectory;
    bool _temporaryFolderLogDir = false;
    QSet<QString> _logRules;
    QVector<QString> _crashLog;
    int _crashLogIndex = 0;
};

} // namespace Occ
