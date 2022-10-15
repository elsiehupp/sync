namespace Occ {
namespace CSync {

/***********************************************************
c_time - time functions

This might be Windows-only and unnecessary on Linux?

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>

@copyright LGPL 2.1 or later
***********************************************************/
public class Time { //: GLib.Object {

    //  private const int CSYNC_SECONDS_SINCE_1601 = 11644473600LL;
    //  private const int CSYNC_USEC_IN_SEC        = 1000000LL;

    //  #ifdef HAVE_UTIMES
    //  public int GLib.FileUtils.utime ( (string uri, time_t times) {
        //  int ret = GLib.FileUtils.utime (uri, times);
        //  return ret;
    //  }

    // after Microsoft KB167296
    //  private static void unix_timeval_to_file_time (time_t t, LPFILETIME pft) {
        //  int64 ll;
        //  ll = Int32x32To64 (t.tv_sec, CSYNC_USEC_IN_SEC*10) + t.tv_usec*10 + CSYNC_SECONDS_SINCE_1601*CSYNC_USEC_IN_SEC*10;
        //  pft.dw_low_date_time = (DWORD)ll;
        //  pft.dw_high_date_time = ll >> 32;
    //  }

} // class Time

} // namespace CSync
} // namespace Occ
