/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Uri>
// #include <QUrlQuery>
// #include <QProcess>

// #include <QSysInfo>

// #include <QLoggingCategory>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_updater)

class Updater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public struct Helper {
        static int64 string_version_to_int (string version);
        static int64 current_version_to_int ();
        static int64 version_to_int (int64 major, int64 minor, int64 patch, int64 build);
    };

    /***********************************************************
    ***********************************************************/
    public static Updater instance ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public virtual void check_for_update ();
    public virtual void background_check_for_update ();
    public virtual bool handle_startup ();


    protected static string client_version ();
    protected Updater ()
        : GLib.Object (nullptr) {
    }


    /***********************************************************
    ***********************************************************/
    private static string get_system_info ();
    private static QUrlQuery get_query_params ();
    private static Updater create ();
    private static Updater _instance;
};


    Updater *Updater._instance = nullptr;

    Updater *Updater.instance () {
        if (!_instance) {
            _instance = create ();
        }
        return _instance;
    }

    GLib.Uri Updater.update_url () {
        GLib.Uri update_base_url (string.from_local8Bit (qgetenv ("OCC_UPDATE_URL")));
        if (update_base_url.is_empty ()) {
            update_base_url = GLib.Uri (QLatin1String (APPLICATION_UPDATE_URL));
        }
        if (!update_base_url.is_valid () || update_base_url.host () == ".") {
            return GLib.Uri ();
        }

        var url_query = get_query_params ();

        update_base_url.set_query (url_query);

        return update_base_url;
    }

    QUrlQuery Updater.get_query_params () {
        QUrlQuery query;
        Theme theme = Theme.instance ();
        string platform = QStringLiteral ("stranger");
        if (Utility.is_linux ()) {
            platform = QStringLiteral ("linux");
        } else if (Utility.is_b_sD ()) {
            platform = QStringLiteral ("bsd");
        } else if (Utility.is_windows ()) {
            platform = QStringLiteral ("win32");
        } else if (Utility.is_mac ()) {
            platform = QStringLiteral ("macos");
        }

        string sys_info = get_system_info ();
        if (!sys_info.is_empty ()) {
            query.add_query_item (QStringLiteral ("client"), sys_info);
        }
        query.add_query_item (QStringLiteral ("version"), client_version ());
        query.add_query_item (QStringLiteral ("platform"), platform);
        query.add_query_item (QStringLiteral ("os_release"), QSysInfo.product_type ());
        query.add_query_item (QStringLiteral ("os_version"), QSysInfo.product_version ());
        query.add_query_item (QStringLiteral ("kernel_version"), QSysInfo.kernel_version ());
        query.add_query_item (QStringLiteral ("oem"), theme.app_name ());
        query.add_query_item (QStringLiteral ("build_arch"), QSysInfo.build_cpu_architecture ());
        query.add_query_item (QStringLiteral ("current_arch"), QSysInfo.current_cpu_architecture ());

        string suffix = QStringLiteral (MIRALL_STRINGIFY (MIRALL_VERSION_SUFFIX));
        query.add_query_item (QStringLiteral ("versionsuffix"), suffix);

        var channel = ConfigFile ().update_channel ();
        if (channel != QLatin1String ("stable")) {
            query.add_query_item (QStringLiteral ("channel"), channel);
        }

        // update_segment (see configfile.h)
        ConfigFile cfg;
        var update_segment = cfg.update_segment ();
        query.add_query_item (QLatin1String ("updatesegment"), string.number (update_segment));

        return query;
    }

    string Updater.get_system_info () {
    #ifdef Q_OS_LINUX
        QProcess process;
        process.on_start (QLatin1String ("lsb_release"), {
            QStringLiteral ("-a")
        });
        process.wait_for_finished ();
        GLib.ByteArray output = process.read_all_standard_output ();
        GLib.debug (lc_updater) << "Sys Info size : " << output.length ();
        if (output.length () > 1024)
            output.clear (); // don't send too much.

        return string.from_local8Bit (output.to_base64 ());
    #else
        return "";
    #endif
    }

    // To test, cmake with -DAPPLICATION_UPDATE_URL="http://127.0.0.1:8080/test.rss"
    Updater *Updater.create () {
        var url = update_url ();
        GLib.debug (lc_updater) << url;
        if (url.is_empty ()) {
            GLib.warn (lc_updater) << "Not a valid updater URL, will not do update check";
            return nullptr;
        }
        // the best we can do is notify about updates
        return new Passive_update_notifier (url);
    }

    int64 Updater.Helper.version_to_int (int64 major, int64 minor, int64 patch, int64 build) {
        return major << 56 | minor << 48 | patch << 40 | build;
    }

    int64 Updater.Helper.current_version_to_int () {
        return version_to_int (MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR,
            MIRALL_VERSION_PATCH, MIRALL_VERSION_BUILD);
    }

    int64 Updater.Helper.string_version_to_int (string version) {
        if (version.is_empty ())
            return 0;
        GLib.ByteArray ba_version = version.to_latin1 ();
        int major = 0, minor = 0, patch = 0, build = 0;
        sscanf (ba_version, "%d.%d.%d.%d", &major, &minor, &patch, &build);
        return version_to_int (major, minor, patch, build);
    }

    string Updater.client_version () {
        return string.from_latin1 (MIRALL_STRINGIFY (MIRALL_VERSION_FULL));
    }

    } // namespace Occ
    