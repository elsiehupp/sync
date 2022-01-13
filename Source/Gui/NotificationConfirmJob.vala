/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>

// #include <QVector>
// #include <QList>
// #include <QPair>
// #include <QUrl>

namespace Occ {

/***********************************************************
@brief The NotificationConfirmJob class
@ingroup gui

Class to call an action-link of a notification coming from the server.
All the communication logic is handled in this class.

***********************************************************/
class NotificationConfirmJob : AbstractNetworkJob {

public:
    NotificationConfirmJob (AccountPtr account);

    /***********************************************************
    @brief Set the verb and link for the job
    
     * @param verb currently supported GET PUT POST DELETE
    ***********************************************************/
    void setLinkAndVerb (QUrl &link, QByteArray &verb);

    /***********************************************************
    @brief Start the OCS request
    ***********************************************************/
    void start () override;

signals:

    /***********************************************************
    Result of the OCS request
    
     * @param reply the reply
    ***********************************************************/
    void jobFinished (string reply, int replyCode);

private slots:
    bool finished () override;

private:
    QByteArray _verb;
    QUrl _link;
};

    NotificationConfirmJob.NotificationConfirmJob (AccountPtr account)
        : AbstractNetworkJob (account, "") {
        setIgnoreCredentialFailure (true);
    }
    
    void NotificationConfirmJob.setLinkAndVerb (QUrl &link, QByteArray &verb) {
        _link = link;
        _verb = verb;
    }
    
    void NotificationConfirmJob.start () {
        if (!_link.isValid ()) {
            qCWarning (lcNotificationsJob) << "Attempt to trigger invalid URL : " << _link.toString ();
            return;
        }
        QNetworkRequest req;
        req.setRawHeader ("Ocs-APIREQUEST", "true");
        req.setRawHeader ("Content-Type", "application/x-www-form-urlencoded");
    
        sendRequest (_verb, _link, req);
    
        AbstractNetworkJob.start ();
    }
    
    bool NotificationConfirmJob.finished () {
        int replyCode = 0;
        // FIXME : check for the reply code!
        const string replyStr = reply ().readAll ();
    
        if (replyStr.contains ("<?xml version=\"1.0\"?>")) {
            const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
            const auto rexMatch = rex.match (replyStr);
            if (rexMatch.hasMatch ()) {
                // this is a error message coming back from ocs.
                replyCode = rexMatch.captured (1).toInt ();
            }
        }
        emit jobFinished (replyStr, replyCode);
    
        return true;
    }
    }
    