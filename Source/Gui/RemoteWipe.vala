/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QNetworkRequest>
// #include <QBuffer>

// #include <QNetworkAccessManager>


namespace Occ {

class RemoteWipe : GLib.Object {
public:
    RemoteWipe (AccountPtr account, GLib.Object *parent = nullptr);

signals:
    /***********************************************************
    Notify if wipe was requested
    ***********************************************************/
    void authorized (AccountState*);

    /***********************************************************
    Notify if user only needs to login again
    ***********************************************************/
    void askUserCredentials ();

public slots:
    /***********************************************************
    Once receives a 401 or 403 status response it will do a fetch to
    <server>/index.php/core/wipe/check
    ***********************************************************/
    void startCheckJobWithAppPassword (string);

private slots:
    /***********************************************************
    If wipe is requested, delete account and data, if not continue by asking
    the user to login again
    ***********************************************************/
    void checkJobSlot ();

    /***********************************************************
    Once the client has wiped all the required data a POST to
    <server>/index.php/core/wipe/success
    ***********************************************************/
    void notifyServerSuccessJob (AccountState *accountState, bool);
    void notifyServerSuccessJobSlot ();

private:
    AccountPtr _account;
    string _appPassword;
    bool _accountRemoved;
    QNetworkAccessManager _networkManager;
    QNetworkReply *_networkReplyCheck;
    QNetworkReply *_networkReplySuccess;

    friend class .TestRemoteWipe;
};

    RemoteWipe.RemoteWipe (AccountPtr account, GLib.Object *parent)
        : GLib.Object (parent),
          _account (account),
          _appPassword (string ()),
          _accountRemoved (false),
          _networkManager (nullptr),
          _networkReplyCheck (nullptr),
          _networkReplySuccess (nullptr) {
        GLib.Object.connect (AccountManager.instance (), &AccountManager.accountRemoved,
                         this, [=] (AccountState *) {
            _accountRemoved = true;
        });
        GLib.Object.connect (this, &RemoteWipe.authorized, FolderMan.instance (),
                         &FolderMan.slotWipeFolderForAccount);
        GLib.Object.connect (FolderMan.instance (), &FolderMan.wipeDone, this,
                         &RemoteWipe.notifyServerSuccessJob);
        GLib.Object.connect (_account.data (), &Account.appPasswordRetrieved, this,
                         &RemoteWipe.startCheckJobWithAppPassword);
    }
    
    void RemoteWipe.startCheckJobWithAppPassword (string pwd){
        if (pwd.isEmpty ())
            return;
    
        _appPassword = pwd;
        QUrl requestUrl = Utility.concatUrlPath (_account.url ().toString (),
                                                 QLatin1String ("/index.php/core/wipe/check"));
        QNetworkRequest request;
        request.setHeader (QNetworkRequest.ContentTypeHeader,
                          "application/x-www-form-urlencoded");
        request.setUrl (requestUrl);
        request.setSslConfiguration (_account.getOrCreateSslConfig ());
        auto requestBody = new QBuffer;
        QUrlQuery arguments (string ("token=%1").arg (_appPassword));
        requestBody.setData (arguments.query (QUrl.FullyEncoded).toLatin1 ());
        _networkReplyCheck = _networkManager.post (request, requestBody);
        GLib.Object.connect (&_networkManager, SIGNAL (sslErrors (QNetworkReply *, QList<QSslError>)),
            _account.data (), SLOT (slotHandleSslErrors (QNetworkReply *, QList<QSslError>)));
        GLib.Object.connect (_networkReplyCheck, &QNetworkReply.finished, this,
                         &RemoteWipe.checkJobSlot);
    }
    
    void RemoteWipe.checkJobSlot () {
        auto jsonData = _networkReplyCheck.readAll ();
        QJsonParseError jsonParseError;
        QJsonObject json = QJsonDocument.fromJson (jsonData, &jsonParseError).object ();
        bool wipe = false;
    
        //check for errors
        if (_networkReplyCheck.error () != QNetworkReply.NoError ||
                jsonParseError.error != QJsonParseError.NoError) {
            string errorReason;
            string errorFromJson = json["error"].toString ();
            if (!errorFromJson.isEmpty ()) {
                qCWarning (lcRemoteWipe) << string ("Error returned from the server : <em>%1<em>")
                                           .arg (errorFromJson.toHtmlEscaped ());
            } else if (_networkReplyCheck.error () != QNetworkReply.NoError) {
                qCWarning (lcRemoteWipe) << string ("There was an error accessing the 'token' endpoint : <br><em>%1</em>")
                                  .arg (_networkReplyCheck.errorString ().toHtmlEscaped ());
            } else if (jsonParseError.error != QJsonParseError.NoError) {
                qCWarning (lcRemoteWipe) << string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (jsonParseError.errorString ());
            } else {
                qCWarning (lcRemoteWipe) <<  string ("The reply from the server did not contain all expected fields");
            }
    
        // check for wipe request
        } else if (!json.value ("wipe").isUndefined ()){
            wipe = json["wipe"].toBool ();
        }
    
        auto manager = AccountManager.instance ();
        auto accountState = manager.account (_account.displayName ()).data ();
    
        if (wipe){
            /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
             * TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!
             *
             *       Disabled as long as selecting another cert is not supported by the UI.
             *
             *       Being able to specify a new certificate is important anyway : expiry etc.
             *
             *       We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
             */
            _account.setRemoteWipeRequested_HACK ();
            // <-- FIXME MS@2019-12-07
    
            // delete account
            manager.deleteAccount (accountState);
            manager.save ();
    
            // delete data
            emit authorized (accountState);
    
        } else {
            // ask user for his credentials again
            accountState.handleInvalidCredentials ();
        }
    
        _networkReplyCheck.deleteLater ();
    }
    
    void RemoteWipe.notifyServerSuccessJob (AccountState *accountState, bool dataWiped){
        if (_accountRemoved && dataWiped && _account == accountState.account ()){
            QUrl requestUrl = Utility.concatUrlPath (_account.url ().toString (),
                                                     QLatin1String ("/index.php/core/wipe/success"));
            QNetworkRequest request;
            request.setHeader (QNetworkRequest.ContentTypeHeader,
                              "application/x-www-form-urlencoded");
            request.setUrl (requestUrl);
            request.setSslConfiguration (_account.getOrCreateSslConfig ());
            auto requestBody = new QBuffer;
            QUrlQuery arguments (string ("token=%1").arg (_appPassword));
            requestBody.setData (arguments.query (QUrl.FullyEncoded).toLatin1 ());
            _networkReplySuccess = _networkManager.post (request, requestBody);
            GLib.Object.connect (_networkReplySuccess, &QNetworkReply.finished, this,
                             &RemoteWipe.notifyServerSuccessJobSlot);
        }
    }
    
    void RemoteWipe.notifyServerSuccessJobSlot () {
        auto jsonData = _networkReplySuccess.readAll ();
        QJsonParseError jsonParseError;
        QJsonObject json = QJsonDocument.fromJson (jsonData, &jsonParseError).object ();
        if (_networkReplySuccess.error () != QNetworkReply.NoError ||
                jsonParseError.error != QJsonParseError.NoError) {
            string errorReason;
            string errorFromJson = json["error"].toString ();
            if (!errorFromJson.isEmpty ()) {
                qCWarning (lcRemoteWipe) << string ("Error returned from the server : <em>%1</em>")
                                  .arg (errorFromJson.toHtmlEscaped ());
            } else if (_networkReplySuccess.error () != QNetworkReply.NoError) {
                qCWarning (lcRemoteWipe) << string ("There was an error accessing the 'success' endpoint : <br><em>%1</em>")
                                  .arg (_networkReplySuccess.errorString ().toHtmlEscaped ());
            } else if (jsonParseError.error != QJsonParseError.NoError) {
                qCWarning (lcRemoteWipe) << string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (jsonParseError.errorString ());
            } else {
                qCWarning (lcRemoteWipe) << string ("The reply from the server did not contain all expected fields.");
            }
        }
    
        _networkReplySuccess.deleteLater ();
    }
    }
    