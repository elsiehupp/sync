#ifndef REMOTEWIPE_H
const int REMOTEWIPE_H

// #include <QNetworkAccessManager>

class TestRemoteWipe;

namespace Occ {

class RemoteWipe : GLib.Object {
public:
    RemoteWipe (AccountPtr account, GLib.Object *parent = nullptr);

signals:
    /**
     * Notify if wipe was requested
     */
    void authorized (AccountState*);

    /**
     * Notify if user only needs to login again
     */
    void askUserCredentials ();

public slots:
    /**
     * Once receives a 401 or 403 status response it will do a fetch to
     * <server>/index.php/core/wipe/check
     */
    void startCheckJobWithAppPassword (QString);

private slots:
    /**
     * If wipe is requested, delete account and data, if not continue by asking
     * the user to login again
     */
    void checkJobSlot ();

    /**
     * Once the client has wiped all the required data a POST to
     * <server>/index.php/core/wipe/success
     */
    void notifyServerSuccessJob (AccountState *accountState, bool);
    void notifyServerSuccessJobSlot ();

private:
    AccountPtr _account;
    QString _appPassword;
    bool _accountRemoved;
    QNetworkAccessManager _networkManager;
    QNetworkReply *_networkReplyCheck;
    QNetworkReply *_networkReplySuccess;

    friend class .TestRemoteWipe;
};
}
#endif // REMOTEWIPE_H