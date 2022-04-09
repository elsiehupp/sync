

//  #include <libcrashreporter-gui/CrashReporter.h>
//  #include <GLib.Appl
//  #include <GLib.Dir>
//  #include <GLib.Debug>
//  #include <GLib.FileInfo>

namespace Occ {
namespace CrashReporter {

/***********************************************************
@author Dominik Schmidt <domme@tomahawk-player.org>

@copyright GPLv3 or Later
***********************************************************/
public class CrashReporter {

    public CrashReporter (int argc, char argv[]) {
        GLib.Application.attribute (GLib.AAUseHighDpiPixmaps, true);
        GLib.Application app = new GLib.Application (argc, argv);

        if (app.arguments ().length != 2) {
            GLib.debug ("You need to pass the .dmp file path as only argument.");
            return 1;
        }

        // TODO: install socorro ....
        CrashReporter reporter = new CrashReporter (new GLib.Uri (CRASHREPORTER_SUBMIT_URL), app.arguments ());

    //  #ifdef CRASHREPORTER_ICON
        reporter.logo (Gdk.Pixbuf (CRASHREPORTER_ICON));
    //  #endif
        reporter.window_title (CRASHREPORTER_PRODUCT_NAME);
        reporter.on_signal_text ("<html><head/><body><p><span style=\" font-weight:600;\">Sorry!</span> " + CRASHREPORTER_PRODUCT_NAME + " crashed. Please tell us about it! " + CRASHREPORTER_PRODUCT_NAME + " has created an error report for you that can help improve the stability in the future. You can now send this report directly to the " + CRASHREPORTER_PRODUCT_NAME + " developers.</p></body></html>");

        GLib.FileInfo crash_log = new GLib.FileInfo (GLib.Dir.temp_path + "/" + CRASHREPORTER_PRODUCT_NAME + "-crash.log");
        if (crash_log.exists ()) {
            GLib.File in_file = new GLib.File (crash_log.file_path);
            if (in_file.open (GLib.File.ReadOnly)) {
                reporter.comment (in_file.read_all ());
            }
        }

        reporter.report_data ("BuildID", CRASHREPORTER_BUILD_ID);
        reporter.report_data ("ProductName", CRASHREPORTER_PRODUCT_NAME);
        reporter.report_data ("Version", CRASHREPORTER_VERSION_STRING);
        reporter.report_data ("ReleaseChannel", CRASHREPORTER_RELEASE_CHANNEL);

        //reporter.report_data ( "timestamp", string.number ( GLib.DateTime.current_date_time ().to_time_t () ) );

        // add parameters

        //            + Pair ("InstallTime", "1357622062")
        //            + Pair ("Theme", "classic/1.0")
        //            + Pair ("Version", "30")
        //            + Pair ("identifier", "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}")
        //            + Pair ("Vendor", "Mozilla")
        //            + Pair ("EMCheckCompatibility", "true")
        //            + Pair ("Throttleable", "0")
        //            + Pair ("URL", "http://code.google.com/p/crashme/")
        //            + Pair ("version", "20.0a1")
        //            + Pair ("CrashTime", "1357770042")
        //            + Pair ("submitted_timestamp", "2013-01-09T22:21:18.646733+00:00")
        //            + Pair ("buildid", "20130107030932")
        //            + Pair ("timestamp", "1357770078.646789")
        //            + Pair ("Notes", "OpenGL : NVIDIA Corporation -- GeForce 8600M GT/PCIe/SSE2 -- 3.3.0 NVIDIA 313.09 -- texture_from_pixmap\r\n")
        //            + Pair ("StartupTime", "1357769913")
        //            + Pair ("FramePoisonSize", "4096")
        //            + Pair ("FramePoisonBase", "7ffffffff0dea000")
        //            + Pair ("Add-ons", "%7B972ce4c6-7e08-4474-a285-3208198ce6fd%7D:20.0a1,crashme%40ted.mielczarek.org:0.4")
        //            + Pair ("SecondsSinceLastCrash", "1831736")
        //            + Pair ("ProductName", "WaterWolf")
        //            + Pair ("legacyProcessing", "0")
        //            + Pair ("ProductID", "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}");

        // TODO:
        // send log
        //    GLib.File log_file ( INSERT_FILE_PATH_HERE );
        //    log_file.open ( GLib.File.ReadOnly );
        //    reporter.report_data ( "upload_file_miralllog", q_compress ( log_file.read_all () ), "application/x-gzip", GLib.FileInfo ( INSERT_FILE_PATH_HERE ).filename ().to_utf8 ());
        //    log_file.close ();

        reporter.show ();

        return app.exec ();
    }

} // public class CrashReporter

} // namespace CrashReporter
} // namespace Occ
