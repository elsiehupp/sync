/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Heule <daniel.heule@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <iostream>
// #include <random>
// #include <qcoreapplication.h>
// #include <QStringList>
// #include <QUrl>
// #include <QFile>
// #include <QFileInfo>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QNetworkProxy>
// #include <qdebug.h>

#include "configfile.h" // ONLY ACCESS THE STATIC FUNCTIONS!
#ifdef TOKEN_AUTH_ONLY
# include "creds/tokencredentials.h"
#else
# include "creds/httpcredentials.h"
#endif

// #include <termios.h>
// #include <unistd.h>

using namespace Occ;

/***********************************************************
@brief Helper class for command line client
@ingroup cmd
***********************************************************/
class Cmd : GLib.Object {

    public Cmd () : GLib.Object () {
    }
public slots:
    void transmission_progress_slot () {
    }
};


static void null_message_handler (QtMsgType, QMessageLogContext &, string &) {
}

struct CmdOptions {
    string source_dir;
    string target_url;
    string remote_path = QStringLiteral ("/");
    string config_directory;
    string user;
    string password;
    string proxy;
    bool silent;
    bool trust_s_sL;
    bool use_netrc;
    bool interactive;
    bool ignore_hidden_files;
    string exclude;
    string unsyncedfolders;
    int restart_times;
    int downlimit;
    int uplimit;
};

// we can't use csync_set_userdata because the SyncEngine sets it already.
// So we have to use a global variable
CmdOptions *opts = nullptr;

class EchoDisabler {

    public EchoDisabler () {
        tcgetattr (STDIN_FILENO, &tios);
        termios tios_new = tios;
        tios_new.c_lflag &= ~ECHO;
        tcsetattr (STDIN_FILENO, TCSANOW, &tios_new);
    }

    public ~EchoDisabler () {
        tcsetattr (STDIN_FILENO, TCSANOW, &tios);
    }

private:
    termios tios;
};

string query_password (string &user) {
    EchoDisabler disabler;
    std.cout << "Password for user " << q_printable (user) << " : ";
    std.string s;
    std.getline (std.cin, s);
    return string.from_std_string (s);
}

#ifndef TOKEN_AUTH_ONLY
class HttpCredentialsText : HttpCredentials {

    public HttpCredentialsText (string &user, string &password)
        : HttpCredentials (user, password)
        , // FIXME : not working with client certs yet (qknight)
        _ssl_trusted (false) {
    }

    public void ask_from_user () override {
        _password = .query_password (user ());
        _ready = true;
        persist ();
        emit asked ();
    }

    public void set_s_sLTrusted (bool is_trusted) {
        _ssl_trusted = is_trusted;
    }

    public bool ssl_is_trusted () override {
        return _ssl_trusted;
    }

private:
    bool _ssl_trusted;
};
#endif /* TOKEN_AUTH_ONLY */

void help () {
    const char *binary_name = APPLICATION_EXECUTABLE "cmd";

    std.cout << binary_name << " - command line " APPLICATION_NAME " client tool" << std.endl;
    std.cout << "" << std.endl;
    std.cout << "Usage : " << binary_name << " [OPTION] <source_dir> <server_url>" << std.endl;
    std.cout << "" << std.endl;
    std.cout << "A proxy can either be set manually using --httpproxy." << std.endl;
    std.cout << "Otherwise, the setting from a configured sync client will be used." << std.endl;
    std.cout << std.endl;
    std.cout << "Options:" << std.endl;
    std.cout << "  --silent, -s           Don't be so verbose" << std.endl;
    std.cout << "  --httpproxy [proxy]    Specify a http proxy to use." << std.endl;
    std.cout << "                         Proxy is http://server:port" << std.endl;
    std.cout << "  --trust                Trust the SSL certification." << std.endl;
    std.cout << "  --exclude [file]       Exclude list file" << std.endl;
    std.cout << "  --unsyncedfolders [file]    File containing the list of unsynced remote folders (selective sync)" << std.endl;
    std.cout << "  --user, -u [name]      Use [name] as the login name" << std.endl;
    std.cout << "  --password, -p [pass]  Use [pass] as password" << std.endl;
    std.cout << "  -n                     Use netrc (5) for login" << std.endl;
    std.cout << "  --non-interactive      Do not block execution with interaction" << std.endl;
    std.cout << "  --max-sync-retries [n] Retries maximum n times (default to 3)" << std.endl;
    std.cout << "  --uplimit [n]          Limit the upload speed of files to n KB/s" << std.endl;
    std.cout << "  --downlimit [n]        Limit the download speed of files to n KB/s" << std.endl;
    std.cout << "  -h                     Sync hidden files, do not ignore them" << std.endl;
    std.cout << "  --version, -v          Display version and exit" << std.endl;
    std.cout << "  --logdebug             More verbose logging" << std.endl;
    std.cout << "  --path                 Path to a folder on a remote server" << std.endl;
    std.cout << "" << std.endl;
    exit (0);
}

void show_version () {
    std.cout << q_utf8Printable (Theme.instance ().version_switch_output ());
    exit (0);
}

void parse_options (QStringList &app_args, CmdOptions *options) {
    QStringList args (app_args);

    int arg_count = args.count ();

    if (arg_count < 3) {
        if (arg_count >= 2) {
            const string option = args.at (1);
            if (option == "-v" || option == "--version") {
                show_version ();
            }
        }
        help ();
    }

    options.target_url = args.take_last ();

    options.source_dir = args.take_last ();
    if (!options.source_dir.ends_with ('/')) {
        options.source_dir.append ('/');
    }
    QFileInfo fi (options.source_dir);
    if (!fi.exists ()) {
        std.cerr << "Source dir '" << q_printable (options.source_dir) << "' does not exist." << std.endl;
        exit (1);
    }
    options.source_dir = fi.absolute_file_path ();

    QStringListIterator it (args);
    // skip file name;
    if (it.has_next ())
        it.next ();

    while (it.has_next ()) {
        const string option = it.next ();

        if (option == "--httpproxy" && !it.peek_next ().starts_with ("-")) {
            options.proxy = it.next ();
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
        } else if ( (option == "-u" || option == "--user") && !it.peek_next ().starts_with ("-")) {
            options.user = it.next ();
        } else if ( (option == "-p" || option == "--password") && !it.peek_next ().starts_with ("-")) {
            options.password = it.next ();
        } else if (option == "--exclude" && !it.peek_next ().starts_with ("-")) {
            options.exclude = it.next ();
        } else if (option == "--unsyncedfolders" && !it.peek_next ().starts_with ("-")) {
            options.unsyncedfolders = it.next ();
        } else if (option == "--max-sync-retries" && !it.peek_next ().starts_with ("-")) {
            options.restart_times = it.next ().to_int ();
        } else if (option == "--uplimit" && !it.peek_next ().starts_with ("-")) {
            options.uplimit = it.next ().to_int () * 1000;
        } else if (option == "--downlimit" && !it.peek_next ().starts_with ("-")) {
            options.downlimit = it.next ().to_int () * 1000;
        } else if (option == "--logdebug") {
            Logger.instance ().set_log_file ("-");
            Logger.instance ().set_log_debug (true);
        } else if (option == "--path" && !it.peek_next ().starts_with ("-")) {
            options.remote_path = it.next ();
        }
        else {
            help ();
        }
    }

    if (options.target_url.is_empty () || options.source_dir.is_empty ()) {
        help ();
    }
}

/* If the selective sync list is different from before, we need to disable the read from db
  (The normal client does it in Selective_sync_dialog.accept*)
***********************************************************/
void selective_sync_fixup (Occ.SyncJournalDb *journal, QStringList &new_list) {
    SqlDatabase db;
    if (!db.open_or_create_read_write (journal.database_file_path ())) {
        return;
    }

    bool ok = false;

    const auto selective_sync_list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
    const QSet<string> old_black_list_set (selective_sync_list.begin (), selective_sync_list.end ());
    if (ok) {
        const QSet<string> black_list_set (new_list.begin (), new_list.end ());
        const auto changes = (old_black_list_set - black_list_set) + (black_list_set - old_black_list_set);
        for (auto &it : changes) {
            journal.schedule_path_for_remote_discovery (it);
        }

        journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, new_list);
    }
}

int main (int argc, char **argv) {
    QCoreApplication app (argc, argv);

    CmdOptions options;
    options.silent = false;
    options.trust_s_sL = false;
    options.use_netrc = false;
    options.interactive = true;
    options.ignore_hidden_files = false; // Default is to sync hidden files
    options.restart_times = 3;
    options.uplimit = 0;
    options.downlimit = 0;

    parse_options (app.arguments (), &options);

    if (options.silent) {
        q_install_message_handler (null_message_handler);
    } else {
        q_set_message_pattern ("%{time MM-dd hh:mm:ss:zzz} [ %{type} %{category} ]%{if-debug}\t[ %{function} ]%{endif}:\t%{message}");
    }

    AccountPtr account = Account.create ();

    if (!account) {
        q_fatal ("Could not initialize account!");
        return EXIT_FAILURE;
    }

    if (options.target_url.contains ("/webdav", Qt.CaseInsensitive) || options.target_url.contains ("/dav", Qt.CaseInsensitive)) {
        q_warning ("Dav or webdav in server URL.");
        std.cerr << "Error! Please specify only the base URL of your host with username and password. Example:" << std.endl
                  << "http (s)://username:password@cloud.example.com" << std.endl;
        return EXIT_FAILURE;
    }

    QUrl host_url = QUrl.from_user_input ( (options.target_url.ends_with (QLatin1Char ('/')) || options.target_url.ends_with (QLatin1Char ('\\'))) ? options.target_url.chopped (1) : options.target_url);

    // Order of retrieval attempt (later attempts override earlier ones):
    // 1. From URL
    // 2. From options
    // 3. From netrc (if enabled)
    // 4. From prompt (if interactive)

    string user = host_url.user_name ();
    string password = host_url.password ();

    if (!options.user.is_empty ()) {
        user = options.user;
    }

    if (!options.password.is_empty ()) {
        password = options.password;
    }

    if (options.use_netrc) {
        NetrcParser parser;
        if (parser.parse ()) {
            NetrcParser.Login_pair pair = parser.find (host_url.host ());
            user = pair.first;
            password = pair.second;
        }
    }

    if (options.interactive) {
        if (user.is_empty ()) {
            std.cout << "Please enter user name : ";
            std.string s;
            std.getline (std.cin, s);
            user = string.from_std_string (s);
        }
        if (password.is_empty ()) {
            password = query_password (user);
        }
    }

    // Find the folder and the original owncloud url

    host_url.set_scheme (host_url.scheme ().replace ("owncloud", "http"));

    QUrl credential_free_url = host_url;
    credential_free_url.set_user_name (string ());
    credential_free_url.set_password (string ());

    const string folder = options.remote_path;

    if (!options.proxy.is_null ()) {
        string host;
        int port = 0;
        bool ok = false;

        QStringList p_list = options.proxy.split (':');
        if (p_list.count () == 3) {
            // http : //192.168.178.23 : 8080
            //  0            1            2
            host = p_list.at (1);
            if (host.starts_with ("//"))
                host.remove (0, 2);

            port = p_list.at (2).to_int (&ok);

            QNetworkProxyFactory.set_use_system_configuration (false);
            QNetworkProxy.set_application_proxy (QNetworkProxy (QNetworkProxy.HttpProxy, host, port));
        } else {
            q_fatal ("Could not read httpproxy. The proxy should have the format \"http://hostname:port\".");
        }
    }

    auto *ssl_error_handler = new Simple_sslErrorHandler;

#ifdef TOKEN_AUTH_ONLY
    auto *cred = new TokenCredentials (user, password, "");
    account.set_credentials (cred);
#else
    auto *cred = new HttpCredentialsText (user, password);
    account.set_credentials (cred);
    if (options.trust_s_sL) {
        cred.set_s_sLTrusted (true);
    }
#endif

    account.set_url (host_url);
    account.set_ssl_error_handler (ssl_error_handler);

    QEventLoop loop;
    auto *job = new JsonApiJob (account, QLatin1String ("ocs/v1.php/cloud/capabilities"));
    GLib.Object.connect (job, &JsonApiJob.json_received, [&] (QJsonDocument &json) {
        auto caps = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
        q_debug () << "Server capabilities" << caps;
        account.set_capabilities (caps.to_variant_map ());
        account.set_server_version (caps["core"].to_object ()["status"].to_object ()["version"].to_string ());
        loop.quit ();
    });
    job.start ();
    loop.exec ();

    if (job.reply ().error () != QNetworkReply.NoError){
        std.cout<<"Error connecting to server\n";
        return EXIT_FAILURE;
    }

    job = new JsonApiJob (account, QLatin1String ("ocs/v1.php/cloud/user"));
    GLib.Object.connect (job, &JsonApiJob.json_received, [&] (QJsonDocument &json) {
        const QJsonObject data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        account.set_dav_user (data.value ("id").to_string ());
        account.set_dav_display_name (data.value ("display-name").to_string ());
        loop.quit ();
    });
    job.start ();
    loop.exec ();

    // much lower age than the default since this utility is usually made to be run right after a change in the tests
    SyncEngine.minimum_file_age_for_upload = std.chrono.milliseconds (0);

    int restart_count = 0;
restart_sync:

    opts = &options;

    QStringList selective_sync_list;
    if (!options.unsyncedfolders.is_empty ()) {
        QFile f (options.unsyncedfolders);
        if (!f.open (QFile.ReadOnly)) {
            q_critical () << "Could not open file containing the list of unsynced folders : " << options.unsyncedfolders;
        } else {
            // filter out empty lines and comments
            selective_sync_list = string.from_utf8 (f.read_all ()).split ('\n').filter (QRegularExpression ("\\S+")).filter (QRegularExpression ("^[^#]"));

            for (int i = 0; i < selective_sync_list.count (); ++i) {
                if (!selective_sync_list.at (i).ends_with (QLatin1Char ('/'))) {
                    selective_sync_list[i].append (QLatin1Char ('/'));
                }
            }
        }
    }

    Cmd cmd;
    string db_path = options.source_dir + SyncJournalDb.make_db_name (options.source_dir, credential_free_url, folder, user);
    SyncJournalDb db (db_path);

    if (!selective_sync_list.empty ()) {
        selective_sync_fixup (&db, selective_sync_list);
    }

    SyncOptions opt;
    opt.fill_from_environment_variables ();
    opt.verify_chunk_sizes ();
    SyncEngine engine (account, options.source_dir, folder, &db);
    engine.set_ignore_hidden_files (options.ignore_hidden_files);
    engine.set_network_limits (options.uplimit, options.downlimit);
    GLib.Object.connect (&engine, &SyncEngine.finished,
        [&app] (bool result) {
            app.exit (result ? EXIT_SUCCESS : EXIT_FAILURE);
        });
    GLib.Object.connect (&engine, &SyncEngine.transmission_progress, &cmd, &Cmd.transmission_progress_slot);
    GLib.Object.connect (&engine, &SyncEngine.sync_error,
        [] (string &error) {
            q_warning () << "Sync error:" << error;
        });

    // Exclude lists

    bool has_user_exclude_file = !options.exclude.is_empty ();
    string system_exclude_file = ConfigFile.exclude_file_from_system ();

    // Always try to load the user-provided exclude list if one is specified
    if (has_user_exclude_file) {
        engine.excluded_files ().add_exclude_file_path (options.exclude);
    }
    // Load the system list if available, or if there's no user-provided list
    if (!has_user_exclude_file || QFile.exists (system_exclude_file)) {
        engine.excluded_files ().add_exclude_file_path (system_exclude_file);
    }

    if (!engine.excluded_files ().reload_exclude_files ()) {
        q_fatal ("Cannot load system exclude list or list supplied via --exclude");
        return EXIT_FAILURE;
    }

    // Have to be done async, else, an error before exec () does not terminate the event loop.
    QMetaObject.invoke_method (&engine, "start_sync", Qt.QueuedConnection);

    int result_code = app.exec ();

    if (engine.is_another_sync_needed () != No_follow_up_sync) {
        if (restart_count < options.restart_times) {
            restart_count++;
            q_debug () << "Restarting Sync, because another sync is needed" << restart_count;
            goto restart_sync;
        }
        q_warning () << "Another sync is needed, but not done because restart count is exceeded" << restart_count;
    }

    return result_code;
}
