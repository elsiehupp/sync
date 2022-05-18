namespace Occ {
namespace Cmd {

/***********************************************************
@class CommandLine

@brief Helper class for command line client

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Heule <daniel.heule@gmail.com>

@copyright GPLv3 or Later
***********************************************************/
public class CommandLine : GLib.Application {

    private class CmdOptions : GLib.Object {
        public string source_dir;
        public string target_url;
        public string remote_path = "/";
        public string config_directory;
        public string user;
        public string password;
        public string proxy;
        public bool silent;
        public bool trust_s_sL;
        public bool use_netrc;
        public bool interactive;
        public bool ignore_hidden_files;
        public string exclude;
        public string unsynced_folders;
        public int restart_times;
        public int downlimit;
        public int uplimit;
    }

    const string BINARY_NAME = Common.Config.APPLICATION_EXECUTABLE + "cmd";

    /***********************************************************
    We can't use csync_userdata because the LibSync.SyncEngine sets it
    already, so we have to use a global variable.
    ***********************************************************/
    CmdOptions opts;

    /***********************************************************
    private static void null_message_handler (QtMsgType message_type, GLib.MessageLogContext message_context, string message_text) { }
    ***********************************************************/

    /***********************************************************
    ***********************************************************/
    public CommandLine () {
        /***********************************************************
        base ();
        ***********************************************************/
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_transmission_progress () { }


    /***********************************************************
    ***********************************************************/
    private string query_password (string user) {
        EchoDisabler disabler;
        GLib.print ("Password for user " + user + ": ");
        string s;
        Readline.getc (GLib.stdin, s);
        return s;
    }


    /***********************************************************
    ***********************************************************/
    private void help () {

        GLib.print (BINARY_NAME + " - command line " + Common.Config.APPLICATION_NAME + " client tool");
        GLib.print ("");
        GLib.print ("Usage: " + BINARY_NAME + " [OPTION] <source_dir> <server_url>");
        GLib.print ("");
        GLib.print ("A proxy can either be set manually using --httpproxy.");
        GLib.print ("Otherwise, the setting from a configured sync client will be used.");
        GLib.print ("");
        GLib.print ("Options:");
        GLib.print ("  --silent, -s           Don't be so verbose");
        GLib.print ("  --httpproxy [proxy]    Specify a http proxy to use.");
        GLib.print ("                         Proxy is http://server:port");
        GLib.print ("  --trust                Trust the SSL certification.");
        GLib.print ("  --exclude [file]       Exclude list file");
        GLib.print ("  --unsynced_folders [file]    File containing the list of unsynced remote folders (selective sync)");
        GLib.print ("  --user, -u [name]      Use [name] as the login name");
        GLib.print ("  --password, -p [pass]  Use [pass] as password");
        GLib.print ("  -n                     Use netrc (5) for login");
        GLib.print ("  --non-interactive      Do not block execution with interaction");
        GLib.print ("  --max-sync-retries [n] Retries maximum n times (default to 3)");
        GLib.print ("  --uplimit [n]          Limit the upload speed of files to n KB/s");
        GLib.print ("  --downlimit [n]        Limit the download speed of files to n KB/s");
        GLib.print ("  -h                     Sync hidden files, do not ignore them");
        GLib.print ("  --version, -v          Display version and exit");
        GLib.print ("  --logdebug             More verbose logging");
        GLib.print ("  --path                 Path to a folder on a remote server");
        GLib.print ("");
        this.quit ();
    }


    /***********************************************************
    ***********************************************************/
    private void show_version () {
        GLib.print (LibSync.Theme.version_switch_output);
        this.quit ();
    }


    /***********************************************************
    ***********************************************************/
    private void parse_options (GLib.List<string> app_args, CmdOptions options) {
        GLib.List<string> args = app_args;

        int arg_count = (int)args.length ();

        if (arg_count < 3) {
            if (arg_count >= 2) {
                if (args.nth_data (1) == "-v" || args.nth_data (1) == "--version") {
                    show_version ();
                }
            }
            help ();
        }

        options.target_url = args.nth_data (args.length ());
        args.remove (options.target_url);

        options.source_dir = args.nth_data (args.length ());
        args.remove (options.source_dir);
        if (!options.source_dir.has_suffix ("/")) {
            options.source_dir += "/";
        }
        GLib.FileInfo file_info = new GLib.FileInfo (options.source_dir);
        if (!file_info.exists ()) {
            GLib.error ("Source directory '" + options.source_dir + "' does not exist.");
            /***********************************************************
            this.quit (1);
            ***********************************************************/
            this.quit ();
        }
        options.source_dir = file_info.absolute_file_path;

        for (int index = 0; index < args.length (); index ++) {
            /***********************************************************
            Skip file name
            ***********************************************************/
            if (index == 0) {
                continue;
            }

            string option = args.nth_data (index);

            if (option == "--httpproxy" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.proxy = args.nth_data (index + 1);
            } else if (option == "-s" || option == "--silent") {
                options.silent = true;
            } else if (option == "--trust") {
                options.trust_s_sL = true;
            } else if (option == "-n") {
                options.use_netrc = true;
            } else if (option == "-h") {
                options.ignore_hidden_files = false;
            } else if (option == "--non-interactive") {
                options.interactive = false;
            } else if ( (option == "-u" || option == "--user") && !args.nth_data (index + 1).has_prefix ("-")) {
                options.user = args.nth_data (index + 1);
            } else if ( (option == "-p" || option == "--password") && !args.nth_data (index + 1).has_prefix ("-")) {
                options.password = args.nth_data (index + 1);
            } else if (option == "--exclude" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.exclude = args.nth_data (index + 1);
            } else if (option == "--unsynced_folders" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.unsynced_folders = args.nth_data (index + 1);
            } else if (option == "--max-sync-retries" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.restart_times = int.parse (args.nth_data (index + 1));
            } else if (option == "--uplimit" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.uplimit = int.parse (args.nth_data (index + 1)) * 1000;
            } else if (option == "--downlimit" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.downlimit = int.parse (args.nth_data (index + 1)) * 1000;
            } else if (option == "--logdebug") {
                LibSync.Logger.log_file = "-";
                LibSync.Logger.log_debug = true;
            } else if (option == "--path" && !args.nth_data (index + 1).has_prefix ("-")) {
                options.remote_path = args.nth_data (index + 1);
            }
            else {
                help ();
            }
        }

        if (options.target_url == "" || options.source_dir == "") {
            help ();
        }
    }


    /***********************************************************
    If the selective sync list is different from before, we need
    to disable the read from database. (The normal client does
    it in SelectiveSyncDialog.accept).
    ***********************************************************/
    private void selective_sync_fixup (Common.SyncJournalDb journal, GLib.List<string> new_list) {
        Sqlite.Database database;
        if (!database.open_or_create_read_write (journal.database_file_path)) {
            return;
        }

        bool ok = false;

        GLib.List<string> selective_sync_list = journal.get_selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        GLib.List<string> old_block_list_set = new GLib.List<string> ();
        if (ok) {
            GLib.List<string> block_list_set = new GLib.List<string> (new_list.begin (), new_list.end ());
            GLib.List<string> changes = (old_block_list_set - block_list_set) + (block_list_set - old_block_list_set);
            foreach (var change in changes) {
                journal.schedule_path_for_remote_discovery (change);
            }

            journal.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, new_list);
        }
    }


    /***********************************************************
    ***********************************************************/
    private int main (int argc, char **argv) {
        GLib.Application app = new GLib.Application (argc, argv);

        CmdOptions options;
        options.silent = false;
        options.trust_s_sL = false;
        options.use_netrc = false;
        options.interactive = true;
        /***********************************************************
        Default is to sync hidden files
        ***********************************************************/
        options.ignore_hidden_files = false;
        options.restart_times = 3;
        options.uplimit = 0;
        options.downlimit = 0;

        parse_options (app.arguments (), options);

        if (options.silent) {
            q_install_message_handler (null_message_handler);
        } else {
            q_message_pattern ("%{time MM-dd hh:mm:ss:zzz} [ %{type} %{category} ]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}");
        }

        LibSync.Account account = LibSync.Account.create ();

        if (!account) {
            GLib.fatal ("Could not initialize account!");
            return EXIT_FAILURE;
        }

        if (options.target_url.down ().contains ("/webdav") || options.target_url.down ().contains ("/dav")) {
            GLib.warning ("Dav or webdav in server URL.");
            GLib.error ("Error! Please specify only the base URL of your host with username and password. Example:" + std.endl
                    + "http (s)://username:password@cloud.example.com");
            return EXIT_FAILURE;
        }

        GLib.Uri host_url = GLib.Uri.from_user_input ( (options.target_url.has_suffix ("/") || options.target_url.has_suffix ('\\')) ? options.target_url.chopped (1) : options.target_url);

        /***********************************************************
        Order of retrieval attempt (later attempts override earlier
        ones):
    
        1. From URL
        2. From options
        3. From netrc (if enabled)
        4. From prompt (if interactive)
        ***********************************************************/

        string user = host_url.user_name ();
        string password = host_url.password ();

        if (options.user != "") {
            user = options.user;
        }

        if (options.password != "") {
            password = options.password;
        }

        if (options.use_netrc) {
            NetrcParser parser;
            if (parser.parse ()) {
                NetrcParser.GLib.Pair<string, string> pair = parser.find (host_url.host ());
                user = pair.first;
                password = pair.second;
            }
        }

        if (options.interactive) {
            if (user == "") {
                GLib.print ("Please enter user name: ");
                string s;
                Readline.getc (GLib.stdin, s);
                user = string.from_std_string (s);
            }
            if (password == "") {
                password = query_password (user);
            }
        }

        /***********************************************************
        Find the folder and the original owncloud url
        ***********************************************************/

        host_url.scheme (host_url.scheme ().replace ("owncloud", "http"));

        GLib.Uri credential_free_url = host_url;
        credential_free_url.user_name ("");
        credential_free_url.password ("");

        if (options.proxy != null) {
            string host;
            int port = 0;
            bool ok = false;

            GLib.List<string> p_list = options.proxy.split (":");
            if (p_list.length == 3) {
                /***********************************************************
                http://192.168.178.23:8080
                0            1            2
                ***********************************************************/
                host = p_list[1];
                if (host.has_prefix ("//")) {
                    host.remove (0, 2);
                }
                port = p_list[2].to_int (ok);
                Soup.NetworkProxyFactory.use_system_configuration (false);
                Soup.NetworkProxy.application_proxy (Soup.NetworkProxy (Soup.NetworkProxy.HttpProxy, host, port));
            } else {
                GLib.fatal ("Could not read httpproxy. The proxy should have the format \"http://hostname:port\".");
            }
        }

        var ssl_error_handler = new SimpleSslErrorHandler ();

        /***********************************************************
        #ifdef TOKEN_AUTH_ONLY
        ***********************************************************/
        var credentials = new TokenCredentials (user, password, "");
        account.credentials (credentials);
        /***********************************************************
        #else
        var credentials = new HttpCredentialsText (user, password);
        account.credentials (credentials);
        if (options.trust_s_sL) {
            credentials.s_sLTrusted (true);
        }
        #endif
        ***********************************************************/

        account.url (host_url);
        account.ssl_error_handler (ssl_error_handler);

        GLib.MainLoop loop;
        var json_api_job = new LibSync.JsonApiJob (account, "ocs/v1.php/cloud/capabilities");
        json_api_job.signal_json_received.connect (
            this.on_signal_capabilities_json_received
        );
        json_api_job.on_signal_start ();
        loop.exec ();

        if (json_api_job.input_stream.error != GLib.InputStream.NoError) {
            GLib.print ("Error connecting to server");
            return EXIT_FAILURE;
        }

        json_api_job = new LibSync.JsonApiJob (account, "ocs/v1.php/cloud/user");
        json_api_job.signal_json_received.connect (
            this.on_signal_user_json_received
        );
        json_api_job.on_signal_start ();
        loop.exec ();

        /***********************************************************
        Much lower age than the default since this utility is
        usually made to be run right after a change in the tests.
        ***********************************************************/
        LibSync.SyncEngine.minimum_file_age_for_upload = std.chrono.milliseconds (0);

        int restart_count = 0;
    }

    private void restart_sync (CmdOptions options, int restart_count) {

        opts = options;

        GLib.List<string> selective_sync_list;
        if (options.unsynced_folders != "") {
            GLib.File f = new GLib.File (options.unsynced_folders);
            if (!f.open (GLib.File.ReadOnly)) {
                GLib.critical ("Could not open file containing the list of unsynced folders: " + options.unsynced_folders);
            } else {
                /***********************************************************
                Filter out empty lines and comments.
                ***********************************************************/
                selective_sync_list = f.read_all ().split ("\n").filter (GLib.Regex ("\\S+")).filter (GLib.Regex ("^[^#]"));

                foreach (var item in selective_sync_list) {
                    if (!item.has_suffix ("/")) {
                        item += "/";
                    }
                }
            }
        }

        CommandLine cmd;
        string db_path = options.source_dir + Common.SyncJournalDb.make_database_name (options.source_dir, credential_free_url, options.remote_path, user);
        Common.SyncJournalDb database = new Common.SyncJournalDb (db_path);

        if (!selective_sync_list.empty ()) {
            selective_sync_fixup (database, selective_sync_list);
        }

        LibSync.SyncOptions opt;
        opt.fill_from_environment_variables ();
        opt.verify_chunk_sizes ();
        LibSync.SyncEngine sync_engine = new LibSync.SyncEngine (account, options.source_dir, options.remote_path, database);
        sync_engine.ignore_hidden_files (options.ignore_hidden_files);
        sync_engine.network_limits (options.uplimit, options.downlimit);
        sync_engine.signal_finished.connect (
            cmd.on_signal_sync_engine_finished
        );
        sync_engine.signal_transmission_progress.connect (
            cmd.on_signal_transmission_progress
        );
        sync_engine.signal_sync_error.connect (
            cmd.on_signal_sync_error
        );

        /***********************************************************
        Exclude lists
        ***********************************************************/
        bool has_user_exclude_file = options.exclude != "";
        string system_exclude_file = LibSync.ConfigFile.exclude_file_from_system ();

        /***********************************************************
        Always try to load the user-provided exclude list if one is
        specified.
        ***********************************************************/
        if (has_user_exclude_file) {
            sync_engine.excluded_files ().add_exclude_file_path (options.exclude);
        }
        /***********************************************************
        Load the system list if available, or if there's no user-
        provided list.
        ***********************************************************/
        if (!has_user_exclude_file || GLib.File.exists (system_exclude_file)) {
            sync_engine.excluded_files ().add_exclude_file_path (system_exclude_file);
        }

        if (!sync_engine.excluded_files ().on_signal_reload_exclude_files ()) {
            GLib.fatal ("Cannot load system exclude list or list supplied via --exclude");
            return EXIT_FAILURE;
        }

        /***********************************************************
        Have to be done async, else, an error before exec () does
        not terminate the event loop.
        ***********************************************************/
        GLib.Object.invoke_method (sync_engine, "on_signal_start_sync", GLib.QueuedConnection);

        int result_code = app.exec ();

        if (sync_engine.is_another_sync_needed () != AnotherSyncNeeded.NO_FOLLOW_UP_SYNC) {
            if (restart_count < options.restart_times) {
                restart_count++;
                GLib.debug ("Another sync is needed; starting try number " + restart_count.to_string ());
                restart_sync (options, restart_count);
            }
            GLib.warning ("Another sync is needed, but not done because restart count is exceeded " + restart_count.to_string ());
        }

        return result_code;
    }


    private void on_signal_capabilities_json_received (GLib.JsonDocument json) {
        var capabilities = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
        GLib.debug ("Server capabilities: " + capabilities);
        account.capabilities (capabilities.to_variant_map ());
        account.server_version (capabilities["core"].to_object ()["status"].to_object ()["version"].to_string ());
        loop.quit ();
    }


    private void on_signal_user_json_received (GLib.JsonDocument json) {
        Json.Object data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        account.dav_user (data.value ("identifier").to_string ());
        account.dav_display_name (data.value ("display-name").to_string ());
        loop.quit ();
    }


    private static void on_signal_sync_engine_finished (GLib.Application app, bool result) {
        app.this.quit (result ? EXIT_SUCCESS : EXIT_FAILURE);
    }


    private static void on_signal_sync_error (string error) {
        GLib.warning ("Sync error: " + error);
    }

} // class CommandLine

} // namespace Cmd
} // namespace Occ
