/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <iostream>
//  #include <random>

#if defined (BUILD_UPDATER)
//  #endif

#if defined (WITH_CRASHREPORTER)
//  #include <libcrashreporter-handler/Handler.h>
//  #endif

//  #include <QTranslator>
//  #include <QMenu>
//  #include <QMessageBox>
//  #include <QDesktopServices>
//  #include <QGuiApplication>
//  #include <QApplicat
//  #include <QPointe
//  #include <QQueue>
//  #include <QTimer>
//  #include <QElapsedTimer>
//  #include <QNetworkConfigurationManager>


namespace CrashReporter {
}

namespace Occ {


/***********************************************************
@brief The Application class
@ingroup gui
***********************************************************/
class Application : SharedTools.QtSingleApplication {

    /***********************************************************
    ***********************************************************/
    public Application (int argc, char **argv);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void show_help ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool debug_mode ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public bool version_only (); // only display the version?
    public void show_version ();

    public void show_main_dialog ();

    public OwncloudGui gui ();


    // TODO: this should not be public
    public void on_signal_owncloud_wizard_done (int);


    /***********************************************************
    ***********************************************************/
    public void on_signal_crash ();


    /***********************************************************
    Will download a virtual file, and open the result.
    The argument is the filename of the virtual file (including
    the extension)
    ***********************************************************/
    public void on_signal_open_virtual_file (string filename);

    /// Attempt to show () the tray icon again. Used if no systray was available initially.
    public void on_signal_try_tray_again ();


    protected void parse_options (string[] &);
    protected void setup_translations ();
    protected void setup_logging ();
    protected bool event (QEvent event) override;

signals:
    void folder_removed ();
    void folder_state_changed (Folder *);
    void signal_is_showing_settings_dialog ();

protected slots:
    void on_signal_parse_message (string , GLib.Object *);
    void on_signal_check_connection ();
    void on_signal_use_mono_icons_changed (bool);
    void on_signal_cleanup ();
    void on_signal_account_state_added (AccountState account_state);
    void on_signal_account_state_removed (AccountState account_state);
    void on_signal_system_online_configuration_changed (QNetworkConfiguration);
    void on_signal_gui_is_showing_settings ();


    /***********************************************************
    ***********************************************************/
    private void help ();


    /***********************************************************
    Maybe a newer version of the client was used with this config file:
    if so, backup, confirm with user and remove the config that can't be read.
    ***********************************************************/
    private bool config_version_migration ();

    /***********************************************************
    ***********************************************************/
    private QPointer<OwncloudGui> this.gui;

    /***********************************************************
    ***********************************************************/
    private Theme this.theme;

    /***********************************************************
    ***********************************************************/
    private bool this.help_only;

    /***********************************************************
    ***********************************************************/
    private 
    private QElapsedTimer this.started_at;

    // options from command line:
    private bool this.show_log_window;
    private bool this.quit_instance = false;
    private string this.log_file;
    private string this.log_dir;
    private int this.log_expire;
    private bool this.log_flush;
    private bool this.log_debug;
    private bool this.user_triggered_connect;
    private bool this.debug_mode;
    private bool this.background_mode;

    /***********************************************************
    ***********************************************************/
    private ClientProxy this.proxy;

    /***********************************************************
    ***********************************************************/
    private QNetworkConfigurationManager this.network_configuration_manager;
    private QTimer this.check_connection_timer;

#if defined (WITH_CRASHREPORTER)
    private QScopedPointer<CrashReporter.Handler> this.crash_handler;
//  #endif
    private QScopedPointer<FolderMan> this.folder_manager;
}



namespace {

    /***********************************************************
    ***********************************************************/
    const strings options_c[] =
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
        string dev_tr_path = Gtk.Application.application_dir_path () + string.from_latin1 ("/../src/gui/");
        if (QDir (dev_tr_path).exists ()) {
            // might miss Qt, QtKeyChain, etc.
            GLib.warning ("Running from build location! Translations may be incomplete!";
            return dev_tr_path;
        }
#if defined (Q_OS_UNIX)
        return string.from_latin1 (SHAREDIR "/" APPLICATION_EXECUTABLE "/i18n/");
//  #endif
    }
}

// ----------------------------------------------------------------------------------

bool Application.config_version_migration () {
    string[] delete_keys, ignore_keys;
    AccountManager.backward_migration_settings_keys (&delete_keys, ignore_keys);
    FolderMan.backward_migration_settings_keys (&delete_keys, ignore_keys);

    ConfigFile config_file;

    // Did the client version change?
    // (The client version is adjusted further down)
    bool version_changed = config_file.client_version_string () != MIRALL_VERSION_STRING;

    // We want to message the user either for destructive changes,
    // or if we're ignoring something and the client version changed.
    bool warning_message = !delete_keys.is_empty () || (!ignore_keys.is_empty () && version_changed);

    if (!version_changed && !warning_message)
        return true;

    const var backup_file = config_file.backup ();

    if (warning_message) {
        string bold_message;
        if (!delete_keys.is_empty ()) {
            bold_message = _("Continuing will mean <b>deleting these settings</b>.");
        } else {
            bold_message = _("Continuing will mean <b>ignoring these settings</b>.");
        }

        QMessageBox box (
            QMessageBox.Warning,
            APPLICATION_SHORTNAME,
            _("Some settings were configured in newer versions of this client and "
               "use features that are not available in this version.<br>"
               "<br>"
               "%1<br>"
               "<br>"
               "The current configuration file was already backed up to <i>%2</i>.")
                .arg (bold_message, backup_file));
        box.add_button (_("Quit"), QMessageBox.AcceptRole);
        var continue_btn = box.add_button (_("Continue"), QMessageBox.DestructiveRole);

        box.exec ();
        if (box.clicked_button () != continue_btn) {
            QTimer.single_shot (0, Gtk.Application, SLOT (quit ()));
            return false;
        }

        var settings = ConfigFile.settings_with_group ("foo");
        settings.end_group ();

        // Wipe confusing keys from the future, ignore the others
        for (var bad_key : delete_keys)
            settings.remove (bad_key);
    }

    config_file.client_version_string (MIRALL_VERSION_STRING);
    return true;
}

OwncloudGui *Application.gui () {
    return this.gui;
}

Application.Application (int argc, char **argv)
    : SharedTools.QtSingleApplication (Theme.instance ().app_name (), argc, argv)
    this.gui (null)
    this.theme (Theme.instance ())
    this.help_only (false)
    this.version_only (false)
    this.show_log_window (false)
    this.log_expire (0)
    this.log_flush (false)
    this.log_debug (true)
    this.user_triggered_connect (false)
    this.debug_mode (false)
    this.background_mode (false) {
    this.started_at.on_signal_start ();

    qsrand (std.random_device () ());

    // TODO : Can't set this without breaking current config paths
    //    organization_name (APPLICATION_VENDOR);
    organization_domain (APPLICATION_REV_DOMAIN);

    // desktop_filename to provide wayland compatibility (in general : conformance with naming standards)
    // but only on Qt >= 5.7, where desktop_filename was introduced
//  #if (QT_VERSION >= 0x050700)
    string desktop_filename = LINUX_APPLICATION_ID + ".desktop";
    desktop_filename (desktop_filename);
//  #endif

    application_name (this.theme.app_name ());
    window_icon (this.theme.application_icon ());

    if (!ConfigFile ().exists ()) {
        // Migrate from version <= 2.4
        application_name (this.theme.app_name_gui ());
//  #ifndef QT_WARNING_DISABLE_DEPRECATED // Was added in Qt 5.9
const int QT_WARNING_DISABLE_DEPRECATED QT_WARNING_DISABLE_GCC ("-Wdeprecated-declarations")
//  #endif
        QT_WARNING_PUSH
        QT_WARNING_DISABLE_DEPRECATED
        // We need to use the deprecated QDesktopServices.storage_location because of its Qt4
        // behavior of adding "data" to the path
        string old_dir = QDesktopServices.storage_location (QDesktopServices.DataLocation);
        if (old_dir.ends_with ('/')) old_dir.chop (1); // macOS 10.11.x does not like trailing slash for rename/move.
        QT_WARNING_POP
        application_name (this.theme.app_name ());
        if (GLib.FileInfo (old_dir).is_dir ()) {
            var conf_dir = ConfigFile ().config_path ();
            if (conf_dir.ends_with ('/')) conf_dir.chop (1);  // macOS 10.11.x does not like trailing slash for rename/move.
            GLib.info ("Migrating old config from" + old_dir + "to" + conf_dir;

            if (!GLib.File.rename (old_dir, conf_dir)) {
                GLib.warning ("Failed to move the old config directory to its new location (" + old_dir + "to" + conf_dir + ")";

                // Try to move the files one by one
                if (GLib.FileInfo (conf_dir).is_dir () || QDir ().mkdir (conf_dir)) {
                    const string[] files_list = QDir (old_dir).entry_list (QDir.Files);
                    GLib.info ("Will move the individual files" + files_list;
                    for (var name : files_list) {
                        if (!GLib.File.rename (old_dir + "/" + name,  conf_dir + "/" + name)) {
                            GLib.warning ("Fallback move of " + name + "also failed";
                        }
                    }
                }
            }
        }
    }

    parse_options (arguments ());
    //no need to waste time;
    if (this.help_only || this.version_only)
        return;

    if (this.quit_instance) {
        QTimer.single_shot (0, Gtk.Application, &QApplication.quit);
        return;
    }

    if (is_running ())
        return;

#if defined (WITH_CRASHREPORTER)
    if (ConfigFile ().crash_reporter ()) {
        var reporter = CRASHREPORTER_EXECUTABLE;
        this.crash_handler.on_signal_reset (new CrashReporter.Handler (QDir.temp_path (), true, reporter));
    }
//  #endif

    setup_logging ();
    setup_translations ();

    if (!config_version_migration ()) {
        return;
    }

    ConfigFile config;
    // The timeout is initialized with an environment variable, if not, override with the value from the config
    if (!AbstractNetworkJob.http_timeout)
        AbstractNetworkJob.http_timeout = config.timeout ();

    // Check vfs plugins
    if (Theme.instance ().show_virtual_files_option () && best_available_vfs_mode () == Vfs.Off) {
        GLib.warning ("Theme wants to show vfs mode, but no vfs plugins are available";
    }
    if (is_vfs_plugin_available (Vfs.WindowsCfApi))
        GLib.info ("VFS windows plugin is available";
    if (is_vfs_plugin_available (Vfs.WithSuffix))
        GLib.info ("VFS suffix plugin is available";

    this.folder_manager.on_signal_reset (new FolderMan);

    connect (this, &SharedTools.QtSingleApplication.message_received, this, &Application.on_signal_parse_message);

    if (!AccountManager.instance ().restore ()) {
        // If there is an error reading the account settings, try again
        // after a couple of seconds, if that fails, give up.
        // (non-existence is not an error)
        Utility.sleep (5);
        if (!AccountManager.instance ().restore ()) {
            GLib.critical ("Could not read the account settings, quitting";
            QMessageBox.critical (
                null,
                _("Error accessing the configuration file"),
                _("There was an error while accessing the configuration "
                   "file at %1. Please make sure the file can be accessed by your user.")
                    .arg (ConfigFile ().config_file ()),
                _("Quit %1").arg (Theme.instance ().app_name_gui ()));
            QTimer.single_shot (0, Gtk.Application, SLOT (quit ()));
            return;
        }
    }

    FolderMan.instance ().sync_enabled (true);

    quit_on_signal_last_window_closed (false);

    this.theme.systray_use_mono_icons (config.mono_icons ());
    connect (this.theme, &Theme.systray_use_mono_icons_changed, this, &Application.on_signal_use_mono_icons_changed);

    // Setting up the gui class will allow tray notifications for the
    // setup that follows, like folder setup
    this.gui = new OwncloudGui (this);
    if (this.show_log_window) {
        this.gui.on_signal_toggle_log_browser (); // this.show_log_window is set in parse_options.
    }
#if WITH_LIBCLOUDPROVIDERS
    this.gui.setup_cloud_providers ();
//  #endif

    FolderMan.instance ().set_up_folders ();
    this.proxy.on_signal_setup_qt_proxy_from_config (); // folders have to be defined first, than we set up the Qt proxy.

    connect (AccountManager.instance (), &AccountManager.on_signal_account_added,
        this, &Application.on_signal_account_state_added);
    connect (AccountManager.instance (), &AccountManager.on_signal_account_removed,
        this, &Application.on_signal_account_state_removed);
    for (var ai : AccountManager.instance ().accounts ()) {
        on_signal_account_state_added (ai.data ());
    }

    connect (FolderMan.instance ().socket_api (), &SocketApi.share_command_received,
        this.gui.data (), &OwncloudGui.on_signal_show_share_dialog);

    connect (FolderMan.instance ().socket_api (), &SocketApi.file_activity_command_received,
        Systray.instance (), &Systray.show_file_activity_dialog);

    // startup procedure.
    connect (&this.check_connection_timer, &QTimer.timeout, this, &Application.on_signal_check_connection);
    this.check_connection_timer.interval (ConnectionValidator.DefaultCallingIntervalMsec); // check for connection every 32 seconds.
    this.check_connection_timer.on_signal_start ();
    // Also check immediately
    QTimer.single_shot (0, this, &Application.on_signal_check_connection);

    // Can't use online_state_changed because it is always true on modern systems because of many interfaces
    connect (&this.network_configuration_manager, &QNetworkConfigurationManager.configuration_changed,
        this, &Application.on_signal_system_online_configuration_changed);

#if defined (BUILD_UPDATER)
    // Update checks
    var updater_scheduler = new UpdaterScheduler (this);
    connect (updater_scheduler, &UpdaterScheduler.updater_announcement,
        this.gui.data (), &OwncloudGui.on_signal_show_tray_message);
    connect (updater_scheduler, &UpdaterScheduler.request_restart,
        this.folder_manager.data (), &FolderMan.on_signal_schedule_app_restart);
//  #endif

    // Cleanup at Quit.
    connect (this, &QCoreApplication.about_to_quit, this, &Application.on_signal_cleanup);

    // Allow other classes to hook into signal_is_showing_settings_dialog () signals (re-auth widgets, for example)
    connect (this.gui.data (), &OwncloudGui.signal_is_showing_settings_dialog, this, &Application.on_signal_gui_is_showing_settings);

    this.gui.create_tray ();
}

Application.~Application () {
    // Make sure all folders are gone, otherwise removing the
    // accounts will remove the associated folders from the settings.
    if (this.folder_manager) {
        this.folder_manager.unload_and_delete_all_folders ();
    }

    // Remove the account from the account manager so it can be deleted.
    disconnect (AccountManager.instance (), &AccountManager.on_signal_account_removed,
        this, &Application.on_signal_account_state_removed);
    AccountManager.instance ().shutdown ();
}

void Application.on_signal_account_state_removed (AccountState account_state) {
    if (this.gui) {
        disconnect (account_state, &AccountState.state_changed,
            this.gui.data (), &OwncloudGui.on_signal_account_state_changed);
        disconnect (account_state.account ().data (), &Account.server_version_changed,
            this.gui.data (), &OwncloudGui.on_signal_tray_message_if_server_unsupported);
    }
    if (this.folder_manager) {
        disconnect (account_state, &AccountState.state_changed,
            this.folder_manager.data (), &FolderMan.on_signal_account_state_changed);
        disconnect (account_state.account ().data (), &Account.server_version_changed,
            this.folder_manager.data (), &FolderMan.on_signal_server_version_changed);
    }

    // if there is no more account, show the wizard.
    if (this.gui && AccountManager.instance ().accounts ().is_empty ()) {
        // allow to add a new account if there is non any more. Always think
        // about single account theming!
        OwncloudSetupWizard.run_wizard (this, SLOT (on_signal_owncloud_wizard_done (int)));
    }
}

void Application.on_signal_account_state_added (AccountState account_state) {
    connect (account_state, &AccountState.state_changed,
        this.gui.data (), &OwncloudGui.on_signal_account_state_changed);
    connect (account_state.account ().data (), &Account.server_version_changed,
        this.gui.data (), &OwncloudGui.on_signal_tray_message_if_server_unsupported);
    connect (account_state, &AccountState.state_changed,
        this.folder_manager.data (), &FolderMan.on_signal_account_state_changed);
    connect (account_state.account ().data (), &Account.server_version_changed,
        this.folder_manager.data (), &FolderMan.on_signal_server_version_changed);

    this.gui.on_signal_tray_message_if_server_unsupported (account_state.account ().data ());
}

void Application.on_signal_cleanup () {
    AccountManager.instance ().save ();
    FolderMan.instance ().unload_and_delete_all_folders ();

    this.gui.on_signal_shutdown ();
    this.gui.delete_later ();
}

// FIXME: This is not ideal yet since a ConnectionValidator might already be running and is in
// progress of timing out in some seconds.
// Maybe we need 2 validators, one triggered by timer, one by network configuration changes?
void Application.on_signal_system_online_configuration_changed (QNetworkConfiguration cnf) {
    if (cnf.state () & QNetworkConfiguration.Active) {
        QMetaObject.invoke_method (this, "on_signal_check_connection", Qt.QueuedConnection);
    }
}

void Application.on_signal_check_connection () {
    const var list = AccountManager.instance ().accounts ();
    for (var account_state : list) {
        AccountState.State state = account_state.state ();

        // Don't check if we're manually signed out or
        // when the error is permanent.
        const var push_notifications = account_state.account ().push_notifications ();
        const var push_notifications_available = (push_notifications && push_notifications.is_ready ());
        if (state != AccountState.State.SIGNED_OUT && state != AccountState.State.CONFIGURATION_ERROR
            && state != AccountState.State.ASKING_CREDENTIALS && !push_notifications_available) {
            account_state.on_signal_check_connectivity ();
        }
    }

    if (list.is_empty ()) {
        // let gui open the setup wizard
        this.gui.on_signal_open_settings_dialog ();

        this.check_connection_timer.stop (); // don't popup the wizard on interval;
    }
}

void Application.on_signal_crash () {
    Utility.crash ();
}

void Application.on_signal_owncloud_wizard_done (int res) {
    FolderMan folder_man = FolderMan.instance ();

    // During the wizard, scheduling of new syncs is disabled
    folder_man.sync_enabled (true);

    if (res == Gtk.Dialog.Accepted) {
        // Check connectivity of the newly created account
        this.check_connection_timer.on_signal_start ();
        on_signal_check_connection ();

        // If one account is configured : enable autostart
//  #ifndef QT_DEBUG
        bool should_auto_start = AccountManager.instance ().accounts ().size () == 1;
#else
        bool should_auto_start = false;
//  #endif
        if (should_auto_start) {
            Utility.launch_on_signal_startup (this.theme.app_name (), this.theme.app_name_gui (), true);
        }

        Systray.instance ().show_window ();
    }
}

void Application.setup_logging () {
    // might be called from second instance
    var logger = Logger.instance ();
    logger.log_file (this.log_file);
    if (this.log_file.is_empty ()) {
        logger.log_dir (this.log_dir.is_empty () ? ConfigFile ().log_dir () : this.log_dir);
    }
    logger.log_expire (this.log_expire > 0 ? this.log_expire : ConfigFile ().log_expire ());
    logger.log_flush (this.log_flush || ConfigFile ().log_flush ());
    logger.log_debug (this.log_debug || ConfigFile ().log_debug ());
    if (!logger.is_logging_to_file () && ConfigFile ().automatic_log_dir ()) {
        logger.setup_temporary_folder_log_dir ();
    }

    logger.on_signal_enter_next_log_file ();

    GLib.info ("##################" + this.theme.app_name ()
                          + "locale:" + QLocale.system ().name ()
                          + "ui_lang:" + property ("ui_lang")
                          + "version:" + this.theme.version ()
                          + "os:" + Utility.platform_name ();
    GLib.info ("Arguments:" + Gtk.Application.arguments ();
}

void Application.on_signal_use_mono_icons_changed (bool) {
    this.gui.on_signal_compute_overall_sync_status ();
}

void Application.on_signal_parse_message (string message, GLib.Object *) {
    if (message.starts_with ("MSG_PARSEOPTIONS:")) {
        const int length_of_msg_prefix = 17;
        string[] options = message.mid (length_of_msg_prefix).split ('|');
        this.show_log_window = false;
        parse_options (options);
        setup_logging ();
        if (this.show_log_window) {
            this.gui.on_signal_toggle_log_browser (); // this.show_log_window is set in parse_options.
        }
        if (this.quit_instance) {
            Gtk.Application.quit ();
        }

    } else if (message.starts_with ("MSG_SHOWMAINDIALOG")) {
        GLib.info ("Running for" + this.started_at.elapsed () / 1000.0 << "sec";
        if (this.started_at.elapsed () < 10 * 1000) {
            // This call is mirrored with the one in int main ()
            GLib.warning ("Ignoring MSG_SHOWMAINDIALOG, possibly double-invocation of client via session restore and var on_signal_start";
            return;
        }

        // Show the main dialog only if there is at least one account configured
        if (!AccountManager.instance ().accounts ().is_empty ()) {
            show_main_dialog ();
        } else {
            this.gui.on_signal_new_account_wizard ();
        }
    }
}

void Application.parse_options (string[] options) {
    QStringListIterator it (options);
    // skip file name;
    if (it.has_next ())
        it.next ();

    //parse options; if help or bad option exit
    while (it.has_next ()) {
        string option = it.next ();
        if (option == "--help" || option == "-h") {
            help ();
            break;
        } else if (option == "--quit" || option == "-q") {
            this.quit_instance = true;
        } else if (option == "--logwindow" || option == "-l") {
            this.show_log_window = true;
        } else if (option == "--logfile") {
            if (it.has_next () && !it.peek_next ().starts_with ("--")) {
                this.log_file = it.next ();
            } else {
                show_hint ("Log file not specified");
            }
        } else if (option == "--logdir") {
            if (it.has_next () && !it.peek_next ().starts_with ("--")) {
                this.log_dir = it.next ();
            } else {
                show_hint ("Log directory not specified");
            }
        } else if (option == "--logexpire") {
            if (it.has_next () && !it.peek_next ().starts_with ("--")) {
                this.log_expire = it.next ().to_int ();
            } else {
                show_hint ("Log expiration not specified");
            }
        } else if (option == "--logflush") {
            this.log_flush = true;
        } else if (option == "--logdebug") {
            this.log_debug = true;
        } else if (option == "--confdir") {
            if (it.has_next () && !it.peek_next ().starts_with ("--")) {
                string conf_dir = it.next ();
                if (!ConfigFile.conf_dir (conf_dir)) {
                    show_hint ("Invalid path passed to --confdir");
                }
            } else {
                show_hint ("Path for confdir not specified");
            }
        } else if (option == "--debug") {
            this.log_debug = true;
            this.debug_mode = true;
        } else if (option == "--background") {
            this.background_mode = true;
        } else if (option == "--version" || option == "-v") {
            this.version_only = true;
        } else if (option.ends_with (APPLICATION_DOTVIRTUALFILE_SUFFIX)) {
            // virtual file, open it after the Folder were created (if the app is not terminated)
            QTimer.single_shot (0, this, [this, option] {
                on_signal_open_virtual_file (option);
            });
        } else {
            show_hint ("Unrecognized option '" + option.to_std_"" + "'");
        }
    }
}

// Helpers for displaying messages. Note that there is no console on Windows.

static void display_help_text (string t) {
    std.cout + q_utf8Printable (t);
}

void Application.show_help () {
    help ();
    string help_text;
    QTextStream stream (&help_text);
    stream +=  this.theme.app_name ()
           + " version "
           + this.theme.version () + endl;

    stream += "File synchronisation desktop utility." + endl
           + endl
           + options_c;

    if (this.theme.app_name () == "own_cloud") {
        stream += endl
               + "For more information, see http://www.owncloud.org" + endl
               + endl;
    }

    display_help_text (help_text);
}

void Application.show_version () {
    display_help_text (Theme.instance ().version_switch_output ());
}

void Application.show_hint (std.string error_hint) {
    static string bin_name = GLib.FileInfo (QCoreApplication.application_file_path ()).filename ();
    std.cerr + error_hint + std.endl;
    std.cerr + "Try '" + bin_name.to_std_"" + " --help' for more information" + std.endl;
    std.exit (1);
}

bool Application.debug_mode () {
    return this.debug_mode;
}

bool Application.background_mode () {
    return this.background_mode;
}

void Application.help () {
    this.help_only = true;
}

string subst_lang (string lang) {
    // Map the more appropriate script codes
    // to country codes as used by Qt and
    // transifex translation conventions.

    // Simplified Chinese
    if (lang == "zh_Hans") {
        return "zh_CN";
    }
    // Traditional Chinese
    if (lang == "zh_Hant") {
        return "zh_TW";
    }
    return lang;
}

void Application.setup_translations () {
    string[] ui_languages;
    ui_languages = QLocale.system ().ui_languages ();

    string enforced_locale = Theme.instance ().enforced_locale ();
    if (!enforced_locale.is_empty ())
        ui_languages.prepend (enforced_locale);

    var translator = new QTranslator (this);
    var qt_translator = new QTranslator (this);
    var qtkeychain_translator = new QTranslator (this);

    for (string lang : q_as_const (ui_languages)) {
        lang.replace ('-', '_'); // work around QTBUG-25973
        lang = subst_lang (lang);
        const string tr_path = application_tr_path ();
        const string tr_file = "client_" + lang;
        if (translator.on_signal_load (tr_file, tr_path) || lang.starts_with ("en")) {
            // Permissive approach : Qt and keychain translations
            // may be missing, but Qt translations must be there in order
            // for us to accept the language. Otherwise, we try with the next.
            // "en" is an exception as it is the default language and may not
            // have a translation file provided.
            GLib.info ("Using" + lang + "translation";
            property ("ui_lang", lang);
            const string qt_tr_path = QLibraryInfo.location (QLibraryInfo.TranslationsPath);
            const string qt_tr_file = "qt_" + lang;
            const string qt_base_tr_file = "qtbase_" + lang;
            if (!qt_translator.on_signal_load (qt_tr_file, qt_tr_path)) {
                if (!qt_translator.on_signal_load (qt_tr_file, tr_path)) {
                    if (!qt_translator.on_signal_load (qt_base_tr_file, qt_tr_path)) {
                        qt_translator.on_signal_load (qt_base_tr_file, tr_path);
                    }
                }
            }
            const string qtkeychain_tr_file = "qtkeychain_" + lang;
            if (!qtkeychain_translator.on_signal_load (qtkeychain_tr_file, qt_tr_path)) {
                qtkeychain_translator.on_signal_load (qtkeychain_tr_file, tr_path);
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
            property ("ui_lang", "C");
    }
}

bool Application.give_help () {
    return this.help_only;
}

bool Application.version_only () {
    return this.version_only;
}

void Application.show_main_dialog () {
    this.gui.on_signal_open_main_dialog ();
}

void Application.on_signal_gui_is_showing_settings () {
    /* emit */ signal_is_showing_settings_dialog ();
}

void Application.on_signal_open_virtual_file (string filename) {
    string virtual_file_ext = APPLICATION_DOTVIRTUALFILE_SUFFIX;
    if (!filename.ends_with (virtual_file_ext)) {
        q_warning ("Can only handle file ending in .owncloud. Unable to open" + filename;
        return;
    }
    var folder = FolderMan.instance ().folder_for_path (filename);
    if (!folder) {
        q_warning ("Can't find sync folder for" + filename;
        // TODO : show a QMessageBox for errors
        return;
    }
    string relative_path = QDir.clean_path (filename).mid (folder.clean_path ().length () + 1);
    folder.on_signal_implicitly_hydrate_file (relative_path);
    string normal_name = filename.left (filename.size () - virtual_file_ext.size ());
    var con = unowned<QMetaObject.Connection>.create ();
    *con = connect (folder, &Folder.signal_sync_finished, folder, [folder, con, normal_name] {
        folder.disconnect (*con);
        if (GLib.File.exists (normal_name)) {
            QDesktopServices.open_url (GLib.Uri.from_local_file (normal_name));
        }
    });
}

void Application.on_signal_try_tray_again () {
    GLib.info ("Trying tray icon, tray available:" + QSystemTrayIcon.is_system_tray_available ();
    this.gui.hide_and_show_tray ();
}

bool Application.event (QEvent event) {
    return SharedTools.QtSingleApplication.event (event);
}

} // namespace Occ
