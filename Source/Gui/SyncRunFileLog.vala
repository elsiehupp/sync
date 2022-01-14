/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>

// #include <qfileinfo.h>

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

    public SyncRunFileLog ();
    public void start (string &folder_path);
    public void log_item (SyncFileItem &item);
    public void log_lap (string &name);
    public void finish ();

protected:
private:
    string date_time_str (QDateTime &dt);

    QScopedPointer<QFile> _file;
    QTextStream _out;
    QElapsedTimer _total_duration;
    QElapsedTimer _lap_duration;
};


    SyncRunFileLog.SyncRunFileLog () = default;

    string SyncRunFileLog.date_time_str (QDateTime &dt) {
        return dt.to_string (Qt.ISODate);
    }

    void SyncRunFileLog.start (string &folder_path) {
        const int64 logfile_max_size = 10 * 1024 * 1024; // 10Mi_b

        const string logpath = QStandardPaths.writable_location (QStandardPaths.App_data_location);
        if (!QDir (logpath).exists ()) {
            QDir ().mkdir (logpath);
        }

        int length = folder_path.split (QLatin1String ("/")).length ();
        string filename_single = folder_path.split (QLatin1String ("/")).at (length - 2);
        string filename = logpath + QLatin1String ("/") + filename_single + QLatin1String ("_sync.log");

        int depth_index = 2;
        while (QFile.exists (filename)) {

            QFile file (filename);
            file.open (QIODevice.Read_only| QIODevice.Text);
            QTextStream in (&file);
            string line = in.read_line ();

            if (string.compare (folder_path,line,Qt.CaseSensitive)!=0) {
                depth_index++;
                if (depth_index <= length) {
                    filename_single = folder_path.split (QLatin1String ("/")).at (length - depth_index) + string ("_") ///
                            + filename_single;
                    filename = logpath+ QLatin1String ("/") + filename_single + QLatin1String ("_sync.log");
                }
                else {
                    filename_single = filename_single + QLatin1String ("_1");
                    filename = logpath + QLatin1String ("/") + filename_single + QLatin1String ("_sync.log");
                }
            }
            else break;
        }

        // When the file is too big, just rename it to an old name.
        QFileInfo info (filename);
        bool exists = info.exists ();
        if (exists && info.size () > logfile_max_size) {
            exists = false;
            string new_filename = filename + QLatin1String (".1");
            QFile.remove (new_filename);
            QFile.rename (filename, new_filename);
        }
        _file.reset (new QFile (filename));

        _file.open (QIODevice.WriteOnly | QIODevice.Append | QIODevice.Text);
        _out.set_device (_file.data ());

        if (!exists) {
            _out << folder_path << endl;
            // We are creating a new file, add the note.
            _out << "# timestamp | duration | file | instruction | dir | modtime | etag | "
                    "size | file_id | status | error_string | http result code | "
                    "other size | other modtime | X-Request-ID"
                 << endl;

            FileSystem.set_file_hidden (filename, true);
        }

        _total_duration.start ();
        _lap_duration.start ();
        _out << "#=#=#=# Syncrun started " << date_time_str (QDateTime.current_date_time_utc ()) << endl;
    }
    void SyncRunFileLog.log_item (SyncFileItem &item) {
        // don't log the directory items that are in the list
        if (item._direction == SyncFileItem.None
            || item._instruction == CSYNC_INSTRUCTION_IGNORE) {
            return;
        }
        string ts = string.from_latin1 (item._response_time_stamp);
        if (ts.length () > 6) {
            const QRegularExpression rx (R" ( (\d\d:\d\d:\d\d))");
            const auto rx_match = rx.match (ts);
            if (rx_match.has_match ()) {
                ts = rx_match.captured (0);
            }
        }

        const QChar L = QLatin1Char ('|');
        _out << ts << L;
        _out << L;
        if (item._instruction != CSYNC_INSTRUCTION_RENAME) {
            _out << item.destination () << L;
        } else {
            _out << item._file << QLatin1String (" . ") << item._rename_target << L;
        }
        _out << item._instruction << L;
        _out << item._direction << L;
        _out << string.number (item._modtime) << L;
        _out << item._etag << L;
        _out << string.number (item._size) << L;
        _out << item._file_id << L;
        _out << item._status << L;
        _out << item._error_string << L;
        _out << string.number (item._http_error_code) << L;
        _out << string.number (item._previous_size) << L;
        _out << string.number (item._previous_modtime) << L;
        _out << item._request_id << L;

        _out << endl;
    }

    void SyncRunFileLog.log_lap (string &name) {
        _out << "#=#=#=#=# " << name << " " << date_time_str (QDateTime.current_date_time_utc ())
             << " (last step : " << _lap_duration.restart () << " msec"
             << ", total : " << _total_duration.elapsed () << " msec)" << endl;
    }

    void SyncRunFileLog.finish () {
        _out << "#=#=#=# Syncrun finished " << date_time_str (QDateTime.current_date_time_utc ())
             << " (last step : " << _lap_duration.elapsed () << " msec"
             << ", total : " << _total_duration.elapsed () << " msec)" << endl;
        _file.close ();
    }
    }
    