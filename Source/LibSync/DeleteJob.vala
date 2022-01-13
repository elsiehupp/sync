/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #pragma once

namespace Occ {

/***********************************************************
@brief The DeleteJob class
@ingroup libsync
***********************************************************/
class DeleteJob : AbstractNetworkJob {
public:
    DeleteJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    DeleteJob (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);

    void start () override;
    bool finished () override;

    QByteArray folderToken ();
    void setFolderToken (QByteArray &folderToken);

signals:
    void finishedSignal ();

private:
    QUrl _url; // Only used if the constructor taking a url is taken.
    QByteArray _folderToken;
};

    DeleteJob.DeleteJob (AccountPtr account, string &path, GLib.Object *parent)
        : AbstractNetworkJob (account, path, parent) {
    }
    
    DeleteJob.DeleteJob (AccountPtr account, QUrl &url, GLib.Object *parent)
        : AbstractNetworkJob (account, string (), parent)
        , _url (url) {
    }
    
    void DeleteJob.start () {
        QNetworkRequest req;
        if (!_folderToken.isEmpty ()) {
            req.setRawHeader ("e2e-token", _folderToken);
        }
    
        if (_url.isValid ()) {
            sendRequest ("DELETE", _url, req);
        } else {
            sendRequest ("DELETE", makeDavUrl (path ()), req);
        }
    
        if (reply ().error () != QNetworkReply.NoError) {
            qCWarning (lcDeleteJob) << " Network error : " << reply ().errorString ();
        }
        AbstractNetworkJob.start ();
    }
    
    bool DeleteJob.finished () {
        qCInfo (lcDeleteJob) << "DELETE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << replyStatusString ();
    
        emit finishedSignal ();
        return true;
    }
    
    QByteArray DeleteJob.folderToken () {
        return _folderToken;
    }
    
    void DeleteJob.setFolderToken (QByteArray &folderToken) {
        _folderToken = folderToken;
    }
    
    } // namespace Occ
    