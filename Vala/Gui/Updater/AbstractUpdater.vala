/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QUrlQuery>
//  #include <QProcess>
//  #include <QSysInfo>

namespace Occ {
namespace Ui {

public abstract class AbstractUpdater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public static AbstractUpdater instance {
        public get {
            if (AbstractUpdater.instance == null) {
                AbstractUpdater.instance = AbstractUpdater.updater;
            }
            return AbstractUpdater.instance;
        }
        private set {
            AbstractUpdater.instance = value;
        }
    }


    /***********************************************************
    ***********************************************************/
    public class Helper : GLib.Object {
        public static int64 string_version_to_int (string version) {
            if (version == "")
                return 0;
            string ba_version = version.to_latin1 ();
            int major = 0, minor = 0, patch = 0, build = 0;
            sscanf (ba_version, "%d.%d.%d.%d", major, minor, patch, build);
            return version_to_int (major, minor, patch, build);
        }

        public static int64 current_version_to_int () {
            return version_to_int (MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR,
                MIRALL_VERSION_PATCH, MIRALL_VERSION_BUILD);
        }


        public static int64 version_to_int (int64 major, int64 minor, int64 patch, int64 build) {
            return major << 56 | minor << 48 | patch << 40 | build;
        }
    }


    /***********************************************************
    ***********************************************************/
    protected AbstractUpdater () {
        base ();
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri update_url {
        public get {
            GLib.Uri update_base_url = new GLib.Uri (qgetenv ("OCC_UPDATE_URL").to_string ());
            if (update_base_url == "") {
                update_base_url = GLib.Uri (APPLICATION_UPDATE_URL);
            }
            if (!update_base_url.is_valid || update_base_url.host () == ".") {
                return new GLib.Uri ();
            }

            var url_query = this.query_params;

            update_base_url.query (url_query);

            return update_base_url;
        }
    }


    /***********************************************************
    ***********************************************************/
    public abstract void check_for_update ();


    /***********************************************************
    ***********************************************************/
    public abstract void on_signal_background_check_for_update ();


    /***********************************************************
    ***********************************************************/
    public abstract bool handle_startup ();


    /***********************************************************
    ***********************************************************/
    protected static string client_version () {
        return MIRALL_STRINGIFY (MIRALL_VERSION_FULL);
    }


    /***********************************************************
    ***********************************************************/
    private static string system_info {
        public get {
            QProcess process;
            process.on_signal_start ("lsb_release", {
                "-a"
            });
            process.wait_for_finished ();
            string output = process.read_all_standard_output ();
            GLib.debug ("Sys Info size: " + output.length);
            if (output.length > 1024)
                output == ""; // don't send too much.

            return string.from_local8Bit (output.to_base64 ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private static QUrlQuery query_params {
        public get {
            QUrlQuery query;
            Theme theme = Theme.instance;
            string platform = "stranger";
            if (Utility.is_linux ()) {
                platform = "linux";
            } else if (Utility.is_bsd ()) {
                platform = "bsd";
            } else if (Utility.is_windows ()) {
                platform = "win32";
            } else if (Utility.is_mac ()) {
                platform = "macos";
            }

            if (AbstractUpdater.system_info != "") {
                query.add_query_item ("client", AbstractUpdater.system_info);
            }
            query.add_query_item ("version", client_version ());
            query.add_query_item ("platform", platform);
            query.add_query_item ("os_release", QSysInfo.product_type ());
            query.add_query_item ("os_version", QSysInfo.product_version ());
            query.add_query_item ("kernel_version", QSysInfo.kernel_version ());
            query.add_query_item ("oem", theme.app_name);
            query.add_query_item ("build_arch", QSysInfo.build_cpu_architecture ());
            query.add_query_item ("current_arch", QSysInfo.current_cpu_architecture ());

            string suffix = MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX);
            query.add_query_item ("versionsuffix", suffix);

            var channel = ConfigFile ().update_channel;
            if (channel != "stable") {
                query.add_query_item ("channel", channel);
            }

            // update_segment (see configfile.h)
            ConfigFile config;
            var update_segment = config.update_segment ();
            query.add_query_item ("updatesegment", string.number (update_segment));

            return query;
        }
    }


    /***********************************************************
    To test, cmake with -DAPPLICATION_UPDATE_URL="http://127.0.0.1:8080/test.rss"
    ***********************************************************/
    private static AbstractUpdater updater {
        public get {
            var url = AbstractUpdater.update_url;
            GLib.debug (url.to_string ());
            if (url == null) {
                GLib.warning ("Not a valid updater URL; will not do update check.");
                return null;
            }
            // the best we can do is notify about updates
            return new PassiveUpdateNotifier (url);
        }
    }

} // class AbstractUpdater

} // namespace Ui
} // namespace Occ
