namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludedPerformance1

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludedPerformance1 : AbstractTestCSyncExclude {

//    /***********************************************************
//    GLib.T_ENABLE_REGEXP_JIT=0 to get slower results :-)
//    ***********************************************************/
//    private TestCSyncExcludedPerformance1 () {
//        base ();
//        int N = 1000;
//        int total_rc = 0;

//        //  GLib.BENCHMARK {

//            for (int i = 0; i < N; ++i) {
//                total_rc += check_dir_full ("/this/is/quite/a/long/path/with/many/components");
//                total_rc += check_file_full ("/1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/29");
//            }
//            GLib.assert_true (total_rc == 0); // mainly to avoid optimization
//        //  }
//    }

} // class TestCSyncExcludedPerformance1

} // namespace Testing
} // namespace Occ
