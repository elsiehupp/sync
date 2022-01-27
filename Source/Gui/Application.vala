/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <iostream>
// #include <random>

#if defined (BUILD_UPDATER)
#endif

#if defined (WITH_CRASHREPORTER)
// #include <libcrashreporter-handler/Handler.h>
#endif

// #include <QTranslator>
// #include <QMenu>
// #include <QMessageBox>
// #include <QDesktopServices>
// #include <QGuiApplication>

// #include <QApplication>
// #include <QPointer>
// #include <QQueue>
// #include <QTimer>
// #include <QElapsedTimer>
// #include <QNetworkConfigurationManager>


namespace CrashReporter {
}

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_application)


/***********************************************************
@brief The Application class
@ingroup gui
***********************************************************/
class Application : SharedTools.QtSingleApplication {

    public Application (int &argc, char **argv);
    ~Application () override;

    public bool give_help ();
    public void show_help ();
    public void show_hint (std.string error_hint);
    public bool debug_mode ();
    public bool background_mode ();
    public bool version_only (); // only display the version?
    public void show_version ();

    public void show_main_dialog ();

    public OwncloudGui *gui ();


    // TODO: this should not be public
    public void on_owncloud_wizard_done (int);
    public void on_crash ();

    /***********************************************************
    Will download a virtual file, and open the result.
    The argument is the filename of the virtual file (including the extension)
    ***********************************************************/
    public void on_open_virtual_file (string filename);

    /// Attempt to show () the tray icon again. Used if no systray was available initially.
    public void on_try_tray_again ();


    protected void parse_options (string[] &);
    protected void setup_translations ();
    protected void setup_logging ();
    protected bool event (QEvent *event) override;

signals:
    void folder_removed ();
    void folder_state_changed (Folder *);
    void is_showing_settings_dialog ();

protected slots:
    void on_parse_message (string , GLib.Object *);
    void on_check_connection ();
    void on_use_mono_icons_changed (bool);
    void on_cleanup ();
    void on_account_state_added (AccountState *account_state);
    void on_account_state_removed (AccountState *account_state);
    void on_system_online_configuration_changed (QNetworkConfiguration);
    void on_gui_is_showing_settings ();


    private void set_help ();

    /***********************************************************
    Maybe a newer version of the client was used with this config file:
    if so, backup, confirm with user and remove the config that can't be read.
    ***********************************************************/
    private bool config_version_migration ();

    private QPointer<OwncloudGui> _gui;

    private Theme _theme;

    private bool _help_only;
    private bool _version_only;

    private QElapsedTimer _started_at;

    // options from command line:
    private bool _show_log_window;
    private bool _quit_instance = false;
    private string _log_file;
    private string _log_dir;
    private int _log_expire;
    private bool _log_flush;
    private bool _log_debug;
    private bool _user_triggered_connect;
    private bool _debug_mode;
    private bool _background_mode;

    private ClientProxy _proxy;

    private QNetworkConfigurationManager _network_configuration_manager;
    private QTimer _check_connection_timer;

#if defined (WITH_CRASHREPORTER)
    private QScopedPointer<CrashReporter.Handler> _crash_handler;
#endif
    private QScopedPointer<FolderMan> _folder_manager;
};



namespace {

    static const char options_c[] =
        "Options:\n"
        "  --help, -h           : show this help screen.\n"
        "  --version, -v        : show version information.\n"
        "  -q --quit            : quit the running instance\n"
        "  --logwindow, -l      : open a window to show log output.\n"
        "  --logfile <filename> : write log output to file <filename>.\n"
        "  --logdir <name>      : write each sync log output in a new file\n"
        "                         in folder <name>.\n"
        "  --logexpire <hours>  : removes logs older than <hours> hours.\n"
        "                         (to be used with --logdir)\n"
        "  --logflush           : flush the log file after every write.\n"
        "  --logdebug           : also output debug-level messages in the log.\n"
        "  --confdir <dirname>  : Use the given configuration folder.\n"
        "  --background         : launch the application in the background.\n";

    string application_tr_path () {
        string dev_tr_path = q_app.application_dir_path () + string.from_latin1 ("/../src/gui/");
        if (QDir (dev_tr_path).exists ()) {
            // might miss Qt, QtKeyChain, etc.
            q_c_warning (lc_application) << "Running from build location! Translations may be incomplete!";
            return dev_tr_path;
        }
#if defined (Q_OS_UNIX)
        return string.from_latin1 (SHAREDIR "/" APPLICATION_EXECUTABLE "/i18n/");
#endif
    }
}

// ----------------------------------------------------------------------------------

bool Application.config_version_migration () {
    string[] delete_keys, ignore_keys;
    AccountManager.backward_migration_settings_keys (&delete_keys, &ignore_keys);
    FolderMan.backward_migration_settings_keys (&delete_keys, &ignore_keys);

    ConfigFile config_file;

    // Did the client version change?
    // (The client version is adjusted further down)
    bool version_changed = config_file.client_version_string () != MIRALL_VERSION_STRING;

    // We want to message the user either for destructive changes,
    // or if we're ignoring something and the client version changed.
    bool warning_message = !delete_keys.is_empty () || (!ignore_keys.is_empty () && version_changed);

    if (!version_changed && !warning_message)
        return true;

    const auto backup_file = config_file.backup ();

    if (warning_message) {
        string bold_message;
        if (!delete_keys.is_empty ()) {
            bold_message = tr ("Continuing will mean <b>deleting these settings</b>.");
        } else {
            bold_message = tr ("Continuing will mean <b>ignoring these settings</b>.");
        }

        QMessageBox box (
            QMessageBox.Warning,
            APPLICATION_SHORTNAME,
            tr ("Some settings were configured in newer versions of this client and "
               "use features that are not available in this version.<br>"
               "<br>"
               "%1<br>"
               "<br>"
               "The current configuration file was already backed up to <i>%2</i>.")
                .arg (bold_message, backup_file));
        box.add_button (tr ("Quit"), QMessageBox.AcceptRole);
        auto continue_btn = box.add_button (tr ("Continue"), QMessageBox.DestructiveRole);

        box.exec ();
        if (box.clicked_button () != continue_btn) {
            QTimer.single_shot (0, q_app, SLOT (quit ()));
            return false;
        }

        auto settings = ConfigFile.settings_with_group ("foo");
        settings.end_group ();

        // Wipe confusing keys from the future, ignore the others
        for (auto &bad_key : delete_keys)
            settings.remove (bad_key);
    }

    config_file.set_client_version_string (MIRALL_VERSION_STRING);
    return true;
}

OwncloudGui *Application.gui () {
    return _gui;
}

Application.Application (int &argc, char **argv)
    : SharedTools.QtSingleApplication (Theme.instance ().app_name (), argc, argv)
    , _gui (nullptr)
    , _theme (Theme.instance ())
    , _help_only (false)
    , _version_only (false)
    , _show_log_window (false)
    , _log_expire (0)
    , _log_flush (false)
    , _log_debug (true)
    , _user_triggered_connect (false)
    , _debug_mode (false)
    , _background_mode (false) {
    _started_at.on_start ();

    qsrand (std.random_device () ());

    // TODO : Can't set this without breaking current config paths
    //    set_organization_name (QLatin1String (APPLICATION_VENDOR));
    set_organization_domain (QLatin1String (APPLICATION_REV_DOMAIN));

    // set_desktop_filename to provide wayland compatibility (in general : conformance with naming standards)
    // but only on Qt >= 5.7, where set_desktop_filename was introduced
#if (QT_VERSION >= 0x050700)
    string desktop_file_name = string (QLatin1String (LINUX_APPLICATION_ID)
                                        + QLatin1String (".desktop"));
    set_desktop_file_name (desktop_file_name);
#endif

    set_application_name (_theme.app_name ());
    set_window_icon (_theme.application_icon ());

    if (!ConfigFile ().exists ()) {
        // Migrate from version <= 2.4
        set_application_name (_theme.app_name_g_u_i ());
#ifndef QT_WARNING_DISABLE_DEPRECATED // Was added in Qt 5.9
const int QT_WARNING_DISABLE_DEPRECATED QT_WARNING_DISABLE_GCC ("-Wdeprecated-declarations")
#endif
        QT_WARNING_PUSH
        QT_WARNING_DISABLE_DEPRECATED
        // We need to use the deprecated QDesktopServices.storage_location because of its Qt4
        // behavior of adding "data" to the path
        string old_dir = QDesktopServices.storage_location (QDesktopServices.DataLocation);
        if (old_dir.ends_with ('/')) old_dir.chop (1); // mac_o_s 10.11.x does not like trailing slash for rename/move.
        QT_WARNING_POP
        set_application_name (_theme.app_name ());
        if (QFileInfo (old_dir).is_dir ()) {
            auto conf_dir = ConfigFile ().config_path ();
            if (conf_dir.ends_with ('/')) conf_dir.chop (1);  // mac_o_s 10.11.x does not like trailing slash for rename/move.
            q_c_info (lc_application) << "Migrating old config from" << old_dir << "to" << conf_dir;

            if (!QFile.rename (old_dir, conf_dir)) {
                q_c_warning (lc_application) << "Failed to move the old config directory to its new location (" << old_dir << "to" << conf_dir << ")";

                // Try to move the files one by one
                if (QFileInfo (conf_dir).is_dir () || QDir ().mkdir (conf_dir)) {
                    const string[] files_list = QDir (old_dir).entry_list (QDir.Files);
                    q_c_info (lc_application) << "Will move the individual files" << files_list;
                    for (auto &name : files_list) {
                        if (!QFile.rename (old_dir + "/" + name,  conf_dir + "/" + name)) {
                            q_c_warning (lc_application) << "Fallback move of " << name << "also failed";
                        }
                    }
                }
            }
        }
    }

    parse_options (arguments ());
    //no need to waste time;
    if (_help_only || _version_only)
        return;

    if (_quit_instance) {
        QTimer.single_shot (0, q_app, &QApplication.quit);
        return;
    }

    if (is_running ())
        return;

#if defined (WITH_CRASHREPORTER)
    if (ConfigFile ().crash_reporter ()) {
        auto reporter = QStringLiteral (CRASHREPORTER_EXECUTABLE);
        _crash_handler.on_reset (new CrashReporter.Handler (QDir.temp_path (), true, reporter));
    }
#endif

    setup_logging ();
    setup_translations ();

    if (!config_version_migration ()) {
        return;
    }

    ConfigFile cfg;
    // The timeout is initialized with an environment variable, if not, override with the value from the config
    if (!AbstractNetworkJob.http_timeout)
        AbstractNetworkJob.http_timeout = cfg.timeout ();

    // Check vfs plugins
    if (Theme.instance ().show_virtual_files_option () && best_available_vfs_mode () == Vfs.Off) {
        q_c_warning (lc_application) << "Theme wants to show vfs mode, but no vfs plugins are available";
    }
    if (is_vfs_plugin_available (Vfs.WindowsCfApi))
        q_c_info (lc_application) << "VFS windows plugin is available";
    if (is_vfs_plugin_available (Vfs.WithSuffix))
        q_c_info (lc_application) << "VFS suffix plugin is available";

    _folder_manager.on_reset (new FolderMan);

    connect (this, &SharedTools.QtSingleApplication.message_received, this, &Application.on_parse_message);

    if (!AccountManager.instance ().restore ()) {
        // If there is an error reading the account settings, try again
        // after a couple of seconds, if that fails, give up.
        // (non-existence is not an error)
        Utility.sleep (5);
        if (!AccountManager.instance ().restore ()) {
            q_c_critical (lc_application) << "Could not read the account settings, quitting";
            QMessageBox.critical (
                nullptr,
                tr ("Error accessing the configuration file"),
                tr ("There was an error while accessing the configuration "
                   "file at %1. Please make sure the file can be accessed by your user.")
                    .arg (ConfigFile ().config_file ()),
                tr ("Quit %1").arg (Theme.instance ().app_name_g_u_i ()));
            QTimer.single_shot (0, q_app, SLOT (quit ()));
            return;
        }
    }

    FolderMan.instance ().set_sync_enabled (true);

    set_quit_on_last_window_closed (false);

    _theme.set_systray_use_mono_icons (cfg.mono_icons ());
    connect (_theme, &Theme.systray_use_mono_icons_changed, this, &Application.on_use_mono_icons_changed);

    // Setting up the gui class will allow tray notifications for the
    // setup that follows, like folder setup
    _gui = new OwncloudGui (this);
    if (_show_log_window) {
        _gui.on_toggle_log_browser (); // _show_log_window is set in parse_options.
    }
#if WITH_LIBCLOUDPROVIDERS
    _gui.setup_cloud_providers ();
#endif

    FolderMan.instance ().setup_folders ();
    _proxy.on_setup_qt_proxy_from_config (); // folders have to be defined first, than we set up the Qt proxy.

    connect (AccountManager.instance (), &AccountManager.on_account_added,
        this, &Application.on_account_state_added);
    connect (AccountManager.instance (), &AccountManager.on_account_removed,
        this, &Application.on_account_state_removed);
    for (auto &ai : AccountManager.instance ().accounts ()) {
        on_account_state_added (ai.data ());
    }

    connect (FolderMan.instance ().socket_api (), &SocketApi.share_command_received,
        _gui.data (), &OwncloudGui.on_show_share_dialog);

    connect (FolderMan.instance ().socket_api (), &SocketApi.file_activity_command_received,
        Systray.instance (), &Systray.show_file_activity_dialog);

    // startup procedure.
    connect (&_check_connection_timer, &QTimer.timeout, this, &Application.on_check_connection);
    _check_connection_timer.set_interval (ConnectionValidator.DefaultCallingIntervalMsec); // check for connection every 32 seconds.
    _check_connection_timer.on_start ();
    // Also check immediately
    QTimer.single_shot (0, this, &Application.on_check_connection);

    // Can't use online_state_changed because it is always true on modern systems because of many interfaces
    connect (&_network_configuration_manager, &QNetworkConfigurationManager.configuration_changed,
        this, &Application.on_system_online_configuration_changed);

#if defined (BUILD_UPDATER)
    // Update checks
    auto *updater_scheduler = new UpdaterScheduler (this);
    connect (updater_scheduler, &UpdaterScheduler.updater_announcement,
        _gui.data (), &OwncloudGui.on_show_tray_message);
    connect (updater_scheduler, &UpdaterScheduler.request_restart,
        _folder_manager.data (), &FolderMan.on_schedule_app_restart);
#endif

    // Cleanup at Quit.
    connect (this, &QCoreApplication.about_to_quit, this, &Application.on_cleanup);

    // Allow other classes to hook into is_showing_settings_dialog () signals (re-auth widgets, for example)
    connect (_gui.data (), &OwncloudGui.is_showing_settings_dialog, this, &Application.on_gui_is_showing_settings);

    _gui.create_tray ();
}

Application.~Application () {
    // Make sure all folders are gone, otherwise removing the
    // accounts will remove the associated folders from the settings.
    if (_folder_manager) {
        _folder_manager.unload_and_delete_all_folders ();
    }

    // Remove the account from the account manager so it can be deleted.
    disconnect (AccountManager.instance (), &AccountManager.on_account_removed,
        this, &Application.on_account_state_removed);
    AccountManager.instance ().shutdown ();
}

void Application.on_account_state_removed (AccountState *account_state) {
    if (_gui) {
        disconnect (account_state, &AccountState.state_changed,
            _gui.data (), &OwncloudGui.on_account_state_changed);
        disconnect (account_state.account ().data (), &Account.server_version_changed,
            _gui.data (), &OwncloudGui.on_tray_message_if_server_unsupported);
    }
    if (_folder_manager) {
        disconnect (account_state, &AccountState.state_changed,
            _folder_manager.data (), &FolderMan.on_account_state_changed);
        disconnect (account_state.account ().data (), &Account.server_version_changed,
            _folder_manager.data (), &FolderMan.on_server_version_changed);
    }

    // if there is no more account, show the wizard.
    if (_gui && AccountManager.instance ().accounts ().is_empty ()) {
        // allow to add a new account if there is non any more. Always think
        // about single account theming!
        OwncloudSetupWizard.run_wizard (this, SLOT (on_owncloud_wizard_done (int)));
    }
}

void Application.on_account_state_added (AccountState *account_state) {
    connect (account_state, &AccountState.state_changed,
        _gui.data (), &OwncloudGui.on_account_state_changed);
    connect (account_state.account ().data (), &Account.server_version_changed,
        _gui.data (), &OwncloudGui.on_tray_message_if_server_unsupported);
    connect (account_state, &AccountState.state_changed,
        _folder_manager.data (), &FolderMan.on_account_state_changed);
    connect (account_state.account ().data (), &Account.server_version_changed,
        _folder_manager.data (), &FolderMan.on_server_version_changed);

    _gui.on_tray_message_if_server_unsupported (account_state.account ().data ());
}

void Application.on_cleanup () {
    AccountManager.instance ().save ();
    FolderMan.instance ().unload_and_delete_all_folders ();

    _gui.on_shutdown ();
    _gui.delete_later ();
}

// FIXME : This is not ideal yet since a ConnectionValidator might already be running and is in
// progress of timing out in some seconds.
// Maybe we need 2 validators, one triggered by timer, one by network configuration changes?
void Application.on_system_online_configuration_changed (QNetworkConfiguration cnf) {
    if (cnf.state () & QNetworkConfiguration.Active) {
        QMetaObject.invoke_method (this, "on_check_connection", Qt.QueuedConnection);
    }
}

void Application.on_check_connection () {
    const auto list = AccountManager.instance ().accounts ();
    for (auto &account_state : list) {
        AccountState.State state = account_state.state ();

        // Don't check if we're manually signed out or
        // when the error is permanent.
        const auto push_notifications = account_state.account ().push_notifications ();
        const auto push_notifications_available = (push_notifications && push_notifications.is_ready ());
        if (state != AccountState.SignedOut && state != AccountState.ConfigurationError
            && state != AccountState.AskingCredentials && !push_notifications_available) {
            account_state.on_check_connectivity ();
        }
    }

    if (list.is_empty ()) {
        // let gui open the setup wizard
        _gui.on_open_settings_dialog ();

        _check_connection_timer.stop (); // don't popup the wizard on interval;
    }
}

void Application.on_crash () {
    Utility.crash ();
}

void Application.on_owncloud_wizard_done (int res) {
    FolderMan *folder_man = FolderMan.instance ();

    // During the wizard, scheduling of new syncs is disabled
    folder_man.set_sync_enabled (true);

    if (res == Gtk.Dialog.Accepted) {
        // Check connectivity of the newly created account
        _check_connection_timer.on_start ();
        on_check_connection ();

        // If one account is configured : enable autostart
#ifndef QT_DEBUG
        bool should_set_auto_start = AccountManager.instance ().accounts ().size () == 1;
#else
        bool should_set_auto_start = false;
#endif
        if (should_set_auto_start) {
            Utility.set_launch_on_startup (_theme.app_name (), _theme.app_name_g_u_i (), true);
        }

        Systray.instance ().show_window ();
    }
}

void Application.setup_logging () {
    // might be called from second instance
    auto logger = Logger.instance ();
    logger.set_log_file (_log_file);
    if (_log_file.is_empty ()) {
        logger.set_log_dir (_log_dir.is_empty () ? ConfigFile ().log_dir () : _log_dir);
    }
    logger.set_log_expire (_log_expire > 0 ? _log_expire : ConfigFile ().log_expire ());
    logger.set_log_flush (_log_flush || ConfigFile ().log_flush ());
    logger.set_log_debug (_log_debug || ConfigFile ().log_debug ());
    if (!logger.is_logging_to_file () && ConfigFile ().automatic_log_dir ()) {
        logger.setup_temporary_folder_log_dir ();
    }

    logger.on_enter_next_log_file ();

    q_c_info (lc_application) << "##################" << _theme.app_name ()
                          << "locale:" << QLocale.system ().name ()
                          << "ui_lang:" << property ("ui_lang")
                          << "version:" << _theme.version ()
                          << "os:" << Utility.platform_name ();
    q_c_info (lc_application) << "Arguments:" << q_app.arguments ();
}

void Application.on_use_mono_icons_changed (bool) {
    _gui.on_compute_overall_sync_status ();
}

void Application.on_parse_message (string msg, GLib.Object *) {
    if (msg.starts_with (QLatin1String ("MSG_PARSEOPTIONS:"))) {
        const int length_of_msg_prefix = 17;
        string[] options = msg.mid (length_of_msg_prefix).split (QLatin1Char ('|'));
        _show_log_window = false;
        parse_options (options);
        setup_logging ();
        if (_show_log_window) {
            _gui.on_toggle_log_browser (); // _show_log_window is set in parse_options.
        }
        if (_quit_instance) {
            q_app.quit ();
        }

    } else if (msg.starts_with (QLatin1String ("MSG_SHOWMAINDIALOG"))) {
        q_c_info (lc_application) << "Running for" << _started_at.elapsed () / 1000.0 << "sec";
        if (_started_at.elapsed () < 10 * 1000) {
            // This call is mirrored with the one in int main ()
            q_c_warning (lc_application) << "Ignoring MSG_SHOWMAINDIALOG, possibly double-invocation of client via session restore and auto on_start";
            return;
        }

        // Show the main dialog only if there is at least one account configured
        if (!AccountManager.instance ().accounts ().is_empty ()) {
            show_main_dialog ();
        } else {
            _gui.on_new_account_wizard ();
        }
    }
}

void Application.parse_options (string[] &options) {
    QStringListIterator it (options);
    // skip file name;
    if (it.has_next ())
        it.next ();

    //parse options; if help or bad option exit
    while (it.has_next ()) {
        string option = it.next ();
        if (option == QLatin1String ("--help") || option == QLatin1String ("-h")) {
            set_help ();
            break;
        } else if (option == QLatin1String ("--quit") || option == QLatin1String ("-q")) {
            _quit_instance = true;
        } else if (option == QLatin1String ("--logwindow") || option == QLatin1String ("-l")) {
            _show_log_window = true;
        } else if (option == QLatin1String ("--logfile")) {
            if (it.has_next () && !it.peek_next ().starts_with (QLatin1String ("--"))) {
                _log_file = it.next ();
            } else {
                show_hint ("Log file not specified");
            }
        } else if (option == QLatin1String ("--logdir")) {
            if (it.has_next () && !it.peek_next ().starts_with (QLatin1String ("--"))) {
                _log_dir = it.next ();
            } else {
                show_hint ("Log dir not specified");
            }
        } else if (option == QLatin1String ("--logexpire")) {
            if (it.has_next () && !it.peek_next ().starts_with (QLatin1String ("--"))) {
                _log_expire = it.next ().to_int ();
            } else {
                show_hint ("Log expiration not specified");
            }
        } else if (option == QLatin1String ("--logflush")) {
            _log_flush = true;
        } else if (option == QLatin1String ("--logdebug")) {
            _log_debug = true;
        } else if (option == QLatin1String ("--confdir")) {
            if (it.has_next () && !it.peek_next ().starts_with (QLatin1String ("--"))) {
                string conf_dir = it.next ();
                if (!ConfigFile.set_conf_dir (conf_dir)) {
                    show_hint ("Invalid path passed to --confdir");
                }
            } else {
                show_hint ("Path for confdir not specified");
            }
        } else if (option == QLatin1String ("--debug")) {
            _log_debug = true;
            _debug_mode = true;
        } else if (option == QLatin1String ("--background")) {
            _background_mode = true;
        } else if (option == QLatin1String ("--version") || option == QLatin1String ("-v")) {
            _version_only = true;
        } else if (option.ends_with (QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX))) {
            // virtual file, open it after the Folder were created (if the app is not terminated)
            QTimer.single_shot (0, this, [this, option] {
                on_open_virtual_file (option);
            });
        } else {
            show_hint ("Unrecognized option '" + option.to_std_string () + "'");
        }
    }
}

// Helpers for displaying messages. Note that there is no console on Windows.

static void display_help_text (string t) {
    std.cout << q_utf8Printable (t);
}

void Application.show_help () {
    set_help ();
    string help_text;
    QTextStream stream (&help_text);
    stream << _theme.app_name ()
           << QLatin1String (" version ")
           << _theme.version () << endl;

    stream << QLatin1String ("File synchronisation desktop utility.") << endl
           << endl
           << QLatin1String (options_c);

    if (_theme.app_name () == QLatin1String ("own_cloud"))
        stream << endl
               << "For more information, see http://www.owncloud.org" << endl
               << endl;

    display_help_text (help_text);
}

void Application.show_version () {
    display_help_text (Theme.instance ().version_switch_output ());
}

void Application.show_hint (std.string error_hint) {
    static string bin_name = QFileInfo (QCoreApplication.application_file_path ()).file_name ();
    std.cerr << error_hint << std.endl;
    std.cerr << "Try '" << bin_name.to_std_string () << " --help' for more information" << std.endl;
    std.exit (1);
}

bool Application.debug_mode () {
    return _debug_mode;
}

bool Application.background_mode () {
    return _background_mode;
}

void Application.set_help () {
    _help_only = true;
}

string subst_lang (string lang) {
    // Map the more appropriate script codes
    // to country codes as used by Qt and
    // transifex translation conventions.

    // Simplified Chinese
    if (lang == QLatin1String ("zh_Hans"))
        return QLatin1String ("zh_CN");
    // Traditional Chinese
    if (lang == QLatin1String ("zh_Hant"))
        return QLatin1String ("zh_TW");
    return lang;
}

void Application.setup_translations () {
    string[] ui_languages;
    ui_languages = QLocale.system ().ui_languages ();

    string enforced_locale = Theme.instance ().enforced_locale ();
    if (!enforced_locale.is_empty ())
        ui_languages.prepend (enforced_locale);

    auto *translator = new QTranslator (this);
    auto *qt_translator = new QTranslator (this);
    auto *qtkeychain_translator = new QTranslator (this);

    for (string lang : q_as_const (ui_languages)) {
        lang.replace (QLatin1Char ('-'), QLatin1Char ('_')); // work around QTBUG-25973
        lang = subst_lang (lang);
        const string tr_path = application_tr_path ();
        const string tr_file = QLatin1String ("client_") + lang;
        if (translator.on_load (tr_file, tr_path) || lang.starts_with (QLatin1String ("en"))) {
            // Permissive approach : Qt and keychain translations
            // may be missing, but Qt translations must be there in order
            // for us to accept the language. Otherwise, we try with the next.
            // "en" is an exception as it is the default language and may not
            // have a translation file provided.
            q_c_info (lc_application) << "Using" << lang << "translation";
            set_property ("ui_lang", lang);
            const string qt_tr_path = QLibraryInfo.location (QLibraryInfo.TranslationsPath);
            const string qt_tr_file = QLatin1String ("qt_") + lang;
            const string qt_base_tr_file = QLatin1String ("qtbase_") + lang;
            if (!qt_translator.on_load (qt_tr_file, qt_tr_path)) {
                if (!qt_translator.on_load (qt_tr_file, tr_path)) {
                    if (!qt_translator.on_load (qt_base_tr_file, qt_tr_path)) {
                        qt_translator.on_load (qt_base_tr_file, tr_path);
                    }
                }
            }
            const string qtkeychain_tr_file = QLatin1String ("qtkeychain_") + lang;
            if (!qtkeychain_translator.on_load (qtkeychain_tr_file, qt_tr_path)) {
                qtkeychain_translator.on_load (qtkeychain_tr_file, tr_path);
            }
            if (!translator.is_empty ())
                install_translator (translator);
            if (!qt_translator.is_empty ())
                install_translator (qt_translator);
            if (!qtkeychain_translator.is_empty ())
                install_translator (qtkeychain_translator);
            break;
        }
        if (property ("ui_lang").is_null ())
            set_property ("ui_lang", "C");
    }
}

bool Application.give_help () {
    return _help_only;
}

bool Application.version_only () {
    return _version_only;
}

void Application.show_main_dialog () {
    _gui.on_open_main_dialog ();
}

void Application.on_gui_is_showing_settings () {
    emit is_showing_settings_dialog ();
}

void Application.on_open_virtual_file (string filename) {
    string virtual_file_ext = QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    if (!filename.ends_with (virtual_file_ext)) {
        q_warning (lc_application) << "Can only handle file ending in .owncloud. Unable to open" << filename;
        return;
    }
    auto folder = FolderMan.instance ().folder_for_path (filename);
    if (!folder) {
        q_warning (lc_application) << "Can't find sync folder for" << filename;
        // TODO : show a QMessageBox for errors
        return;
    }
    string relative_path = QDir.clean_path (filename).mid (folder.clean_path ().length () + 1);
    folder.on_implicitly_hydrate_file (relative_path);
    string normal_name = filename.left (filename.size () - virtual_file_ext.size ());
    auto con = unowned<QMetaObject.Connection>.create ();
    *con = connect (folder, &Folder.sync_finished, folder, [folder, con, normal_name] {
        folder.disconnect (*con);
        if (QFile.exists (normal_name)) {
            QDesktopServices.open_url (QUrl.from_local_file (normal_name));
        }
    });
}

void Application.on_try_tray_again () {
    q_c_info (lc_application) << "Trying tray icon, tray available:" << QSystemTrayIcon.is_system_tray_available ();
    _gui.hide_and_show_tray ();
}

bool Application.event (QEvent *event) {
    return SharedTools.QtSingleApplication.event (event);
}

} // namespace Occ
