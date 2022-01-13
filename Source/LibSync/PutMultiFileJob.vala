/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QHttpPart>

// #pragma once

// #include <QLoggingCategory>
// #include <QMap>
// #include <QByteArray>
// #include <QUrl>
// #include <string>
// #include <QElapsedTimer>
// #include <QHttpMultiPart>
// #include <memory>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcPutMultiFileJob)

struct SingleUploadFileData {
    std.unique_ptr<UploadDevice> _device;
    QMap<QByteArray, QByteArray> _headers;
};

/***********************************************************
@brief The PutMultiFileJob class
@ingroup libsync
***********************************************************/
class PutMultiFileJob : AbstractNetworkJob {

public:
    PutMultiFileJob (AccountPtr account, QUrl &url,
                             std.vector<SingleUploadFileData> devices, GLib.Object *parent = nullptr)
        : AbstractNetworkJob (account, {}, parent)
        , _devices (std.move (devices))
        , _url (url) {
        _body.setContentType (QHttpMultiPart.RelatedType);
        for (auto &singleDevice : _devices) {
            singleDevice._device.setParent (this);
            connect (this, &PutMultiFileJob.uploadProgress,
                    singleDevice._device.get (), &UploadDevice.slotJobUploadProgress);
        }
    }

    ~PutMultiFileJob () override;

    void start () override;

    bool finished () override;

    string errorString () const override {
        return _errorString.isEmpty () ? AbstractNetworkJob.errorString () : _errorString;
    }

    std.chrono.milliseconds msSinceStart () {
        return std.chrono.milliseconds (_requestTimer.elapsed ());
    }

signals:
    void finishedSignal ();
    void uploadProgress (int64, int64);

private:
    QHttpMultiPart _body;
    std.vector<SingleUploadFileData> _devices;
    string _errorString;
    QUrl _url;
    QElapsedTimer _requestTimer;
};


    PutMultiFileJob.~PutMultiFileJob () = default;
    
    void PutMultiFileJob.start () {
        QNetworkRequest req;
    
        for (auto &oneDevice : _devices) {
            auto onePart = QHttpPart{};
    
            onePart.setBodyDevice (oneDevice._device.get ());
    
            for (QMap<QByteArray, QByteArray>.const_iterator it = oneDevice._headers.begin (); it != oneDevice._headers.end (); ++it) {
                onePart.setRawHeader (it.key (), it.value ());
            }
    
            req.setPriority (QNetworkRequest.LowPriority); // Long uploads must not block non-propagation jobs.
    
            _body.append (onePart);
        }
    
        sendRequest ("POST", _url, req, &_body);
    
        if (reply ().error () != QNetworkReply.NoError) {
            qCWarning (lcPutMultiFileJob) << " Network error : " << reply ().errorString ();
        }
    
        connect (reply (), &QNetworkReply.uploadProgress, this, &PutMultiFileJob.uploadProgress);
        connect (this, &AbstractNetworkJob.networkActivity, account ().data (), &Account.propagatorNetworkActivity);
        _requestTimer.start ();
        AbstractNetworkJob.start ();
    }
    
    bool PutMultiFileJob.finished () {
        for (auto &oneDevice : _devices) {
            oneDevice._device.close ();
        }
    
        qCInfo (lcPutMultiFileJob) << "POST of" << reply ().request ().url ().toString () << path () << "FINISHED WITH STATUS"
                         << replyStatusString ()
                         << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute)
                         << reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute);
    
        emit finishedSignal ();
        return true;
    }
    
    }
    