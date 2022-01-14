/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <functional>
// #include <QBit_array>
// #include <QPointer>

// #include <QJsonDocument>
// #include <QJsonObject>

// #include <memory>
// #include <QTimer>

#ifndef OWNCLOUD_TEST
#endif

// #include <array>
// #include <QBit_array>
// #include <QUrl>
// #include <QMeta_method>
// #include <QMetaObject>
// #include <QStringList>
// #include <QScopedPointer>
// #include <QFile>
// #include <QDir>
// #include <QApplication>
// #include <QLocal_socket>
// #include <QString_builder>
// #include <QMessageBox>
// #include <QInputDialog>
// #include <QFileDialog>

// #include <QAction>
// #include <QJsonArray>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <Gtk.Widget>

// #include <QClipboard>
// #include <QDesktopServices>

// #include <QProcess>
// #include <QStandardPaths>

// This is the version that is returned when the client asks for the VERSION.
// The first number should be changed if there is an incompatible change that breaks old clients.
// The second number should be changed when there are new features.
const int MIRALL_SOCKET_API_VERSION "1.1"

#include "sharedialog.h" // for the Share_dialog_start_page

// #include <QLocal_server>
using Socket_api_server = QLocal_server;


namespace Occ {

class DirectEditor;

Q_DECLARE_LOGGING_CATEGORY (lc_socket_api)

/***********************************************************
@brief The SocketApi class
@ingroup gui
***********************************************************/
class SocketApi : GLib.Object {

    public SocketApi (GLib.Object *parent = nullptr);
    public ~SocketApi () override;

public slots:
    void slot_update_folder_view (Folder *f);
    void slot_unregister_path (string &alias);
    void slot_register_path (string &alias);
    void broadcast_status_push_message (string &system_path, SyncFileStatus file_status);

signals:
    void share_command_received (string &share_path, string &local_path, Share_dialog_start_page start_page);
    void file_activity_command_received (string &share_path, string &local_path);

private slots:
    void slot_new_connection ();
    void on_lost_connection ();
    void slot_socket_destroyed (GLib.Object *obj);
    void slot_read_socket ();

    static void copy_url_to_clipboard (string &link);
    static void email_private_link (string &link);
    static void open_private_link (string &link);

private:
    // Helper structure for getting information on a file
    // based on its local path - used for nearly all remote
    // actions.
    struct File_data {
        static File_data get (string &local_file);
        SyncFileStatus sync_file_status ();
        SyncJournalFileRecord journal_record ();
        File_data parent_folder ();

        // Relative path of the file locally, without any vfs suffix
        string folder_relative_path_no_vfs_suffix ();

        Folder *folder;
        // Absolute path of the file locally. (May be a virtual file)
        string local_path;
        // Relative path of the file locally, as in the DB. (May be a virtual file)
        string folder_relative_path;
        // Path of the file on the server (In case of virtual file, it points to the actual file)
        string server_relative_path;
    };

    void broadcast_message (string &msg, bool do_wait = false);

    // opens share dialog, sends reply
    void process_share_request (string &local_file, Socket_listener *listener, Share_dialog_start_page start_page);
    void process_file_activity_request (string &local_file);

    Q_INVOKABLE void command_RETRIEVE_FOLDER_STATUS (string &argument, Socket_listener *listener);
    Q_INVOKABLE void command_RETRIEVE_FILE_STATUS (string &argument, Socket_listener *listener);

    Q_INVOKABLE void command_VERSION (string &argument, Socket_listener *listener);

    Q_INVOKABLE void command_SHARE_MENU_TITLE (string &argument, Socket_listener *listener);

    // The context menu actions
    Q_INVOKABLE void command_ACTIVITY (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_SHARE (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_MANAGE_PUBLIC_LINKS (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_COPY_PUBLIC_LINK (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_COPY_PRIVATE_LINK (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_EMAIL_PRIVATE_LINK (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_OPEN_PRIVATE_LINK (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_MAKE_AVAILABLE_LOCALLY (string &files_arg, Socket_listener *listener);
    Q_INVOKABLE void command_MAKE_ONLINE_ONLY (string &files_arg, Socket_listener *listener);
    Q_INVOKABLE void command_RESOLVE_CONFLICT (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_DELETE_ITEM (string &local_file, Socket_listener *listener);
    Q_INVOKABLE void command_MOVE_ITEM (string &local_file, Socket_listener *listener);

    // External sync
    Q_INVOKABLE void command_V2_LIST_ACCOUNTS (QSharedPointer<Socket_api_job_v2> &job) const;
    Q_INVOKABLE void command_V2_UPLOAD_FILES_FROM (QSharedPointer<Socket_api_job_v2> &job) const;

    // Fetch the private link and call target_fun
    void fetch_private_link_url_helper (string &local_file, std.function<void (string &url)> &target_fun);

    /***********************************************************
    Sends translated/branded strings that may be useful to the integration
    ***********************************************************/
    Q_INVOKABLE void command_GET_STRINGS (string &argument, Socket_listener *listener);

    // Sends the context menu options relating to sharing to listener
    void send_sharing_context_menu_options (File_data &file_data, Socket_listener *listener, bool enabled);

    /***********************************************************
    Send the list of menu item. (added in version 1.1)
    argument is a list of files for which the menu should be shown, separated by '\x1e'
    Reply with  GET_MENU_ITEMS:BEGIN
    followed by several MENU_ITEM:[Action]:[flag]:[Text]
    If flag contains 'd', the menu should be disabled
    and ends with GET_MENU_ITEMS:END
    ***********************************************************/
    Q_INVOKABLE void command_GET_MENU_ITEMS (string &argument, Socket_listener *listener);

    /// Direct Editing
    Q_INVOKABLE void command_EDIT (string &local_file, Socket_listener *listener);
    DirectEditor* get_direct_editor_for_local_file (string &local_file);

#if GUI_TESTING
    Q_INVOKABLE void command_ASYNC_ASSERT_ICON_IS_EQUAL (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_LIST_WIDGETS (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_INVOKE_WIDGET_METHOD (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_GET_WIDGET_PROPERTY (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_SET_WIDGET_PROPERTY (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (QSharedPointer<Socket_api_job> &job);
    Q_INVOKABLE void command_ASYNC_TRIGGER_MENU_ACTION (QSharedPointer<Socket_api_job> &job);
#endif

    string build_register_path_message (string &path);

    QSet<string> _registered_aliases;
    QMap<QIODevice *, QSharedPointer<Socket_listener>> _listeners;
    Socket_api_server _local_server;
};
}













namespace {

const QLatin1Char Record_separator () {
    return QLatin1Char ('\x1e');
}

QStringList split (string &data) {
    // TODO : string ref?
    return data.split (Record_separator ());
}

#if GUI_TESTING

using namespace Occ;

QList<GLib.Object> all_objects (QList<Gtk.Widget> &widgets) {
    QList<GLib.Object> objects;
    std.copy (widgets.const_begin (), widgets.const_end (), std.back_inserter (objects));

    objects << q_app;

    return objects;
}

GLib.Object *find_widget (string &query_string, QList<Gtk.Widget> &widgets = QApplication.all_widgets ()) {
    auto objects = all_objects (widgets);

    QList<GLib.Object>.Const_iterator found_widget;

    if (query_string.contains ('>')) {
        q_c_debug (lc_socket_api) << "query_string contains >";

        auto sub_queries = query_string.split ('>', string.Skip_empty_parts);
        Q_ASSERT (sub_queries.count () == 2);

        auto parent_query_string = sub_queries[0].trimmed ();
        q_c_debug (lc_socket_api) << "Find parent : " << parent_query_string;
        auto parent = find_widget (parent_query_string);

        if (!parent) {
            return nullptr;
        }

        auto child_query_string = sub_queries[1].trimmed ();
        auto child = find_widget (child_query_string, parent.find_children<Gtk.Widget> ());
        q_c_debug (lc_socket_api) << "found child : " << !!child;
        return child;

    } else if (query_string.starts_with ('#')) {
        auto object_name = query_string.mid (1);
        q_c_debug (lc_socket_api) << "find object_name : " << object_name;
        found_widget = std.find_if (objects.const_begin (), objects.const_end (), [&] (GLib.Object *widget) {
            return widget.object_name () == object_name;
        });
    } else {
        QList<GLib.Object> matches;
        std.copy_if (objects.const_begin (), objects.const_end (), std.back_inserter (matches), [&] (GLib.Object *widget) {
            return widget.inherits (query_string.to_latin1 ());
        });

        std.for_each (matches.const_begin (), matches.const_end (), [] (GLib.Object *w) {
            if (!w)
                return;
            q_c_debug (lc_socket_api) << "WIDGET : " << w.object_name () << w.meta_object ().class_name ();
        });

        if (matches.empty ()) {
            return nullptr;
        }
        return matches[0];
    }

    if (found_widget == objects.const_end ()) {
        return nullptr;
    }

    return *found_widget;
}
#endif

static inline string remove_trailing_slash (string path) {
    Q_ASSERT (path.ends_with (QLatin1Char ('/')));
    path.truncate (path.length () - 1);
    return path;
}

static string build_message (string &verb, string &path, string &status = string ()) {
    string msg (verb);

    if (!status.is_empty ()) {
        msg.append (QLatin1Char (':'));
        msg.append (status);
    }
    if (!path.is_empty ()) {
        msg.append (QLatin1Char (':'));
        QFileInfo fi (path);
        msg.append (QDir.to_native_separators (fi.absolute_file_path ()));
    }
    return msg;
}

void Socket_listener.send_message (string &message, bool do_wait) {
    if (!socket) {
        q_c_warning (lc_socket_api) << "Not sending message to dead socket:" << message;
        return;
    }

    q_c_debug (lc_socket_api) << "Sending SocketApi message -." << message << "to" << socket;
    string local_message = message;
    if (!local_message.ends_with (QLatin1Char ('\n'))) {
        local_message.append (QLatin1Char ('\n'));
    }

    QByteArray bytes_to_send = local_message.to_utf8 ();
    int64 sent = socket.write (bytes_to_send);
    if (do_wait) {
        socket.wait_for_bytes_written (1000);
    }
    if (sent != bytes_to_send.length ()) {
        q_c_warning (lc_socket_api) << "Could not send all data on socket for " << local_message;
    }
}

SocketApi.SocketApi (GLib.Object *parent)
    : GLib.Object (parent) {
    string socket_path;

    q_register_meta_type<Socket_listener> ("Socket_listener*");
    q_register_meta_type<QSharedPointer<Socket_api_job>> ("QSharedPointer<Socket_api_job>");
    q_register_meta_type<QSharedPointer<Socket_api_job_v2>> ("QSharedPointer<Socket_api_job_v2>");

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
    } else if (Utility.is_linux () || Utility.is_b_sD ()) {
        string runtime_dir;
        runtime_dir = QStandardPaths.writable_location (QStandardPaths.Runtime_location);
        socket_path = runtime_dir + "/" + Theme.instance ().app_name () + "/socket";
    } else {
        q_c_warning (lc_socket_api) << "An unexpected system detected, this probably won't work.";
    }

    Socket_api_server.remove_server (socket_path);
    QFileInfo info (socket_path);
    if (!info.dir ().exists ()) {
        bool result = info.dir ().mkpath (".");
        q_c_debug (lc_socket_api) << "creating" << info.dir ().path () << result;
        if (result) {
            QFile.set_permissions (socket_path,
                QFile.Permissions (QFile.Read_owner + QFile.Write_owner + QFile.Exe_owner));
        }
    }
    if (!_local_server.listen (socket_path)) {
        q_c_warning (lc_socket_api) << "can't start server" << socket_path;
    } else {
        q_c_info (lc_socket_api) << "server started, listening at " << socket_path;
    }

    connect (&_local_server, &Socket_api_server.new_connection, this, &SocketApi.slot_new_connection);

    // folder watcher
    connect (FolderMan.instance (), &FolderMan.folder_sync_state_change, this, &SocketApi.slot_update_folder_view);
}

SocketApi.~SocketApi () {
    q_c_debug (lc_socket_api) << "dtor";
    _local_server.close ();
    // All remaining sockets will be destroyed with _local_server, their parent
    ASSERT (_listeners.is_empty () || _listeners.first ().socket.parent () == &_local_server)
    _listeners.clear ();
}

void SocketApi.slot_new_connection () {
    // Note that on mac_o_s this is not actually a line-based QIODevice, it's a Socket_api_socket which is our
    // custom message based mac_o_s IPC.
    QIODevice *socket = _local_server.next_pending_connection ();

    if (!socket) {
        return;
    }
    q_c_info (lc_socket_api) << "New connection" << socket;
    connect (socket, &QIODevice.ready_read, this, &SocketApi.slot_read_socket);
    connect (socket, SIGNAL (disconnected ()), this, SLOT (on_lost_connection ()));
    connect (socket, &GLib.Object.destroyed, this, &SocketApi.slot_socket_destroyed);
    ASSERT (socket.read_all ().is_empty ());

    auto listener = QSharedPointer<Socket_listener>.create (socket);
    _listeners.insert (socket, listener);
    for (Folder *f : FolderMan.instance ().map ()) {
        if (f.can_sync ()) {
            string message = build_register_path_message (remove_trailing_slash (f.path ()));
            q_c_info (lc_socket_api) << "Trying to send SocketApi Register Path Message -." << message << "to" << listener.socket;
            listener.send_message (message);
        }
    }
}

void SocketApi.on_lost_connection () {
    q_c_info (lc_socket_api) << "Lost connection " << sender ();
    sender ().delete_later ();

    auto socket = qobject_cast<QIODevice> (sender ());
    ASSERT (socket);
    _listeners.remove (socket);
}

void SocketApi.slot_socket_destroyed (GLib.Object *obj) {
    auto *socket = static_cast<QIODevice> (obj);
    _listeners.remove (socket);
}

void SocketApi.slot_read_socket () {
    auto *socket = qobject_cast<QIODevice> (sender ());
    ASSERT (socket);

    // Find the Socket_listener
    //
    // It's possible for the disconnected () signal to be triggered before
    // the ready_read () signals are received - in that case there won't be a
    // valid listener. We execute the handler anyway, but it will work with
    // a Socket_listener that doesn't send any messages.
    static auto invalid_listener = QSharedPointer<Socket_listener>.create (nullptr);
    const auto listener = _listeners.value (socket, invalid_listener);
    while (socket.can_read_line ()) {
        // Make sure to normalize the input from the socket to
        // make sure that the path will match, especially on OS X.
        const string line = string.from_utf8 (socket.read_line ().trimmed ()).normalized (string.Normalization_form_C);
        q_c_info (lc_socket_api) << "Received SocketApi message <--" << line << "from" << socket;
        const int arg_pos = line.index_of (QLatin1Char (':'));
        const QByteArray command = line.mid_ref (0, arg_pos).to_utf8 ().to_upper ();
        const int index_of_method = [&] {
            QByteArray function_with_arguments = QByteArrayLiteral ("command_");
            if (command.starts_with ("ASYNC_")) {
                function_with_arguments += command + QByteArrayLiteral (" (QSharedPointer<Socket_api_job>)");
            } else if (command.starts_with ("V2/")) {
                function_with_arguments += QByteArrayLiteral ("V2_") + command.mid (3) + QByteArrayLiteral (" (QSharedPointer<Socket_api_job_v2>)");
            } else {
                function_with_arguments += command + QByteArrayLiteral (" (string,Socket_listener*)");
            }
            Q_ASSERT (static_qt_meta_object.normalized_signature (function_with_arguments) == function_with_arguments);
            const auto out = static_meta_object.index_of_method (function_with_arguments);
            if (out == -1) {
                listener.send_error (QStringLiteral ("Function %1 not found").arg (string.from_utf8 (function_with_arguments)));
            }
            ASSERT (out != -1)
            return out;
        } ();

        const auto argument = arg_pos != -1 ? line.mid_ref (arg_pos + 1) : QStringRef ();
        if (command.starts_with ("ASYNC_")) {
            auto arguments = argument.split ('|');
            if (arguments.size () != 2) {
                listener.send_error (QStringLiteral ("argument count is wrong"));
                return;
            }

            auto json = QJsonDocument.from_json (arguments[1].to_utf8 ()).object ();

            auto job_id = arguments[0];

            auto socket_api_job = QSharedPointer<Socket_api_job> (
                new Socket_api_job (job_id.to_string (), listener, json), &GLib.Object.delete_later);
            if (index_of_method != -1) {
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (QSharedPointer<Socket_api_job>, socket_api_job));
            } else {
                q_c_warning (lc_socket_api) << "The command is not supported by this version of the client:" << command
                                       << "with argument:" << argument;
                socket_api_job.reject (QStringLiteral ("command not found"));
            }
        } else if (command.starts_with ("V2/")) {
            QJsonParseError error;
            const auto json = QJsonDocument.from_json (argument.to_utf8 (), &error).object ();
            if (error.error != QJsonParseError.NoError) {
                q_c_warning (lc_socket_api ()) << "Invalid json" << argument.to_string () << error.error_string ();
                listener.send_error (error.error_string ());
                return;
            }
            auto socket_api_job = QSharedPointer<Socket_api_job_v2>.create (listener, command, json);
            if (index_of_method != -1) {
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (QSharedPointer<Socket_api_job_v2>, socket_api_job));
            } else {
                q_c_warning (lc_socket_api) << "The command is not supported by this version of the client:" << command
                                       << "with argument:" << argument;
                socket_api_job.failure (QStringLiteral ("command not found"));
            }
        } else {
            if (index_of_method != -1) {
                // to ensure that listener is still valid we need to call it with Qt.Direct_connection
                ASSERT (thread () == QThread.current_thread ())
                static_meta_object.method (index_of_method)
                    .invoke (this, Qt.Direct_connection, Q_ARG (string, argument.to_string ()),
                        Q_ARG (Socket_listener *, listener.data ()));
            }
        }
    }
}

void SocketApi.slot_register_path (string &alias) {
    // Make sure not to register twice to each connected client
    if (_registered_aliases.contains (alias))
        return;

    Folder *f = FolderMan.instance ().folder (alias);
    if (f) {
        const string message = build_register_path_message (remove_trailing_slash (f.path ()));
        for (auto &listener : q_as_const (_listeners)) {
            q_c_info (lc_socket_api) << "Trying to send SocketApi Register Path Message -." << message << "to" << listener.socket;
            listener.send_message (message);
        }
    }

    _registered_aliases.insert (alias);
}

void SocketApi.slot_unregister_path (string &alias) {
    if (!_registered_aliases.contains (alias))
        return;

    Folder *f = FolderMan.instance ().folder (alias);
    if (f)
        broadcast_message (build_message (QLatin1String ("UNREGISTER_PATH"), remove_trailing_slash (f.path ()), string ()), true);

    _registered_aliases.remove (alias);
}

void SocketApi.slot_update_folder_view (Folder *f) {
    if (_listeners.is_empty ()) {
        return;
    }

    if (f) {
        // do only send UPDATE_VIEW for a couple of status
        if (f.sync_result ().status () == SyncResult.Sync_prepare
            || f.sync_result ().status () == SyncResult.Success
            || f.sync_result ().status () == SyncResult.Paused
            || f.sync_result ().status () == SyncResult.Problem
            || f.sync_result ().status () == SyncResult.Error
            || f.sync_result ().status () == SyncResult.Setup_error) {
            string root_path = remove_trailing_slash (f.path ());
            broadcast_status_push_message (root_path, f.sync_engine ().sync_file_status_tracker ().file_status (""));

            broadcast_message (build_message (QLatin1String ("UPDATE_VIEW"), root_path));
        } else {
            q_c_debug (lc_socket_api) << "Not sending UPDATE_VIEW for" << f.alias () << "because status () is" << f.sync_result ().status ();
        }
    }
}

void SocketApi.broadcast_message (string &msg, bool do_wait) {
    for (auto &listener : q_as_const (_listeners)) {
        listener.send_message (msg, do_wait);
    }
}

void SocketApi.process_file_activity_request (string &local_file) {
    const auto file_data = File_data.get (local_file);
    emit file_activity_command_received (file_data.server_relative_path, file_data.local_path);
}

void SocketApi.process_share_request (string &local_file, Socket_listener *listener, Share_dialog_start_page start_page) {
    auto theme = Theme.instance ();

    auto file_data = File_data.get (local_file);
    auto share_folder = file_data.folder;
    if (!share_folder) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.to_native_separators (local_file);
        // files that are not within a sync folder are not synced.
        listener.send_message (message);
    } else if (!share_folder.account_state ().is_connected ()) {
        const string message = QLatin1String ("SHARE:NOTCONNECTED:") + QDir.to_native_separators (local_file);
        // if the folder isn't connected, don't open the share dialog
        listener.send_message (message);
    } else if (!theme.link_sharing () && (!theme.user_group_sharing () || share_folder.account_state ().account ().server_version_int () < Account.make_server_version (8, 2, 0))) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.to_native_separators (local_file);
        listener.send_message (message);
    } else {
        // If the file doesn't have a journal record, it might not be uploaded yet
        if (!file_data.journal_record ().is_valid ()) {
            const string message = QLatin1String ("SHARE:NOTSYNCED:") + QDir.to_native_separators (local_file);
            listener.send_message (message);
            return;
        }

        auto &remote_path = file_data.server_relative_path;

        // Can't share root folder
        if (remote_path == "/") {
            const string message = QLatin1String ("SHARE:CANNOTSHAREROOT:") + QDir.to_native_separators (local_file);
            listener.send_message (message);
            return;
        }

        const string message = QLatin1String ("SHARE:OK:") + QDir.to_native_separators (local_file);
        listener.send_message (message);

        emit share_command_received (remote_path, file_data.local_path, start_page);
    }
}

void SocketApi.broadcast_status_push_message (string &system_path, SyncFileStatus file_status) {
    string msg = build_message (QLatin1String ("STATUS"), system_path, file_status.to_socket_api_string ());
    Q_ASSERT (!system_path.ends_with ('/'));
    uint directory_hash = q_hash (system_path.left (system_path.last_index_of ('/')));
    for (auto &listener : q_as_const (_listeners)) {
        listener.send_message_if_directory_monitored (msg, directory_hash);
    }
}

void SocketApi.command_RETRIEVE_FOLDER_STATUS (string &argument, Socket_listener *listener) {
    // This command is the same as RETRIEVE_FILE_STATUS
    command_RETRIEVE_FILE_STATUS (argument, listener);
}

void SocketApi.command_RETRIEVE_FILE_STATUS (string &argument, Socket_listener *listener) {
    string status_string;

    auto file_data = File_data.get (argument);
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

    const string message = QLatin1String ("STATUS:") % status_string % QLatin1Char (':') % QDir.to_native_separators (argument);
    listener.send_message (message);
}

void SocketApi.command_SHARE (string &local_file, Socket_listener *listener) {
    process_share_request (local_file, listener, Share_dialog_start_page.Users_and_groups);
}

void SocketApi.command_ACTIVITY (string &local_file, Socket_listener *listener) {
    Q_UNUSED (listener);

    process_file_activity_request (local_file);
}

void SocketApi.command_MANAGE_PUBLIC_LINKS (string &local_file, Socket_listener *listener) {
    process_share_request (local_file, listener, Share_dialog_start_page.Public_links);
}

void SocketApi.command_VERSION (string &, Socket_listener *listener) {
    listener.send_message (QLatin1String ("VERSION:" MIRALL_VERSION_STRING ":" MIRALL_SOCKET_API_VERSION));
}

void SocketApi.command_SHARE_MENU_TITLE (string &, Socket_listener *listener) {
    //listener.send_message (QLatin1String ("SHARE_MENU_TITLE:") + tr ("Share with %1", "parameter is Nextcloud").arg (Theme.instance ().app_name_g_u_i ()));
    listener.send_message (QLatin1String ("SHARE_MENU_TITLE:") + Theme.instance ().app_name_g_u_i ());
}

void SocketApi.command_EDIT (string &local_file, Socket_listener *listener) {
    Q_UNUSED (listener)
    auto file_data = File_data.get (local_file);
    if (!file_data.folder) {
        q_c_warning (lc_socket_api) << "Unknown path" << local_file;
        return;
    }

    auto record = file_data.journal_record ();
    if (!record.is_valid ())
        return;

    DirectEditor* editor = get_direct_editor_for_local_file (file_data.local_path);
    if (!editor)
        return;

    auto *job = new JsonApiJob (file_data.folder.account_state ().account (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing/open"), this);

    QUrlQuery params;
    params.add_query_item ("path", file_data.server_relative_path);
    params.add_query_item ("editor_id", editor.id ());
    job.add_query_params (params);
    job.set_verb (JsonApiJob.Verb.Post);

    GLib.Object.connect (job, &JsonApiJob.json_received, [] (QJsonDocument &json){
        auto data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        auto url = QUrl (data.value ("url").to_string ());

        if (!url.is_empty ())
            Utility.open_browser (url);
    });
    job.start ();
}

// don't pull the share manager into socketapi unittests
#ifndef OWNCLOUD_TEST

class Get_or_create_public_link_share : GLib.Object {

    public Get_or_create_public_link_share (AccountPtr &account, string &local_file,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account)
        , _share_manager (account)
        , _local_file (local_file) {
        connect (&_share_manager, &Share_manager.shares_fetched,
            this, &Get_or_create_public_link_share.shares_fetched);
        connect (&_share_manager, &Share_manager.link_share_created,
            this, &Get_or_create_public_link_share.link_share_created);
        connect (&_share_manager, &Share_manager.link_share_requires_password,
            this, &Get_or_create_public_link_share.link_share_requires_password);
        connect (&_share_manager, &Share_manager.server_error,
            this, &Get_or_create_public_link_share.server_error);
    }

    public void run () {
        q_c_debug (lc_public_link) << "Fetching shares";
        _share_manager.fetch_shares (_local_file);
    }

private slots:
    void shares_fetched (QList<QSharedPointer<Share>> &shares) {
        auto share_name = SocketApi.tr ("Context menu share");

        // If there already is a context menu share, reuse it
        for (auto &share : shares) {
            const auto link_share = q_shared_pointer_dynamic_cast<Link_share> (share);
            if (!link_share)
                continue;

            if (link_share.get_name () == share_name) {
                q_c_debug (lc_public_link) << "Found existing share, reusing";
                return success (link_share.get_link ().to_string ());
            }
        }

        // otherwise create a new one
        q_c_debug (lc_public_link) << "Creating new share";
        _share_manager.create_link_share (_local_file, share_name, string ());
    }

    void link_share_created (QSharedPointer<Link_share> &share) {
        q_c_debug (lc_public_link) << "New share created";
        success (share.get_link ().to_string ());
    }

    void password_required () {
        bool ok = false;
        string password = QInputDialog.get_text (nullptr,
                                                 tr ("Password for share required"),
                                                 tr ("Please enter a password for your link share:"),
                                                 QLineEdit.Normal,
                                                 string (),
                                                 &ok);

        if (!ok) {
            // The dialog was canceled so no need to do anything
            return;
        }

        // Try to create the link share again with the newly entered password
        _share_manager.create_link_share (_local_file, string (), password);
    }

    void link_share_requires_password (string &message) {
        q_c_info (lc_public_link) << "Could not create link share:" << message;
        emit error (message);
        delete_later ();
    }

    void server_error (int code, string &message) {
        q_c_warning (lc_public_link) << "Share fetch/create error" << code << message;
        QMessageBox.warning (
            nullptr,
            tr ("Sharing error"),
            tr ("Could not retrieve or create the public link share. Error:\n\n%1").arg (message),
            QMessageBox.Ok,
            QMessageBox.NoButton);
        emit error (message);
        delete_later ();
    }

signals:
    void done (string &link);
    void error (string &message);

private:
    void success (string &link) {
        emit done (link);
        delete_later ();
    }

    AccountPtr _account;
    Share_manager _share_manager;
    string _local_file;
};

#else

class Get_or_create_public_link_share : GLib.Object {

    public Get_or_create_public_link_share (AccountPtr &, string &,
        std.function<void (string &link)>, GLib.Object *) {
    }

    public void run () {
    }
};

#endif

void SocketApi.command_COPY_PUBLIC_LINK (string &local_file, Socket_listener *) {
    auto file_data = File_data.get (local_file);
    if (!file_data.folder)
        return;

    AccountPtr account = file_data.folder.account_state ().account ();
    auto job = new Get_or_create_public_link_share (account, file_data.server_relative_path, this);
    connect (job, &Get_or_create_public_link_share.done, this,
        [] (string &url) {
            copy_url_to_clipboard (url);
        });
    connect (job, &Get_or_create_public_link_share.error, this,
        [=] () {
            emit share_command_received (file_data.server_relative_path, file_data.local_path, Share_dialog_start_page.Public_links);
        });
    job.run ();
}

// Fetches the private link url asynchronously and then calls the target slot
void SocketApi.fetch_private_link_url_helper (string &local_file, std.function<void (string &url)> &target_fun) {
    auto file_data = File_data.get (local_file);
    if (!file_data.folder) {
        q_c_warning (lc_socket_api) << "Unknown path" << local_file;
        return;
    }

    auto record = file_data.journal_record ();
    if (!record.is_valid ())
        return;

    fetch_private_link_url (
        file_data.folder.account_state ().account (),
        file_data.server_relative_path,
        record.numeric_file_id (),
        this,
        target_fun);
}

void SocketApi.command_COPY_PRIVATE_LINK (string &local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.copy_url_to_clipboard);
}

void SocketApi.command_EMAIL_PRIVATE_LINK (string &local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.email_private_link);
}

void SocketApi.command_OPEN_PRIVATE_LINK (string &local_file, Socket_listener *) {
    fetch_private_link_url_helper (local_file, &SocketApi.open_private_link);
}

void SocketApi.command_MAKE_AVAILABLE_LOCALLY (string &files_arg, Socket_listener *) {
    const QStringList files = split (files_arg);

    for (auto &file : files) {
        auto data = File_data.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().set_pin_state (data.folder_relative_path, PinState.AlwaysLocal)) {
            q_c_warning (lc_socket_api) << "Could not set pin state of" << data.folder_relative_path << "to always local";
        }

        // Trigger sync
        data.folder.schedule_path_for_local_discovery (data.folder_relative_path);
        data.folder.schedule_this_folder_soon ();
    }
}

/***********************************************************
Go over all the files and replace them by a virtual file
***********************************************************/
void SocketApi.command_MAKE_ONLINE_ONLY (string &files_arg, Socket_listener *) {
    const QStringList files = split (files_arg);

    for (auto &file : files) {
        auto data = File_data.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().set_pin_state (data.folder_relative_path, PinState.OnlineOnly)) {
            q_c_warning (lc_socket_api) << "Could not set pin state of" << data.folder_relative_path << "to online only";
        }

        // Trigger sync
        data.folder.schedule_path_for_local_discovery (data.folder_relative_path);
        data.folder.schedule_this_folder_soon ();
    }
}

void SocketApi.copy_url_to_clipboard (string &link) {
    QApplication.clipboard ().set_text (link);
}

void SocketApi.command_RESOLVE_CONFLICT (string &local_file, Socket_listener *) {
    const auto file_data = File_data.get (local_file);
    if (!file_data.folder || !Utility.is_conflict_file (file_data.folder_relative_path))
        return; // should not have shown menu item

    const auto conflicted_relative_path = file_data.folder_relative_path;
    const auto base_relative_path = file_data.folder.journal_db ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());

    const auto dir = QDir (file_data.folder.path ());
    const auto conflicted_path = dir.file_path (conflicted_relative_path);
    const auto base_path = dir.file_path (base_relative_path);

    const auto base_name = QFileInfo (base_path).file_name ();

#ifndef OWNCLOUD_TEST
    ConflictDialog dialog;
    dialog.set_base_filename (base_name);
    dialog.set_local_version_filename (conflicted_path);
    dialog.set_remote_version_filename (base_path);
    if (dialog.exec () == ConflictDialog.Accepted) {
        file_data.folder.schedule_this_folder_soon ();
    }
#endif
}

void SocketApi.command_DELETE_ITEM (string &local_file, Socket_listener *) {
    ConflictSolver solver;
    solver.set_local_version_filename (local_file);
    solver.exec (ConflictSolver.KeepRemoteVersion);
}

void SocketApi.command_MOVE_ITEM (string &local_file, Socket_listener *) {
    const auto file_data = File_data.get (local_file);
    const auto parent_dir = file_data.parent_folder ();
    if (!file_data.folder)
        return; // should not have shown menu item

    string default_dir_and_name = file_data.folder_relative_path;

    // If it's a conflict, we want to save it under the base name by default
    if (Utility.is_conflict_file (default_dir_and_name)) {
        default_dir_and_name = file_data.folder.journal_db ().conflict_file_base_name (file_data.folder_relative_path.to_utf8 ());
    }

    // If the parent doesn't accept new files, go to the root of the sync folder
    QFileInfo file_info (local_file);
    const auto parent_record = parent_dir.journal_record ();
    if ( (file_info.is_file () && !parent_record._remote_perm.has_permission (RemotePermissions.Can_add_file))
        || (file_info.is_dir () && !parent_record._remote_perm.has_permission (RemotePermissions.Can_add_sub_directories))) {
        default_dir_and_name = QFileInfo (default_dir_and_name).file_name ();
    }

    // Add back the folder path
    default_dir_and_name = QDir (file_data.folder.path ()).file_path (default_dir_and_name);

    const auto target = QFileDialog.get_save_file_name (
        nullptr,
        tr ("Select new location …"),
        default_dir_and_name,
        string (), nullptr, QFileDialog.Hide_name_filter_details);
    if (target.is_empty ())
        return;

    ConflictSolver solver;
    solver.set_local_version_filename (local_file);
    solver.set_remote_version_filename (target);
}

void SocketApi.command_V2_LIST_ACCOUNTS (QSharedPointer<Socket_api_job_v2> &job) {
    QJsonArray out;
    for (auto acc : AccountManager.instance ().accounts ()) {
        // TODO : Use uuid once https://github.com/owncloud/client/pull/8397 is merged
        out << QJsonObject ({
            {
                "name", acc.account ().display_name ()
            },
            {
                "id", acc.account ().id ()
            }
        });
    }
    job.success ({
        {
            "accounts", out
        }
    });
}

void SocketApi.command_V2_UPLOAD_FILES_FROM (QSharedPointer<Socket_api_job_v2> &job) {
    auto upload_job = new Socket_upload_job (job);
    upload_job.start ();
}

void SocketApi.email_private_link (string &link) {
    Utility.open_email_composer (
        tr ("I shared something with you"),
        link,
        nullptr);
}

void Occ.SocketApi.open_private_link (string &link) {
    Utility.open_browser (link);
}

void SocketApi.command_GET_STRINGS (string &argument, Socket_listener *listener) {
    {
        c std.array<std.pair<const char *, QString
        {
            "SHARE_MENU_TITLE", tr ("Share options")
        },
        {
            "FILE_ACTIVITY_MENU_TITLE", tr ("Activity")
        },
        {
            "CONTEXT_MENU_TITLE", Theme.instance ().app_name_g_u_i ()
        },
        {
            "COPY_PRIVATE_LINK_MENU_TITLE", tr ("Copy private link to clipboard")
        },
        {
            "EMAIL_PRIVATE_LINK_MENU_TITLE", tr ("Send private link by email …")
        },
        {
            "CONTEXT_MENU_ICON", APPLICATION_ICON_NAME
        },
    } };
    listener.send_message (string ("GET_STRINGS:BEGIN"));
    for (auto& key_value : strings) {
        if (argument.is_empty () || argument == QLatin1String (key_value.first)) {
            listener.send_message (string ("STRING:%1:%2").arg (key_value.first, key_value.second));
        }
    }
    listener.send_message (string ("GET_STRINGS:END"));
}

void SocketApi.send_sharing_context_menu_options (File_data &file_data, Socket_listener *listener, bool enabled) {
    auto record = file_data.journal_record ();
    bool is_on_the_server = record.is_valid ();
    auto flag_string = is_on_the_server && enabled ? QLatin1String (".") : QLatin1String (":d:");

    auto capabilities = file_data.folder.account_state ().account ().capabilities ();
    auto theme = Theme.instance ();
    if (!capabilities.share_a_p_i () || ! (theme.user_group_sharing () || (theme.link_sharing () && capabilities.share_public_link ())))
        return;

    // If sharing is globally disabled, do not show any sharing entries.
    // If there is no permission to share for this file, add a disabled entry saying so
    if (is_on_the_server && !record._remote_perm.is_null () && !record._remote_perm.has_permission (RemotePermissions.Can_reshare)) {
        listener.send_message (QLatin1String ("MENU_ITEM:DISABLED:d:") + (!record.is_directory () ? tr ("Resharing this file is not allowed") : tr ("Resharing this folder is not allowed")));
    } else {
        listener.send_message (QLatin1String ("MENU_ITEM:SHARE") + flag_string + tr ("Share options"));

        // Do we have public links?
        bool public_links_enabled = theme.link_sharing () && capabilities.share_public_link ();

        // Is is possible to create a public link without user choices?
        bool can_create_default_public_link = public_links_enabled
            && !capabilities.share_public_link_enforce_expire_date ()
            && !capabilities.share_public_link_ask_optional_password ()
            && !capabilities.share_public_link_enforce_password ();

        if (can_create_default_public_link) {
            listener.send_message (QLatin1String ("MENU_ITEM:COPY_PUBLIC_LINK") + flag_string + tr ("Copy public link"));
        } else if (public_links_enabled) {
            listener.send_message (QLatin1String ("MENU_ITEM:MANAGE_PUBLIC_LINKS") + flag_string + tr ("Copy public link"));
        }
    }

    listener.send_message (QLatin1String ("MENU_ITEM:COPY_PRIVATE_LINK") + flag_string + tr ("Copy internal link"));

    // Disabled : only providing email option for private links would look odd,
    // and the copy option is more general.
    //listener.send_message (QLatin1String ("MENU_ITEM:EMAIL_PRIVATE_LINK") + flag_string + tr ("Send private link by email …"));
}

SocketApi.File_data SocketApi.File_data.get (string &local_file) {
    File_data data;

    data.local_path = QDir.clean_path (local_file);
    if (data.local_path.ends_with (QLatin1Char ('/')))
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
    auto result = folder_relative_path;
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
    folder.journal_db ().get_file_record (folder_relative_path, &record);
    return record;
}

SocketApi.File_data SocketApi.File_data.parent_folder () {
    return File_data.get (QFileInfo (local_path).dir ().path ().to_utf8 ());
}

void SocketApi.command_GET_MENU_ITEMS (string &argument, Occ.Socket_listener *listener) {
    listener.send_message (string ("GET_MENU_ITEMS:BEGIN"));
    const QStringList files = split (argument);

    // Find the common sync folder.
    // sync_folder will be null if files are in different folders.
    Folder *sync_folder = nullptr;
    for (auto &file : files) {
        auto folder = FolderMan.instance ().folder_for_path (file);
        if (folder != sync_folder) {
            if (!sync_folder) {
                sync_folder = folder;
            } else {
                sync_folder = nullptr;
                break;
            }
        }
    }

    // Sharing actions show for single files only
    if (sync_folder && files.size () == 1 && sync_folder.account_state ().is_connected ()) {
        string system_path = QDir.clean_path (argument);
        if (system_path.ends_with (QLatin1Char ('/'))) {
            system_path.truncate (system_path.length () - 1);
        }

        File_data file_data = File_data.get (argument);
        const auto record = file_data.journal_record ();
        const bool is_on_the_server = record.is_valid ();
        const auto is_e2e_encrypted_path = file_data.journal_record ()._is_e2e_encrypted || !file_data.journal_record ()._e2e_mangled_name.is_empty ();
        auto flag_string = is_on_the_server && !is_e2e_encrypted_path ? QLatin1String (".") : QLatin1String (":d:");

        const QFileInfo file_info (file_data.local_path);
        if (!file_info.is_dir ()) {
            listener.send_message (QLatin1String ("MENU_ITEM:ACTIVITY") + flag_string + tr ("Activity"));
        }

        DirectEditor* editor = get_direct_editor_for_local_file (file_data.local_path);
        if (editor) {
            //listener.send_message (QLatin1String ("MENU_ITEM:EDIT") + flag_string + tr ("Edit via ") + editor.name ());
            listener.send_message (QLatin1String ("MENU_ITEM:EDIT") + flag_string + tr ("Edit"));
        } else {
            listener.send_message (QLatin1String ("MENU_ITEM:OPEN_PRIVATE_LINK") + flag_string + tr ("Open in browser"));
        }

        send_sharing_context_menu_options (file_data, listener, !is_e2e_encrypted_path);

        // Conflict files get conflict resolution actions
        bool is_conflict = Utility.is_conflict_file (file_data.folder_relative_path);
        if (is_conflict || !is_on_the_server) {
            // Check whether this new file is in a read-only directory
            const auto parent_dir = file_data.parent_folder ();
            const auto parent_record = parent_dir.journal_record ();
            const bool can_add_to_dir =
                !parent_record.is_valid () // We're likely at the root of the sync folder, got to assume we can add there
                || (file_info.is_file () && parent_record._remote_perm.has_permission (RemotePermissions.Can_add_file))
                || (file_info.is_dir () && parent_record._remote_perm.has_permission (RemotePermissions.Can_add_sub_directories));
            const bool can_change_file =
                !is_on_the_server
                || (record._remote_perm.has_permission (RemotePermissions.Can_delete)
                       && record._remote_perm.has_permission (RemotePermissions.Can_move)
                       && record._remote_perm.has_permission (RemotePermissions.Can_rename));

            if (is_conflict && can_change_file) {
                if (can_add_to_dir) {
                    listener.send_message (QLatin1String ("MENU_ITEM:RESOLVE_CONFLICT.") + tr ("Resolve conflict …"));
                } else {
                    if (is_on_the_server) {
                        // Uploaded conflict file in read-only directory
                        listener.send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move and rename …"));
                    } else {
                        // Local-only conflict file in a read-only dir
                        listener.send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move, rename and upload …"));
                    }
                    listener.send_message (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + tr ("Delete local changes"));
                }
            }

            // File in a read-only directory?
            if (!is_conflict && !is_on_the_server && !can_add_to_dir) {
                listener.send_message (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move and upload …"));
                listener.send_message (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + tr ("Delete"));
            }
        }
    }

    // File availability actions
    if (sync_folder
        && sync_folder.virtual_files_enabled ()
        && sync_folder.vfs ().socket_api_pin_state_actions_shown ()) {
        ENFORCE (!files.is_empty ());

        // Determine the combined availability status of the files
        auto combined = Optional<VfsItemAvailability> ();
        auto merge = [] (VfsItemAvailability lhs, VfsItemAvailability rhs) {
            if (lhs == rhs)
                return lhs;
            if (int (lhs) > int (rhs))
                std.swap (lhs, rhs); // reduce cases ensuring lhs < rhs
            if (lhs == VfsItemAvailability.AlwaysLocal && rhs == VfsItemAvailability.AllHydrated)
                return VfsItemAvailability.AllHydrated;
            if (lhs == VfsItemAvailability.AllDehydrated && rhs == VfsItemAvailability.OnlineOnly)
                return VfsItemAvailability.AllDehydrated;
            return VfsItemAvailability.Mixed;
        };
        for (auto &file : files) {
            auto file_data = File_data.get (file);
            auto availability = sync_folder.vfs ().availability (file_data.folder_relative_path);
            if (!availability) {
                if (availability.error () == Vfs.AvailabilityError.DbError)
                    availability = VfsItemAvailability.Mixed;
                if (availability.error () == Vfs.AvailabilityError.NoSuchItem)
                    continue;
            }
            if (!combined) {
                combined = *availability;
            } else {
                combined = merge (*combined, *availability);
            }
        }

        // TODO : Should be a submenu, should use icons
        auto make_pin_context_menu = [&] (bool make_available_locally, bool free_space) {
            listener.send_message (QLatin1String ("MENU_ITEM:CURRENT_PIN:d:")
                + Utility.vfs_current_availability_text (*combined));
            if (!Theme.instance ().enforce_virtual_files_sync_folder ()) {
                listener.send_message (QLatin1String ("MENU_ITEM:MAKE_AVAILABLE_LOCALLY:")
                    + (make_available_locally ? QLatin1String (":") : QLatin1String ("d:")) + Utility.vfs_pin_action_text ());
            }

            listener.send_message (QLatin1String ("MENU_ITEM:MAKE_ONLINE_ONLY:")
                + (free_space ? QLatin1String (":") : QLatin1String ("d:"))
                + Utility.vfs_free_space_action_text ());
        };

        if (combined) {
            switch (*combined) {
            case VfsItemAvailability.AlwaysLocal:
                make_pin_context_menu (false, true);
                break;
            case VfsItemAvailability.AllHydrated:
            case VfsItemAvailability.Mixed:
                make_pin_context_menu (true, true);
                break;
            case VfsItemAvailability.AllDehydrated:
            case VfsItemAvailability.OnlineOnly:
                make_pin_context_menu (true, false);
                break;
            }
        }
    }

    listener.send_message (string ("GET_MENU_ITEMS:END"));
}

DirectEditor* SocketApi.get_direct_editor_for_local_file (string &local_file) {
    File_data file_data = File_data.get (local_file);
    auto capabilities = file_data.folder.account_state ().account ().capabilities ();

    if (file_data.folder && file_data.folder.account_state ().is_connected ()) {
        const auto record = file_data.journal_record ();
        const auto mime_match_mode = record.is_virtual_file () ? QMimeDatabase.Match_extension : QMimeDatabase.Match_default;

        QMimeDatabase db;
        QMimeType type = db.mime_type_for_file (local_file, mime_match_mode);

        DirectEditor* editor = capabilities.get_direct_editor_for_mimetype (type);
        if (!editor) {
            editor = capabilities.get_direct_editor_for_optional_mimetype (type);
        }
        return editor;
    }

    return nullptr;
}

#if GUI_TESTING
void SocketApi.command_ASYNC_LIST_WIDGETS (QSharedPointer<Socket_api_job> &job) {
    string response;
    for (auto &widget : all_objects (QApplication.all_widgets ())) {
        auto object_name = widget.object_name ();
        if (!object_name.is_empty ()) {
            response += object_name + ":" + widget.property ("text").to_string () + ", ";
        }
    }
    job.resolve (response);
}

void SocketApi.command_ASYNC_INVOKE_WIDGET_METHOD (QSharedPointer<Socket_api_job> &job) {
    auto &arguments = job.arguments ();

    auto widget = find_widget (arguments["object_name"].to_string ());
    if (!widget) {
        job.reject (QLatin1String ("widget not found"));
        return;
    }

    QMetaObject.invoke_method (widget, arguments["method"].to_string ().to_utf8 ().const_data ());
    job.resolve ();
}

void SocketApi.command_ASYNC_GET_WIDGET_PROPERTY (QSharedPointer<Socket_api_job> &job) {
    string widget_name = job.arguments ()[QLatin1String ("object_name")].to_string ();
    auto widget = find_widget (widget_name);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 2 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }

    auto property_name = job.arguments ()[QLatin1String ("property")].to_string ();

    auto segments = property_name.split ('.');

    GLib.Object *current_object = widget;
    string value;
    for (int i = 0; i < segments.count (); i++) {
        auto segment = segments.at (i);
        auto var = current_object.property (segment.to_utf8 ().const_data ());

        if (var.can_convert<string> ()) {
            var.convert (QMetaType.string);
            value = var.value<string> ();
            break;
        }

        auto tmp_object = var.value<GLib.Object> ();
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

void SocketApi.command_ASYNC_SET_WIDGET_PROPERTY (QSharedPointer<Socket_api_job> &job) {
    auto &arguments = job.arguments ();
    string widget_name = arguments["object_name"].to_string ();
    auto widget = find_widget (widget_name);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 4 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }
    widget.set_property (arguments["property"].to_string ().to_utf8 ().const_data (),
        arguments["value"]);

    job.resolve ();
}

void SocketApi.command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (QSharedPointer<Socket_api_job> &job) {
    auto &arguments = job.arguments ();
    string widget_name = arguments["object_name"].to_string ();
    auto widget = find_widget (arguments["object_name"].to_string ());
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 5 : %1")).arg (widget_name);
        job.reject (message);
        return;
    }

    Listener_closure *closure = new Listener_closure ([job] () {
        job.resolve ("signal emitted");
    });

    auto signal_signature = arguments["signal_signature"].to_string ();
    signal_signature.prepend ("2");
    auto utf8 = signal_signature.to_utf8 ();
    auto signal_signature_final = utf8.const_data ();
    connect (widget, signal_signature_final, closure, SLOT (closure_slot ()), Qt.QueuedConnection);
}

void SocketApi.command_ASYNC_TRIGGER_MENU_ACTION (QSharedPointer<Socket_api_job> &job) {
    auto &arguments = job.arguments ();

    auto object_name = arguments["object_name"].to_string ();
    auto widget = find_widget (object_name);
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 1 : %1")).arg (object_name);
        job.reject (message);
        return;
    }

    auto children = widget.find_children<Gtk.Widget> ();
    for (auto child_widget : children) {
        // foo is the popupwidget!
        auto actions = child_widget.actions ();
        for (auto action : actions) {
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

void SocketApi.command_ASYNC_ASSERT_ICON_IS_EQUAL (QSharedPointer<Socket_api_job> &job) {
    auto widget = find_widget (job.arguments ()[QLatin1String ("query_string")].to_string ());
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 6 : %1")).arg (job.arguments ()["query_string"].to_string ());
        job.reject (message);
        return;
    }

    auto property_name = job.arguments ()[QLatin1String ("property_path")].to_string ();

    auto segments = property_name.split ('.');

    GLib.Object *current_object = widget;
    QIcon value;
    for (int i = 0; i < segments.count (); i++) {
        auto segment = segments.at (i);
        auto var = current_object.property (segment.to_utf8 ().const_data ());

        if (var.can_convert<QIcon> ()) {
            var.convert (QMetaType.QIcon);
            value = var.value<QIcon> ();
            break;
        }

        auto tmp_object = var.value<GLib.Object> ();
        if (tmp_object) {
            current_object = tmp_object;
        } else {
            job.reject (string (QLatin1String ("Icon not found : %1")).arg (property_name));
        }
    }

    auto icon_name = job.arguments ()[QLatin1String ("icon_name")].to_string ();
    if (value.name () == icon_name) {
        job.resolve ();
    } else {
        job.reject ("icon_name " + icon_name + " does not match : " + value.name ());
    }
}
#endif

string SocketApi.build_register_path_message (string &path) {
    QFileInfo fi (path);
    string message = QLatin1String ("REGISTER_PATH:");
    message.append (QDir.to_native_separators (fi.absolute_file_path ()));
    return message;
}

void Socket_api_job.resolve (string &response) {
    _socket_listener.send_message (QStringLiteral ("RESOLVE|") + _job_id + QLatin1Char ('|') + response);
}

void Socket_api_job.resolve (QJsonObject &response) {
    resolve (QJsonDocument {
        response
    }.to_json ());
}

void Socket_api_job.reject (string &response) {
    _socket_listener.send_message (QStringLiteral ("REJECT|") + _job_id + QLatin1Char ('|') + response);
}

Socket_api_job_v2.Socket_api_job_v2 (QSharedPointer<Socket_listener> &socket_listener, QByteArray &command, QJsonObject &arguments)
    : _socket_listener (socket_listener)
    , _command (command)
    , _job_id (arguments[QStringLiteral ("id")].to_string ())
    , _arguments (arguments[QStringLiteral ("arguments")].to_object ()) {
    ASSERT (!_job_id.is_empty ())
}

void Socket_api_job_v2.success (QJsonObject &response) {
    do_finish (response);
}

void Socket_api_job_v2.failure (string &error) {
    do_finish ({
        {
            QStringLiteral ("error"), error
        }
    });
}

void Socket_api_job_v2.do_finish (QJsonObject &obj) {
    _socket_listener.send_message (_command + QStringLiteral ("_RESULT:") + QJsonDocument ({
        {
            QStringLiteral ("id"), _job_id
        },
        {
            QStringLiteral ("arguments"), obj
        }
    }).to_json (QJsonDocument.Compact));
    Q_EMIT finished ();
}


    class Bloom_filter {
        // Initialize with m=1024 bits and k=2 (high and low 16 bits of a q_hash).
        // For a client navigating in less than 100 directories, this gives us a probability less than
        // (1-e^ (-2*100/1024))^2 = 0.03147872136 false positives.
        const static int Num_bits = 1024;

        public Bloom_filter ()
            : hash_bits (Num_bits) {
        }

        public void store_hash (uint hash) {
            hash_bits.set_bit ( (hash & 0x_f_f_f_f) % Num_bits); // NOLINT it's uint all the way and the modulo puts us back in the 0..1023 range
            hash_bits.set_bit ( (hash >> 16) % Num_bits); // NOLINT
        }
        public bool is_hash_maybe_stored (uint hash) {
            return hash_bits.test_bit ( (hash & 0x_f_f_f_f) % Num_bits) // NOLINT
                && hash_bits.test_bit ( (hash >> 16) % Num_bits); // NOLINT
        }

    private:
        QBit_array hash_bits;
    };

    class Socket_listener {

        public QPointer<QIODevice> socket;

        public Socket_listener (QIODevice *_socket)
            : socket (_socket) {
        }

        public void send_message (string &message, bool do_wait = false) const;
        public void send_warning (string &message, bool do_wait = false) {
            send_message (QStringLiteral ("WARNING:") + message, do_wait);
        }
        public void send_error (string &message, bool do_wait = false) {
            send_message (QStringLiteral ("ERROR:") + message, do_wait);
        }

        public void send_message_if_directory_monitored (string &message, uint system_directory_hash) {
            if (_monitored_directories_bloom_filter.is_hash_maybe_stored (system_directory_hash))
                send_message (message, false);
        }

        public void register_monitored_directory (uint system_directory_hash) {
            _monitored_directories_bloom_filter.store_hash (system_directory_hash);
        }

    private:
        Bloom_filter _monitored_directories_bloom_filter;
    };

    class Listener_closure : GLib.Object {

        public using Callback_function = std.function<void ()>;
        public Listener_closure (Callback_function callback)
            : callback_ (callback) {
        }

    public slots:
        void closure_slot () {
            callback_ ();
            delete_later ();
        }

    private:
        Callback_function callback_;
    };

    class Socket_api_job : GLib.Object {

        public Socket_api_job (string &job_id, QSharedPointer<Socket_listener> &socket_listener, QJsonObject &arguments)
            : _job_id (job_id)
            , _socket_listener (socket_listener)
            , _arguments (arguments) {
        }

        public void resolve (string &response = string ());

        public void resolve (QJsonObject &response);

        public const QJsonObject &arguments () {
            return _arguments;
        }

        public void reject (string &response);

    protected:
        string _job_id;
        QSharedPointer<Socket_listener> _socket_listener;
        QJsonObject _arguments;
    };

    class Socket_api_job_v2 : GLib.Object {

        public Socket_api_job_v2 (QSharedPointer<Socket_listener> &socket_listener, QByteArray &command, QJsonObject &arguments);

        public void success (QJsonObject &response) const;
        public void failure (string &error) const;

        public const QJsonObject &arguments () {
            return _arguments;
        }
        public QByteArray command () {
            return _command;
        }

    signals:
        void finished ();

    private:
        void do_finish (QJsonObject &obj) const;

        QSharedPointer<Socket_listener> _socket_listener;
        const QByteArray _command;
        string _job_id;
        QJsonObject _arguments;
    };
}
