/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #pragma once

namespace Occ {

/***********************************************************
@brief The Delete_job class
@ingroup libsync
***********************************************************/
class Delete_job : AbstractNetworkJob {
public:
    Delete_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    Delete_job (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);

    void start () override;
    bool finished () override;

    QByteArray folder_token ();
    void set_folder_token (QByteArray &folder_token);

signals:
    void finished_signal ();

private:
    QUrl _url; // Only used if the constructor taking a url is taken.
    QByteArray _folder_token;
};

    Delete_job.Delete_job (AccountPtr account, string &path, GLib.Object *parent)
        : AbstractNetworkJob (account, path, parent) {
    }
    
    Delete_job.Delete_job (AccountPtr account, QUrl &url, GLib.Object *parent)
        : AbstractNetworkJob (account, string (), parent)
        , _url (url) {
    }
    
    void Delete_job.start () {
        QNetworkRequest req;
        if (!_folder_token.is_empty ()) {
            req.set_raw_header ("e2e-token", _folder_token);
        }
    
        if (_url.is_valid ()) {
            send_request ("DELETE", _url, req);
        } else {
            send_request ("DELETE", make_dav_url (path ()), req);
        }
    
        if (reply ().error () != QNetworkReply.NoError) {
            q_c_warning (lc_delete_job) << " Network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.start ();
    }
    
    bool Delete_job.finished () {
        q_c_info (lc_delete_job) << "DELETE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << reply_status_string ();
    
        emit finished_signal ();
        return true;
    }
    
    QByteArray Delete_job.folder_token () {
        return _folder_token;
    }
    
    void Delete_job.set_folder_token (QByteArray &folder_token) {
        _folder_token = folder_token;
    }
    
    } // namespace Occ
    