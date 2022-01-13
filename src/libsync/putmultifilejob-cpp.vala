/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QHttpPart>

namespace Occ {

Q_LOGGING_CATEGORY (lcPutMultiFileJob, "nextcloud.sync.networkjob.put.multi", QtInfoMsg)

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
