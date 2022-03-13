/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QRegularExpression>
//  #include <qfileinfo.h>
//  #include <QTextStream>
//  #include <QScopedPointer>
//  #include <QElapsedTimer>
//  #include <QStandardPaths>
//  #include <QDir>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SyncRunFileLog class
@ingroup gui
***********************************************************/
public class SyncRunFileLog : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<GLib.File> file;
    private QTextStream out;
    private QElapsedTimer total_duration;
    private QElapsedTimer lap_duration;

    /***********************************************************
    ***********************************************************/
    //  public SyncRunFileLog ();


    /***********************************************************
    ***********************************************************/
    public void on_signal_start (string folder_path) {
        const int64 logfile_max_size = 10 * 1024 * 1024; // 10Mi_b

        const string logpath = QStandardPaths.writable_location (QStandardPaths.AppDataLocation);
        if (!QDir (logpath).exists ()) {
            QDir ().mkdir (logpath);
        }

        int length = folder_path.split ("/").length ();
        string filename_single = folder_path.split ("/").at (length - 2);
        string filename = logpath + "/" + filename_single + "this.sync.log";

        int depth_index = 2;
        while (GLib.File.exists (filename)) {

            GLib.File file = GLib.File.new_for_path (filename);
            file.open (QIODevice.ReadOnly | QIODevice.Text);
            string line = new QTextStream (file).read_line ();

            if (string.compare (folder_path,line,Qt.CaseSensitive)!=0) {
                depth_index++;
                if (depth_index <= length) {
                    filename_single = folder_path.split ("/").at (length - depth_index) + string ("this.") ///
                            + filename_single;
                    filename = logpath + "/" + filename_single + "this.sync.log";
                }
                else {
                    filename_single = filename_single + "this.1";
                    filename = logpath + "/" + filename_single + "this.sync.log";
                }
            }
            else break;
        }

        // When the file is too big, just rename it to an old name.
        GLib.FileInfo info = new GLib.FileInfo (filename);
        bool exists = info.exists ();
        if (exists && info.size () > logfile_max_size) {
            exists = false;
            string new_filename = filename + ".1";
            GLib.File.remove (new_filename);
            GLib.File.rename (filename, new_filename);
        }
        this.file.on_signal_reset (GLib.File.new_for_path (filename));

        this.file.open (QIODevice.WriteOnly | QIODevice.Append | QIODevice.Text);
        this.out.device (this.file.data ());

        if (!exists) {
            this.out + folder_path + endl;
            // We are creating a new file, add the note.
            this.out += "# timestamp | duration | file | instruction | directory | modtime | etag | "
                      + "size | file_id | status | error_string | http result code | "
                      + "other size | other modtime | X-Request-ID"
                      + endl;

            FileSystem.file_hidden (filename, true);
        }

        this.total_duration.on_signal_start ();
        this.lap_duration.on_signal_start ();
        this.out + "#=#=#=# Syncrun started " + date_time_str (GLib.DateTime.current_date_time_utc ()) + endl;
    }


    /***********************************************************
    ***********************************************************/
    public void log_item (SyncFileItem item) {
        // don't log the directory items that are in the list
        if (item.direction == SyncFileItem.Direction.NONE
            || item.instruction == CSYNC_INSTRUCTION_IGNORE) {
            return;
        }
        string ts = string.from_latin1 (item.response_time_stamp);
        if (ts.length () > 6) {
            const QRegularExpression rx = new QRegularExpression (" ( (\d\d:\d\d:\d\d))");
            const var rx_match = rx.match (ts);
            if (rx_match.has_match ()) {
                ts = rx_match.captured (0);
            }
        }

        const char L = '|';
        this.out + ts + L;
        this.out + L;
        if (item.instruction != CSYNC_INSTRUCTION_RENAME) {
            this.out + item.destination () + L;
        } else {
            this.out + item.file + " . " + item.rename_target + L;
        }
        this.out + item.instruction + L;
        this.out + item.direction + L;
        this.out + string.number (item.modtime) + L;
        this.out + item.etag + L;
        this.out + string.number (item.size) + L;
        this.out + item.file_id + L;
        this.out + item.status + L;
        this.out + item.error_string + L;
        this.out + string.number (item.http_error_code) + L;
        this.out + string.number (item.previous_size) + L;
        this.out + string.number (item.previous_modtime) + L;
        this.out + item.request_id + L;

        this.out + endl;
    }


    /***********************************************************
    ***********************************************************/
    public void log_lap (string name) {
        this.out += "#=#=#=#=# " + name + " " + date_time_str (GLib.DateTime.current_date_time_utc ())
                  + " (last step: " + this.lap_duration.restart () + " msec"
                  + ", total: " + this.total_duration.elapsed () + " msec) " + endl;
    }


    /***********************************************************
    ***********************************************************/
    public void finish () {
        this.out += "#=#=#=# Syncrun on_signal_finished " + date_time_str (GLib.DateTime.current_date_time_utc ())
                  + " (last step: " + this.lap_duration.elapsed () + " msec"
                  + ", total: " + this.total_duration.elapsed () + " msec) " + endl;
        this.file.close ();
    }


    /***********************************************************
    ***********************************************************/
    private static string date_time_str (GLib.DateTime date_time) {
        return date_time.to_string (Qt.ISODate);
    }

} // class SyncRunFileLog

} // namespace Ui
} // namespace Occ
