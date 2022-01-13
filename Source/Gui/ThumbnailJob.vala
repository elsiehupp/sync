/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Job to fetch a thumbnail for a file
@ingroup gui

Job that allows fetching a preview (of 150x150 for now) of a given file.
Once the job has finished the jobFinished signal will be emitted.
***********************************************************/
class ThumbnailJob : AbstractNetworkJob {
public:
    ThumbnailJob (string &path, AccountPtr account, GLib.Object *parent = nullptr);
public slots:
    void start () override;
signals:
    /***********************************************************
     * @param statusCode the HTTP status code
     * @param reply the content of the reply
     *
     * Signal that the job is done. If the statusCode is 200 (success) reply
     * will contain the image data in PNG. If the status code is different the content
     * of reply is undefined.
     */
    void jobFinished (int statusCode, QByteArray reply);
private slots:
    bool finished () override;
};
}








/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

    ThumbnailJob.ThumbnailJob (string &path, AccountPtr account, GLib.Object *parent)
        : AbstractNetworkJob (account, QLatin1String ("index.php/apps/files/api/v1/thumbnail/150/150/") + path, parent) {
        setIgnoreCredentialFailure (true);
    }
    
    void ThumbnailJob.start () {
        sendRequest ("GET", makeAccountUrl (path ()));
        AbstractNetworkJob.start ();
    }
    
    bool ThumbnailJob.finished () {
        emit jobFinished (reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt (), reply ().readAll ());
        return true;
    }
    }
    