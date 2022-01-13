/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QTextStream>
// #include <QScopedPointer>
// #include <QElapsedTimer>
// #include <QStandardPaths>
// #include <QDir>

namespace Occ {

/***********************************************************
@brief The SyncRunFileLog class
@ingroup gui
***********************************************************/
class SyncRunFileLog {
public:
    SyncRunFileLog ();
    void start (string &folderPath);
    void logItem (SyncFileItem &item);
    void logLap (string &name);
    void finish ();

protected:
private:
    string dateTimeStr (QDateTime &dt);

    QScopedPointer<QFile> _file;
    QTextStream _out;
    QElapsedTimer _totalDuration;
    QElapsedTimer _lapDuration;
};
}








/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>

// #include <qfileinfo.h>

namespace Occ {

    SyncRunFileLog.SyncRunFileLog () = default;
    
    string SyncRunFileLog.dateTimeStr (QDateTime &dt) {
        return dt.toString (Qt.ISODate);
    }
    
    void SyncRunFileLog.start (string &folderPath) {
        const int64 logfileMaxSize = 10 * 1024 * 1024; // 10MiB
    
        const string logpath = QStandardPaths.writableLocation (QStandardPaths.AppDataLocation);
        if (!QDir (logpath).exists ()) {
            QDir ().mkdir (logpath);
        }
    
        int length = folderPath.split (QLatin1String ("/")).length ();
        string filenameSingle = folderPath.split (QLatin1String ("/")).at (length - 2);
        string filename = logpath + QLatin1String ("/") + filenameSingle + QLatin1String ("_sync.log");
    
        int depthIndex = 2;
        while (QFile.exists (filename)) {
    
            QFile file (filename);
            file.open (QIODevice.ReadOnly| QIODevice.Text);
            QTextStream in (&file);
            string line = in.readLine ();
    
            if (string.compare (folderPath,line,Qt.CaseSensitive)!=0) {
                depthIndex++;
                if (depthIndex <= length) {
                    filenameSingle = folderPath.split (QLatin1String ("/")).at (length - depthIndex) + string ("_") ///
                            + filenameSingle;
                    filename = logpath+ QLatin1String ("/") + filenameSingle + QLatin1String ("_sync.log");
                }
                else {
                    filenameSingle = filenameSingle + QLatin1String ("_1");
                    filename = logpath + QLatin1String ("/") + filenameSingle + QLatin1String ("_sync.log");
                }
            }
            else break;
        }
    
        // When the file is too big, just rename it to an old name.
        QFileInfo info (filename);
        bool exists = info.exists ();
        if (exists && info.size () > logfileMaxSize) {
            exists = false;
            string newFilename = filename + QLatin1String (".1");
            QFile.remove (newFilename);
            QFile.rename (filename, newFilename);
        }
        _file.reset (new QFile (filename));
    
        _file.open (QIODevice.WriteOnly | QIODevice.Append | QIODevice.Text);
        _out.setDevice (_file.data ());
    
        if (!exists) {
            _out << folderPath << endl;
            // We are creating a new file, add the note.
            _out << "# timestamp | duration | file | instruction | dir | modtime | etag | "
                    "size | fileId | status | errorString | http result code | "
                    "other size | other modtime | X-Request-ID"
                 << endl;
    
            FileSystem.setFileHidden (filename, true);
        }
    
        _totalDuration.start ();
        _lapDuration.start ();
        _out << "#=#=#=# Syncrun started " << dateTimeStr (QDateTime.currentDateTimeUtc ()) << endl;
    }
    void SyncRunFileLog.logItem (SyncFileItem &item) {
        // don't log the directory items that are in the list
        if (item._direction == SyncFileItem.None
            || item._instruction == CSYNC_INSTRUCTION_IGNORE) {
            return;
        }
        string ts = string.fromLatin1 (item._responseTimeStamp);
        if (ts.length () > 6) {
            const QRegularExpression rx (R" ( (\d\d:\d\d:\d\d))");
            const auto rxMatch = rx.match (ts);
            if (rxMatch.hasMatch ()) {
                ts = rxMatch.captured (0);
            }
        }
    
        const QChar L = QLatin1Char ('|');
        _out << ts << L;
        _out << L;
        if (item._instruction != CSYNC_INSTRUCTION_RENAME) {
            _out << item.destination () << L;
        } else {
            _out << item._file << QLatin1String (" . ") << item._renameTarget << L;
        }
        _out << item._instruction << L;
        _out << item._direction << L;
        _out << string.number (item._modtime) << L;
        _out << item._etag << L;
        _out << string.number (item._size) << L;
        _out << item._fileId << L;
        _out << item._status << L;
        _out << item._errorString << L;
        _out << string.number (item._httpErrorCode) << L;
        _out << string.number (item._previousSize) << L;
        _out << string.number (item._previousModtime) << L;
        _out << item._requestId << L;
    
        _out << endl;
    }
    
    void SyncRunFileLog.logLap (string &name) {
        _out << "#=#=#=#=# " << name << " " << dateTimeStr (QDateTime.currentDateTimeUtc ())
             << " (last step : " << _lapDuration.restart () << " msec"
             << ", total : " << _totalDuration.elapsed () << " msec)" << endl;
    }
    
    void SyncRunFileLog.finish () {
        _out << "#=#=#=# Syncrun finished " << dateTimeStr (QDateTime.currentDateTimeUtc ())
             << " (last step : " << _lapDuration.elapsed () << " msec"
             << ", total : " << _totalDuration.elapsed () << " msec)" << endl;
        _file.close ();
    }
    }
    