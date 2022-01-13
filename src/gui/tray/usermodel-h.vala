#ifndef USERMODEL_H
#define USERMODEL_H

// #include <QAbstractListModel>
// #include <QImage>
// #include <QDateTime>
// #include <QStringList>
// #include <QQuickImageProvider>
// #include <QHash>

// #include <chrono>

namespace OCC {
class UnifiedSearchResultsListModel;

class User : public QObject {
    Q_PROPERTY (QString name READ name NOTIFY nameChanged)
    Q_PROPERTY (QString server READ server CONSTANT)
    Q_PROPERTY (bool serverHasUserStatus READ serverHasUserStatus CONSTANT)
    Q_PROPERTY (QUrl statusIcon READ statusIcon NOTIFY statusChanged)
    Q_PROPERTY (QString statusEmoji READ statusEmoji NOTIFY statusChanged)
    Q_PROPERTY (QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY (bool desktopNotificationsAllowed READ isDesktopNotificationsAllowed NOTIFY desktopNotificationsAllowedChanged)
    Q_PROPERTY (bool hasLocalFolder READ hasLocalFolder NOTIFY hasLocalFolderChanged)
    Q_PROPERTY (bool serverHasTalk READ serverHasTalk NOTIFY serverHasTalkChanged)
    Q_PROPERTY (QString avatar READ avatarUrl NOTIFY avatarChanged)
    Q_PROPERTY (bool isConnected READ isConnected NOTIFY accountStateChanged)
    Q_PROPERTY (UnifiedSearchResultsListModel* unifiedSearchResultsListModel READ getUnifiedSearchResultsListModel CONSTANT)
public:
    User (AccountStatePtr &account, bool &isCurrent = false, QObject *parent = nullptr);

    AccountPtr account () const;
    AccountStatePtr accountState () const;

    bool isConnected () const;
    bool isCurrentUser () const;
    void setCurrentUser (bool &isCurrent);
    Folder *getFolder () const;
    ActivityListModel *getActivityModel ();
    UnifiedSearchResultsListModel *getUnifiedSearchResultsListModel () const;
    void openLocalFolder ();
    QString name () const;
    QString server (bool shortened = true) const;
    bool hasLocalFolder () const;
    bool serverHasTalk () const;
    bool serverHasUserStatus () const;
    AccountApp *talkApp () const;
    bool hasActivities () const;
    AccountAppList appList () const;
    QImage avatar () const;
    void login () const;
    void logout () const;
    void removeAccount () const;
    QString avatarUrl () const;
    bool isDesktopNotificationsAllowed () const;
    UserStatus.OnlineStatus status () const;
    QString statusMessage () const;
    QUrl statusIcon () const;
    QString statusEmoji () const;
    void processCompletedSyncItem (Folder *folder, SyncFileItemPtr &item);

signals:
    void guiLog (QString &, QString &);
    void nameChanged ();
    void hasLocalFolderChanged ();
    void serverHasTalkChanged ();
    void avatarChanged ();
    void accountStateChanged ();
    void statusChanged ();
    void desktopNotificationsAllowedChanged ();

public slots:
    void slotItemCompleted (QString &folder, SyncFileItemPtr &item);
    void slotProgressInfo (QString &folder, ProgressInfo &progress);
    void slotAddError (QString &folderAlias, QString &message, ErrorCategory category);
    void slotAddErrorToGui (QString &folderAlias, SyncFileItem.Status status, QString &errorMessage, QString &subject = {});
    void slotNotificationRequestFinished (int statusCode);
    void slotNotifyNetworkError (QNetworkReply *reply);
    void slotEndNotificationRequest (int replyCode);
    void slotNotifyServerFinished (QString &reply, int replyCode);
    void slotSendNotificationRequest (QString &accountName, QString &link, QByteArray &verb, int row);
    void slotBuildNotificationDisplay (ActivityList &list);
    void slotRefreshNotifications ();
    void slotRefreshActivities ();
    void slotRefresh ();
    void slotRefreshUserStatus ();
    void slotRefreshImmediately ();
    void setNotificationRefreshInterval (std.chrono.milliseconds interval);
    void slotRebuildNavigationAppList ();

private:
    void slotPushNotificationsReady ();
    void slotDisconnectPushNotifications ();
    void slotReceivedPushNotification (Account *account);
    void slotReceivedPushActivity (Account *account);
    void slotCheckExpiredActivities ();

    void connectPushNotifications () const;
    bool checkPushNotificationsAreReady () const;

    bool isActivityOfCurrentAccount (Folder *folder) const;
    bool isUnsolvableConflict (SyncFileItemPtr &item) const;

    void showDesktopNotification (QString &title, QString &message);

private:
    AccountStatePtr _account;
    bool _isCurrentUser;
    ActivityListModel *_activityModel;
    UnifiedSearchResultsListModel *_unifiedSearchResultsModel;
    ActivityList _blacklistedNotifications;

    QTimer _expiredActivitiesCheckTimer;
    QTimer _notificationCheckTimer;
    QHash<AccountState *, QElapsedTimer> _timeSinceLastCheck;

    QElapsedTimer _guiLogTimer;
    NotificationCache _notificationCache;

    // number of currently running notification requests. If non zero,
    // no query for notifications is started.
    int _notificationRequestsRunning;
};

class UserModel : public QAbstractListModel {
    Q_PROPERTY (User* currentUser READ currentUser NOTIFY newUserSelected)
    Q_PROPERTY (int currentUserId READ currentUserId NOTIFY newUserSelected)
public:
    static UserModel *instance ();
    ~UserModel () override = default;

    void addUser (AccountStatePtr &user, bool &isCurrent = false);
    int currentUserIndex ();

    int rowCount (QModelIndex &parent = QModelIndex ()) const override;

    QVariant data (QModelIndex &index, int role = Qt.DisplayRole) const override;

    QImage avatarById (int &id);

    User *currentUser () const;

    int findUserIdForAccount (AccountState *account) const;

    Q_INVOKABLE void fetchCurrentActivityModel ();
    Q_INVOKABLE void openCurrentAccountLocalFolder ();
    Q_INVOKABLE void openCurrentAccountTalk ();
    Q_INVOKABLE void openCurrentAccountServer ();
    Q_INVOKABLE int numUsers ();
    Q_INVOKABLE QString currentUserServer ();
    int currentUserId () const;
    Q_INVOKABLE bool isUserConnected (int &id);
    Q_INVOKABLE void switchCurrentUser (int &id);
    Q_INVOKABLE void login (int &id);
    Q_INVOKABLE void logout (int &id);
    Q_INVOKABLE void removeAccount (int &id);

    Q_INVOKABLE std.shared_ptr<OCC.UserStatusConnector> userStatusConnector (int id);

    ActivityListModel *currentActivityModel ();

    enum UserRoles {
        NameRole = Qt.UserRole + 1,
        ServerRole,
        ServerHasUserStatusRole,
        StatusIconRole,
        StatusEmojiRole,
        StatusMessageRole,
        DesktopNotificationsAllowedRole,
        AvatarRole,
        IsCurrentUserRole,
        IsConnectedRole,
        IdRole
    };

    AccountAppList appList () const;

signals:
    Q_INVOKABLE void addAccount ();
    Q_INVOKABLE void newUserSelected ();

protected:
    QHash<int, QByteArray> roleNames () const override;

private:
    static UserModel *_instance;
    UserModel (QObject *parent = nullptr);
    QList<User*> _users;
    int _currentUserId = 0;
    bool _init = true;

    void buildUserList ();
};

class ImageProvider : public QQuickImageProvider {
public:
    ImageProvider ();
    QImage requestImage (QString &id, QSize *size, QSize &requestedSize) override;
};

class UserAppsModel : public QAbstractListModel {
public:
    static UserAppsModel *instance ();
    ~UserAppsModel () override = default;

    int rowCount (QModelIndex &parent = QModelIndex ()) const override;

    QVariant data (QModelIndex &index, int role = Qt.DisplayRole) const override;

    enum UserAppsRoles {
        NameRole = Qt.UserRole + 1,
        UrlRole,
        IconUrlRole
    };

    void buildAppList ();

public slots:
    void openAppUrl (QUrl &url);

protected:
    QHash<int, QByteArray> roleNames () const override;

private:
    static UserAppsModel *_instance;
    UserAppsModel (QObject *parent = nullptr);

    AccountAppList _apps;
};

}
#endif // USERMODEL_H
