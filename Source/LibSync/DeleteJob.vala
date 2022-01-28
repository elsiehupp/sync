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

    public DeleteJob (AccountPtr account, string path, GLib.Object parent = nullptr);


    public DeleteJob (AccountPtr account, QUrl url, GLib.Object parent = nullptr);

    public void on_start () override;
    public bool on_finished () override;

    public GLib.ByteArray folder_token ();


    public void set_folder_token (GLib.ByteArray folder_token);

signals:
    void finished_signal ();


    private QUrl _url; // Only used if the constructor taking a url is taken.
    private GLib.ByteArray _folder_token;
};

    DeleteJob.DeleteJob (AccountPtr account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    DeleteJob.DeleteJob (AccountPtr account, QUrl url, GLib.Object parent)
        : AbstractNetworkJob (account, string (), parent)
        , _url (url) {
    }

    void DeleteJob.on_start () {
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
        AbstractNetworkJob.on_start ();
    }

    bool DeleteJob.on_finished () {
        q_c_info (lc_delete_job) << "DELETE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << reply_status_string ();

        emit finished_signal ();
        return true;
    }

    GLib.ByteArray DeleteJob.folder_token () {
        return _folder_token;
    }

    void DeleteJob.set_folder_token (GLib.ByteArray folder_token) {
        _folder_token = folder_token;
    }

    } // namespace Occ
    