/***********************************************************
@author Dominik Schmidt <dev@dominik-schmidt.de>
@author Klaas Freitag <freitag@owncloud.com>
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

//  #include <functional>
//  #include <GLib.BitArray>
//  #include <GLib.Pointer>
//  #include <GLib.JsonDocument
//  #include <GLib.JsonOb
//  #include <memory>

//  #ifndef OWNCLOUD_TEST
//  #endif

//  #include <array>
//  #include <GLib.BitArray>
//  #include <GLib.Meta_method>
//  #include <GLib.Object>
//  #include <GLib.ScopedPointer>
//  #include <GLib.Dir>
//  #include <GLib.Application>
//  #include <GLib.LocalSocket>
//  #include <GLib.String_builder>
//  #include <Gtk.MessageBox>
//  #include <GLib.InputDialog>
//  #include <GLib.FileDialog>
//  #include <GLib.Action>
//  #include <GLib.JsonArray>
//  #include <GLib.JsonDocumen
//  #include <Json.Object>
//  #include <Gtk.Widget>
//  #include <GLib.Clipboar
//  #include <GLib.DesktopServices>

//  #include <GLib.Process>
//  #include <GLib.StandardPaths>

//  #include <GLib.LocalServer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SocketApi class
@ingroup gui
***********************************************************/
public class SocketApi : GLib.Object {

    class SocketApiServer : GLib.LocalServer { }

    /***********************************************************
    ***********************************************************/
    private GLib.List<string> registered_aliases;
    private GLib.HashTable<GLib.IODevice, SocketListener> listeners;
    private SocketApiServer local_server;

    /***********************************************************
    This is the version that is returned when the client asks
    for the VERSION. The first number should be changed if there
    is an incompatible change that breaks old clients. The
    second number should be changed when there are new features.
    ***********************************************************/
    const int MIRALL_SOCKET_API_VERSION = "1.1";

    internal signal void signal_share_command_received (string share_path, string local_path, ShareDialogStartPage start_page);
    internal signal void signal_file_activity_command_received (string share_path, string local_path);

    /***********************************************************
    ***********************************************************/
    public SocketApi (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        string socket_path;

        q_register_meta_type<SocketListener> ("SocketListener*");
        q_register_meta_type<unowned SocketApiJob> ("unowned SocketApiJob");
        q_register_meta_type<unowned SocketApiJobV2> ("unowned SocketApiJobV2");

        if (Utility.is_windows ()) {
            socket_path
                = " (\\.\pipe\)"
                + Common.Config.APPLICATION_EXECUTABLE
                + "-"
                + qgetenv ("USERNAME");
            // TODO: once the windows extension supports multiple
            // client connections, switch back to the theme name
            // See issue #2388
            // + Theme.app_name;
        } else if (Utility.is_mac ()) {
            // This must match the code signing Team setting of the extension
            // Example for developer builds (with ad-hoc signing identity): "" "com.owncloud.desktopclient" ".socket_api"
            // Example for official signed packages: "9B5WD74GWJ." "com.owncloud.desktopclient" ".socket_api"
            socket_path = SOCKETAPI_TEAM_IDENTIFIER_PREFIX + Common.Config.APPLICATION_REV_DOMAIN + ".socket_api";
        } else if (Utility.is_linux () || Utility.is_bsd ()) {
            string runtime_dir;
            runtime_dir = GLib.StandardPaths.writable_location (GLib.StandardPaths.Runtime_location);
            socket_path = runtime_dir + "/" + Theme.app_name + "/socket";
        } else {
            GLib.warning ("An unexpected system detected, so this probably won't work.");
        }

        SocketApiServer.remove_server (socket_path);
        GLib.FileInfo info = new GLib.FileInfo (socket_path);
        if (!info.directory ().exists ()) {
            bool result = info.directory ().mkpath (".");
            GLib.debug ("Creating " + info.directory ().path + result);
            if (result) {
                GLib.File.permissions (socket_path,
                    GLib.File.Permissions (GLib.File.Read_owner + GLib.File.WriteOwner + GLib.File.Exe_owner));
            }
        }
        if (!this.local_server.listen (socket_path)) {
            GLib.warning ("Can't start server " + socket_path);
        } else {
            GLib.info ("Server started, listening at " + socket_path);
        }

        this.local_server.new_connection.connect (
            this.on_signal_new_connection
        );

        // folder_connection watcher
        FolderManager.instance.signal_folder_sync_state_change.connect (
            this.on_signal_update_folder_view
        );
    }


    /***********************************************************
    ***********************************************************/
    ~SocketApi () {
        GLib.debug ("dtor");
        this.local_server.close ();
        // All remaining sockets will be destroyed with this.local_server, their parent
        //  GLib.assert_true (this.listeners == "" || this.listeners.nth_data (0).socket.parent () == this.local_server)
        this.listeners = null;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_folder_view (FolderConnection folder_connection) {
        if (this.listeners == null) {
            return;
        }

        // do only send UPDATE_VIEW for a couple of status
        if (folder_connection.sync_result.status () == SyncResult.Status.SYNC_PREPARE
            || folder_connection.sync_result.status () == SyncResult.Status.SUCCESS
            || folder_connection.sync_result.status () == SyncResult.Status.PAUSED
            || folder_connection.sync_result.status () == SyncResult.Status.PROBLEM
            || folder_connection.sync_result.status () == SyncResult.Status.ERROR
            || folder_connection.sync_result.status () == SyncResult.Status.SETUP_ERROR) {
            string root_path = remove_trailing_slash (folder_connection.path);
            on_signal_broadcast_status_push_message (root_path, folder_connection.sync_engine.sync_file_status_tracker.file_status (""));

            broadcast_message (build_message ("UPDATE_VIEW", root_path));
        } else {
            GLib.debug ("Not sending UPDATE_VIEW for " + folder_connection.alias () + " because status () is " + folder_connection.sync_result.status ());
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_unregister_path (string alias) {
        if (!this.registered_aliases.contains (alias)) {
            return;
        }

        
        try {
            broadcast_message (
                build_message (
                    "UNREGISTER_PATH",
                    remove_trailing_slash (FolderManager.instance.folder_by_alias (alias).path),
                    ""
                ),
                true
            );
        } catch {

        }

        this.registered_aliases.remove (alias);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_register_path (string alias) {
        // Make sure not to register twice to each connected client
        if (this.registered_aliases.contains (alias)) {
            return;
        }

        try {
            string message = build_register_path_message (remove_trailing_slash (FolderManager.instance.folder_by_alias (alias).path));
            foreach (var listener in this.listeners) {
                GLib.info ("Trying to send SocketApi Register Path Message --> " + message + " to " + listener.socket);
                listener.on_signal_send_message (message);
            }
        } catch {

        }

        this.registered_aliases.insert (alias);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_broadcast_status_push_message (string system_path, SyncFileStatus file_status) {
        string message = build_message (
            "STATUS",
            system_path,
            file_status.to_socket_api_string ()
        );
        //  GLib.assert_true (!system_path.has_suffix ("/"));
        uint32 directory_hash = q_hash (system_path.left (system_path.last_index_of ("/")));
        foreach (var listener in this.listeners) {
            listener.send_message_if_directory_monitored (message, directory_hash);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_send_message (string message, bool do_wait) {
        if (!socket) {
            GLib.warning ("Not sending message to dead socket: " + message);
            return;
        }

        GLib.debug ("Sending SocketApi message --> " + message + " to " + socket);
        string local_message = message;
        if (!local_message.has_suffix ("\n")) {
            local_message += "\n";
        }

        string bytes_to_send = local_message.to_utf8 ();
        int64 sent = socket.write (bytes_to_send);
        if (do_wait) {
            socket.wait_for_bytes_written (1000);
        }
        if (sent != bytes_to_send.length) {
            GLib.warning ("Could not send all data on socket for " + local_message);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection () {
        // Note that on macOS this is not actually a line-based GLib.IODevice, it's a SocketApiSocket which is our
        // custom message based macOS IPC.
        GLib.OutputStream socket = this.local_server.next_pending_connection ();

        if (!socket) {
            return;
        }
        GLib.info ("New connection " + socket);
        socket.ready_read.connect (
            this.on_signal_read_socket
        );
        socket.disconnected.connect (
            this.on_signal_lost_connection
        );
        socket.destroyed.connect (
            this.on_signal_socket_destroyed
        );
        //  GLib.assert_true (socket.read_all () == "");

        unowned var listener = SocketListener.create (socket);
        this.listeners.insert (socket, listener);
        foreach (FolderConnection folder_connection in FolderManager.instance.map ()) {
            if (folder_connection.can_sync ()) {
                string message = build_register_path_message (remove_trailing_slash (folder_connection.path));
                GLib.info ("Trying to send SocketApi Register Path Message --> " + message + " to " + listener.socket);
                listener.on_signal_send_message (message);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_lost_connection () {
        GLib.info ("Lost connection " + sender ());
        sender ().delete_later ();

        var socket = (GLib.IODevice) sender ();
        //  GLib.assert_true (socket);
        this.listeners.remove (socket);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_socket_destroyed (GLib.Object object) {
        var socket = (GLib.IODevice)object;
        this.listeners.remove (socket);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_socket () {
        var socket = (GLib.IODevice)sender ();
        //  GLib.assert_true (socket);

        // Find the SocketListener
        //  
        // It's possible for the disconnected () signal to be triggered before
        // the ready_read () signals are received - in that case there won't be a
        // valid listener. We execute the handler anyway, but it will work with
        // a SocketListener that doesn't send any messages.
        unowned SocketListener invalid_listener = SocketListener.create (null);
        var listener = this.listeners.value (socket, invalid_listener);
        while (socket.can_read_line ()) {
            // Make sure to normalize the input from the socket to
            // make sure that the path will match, especially on OS X.
            string line = string.from_utf8 (socket.read_line ().trimmed ()).normalized (string.Normalization_form_C);
            GLib.info ("Received SocketApi message <-- " + line + " from " + socket);
            int arg_pos = line.index_of (':');
            string command = line.mid_ref (0, arg_pos).to_utf8 ().to_upper ();

            var argument = arg_pos != -1 ? line.mid_ref (arg_pos + 1) : /* GLib.StringRef */ new string ();
            if (command.has_prefix ("ASYNC_")) {
                var arguments = argument.split ('|');
                if (arguments.size () != 2) {
                    listener.send_error ("argument count is wrong");
                    return;
                }

                var json = GLib.JsonDocument.from_json (arguments[1].to_utf8 ()).object ();

                var job_id = arguments[0];

                unowned SocketApiJob socket_api_job = new SocketApiJob (job_id.to_string (), listener, json); //, GLib.Object.delete_later);
                if (index_of_method (command) != -1) {
                    static_meta_object.method (index_of_method (command))
                        .invoke (this, GLib.QueuedConnection,
                            Q_ARG (SocketApiJob, socket_api_job));
                } else {
                    GLib.warning (
                        "The command is not supported by this version of the client " + command
                        + " with argument: " + argument);
                    socket_api_job.reject ("command not found");
                }
            } else if (command.has_prefix ("V2/")) {
                Json.ParserError error;
                var json = GLib.JsonDocument.from_json (argument.to_utf8 (), error).object ();
                if (error.error != Json.ParserError.NoError) {
                    GLib.warning ("Invalid json " + argument.to_string () + error.error_string);
                    listener.send_error (error.error_string);
                    return;
                }
                unowned SocketApiJobV2 socket_api_job = SocketApiJobV2.create (listener, command, json);
                if (index_of_method (command) != -1) {
                    static_meta_object.method (index_of_method (command))
                        .invoke (this, GLib.QueuedConnection,
                            Q_ARG (SocketApiJobV2, socket_api_job));
                } else {
                    GLib.warning (
                        "The command is not supported by this version of the client: " + command
                        + " with argument: " + argument);
                    socket_api_job.failure ("command not found");
                }
            } else {
                if (index_of_method (command) != -1) {
                    // to ensure that listener is still valid we need to call it with GLib.Direct_connection
                    //  GLib.assert_true (thread () == GLib.Thread.current_thread ())
                    static_meta_object.method (index_of_method (command))
                        .invoke (this, GLib.Direct_connection, Q_ARG (string, argument.to_string ()),
                            Q_ARG (SocketListener, listener));
                }
            }
        }
    }


    private static int index_of_method (string command) {
        string function_with_arguments = "command_";
        if (command.has_prefix ("ASYNC_")) {
            function_with_arguments += command + " (SocketApiJob)";
        } else if (command.has_prefix ("V2/")) {
            function_with_arguments += "V2_" + command.mid (3) + " (SocketApiJobV2)";
        } else {
            function_with_arguments += command + " (string,SocketListener*)";
        }
        //  GLib.assert_true (static_qt_meta_object.normalized_signature (function_with_arguments) == function_with_arguments);
        var output = static_meta_object.index_of_method (function_with_arguments);
        if (output == -1) {
            listener.send_error ("Function %1 not found".printf (string.from_utf8 (function_with_arguments)));
        }
        //  GLib.assert_true (output != -1)
        return output;
    }


    /***********************************************************
    ***********************************************************/
    private static void copy_url_to_clipboard (string link) {
        GLib.Application.clipboard ().on_signal_text (link);
    }


    /***********************************************************
    ***********************************************************/
    private static void email_private_link (string link) {
        OpenExternal.open_email_composer (
            _("I shared something with you"),
            link,
            null);
    }


    /***********************************************************
    ***********************************************************/
    private static void open_private_link (string link) {
        OpenExternal.open_browser (link);
    }


    private delegate void TargetFunction (string url);
    private static TargetFunction target_function;

    /***********************************************************
    @brief Runs a PROPFIND to figure out the private link url

    The numeric_file_id is used only to build the deprecated_private_link_url
    locally as a fallback. If it's empty an
    will be called with an empty string.

    The job and signal connections are parented to the target
    GLib.Object.

    Note: target_function is guaranteed to be called only
    through the event loop and never directly.
    ***********************************************************/
    private static void fetch_private_link_url (
        unowned Account account,
        string remote_path,
        string numeric_file_id,
        GLib.Object target,
        TargetFunction target_function) {

        SocketApi.target_function = target_function;;
        string old_url;
        if (numeric_file_id != "") {
            old_url = account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);
        }

        // Retrieve the new link by PROPFIND
        var prop_find_job = new PropfindJob (account, remote_path, target);
        prop_find_job.properties (
            new GLib.List<string> ()
            + "http://owncloud.org/ns:fileid" // numeric file identifier for fallback private link generation
            + "http://owncloud.org/ns:privatelink");
        prop_find_job.on_signal_timeout (10 * 1000);
        prop_find_job.result.connect (
            target,
            this.on_signal_prop_find_job_result
        );
        prop_find_job.signal_finished_with_error.connect (
            target,
            this.on_signal_prop_find_job_finished_with_error
        );
        prop_find_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_prop_find_job_result (GLib.VariantMap result) {
        var private_link_url = result["privatelink"].to_string ();
        var numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url == "") {
            SocketApi.target_function (private_link_url);
        } else if (!numeric_file_id == "") {
            SocketApi.target_function (account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded));
        } else {
            SocketApi.target_function (old_url);
        }
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_prop_find_job_finished_with_error (GLib.InputStream reply) {
        SocketApi.target_function (old_url);
    }


    /***********************************************************
    Helper structure for getting information on a file based on
    its local path - used for nearly all remote actions.
    ***********************************************************/
    private struct FileData {
        FolderConnection folder_connection;

        /***********************************************************
        Absolute path of the file locally. (May be a virtual file)
        ***********************************************************/
        string local_path;

        /***********************************************************
        Relative path of the file locally, as in the DB.
        (May be a virtual file)
        ***********************************************************/
        string folder_relative_path;

        /***********************************************************
        Path of the file on the server (In case of virtual file,
        it points to the actual file)
        ***********************************************************/
        string server_relative_path;

        /***********************************************************
        ***********************************************************/
        public static FileData file_data (string local_file) {
            FileData data;

            data.local_path = GLib.Dir.clean_path (local_file);
            if (data.local_path.has_suffix ("/"))
                data.local_path.chop (1);

            data.folder_connection = FolderManager.instance.folder_for_path (data.local_path);
            if (data.folder_connection == null) {
                return data;
            }

            data.folder_relative_path = data.local_path.mid (data.folder_connection.clean_path.length + 1);
            data.server_relative_path = new GLib.Dir (data.folder_connection.remote_path).file_path (data.folder_relative_path);
            string virtual_file_ext = Common.Config.APPLICATION_DOTVIRTUALFILE_SUFFIX;
            if (data.server_relative_path.has_suffix (virtual_file_ext)) {
                data.server_relative_path.chop (virtual_file_ext.size ());
            }
            return data;
        }


        /***********************************************************
        ***********************************************************/
        public SyncFileStatus sync_file_status () {
            if (this.folder_connection == null) {
                return SyncFileStatus.SyncFileStatusTag.STATUS_NONE;
            }
            return folder_connection.sync_engine.sync_file_status_tracker.file_status (folder_relative_path);
        }


        /***********************************************************
        ***********************************************************/
        public SyncJournalFileRecord journal_record () {
            SyncJournalFileRecord record;
            if (this.folder_connection == null) {
                return record;
            }
            folder_connection.journal_database ().file_record (folder_relative_path, record);
            return record;
        }


        /***********************************************************
        ***********************************************************/
        internal FileData parent_folder () {
            return FileData.file_data (new GLib.FileInfo (local_path).directory ().path.to_utf8 ());
        }


        /***********************************************************
        Relative path of the file locally, without any vfs suffix
        ***********************************************************/
        string folder_relative_path_no_vfs_suffix () {
            var result = folder_relative_path;
            string virtual_file_ext = Common.Config.APPLICATION_DOTVIRTUALFILE_SUFFIX;
            if (result.has_suffix (virtual_file_ext)) {
                result.chop (virtual_file_ext.size ());
            }
            return result;
        }

    }


    /***********************************************************
    ***********************************************************/
    private void broadcast_message (string message, bool do_wait = false) {
        foreach (var listener in q_as_const (this.listeners)) {
            listener.on_signal_send_message (message, do_wait);
        }
    }


    /***********************************************************
    Opens share dialog, sends reply
    ***********************************************************/
    private void process_share_request (string local_file, SocketListener listener, ShareDialogStartPage start_page) {
        var theme = Theme.instance;

        var file_data = FileData.file_data (local_file);
        var share_folder = file_data.folder_connection;
        if (share_folder == null) {
            string message = "SHARE:NOP:" + GLib.Dir.to_native_separators (local_file);
            // files that are not within a sync folder_connection are not synced.
            listener.on_signal_send_message (message);
        } else if (!share_folder.account_state.is_connected) {
            string message = "SHARE:NOTCONNECTED:" + GLib.Dir.to_native_separators (local_file);
            // if the folder_connection isn't connected, don't open the share dialog
            listener.on_signal_send_message (message);
        } else if (!theme.link_sharing && (!theme.user_group_sharing || share_folder.account_state.account.server_version_int < Account.make_server_version (8, 2, 0))) {
            string message = "SHARE:NOP:" + GLib.Dir.to_native_separators (local_file);
            listener.on_signal_send_message (message);
        } else {
            // If the file doesn't have a journal record, it might not be uploaded yet
            if (!file_data.journal_record ().is_valid) {
                string message = "SHARE:NOTSYNCED:" + GLib.Dir.to_native_separators (local_file);
                listener.on_signal_send_message (message);
                return;
            }

            var remote_path = file_data.server_relative_path;

            // Can't share root folder_connection
            if (remote_path == "/") {
                string message = "SHARE:CANNOTSHAREROOT:" + GLib.Dir.to_native_separators (local_file);
                listener.on_signal_send_message (message);
                return;
            }

            string message = "SHARE:OK:" + GLib.Dir.to_native_separators (local_file);
            listener.on_signal_send_message (message);

            /* emit */ signal_share_command_received (remote_path, file_data.local_path, start_page);
        }
    }


    /***********************************************************
    Opens share dialog, sends reply
    ***********************************************************/
    private void process_file_activity_request (string local_file) {
        var file_data = FileData.file_data (local_file);
        /* emit */ signal_file_activity_command_received (file_data.server_relative_path, file_data.local_path);
    }



    /***********************************************************
    ***********************************************************/
    private void command_RETRIEVE_FOLDER_STATUS (string argument, SocketListener listener) {
        // This command is the same as RETRIEVE_FILE_STATUS
        command_RETRIEVE_FILE_STATUS (argument, listener);
    }


    /***********************************************************
    ***********************************************************/
    private void command_RETRIEVE_FILE_STATUS (string argument, SocketListener listener) {
        string status_string;

        var file_data = FileData.file_data (argument);
        if (file_data.folder_connection == null) {
            // this can happen in offline mode e.g. : nothing to worry about
            status_string = "NOP";
        } else {
            // The user probably visited this directory in the file shell.
            // Let the listener know that it should now send status pushes for sibblings of this file.
            string directory = file_data.local_path.left (file_data.local_path.last_index_of ("/"));
            listener.register_monitored_directory (q_hash (directory));

            SyncFileStatus file_status = file_data.sync_file_status ();
            status_string = file_status.to_socket_api_string ();
        }

        listener.on_signal_send_message ("STATUS:" + status_string + ':' + GLib.Dir.to_native_separators (argument));
    }


    /***********************************************************
    ***********************************************************/
    private void command_VERSION (string argument, SocketListener listener) {
        listener.on_signal_send_message ("VERSION:" + MIRALL_VERSION_STRING + ":" + MIRALL_SOCKET_API_VERSION);
    }


    /***********************************************************
    ***********************************************************/
    private void command_SHARE_MENU_TITLE (string argument, SocketListener listener) {
        //  listener.on_signal_send_message ("SHARE_MENU_TITLE: " + _("Share with %1", "parameter is Nextcloud").printf (Theme.app_name_gui));
        listener.on_signal_send_message ("SHARE_MENU_TITLE:"  + Theme.app_name_gui);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_ACTIVITY (string local_file, SocketListener listener) {
        //  Q_UNUSED (listener);

        process_file_activity_request (local_file);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_SHARE (string local_file, SocketListener listener) {
        process_share_request (local_file, listener, ShareDialogStartPage.USERS_AND_GROUPS);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_MANAGE_PUBLIC_LINKS (string local_file, SocketListener listener) {
        process_share_request (local_file, listener, ShareDialogStartPage.PUBLIC_LINKS);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_COPY_PUBLIC_LINK (string local_file, SocketListener listener) {
        var file_data = FileData.file_data (local_file);
        if (file_data.folder_connection == null) {
            return;
        }

        unowned Account account = file_data.folder_connection.account_state.account;
        var get_or_create_public_link_share_job = new GetOrCreatePublicLinkShare (account, file_data.server_relative_path, this);
        get_or_create_public_link_share_job.signal_finished.connect (
            this.on_signal_get_or_create_public_link_share_finished
        );
        get_or_create_public_link_share_job.signal_error.connect (
            this.on_signal_get_or_create_public_link_share_error
        );
        get_or_create_public_link_share_job.run ();
    }


    private void on_signal_get_or_create_public_link_share_done (string url) {
        copy_url_to_clipboard (url);
    }


    private void on_signal_get_or_create_public_link_share_error () {
        /* emit */ signal_share_command_received (file_data.server_relative_path, file_data.local_path, ShareDialogStartPage.PUBLIC_LINKS);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_COPY_PRIVATE_LINK (string local_file, SocketListener listener) {
        fetch_private_link_url_helper (local_file, SocketApi.copy_url_to_clipboard);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_EMAIL_PRIVATE_LINK (string local_file, SocketListener listener) {
        fetch_private_link_url_helper (local_file, SocketApi.email_private_link);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_OPEN_PRIVATE_LINK (string local_file, SocketListener listener) {
        fetch_private_link_url_helper (local_file, SocketApi.open_private_link);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_MAKE_AVAILABLE_LOCALLY (string files_arg, SocketListener listener) {
        GLib.List<string> files = split (files_arg);

        foreach (string file in files) {
            var data = FileData.file_data (file);
            if (data.folder_connection == null) {
                continue;
            }

            // Update the pin state on all items
            if (!data.folder_connection.vfs.pin_state (data.folder_relative_path, PinState.PinState.ALWAYS_LOCAL)) {
                GLib.warning ("Could not set pin state of " + data.folder_relative_path + " to always local.");
            }

            // Trigger sync
            data.folder_connection.on_signal_schedule_path_for_local_discovery (data.folder_relative_path);
            data.folder_connection.schedule_this_folder_soon ();
        }
    }


    /***********************************************************
    Context menu action
    Go over all the files and replace them by a virtual file
    ***********************************************************/
    private void command_MAKE_ONLINE_ONLY (string files_arg, SocketListener listener) {
        GLib.List<string> files = split (files_arg);

        foreach (string file in files) {
            var data = FileData.file_data (file);
            if (data.folder_connection == null) {
                continue;
            }

            // Update the pin state on all items
            if (!data.folder_connection.vfs.pin_state (data.folder_relative_path, Common.ItemAvailability.ONLINE_ONLY)) {
                GLib.warning ("Could not set pin state of " + data.folder_relative_path + " to online only.");
            }

            // Trigger sync
            data.folder_connection.on_signal_schedule_path_for_local_discovery (data.folder_relative_path);
            data.folder_connection.schedule_this_folder_soon ();
        }
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_RESOLVE_CONFLICT (string local_file, SocketListener listener) {
        var file_data = FileData.file_data (local_file);
        if (file_data.folder_connection == null || !Utility.is_conflict_file (file_data.folder_relative_path)) {
            return; // should not have shown menu item
        }

        var conflicted_relative_path = file_data.folder_relative_path;
        var base_relative_path = file_data.folder_connection.journal_database ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());

        var directory = new GLib.Dir (file_data.folder_connection.path);
        var conflicted_path = directory.file_path (conflicted_relative_path);
        var base_path = directory.file_path (base_relative_path);

        var base_name = new GLib.FileInfo (base_path).filename ();

    //  #ifndef OWNCLOUD_TEST
        ConflictDialog dialog;
        dialog.on_signal_base_filename (base_name);
        dialog.on_signal_local_version_filename (conflicted_path);
        dialog.on_signal_remote_version_filename (base_path);
        if (dialog.exec () == ConflictDialog.Accepted) {
            file_data.folder_connection.schedule_this_folder_soon ();
        }
    //  #endif
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_DELETE_ITEM (string local_file, SocketListener listener) {
        ConflictSolver solver;
        solver.on_signal_local_version_filename (local_file);
        solver.exec (ConflictSolver.Solution.KEEP_REMOTE_VERSION);
    }


    /***********************************************************
    Context menu action
    ***********************************************************/
    private void command_MOVE_ITEM (string local_file, SocketListener listener) {
        var file_data = FileData.file_data (local_file);
        var parent_dir = file_data.parent_folder ();
        if (file_data.folder_connection == null) {
            return; // should not have shown menu item
        }

        string default_dir_and_name = file_data.folder_relative_path;

        // If it's a conflict, we want to save it under the base name by default
        if (Utility.is_conflict_file (default_dir_and_name)) {
            default_dir_and_name = file_data.folder_connection.journal_database ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());
        }

        // If the parent doesn't accept new files, go to the root of the sync folder_connection
        GLib.FileInfo file_info = new GLib.FileInfo (local_file);
        var parent_record = parent_dir.journal_record ();
        if ((file_info.is_file () && !parent_record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_ADD_FILE))
            || (file_info.is_dir () && !parent_record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES))) {
            default_dir_and_name = new GLib.FileInfo (default_dir_and_name).filename ();
        }

        // Add back the folder_connection path
        default_dir_and_name = new GLib.Dir (file_data.folder_connection.path).file_path (default_dir_and_name);

        var target = GLib.FileDialog.save_filename (
            null,
            _("Select new location …"),
            default_dir_and_name,
            "", null, GLib.FileDialog.Hide_name_filter_details
        );
        if (target == "") {
            return;
        }

        ConflictSolver solver;
        solver.on_signal_local_version_filename (local_file);
        solver.on_signal_remote_version_filename (target);
    }


    /***********************************************************
    External sync
    ***********************************************************/
    private void command_V2_LIST_ACCOUNTS (SocketApiJobV2 socket_api_v2_job) {
        GLib.JsonArray output;
        foreach (var account in AccountManager.instance.accounts) {
            // TODO: Use uuid once https://github.com/owncloud/client/pull/8397 is merged
            output += new Json.Object (
                {
                    {
                        "name",
                        account.account.display_name
                    },
                    {
                        "identifier",
                        account.account.identifier
                    }
                }
            );
        }
        socket_api_v2_job.on_signal_success (
            {
                {
                    "accounts",
                    output
                }
            }
        );
    }


    /***********************************************************
    External sync
    ***********************************************************/
    private void command_V2_UPLOAD_FILES_FROM (SocketApiJobV2 socket_api_v2_job) {
        var upload_job = new SocketUploadJob (socket_api_v2_job);
        upload_job.on_signal_start ();
    }


    delegate void UrlHelper (string url);


    /***********************************************************
    Fetch the private link and call target_fun
    Fetches the private link url asynchronously and then calls the target slot
    ***********************************************************/
    private void fetch_private_link_url_helper (string local_file, UrlHelper target_fun) {
        var file_data = FileData.file_data (local_file);
        if (file_data.folder_connection == null) {
            GLib.warning ("Unknown path " + local_file);
            return;
        }

        var record = file_data.journal_record ();
        if (!record.is_valid) {
            return;
        }

        fetch_private_link_url (
            file_data.folder_connection.account_state.account,
            file_data.server_relative_path,
            record.numeric_file_id (),
            this,
            target_fun);
    }


    /***********************************************************
    Sends translated/branded strings that may be useful to the
    integration
    ***********************************************************/
    private void command_GET_STRINGS (string argument, SocketListener listener) {
        GLib.HashTable<string, string> strings = {
            {
                "SHARE_MENU_TITLE", _("Share options")
            },
            {
                "FILE_ACTIVITY_MENU_TITLE", _("Activity")
            },
            {
                "CONTEXT_MENU_TITLE", Theme.app_name_gui
            },
            {
                "COPY_PRIVATE_LINK_MENU_TITLE", _("Copy private link to clipboard")
            },
            {
                "EMAIL_PRIVATE_LINK_MENU_TITLE", _("Send private link by email …")
            },
            {
                "CONTEXT_MENU_ICON", APPLICATION_ICON_NAME
            },
        };
        listener.on_signal_send_message ("GET_STRINGS:BEGIN");
        foreach (var key_value in strings) {
            if (argument == "" || argument == key_value.first) {
                listener.on_signal_send_message ("STRING:%1:%2".printf (key_value.first, key_value.second));
            }
        }
        listener.on_signal_send_message ("GET_STRINGS:END");
    }


    /***********************************************************
    Sends the context menu options relating to sharing to listener
    ***********************************************************/
    private void send_sharing_context_menu_options (FileData file_data, SocketListener listener, bool enabled) {
        var record = file_data.journal_record ();
        bool is_on_signal_the_server = record.is_valid;
        var flag_string = is_on_signal_the_server && enabled ? "." : ":d:";

        var capabilities = file_data.folder_connection.account_state.account.capabilities;
        var theme = Theme.instance;
        if (!capabilities.share_api () || ! (theme.user_group_sharing || (theme.link_sharing && capabilities.share_public_link ())))
            return;

        // If sharing is globally disabled, do not show any sharing entries.
        // If there is no permission to share for this file, add a disabled entry saying so
        if (is_on_signal_the_server && !record.remote_permissions == null && !record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_RESHARE)) {
            listener.on_signal_send_message ("MENU_ITEM:DISABLED:d:" + (!record.is_directory () ? _("Resharing this file is not allowed") : _("Resharing this folder_connection is not allowed")));
        } else {
            listener.on_signal_send_message ("MENU_ITEM:SHARE" + flag_string + _("Share options"));

            // Do we have public links?
            bool public_links_enabled = theme.link_sharing && capabilities.share_public_link ();

            // Is is possible to create a public link without user choices?
            bool can_create_default_public_link = public_links_enabled
                && !capabilities.share_public_link_enforce_expire_date ()
                && !capabilities.share_public_link_ask_optional_password ()
                && !capabilities.share_public_link_enforce_password ();

            if (can_create_default_public_link) {
                listener.on_signal_send_message ("MENU_ITEM:COPY_PUBLIC_LINK" + flag_string + _("Copy public link"));
            } else if (public_links_enabled) {
                listener.on_signal_send_message ("MENU_ITEM:MANAGE_PUBLIC_LINKS" + flag_string + _("Copy public link"));
            }
        }

        listener.on_signal_send_message ("MENU_ITEM:COPY_PRIVATE_LINK" + flag_string + _("Copy internal link"));

        // Disabled : only providing email option for private links would look odd,
        // and the copy option is more general.
        //  listener.on_signal_send_message ("MENU_ITEM:EMAIL_PRIVATE_LINK" + flag_string + _("Send private link by email …"));
    }


    /***********************************************************
    Send the list of menu item. (added in version 1.1)
    argument is a list of files for which the menu should be
    shown, separated by '\x1e'
    Reply with  GET_MENU_ITEMS:BEGIN
    followed by several MENU_ITEM:[Action]:[flag]:[Text]
    If flag contains 'd', the menu should be disabled
    and ends with GET_MENU_ITEMS:END
    ***********************************************************/
    private void command_GET_MENU_ITEMS (string argument, SocketListener listener) {
        listener.on_signal_send_message ("GET_MENU_ITEMS:BEGIN");
        GLib.List<string> files = split (argument);

        // Find the common sync folder_connection.
        // sync_folder will be null if files are in different folders.
        FolderConnection sync_folder = null;
        foreach (var file in files) {
            var folder_connection = FolderManager.instance.folder_for_path (file);
            if (folder_connection != sync_folder) {
                if (sync_folder == null) {
                    sync_folder = folder_connection;
                } else {
                    sync_folder = null;
                    break;
                }
            }
        }

        // Sharing actions show for single files only
        if (sync_folder != null && files.size () == 1 && sync_folder.account_state.is_connected) {
            string system_path = GLib.Dir.clean_path (argument);
            if (system_path.has_suffix ("/")) {
                system_path.truncate (system_path.length - 1);
            }

            FileData file_data = FileData.file_data (argument);
            var record = file_data.journal_record ();
            bool is_on_signal_the_server = record.is_valid;
            var is_e2e_encrypted_path = file_data.journal_record ().is_e2e_encrypted || !file_data.journal_record ().e2e_mangled_name == "";
            var flag_string = is_on_signal_the_server && !is_e2e_encrypted_path ? "." : ":d:";

            GLib.FileInfo file_info = new GLib.FileInfo (file_data.local_path);
            if (!file_info.is_dir ()) {
                listener.on_signal_send_message ("MENU_ITEM:ACTIVITY" + flag_string + _("Activity"));
            }

            DirectEditor editor = direct_editor_for_local_file (file_data.local_path);
            if (editor) {
                //  listener.on_signal_send_message ("MENU_ITEM:EDIT" + flag_string + _("Edit via ") + editor.name ());
                listener.on_signal_send_message ("MENU_ITEM:EDIT" + flag_string + _("Edit"));
            } else {
                listener.on_signal_send_message ("MENU_ITEM:OPEN_PRIVATE_LINK" + flag_string + _("Open in browser"));
            }

            send_sharing_context_menu_options (file_data, listener, !is_e2e_encrypted_path);

            // Conflict files get conflict resolution actions
            bool is_conflict = Utility.is_conflict_file (file_data.folder_relative_path);
            if (is_conflict || !is_on_signal_the_server) {
                // Check whether this new file is in a read-only directory
                var parent_dir = file_data.parent_folder ();
                var parent_record = parent_dir.journal_record ();
                bool can_add_to_dir =
                    !parent_record.is_valid // We're likely at the root of the sync folder_connection, got to assume we can add there
                    || (file_info.is_file () && parent_record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_ADD_FILE))
                    || (file_info.is_dir () && parent_record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES));
                bool can_change_file =
                    !is_on_signal_the_server
                    || (record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_DELETE)
                        && record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_MOVE)
                        && record.remote_permissions.has_permission (RemotePermissions.Permissions.CAN_RENAME));

                if (is_conflict && can_change_file) {
                    if (can_add_to_dir) {
                        listener.on_signal_send_message ("MENU_ITEM:RESOLVE_CONFLICT." + _("Resolve conflict …"));
                    } else {
                        if (is_on_signal_the_server) {
                            // Uploaded conflict file in read-only directory
                            listener.on_signal_send_message ("MENU_ITEM:MOVE_ITEM." + _("Move and rename …"));
                        } else {
                            // Local-only conflict file in a read-only directory
                            listener.on_signal_send_message ("MENU_ITEM:MOVE_ITEM." + _("Move, rename and upload …"));
                        }
                        listener.on_signal_send_message ("MENU_ITEM:DELETE_ITEM." + _("Delete local changes"));
                    }
                }

                // File in a read-only directory?
                if (!is_conflict && !is_on_signal_the_server && !can_add_to_dir) {
                    listener.on_signal_send_message ("MENU_ITEM:MOVE_ITEM." + _("Move and upload …"));
                    listener.on_signal_send_message ("MENU_ITEM:DELETE_ITEM." + _("Delete"));
                }
            }
        }

        // File availability actions
        if (sync_folder != null
            && sync_folder.virtual_files_enabled
            && sync_folder.vfs.socket_api_pin_state_actions_shown) {
            //  ENFORCE (!files == "");

            // Determine the combined availability status of the files
            var combined = new Optional<Common.ItemAvailability> ();
            foreach (var file in files) {
                var file_data = FileData.file_data (file);
                var availability = sync_folder.vfs.availability (file_data.folder_relative_path);
                if (!availability) {
                    if (availability.error == AbstractVfs.AvailabilityError.DATABASE_ERROR) {
                        availability = Common.ItemAvailability.MIXED;
                    }
                    if (availability.error == AbstractVfs.AvailabilityError.NO_SUCH_ITEM) {
                        continue;
                    }
                }
                if (!combined) {
                    combined = *availability;
                } else {
                    combined = merge (*combined, *availability);
                }
            }

            if (combined) {
                switch (*combined) {
                case Common.ItemAvailability.PinState.ALWAYS_LOCAL:
                    make_pin_context_menu (false, true);
                    break;
                case Common.ItemAvailability.ALL_HYDRATED:
                case Common.ItemAvailability.MIXED:
                    make_pin_context_menu (true, true);
                    break;
                case Common.ItemAvailability.ALL_DEHYDRATED:
                case Common.ItemAvailability.ONLINE_ONLY:
                    make_pin_context_menu (true, false);
                    break;
                }
            }
        }

        listener.on_signal_send_message ("GET_MENU_ITEMS:END");
    }


    /***********************************************************
    ***********************************************************/
    private static void merge (Common.ItemAvailability lhs, Common.ItemAvailability rhs) {
        if (lhs == rhs) {
            return lhs;
        }
        if ((int)lhs > (int)rhs) {
            // reduce cases ensuring lhs < rhs
            Common.ItemAvailability temp = lhs;
            rhs = lhs;
            lhs = temp;
        }
        if (lhs == Common.ItemAvailability.ALWAYS_LOCAL && rhs == Common.ItemAvailability.ALL_HYDRATED) {
            return Common.ItemAvailability.ALL_HYDRATED;
        }
        if (lhs == Common.ItemAvailability.ALL_DEHYDRATED && rhs == Common.ItemAvailability.ONLINE_ONLY) {
            return Common.ItemAvailability.ALL_DEHYDRATED;
        }
        return Common.ItemAvailability.MIXED;
    }


    /***********************************************************
    TODO: Should be a submenu, should use icons
    ***********************************************************/
    private void make_pin_context_menu (bool make_available_locally, bool free_space) {
        listener.on_signal_send_message (
            "MENU_ITEM:CURRENT_PIN:d:"
            + Common.ItemAvailability.to_string (combined));
        if (!Theme.enforce_virtual_files_sync_folder) {
            listener.on_signal_send_message (
                "MENU_ITEM:MAKE_AVAILABLE_LOCALLY:"
                + (make_available_locally ? ":" : "d:")
                + Utility.vfs_pin_action_text ()
            );
        }

        listener.on_signal_send_message ("MENU_ITEM:MAKE_ONLINE_ONLY:"
            + (free_space ? ":" : "d:")
            + Utility.vfs_free_space_action_text ()
        );
    }


    /***********************************************************
    Direct Editing
    ***********************************************************/
    private void command_EDIT (string local_file, SocketListener listener) {
        //  Q_UNUSED (listener)
        var file_data = FileData.file_data (local_file);
        if (file_data.folder_connection == null) {
            GLib.warning ("Unknown path " + local_file);
            return;
        }

        var record = file_data.journal_record ();
        if (!record.is_valid)
            return;

        DirectEditor editor = direct_editor_for_local_file (file_data.local_path);
        if (!editor) {
            return;
        }

        var json_api_job = new LibSync.JsonApiJob (file_data.folder_connection.account_state.account, "ocs/v2.php/apps/files/api/v1/direct_editing/open", this);

        GLib.UrlQuery parameters;
        parameters.add_query_item ("path", file_data.server_relative_path);
        parameters.add_query_item ("editor_id", editor.identifier);
        json_api_job.add_query_params (parameters);
        json_api_job.verb (LibSync.JsonApiJob.Verb.POST);

        json_api_job.signal_json_received.connect (
            this.on_signal_json_received
        );
        json_api_job.on_signal_start ();
    }


    private void on_signal_json_received (GLib.JsonDocument json) {
        var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var url = new GLib.Uri (data.value ("url").to_string ());

        if (!url == "") {
            OpenExternal.open_browser (url);
        }
    }


    /***********************************************************
    Direct Editing
    ***********************************************************/
    private DirectEditor direct_editor_for_local_file (string local_file) {
        FileData file_data = FileData.file_data (local_file);
        var capabilities = file_data.folder_connection.account_state.account.capabilities;

        if (file_data.folder_connection != null && file_data.folder_connection.account_state.is_connected) {
            var record = file_data.journal_record ();
            var mime_match_mode = record.is_virtual_file () ? GLib.MimeDatabase.Match_extension : GLib.MimeDatabase.Match_default;

            GLib.MimeDatabase database;
            GLib.MimeType type = database.mime_type_for_file (local_file, mime_match_mode);

            DirectEditor* editor = capabilities.direct_editor_for_mimetype (type);
            if (!editor) {
                editor = capabilities.direct_editor_for_optional_mimetype (type);
            }
            return editor;
        }

        return null;
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_ASSERT_ICON_IS_EQUAL (SocketApiJob socket_api_job) {
        var widget = find_widget (socket_api_job.arguments ()["query_string"].to_string ());
        if (!widget) {
            string message = "Object not found: 6: %1".printf (socket_api_job.arguments ()["query_string"].to_string ());
            socket_api_job.reject (message);
            return;
        }

        var property_name = socket_api_job.arguments ()["PROPERTY_PATH"].to_string ();

        var segments = property_name.split ('.');

        GLib.Object current_object = widget;
        Gtk.Icon value;
        for (int i = 0; i < segments.length; i++) {
            var segment = segments.at (i);
            var variable = current_object.property (segment.to_utf8 ().const_data ());

            if (variable.can_convert<Gtk.Icon> ()) {
                variable.convert (GLib.MetaType.Gtk.Icon);
                value = variable.value<Gtk.Icon> ();
                break;
            }

            var temporary_object = variable.value<GLib.Object> ();
            if (temporary_object) {
                current_object = temporary_object;
            } else {
                socket_api_job.reject ("Icon not found : %1").printf (property_name);
            }
        }

        var icon_name = socket_api_job.arguments ()["icon_name"].to_string ();
        if (value.name () == icon_name) {
            socket_api_job.resolve ();
        } else {
            socket_api_job.reject ("icon_name " + icon_name + " does not match: " + value.name ());
        }
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_LIST_WIDGETS (SocketApiJob socket_api_job) {
        string response;
        foreach (var widget in all_objects (GLib.Application.all_widgets ())) {
            var object_name = widget.object_name ();
            if (!object_name == "") {
                response += object_name + ":" + widget.property ("text").to_string () + ", ";
            }
        }
        socket_api_job.resolve (response);
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_INVOKE_WIDGET_METHOD (SocketApiJob socket_api_job) {
        var arguments = socket_api_job.arguments ();

        var widget = find_widget (arguments["object_name"].to_string ());
        if (!widget) {
            socket_api_job.reject ("widget not found");
            return;
        }

        GLib.Object.invoke_method (widget, arguments["method"].to_string ().to_utf8 ().const_data ());
        socket_api_job.resolve ();
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_GET_WIDGET_PROPERTY (SocketApiJob socket_api_job) {
        string widget_name = socket_api_job.arguments ()["object_name"].to_string ();
        var widget = find_widget (widget_name);
        if (!widget) {
            string message = "Widget not found : 2 : %1".printf (widget_name);
            socket_api_job.reject (message);
            return;
        }

        var property_name = socket_api_job.arguments ()["property"].to_string ();

        var segments = property_name.split ('.');

        GLib.Object current_object = widget;
        string value;
        for (int i = 0; i < segments.length; i++) {
            var segment = segments.at (i);
            var variable = current_object.property (segment.to_utf8 ().const_data ());

            if (variable.can_convert<string> ()) {
                variable.convert (GLib.MetaType.string);
                value = variable.value<string> ();
                break;
            }

            var temporary_object = variable.value<GLib.Object> ();
            if (temporary_object) {
                current_object = temporary_object;
            } else {
                string message = "Widget not found: 3 : %1".printf (widget_name);
                socket_api_job.reject (message);
                return;
            }
        }

        socket_api_job.resolve (value);
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_SET_WIDGET_PROPERTY (SocketApiJob socket_api_job) {
        var arguments = socket_api_job.arguments ();
        string widget_name = arguments["object_name"].to_string ();
        var widget = find_widget (widget_name);
        if (!widget) {
            string message = "Widget not found: 4: %1".printf (widget_name);
            socket_api_job.reject (message);
            return;
        }
        widget.property (arguments["property"].to_string ().to_utf8 ().const_data (),
            arguments["value"]);

        socket_api_job.resolve ();
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (SocketApiJob socket_api_job) {
        var arguments = socket_api_job.arguments ();
        string widget_name = arguments["object_name"].to_string ();
        var widget = find_widget (arguments["object_name"].to_string ());
        if (!widget) {
            string message = "Widget not found: 5: %1".printf (widget_name);
            socket_api_job.reject (message);
            return;
        }

        ListenerClosure closure = new ListenerClosure (this.listener_closure);

        var signal_signature = arguments["signal_signature"].to_string ();
        signal_signature.prepend ("2");
        var utf8 = signal_signature.to_utf8 ();
        var signal_signature_final = utf8.const_data ();
        widget.signal_signature_final.connect (
            closure.on_signal_closure // GLib.QueuedConnection
        );
    }


    private void listener_closure (SocketApiJob socket_api_job) {
        socket_api_job.resolve ("signal emitted");
    }


    /***********************************************************
    #if GUI_TESTING
    ***********************************************************/
    private void command_ASYNC_TRIGGER_MENU_ACTION (SocketApiJob socket_api_job) {
        var arguments = socket_api_job.arguments ();

        var object_name = arguments["object_name"].to_string ();
        var widget = find_widget (object_name);
        if (!widget) {
            string message = "Object not found: 1: %1".printf (object_name);
            socket_api_job.reject (message);
            return;
        }

        var children = widget.find_children<Gtk.Widget> ();
        foreach (var child_widget in children) {
            // foo is the popupwidget!
            var actions = child_widget.actions ();
            foreach (var action in actions) {
                if (action.object_name () == arguments["action_name"].to_string ()) {
                    action.trigger ();

                    socket_api_job.resolve ("action found");
                    return;
                }
            }
        }

        string message = "Action not found : 1 : %1".printf (arguments["action_name"].to_string ());
        socket_api_job.reject (message);
    }


    /***********************************************************
    ***********************************************************/
    private string build_register_path_message (string path) {
        GLib.FileInfo file_info = new GLib.FileInfo (path);
        string message = "REGISTER_PATH:";
        message += GLib.Dir.to_native_separators (file_info.absolute_file_path);
        return message;
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.List<string> split (string data) {
        string RECORD_SEPARATOR = '\x1e';
        // TODO: string ref?
        return data.split (RECORD_SEPARATOR);
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.List<GLib.Object> all_objects (GLib.List<Gtk.Widget> widgets) {
        GLib.List<GLib.Object> objects;
        std.copy (widgets.const_begin (), widgets.const_end (), std.back_inserter (objects));

        objects += GLib.Application;

        return objects;
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.Object find_widget (string query_string, GLib.List<Gtk.Widget> widgets = GLib.Application.all_widgets ()) {
        if (query_string.contains (">")) {
            GLib.debug ("query_string contains >");

            var sub_queries = query_string.split (">", string.SkipEmptyParts);
            //  GLib.assert_true (sub_queries.length == 2);

            var parent_query_string = sub_queries[0].trimmed ();
            GLib.debug ("Find parent: " + parent_query_string);
            var parent = find_widget (parent_query_string);

            if (!parent) {
                return null;
            }

            var child_query_string = sub_queries[1].trimmed ();
            var child = find_widget (child_query_string, parent.find_children<Gtk.Widget> ());
            GLib.debug ("found child: " + !!child);
            return child;

        } else if (query_string.has_prefix ('#')) {
            var object_name = query_string.mid (1);
            GLib.debug ("find object_name: " + object_name);
            Gtk.Widget found_widget;
            foreach (var widget in widgets) {
                if (widget.object_name () == object_name) {
                    found_widget = widget;
                    break;
                }
            }
        } else {
            GLib.List<GLib.Object> matches = new GLib.List<GLib.Object> ();
            foreach (var widget in widgets) {
                if (widget.inherits (query_string.to_latin1 ())) {
                    matches.append (widget);
                }
            }
            foreach (var match in matches) {
                if (match == null) {
                    return;
                }
                GLib.debug ("WIDGET: " + match.object_name () + match.meta_object ().class_name ());
            }

            if (matches.length () == 0) {
                return null;
            }
            return matches[0];
        }

        if (found_widget == null) {
            return null;
        }

        return found_widget;
    }


    /***********************************************************
    ***********************************************************/
    private static string remove_trailing_slash (string path) {
        //  GLib.assert_true (path.has_suffix ("/"));
        path.truncate (path.length - 1);
        return path;
    }


    /***********************************************************
    ***********************************************************/
    private static string build_message (string verb, string path, string status = "") {
        string message = verb;

        if (status != "") {
            message += ":";
            message += status;
        }
        if (path != "") {
            message += ":";
            GLib.FileInfo file_info = new GLib.FileInfo (path);
            message += GLib.Dir.to_native_separators (file_info.absolute_file_path);
        }
        return message;
    }

} // class SocketApi

} // namespace Ui
} // namespace Occ
