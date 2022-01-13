/*
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

#include "sharedialog.h" // for the ShareDialogStartPage

// #include <QLocalServer>
using SocketApiServer = QLocalServer;

class QLocalSocket;

namespace Occ {

class Folder;
class DirectEditor;
class SocketApiJobV2;

Q_DECLARE_LOGGING_CATEGORY (lcSocketApi)

/**
@brief The SocketApi class
@ingroup gui
*/
class SocketApi : GLib.Object {

public:
    SocketApi (GLib.Object *parent = nullptr);
    ~SocketApi () override;

public slots:
    void slotUpdateFolderView (Folder *f);
    void slotUnregisterPath (QString &alias);
    void slotRegisterPath (QString &alias);
    void broadcastStatusPushMessage (QString &systemPath, SyncFileStatus fileStatus);

signals:
    void shareCommandReceived (QString &sharePath, QString &localPath, ShareDialogStartPage startPage);
    void fileActivityCommandReceived (QString &sharePath, QString &localPath);

private slots:
    void slotNewConnection ();
    void onLostConnection ();
    void slotSocketDestroyed (GLib.Object *obj);
    void slotReadSocket ();

    static void copyUrlToClipboard (QString &link);
    static void emailPrivateLink (QString &link);
    static void openPrivateLink (QString &link);

private:
    // Helper structure for getting information on a file
    // based on its local path - used for nearly all remote
    // actions.
    struct FileData {
        static FileData get (QString &localFile);
        SyncFileStatus syncFileStatus ();
        SyncJournalFileRecord journalRecord ();
        FileData parentFolder ();

        // Relative path of the file locally, without any vfs suffix
        QString folderRelativePathNoVfsSuffix ();

        Folder *folder;
        // Absolute path of the file locally. (May be a virtual file)
        QString localPath;
        // Relative path of the file locally, as in the DB. (May be a virtual file)
        QString folderRelativePath;
        // Path of the file on the server (In case of virtual file, it points to the actual file)
        QString serverRelativePath;
    };

    void broadcastMessage (QString &msg, bool doWait = false);

    // opens share dialog, sends reply
    void processShareRequest (QString &localFile, SocketListener *listener, ShareDialogStartPage startPage);
    void processFileActivityRequest (QString &localFile);

    Q_INVOKABLE void command_RETRIEVE_FOLDER_STATUS (QString &argument, SocketListener *listener);
    Q_INVOKABLE void command_RETRIEVE_FILE_STATUS (QString &argument, SocketListener *listener);

    Q_INVOKABLE void command_VERSION (QString &argument, SocketListener *listener);

    Q_INVOKABLE void command_SHARE_MENU_TITLE (QString &argument, SocketListener *listener);

    // The context menu actions
    Q_INVOKABLE void command_ACTIVITY (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_SHARE (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MANAGE_PUBLIC_LINKS (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_COPY_PUBLIC_LINK (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_COPY_PRIVATE_LINK (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_EMAIL_PRIVATE_LINK (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_OPEN_PRIVATE_LINK (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MAKE_AVAILABLE_LOCALLY (QString &filesArg, SocketListener *listener);
    Q_INVOKABLE void command_MAKE_ONLINE_ONLY (QString &filesArg, SocketListener *listener);
    Q_INVOKABLE void command_RESOLVE_CONFLICT (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_DELETE_ITEM (QString &localFile, SocketListener *listener);
    Q_INVOKABLE void command_MOVE_ITEM (QString &localFile, SocketListener *listener);

    // External sync
    Q_INVOKABLE void command_V2_LIST_ACCOUNTS (QSharedPointer<SocketApiJobV2> &job) const;
    Q_INVOKABLE void command_V2_UPLOAD_FILES_FROM (QSharedPointer<SocketApiJobV2> &job) const;

    // Fetch the private link and call targetFun
    void fetchPrivateLinkUrlHelper (QString &localFile, std.function<void (QString &url)> &targetFun);

    /** Sends translated/branded strings that may be useful to the integration */
    Q_INVOKABLE void command_GET_STRINGS (QString &argument, SocketListener *listener);

    // Sends the context menu options relating to sharing to listener
    void sendSharingContextMenuOptions (FileData &fileData, SocketListener *listener, bool enabled);

    /** Send the list of menu item. (added in version 1.1)
     * argument is a list of files for which the menu should be shown, separated by '\x1e'
     * Reply with  GET_MENU_ITEMS:BEGIN
     * followed by several MENU_ITEM:[Action]:[flag]:[Text]
     * If flag contains 'd', the menu should be disabled
     * and ends with GET_MENU_ITEMS:END
     */
    Q_INVOKABLE void command_GET_MENU_ITEMS (QString &argument, SocketListener *listener);

    /// Direct Editing
    Q_INVOKABLE void command_EDIT (QString &localFile, SocketListener *listener);
    DirectEditor* getDirectEditorForLocalFile (QString &localFile);

#if GUI_TESTING
    Q_INVOKABLE void command_ASYNC_ASSERT_ICON_IS_EQUAL (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_LIST_WIDGETS (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_INVOKE_WIDGET_METHOD (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_GET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_SET_WIDGET_PROPERTY (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_WAIT_FOR_WIDGET_SIGNAL (QSharedPointer<SocketApiJob> &job);
    Q_INVOKABLE void command_ASYNC_TRIGGER_MENU_ACTION (QSharedPointer<SocketApiJob> &job);
#endif

    QString buildRegisterPathMessage (QString &path);

    QSet<QString> _registeredAliases;
    QMap<QIODevice *, QSharedPointer<SocketListener>> _listeners;
    SocketApiServer _localServer;
};
}
