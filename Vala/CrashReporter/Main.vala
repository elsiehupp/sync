/***********************************************************
Copyright (C) by Dominik Schmidt <domme@tomahawk-player.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <libcrashreporter-gui/CrashReporter.h>
//  #include
//  #include <QAppl
//  #include <QDir>
//  #include <QDebug>
//  #include <QFileInfo>

int main (int argc, char argv[]) {
    QCoreApplication.set_attribute (Qt.AA_Use_high_dpi_pixmaps, true);
    QApplication app (argc, argv);

    if (app.arguments ().size () != 2) {
        q_debug () << "You need to pass the .dmp file path as only argument";
        return 1;
    }

    // TODO : install socorro ....
    CrashReporter reporter (GLib.Uri (CRASHREPORTER_SUBMIT_URL), app.arguments ());

#ifdef CRASHREPORTER_ICON
    reporter.set_logo (QPixmap (CRASHREPORTER_ICON));
#endif
    reporter.set_window_title (CRASHREPORTER_PRODUCT_NAME);
    reporter.on_set_text ("<html><head/><body><p><span style=\" font-weight:600;\">Sorry!</span> " CRASHREPORTER_PRODUCT_NAME " crashed. Please tell us about it! " CRASHREPORTER_PRODUCT_NAME " has created an error report for you that can help improve the stability in the future. You can now send this report directly to the " CRASHREPORTER_PRODUCT_NAME " developers.</p></body></html>");

    const QFileInfo crash_log (QDir.temp_path () + "/" + CRASHREPORTER_PRODUCT_NAME + "-crash.log");
    if (crash_log.exists ()) {
        GLib.File in_file (crash_log.file_path ());
        if (in_file.open (GLib.File.ReadOnly)) {
            reporter.set_comment (in_file.read_all ());
        }
    }

    reporter.set_report_data ("Build_iD", CRASHREPORTER_BUILD_ID);
    reporter.set_report_data ("Product_name", CRASHREPORTER_PRODUCT_NAME);
    reporter.set_report_data ("Version", CRASHREPORTER_VERSION_STRING);
    reporter.set_report_data ("Release_channel", CRASHREPORTER_RELEASE_CHANNEL);

    //reporter.set_report_data ( "timestamp", GLib.ByteArray.number ( GLib.DateTime.current_date_time ().to_time_t () ) );

    // add parameters

    //            << Pair ("Install_time", "1357622062")
    //            << Pair ("Theme", "classic/1.0")
    //            << Pair ("Version", "30")
    //            << Pair ("identifier", "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}")
    //            << Pair ("Vendor", "Mozilla")
    //            << Pair ("EMCheck_compatibility", "true")
    //            << Pair ("Throttleable", "0")
    //            << Pair ("URL", "http://code.google.com/p/crashme/")
    //            << Pair ("version", "20.0a1")
    //            << Pair ("Crash_time", "1357770042")
    //            << Pair ("submitted_timestamp", "2013-01-09T22:21:18.646733+00:00")
    //            << Pair ("buildid", "20130107030932")
    //            << Pair ("timestamp", "1357770078.646789")
    //            << Pair ("Notes", "Open_g_l : NVIDIA Corporation -- Ge_force 8600M GT/PCIe/SSE2 -- 3.3.0 NVIDIA 313.09 -- texture_from_pixmap\r\n")
    //            << Pair ("Startup_time", "1357769913")
    //            << Pair ("Frame_poison_size", "4096")
    //            << Pair ("Frame_poison_base", "7ffffffff0dea000")
    //            << Pair ("Add-ons", "%7B972ce4c6-7e08-4474-a285-3208198ce6fd%7D:20.0a1,crashme%40ted.mielczarek.org:0.4")
    //            << Pair ("Seconds_since_last_crash", "1831736")
    //            << Pair ("Product_name", "Water_wolf")
    //            << Pair ("legacy_processing", "0")
    //            << Pair ("Product_iD", "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}")

    ;

    // TODO:
    // send log
    //    GLib.File log_file ( INSERT_FILE_PATH_HERE );
    //    log_file.open ( GLib.File.ReadOnly );
    //    reporter.set_report_data ( "upload_file_miralllog", q_compress ( log_file.read_all () ), "application/x-gzip", QFileInfo ( INSERT_FILE_PATH_HERE ).filename ().to_utf8 ());
    //    log_file.close ();

    reporter.show ();

    return app.exec ();
}
