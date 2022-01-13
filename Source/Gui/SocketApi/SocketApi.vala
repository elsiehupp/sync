/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <functional>
// #include <QBitArray>
// #include <QPointer>

// #include <QJsonDocument>
// #include <QJsonObject>

// #include <memory>
// #include <QTimer>

#ifndef OWNCLOUD_TEST
#endif

// #include <array>
// #include <QBitArray>
// #include <QUrl>
// #include <QMetaMethod>
// #include <QMetaObject>
// #include <QStringList>
// #include <QScopedPointer>
// #include <QFile>
// #include <QDir>
// #include <QApplication>
// #include <QLocalSocket>
// #include <QStringBuilder>
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

#include "sharedialog.h" // for the ShareDialogStartPage

// #include <QLocalServer>
using SocketApiServer = QLocalServer;


namespace Occ {

class DirectEditor;

Q_DECLARE_LOGGING_CATEGORY (lcSocketApi)

/***********************************************************
@brief The SocketApi class
@ingroup gui
***********************************************************/
class SocketApi : GLib.Object {

public:
    SocketApi (GLib.Object *parent = nullptr);
    ~SocketApi () override;

public slots:
    void slotUpdateFolderView (Folder *f);
    void slotUnregisterPath (string &alias);
    void slotRegisterPath (string &alias);
    void broadcastStatusPushMessage (string &systemPath, SyncFileStatus fileStatus);

signals:
    void shareCommandReceived (string &sharePath, string &localPath, ShareDialogStartPage startPage);
    void fileActivityCommandReceived (string &sharePath, string &localPath);

private slots:
    void slotNewConnection ();
    void onLostConnection ();
    void slotSocketDestroyed (GLib.Object *obj);
    void slotReadSocket ();

    static void copyUrlToClipboard (string &link);
    static void emailPrivateLink (string &link);
    static void openPrivateLink (string &link);

private:
    // Helper structure for getting information on a file
    // based on its local path - used for nearly all remote
    // actions.
    struct FileData {
        static FileData get (string &localFile);
        SyncFileStatus syncFileStatus ();
        SyncJournalFileRecord journalRecord ();
        FileData parentFolder ();

        // Relative path of the file locally, without any vfs suffix
        string folderRelativePathNoVfsSuffix ();

        Folder *folder;
        // Absolute path of the file locally. (May be a virtual file)
        string localPath;
        // Relative path of the file locally, as in the DB. (May be a virtual file)
        string folderRelativePath;
        // Path of the file on the server (In case of virtual file, it points to the actual file)
        string serverRelativePath;
    };

    void broadcastMessage (string &msg, bool doWait = false);

    // opens share dialog, sends reply
    void processShareRequest (string &localFile, SocketListener *listener, ShareDialogStartPage startPage);
    void processFileActivityRequest (string &localFile);

    Q_INVOKABLE void command_RETRIEVE_FOLDER_STATUS (string &argument, SocketListener *listener);
    Q_INVOKABLE void command_RETRIEVE_FILE_STATUS (string &argument, SocketListener *listener);

    Q_INVOKABLE void command_VERSION (string &argument, SocketListener *listener);

    Q_INVOKABLE void command_SHARE_MENU_TITLE (string &argument, SocketListener *listener);

    // The context menu actions
    Q_INVOKABLE void command_ACTIVITY (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_SHARE (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MANAGE_PUBLIC_LINKS (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_COPY_PUBLIC_LINK (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_COPY_PRIVATE_LINK (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_EMAIL_PRIVATE_LINK (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_OPEN_PRIVATE_LINK (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MAKE_AVAILABLE_LOCALLY (string &filesArg, SocketListener *listener);
    Q_INVOKABLE void command_MAKE_ONLINE_ONLY (string &filesArg, SocketListener *listener);
    Q_INVOKABLE void command_RESOLVE_CONFLICT (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_DELETE_ITEM (string &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MOVE_ITEM (string &localFile, SocketListener *listener);

    // External sync
    Q_INVOKABLE void command_V2_LIST_ACCOUNTS (QSharedPointer<SocketApiJobV2> &job) const;
    Q_INVOKABLE void command_V2_UPLOAD_FILES_FROM (QSharedPointer<SocketApiJobV2> &job) const;

    // Fetch the private link and call targetFun
    void fetchPrivateLinkUrlHelper (string &localFile, std.function<void (string &url)> &targetFun);

    /***********************************************************
    Sends translated/branded strings that may be useful to the integration */
    Q_INVOKABLE void command_GET_STRINGS (string &argument, SocketListener *listener);

    // Sends the context menu options relating to sharing to listener
    void sendSharingContextMenuOptions (FileData &fileData, SocketListener *listener, bool enabled);

    /***********************************************************
    Send the list of menu item. (added in version 1.1)
    argument is a list of files for which the menu should be shown, separated by '\x1e'
    Reply with  GET_MENU_ITEMS:BEGIN
    followed by several MENU_ITEM:[Action]:[flag]:[Text]
    If flag contains 'd', the menu should be disabled
    and ends with GET_MENU_ITEMS:END
    ***********************************************************/
    Q_INVOKABLE void command_GET_MENU_ITEMS (string &argument, SocketListener *listener);

    /// Direct Editing
    Q_INVOKABLE void command_EDIT (string &localFile, SocketListener *listener);
    DirectEditor* getDirectEditorForLocalFile (string &localFile);

#if GUI_TESTING
    Q_INVOKABLE void command_ASYNC_ASSERT_ICON_IS_EQUAL (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_LIST_WIDGETS (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_INVOKE_WIDGET_METHOD (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_GET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_SET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_TRIGGER_MENU_ACTION (QSharedPointer<SocketApiJob> &job);
#endif

    string buildRegisterPathMessage (string &path);

    QSet<string> _registeredAliases;
    QMap<QIODevice *, QSharedPointer<SocketListener>> _listeners;
    SocketApiServer _localServer;
};
}













namespace {

const QLatin1Char RecordSeparator () {
    return QLatin1Char ('\x1e');
}

QStringList split (string &data) {
    // TODO : string ref?
    return data.split (RecordSeparator ());
}

#if GUI_TESTING

using namespace Occ;

QList<GLib.Object> allObjects (QList<Gtk.Widget> &widgets) {
    QList<GLib.Object> objects;
    std.copy (widgets.constBegin (), widgets.constEnd (), std.back_inserter (objects));

    objects << qApp;

    return objects;
}

GLib.Object *findWidget (string &queryString, QList<Gtk.Widget> &widgets = QApplication.allWidgets ()) {
    auto objects = allObjects (widgets);

    QList<GLib.Object>.const_iterator foundWidget;

    if (queryString.contains ('>')) {
        qCDebug (lcSocketApi) << "queryString contains >";

        auto subQueries = queryString.split ('>', string.SkipEmptyParts);
        Q_ASSERT (subQueries.count () == 2);

        auto parentQueryString = subQueries[0].trimmed ();
        qCDebug (lcSocketApi) << "Find parent : " << parentQueryString;
        auto parent = findWidget (parentQueryString);

        if (!parent) {
            return nullptr;
        }

        auto childQueryString = subQueries[1].trimmed ();
        auto child = findWidget (childQueryString, parent.findChildren<Gtk.Widget> ());
        qCDebug (lcSocketApi) << "found child : " << !!child;
        return child;

    } else if (queryString.startsWith ('#')) {
        auto objectName = queryString.mid (1);
        qCDebug (lcSocketApi) << "find objectName : " << objectName;
        foundWidget = std.find_if (objects.constBegin (), objects.constEnd (), [&] (GLib.Object *widget) {
            return widget.objectName () == objectName;
        });
    } else {
        QList<GLib.Object> matches;
        std.copy_if (objects.constBegin (), objects.constEnd (), std.back_inserter (matches), [&] (GLib.Object *widget) {
            return widget.inherits (queryString.toLatin1 ());
        });

        std.for_each (matches.constBegin (), matches.constEnd (), [] (GLib.Object *w) {
            if (!w)
                return;
            qCDebug (lcSocketApi) << "WIDGET : " << w.objectName () << w.metaObject ().className ();
        });

        if (matches.empty ()) {
            return nullptr;
        }
        return matches[0];
    }

    if (foundWidget == objects.constEnd ()) {
        return nullptr;
    }

    return *foundWidget;
}
#endif

static inline string removeTrailingSlash (string path) {
    Q_ASSERT (path.endsWith (QLatin1Char ('/')));
    path.truncate (path.length () - 1);
    return path;
}

static string buildMessage (string &verb, string &path, string &status = string ()) {
    string msg (verb);

    if (!status.isEmpty ()) {
        msg.append (QLatin1Char (':'));
        msg.append (status);
    }
    if (!path.isEmpty ()) {
        msg.append (QLatin1Char (':'));
        QFileInfo fi (path);
        msg.append (QDir.toNativeSeparators (fi.absoluteFilePath ()));
    }
    return msg;
}

void SocketListener.sendMessage (string &message, bool doWait) {
    if (!socket) {
        qCWarning (lcSocketApi) << "Not sending message to dead socket:" << message;
        return;
    }

    qCDebug (lcSocketApi) << "Sending SocketAPI message -." << message << "to" << socket;
    string localMessage = message;
    if (!localMessage.endsWith (QLatin1Char ('\n'))) {
        localMessage.append (QLatin1Char ('\n'));
    }

    QByteArray bytesToSend = localMessage.toUtf8 ();
    int64 sent = socket.write (bytesToSend);
    if (doWait) {
        socket.waitForBytesWritten (1000);
    }
    if (sent != bytesToSend.length ()) {
        qCWarning (lcSocketApi) << "Could not send all data on socket for " << localMessage;
    }
}

SocketApi.SocketApi (GLib.Object *parent)
    : GLib.Object (parent) {
    string socketPath;

    qRegisterMetaType<SocketListener> ("SocketListener*");
    qRegisterMetaType<QSharedPointer<SocketApiJob>> ("QSharedPointer<SocketApiJob>");
    qRegisterMetaType<QSharedPointer<SocketApiJobV2>> ("QSharedPointer<SocketApiJobV2>");

    if (Utility.isWindows ()) {
        socketPath = QLatin1String (R" (\\.\pipe\)")
            + QLatin1String (APPLICATION_EXECUTABLE)
            + QLatin1String ("-")
            + string.fromLocal8Bit (qgetenv ("USERNAME"));
        // TODO : once the windows extension supports multiple
        // client connections, switch back to the theme name
        // See issue #2388
        // + Theme.instance ().appName ();
    } else if (Utility.isMac ()) {
        // This must match the code signing Team setting of the extension
        // Example for developer builds (with ad-hoc signing identity) : "" "com.owncloud.desktopclient" ".socketApi"
        // Example for official signed packages : "9B5WD74GWJ." "com.owncloud.desktopclient" ".socketApi"
        socketPath = SOCKETAPI_TEAM_IDENTIFIER_PREFIX APPLICATION_REV_DOMAIN ".socketApi";
    } else if (Utility.isLinux () || Utility.isBSD ()) {
        string runtimeDir;
        runtimeDir = QStandardPaths.writableLocation (QStandardPaths.RuntimeLocation);
        socketPath = runtimeDir + "/" + Theme.instance ().appName () + "/socket";
    } else {
        qCWarning (lcSocketApi) << "An unexpected system detected, this probably won't work.";
    }

    SocketApiServer.removeServer (socketPath);
    QFileInfo info (socketPath);
    if (!info.dir ().exists ()) {
        bool result = info.dir ().mkpath (".");
        qCDebug (lcSocketApi) << "creating" << info.dir ().path () << result;
        if (result) {
            QFile.setPermissions (socketPath,
                QFile.Permissions (QFile.ReadOwner + QFile.WriteOwner + QFile.ExeOwner));
        }
    }
    if (!_localServer.listen (socketPath)) {
        qCWarning (lcSocketApi) << "can't start server" << socketPath;
    } else {
        qCInfo (lcSocketApi) << "server started, listening at " << socketPath;
    }

    connect (&_localServer, &SocketApiServer.newConnection, this, &SocketApi.slotNewConnection);

    // folder watcher
    connect (FolderMan.instance (), &FolderMan.folderSyncStateChange, this, &SocketApi.slotUpdateFolderView);
}

SocketApi.~SocketApi () {
    qCDebug (lcSocketApi) << "dtor";
    _localServer.close ();
    // All remaining sockets will be destroyed with _localServer, their parent
    ASSERT (_listeners.isEmpty () || _listeners.first ().socket.parent () == &_localServer)
    _listeners.clear ();
}

void SocketApi.slotNewConnection () {
    // Note that on macOS this is not actually a line-based QIODevice, it's a SocketApiSocket which is our
    // custom message based macOS IPC.
    QIODevice *socket = _localServer.nextPendingConnection ();

    if (!socket) {
        return;
    }
    qCInfo (lcSocketApi) << "New connection" << socket;
    connect (socket, &QIODevice.readyRead, this, &SocketApi.slotReadSocket);
    connect (socket, SIGNAL (disconnected ()), this, SLOT (onLostConnection ()));
    connect (socket, &GLib.Object.destroyed, this, &SocketApi.slotSocketDestroyed);
    ASSERT (socket.readAll ().isEmpty ());

    auto listener = QSharedPointer<SocketListener>.create (socket);
    _listeners.insert (socket, listener);
    for (Folder *f : FolderMan.instance ().map ()) {
        if (f.canSync ()) {
            string message = buildRegisterPathMessage (removeTrailingSlash (f.path ()));
            qCInfo (lcSocketApi) << "Trying to send SocketAPI Register Path Message -." << message << "to" << listener.socket;
            listener.sendMessage (message);
        }
    }
}

void SocketApi.onLostConnection () {
    qCInfo (lcSocketApi) << "Lost connection " << sender ();
    sender ().deleteLater ();

    auto socket = qobject_cast<QIODevice> (sender ());
    ASSERT (socket);
    _listeners.remove (socket);
}

void SocketApi.slotSocketDestroyed (GLib.Object *obj) {
    auto *socket = static_cast<QIODevice> (obj);
    _listeners.remove (socket);
}

void SocketApi.slotReadSocket () {
    auto *socket = qobject_cast<QIODevice> (sender ());
    ASSERT (socket);

    // Find the SocketListener
    //
    // It's possible for the disconnected () signal to be triggered before
    // the readyRead () signals are received - in that case there won't be a
    // valid listener. We execute the handler anyway, but it will work with
    // a SocketListener that doesn't send any messages.
    static auto invalidListener = QSharedPointer<SocketListener>.create (nullptr);
    const auto listener = _listeners.value (socket, invalidListener);
    while (socket.canReadLine ()) {
        // Make sure to normalize the input from the socket to
        // make sure that the path will match, especially on OS X.
        const string line = string.fromUtf8 (socket.readLine ().trimmed ()).normalized (string.NormalizationForm_C);
        qCInfo (lcSocketApi) << "Received SocketAPI message <--" << line << "from" << socket;
        const int argPos = line.indexOf (QLatin1Char (':'));
        const QByteArray command = line.midRef (0, argPos).toUtf8 ().toUpper ();
        const int indexOfMethod = [&] {
            QByteArray functionWithArguments = QByteArrayLiteral ("command_");
            if (command.startsWith ("ASYNC_")) {
                functionWithArguments += command + QByteArrayLiteral (" (QSharedPointer<SocketApiJob>)");
            } else if (command.startsWith ("V2/")) {
                functionWithArguments += QByteArrayLiteral ("V2_") + command.mid (3) + QByteArrayLiteral (" (QSharedPointer<SocketApiJobV2>)");
            } else {
                functionWithArguments += command + QByteArrayLiteral (" (string,SocketListener*)");
            }
            Q_ASSERT (staticQtMetaObject.normalizedSignature (functionWithArguments) == functionWithArguments);
            const auto out = staticMetaObject.indexOfMethod (functionWithArguments);
            if (out == -1) {
                listener.sendError (QStringLiteral ("Function %1 not found").arg (string.fromUtf8 (functionWithArguments)));
            }
            ASSERT (out != -1)
            return out;
        } ();

        const auto argument = argPos != -1 ? line.midRef (argPos + 1) : QStringRef ();
        if (command.startsWith ("ASYNC_")) {
            auto arguments = argument.split ('|');
            if (arguments.size () != 2) {
                listener.sendError (QStringLiteral ("argument count is wrong"));
                return;
            }

            auto json = QJsonDocument.fromJson (arguments[1].toUtf8 ()).object ();

            auto jobId = arguments[0];

            auto socketApiJob = QSharedPointer<SocketApiJob> (
                new SocketApiJob (jobId.toString (), listener, json), &GLib.Object.deleteLater);
            if (indexOfMethod != -1) {
                staticMetaObject.method (indexOfMethod)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (QSharedPointer<SocketApiJob>, socketApiJob));
            } else {
                qCWarning (lcSocketApi) << "The command is not supported by this version of the client:" << command
                                       << "with argument:" << argument;
                socketApiJob.reject (QStringLiteral ("command not found"));
            }
        } else if (command.startsWith ("V2/")) {
            QJsonParseError error;
            const auto json = QJsonDocument.fromJson (argument.toUtf8 (), &error).object ();
            if (error.error != QJsonParseError.NoError) {
                qCWarning (lcSocketApi ()) << "Invalid json" << argument.toString () << error.errorString ();
                listener.sendError (error.errorString ());
                return;
            }
            auto socketApiJob = QSharedPointer<SocketApiJobV2>.create (listener, command, json);
            if (indexOfMethod != -1) {
                staticMetaObject.method (indexOfMethod)
                    .invoke (this, Qt.QueuedConnection,
                        Q_ARG (QSharedPointer<SocketApiJobV2>, socketApiJob));
            } else {
                qCWarning (lcSocketApi) << "The command is not supported by this version of the client:" << command
                                       << "with argument:" << argument;
                socketApiJob.failure (QStringLiteral ("command not found"));
            }
        } else {
            if (indexOfMethod != -1) {
                // to ensure that listener is still valid we need to call it with Qt.DirectConnection
                ASSERT (thread () == QThread.currentThread ())
                staticMetaObject.method (indexOfMethod)
                    .invoke (this, Qt.DirectConnection, Q_ARG (string, argument.toString ()),
                        Q_ARG (SocketListener *, listener.data ()));
            }
        }
    }
}

void SocketApi.slotRegisterPath (string &alias) {
    // Make sure not to register twice to each connected client
    if (_registeredAliases.contains (alias))
        return;

    Folder *f = FolderMan.instance ().folder (alias);
    if (f) {
        const string message = buildRegisterPathMessage (removeTrailingSlash (f.path ()));
        for (auto &listener : qAsConst (_listeners)) {
            qCInfo (lcSocketApi) << "Trying to send SocketAPI Register Path Message -." << message << "to" << listener.socket;
            listener.sendMessage (message);
        }
    }

    _registeredAliases.insert (alias);
}

void SocketApi.slotUnregisterPath (string &alias) {
    if (!_registeredAliases.contains (alias))
        return;

    Folder *f = FolderMan.instance ().folder (alias);
    if (f)
        broadcastMessage (buildMessage (QLatin1String ("UNREGISTER_PATH"), removeTrailingSlash (f.path ()), string ()), true);

    _registeredAliases.remove (alias);
}

void SocketApi.slotUpdateFolderView (Folder *f) {
    if (_listeners.isEmpty ()) {
        return;
    }

    if (f) {
        // do only send UPDATE_VIEW for a couple of status
        if (f.syncResult ().status () == SyncResult.SyncPrepare
            || f.syncResult ().status () == SyncResult.Success
            || f.syncResult ().status () == SyncResult.Paused
            || f.syncResult ().status () == SyncResult.Problem
            || f.syncResult ().status () == SyncResult.Error
            || f.syncResult ().status () == SyncResult.SetupError) {
            string rootPath = removeTrailingSlash (f.path ());
            broadcastStatusPushMessage (rootPath, f.syncEngine ().syncFileStatusTracker ().fileStatus (""));

            broadcastMessage (buildMessage (QLatin1String ("UPDATE_VIEW"), rootPath));
        } else {
            qCDebug (lcSocketApi) << "Not sending UPDATE_VIEW for" << f.alias () << "because status () is" << f.syncResult ().status ();
        }
    }
}

void SocketApi.broadcastMessage (string &msg, bool doWait) {
    for (auto &listener : qAsConst (_listeners)) {
        listener.sendMessage (msg, doWait);
    }
}

void SocketApi.processFileActivityRequest (string &localFile) {
    const auto fileData = FileData.get (localFile);
    emit fileActivityCommandReceived (fileData.serverRelativePath, fileData.localPath);
}

void SocketApi.processShareRequest (string &localFile, SocketListener *listener, ShareDialogStartPage startPage) {
    auto theme = Theme.instance ();

    auto fileData = FileData.get (localFile);
    auto shareFolder = fileData.folder;
    if (!shareFolder) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.toNativeSeparators (localFile);
        // files that are not within a sync folder are not synced.
        listener.sendMessage (message);
    } else if (!shareFolder.accountState ().isConnected ()) {
        const string message = QLatin1String ("SHARE:NOTCONNECTED:") + QDir.toNativeSeparators (localFile);
        // if the folder isn't connected, don't open the share dialog
        listener.sendMessage (message);
    } else if (!theme.linkSharing () && (!theme.userGroupSharing () || shareFolder.accountState ().account ().serverVersionInt () < Account.makeServerVersion (8, 2, 0))) {
        const string message = QLatin1String ("SHARE:NOP:") + QDir.toNativeSeparators (localFile);
        listener.sendMessage (message);
    } else {
        // If the file doesn't have a journal record, it might not be uploaded yet
        if (!fileData.journalRecord ().isValid ()) {
            const string message = QLatin1String ("SHARE:NOTSYNCED:") + QDir.toNativeSeparators (localFile);
            listener.sendMessage (message);
            return;
        }

        auto &remotePath = fileData.serverRelativePath;

        // Can't share root folder
        if (remotePath == "/") {
            const string message = QLatin1String ("SHARE:CANNOTSHAREROOT:") + QDir.toNativeSeparators (localFile);
            listener.sendMessage (message);
            return;
        }

        const string message = QLatin1String ("SHARE:OK:") + QDir.toNativeSeparators (localFile);
        listener.sendMessage (message);

        emit shareCommandReceived (remotePath, fileData.localPath, startPage);
    }
}

void SocketApi.broadcastStatusPushMessage (string &systemPath, SyncFileStatus fileStatus) {
    string msg = buildMessage (QLatin1String ("STATUS"), systemPath, fileStatus.toSocketAPIString ());
    Q_ASSERT (!systemPath.endsWith ('/'));
    uint directoryHash = qHash (systemPath.left (systemPath.lastIndexOf ('/')));
    for (auto &listener : qAsConst (_listeners)) {
        listener.sendMessageIfDirectoryMonitored (msg, directoryHash);
    }
}

void SocketApi.command_RETRIEVE_FOLDER_STATUS (string &argument, SocketListener *listener) {
    // This command is the same as RETRIEVE_FILE_STATUS
    command_RETRIEVE_FILE_STATUS (argument, listener);
}

void SocketApi.command_RETRIEVE_FILE_STATUS (string &argument, SocketListener *listener) {
    string statusString;

    auto fileData = FileData.get (argument);
    if (!fileData.folder) {
        // this can happen in offline mode e.g. : nothing to worry about
        statusString = QLatin1String ("NOP");
    } else {
        // The user probably visited this directory in the file shell.
        // Let the listener know that it should now send status pushes for sibblings of this file.
        string directory = fileData.localPath.left (fileData.localPath.lastIndexOf ('/'));
        listener.registerMonitoredDirectory (qHash (directory));

        SyncFileStatus fileStatus = fileData.syncFileStatus ();
        statusString = fileStatus.toSocketAPIString ();
    }

    const string message = QLatin1String ("STATUS:") % statusString % QLatin1Char (':') % QDir.toNativeSeparators (argument);
    listener.sendMessage (message);
}

void SocketApi.command_SHARE (string &localFile, SocketListener *listener) {
    processShareRequest (localFile, listener, ShareDialogStartPage.UsersAndGroups);
}

void SocketApi.command_ACTIVITY (string &localFile, SocketListener *listener) {
    Q_UNUSED (listener);

    processFileActivityRequest (localFile);
}

void SocketApi.command_MANAGE_PUBLIC_LINKS (string &localFile, SocketListener *listener) {
    processShareRequest (localFile, listener, ShareDialogStartPage.PublicLinks);
}

void SocketApi.command_VERSION (string &, SocketListener *listener) {
    listener.sendMessage (QLatin1String ("VERSION:" MIRALL_VERSION_STRING ":" MIRALL_SOCKET_API_VERSION));
}

void SocketApi.command_SHARE_MENU_TITLE (string &, SocketListener *listener) {
    //listener.sendMessage (QLatin1String ("SHARE_MENU_TITLE:") + tr ("Share with %1", "parameter is Nextcloud").arg (Theme.instance ().appNameGUI ()));
    listener.sendMessage (QLatin1String ("SHARE_MENU_TITLE:") + Theme.instance ().appNameGUI ());
}

void SocketApi.command_EDIT (string &localFile, SocketListener *listener) {
    Q_UNUSED (listener)
    auto fileData = FileData.get (localFile);
    if (!fileData.folder) {
        qCWarning (lcSocketApi) << "Unknown path" << localFile;
        return;
    }

    auto record = fileData.journalRecord ();
    if (!record.isValid ())
        return;

    DirectEditor* editor = getDirectEditorForLocalFile (fileData.localPath);
    if (!editor)
        return;

    auto *job = new JsonApiJob (fileData.folder.accountState ().account (), QLatin1String ("ocs/v2.php/apps/files/api/v1/directEditing/open"), this);

    QUrlQuery params;
    params.addQueryItem ("path", fileData.serverRelativePath);
    params.addQueryItem ("editorId", editor.id ());
    job.addQueryParams (params);
    job.setVerb (JsonApiJob.Verb.Post);

    GLib.Object.connect (job, &JsonApiJob.jsonReceived, [] (QJsonDocument &json){
        auto data = json.object ().value ("ocs").toObject ().value ("data").toObject ();
        auto url = QUrl (data.value ("url").toString ());

        if (!url.isEmpty ())
            Utility.openBrowser (url);
    });
    job.start ();
}

// don't pull the share manager into socketapi unittests
#ifndef OWNCLOUD_TEST

class GetOrCreatePublicLinkShare : GLib.Object {
public:
    GetOrCreatePublicLinkShare (AccountPtr &account, string &localFile,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account)
        , _shareManager (account)
        , _localFile (localFile) {
        connect (&_shareManager, &ShareManager.sharesFetched,
            this, &GetOrCreatePublicLinkShare.sharesFetched);
        connect (&_shareManager, &ShareManager.linkShareCreated,
            this, &GetOrCreatePublicLinkShare.linkShareCreated);
        connect (&_shareManager, &ShareManager.linkShareRequiresPassword,
            this, &GetOrCreatePublicLinkShare.linkShareRequiresPassword);
        connect (&_shareManager, &ShareManager.serverError,
            this, &GetOrCreatePublicLinkShare.serverError);
    }

    void run () {
        qCDebug (lcPublicLink) << "Fetching shares";
        _shareManager.fetchShares (_localFile);
    }

private slots:
    void sharesFetched (QList<QSharedPointer<Share>> &shares) {
        auto shareName = SocketApi.tr ("Context menu share");

        // If there already is a context menu share, reuse it
        for (auto &share : shares) {
            const auto linkShare = qSharedPointerDynamicCast<LinkShare> (share);
            if (!linkShare)
                continue;

            if (linkShare.getName () == shareName) {
                qCDebug (lcPublicLink) << "Found existing share, reusing";
                return success (linkShare.getLink ().toString ());
            }
        }

        // otherwise create a new one
        qCDebug (lcPublicLink) << "Creating new share";
        _shareManager.createLinkShare (_localFile, shareName, string ());
    }

    void linkShareCreated (QSharedPointer<LinkShare> &share) {
        qCDebug (lcPublicLink) << "New share created";
        success (share.getLink ().toString ());
    }

    void passwordRequired () {
        bool ok = false;
        string password = QInputDialog.getText (nullptr,
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
        _shareManager.createLinkShare (_localFile, string (), password);
    }

    void linkShareRequiresPassword (string &message) {
        qCInfo (lcPublicLink) << "Could not create link share:" << message;
        emit error (message);
        deleteLater ();
    }

    void serverError (int code, string &message) {
        qCWarning (lcPublicLink) << "Share fetch/create error" << code << message;
        QMessageBox.warning (
            nullptr,
            tr ("Sharing error"),
            tr ("Could not retrieve or create the public link share. Error:\n\n%1").arg (message),
            QMessageBox.Ok,
            QMessageBox.NoButton);
        emit error (message);
        deleteLater ();
    }

signals:
    void done (string &link);
    void error (string &message);

private:
    void success (string &link) {
        emit done (link);
        deleteLater ();
    }

    AccountPtr _account;
    ShareManager _shareManager;
    string _localFile;
};

#else

class GetOrCreatePublicLinkShare : GLib.Object {
public:
    GetOrCreatePublicLinkShare (AccountPtr &, string &,
        std.function<void (string &link)>, GLib.Object *) {
    }

    void run () {
    }
};

#endif

void SocketApi.command_COPY_PUBLIC_LINK (string &localFile, SocketListener *) {
    auto fileData = FileData.get (localFile);
    if (!fileData.folder)
        return;

    AccountPtr account = fileData.folder.accountState ().account ();
    auto job = new GetOrCreatePublicLinkShare (account, fileData.serverRelativePath, this);
    connect (job, &GetOrCreatePublicLinkShare.done, this,
        [] (string &url) { copyUrlToClipboard (url); });
    connect (job, &GetOrCreatePublicLinkShare.error, this,
        [=] () { emit shareCommandReceived (fileData.serverRelativePath, fileData.localPath, ShareDialogStartPage.PublicLinks); });
    job.run ();
}

// Fetches the private link url asynchronously and then calls the target slot
void SocketApi.fetchPrivateLinkUrlHelper (string &localFile, std.function<void (string &url)> &targetFun) {
    auto fileData = FileData.get (localFile);
    if (!fileData.folder) {
        qCWarning (lcSocketApi) << "Unknown path" << localFile;
        return;
    }

    auto record = fileData.journalRecord ();
    if (!record.isValid ())
        return;

    fetchPrivateLinkUrl (
        fileData.folder.accountState ().account (),
        fileData.serverRelativePath,
        record.numericFileId (),
        this,
        targetFun);
}

void SocketApi.command_COPY_PRIVATE_LINK (string &localFile, SocketListener *) {
    fetchPrivateLinkUrlHelper (localFile, &SocketApi.copyUrlToClipboard);
}

void SocketApi.command_EMAIL_PRIVATE_LINK (string &localFile, SocketListener *) {
    fetchPrivateLinkUrlHelper (localFile, &SocketApi.emailPrivateLink);
}

void SocketApi.command_OPEN_PRIVATE_LINK (string &localFile, SocketListener *) {
    fetchPrivateLinkUrlHelper (localFile, &SocketApi.openPrivateLink);
}

void SocketApi.command_MAKE_AVAILABLE_LOCALLY (string &filesArg, SocketListener *) {
    const QStringList files = split (filesArg);

    for (auto &file : files) {
        auto data = FileData.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().setPinState (data.folderRelativePath, PinState.AlwaysLocal)) {
            qCWarning (lcSocketApi) << "Could not set pin state of" << data.folderRelativePath << "to always local";
        }

        // Trigger sync
        data.folder.schedulePathForLocalDiscovery (data.folderRelativePath);
        data.folder.scheduleThisFolderSoon ();
    }
}

/* Go over all the files and replace them by a virtual file */
void SocketApi.command_MAKE_ONLINE_ONLY (string &filesArg, SocketListener *) {
    const QStringList files = split (filesArg);

    for (auto &file : files) {
        auto data = FileData.get (file);
        if (!data.folder)
            continue;

        // Update the pin state on all items
        if (!data.folder.vfs ().setPinState (data.folderRelativePath, PinState.OnlineOnly)) {
            qCWarning (lcSocketApi) << "Could not set pin state of" << data.folderRelativePath << "to online only";
        }

        // Trigger sync
        data.folder.schedulePathForLocalDiscovery (data.folderRelativePath);
        data.folder.scheduleThisFolderSoon ();
    }
}

void SocketApi.copyUrlToClipboard (string &link) {
    QApplication.clipboard ().setText (link);
}

void SocketApi.command_RESOLVE_CONFLICT (string &localFile, SocketListener *) {
    const auto fileData = FileData.get (localFile);
    if (!fileData.folder || !Utility.isConflictFile (fileData.folderRelativePath))
        return; // should not have shown menu item

    const auto conflictedRelativePath = fileData.folderRelativePath;
    const auto baseRelativePath = fileData.folder.journalDb ().conflictFileBaseName (fileData.folderRelativePath.toUtf8 ());

    const auto dir = QDir (fileData.folder.path ());
    const auto conflictedPath = dir.filePath (conflictedRelativePath);
    const auto basePath = dir.filePath (baseRelativePath);

    const auto baseName = QFileInfo (basePath).fileName ();

#ifndef OWNCLOUD_TEST
    ConflictDialog dialog;
    dialog.setBaseFilename (baseName);
    dialog.setLocalVersionFilename (conflictedPath);
    dialog.setRemoteVersionFilename (basePath);
    if (dialog.exec () == ConflictDialog.Accepted) {
        fileData.folder.scheduleThisFolderSoon ();
    }
#endif
}

void SocketApi.command_DELETE_ITEM (string &localFile, SocketListener *) {
    ConflictSolver solver;
    solver.setLocalVersionFilename (localFile);
    solver.exec (ConflictSolver.KeepRemoteVersion);
}

void SocketApi.command_MOVE_ITEM (string &localFile, SocketListener *) {
    const auto fileData = FileData.get (localFile);
    const auto parentDir = fileData.parentFolder ();
    if (!fileData.folder)
        return; // should not have shown menu item

    string defaultDirAndName = fileData.folderRelativePath;

    // If it's a conflict, we want to save it under the base name by default
    if (Utility.isConflictFile (defaultDirAndName)) {
        defaultDirAndName = fileData.folder.journalDb ().conflictFileBaseName (fileData.folderRelativePath.toUtf8 ());
    }

    // If the parent doesn't accept new files, go to the root of the sync folder
    QFileInfo fileInfo (localFile);
    const auto parentRecord = parentDir.journalRecord ();
    if ( (fileInfo.isFile () && !parentRecord._remotePerm.hasPermission (RemotePermissions.CanAddFile))
        || (fileInfo.isDir () && !parentRecord._remotePerm.hasPermission (RemotePermissions.CanAddSubDirectories))) {
        defaultDirAndName = QFileInfo (defaultDirAndName).fileName ();
    }

    // Add back the folder path
    defaultDirAndName = QDir (fileData.folder.path ()).filePath (defaultDirAndName);

    const auto target = QFileDialog.getSaveFileName (
        nullptr,
        tr ("Select new location …"),
        defaultDirAndName,
        string (), nullptr, QFileDialog.HideNameFilterDetails);
    if (target.isEmpty ())
        return;

    ConflictSolver solver;
    solver.setLocalVersionFilename (localFile);
    solver.setRemoteVersionFilename (target);
}

void SocketApi.command_V2_LIST_ACCOUNTS (QSharedPointer<SocketApiJobV2> &job) {
    QJsonArray out;
    for (auto acc : AccountManager.instance ().accounts ()) {
        // TODO : Use uuid once https://github.com/owncloud/client/pull/8397 is merged
        out << QJsonObject ({ { "name", acc.account ().displayName () }, { "id", acc.account ().id () } });
    }
    job.success ({ { "accounts", out } });
}

void SocketApi.command_V2_UPLOAD_FILES_FROM (QSharedPointer<SocketApiJobV2> &job) {
    auto uploadJob = new SocketUploadJob (job);
    uploadJob.start ();
}

void SocketApi.emailPrivateLink (string &link) {
    Utility.openEmailComposer (
        tr ("I shared something with you"),
        link,
        nullptr);
}

void Occ.SocketApi.openPrivateLink (string &link) {
    Utility.openBrowser (link);
}

void SocketApi.command_GET_STRINGS (string &argument, SocketListener *listener) { {c std.array<std.pair<const char *, QStrin { "SHARE_MENU_TITLE", tr ("Share options") }, { "FILE_ACTIVITY_MENU_TITLE", tr ("Activity") }, { "CONTEXT_MENU_TITLE", Theme.instance ().appNameGUI () }, { "COPY_PRIVATE_LINK_MENU_TITLE", tr ("Copy private link to clipboard") } { "EMAIL_PRIVATE_LINK_MENU_TITLE", tr ("Send private link by email …") },
        { "CONTEXT_MENU_ICON", APPLICATION_ICON_NAME },
    } };
    listener.sendMessage (string ("GET_STRINGS:BEGIN"));
    for (auto& key_value : strings) {
        if (argument.isEmpty () || argument == QLatin1String (key_value.first)) {
            listener.sendMessage (string ("STRING:%1:%2").arg (key_value.first, key_value.second));
        }
    }
    listener.sendMessage (string ("GET_STRINGS:END"));
}

void SocketApi.sendSharingContextMenuOptions (FileData &fileData, SocketListener *listener, bool enabled) {
    auto record = fileData.journalRecord ();
    bool isOnTheServer = record.isValid ();
    auto flagString = isOnTheServer && enabled ? QLatin1String (".") : QLatin1String (":d:");

    auto capabilities = fileData.folder.accountState ().account ().capabilities ();
    auto theme = Theme.instance ();
    if (!capabilities.shareAPI () || ! (theme.userGroupSharing () || (theme.linkSharing () && capabilities.sharePublicLink ())))
        return;

    // If sharing is globally disabled, do not show any sharing entries.
    // If there is no permission to share for this file, add a disabled entry saying so
    if (isOnTheServer && !record._remotePerm.isNull () && !record._remotePerm.hasPermission (RemotePermissions.CanReshare)) {
        listener.sendMessage (QLatin1String ("MENU_ITEM:DISABLED:d:") + (!record.isDirectory () ? tr ("Resharing this file is not allowed") : tr ("Resharing this folder is not allowed")));
    } else {
        listener.sendMessage (QLatin1String ("MENU_ITEM:SHARE") + flagString + tr ("Share options"));

        // Do we have public links?
        bool publicLinksEnabled = theme.linkSharing () && capabilities.sharePublicLink ();

        // Is is possible to create a public link without user choices?
        bool canCreateDefaultPublicLink = publicLinksEnabled
            && !capabilities.sharePublicLinkEnforceExpireDate ()
            && !capabilities.sharePublicLinkAskOptionalPassword ()
            && !capabilities.sharePublicLinkEnforcePassword ();

        if (canCreateDefaultPublicLink) {
            listener.sendMessage (QLatin1String ("MENU_ITEM:COPY_PUBLIC_LINK") + flagString + tr ("Copy public link"));
        } else if (publicLinksEnabled) {
            listener.sendMessage (QLatin1String ("MENU_ITEM:MANAGE_PUBLIC_LINKS") + flagString + tr ("Copy public link"));
        }
    }

    listener.sendMessage (QLatin1String ("MENU_ITEM:COPY_PRIVATE_LINK") + flagString + tr ("Copy internal link"));

    // Disabled : only providing email option for private links would look odd,
    // and the copy option is more general.
    //listener.sendMessage (QLatin1String ("MENU_ITEM:EMAIL_PRIVATE_LINK") + flagString + tr ("Send private link by email …"));
}

SocketApi.FileData SocketApi.FileData.get (string &localFile) {
    FileData data;

    data.localPath = QDir.cleanPath (localFile);
    if (data.localPath.endsWith (QLatin1Char ('/')))
        data.localPath.chop (1);

    data.folder = FolderMan.instance ().folderForPath (data.localPath);
    if (!data.folder)
        return data;

    data.folderRelativePath = data.localPath.mid (data.folder.cleanPath ().length () + 1);
    data.serverRelativePath = QDir (data.folder.remotePath ()).filePath (data.folderRelativePath);
    string virtualFileExt = QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    if (data.serverRelativePath.endsWith (virtualFileExt)) {
        data.serverRelativePath.chop (virtualFileExt.size ());
    }
    return data;
}

string SocketApi.FileData.folderRelativePathNoVfsSuffix () {
    auto result = folderRelativePath;
    string virtualFileExt = QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    if (result.endsWith (virtualFileExt)) {
        result.chop (virtualFileExt.size ());
    }
    return result;
}

SyncFileStatus SocketApi.FileData.syncFileStatus () {
    if (!folder)
        return SyncFileStatus.StatusNone;
    return folder.syncEngine ().syncFileStatusTracker ().fileStatus (folderRelativePath);
}

SyncJournalFileRecord SocketApi.FileData.journalRecord () {
    SyncJournalFileRecord record;
    if (!folder)
        return record;
    folder.journalDb ().getFileRecord (folderRelativePath, &record);
    return record;
}

SocketApi.FileData SocketApi.FileData.parentFolder () {
    return FileData.get (QFileInfo (localPath).dir ().path ().toUtf8 ());
}

void SocketApi.command_GET_MENU_ITEMS (string &argument, Occ.SocketListener *listener) {
    listener.sendMessage (string ("GET_MENU_ITEMS:BEGIN"));
    const QStringList files = split (argument);

    // Find the common sync folder.
    // syncFolder will be null if files are in different folders.
    Folder *syncFolder = nullptr;
    for (auto &file : files) {
        auto folder = FolderMan.instance ().folderForPath (file);
        if (folder != syncFolder) {
            if (!syncFolder) {
                syncFolder = folder;
            } else {
                syncFolder = nullptr;
                break;
            }
        }
    }

    // Sharing actions show for single files only
    if (syncFolder && files.size () == 1 && syncFolder.accountState ().isConnected ()) {
        string systemPath = QDir.cleanPath (argument);
        if (systemPath.endsWith (QLatin1Char ('/'))) {
            systemPath.truncate (systemPath.length () - 1);
        }

        FileData fileData = FileData.get (argument);
        const auto record = fileData.journalRecord ();
        const bool isOnTheServer = record.isValid ();
        const auto isE2eEncryptedPath = fileData.journalRecord ()._isE2eEncrypted || !fileData.journalRecord ()._e2eMangledName.isEmpty ();
        auto flagString = isOnTheServer && !isE2eEncryptedPath ? QLatin1String (".") : QLatin1String (":d:");

        const QFileInfo fileInfo (fileData.localPath);
        if (!fileInfo.isDir ()) {
            listener.sendMessage (QLatin1String ("MENU_ITEM:ACTIVITY") + flagString + tr ("Activity"));
        }

        DirectEditor* editor = getDirectEditorForLocalFile (fileData.localPath);
        if (editor) {
            //listener.sendMessage (QLatin1String ("MENU_ITEM:EDIT") + flagString + tr ("Edit via ") + editor.name ());
            listener.sendMessage (QLatin1String ("MENU_ITEM:EDIT") + flagString + tr ("Edit"));
        } else {
            listener.sendMessage (QLatin1String ("MENU_ITEM:OPEN_PRIVATE_LINK") + flagString + tr ("Open in browser"));
        }

        sendSharingContextMenuOptions (fileData, listener, !isE2eEncryptedPath);

        // Conflict files get conflict resolution actions
        bool isConflict = Utility.isConflictFile (fileData.folderRelativePath);
        if (isConflict || !isOnTheServer) {
            // Check whether this new file is in a read-only directory
            const auto parentDir = fileData.parentFolder ();
            const auto parentRecord = parentDir.journalRecord ();
            const bool canAddToDir =
                !parentRecord.isValid () // We're likely at the root of the sync folder, got to assume we can add there
                || (fileInfo.isFile () && parentRecord._remotePerm.hasPermission (RemotePermissions.CanAddFile))
                || (fileInfo.isDir () && parentRecord._remotePerm.hasPermission (RemotePermissions.CanAddSubDirectories));
            const bool canChangeFile =
                !isOnTheServer
                || (record._remotePerm.hasPermission (RemotePermissions.CanDelete)
                       && record._remotePerm.hasPermission (RemotePermissions.CanMove)
                       && record._remotePerm.hasPermission (RemotePermissions.CanRename));

            if (isConflict && canChangeFile) {
                if (canAddToDir) {
                    listener.sendMessage (QLatin1String ("MENU_ITEM:RESOLVE_CONFLICT.") + tr ("Resolve conflict …"));
                } else {
                    if (isOnTheServer) {
                        // Uploaded conflict file in read-only directory
                        listener.sendMessage (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move and rename …"));
                    } else {
                        // Local-only conflict file in a read-only dir
                        listener.sendMessage (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move, rename and upload …"));
                    }
                    listener.sendMessage (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + tr ("Delete local changes"));
                }
            }

            // File in a read-only directory?
            if (!isConflict && !isOnTheServer && !canAddToDir) {
                listener.sendMessage (QLatin1String ("MENU_ITEM:MOVE_ITEM.") + tr ("Move and upload …"));
                listener.sendMessage (QLatin1String ("MENU_ITEM:DELETE_ITEM.") + tr ("Delete"));
            }
        }
    }

    // File availability actions
    if (syncFolder
        && syncFolder.virtualFilesEnabled ()
        && syncFolder.vfs ().socketApiPinStateActionsShown ()) {
        ENFORCE (!files.isEmpty ());

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
            auto fileData = FileData.get (file);
            auto availability = syncFolder.vfs ().availability (fileData.folderRelativePath);
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
        auto makePinContextMenu = [&] (bool makeAvailableLocally, bool freeSpace) {
            listener.sendMessage (QLatin1String ("MENU_ITEM:CURRENT_PIN:d:")
                + Utility.vfsCurrentAvailabilityText (*combined));
            if (!Theme.instance ().enforceVirtualFilesSyncFolder ()) {
                listener.sendMessage (QLatin1String ("MENU_ITEM:MAKE_AVAILABLE_LOCALLY:")
                    + (makeAvailableLocally ? QLatin1String (":") : QLatin1String ("d:")) + Utility.vfsPinActionText ());
            }

            listener.sendMessage (QLatin1String ("MENU_ITEM:MAKE_ONLINE_ONLY:")
                + (freeSpace ? QLatin1String (":") : QLatin1String ("d:"))
                + Utility.vfsFreeSpaceActionText ());
        };

        if (combined) {
            switch (*combined) {
            case VfsItemAvailability.AlwaysLocal:
                makePinContextMenu (false, true);
                break;
            case VfsItemAvailability.AllHydrated:
            case VfsItemAvailability.Mixed:
                makePinContextMenu (true, true);
                break;
            case VfsItemAvailability.AllDehydrated:
            case VfsItemAvailability.OnlineOnly:
                makePinContextMenu (true, false);
                break;
            }
        }
    }

    listener.sendMessage (string ("GET_MENU_ITEMS:END"));
}

DirectEditor* SocketApi.getDirectEditorForLocalFile (string &localFile) {
    FileData fileData = FileData.get (localFile);
    auto capabilities = fileData.folder.accountState ().account ().capabilities ();

    if (fileData.folder && fileData.folder.accountState ().isConnected ()) {
        const auto record = fileData.journalRecord ();
        const auto mimeMatchMode = record.isVirtualFile () ? QMimeDatabase.MatchExtension : QMimeDatabase.MatchDefault;

        QMimeDatabase db;
        QMimeType type = db.mimeTypeForFile (localFile, mimeMatchMode);

        DirectEditor* editor = capabilities.getDirectEditorForMimetype (type);
        if (!editor) {
            editor = capabilities.getDirectEditorForOptionalMimetype (type);
        }
        return editor;
    }

    return nullptr;
}

#if GUI_TESTING
void SocketApi.command_ASYNC_LIST_WIDGETS (QSharedPointer<SocketApiJob> &job) {
    string response;
    for (auto &widget : allObjects (QApplication.allWidgets ())) {
        auto objectName = widget.objectName ();
        if (!objectName.isEmpty ()) {
            response += objectName + ":" + widget.property ("text").toString () + ", ";
        }
    }
    job.resolve (response);
}

void SocketApi.command_ASYNC_INVOKE_WIDGET_METHOD (QSharedPointer<SocketApiJob> &job) {
    auto &arguments = job.arguments ();

    auto widget = findWidget (arguments["objectName"].toString ());
    if (!widget) {
        job.reject (QLatin1String ("widget not found"));
        return;
    }

    QMetaObject.invokeMethod (widget, arguments["method"].toString ().toUtf8 ().constData ());
    job.resolve ();
}

void SocketApi.command_ASYNC_GET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job) {
    string widgetName = job.arguments ()[QLatin1String ("objectName")].toString ();
    auto widget = findWidget (widgetName);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 2 : %1")).arg (widgetName);
        job.reject (message);
        return;
    }

    auto propertyName = job.arguments ()[QLatin1String ("property")].toString ();

    auto segments = propertyName.split ('.');

    GLib.Object *currentObject = widget;
    string value;
    for (int i = 0; i < segments.count (); i++) {
        auto segment = segments.at (i);
        auto var = currentObject.property (segment.toUtf8 ().constData ());

        if (var.canConvert<string> ()) {
            var.convert (QMetaType.string);
            value = var.value<string> ();
            break;
        }

        auto tmpObject = var.value<GLib.Object> ();
        if (tmpObject) {
            currentObject = tmpObject;
        } else {
            string message = string (QLatin1String ("Widget not found : 3 : %1")).arg (widgetName);
            job.reject (message);
            return;
        }
    }

    job.resolve (value);
}

void SocketApi.command_ASYNC_SET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job) {
    auto &arguments = job.arguments ();
    string widgetName = arguments["objectName"].toString ();
    auto widget = findWidget (widgetName);
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 4 : %1")).arg (widgetName);
        job.reject (message);
        return;
    }
    widget.setProperty (arguments["property"].toString ().toUtf8 ().constData (),
        arguments["value"]);

    job.resolve ();
}

void SocketApi.command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (QSharedPointer<SocketApiJob> &job) {
    auto &arguments = job.arguments ();
    string widgetName = arguments["objectName"].toString ();
    auto widget = findWidget (arguments["objectName"].toString ());
    if (!widget) {
        string message = string (QLatin1String ("Widget not found : 5 : %1")).arg (widgetName);
        job.reject (message);
        return;
    }

    ListenerClosure *closure = new ListenerClosure ([job] () { job.resolve ("signal emitted"); });

    auto signalSignature = arguments["signalSignature"].toString ();
    signalSignature.prepend ("2");
    auto utf8 = signalSignature.toUtf8 ();
    auto signalSignatureFinal = utf8.constData ();
    connect (widget, signalSignatureFinal, closure, SLOT (closureSlot ()), Qt.QueuedConnection);
}

void SocketApi.command_ASYNC_TRIGGER_MENU_ACTION (QSharedPointer<SocketApiJob> &job) {
    auto &arguments = job.arguments ();

    auto objectName = arguments["objectName"].toString ();
    auto widget = findWidget (objectName);
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 1 : %1")).arg (objectName);
        job.reject (message);
        return;
    }

    auto children = widget.findChildren<Gtk.Widget> ();
    for (auto childWidget : children) {
        // foo is the popupwidget!
        auto actions = childWidget.actions ();
        for (auto action : actions) {
            if (action.objectName () == arguments["actionName"].toString ()) {
                action.trigger ();

                job.resolve ("action found");
                return;
            }
        }
    }

    string message = string (QLatin1String ("Action not found : 1 : %1")).arg (arguments["actionName"].toString ());
    job.reject (message);
}

void SocketApi.command_ASYNC_ASSERT_ICON_IS_EQUAL (QSharedPointer<SocketApiJob> &job) {
    auto widget = findWidget (job.arguments ()[QLatin1String ("queryString")].toString ());
    if (!widget) {
        string message = string (QLatin1String ("Object not found : 6 : %1")).arg (job.arguments ()["queryString"].toString ());
        job.reject (message);
        return;
    }

    auto propertyName = job.arguments ()[QLatin1String ("propertyPath")].toString ();

    auto segments = propertyName.split ('.');

    GLib.Object *currentObject = widget;
    QIcon value;
    for (int i = 0; i < segments.count (); i++) {
        auto segment = segments.at (i);
        auto var = currentObject.property (segment.toUtf8 ().constData ());

        if (var.canConvert<QIcon> ()) {
            var.convert (QMetaType.QIcon);
            value = var.value<QIcon> ();
            break;
        }

        auto tmpObject = var.value<GLib.Object> ();
        if (tmpObject) {
            currentObject = tmpObject;
        } else {
            job.reject (string (QLatin1String ("Icon not found : %1")).arg (propertyName));
        }
    }

    auto iconName = job.arguments ()[QLatin1String ("iconName")].toString ();
    if (value.name () == iconName) {
        job.resolve ();
    } else {
        job.reject ("iconName " + iconName + " does not match : " + value.name ());
    }
}
#endif

string SocketApi.buildRegisterPathMessage (string &path) {
    QFileInfo fi (path);
    string message = QLatin1String ("REGISTER_PATH:");
    message.append (QDir.toNativeSeparators (fi.absoluteFilePath ()));
    return message;
}

void SocketApiJob.resolve (string &response) {
    _socketListener.sendMessage (QStringLiteral ("RESOLVE|") + _jobId + QLatin1Char ('|') + response);
}

void SocketApiJob.resolve (QJsonObject &response) {
    resolve (QJsonDocument { response }.toJson ());
}

void SocketApiJob.reject (string &response) {
    _socketListener.sendMessage (QStringLiteral ("REJECT|") + _jobId + QLatin1Char ('|') + response);
}

SocketApiJobV2.SocketApiJobV2 (QSharedPointer<SocketListener> &socketListener, QByteArray &command, QJsonObject &arguments)
    : _socketListener (socketListener)
    , _command (command)
    , _jobId (arguments[QStringLiteral ("id")].toString ())
    , _arguments (arguments[QStringLiteral ("arguments")].toObject ()) {
    ASSERT (!_jobId.isEmpty ())
}

void SocketApiJobV2.success (QJsonObject &response) {
    doFinish (response);
}

void SocketApiJobV2.failure (string &error) {
    doFinish ({ { QStringLiteral ("error"), error } });
}

void SocketApiJobV2.doFinish (QJsonObject &obj) {
    _socketListener.sendMessage (_command + QStringLiteral ("_RESULT:") + QJsonDocument ({ { QStringLiteral ("id"), _jobId }, { QStringLiteral ("arguments"), obj } }).toJson (QJsonDocument.Compact));
    Q_EMIT finished ();
}

} // namespace Occ

#include "socketapi.moc"














namespace Occ {

    class BloomFilter {
        // Initialize with m=1024 bits and k=2 (high and low 16 bits of a qHash).
        // For a client navigating in less than 100 directories, this gives us a probability less than
        // (1-e^ (-2*100/1024))^2 = 0.03147872136 false positives.
        const static int NumBits = 1024;
    
    public:
        BloomFilter ()
            : hashBits (NumBits) {
        }
    
        void storeHash (uint hash) {
            hashBits.setBit ( (hash & 0xFFFF) % NumBits); // NOLINT it's uint all the way and the modulo puts us back in the 0..1023 range
            hashBits.setBit ( (hash >> 16) % NumBits); // NOLINT
        }
        bool isHashMaybeStored (uint hash) {
            return hashBits.testBit ( (hash & 0xFFFF) % NumBits) // NOLINT
                && hashBits.testBit ( (hash >> 16) % NumBits); // NOLINT
        }
    
    private:
        QBitArray hashBits;
    };
    
    class SocketListener {
    public:
        QPointer<QIODevice> socket;
    
        SocketListener (QIODevice *_socket)
            : socket (_socket) {
        }
    
        void sendMessage (string &message, bool doWait = false) const;
        void sendWarning (string &message, bool doWait = false) {
            sendMessage (QStringLiteral ("WARNING:") + message, doWait);
        }
        void sendError (string &message, bool doWait = false) {
            sendMessage (QStringLiteral ("ERROR:") + message, doWait);
        }
    
        void sendMessageIfDirectoryMonitored (string &message, uint systemDirectoryHash) {
            if (_monitoredDirectoriesBloomFilter.isHashMaybeStored (systemDirectoryHash))
                sendMessage (message, false);
        }
    
        void registerMonitoredDirectory (uint systemDirectoryHash) {
            _monitoredDirectoriesBloomFilter.storeHash (systemDirectoryHash);
        }
    
    private:
        BloomFilter _monitoredDirectoriesBloomFilter;
    };
    
    class ListenerClosure : GLib.Object {
    public:
        using CallbackFunction = std.function<void ()>;
        ListenerClosure (CallbackFunction callback)
            : callback_ (callback) {
        }
    
    public slots:
        void closureSlot () {
            callback_ ();
            deleteLater ();
        }
    
    private:
        CallbackFunction callback_;
    };
    
    class SocketApiJob : GLib.Object {
    public:
        SocketApiJob (string &jobId, QSharedPointer<SocketListener> &socketListener, QJsonObject &arguments)
            : _jobId (jobId)
            , _socketListener (socketListener)
            , _arguments (arguments) {
        }
    
        void resolve (string &response = string ());
    
        void resolve (QJsonObject &response);
    
        const QJsonObject &arguments () { return _arguments; }
    
        void reject (string &response);
    
    protected:
        string _jobId;
        QSharedPointer<SocketListener> _socketListener;
        QJsonObject _arguments;
    };
    
    class SocketApiJobV2 : GLib.Object {
    public:
        SocketApiJobV2 (QSharedPointer<SocketListener> &socketListener, QByteArray &command, QJsonObject &arguments);
    
        void success (QJsonObject &response) const;
        void failure (string &error) const;
    
        const QJsonObject &arguments () { return _arguments; }
        QByteArray command () { return _command; }
    
    signals:
        void finished ();
    
    private:
        void doFinish (QJsonObject &obj) const;
    
        QSharedPointer<SocketListener> _socketListener;
        const QByteArray _command;
        string _jobId;
        QJsonObject _arguments;
    };
    }
    
    Q_DECLARE_METATYPE (Occ.SocketListener *)
    