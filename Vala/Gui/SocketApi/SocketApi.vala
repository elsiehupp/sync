/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <functional>
//  #include <QBit_array>
//  #include <QPointer>
//  #include <QJsonDocument
//  #include <QJsonOb
//  #include <memory>
//  #include <QTimer>

//  #ifndef OWNCLOUD_TEST
//  #endif

//  #include <array>
//  #include <QBit_array>
//  #include <QMeta_method>
//  #include <QMetaObject>
//  #include <QScopedPointer>
//  #include <QDir>
//  #include <QApplication>
//  #include <QLocal_socket>
//  #include <QString_builder>
//  #include <QMessageBox>
//  #include <QInputDialog>
//  #include <QFileDialog>
//  #include <QAction>
//  #include <QJsonArray>
//  #include <QJsonDocumen
//  #include <QJsonObject>
//  #include <Gtk.Widget>
//  #include <QClipboar
//  #include <QDesktopServices>

//  #include <QProcess>
//  #include <QStandardPaths>

// This is the version that is returned when the client asks for the VERSION.
// The first number should be changed if there is an incompatible change that breaks old clients.
// The second number should be changed when there are new features.
const int MIRALL_SOCKET_API_VERSION "1.1"

#include "sharedialog.h" // for the Share_dialog_start_page

//  #include <QLocal_server>
using Socket_api_server = QLocal_server;

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SocketApi class
@ingroup gui
***********************************************************/
class SocketApi : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public SocketApi (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_signal_unregister_path (string alias)

    /***********************************************************
    ***********************************************************/
    public void on_signal_register_path (string alias);


    public void on_signal_broadcast_status_push_message (string system_path, SyncFileStatus file_status);

signals:
    void share_command_received (string share_path, string local_path, Share_dialog_start_page start_page);
    void file_activity_command_received (string share_path, string local_path);


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection ();
    private void on_signal_lost_connection ();
    private void on_signal_socket_destroyed (GLib.Object obj);
    private void on_signal_read_socket ();

    /***********************************************************
    ***********************************************************/
    static void copy_url_to_clipboard (string link);
    static void email_private_link (string link);
    static void open_private_link (string link);


    // Helper structure for getting information on a file
    // based on its local path - used for nearly all remote
    // actions.
    private struct File_data {
        static File_data get (string local_file);
        SyncFileStatus sync_file_status ();
        SyncJournalFileRecord journal_record ();
        File_data parent_folder ();

        // Relative path of the file locally, without any vfs suffix
        string folder_relative_path_no_vfs_suffix ();

        Folder folder;
        // Absolute path of the file locally. (May be a virtual file)
        string local_path;
        // Relative path of the file locally, as in the DB. (May be a virtual file)
        string folder_relative_path;
        // Path of the file on the server (In case of virtual file, it points to the actual file)
        string server_relative_path;
    }

    /***********************************************************
    ***********************************************************/
    private void broadcast_message (string message, bool do_wait = false);

    // opens share dialog, sends reply
    private void process_share_request (string local_file, Socket_listener listener, Share_dialog_start_page start_page);
    private void process_file_activity_request (string local_file);

    private void command_RETRIEVE_FOLDER_STATUS (string argument, Socket_listener listener);
    private void command_RETRIEVE_FILE_STATUS (string argument, Socket_listener listener);

    private void command_VERSION (string argument, Socket_listener listener);

    private void command_SHARE_MENU_TITLE (string argument, Socket_listener listener);

    // The context menu actions
    private void command_ACTIVITY (string local_file, Socket_listener listener);
    private void command_SHARE (string local_file, Socket_listener listener);
    private void command_MANAGE_PUBLIC_LINKS (string local_file, Socket_listener listener);
    private void command_COPY_PUBLIC_LINK (string local_file, Socket_listener listener);
    private void command_COPY_PRIVATE_LINK (string local_file, Socket_listener listener);
    private void command_EMAIL_PRIVATE_LINK (string local_file, Socket_listener listener);
    private void command_OPEN_PRIVATE_LINK (string local_file, Socket_listener listener);
    private void command_MAKE_AVAILABLE_LOCALLY (string files_arg, Socket_listener listener);
    private void command_MAKE_ONLINE_ONLY (string files_arg, Socket_listener listener);
    private void command_RESOLVE_CONFLICT (string local_file, Socket_listener listener);
    private void command_DELETE_ITEM (string local_file, Socket_listener listener);
    private void command_MOVE_ITEM (string local_file, Socket_listener listener);

    // External sync
    private void command_V2_LIST_ACCOUNTS (unowned<Socket_api_job_v2> job);
    private void command_V2_UPLOAD_FILES_FROM (unowned<Socket_api_job_v2> job);

    // Fetch the private link and call target_fun
    private void fetch_private_link_url_helper (string local_file, std.function<void (string url)> target_fun);


    /***********************************************************
    Sends translated/branded strings that may be useful to the integration
    ***********************************************************/
    private void command_GET_STRINGS (string argument, Socket_listener listener);

    // Sends the context menu options relating to sharing to listener
    private void send_sharing_context_menu_options (File_data file_data, Socket_listener listener, bool enabled);


    /***********************************************************
    Send the list of menu item. (added in version 1.1)
    argument is a list of files for which the menu should be shown, separated by '\x1e'
    Reply with  GET_MENU_ITEMS:BEGIN
    followed by several MENU_ITEM:[Action]:[flag]:[Text]
    If flag contains 'd', the menu should be disabled
    and ends with GET_MENU_ITEMS:END
    ***********************************************************/
    private void command_GET_MENU_ITEMS (string argument, Socket_listener listener);

    /// Direct Editing
    private void command_EDIT (string local_file, Socket_listener listener);
    DirectEditor* get_direct_editor_for_local_file (string local_file);

#if GUI_TESTING
    private void command_ASYNC_ASSERT_ICON_IS_EQUAL (unowned<Socket_api_job> job);
    private void command_ASYNC_LIST_WIDGETS (unowned<Socket_api_job> job);
    private void command_ASYNC_INVOKE_WIDGET_METHOD (unowned<Socket_api_job> job);
    private void command_ASYNC_GET_WIDGET_PROPERTY (unowned<Socket_api_job> job);
    private void command_ASYNC_SET_WIDGET_PROPERTY (unowned<Socket_api_job> job);
    private void command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (unowned<Socket_api_job> job);
    private void command_ASYNC_TRIGGER_MENU_ACTION (unowned<Socket_api_job> job);
//  #endif

    /***********************************************************
    ***********************************************************/
    private string build_register_path_message (string path);

    /***********************************************************
    ***********************************************************/
    private GLib.Set<string> this.registered_aliases;
    private GLib.HashMap<QIODevice *, unowned<Socket_listener>> this.listeners;
    private Socket_api_server this.local_server;
}
}













namespace {

const string RecordSeparator () {
    return '\x1e';
}

string[] split (string data) {
    // TODO : string ref?
    return data.split (RecordSeparator ());
}

#if GUI_TESTING

using namespace Occ;

GLib.List<GLib.Object> all_objects (GLib.List<Gtk.Widget> widgets) {
    GLib.List<GLib.Object> objects;
    std.copy (widgets.const_begin (), widgets.const_end (), std.back_inserter (objects));

    objects + Gtk.Application;

    return objects;
}

GLib.Object find_widget (string query_string, GLib.List<Gtk.Widget> widgets = QApplication.all_widgets ()) {
    var objects = all_objects (widgets);

    GLib.List<GLib.Object>.ConstIterator found_widget;

    if (query_string.contains ('>')) {
        GLib.debug ("query_string contains >";

        var sub_queries = query_string.split ('>', string.SkipEmptyParts);
        //  Q_ASSERT (sub_queries.count () == 2);

        var parent_query_string = sub_queries[0].trimmed ();
        GLib.debug ("Find parent : " + parent_query_string;
        var parent = find_widget (parent_query_string);

        if (!parent) {
            return null;
        }

        var child_query_string = sub_queries[1].trimmed ();
        var child = find_widget (child_query_string, parent.find_children<Gtk.Widget> ());
        GLib.debug ("found child : " + !!child;
        return child;

    } else if (query_string.starts_with ('#')) {
        var object_name = query_string.mid (1);
        GLib.debug ("find object_name : " + object_name;
        found_widget = std.find_if (objects.const_begin (), objects.const_end (), [&] (GLib.Object widget) {
            return widget.object_name () == object_name;
        });
    } else {
        GLib.List<GLib.Object> matches;
        std.copy_if (objects.const_begin (), objects.const_end (), std.back_inserter (matches), [&] (GLib.Object widget) {
            return widget.inherits (query_string.to_latin1 ());
        });

        std.for_each (matches.const_begin (), matches.const_end (), [] (GLib.Object w) {
            if (!w)
                return;
            GLib.debug ("WIDGET : " + w.object_name () + w.meta_object ().class_name ();
        });

        if (matches.empty ()) {
            return null;
        }
        return matches[0];
    }

    if (found_widget == objects.const_end ()) {
        return null;
    }

    return found_widget;
}
//  #endif

static inline string remove_trailing_slash (string path) {
    //  Q_ASSERT (path.ends_with ('/'));
    path.truncate (path.length () - 1);
    return path;
}

static string build_message (string verb, string path, string status = "") {
    string message (verb);

    if (!status.is_empty ()) {
        message.append (':');
        message.append (status);
    }
    if (!path.is_empty ()) {
        message.append (':');
        GLib.FileInfo fi (path);
        message.append (QDir.to_native_separators (fi.absolute_file_path ()));
    }
    return message;
}

void Socket_listener.on_signal_send_message (string message, bool do_wait) {
    if (!socket) {
        GLib.warning ("Not sending message to dead socket:" + message;
        return;
    }

    GLib.debug ("Sending SocketApi message -." + message + "to" + socket;
    string local_message = message;
    if (!local_message.ends_with ('\n')) {
        local_message.append ('\n');
    }

    GLib.ByteArray bytes_to_send = local_message.to_utf8 ();
    int64 sent = socket.write (bytes_to_send);
    if (do_wait) {
        socket.wait_for_bytes_written (1000);
    }
    if (sent != bytes_to_send.length ()) {
        GLib.warning ("Could not send all data on socket for " + local_message;
    }
}

SocketApi.SocketApi (GLib.Object parent) {
    base (parent);
    string socket_path;

    q_register_meta_type<Socket_listener> ("Socket_listener*");
    q_register_meta_type<unowned<Socket_api_job>> ("unowned<Socket_api_job>");
    q_register_meta_type<unowned<Socket_api_job_v2>> ("unowned<Socket_api_job_v2>");

    if (Utility.is_windows ()) {
        socket_path = QLatin1String (R" (\\.\pipe\)")
            + QLatin1String (APPLICATION_EXECUTABLE)
            + QLatin1String ("-")
            + string.from_local8Bit (qgetenv ("USERNAME"));
        // TODO : once the windows extension supports multiple
        // client connections, switch back to the theme name
        // See issue #2388
        // + Theme.instance ().app_name ();
    } else if (Utility.is_mac ()) {
        // This must match the code signing Team setting of the extension
        // Example for developer builds (with ad-hoc signing identity) : "" "com.owncloud.desktopclient" ".socket_api"
        // Example for official signed packages : "9B5WD74GWJ." "com.owncloud.desktopclient" ".socket_api"
        socket_path = SOCKETAPI_TEAM_IDENTIFIER_PREFIX APPLICATION_REV_DOMAIN ".socket_api";
    } else if (Utility.is_linux () || Utility.is_bsd ()) {
        string runtime_dir;
        runtime_dir = QStandardPaths.writable_location (QStandardPaths.Runtime_location);
        socket_path = runtime_dir + "/" + Theme.instance ().app_name () + "/socket";
    } else {
        GLib.warning ("An unexpected system detected, this probably won't work.";
    }

    Socket_api_server.remove_server (socket_path);
    GLib.FileInfo info (socket_path);
    if (!info.dir ().exists ()) {
        bool result = info.dir ().mkpath (".");
        GLib.debug ("creating" + info.dir ().path () + result;
        if (result) {
            GLib.File.permissions (socket_path,
                GLib.File.Permissions (GLib.File.Read_owner + GLib.File.WriteOwner + GLib.File.Exe_owner));
        }
    }
    if (!this.local_server.listen (socket_path)) {
        GLib.warning ("can't on_signal_start server" + socket_path;
    } else {
        GLib.info ("server started, listening at " + socket_path;
    }

    connect (&this.local_server, &Socket_api_server.new_connection, this, &SocketApi.on_signal_new_connection);

    // folder watcher
    connect (FolderMan.instance (), &FolderMan.folder_sync_state_change, this, &SocketApi.on_signal_update_folder_view);
}

SocketApi.~SocketApi () {
    GLib.debug ("dtor";
    this.local_server.close ();
    // All remaining sockets will be destroyed with this.local_server, their parent
    //  ASSERT (this.listeners.is_empty () || this.listeners.first ().socket.parent () == this.local_server)
    this.listeners.clear ();
}

void SocketApi.on_signal_new_connection () {
    // Note that on macOS this is not actually a line-based QIODevice, it's a Socket_api_socket which is our
    // custom message based macOS IPC.
    QIODevice socket = this.local_server.next_pending_connection ();

    if (!socket) {
        return;
    }
    GLib.info ("New connection" + socket;
    connect (socket, &QIODevice.ready_read, this, &SocketApi.on_signal_read_socket);
    connect (socket, SIGNAL (disconnected ()), this, SLOT (on_signal_lost_connection ()));
    connect (socket, &GLib.Object.destroyed, this, &SocketApi.on_signal_socket_destroyed);
    //  ASSERT (socket.read_all ().is_empty ());

    var listener = unowned<Socket_listener>.create (socket);
    this.listeners.insert (socket, listener);
    for (Folder f : FolderMan.instance ().map ()) {
        if (f.can_sync ()) {
            string message = build_register_path_message (remove_trailing_slash (f.path ()));
            GLib.info ("Trying to send SocketApi Register Path Message -." + message + "to" + listener.socket;
            listener.on_signal_send_message (message);
        }
    }
}

void SocketApi.on_signal_lost_connection () {
    GLib.info ("Lost connection " + sender ();
    sender ().delete_later ();

    var socket = qobject_cast<QIODevice> (sender ());
    //  ASSERT (socket);
    this.listeners.remove (socket);
}

void SocketApi.on_signal_socket_destroyed (GLib.Object obj) {
    var socket = static_cast<QIODevice> (obj);
    this.listeners.remove (socket);
}

void SocketApi.on_signal_read_socket () {
    var socket = qobject_cast<QIODevice> (sender ());
    //  ASSERT (socket);

    // Find the Socket_listener
    //
    // It's possible for the disconnected () signal to be triggered before
    // the ready_read () signals are received - in that case there won't be a
    // valid listener. We execute the handler anyway, but it will work with
    // a Socket_listener that doesn't send any messages.
    static var invalid_listener = unowned<Socket_listener>.create (null);
    const var listener = this.listeners.value (socket, invalid_listener);
    while (socket.can_read_line ()) {
        // Make sure to normalize the input from the socket to
        // make sure that the path will match, especially on OS X.
        const string line = string.from_utf8 (socket.read_line ().trimmed ()).normalized (string.Normalization_form_C);
        GLib.info ("Received SocketApi message <--" + line + "from" + socket;
        const int arg_pos = line.index_of (':');
        const GLib.ByteArray command = line.mid_ref (0, arg_pos).to_utf8 ().to_upper ();
        const int index_of_method = [&] {
            GLib.ByteArray function_with_arguments = QByteArrayLiteral ("command_");
            if (command.starts_with ("ASYNC_")) {
                function_with_arguments += command + QByteArrayLiteral (" (unowned<Socket_api_job>)");
            } else if (command.starts_with ("V2/")) {
                function_with_arguments += QByteArrayLiteral ("V2_") + command.mid (3) + QByteArrayLiteral (" (unowned<Socket_api_job_v2>)");
            } else {
                function_with_arguments += command + QByteArrayLiteral (" (string,Socket_listener*)");
            }
            //  Q_ASSERT (static_qt_meta_object.normalized_signature (function_with_arguments) == function_with_arguments);
            const var out = static_meta_object.index_of_method (function_with_arguments);
            if (out == -1) {
                listener.send_error (QStringLiteral ("Function %1 not found").arg (string.from_utf8 (function_with_arguments)));
            }
            //  ASSERT (out != -1)
            return out;
        } ();

        const var argument = arg_pos != -1 ? line.mid_ref (arg_pos + 1) : QStringRef ();
        if (command.starts_with ("ASYNC_")) {
            var arguments = argument.split ('|');
            if (arguments.size () != 2) {
                listener.send_error (QStringLiteral ("argument count is wrong"));
                return;
            }

            var json = QJsonDocument.from_json (arguments[1].to_utf8 ()).object ();

            var job_id = arguments[0];

            var socket_api_job = unowned<Socket_api_job> (
                new Socket_api_job (job_id.to_string (), listener, json), &GLib.Object.delete_later);
            if (index_of_method != -1) {
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (unowned<Socket_api_job>, socket_api_job));
            } else {
                GLib.warning ("The command is not supported by this version of the client:" + command
                                       + "with argument:" + argument;
                socket_api_job.reject (QStringLiteral ("command not found"));
            }
        } else if (command.starts_with ("V2/")) {
            QJsonParseError error;
            const var json = QJsonDocument.from_json (argument.to_utf8 (), error).object ();
            if (error.error != QJsonParseError.NoError) {
                GLib.warning ()) + "Invalid json" + argument.to_string () + error.error_string ();
                listener.send_error (error.error_string ());
                return;
            }
            var socket_api_job = unowned<Socket_api_job_v2>.create (listener, command, json);
            if (index_of_method != -1) {
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (unowned<Socket_api_job_v2>, socket_api_job));
            } else {
                GLib.warning ("The command is not supported by this version of the client:" + command
                                       + "with argument:" + argument;
                socket_api_job.failure (QStringLiteral ("command not found"));
            }
        } else {
            if (index_of_method != -1) {
                // to ensure that listener is still valid we need to call it with Qt.Direct_connection
                //  ASSERT (thread () == QThread.current_thread ())
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.Direct_connection, Q_ARG (string, argument.to_string ()),
                        Q_ARG (Socket_listener *, listener.data ()));
            }
        }
    }
}

void SocketApi.on_signal_register_path (string alias) {
    // Make sure not to register twice to each connected client
    if (this.registered_aliases.contains (alias))
        return;

    Folder f = FolderMan.instance ().folder (alias);
    if (f) {
        const string message = build_register_path_message (remove_trailing_slash (f.path ()));
        for (var listener : q_as_const (this.listeners)) {
            GLib.info ("Trying to send SocketApi Register Path Message -." + message + "to" + listener.socket;
            listener.on_signal_send_message (message);
        }
    }

    this.registered_aliases.insert (alias);
}

void SocketApi.on_signal_unregister_path (string alias) {
    if (!this.registered_aliases.contains (alias))
        return;

    Folder f = FolderMan.instance ().folder (alias);
    if (f)
        broadcast_message (build_message (QLatin1String ("UNREGISTER_PATH"), remove_trailing_slash (f.path ()), ""), true);

    this.registered_aliases.remove (alias);
}

void SocketApi.on_signal_update_folder_view (Folder f) {
    if (this.listeners.is_empty ()) {
        return;
    }

    if (f) {
        // do only send UPDATE_VIEW for a couple of status
        if (f.sync_result ().status () == SyncResult.Status.SYNC_PREPARE
            || f.sync_result ().status () == SyncResult.Status.SUCCESS
            || f.sync_result ().status () == SyncResult.Status.PAUSED
            || f.sync_result ().status () == SyncResult.Status.PROBLEM
            || f.sync_result ().status () == SyncResult.Status.ERROR
            || f.sync_result ().status () == SyncResult.Status.SETUP_ERROR) {
            string root_path = remove_trailing_slash (f.path ());
            on_signal_broadcast_status_push_message (root_path, f.sync_engine ().sync_file_status_tracker ().file_status (""));

            broadcast_message (build_message (QLatin1String ("UPDATE_VIEW"), root_path));
        } else {
            GLib.debug ("Not sending UPDATE_VIEW for" + f.alias ("because status () is" + f.sync_result ().status ();
        }
    }
}

void SocketApi.broadcast_message (string message, bool do_wait) {
    for (var listener : q_as_const (this.listeners)) {
        listener.on_signal_send_message (message, do_wait);
    }
}

void SocketApi.process_file_activity_request (string local_file) {
    const var file_data = File_data.get (local_file);
    /* emit */ file_activity_command_received (file_data.server_relative_path, file_data.local_path);
}

void SocketApi.process_share_request (string local_file, Socket_listener listener, Share_dialog_start_page start_page) {
    var theme = Theme.instance ();

    var file_data = File_data.get (local_file);
    var share_folder = file_data.folder;
    if (!share_folder) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.to_native_separators (local_file);
        // files that are not within a sync folder are not synced.
        listener.on_signal_send_message (message);
    } else if (!share_folder.account_state ().is_connected ()) {
        const string message = QLatin1String ("SHARE:NOTCONNECTED:") + QDir.to_native_separators (local_file);
        // if the folder isn't connected, don't open the share dialog
        listener.on_signal_send_message (message);
    } else if (!theme.link_sharing () && (!theme.user_group_sharing () || share_folder.account_state ().account ().server_version_int () < Account.make_server_version (8, 2, 0))) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.to_native_separators (local_file);
        listener.on_signal_send_message (message);
    } else {
        // If the file doesn't have a journal record, it might not be uploaded yet
        if (!file_data.journal_record ().is_valid ()) {
            const string message = QLatin1String ("SHARE:NOTSYNCED:") + QDir.to_native_separators (local_file);
            listener.on_signal_send_message (message);
            return;
        }

        var remote_path = file_data.server_relative_path;

        // Can't share root folder
        if (remote_path == "/") {
            const string message = QLatin1String ("SHARE:CANNOTSHAREROOT:") + QDir.to_native_separators (local_file);
            listener.on_signal_send_message (message);
            return;
        }

        const string message = QLatin1String ("SHARE:OK:") + QDir.to_native_separators (local_file);
        listener.on_signal_send_message (message);

        /* emit */ share_command_received (remote_path, file_data.local_path, start_page);
    }
}

void SocketApi.on_signal_broadcast_status_push_message (string system_path, SyncFileStatus file_status) {
    string message = build_message (QLatin1String ("STATUS"), system_path, file_status.to_socket_api_string ());
    //  Q_ASSERT (!system_path.ends_with ('/'));
    uint32 directory_hash = q_hash (system_path.left (system_path.last_index_of ('/')));
    for (var listener : q_as_const (this.listeners)) {
        listener.send_message_if_directory_monitored (message, directory_hash);
    }
}

void SocketApi.command_RETRIEVE_FOLDER_STATUS (string argument, Socket_listener listener) {
    // This command is the same as RETRIEVE_FILE_STATUS
    command_RETRIEVE_FILE_STATUS (argument, listener);
}

void SocketApi.command_RETRIEVE_FILE_STATUS (string argument, Socket_listener listener) {
    string status_string;

    var file_data = File_data.get (argument);
    if (!file_data.folder) {
        // this can happen in offline mode e.g. : nothing to worry about
        status_string = QLatin1String ("NOP");
    } else {
        // The user probably visited this directory in the file shell.
        // Let the listener know that it should now send status pushes for sibblings of this file.
        string directory = file_data.local_path.left (file_data.local_path.last_index_of ('/'));
        listener.register_monitored_directory (q_hash (directory));

        SyncFileStatus file_status = file_data.sync_file_status ();
        status_string = file_status.to_socket_api_string ();
    }

    const string message = QLatin1String ("STATUS:") % status_string % ':' % QDir.to_native_separators (argument);
    listener.on_signal_send_message (message);
}

void SocketApi.command_SHARE (string local_file, Socket_listener listener) {
    process_share_request (local_file, listener, Share_dialog_start_page.Users_and_groups);
}

void SocketApi.command_ACTIVITY (string local_file, Socket_listener listener) {
    //  Q_UNUSED (listener);

    process_file_activity_request (local_file);
}

void SocketApi.command_MANAGE_PUBLIC_LINKS (string local_file, Socket_listener listener) {
    process_share_request (local_file, listener, Share_dialog_start_page.Public_links);
}

void SocketApi.command_VERSION (string , Socket_listener listener) {
    listener.on_signal_send_message (QLatin1String ("VERSION:" MIRALL_VERSION_STRING ":" MIRALL_SOCKET_API_VERSION));
}

void SocketApi.command_SHARE_MENU_TITLE (string , Socket_listener listener) {
    //listener.on_signal_send_message (QLatin1String ("SHARE_MENU_TITLE:") + _("Share with %1", "parameter is Nextcloud").arg (Theme.instance ().app_name_gui ()));
    listener.on_signal_send_message (QLatin1String ("SHARE_MENU_TITLE:") + Theme.instance ().app_name_gui ());
}

void SocketApi.command_EDIT (string local_file, Socket_listener listener) {
    //  Q_UNUSED (listener)
    var file_data = File_data.get (local_file);
    if (!file_data.folder) {
        GLib.warning ("Unknown path" + local_file;
        return;
    }

    var record = file_data.journal_record ();
    if (!record.is_valid ())
        return;

    DirectEditor* editor = get_direct_editor_for_local_file (file_data.local_path);
    if (!editor)
        return;

    var job = new JsonApiJob (file_data.folder.account_state ().account (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing/open"), this);

    QUrlQuery parameters;
    parameters.add_query_item ("path", file_data.server_relative_path);
    parameters.add_query_item ("editor_id", editor.identifier ());
    job.add_query_params (parameters);
    job.verb (JsonApiJob.Verb.POST);

    GLib.Object.connect (job, &JsonApiJob.json_received, [] (QJsonDocument json) {
        var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var url = GLib.Uri (data.value ("url").to_string ());

        if (!url.is_empty ())
            Utility.open_browser (url);
    });
    job.on_signal_start ();
}


void SocketApi.command_COPY_PUBLIC_LINK (string local_file, Socket_listener *) {
    var file_data = File_data.get (local_file);
    if (!file_data.folder)
        return;

    AccountPointer account = file_data.folder.account_state ().account ();
    var job = new Get_or_create_public_link_share (account, file_data.server_relative_path, this);
    connect (job, &Get_or_create_public_link_share.done, this,
        [] (string url) {
            copy_url_to_clipboard (url);
        });
    connect (job, &Get_or_create_public_link_share.error, this,
        [=] () {
            /* emit */ share_command_received (file_data.server_relative_path, file_data.local_path, Share_dialog_start_page.Public_links);
        });
    job.run ();
}

// Fetches the private link url asynchronously and then calls the target slot
void SocketApi.fetch_private_link_url_helper (string local_file, std.function<void (string url)> target_fun) {
    var file_data = File_data.get (local_file);
    if (!file_data.folder) {
        GLib.warning ("Unknown path" + local_file;
        return;
    }

    var record = file_data.journal_record ();
    if (!record.is_valid ())
        return;

    fetch_private_link_url (
        file_data.folder.account_state ().account (),
        file_data.server_relative_path,
        record.numeric_file_id (),
        this,
        target_fun);
}


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
void fetch_private_link_url (
    AccountPointer account,
    string remote_path,
    GLib.ByteArray numeric_file_id,
    GLib.Object target,
    std.function<void (string url)> target_function) {
    string old_url;
    if (!numeric_file_id.is_empty ())
        old_url = account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);

    // Retrieve the new link by PROPFIND
    var job = new PropfindJob (account, remote_path, target);
    job.properties (
        GLib.List<GLib.ByteArray> ()
        + "http://owncloud.org/ns:fileid" // numeric file identifier for fallback private link generation
        + "http://owncloud.org/ns:privatelink");
    job.on_signal_timeout (10 * 1000);
    GLib.Object.connect (job, &PropfindJob.result, target, [=] (QVariantMap result) {
        var private_link_url = result["privatelink"].to_string ();
        var numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url.is_empty ()) {
            target_function (private_link_url);
        } else if (!numeric_file_id.is_empty ()) {
            target_function (account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded));
        } else {
            target_function (old_url);
        }
    });
    GLib.Object.connect (job, &PropfindJob.finished_with_error, target, [=] (Soup.Reply *) {
        target_function (old_url);
    });
    job.on_signal_start ();
}

void SocketApi.command_COPY_PRIVATE_LINK (string local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.copy_url_to_clipboard);
}

void SocketApi.command_EMAIL_PRIVATE_LINK (string local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.email_private_link);
}

void SocketApi.command_OPEN_PRIVATE_LINK (string local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.open_private_link);
}

void SocketApi.command_MAKE_AVAILABLE_LOCALLY (string files_arg, Socket_listener *) {
    const string[] files = split (files_arg);

    for (var file : files) {
        var data = File_data.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().pin_state (data.folder_relative_path, PinState.PinState.ALWAYS_LOCAL)) {
            GLib.warning ("Could not set pin state of" + data.folder_relative_path + "to always local";
        }

        // Trigger sync
        data.folder.on_signal_schedule_path_for_local_discovery (data.folder_relative_path);
        data.folder.schedule_this_folder_soon ();
    }
}

/***********************************************************
Go over all the files and replace them by a virtual file
***********************************************************/
void SocketApi.command_MAKE_ONLINE_ONLY (string files_arg, Socket_listener *) {
    const string[] files = split (files_arg);

    for (var file : files) {
        var data = File_data.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().pin_state (data.folder_relative_path, PinState.VfsItemAvailability.ONLINE_ONLY)) {
            GLib.warning ("Could not set pin state of" + data.folder_relative_path + "to online only";
        }

        // Trigger sync
        data.folder.on_signal_schedule_path_for_local_discovery (data.folder_relative_path);
        data.folder.schedule_this_folder_soon ();
    }
}

void SocketApi.copy_url_to_clipboard (string link) {
    QApplication.clipboard ().on_signal_text (link);
}

void SocketApi.command_RESOLVE_CONFLICT (string local_file, Socket_listener *) {
    const var file_data = File_data.get (local_file);
    if (!file_data.folder || !Utility.is_conflict_file (file_data.folder_relative_path))
        return; // should not have shown menu item

    const var conflicted_relative_path = file_data.folder_relative_path;
    const var base_relative_path = file_data.folder.journal_database ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());

    const var dir = QDir (file_data.folder.path ());
    const var conflicted_path = dir.file_path (conflicted_relative_path);
    const var base_path = dir.file_path (base_relative_path);

    const var base_name = GLib.FileInfo (base_path).filename ();

//  #ifndef OWNCLOUD_TEST
    ConflictDialog dialog;
    dialog.on_signal_base_filename (base_name);
    dialog.on_signal_local_version_filename (conflicted_path);
    dialog.on_signal_remote_version_filename (base_path);
    if (dialog.exec () == ConflictDialog.Accepted) {
        file_data.folder.schedule_this_folder_soon ();
    }
//  #endif
}

void SocketApi.command_DELETE_ITEM (string local_file, Socket_listener *) {
    ConflictSolver solver;
    solver.on_signal_local_version_filename (local_file);
    solver.exec (ConflictSolver.Solution.KEEP_REMOTE_VERSION);
}

void SocketApi.command_MOVE_ITEM (string local_file, Socket_listener *) {
    const var file_data = File_data.get (local_file);
    const var parent_dir = file_data.parent_folder ();
    if (!file_data.folder)
        return; // should not have shown menu item

    string default_dir_and_name = file_data.folder_relative_path;

    // If it's a conflict, we want to save it under the base name by default
    if (Utility.is_conflict_file (default_dir_and_name)) {
        default_dir_and_name = file_data.folder.journal_database ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());
    }

    // If the parent doesn't accept new files, go to the root of the sync folder
    GLib.FileInfo file_info (local_file);
    const var parent_record = parent_dir.journal_record ();
    if ( (file_info.is_file () && !parent_record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_ADD_FILE))
        || (file_info.is_dir () && !parent_record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES))) {
        default_dir_and_name = GLib.FileInfo (default_dir_and_name).filename ();
    }

    // Add back the folder path
    default_dir_and_name = QDir (file_data.folder.path ()).file_path (default_dir_and_name);

    const var target = QFileDialog.get_save_filename (
        null,
        _("Select new location …"),
        default_dir_and_name,
        "", null, QFileDialog.Hide_name_filter_details);
    if (target.is_empty ())
        return;

    ConflictSolver solver;
    solver.on_signal_local_version_filename (local_file);
    solver.on_signal_remote_version_filename (target);
}

void SocketApi.command_V2_LIST_ACCOUNTS (unowned<Socket_api_job_v2> job) {
    QJsonArray out;
    for (var acc : AccountManager.instance ().accounts ()) {
        // TODO : Use uuid once https://github.com/owncloud/client/pull/8397 is merged
        out + QJsonObject ({
            {
                "name", acc.account ().display_name ()
            },
            {
                "identifier", acc.account ().identifier ()
            }
        });
    }
    job.on_signal_success ({
        {
            "accounts", out
        }
    });
}

void SocketApi.command_V2_UPLOAD_FILES_FROM (unowned<Socket_api_job_v2> job) {
    var upload_job = new Socket_upload_job (job);
    upload_job.on_signal_start ();
}

void SocketApi.email_private_link (string link) {
    Utility.open_email_composer (
        _("I shared something with you"),
        link,
        null);
}

void Occ.SocketApi.open_private_link (string link) {
    Utility.open_browser (link);
}

void SocketApi.command_GET_STRINGS (string argument, Socket_listener listener) {
    {
        c std.array<std.pair<const char *, QString
        {
            "SHARE_MENU_TITLE", _("Share options")
        },
        {
            "FILE_ACTIVITY_MENU_TITLE", _("Activity")
        },
        {
            "CONTEXT_MENU_TITLE", Theme.instance ().app_name_gui ()
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
    } };
    listener.on_signal_send_message (string ("GET_STRINGS:BEGIN"));
    for (var& key_value : strings) {
        if (argument.is_empty () || argument == QLatin1String (key_value.first)) {
            listener.on_signal_send_message (string ("STRING:%1:%2").arg (key_value.first, key_value.second));
        }
    }
    listener.on_signal_send_message (string ("GET_STRINGS:END"));
}

void SocketApi.send_sharing_context_menu_options (File_data file_data, Socket_listener listener, bool enabled) {
    var record = file_data.journal_record ();
    bool is_on_signal_the_server = record.is_valid ();
    var flag_string = is_on_signal_the_server && enabled ? QLatin1String (".") : QLatin1String (":d:");

    var capabilities = file_data.folder.account_state ().account ().capabilities ();
    var theme = Theme.instance ();
    if (!capabilities.share_api () || ! (theme.user_group_sharing () || (theme.link_sharing () && capabilities.share_public_link ())))
        return;

    // If sharing is globally disabled, do not show any sharing entries.
    // If there is no permission to share for this file, add a disabled entry saying so
    if (is_on_signal_the_server && !record.remote_perm.is_null () && !record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_RESHARE)) {
        listener.on_signal_send_message (QLatin1String ("MENU_ITEM:DISABLED:d:") + (!record.is_directory () ? _("Resharing this file is not allowed") : _("Resharing this folder is not allowed")));
    } else {
        listener.on_signal_send_message (QLatin1String ("MENU_ITEM:SHARE") + flag_string + _("Share options"));

        // Do we have public links?
        bool public_links_enabled = theme.link_sharing () && capabilities.share_public_link ();

        // Is is possible to create a public link without user choices?
        bool can_create_default_public_link = public_links_enabled
            && !capabilities.share_public_link_enforce_expire_date ()
            && !capabilities.share_public_link_ask_optional_password ()
            && !capabilities.share_public_link_enforce_password ();

        if (can_create_default_public_link) {
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:COPY_PUBLIC_LINK") + flag_string + _("Copy public link"));
        } else if (public_links_enabled) {
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MANAGE_PUBLIC_LINKS") + flag_string + _("Copy public link"));
        }
    }

    listener.on_signal_send_message (QLatin1String ("MENU_ITEM:COPY_PRIVATE_LINK") + flag_string + _("Copy internal link"));

    // Disabled : only providing email option for private links would look odd,
    // and the copy option is more general.
    //listener.on_signal_send_message (QLatin1String ("MENU_ITEM:EMAIL_PRIVATE_LINK") + flag_string + _("Send private link by email …"));
}

SocketApi.File_data SocketApi.File_data.get (string local_file) {
    File_data data;

    data.local_path = QDir.clean_path (local_file);
    if (data.local_path.ends_with ('/'))
        data.local_path.chop (1);

    data.folder = FolderMan.instance ().folder_for_path (data.local_path);
    if (!data.folder)
        return data;

    data.folder_relative_path = data.local_path.mid (data.folder.clean_path ().length () + 1);
    data.server_relative_path = QDir (data.folder.remote_path ()).file_path (data.folder_relative_path);
    string virtual_file_ext = QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    if (data.server_relative_path.ends_with (virtual_file_ext)) {
        data.server_relative_path.chop (virtual_file_ext.size ());
    }
    return data;
}

string SocketApi.File_data.folder_relative_path_no_vfs_suffix () {
    var result = folder_relative_path;
    string virtual_file_ext = QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    if (result.ends_with (virtual_file_ext)) {
        result.chop (virtual_file_ext.size ());
    }
    return result;
}

SyncFileStatus SocketApi.File_data.sync_file_status () {
    if (!folder)
        return SyncFileStatus.SyncFileStatusTag.STATUS_NONE;
    return folder.sync_engine ().sync_file_status_tracker ().file_status (folder_relative_path);
}

SyncJournalFileRecord SocketApi.File_data.journal_record () {
    SyncJournalFileRecord record;
    if (!folder)
        return record;
    folder.journal_database ().get_file_record (folder_relative_path, record);
    return record;
}

SocketApi.File_data SocketApi.File_data.parent_folder () {
    return File_data.get (GLib.FileInfo (local_path).dir ().path ().to_utf8 ());
}

void SocketApi.command_GET_MENU_ITEMS (string argument, Occ.Socket_listener listener) {
    listener.on_signal_send_message (string ("GET_MENU_ITEMS:BEGIN"));
    const string[] files = split (argument);

    // Find the common sync folder.
    // sync_folder will be null if files are in different folders.
    Folder sync_folder = null;
    for (var file : files) {
        var folder = FolderMan.instance ().folder_for_path (file);
        if (folder != sync_folder) {
            if (!sync_folder) {
                sync_folder = folder;
            } else {
                sync_folder = null;
                break;
            }
        }
    }

    // Sharing actions show for single files only
    if (sync_folder && files.size () == 1 && sync_folder.account_state ().is_connected ()) {
        string system_path = QDir.clean_path (argument);
        if (system_path.ends_with ('/')) {
            system_path.truncate (system_path.length () - 1);
        }

        File_data file_data = File_data.get (argument);
        const var record = file_data.journal_record ();
        const bool is_on_signal_the_server = record.is_valid ();
        const var is_e2e_encrypted_path = file_data.journal_record ().is_e2e_encrypted || !file_data.journal_record ().e2e_mangled_name.is_empty ();
        var flag_string = is_on_signal_the_server && !is_e2e_encrypted_path ? QLatin1String (".") : QLatin1String (":d:");

        const GLib.FileInfo file_info (file_data.local_path);
        if (!file_info.is_dir ()) {
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:ACTIVITY") + flag_string + _("Activity"));
        }

        DirectEditor* editor = get_direct_editor_for_local_file (file_data.local_path);
        if (editor) {
            //listener.on_signal_send_message (QLatin1String ("MENU_ITEM:EDIT") + flag_string + _("Edit via ") + editor.name ());
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:EDIT") + flag_string + _("Edit"));
        } else {
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:OPEN_PRIVATE_LINK") + flag_string + _("Open in browser"));
        }

        send_sharing_context_menu_options (file_data, listener, !is_e2e_encrypted_path);

        // Conflict files get conflict resolution actions
        bool is_conflict = Utility.is_conflict_file (file_data.folder_relative_path);
        if (is_conflict || !is_on_signal_the_server) {
            // Check whether this new file is in a read-only directory
            const var parent_dir = file_data.parent_folder ();
            const var parent_record = parent_dir.journal_record ();
            const bool can_add_to_dir =
                !parent_record.is_valid () // We're likely at the root of the sync folder, got to assume we can add there
                || (file_info.is_file () && parent_record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_ADD_FILE))
                || (file_info.is_dir () && parent_record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES));
            const bool can_change_file =
                !is_on_signal_the_server
                || (record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_DELETE)
                       && record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_MOVE)
                       && record.remote_perm.has_permission (RemotePermissions.Permissions.CAN_RENAME));

            if (is_conflict && can_change_file) {
                if (can_add_to_dir) {
                    listener.on_signal_send_message (QLatin1String ("MENU_ITEM:RESOLVE_CONFLICT.") + _("Resolve conflict …"));
                } else {
                    if (is_on_signal_the_server) {
                        // Uploaded conflict file in read-only directory
                        listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + _("Move and rename …"));
                    } else {
                        // Local-only conflict file in a read-only dir
                        listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + _("Move, rename and upload …"));
                    }
                    listener.on_signal_send_message (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + _("Delete local changes"));
                }
            }

            // File in a read-only directory?
            if (!is_conflict && !is_on_signal_the_server && !can_add_to_dir) {
                listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + _("Move and upload …"));
                listener.on_signal_send_message (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + _("Delete"));
            }
        }
    }

    // File availability actions
    if (sync_folder
        && sync_folder.virtual_files_enabled ()
        && sync_folder.vfs ().socket_api_pin_state_actions_shown ()) {
        ENFORCE (!files.is_empty ());

        // Determine the combined availability status of the files
        var combined = Optional<VfsItemAvailability> ();
        var merge = [] (VfsItemAvailability lhs, VfsItemAvailability rhs) {
            if (lhs == rhs)
                return lhs;
            if (int (lhs) > int (rhs))
                std.swap (lhs, rhs); // reduce cases ensuring lhs < rhs
            if (lhs == VfsItemAvailability.PinState.ALWAYS_LOCAL && rhs == VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED)
                return VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED;
            if (lhs == VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED && rhs == VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY)
                return VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED;
            return VfsItemAvailability.VfsItemAvailability.MIXED;
        }
        for (var file : files) {
            var file_data = File_data.get (file);
            var availability = sync_folder.vfs ().availability (file_data.folder_relative_path);
            if (!availability) {
                if (availability.error () == Vfs.AvailabilityError.DATABASE_ERROR)
                    availability = VfsItemAvailability.VfsItemAvailability.MIXED;
                if (availability.error () == Vfs.AvailabilityError.NO_SUCH_ITEM)
                    continue;
            }
            if (!combined) {
                combined = *availability;
            } else {
                combined = merge (*combined, *availability);
            }
        }

        // TODO : Should be a submenu, should use icons
        var make_pin_context_menu = [&] (bool make_available_locally, bool free_space) {
            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:CURRENT_PIN:d:")
                + Utility.vfs_current_availability_text (*combined));
            if (!Theme.instance ().enforce_virtual_files_sync_folder ()) {
                listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MAKE_AVAILABLE_LOCALLY:")
                    + (make_available_locally ? QLatin1String (":") : QLatin1String ("d:")) + Utility.vfs_pin_action_text ());
            }

            listener.on_signal_send_message (QLatin1String ("MENU_ITEM:MAKE_ONLINE_ONLY:")
                + (free_space ? QLatin1String (":") : QLatin1String ("d:"))
                + Utility.vfs_free_space_action_text ());
        }

        if (combined) {
            switch (*combined) {
            case VfsItemAvailability.PinState.ALWAYS_LOCAL:
                make_pin_context_menu (false, true);
                break;
            case VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED:
            case VfsItemAvailability.VfsItemAvailability.MIXED:
                make_pin_context_menu (true, true);
                break;
            case VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED:
            case VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY:
                make_pin_context_menu (true, false);
                break;
            }
        }
    }

    listener.on_signal_send_message (string ("GET_MENU_ITEMS:END"));
}

DirectEditor* SocketApi.get_direct_editor_for_local_file (string local_file) {
    File_data file_data = File_data.get (local_file);
    var capabilities = file_data.folder.account_state ().account ().capabilities ();

    if (file_data.folder && file_data.folder.account_state ().is_connected ()) {
        const var record = file_data.journal_record ();
        const var mime_match_mode = record.is_virtual_file () ? QMimeDatabase.Match_extension : QMimeDatabase.Match_default;

        QMimeDatabase database;
        QMimeType type = database.mime_type_for_file (local_file, mime_match_mode);

        DirectEditor* editor = capabilities.get_direct_editor_for_mimetype (type);
        if (!editor) {
            editor = capabilities.get_direct_editor_for_optional_mimetype (type);
        }
        return editor;
    }

    return null;
}

#if GUI_TESTING
void SocketApi.command_ASYNC_LIST_WIDGETS (unowned<Socket_api_job> job) {
    string response;
    for (var widget : all_objects (QApplication.all_widgets ())) {
        var object_name = widget.object_name ();
        if (!object_name.is_empty ()) {
            response += object_name + ":" + widget.property ("text").to_string () + ", ";
        }
    }
    job.resolve (response);
}

void SocketApi.command_ASYNC_INVOKE_WIDGET_METHOD (unowned<Socket_api_job> job) {
    var arguments = job.arguments ();

    var widget = find_widget (arguments["object_name"].to_string ());
    if (!widget) {
        job.reject (QLatin1String ("widget not found"));
        return;
    }

    QMetaObject.invoke_method (widget, arguments["method"].to_string ().to_utf8 ().const_data ());
    job.resolve ();
}

void SocketApi.command_ASYNC_GET_WIDGET_PROPERTY (unowned<Socket_api_job> job) {
    string widget_name = job.arguments ()[QLatin1String ("object_name")].to_string ();
    var widget = find_widget (widget_name);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 2 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }

    var property_name = job.arguments ()[QLatin1String ("property")].to_string ();

    var segments = property_name.split ('.');

    GLib.Object current_object = widget;
    string value;
    for (int i = 0; i < segments.count (); i++) {
        var segment = segments.at (i);
        var var = current_object.property (segment.to_utf8 ().const_data ());

        if (var.can_convert<string> ()) {
            var.convert (QMetaType.string);
            value = var.value<string> ();
            break;
        }

        var tmp_object = var.value<GLib.Object> ();
        if (tmp_object) {
            current_object = tmp_object;
        } else {
            string message = string (QLatin1String ("Widget not found : 3 : %1")).arg (widget_name);
            job.reject (message);
            return;
        }
    }

    job.resolve (value);
}

void SocketApi.command_ASYNC_SET_WIDGET_PROPERTY (unowned<Socket_api_job> job) {
    var arguments = job.arguments ();
    string widget_name = arguments["object_name"].to_string ();
    var widget = find_widget (widget_name);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 4 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }
    widget.property (arguments["property"].to_string ().to_utf8 ().const_data (),
        arguments["value"]);

    job.resolve ();
}

void SocketApi.command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (unowned<Socket_api_job> job) {
    var arguments = job.arguments ();
    string widget_name = arguments["object_name"].to_string ();
    var widget = find_widget (arguments["object_name"].to_string ());
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 5 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }

    Listener_closure closure = new Listener_closure ([job] () {
        job.resolve ("signal emitted");
    });

    var signal_signature = arguments["signal_signature"].to_string ();
    signal_signature.prepend ("2");
    var utf8 = signal_signature.to_utf8 ();
    var signal_signature_final = utf8.const_data ();
    connect (widget, signal_signature_final, closure, SLOT (closure_slot ()), Qt.QueuedConnection);
}

void SocketApi.command_ASYNC_TRIGGER_MENU_ACTION (unowned<Socket_api_job> job) {
    var arguments = job.arguments ();

    var object_name = arguments["object_name"].to_string ();
    var widget = find_widget (object_name);
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 1 : %1")).arg (object_name);
        job.reject (message);
        return;
    }

    var children = widget.find_children<Gtk.Widget> ();
    for (var child_widget : children) {
        // foo is the popupwidget!
        var actions = child_widget.actions ();
        for (var action : actions) {
            if (action.object_name () == arguments["action_name"].to_string ()) {
                action.trigger ();

                job.resolve ("action found");
                return;
            }
        }
    }

    string message = string (QLatin1String ("Action not found : 1 : %1")).arg (arguments["action_name"].to_string ());
    job.reject (message);
}

void SocketApi.command_ASYNC_ASSERT_ICON_IS_EQUAL (unowned<Socket_api_job> job) {
    var widget = find_widget (job.arguments ()[QLatin1String ("query_string")].to_string ());
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 6 : %1")).arg (job.arguments ()["query_string"].to_string ());
        job.reject (message);
        return;
    }

    var property_name = job.arguments ()[QLatin1String ("PROPERTY_PATH")].to_string ();

    var segments = property_name.split ('.');

    GLib.Object current_object = widget;
    QIcon value;
    for (int i = 0; i < segments.count (); i++) {
        var segment = segments.at (i);
        var var = current_object.property (segment.to_utf8 ().const_data ());

        if (var.can_convert<QIcon> ()) {
            var.convert (QMetaType.QIcon);
            value = var.value<QIcon> ();
            break;
        }

        var tmp_object = var.value<GLib.Object> ();
        if (tmp_object) {
            current_object = tmp_object;
        } else {
            job.reject (string (QLatin1String ("Icon not found : %1")).arg (property_name));
        }
    }

    var icon_name = job.arguments ()[QLatin1String ("icon_name")].to_string ();
    if (value.name () == icon_name) {
        job.resolve ();
    } else {
        job.reject ("icon_name " + icon_name + " does not match : " + value.name ());
    }
}
//  #endif

string SocketApi.build_register_path_message (string path) {
    GLib.FileInfo fi (path);
    string message = "REGISTER_PATH:";
    message.append (QDir.to_native_separators (fi.absolute_file_path ()));
    return message;
}







}
