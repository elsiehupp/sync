/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>
@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <iostream>
//  #include <random>

//  #if defined (BUILD_UPDATER)
//  #endif

//  #if defined (WITH_CRASHREPORTER)
//  #include <libcrashreporter-handler/Handler.h>
//  #endif

//  #include <GLib.Translator>
//  #include <GLib.Menu>
//  #include <Gtk.MessageBox>
//  #include <GLib.DesktopServices>
//  #include <GLib.Application>
//  #include <GLib.Applicat
//  #include <GLib.Pointe
//  #include <GLib.Queue>
//  #include <GLib.Timer>
//  #include <GLib.NetworkConfigurationManager>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Application class
@ingroup gui
***********************************************************/
public class Application : GLib.Application {

    /***********************************************************
    ***********************************************************/
    GLib.List<string> OPTIONS = {
        "Options:\n",
        "  --help, -h           : show this help screen.\n",
        "  --version, -v        : show version information.\n",
        "  -q --quit            : quit the running instance\n",
        "  --logwindow, -l      : open a window to show log output.\n",
        "  --logfile <filename> : write log output to file <filename>.\n",
        "  --logdir <name>      : write each sync log output in a new file\n",
        "                         in folder_connection <name>.\n",
        "  --logexpire <hours>  : removes logs older than <hours> hours.\n",
        "                         (to be used with --logdir)\n",
        "  --logflush           : flush the log file after every write.\n",
        "  --logdebug           : also output debug-level messages in the log.\n",
        "  --confdir <dirname>  : Use the given configuration folder_connection.\n",
        "  --background         : launch the application in the background.\n"
    };

    /***********************************************************
    ***********************************************************/
    OwncloudGui gui { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private Theme theme;

    /***********************************************************
    ***********************************************************/
    private bool help_only;

    /***********************************************************
    ***********************************************************/
    private GLib.Timer started_at;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private bool show_log_window;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private bool quit_instance = false;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private string log_file;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private string log_dir;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private int log_expire;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private bool log_flush;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private bool log_debug;

    /***********************************************************
    Option from command line
    ***********************************************************/
    private bool user_triggered_connect;

    /***********************************************************
    Option from command line
    ***********************************************************/
    bool debug_mode {
        /***********************************************************
        Helper for displaying messages. Note that there is no
        console on Windows.
        ***********************************************************/
        public get;
        private set;
    }

    /***********************************************************
    Option from command line
    ***********************************************************/
    bool background_mode {
        /***********************************************************
        Helper for displaying messages. Note that there is no
        console on Windows.
        ***********************************************************/
        public get;
        private set;
    }

    /***********************************************************
    ***********************************************************/
    private ClientProxy proxy;

    /***********************************************************
    ***********************************************************/
    private GLib.NetworkConfigurationManager network_configuration_manager;

    /***********************************************************
    ***********************************************************/
    private GLib.Timeout check_connection_timer;

    /***********************************************************
    #if defined (WITH_CRASHREPORTER)
    ***********************************************************/
    private CrashReporter.Handler crash_handler;

    /***********************************************************
    ***********************************************************/
    private FolderManager folder_manager;


    internal signal void signal_folder_removed ();
    internal signal void signal_folder_state_changed (FolderConnection folder_connection);
    internal signal void signal_is_showing_settings_dialog ();

    /***********************************************************
    ***********************************************************/
    public Application (int argc, char **argv) {
        base (Theme.app_name, argc, argv);
        this.gui = null;
        this.theme = Theme.instance;
        this.help_only = false;
        this.version_only = false;
        this.show_log_window = false;
        this.log_expire = 0;
        this.log_flush = false;
        this.log_debug = true;
        this.user_triggered_connect = false;
        this.debug_mode = false;
        this.background_mode = false;
        this.started_at.on_signal_start ();

        qsrand (std.random_device () ());

        // TODO: Can't set this without breaking current config paths
        //    organization_name (APPLICATION_VENDOR);
        organization_domain (APPLICATION_REV_DOMAIN);

        // desktop_filename to provide wayland compatibility (in general : conformance with naming standards)
        // but only on Qt >= 5.7, where desktop_filename was introduced
    //  #if (GLib.T_VERSION >= 0x050700)
        string desktop_filename = Common.Config.LINUX_APPLICATION_ID + ".desktop";
        desktop_filename (desktop_filename);
    //  #endif

        application_name (this.theme.app_name);
        window_icon (this.theme.application_icon);

        if (!ConfigFile ().exists ()) {
            // Migrate from version <= 2.4
            application_name (this.theme.app_name_gui);
    //  #ifndef GLib.T_WARNING_DISABLE_DEPRECATED // Was added in Qt 5.9
        //  const int GLib.T_WARNING_DISABLE_DEPRECATED = GLib.T_WARNING_DISABLE_GCC ("-Wdeprecated-declarations")
    //  #endif
            //  GLib.T_WARNING_PUSH
            //  GLib.T_WARNING_DISABLE_DEPRECATED
            // We need to use the deprecated GLib.DesktopServices.storage_location because of its Qt4
            // behavior of adding "data" to the path
            string old_dir = GLib.DesktopServices.storage_location (GLib.DesktopServices.DataLocation);
            if (old_dir.has_suffix ("/")) {
                // macOS 10.11.x does not like trailing slash for rename/move.
                old_dir.chop (1);
            }
            //  GLib.T_WARNING_POP
            application_name (this.theme.app_name);
            if (new GLib.FileInfo (old_dir).is_dir ()) {
                var configuration_directory = ConfigFile ().config_path;
                if (configuration_directory.has_suffix ("/")) {
                    // macOS 10.11.x does not like trailing slash for rename/move.
                    configuration_directory.chop (1);
                }
                GLib.info ("Migrating old config from " + old_dir + " to " + configuration_directory);

                if (!new GLib.File.rename (old_dir, configuration_directory)) {
                    GLib.warning ("Failed to move the old config directory to its new location (" + old_dir + " to " + configuration_directory + ")");

                    // Try to move the files one by one
                    if (new GLib.FileInfo (configuration_directory).is_dir () || new GLib.Dir ().mkdir (configuration_directory)) {
                        GLib.List<string> files_list = new GLib.Dir (old_dir).entry_list (GLib.Dir.Files);
                        GLib.info ("Will move the individual files " + files_list);
                        foreach (var name in files_list) {
                            if (!GLib.File.rename (old_dir + "/" + name, configuration_directory + "/" + name)) {
                                GLib.warning ("Fallback move of " + name + " also failed");
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
            GLib.Timeout.single_shot (0, GLib.Application, GLib.Application.quit);
            return;
        }

        if (is_running ())
            return;

    //  #if defined (WITH_CRASHREPORTER)
        if (ConfigFile ().crash_reporter ()) {
            var reporter = CRASHREPORTER_EXECUTABLE;
            this.crash_handler.on_signal_reset (new CrashReporter.Handler (GLib.Dir.temp_path, true, reporter));
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
        if (Theme.show_virtual_files_option && this.best_available_vfs_mode == AbstractVfs.Off) {
            GLib.warning ("Theme wants to show vfs mode, but no vfs plugins are available.");
        }
        if (is_vfs_plugin_available (AbstractVfs.WindowsCfApi))
            GLib.info ("VFS windows plugin is available");
        if (is_vfs_plugin_available (AbstractVfs.WithSuffix))
            GLib.info ("VFS suffix plugin is available");

        this.folder_manager.on_signal_reset (new FolderManager ());

        this.signal_message_received.connect (
            this.on_signal_parse_message
        );

        if (!AccountManager.instance.restore ()) {
            // If there is an error reading the account settings, try again
            // after a couple of seconds, if that fails, give up.
            // (non-existence is not an error)
            Utility.sleep (5);
            if (!AccountManager.instance.restore ()) {
                GLib.critical ("Could not read the account settings; quitting.");
                Gtk.MessageBox.critical (
                    null,
                    _("Error accessing the configuration file"),
                    _("There was an error while accessing the configuration "
                    "file at %1. Please make sure the file can be accessed by your user.")
                        .printf (ConfigFile ().config_file ()),
                    _("Quit %1").printf (Theme.app_name_gui));
                GLib.Timeout.single_shot (0, GLib.Application, SLOT (quit ()));
                return;
            }
        }

        FolderManager.instance.sync_enabled = true;

        quit_on_signal_last_window_closed (false);

        this.theme.systray_use_mono_icons (config.mono_icons ());
        this.theme.signal_systray_use_mono_icons_changed.connect (
            this.on_signal_use_mono_icons_changed
        );

        // Setting up the gui class will allow tray notifications for the
        // setup that follows, like folder_connection setup
        this.gui = new OwncloudGui (this);
        if (this.show_log_window) {
            this.gui.on_signal_toggle_log_browser (); // this.show_log_window is set in parse_options.
        }
    //  #if WITH_LIBCLOUDPROVIDERS
        this.gui.setup_cloud_providers ();
    //  #endif

        FolderManager.instance.set_up_folders ();
        this.proxy.on_signal_setup_qt_proxy_from_config (); // folders have to be defined first, than we set up the Qt proxy.

        AccountManager.instance.signal_account_added.connect (
            this.on_signal_account_state_added
        );
        AccountManager.instance.signal_account_removed.connect (
            this.on_signal_account_state_removed
        );
        foreach (var account_instance in AccountManager.instance.accounts) {
            on_signal_account_state_added (account_instance);
        }

        FolderManager.instance.socket_api.signal_share_command_received.connect (
            this.gui.on_signal_show_share_dialog
        );

        FolderManager.instance.socket_api.signal_file_activity_command_received.connect (
            Systray.instance.show_file_activity_dialog
        );

        // startup procedure.
        this.check_connection_timer.timeout.connect (
            this.on_signal_check_connection
        );
        this.check_connection_timer.interval (ConnectionValidator.DEFAULT_CALLING_INTERVAL_MILLISECONDS); // check for connection every 32 seconds.
        this.check_connection_timer.on_signal_start ();
        // Also check immediately
        GLib.Timeout.single_shot (0, this, Application.on_signal_check_connection);

        // Can't use online_state_changed because it is always true on modern systems because of many interfaces
        this.network_configuration_manager.configuration_changed.connect (
            this.on_signal_system_online_configuration_changed
        );

    //  #if defined (BUILD_UPDATER)
        // Update checks
        var updater_scheduler = new UpdaterScheduler (this);
        updater_scheduler.signal_updater_announcement.connect (
            this.gui.on_signal_show_tray_message
        );
        updater_scheduler.signal_request_restart.connect (
            this.folder_manager.on_signal_schedule_app_restart
        );
    //  #endif

        // Cleanup at Quit.
        this.about_to_quit.connect (
            this.clean_up
        );

        // Allow other classes to hook into signal_is_showing_settings_dialog () signals (re-auth widgets, for example)
        this.gui.signal_is_showing_settings_dialog.connect (
            this.on_signal_gui_is_showing_settings
        );

        this.gui.create_tray ();
    }


    ~Application () {
        // Make sure all folders are gone, otherwise removing the
        // accounts will remove the associated folders from the settings.
        if (this.folder_manager != null) {
            this.folder_manager.unload_and_delete_all_folders ();
        }

        // Remove the account from the account manager so it can be deleted.
        AccountManager.instance.on_account_removed.disconnect (
            this.on_signal_account_state_removed
        );
        AccountManager.instance.on_signal_shutdown ();
    }


    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    public void show_help () {
        help ();
        string help_text;
        GLib.OutputStream stream = new GLib.OutputStream (help_text);
        stream +=  this.theme.app_name
            " version "
            this.theme.version + endl;

        stream += "File synchronisation desktop utility." + endl
            endl
            OPTIONS;

        if (this.theme.app_name == "own_cloud") {
            stream += endl
                "For more information, see http://www.owncloud.org" + endl
                endl;
        }

        display_help_text (help_text);
    }


    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    public void show_hint (string error_hint) {
        std.cerr += error_hint + std.endl;
        std.cerr += "Try '" + Application.GLib.FileInfo (GLib.Application.application_file_path).filename ().to_std_string () + " --help' for more information" + std.endl;
        std.GLib.Application.quit (1);
    }






    /***********************************************************
    ***********************************************************/
    public bool give_help () {
        return this.help_only;
    }



    /***********************************************************
    Cnly display the version?
    ***********************************************************/
    public bool version_only () {
        return this.version_only;
    }



    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    public void show_version () {
        display_help_text (Theme.version_switch_output);
    }


    /***********************************************************
    ***********************************************************/
    public void show_main_dialog () {
        this.gui.on_signal_open_main_dialog ();
    }




    /***********************************************************
    TODO: this should not be public
    ***********************************************************/
    public void on_signal_owncloud_wizard_done (int res) {
        FolderManager folder_man = FolderManager.instance;

        // During the wizard, scheduling of new syncs is disabled
        folder_man.sync_enabled = true;

        if (res == Gtk.Dialog.Accepted) {
            // Check connectivity of the newly created account
            this.check_connection_timer.on_signal_start ();
            on_signal_check_connection ();

            // If one account is configured : enable autostart
    //  #ifndef GLib.T_DEBUG
            bool should_auto_start = AccountManager.instance.accounts.length () == 1;
    //  #else
            //  bool should_auto_start = false;
    //  #endif
            if (should_auto_start) {
                Utility.launch_on_signal_startup (this.theme.app_name, this.theme.app_name_gui, true);
            }

            Systray.instance.show_window ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_crash () {
        Utility.crash ();
    }


    /***********************************************************
    Will download a virtual file, and open the result.
    The argument is the filename of the virtual file (including
    the extension)
    ***********************************************************/
    public void on_signal_open_virtual_file (string filename) {
        string virtual_file_ext = Common.Config.APPLICATION_DOTVIRTUALFILE_SUFFIX;
        if (!filename.has_suffix (virtual_file_ext)) {
            GLib.warning ("Can only handle file ending in .owncloud. Unable to open " + filename);
            return;
        }
        var folder_connection = FolderManager.instance.folder_for_path (filename);
        if (folder_connection == null) {
            GLib.warning ("Can't find sync folder_connection for " + filename);
            // TODO: show a Gtk.MessageBox for errors
            return;
        }
        string relative_path = GLib.Dir.clean_path (filename).mid (folder_connection.clean_path.length + 1);
        folder_connection.on_signal_implicitly_hydrate_file (relative_path);
        string normal_name = filename.left (filename.length - virtual_file_ext.length);
        GLib.Object.Connection.create () = connect (
            folder_connection,
            FolderConnection.signal_sync_finished, folder_connection,
            this.on_signal_sync_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_finished (FolderConnection folder_connection, GLib.Object con, string normal_name) {
        folder_connection.disconnect (con);
        if (GLib.File.exists (normal_name)) {
            GLib.DesktopServices.open_url (GLib.Uri.from_local_file (normal_name));
        }
    }


    /***********************************************************
    Attempt to show () the tray icon again. Used if no systray
    was available initially.
    ***********************************************************/
    public void on_signal_try_tray_again () {
        GLib.info ("Trying tray icon, tray available: " + GLib.SystemTrayIcon.is_system_tray_available ());
        this.gui.hide_and_show_tray ();
    }


    /***********************************************************
    ***********************************************************/
    protected void parse_options (GLib.List<string> options) {
        GLib.StringListIterator iterator = new GLib.StringListIterator (options);
        // skip file name;
        if (iterator.has_next ()) {
            iterator.next ();
        }

        //parse options; if help or bad option exit
        while (iterator.has_next ()) {
            string option = iterator.next ();
            if (option == "--help" || option == "-h") {
                help ();
                break;
            } else if (option == "--quit" || option == "-q") {
                this.quit_instance = true;
            } else if (option == "--logwindow" || option == "-l") {
                this.show_log_window = true;
            } else if (option == "--logfile") {
                if (iterator.has_next () && !iterator.peek_next ().has_prefix ("--")) {
                    this.log_file = iterator.next ();
                } else {
                    show_hint ("Log file not specified");
                }
            } else if (option == "--logdir") {
                if (iterator.has_next () && !iterator.peek_next ().has_prefix ("--")) {
                    this.log_dir = iterator.next ();
                } else {
                    show_hint ("Log directory not specified");
                }
            } else if (option == "--logexpire") {
                if (iterator.has_next () && !iterator.peek_next ().has_prefix ("--")) {
                    this.log_expire = iterator.next ().to_int ();
                } else {
                    show_hint ("Log expiration not specified");
                }
            } else if (option == "--logflush") {
                this.log_flush = true;
            } else if (option == "--logdebug") {
                this.log_debug = true;
            } else if (option == "--confdir") {
                if (iterator.has_next () && !iterator.peek_next ().has_prefix ("--")) {
                    string configuration_directory = iterator.next ();
                    if (!ConfigFile.configuration_directory (configuration_directory)) {
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
            } else if (option.has_suffix (APPLICATION_DOTVIRTUALFILE_SUFFIX)) {
                // virtual file, open iterator after the FolderConnection were created (if the app is not terminated)
                GLib.Timeout.single_shot (
                    0,
                    this,
                    this.on_signal_open_virtual_file (option)
                );
            } else {
                show_hint ("Unrecognized option '" + option + "'");
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void setup_translations () {
        GLib.List<string> ui_languages;
        ui_languages = GLib.Locale.system ().ui_languages ();

        string enforced_locale = Theme.enforced_locale;
        if (!enforced_locale == "")
            ui_languages.prepend (enforced_locale);

        var translator = new GLib.Translator (this);
        var qt_translator = new GLib.Translator (this);
        var qtkeychain_translator = new GLib.Translator (this);

        foreach (string lang in ui_languages) {
            lang.replace ('-', '_'); // work around GLib.TBUG-25973
            lang = subst_lang (lang);
            string tr_path = application_tr_path;
            string tr_file = "client_" + lang;
            if (translator.on_signal_load (tr_file, tr_path) || lang.has_prefix ("en")) {
                // Permissive approach : Qt and keychain translations
                // may be missing, but Qt translations must be there in order
                // for us to accept the language. Otherwise, we try with the next.
                // "en" is an exception as it is the default language and may not
                // have a translation file provided.
                GLib.info ("Using " + lang + " translation");
                property ("ui_lang", lang);
                string qt_tr_path = GLib.LibraryInfo.location (GLib.LibraryInfo.TranslationsPath);
                string qt_tr_file = "qt_" + lang;
                string qt_base_tr_file = "qtbase_" + lang;
                if (!qt_translator.on_signal_load (qt_tr_file, qt_tr_path)) {
                    if (!qt_translator.on_signal_load (qt_tr_file, tr_path)) {
                        if (!qt_translator.on_signal_load (qt_base_tr_file, qt_tr_path)) {
                            qt_translator.on_signal_load (qt_base_tr_file, tr_path);
                        }
                    }
                }
                string qtkeychain_tr_file = "qtkeychain_" + lang;
                if (!qtkeychain_translator.on_signal_load (qtkeychain_tr_file, qt_tr_path)) {
                    qtkeychain_translator.on_signal_load (qtkeychain_tr_file, tr_path);
                }
                if (!translator == "")
                    install_translator (translator);
                if (!qt_translator == "")
                    install_translator (qt_translator);
                if (!qtkeychain_translator == "")
                    install_translator (qtkeychain_translator);
                break;
            }
            if (property ("ui_lang") == null)
                property ("ui_lang", "C");
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void setup_logging () {
        // might be called from second instance
        var logger = LibSync.Logger.instance;
        logger.log_file (this.log_file);
        if (this.log_file == "") {
            logger.log_dir (this.log_dir == "" ? ConfigFile ().log_dir () : this.log_dir);
        }
        logger.log_expire (this.log_expire > 0 ? this.log_expire : ConfigFile ().log_expire ());
        logger.log_flush (this.log_flush || ConfigFile ().log_flush ());
        logger.log_debug (this.log_debug || ConfigFile ().log_debug ());
        if (!logger.is_logging_to_file () && ConfigFile ().automatic_log_dir ()) {
            logger.setup_temporary_folder_log_dir ();
        }

        logger.on_signal_enter_next_log_file ();

        GLib.info ("##################"
            this.theme.app_name
            "locale:" + GLib.Locale.system ().name ()
            "ui_lang:" + property ("ui_lang")
            "version:" + this.theme.version
            "os:" + Utility.platform_name ()
        );
        GLib.info ("Arguments: " + GLib.Application.arguments ());
    }


    /***********************************************************
    ***********************************************************/
    protected override bool event (Gdk.Event event) {
        return SharedTools.SingleApplication.event (event);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_parse_message (string message, GLib.Object object) {
        if (message.has_prefix ("MSG_PARSEOPTIONS:")) {
            int length_of_msg_prefix = 17;
            GLib.List<string> options = message.mid (length_of_msg_prefix).split ('|');
            this.show_log_window = false;
            parse_options (options);
            setup_logging ();
            if (this.show_log_window) {
                this.gui.on_signal_toggle_log_browser (); // this.show_log_window is set in parse_options.
            }
            if (this.quit_instance) {
                this.quit ();
            }

        } else if (message.has_prefix ("MSG_SHOWMAINDIALOG")) {
            GLib.info ("Running for" + (this.started_at.elapsed () / 1000.0).to_string () + " sec.");
            if (this.started_at.elapsed () < 10 * 1000) {
                // This call is mirrored with the one in int main ()
                GLib.warning ("Ignoring MSG_SHOWMAINDIALOG, possibly double-invocation of client via session restore and var on_signal_start.");
                return;
            }

            // Show the main dialog only if there is at least one account configured
            if (AccountManager.instance.accounts.length () > 0) {
                this.show_main_dialog ();
            } else {
                this.gui.on_signal_new_account_wizard ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_check_connection () {
        foreach (var account_state in AccountManager.instance.accounts) {
            AccountState.State state = account_state.state;

            // Don't check if we're manually signed out or
            // when the error is permanent.
            if (state != AccountState.State.SIGNED_OUT && state != AccountState.State.CONFIGURATION_ERROR
                && state != AccountState.State.ASKING_CREDENTIALS
                && !(
                    account_state.account.push_notifications ()
                    && account_state.account.push_notifications ().is_ready ()
                )) {
                account_state.on_signal_check_connectivity ();
            }
        }

        if (AccountManager.instance.accounts.length () == 0) {
            // let gui open the setup wizard
            this.gui.on_signal_open_settings_dialog ();

            this.check_connection_timer.stop (); // don't popup the wizard on interval;
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_use_mono_icons_changed (bool value) {
        this.gui.on_signal_compute_overall_sync_status ();
    }


    /***********************************************************
    ***********************************************************/
    protected void clean_up () {
        AccountManager.instance.save ();
        FolderManager.instance.unload_and_delete_all_folders ();

        this.gui.on_signal_shutdown ();
        this.gui.delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_account_state_added (AccountState account_state) {
        account_state.signal_state_changed.connect (
            this.gui.on_signal_account_state_changed
        );
        account_state.account.server_version_changed.connect (
            this.gui.on_signal_tray_message_if_server_unsupported
        );
        account_state.signal_state_changed.connect (
            this.folder_manager.on_signal_account_state_changed
        );
        account_state.account.server_version_changed.connect (
            this.folder_manager.on_signal_server_version_changed
        );

        this.gui.on_signal_tray_message_if_server_unsupported (account_state.account);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_account_state_removed (AccountState account_state) {
        if (this.gui != null) {
            disconnect (account_state, AccountState.signal_state_changed,
                this.gui, OwncloudGui.on_signal_account_state_changed);
            disconnect (account_state.account, Account.server_version_changed,
                this.gui, OwncloudGui.on_signal_tray_message_if_server_unsupported);
        }
        if (this.folder_manager != null) {
            account_state.signal_state_changed.disconnect (
                this.folder_manager.on_signal_account_state_changed
            );
            account_state.account.signal_server_version_changed.disconnect (
                this.folder_manager.on_signal_server_version_changed
            );
        }

        // if there is no more account, show the wizard.
        if (this.gui != null && AccountManager.instance.accounts.length () == 0) {
            // allow to add a new account if there is non any more. Always think
            // about single account theming!
            OwncloudSetupWizard.run_wizard (this, SLOT (on_signal_owncloud_wizard_done (int)));
        }
    }


    /***********************************************************
    FIXME: This is not ideal yet since a ConnectionValidator
    might already be running and is in progress of timing out in
    some seconds. Maybe we need 2 validators, one triggered by
    timer, one by network configuration changes?
    ***********************************************************/
    protected void on_signal_system_online_configuration_changed (GLib.NetworkConfiguration cnf) {
        if (cnf.state & GLib.NetworkConfiguration.Active) {
            GLib.Object.invoke_method (this, "on_signal_check_connection", GLib.QueuedConnection);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_gui_is_showing_settings () {
        /* emit */ signal_is_showing_settings_dialog ();
    }


    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    private void help () {
        this.help_only = true;
    }


    /***********************************************************
    Maybe a newer version of the client was used with this
    config file: if so, backup, confirm with user and remove
    the config that can't be read.
    ***********************************************************/
    private bool config_version_migration () {
        GLib.List<string> delete_keys = new GLib.List<string> ();
        GLib.List<string> ignore_keys = new GLib.List<string> ();
        AccountManager.backward_migration_settings_keys (delete_keys, ignore_keys);
        FolderManager.backward_migration_settings_keys (delete_keys, ignore_keys);

        ConfigFile config_file;

        // Did the client version change?
        // (The client version is adjusted further down)
        bool version_changed = config_file.client_version_string != Common.Version.MIRALL_VERSION_STRING;

        // We want to message the user either for destructive changes,
        // or if we're ignoring something and the client version changed.
        bool warning_message = delete_keys != null || (ignore_keys != null && version_changed);

        if (!version_changed && !warning_message)
            return true;

        var backup_file = config_file.create_backup ();

        if (warning_message) {
            string bold_message;
            if (delete_keys != null) {
                bold_message = _("Continuing will mean <b>deleting these settings</b>.");
            } else {
                bold_message = _("Continuing will mean <b>ignoring these settings</b>.");
            }

            Gtk.MessageBox box = new Gtk.MessageBox (
                Gtk.MessageBox.Warning,
                APPLICATION_SHORTNAME,
                _("Some settings were configured in newer versions of this client and "
                "use features that are not available in this version.<br>"
                "<br>"
                "%1<br>"
                "<br>"
                "The current configuration file was already backed up to <i>%2</i>.")
                    .printf (bold_message, backup_file));
            box.add_button (_("Quit"), Gtk.MessageBox.AcceptRole);
            var continue_btn = box.add_button (_("Continue"), Gtk.MessageBox.DestructiveRole);

            box.exec ();
            if (box.clicked_button () != continue_btn) {
                GLib.Timeout.single_shot (0, GLib.Application, SLOT (quit ()));
                return false;
            }

            var settings = ConfigFile.settings_with_group ("foo");
            settings.end_group ();

            // Wipe confusing keys from the future, ignore the others
            foreach (var bad_key in delete_keys)
                settings.remove (bad_key);
        }

        config_file.client_version_string (MIRALL_VERSION_STRING);
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private static string application_tr_path {
        string dev_tr_path = GLib.Application.application_dir_path + "/../src/gui/";
        if (GLib.Dir (dev_tr_path).exists ()) {
            // might miss Qt, QtKeyChain, etc.
            GLib.warning ("Running from build location! Translations may be incomplete!");
            return dev_tr_path;
        }
//  #if defined (Q_OS_UNIX)
        return SHAREDIR + "/" + APPLICATION_EXECUTABLE + "/i18n/";
//  #endif
    }


    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    private static void display_help_text (string t) {
        std.cout += t.to_string ();
    }


    /***********************************************************
    Helper for displaying messages. Note that there is no
    console on Windows.
    ***********************************************************/
    private static string subst_lang (string lang) {
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

} // class Application

} // namespace Ui
} // namespace Occ
