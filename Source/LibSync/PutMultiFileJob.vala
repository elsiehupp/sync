/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QHttp_part>

// #pragma once

// #include <QLoggingCategory>
// #include <QMap>
// #include <GLib.Uri>
// #include <string>
// #include <QElapsedTimer>
// #include <QHttpMultiPart>
// #include <memory>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_put_multi_file_job)

struct SingleUploadFileData {
    std.unique_ptr<UploadDevice> _device;
    QMap<GLib.ByteArray, GLib.ByteArray> _headers;
};

/***********************************************************
@brief The PutMultiFileJob class
@ingroup libsync
***********************************************************/
class PutMultiFileJob : AbstractNetworkJob {

    public PutMultiFileJob (AccountPointer account, GLib.Uri url,
                             std.vector<SingleUploadFileData> devices, GLib.Object parent = nullptr)
        : AbstractNetworkJob (account, {}, parent)
        , _devices (std.move (devices))
        , _url (url) {
        _body.set_content_type (QHttpMultiPart.Related_type);
        for (var &single_device : _devices) {
            single_device._device.set_parent (this);
            connect (this, &PutMultiFileJob.upload_progress,
                    single_device._device.get (), &UploadDevice.on_job_upload_progress);
        }
    }

    ~PutMultiFileJob () override;

    public void on_start () override;

    public bool on_finished () override;

    public string error_string () override {
        return _error_string.is_empty () ? AbstractNetworkJob.error_string () : _error_string;
    }


    public std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (_request_timer.elapsed ());
    }

signals:
    void finished_signal ();
    void upload_progress (int64, int64);


    private QHttpMultiPart _body;
    private std.vector<SingleUploadFileData> _devices;
    private string _error_string;
    private GLib.Uri _url;
    private QElapsedTimer _request_timer;
};


    PutMultiFileJob.~PutMultiFileJob () = default;

    void PutMultiFileJob.on_start () {
        QNetworkRequest req;

        for (var &one_device : _devices) {
            var one_part = QHttp_part{};

            one_part.set_body_device (one_device._device.get ());

            for (QMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = one_device._headers.begin (); it != one_device._headers.end (); ++it) {
                one_part.set_raw_header (it.key (), it.value ());
            }

            req.set_priority (QNetworkRequest.Low_priority); // Long uploads must not block non-propagation jobs.

            _body.append (one_part);
        }

        send_request ("POST", _url, req, &_body);

        if (reply ().error () != QNetworkReply.NoError) {
            GLib.warn (lc_put_multi_file_job) << " Network error : " << reply ().error_string ();
        }

        connect (reply (), &QNetworkReply.upload_progress, this, &PutMultiFileJob.upload_progress);
        connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);
        _request_timer.on_start ();
        AbstractNetworkJob.on_start ();
    }

    bool PutMultiFileJob.on_finished () {
        for (var &one_device : _devices) {
            one_device._device.close ();
        }

        q_c_info (lc_put_multi_file_job) << "POST of" << reply ().request ().url ().to_string () << path () << "FINISHED WITH STATUS"
                         << reply_status_string ()
                         << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute)
                         << reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute);

        emit finished_signal ();
        return true;
    }

    }
    