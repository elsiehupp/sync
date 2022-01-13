/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QList>
// #include <QDateTime>
// #include <QFile>
// #include <QTextStream>
// #include <qmutex.h>

namespace Occ {

/***********************************************************
@brief The Logger class
@ingroup libsync
***********************************************************/
class Logger : GLib.Object {
public:
    bool isLoggingToFile ();

    void doLog (QtMsgType type, QMessageLogContext &ctx, string &message);

    static Logger *instance ();

    void postGuiLog (string &title, string &message);
    void postOptionalGuiLog (string &title, string &message);
    void postGuiMessage (string &title, string &message);

    string logFile ();
    void setLogFile (string &name);

    void setLogExpire (int expire);

    string logDir ();
    void setLogDir (string &dir);

    void setLogFlush (bool flush);

    bool logDebug () { return _logDebug; }
    void setLogDebug (bool debug);

    /** Returns where the automatic logdir would be */
    string temporaryFolderLogDirPath ();

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

    void addLogRule (QSet<string> &rules) {
        setLogRules (_logRules + rules);
    }
    void removeLogRule (QSet<string> &rules) {
        setLogRules (_logRules - rules);
    }
    void setLogRules (QSet<string> &rules);

signals:
    void logWindowLog (string &);

    void guiLog (string &, string &);
    void guiMessage (string &, string &);
    void optionalGuiLog (string &, string &);

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
    string _logDirectory;
    bool _temporaryFolderLogDir = false;
    QSet<string> _logRules;
    QVector<string> _crashLog;
    int _crashLogIndex = 0;
};

} // namespace Occ
