/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QRegularExpression>
// #include <QStringList>
// #include <QtGlobal>
// #include <QTextCodec>
// #include <qmetaobject.h>

// #include <iostream>

#ifdef ZLIB_FOUND
// #include <zlib.h>
#endif

namespace {
constexpr int CrashLogSize = 20;
}

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

    /***********************************************************
    Returns where the automatic logdir would be */
    string temporaryFolderLogDirPath ();

    /***********************************************************
    Sets up default dir log setup.

    logdir : a temporary folder
    logexpire : 4 hours
    logdebug : true
    
    Used in conjunction with ConfigFile.automaticLogDir
    ***********************************************************/
    void setupTemporaryFolderLogDir ();

    /***********************************************************
    For switching off via logwindow */
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

Logger *Logger.instance () {
    static Logger log;
    return &log;
}

Logger.Logger (GLib.Object *parent)
    : GLib.Object (parent) {
    qSetMessagePattern (QStringLiteral ("%{time yyyy-MM-dd hh:mm:ss:zzz} [ %{type} %{category} %{file}:%{line} "
                                      "]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}"));
    _crashLog.resize (CrashLogSize);
#ifndef NO_MSG_HANDLER
    qInstallMessageHandler ([] (QtMsgType type, QMessageLogContext &ctx, string &message) {
            Logger.instance ().doLog (type, ctx, message);
        });
#endif
}

Logger.~Logger () {
#ifndef NO_MSG_HANDLER
    qInstallMessageHandler (nullptr);
#endif
}

void Logger.postGuiLog (string &title, string &message) {
    emit guiLog (title, message);
}

void Logger.postOptionalGuiLog (string &title, string &message) {
    emit optionalGuiLog (title, message);
}

void Logger.postGuiMessage (string &title, string &message) {
    emit guiMessage (title, message);
}

bool Logger.isLoggingToFile () {
    QMutexLocker lock (&_mutex);
    return _logstream;
}

void Logger.doLog (QtMsgType type, QMessageLogContext &ctx, string &message) { {onst string msg = qFormatLogMessage (type, ctx, message);
    {
        QMutexLocker lock (&_mutex);
        _crashLogIndex = (_crashLogIndex + 1) % CrashLogSize;
        _crashLog[_crashLogIndex] = msg;
        if (_logstream) {
            (*_logstream) << msg << Qt.endl;
            if (_doFileFlush)
                _logstream.flush ();
        }
        if (type == QtFatalMsg) {
            close ();
        }
    }
    emit logWindowLog (msg);
}

void Logger.close () {
    dumpCrashLog ();
    if (_logstream) {
        _logstream.flush ();
        _logFile.close ();
        _logstream.reset ();
    }
}

string Logger.logFile () {
    return _logFile.fileName ();
}

void Logger.setLogFile (string &name) {
    QMutexLocker locker (&_mutex);
    if (_logstream) {
        _logstream.reset (nullptr);
        _logFile.close ();
    }

    if (name.isEmpty ()) {
        return;
    }

    bool openSucceeded = false;
    if (name == QLatin1String ("-")) {
        openSucceeded = _logFile.open (stdout, QIODevice.WriteOnly);
    } else {
        _logFile.setFileName (name);
        openSucceeded = _logFile.open (QIODevice.WriteOnly);
    }

    if (!openSucceeded) {
        locker.unlock (); // Just in case postGuiMessage has a qDebug ()
        postGuiMessage (tr ("Error"),
            string (tr ("<nobr>File \"%1\"<br/>cannot be opened for writing.<br/><br/>"
                       "The log output <b>cannot</b> be saved!</nobr>"))
                .arg (name));
        return;
    }

    _logstream.reset (new QTextStream (&_logFile));
    _logstream.setCodec (QTextCodec.codecForName ("UTF-8"));
}

void Logger.setLogExpire (int expire) {
    _logExpire = expire;
}

string Logger.logDir () {
    return _logDirectory;
}

void Logger.setLogDir (string &dir) {
    _logDirectory = dir;
}

void Logger.setLogFlush (bool flush) {
    _doFileFlush = flush;
}

void Logger.setLogDebug (bool debug) {
    const QSet<string> rules = {debug ? QStringLiteral ("nextcloud.*.debug=true") : string ()};
    if (debug) {
        addLogRule (rules);
    } else {
        removeLogRule (rules);
    }
    _logDebug = debug;
}

string Logger.temporaryFolderLogDirPath () {
    return QDir.temp ().filePath (QStringLiteral (APPLICATION_SHORTNAME "-logdir"));
}

void Logger.setupTemporaryFolderLogDir () {
    auto dir = temporaryFolderLogDirPath ();
    if (!QDir ().mkpath (dir))
        return;
    setLogDebug (true);
    setLogExpire (4 /*hours*/);
    setLogDir (dir);
    _temporaryFolderLogDir = true;
}

void Logger.disableTemporaryFolderLogDir () {
    if (!_temporaryFolderLogDir)
        return;

    enterNextLogFile ();
    setLogDir (string ());
    setLogDebug (false);
    setLogFile (string ());
    _temporaryFolderLogDir = false;
}

void Logger.setLogRules (QSet<string> &rules) {
    _logRules = rules;
    string tmp;
    QTextStream out (&tmp);
    for (auto &p : rules) {
        out << p << QLatin1Char ('\n');
    }
    qDebug () << tmp;
    QLoggingCategory.setFilterRules (tmp);
}

void Logger.dumpCrashLog () {
    QFile logFile (QDir.tempPath () + QStringLiteral ("/" APPLICATION_NAME "-crash.log"));
    if (logFile.open (QFile.WriteOnly)) {
        QTextStream out (&logFile);
        for (int i = 1; i <= CrashLogSize; ++i) {
            out << _crashLog[ (_crashLogIndex + i) % CrashLogSize] << QLatin1Char ('\n');
        }
    }
}

static bool compressLog (string &originalName, string &targetName) {
#ifdef ZLIB_FOUND
    QFile original (originalName);
    if (!original.open (QIODevice.ReadOnly))
        return false;
    auto compressed = gzopen (targetName.toUtf8 (), "wb");
    if (!compressed) {
        return false;
    }

    while (!original.atEnd ()) {
        auto data = original.read (1024 * 1024);
        auto written = gzwrite (compressed, data.data (), data.size ());
        if (written != data.size ()) {
            gzclose (compressed);
            return false;
        }
    }
    gzclose (compressed);
    return true;
#else
    return false;
#endif
}

void Logger.enterNextLogFile () {
    if (!_logDirectory.isEmpty ()) {

        QDir dir (_logDirectory);
        if (!dir.exists ()) {
            dir.mkpath (".");
        }

        // Tentative new log name, will be adjusted if one like this already exists
        QDateTime now = QDateTime.currentDateTime ();
        string newLogName = now.toString ("yyyyMMdd_HHmm") + "_owncloud.log";

        // Expire old log files and deal with conflicts
        QStringList files = dir.entryList (QStringList ("*owncloud.log.*"),
            QDir.Files, QDir.Name);
        const QRegularExpression rx (QRegularExpression.anchoredPattern (R" (.*owncloud\.log\. (\d+).*)"));
        int maxNumber = -1;
        foreach (string &s, files) {
            if (_logExpire > 0) {
                QFileInfo fileInfo (dir.absoluteFilePath (s));
                if (fileInfo.lastModified ().addSecs (60 * 60 * _logExpire) < now) {
                    dir.remove (s);
                }
            }
            const auto rxMatch = rx.match (s);
            if (s.startsWith (newLogName) && rxMatch.hasMatch ()) {
                maxNumber = qMax (maxNumber, rxMatch.captured (1).toInt ());
            }
        }
        newLogName.append ("." + string.number (maxNumber + 1));

        auto previousLog = _logFile.fileName ();
        setLogFile (dir.filePath (newLogName));

        // Compress the previous log file. On a restart this can be the most recent
        // log file.
        auto logToCompress = previousLog;
        if (logToCompress.isEmpty () && files.size () > 0 && !files.last ().endsWith (".gz"))
            logToCompress = dir.absoluteFilePath (files.last ());
        if (!logToCompress.isEmpty ()) {
            string compressedName = logToCompress + ".gz";
            if (compressLog (logToCompress, compressedName)) {
                QFile.remove (logToCompress);
            } else {
                QFile.remove (compressedName);
            }
        }
    }
}

} // namespace Occ
