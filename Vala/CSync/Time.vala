namespace Occ {
namespace CSync {

/***********************************************************
c_time - time functions

This might be Windows-only and unnecessary on Linux?

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>

@copyright LGPL 2.1 or later
***********************************************************/
public class Time : GLib.Object {

    private const int CSYNC_SECONDS_SINCE_1601 = 11644473600LL;
    private const int CSYNC_USEC_IN_SEC        = 1000000LL;

    //  #ifdef HAVE_UTIMES
    public int c_utimes (string uri, timeval times) {
        int ret = utimes (GLib.File.encode_name (uri).const_data (), times);
        return ret;
    }

    public int c_utimes (string uri, timeval times) {
        FILETIME last_access_time;
        FILETIME last_modification_time;
        HANDLE h_file;

        var wuri = uri.to_std_w_string ();

        if (times) {
            unix_timeval_to_file_time (times[0], &last_access_time);
            unix_timeval_to_file_time (times[1], &last_modification_time);
        }
        else {
            Get_system_time_as_file_time (&last_access_time);
            Get_system_time_as_file_time (&last_modification_time);
        }

        h_file=Create_file_w (wuri, FILE_WRITE_ATTRIBUTES, FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE,
                        NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL+FILE_FLAG_BACKUP_SEMANTICS, NULL);
        if (h_file==INVALID_HANDLE_VALUE) {
            switch (Get_last_error ()) {
                case ERROR_FILE_NOT_FOUND:
                    errno=ENOENT;
                    break;
                case ERROR_PATH_NOT_FOUND:
                case ERROR_INVALID_DRIVE:
                    errno=ENOTDIR;
                    break;
                    /*case ERROR_WRITE_PROTECT :   //Create_file sets ERROR_ACCESS_DENIED on read-only devices
                                errno=EROFS;
                                break;*/
                    case ERROR_ACCESS_DENIED:
                        errno=EACCES;
                        break;
                    default:
                        errno=ENOENT;   //what other errors can occur?
            }

            return -1;
        }

        if (!set_file_time (h_file, NULL, &last_access_time, &last_modification_time)) {
            //can this happen?
            errno=ENOENT;
            close_handle (h_file);
            return -1;
        }

        close_handle (h_file);

        return 0;
    }

    // after Microsoft KB167296
    private static void unix_timeval_to_file_time (timeval t, LPFILETIME pft) {
        LONGLONG ll;
        ll = Int32x32To64 (t.tv_sec, CSYNC_USEC_IN_SEC*10) + t.tv_usec*10 + CSYNC_SECONDS_SINCE_1601*CSYNC_USEC_IN_SEC*10;
        pft.dw_low_date_time = (DWORD)ll;
        pft.dw_high_date_time = ll >> 32;
    }

} // class Time

} // namespace CSync
} // namespace Occ
