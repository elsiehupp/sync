/***********************************************************
c_time - time functions

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

// #include <string>

#ifdef _WIN32
// #include <time.h>
#else
// #include <sys/time.h>
#endif

OCSYNC_EXPORT int c_utimes (string &uri, struct timeval *times);

















/***********************************************************
c_time - time functions

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

// #include <QFile>

#ifdef HAVE_UTIMES
int c_utimes (string &uri, struct timeval *times) {
    int ret = utimes (QFile.encode_name (uri).const_data (), times);
    return ret;
}
#else // HAVE_UTIMES

#ifdef _WIN32
// implementation for utimes taken from KDE mingw headers

// #include <errno.h>
// #include <wtypes.h>
const int CSYNC_SECONDS_SINCE_1601 11644473600LL
const int CSYNC_USEC_IN_SEC            1000000LL
//after Microsoft KB167296
static void Unix_timeval_to_file_time (struct timeval t, LPFILETIME pft) {
    LONGLONG ll;
    ll = Int32x32To64 (t.tv_sec, CSYNC_USEC_IN_SEC*10) + t.tv_usec*10 + CSYNC_SECONDS_SINCE_1601*CSYNC_USEC_IN_SEC*10;
    pft.dw_low_date_time = (DWORD)ll;
    pft.dw_high_date_time = ll >> 32;
}

int c_utimes (string &uri, struct timeval *times) {
    FILETIME Last_access_time;
    FILETIME Last_modification_time;
    HANDLE h_file;

    auto wuri = uri.to_std_w_string ();

    if (times) {
        Unix_timeval_to_file_time (times[0], &Last_access_time);
        Unix_timeval_to_file_time (times[1], &Last_modification_time);
    }
    else {
        Get_system_time_as_file_time (&Last_access_time);
        Get_system_time_as_file_time (&Last_modification_time);
    }

    h_file=Create_file_w (wuri.data (), FILE_WRITE_ATTRIBUTES, FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE,
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

    if (!Set_file_time (h_file, NULL, &Last_access_time, &Last_modification_time)) {
        //can this happen?
        errno=ENOENT;
        Close_handle (h_file);
        return -1;
    }

    Close_handle (h_file);

    return 0;
}

#endif // _WIN32
#endif // HAVE_UTIMES
