/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief Job to fetch a thumbnail for a file
@ingroup gui

Job that allows fetching a preview (of 150x150 for now) of a given file.
Once the job has on_finished the job_finished signal will be emitted.
***********************************************************/
class Thumbnail_job : AbstractNetworkJob {

    public Thumbnail_job (string path, AccountPointer account, GLib.Object parent = nullptr);

    public on_ void on_start () override;
signals:
    /***********************************************************
    @param status_code the HTTP status code
    @param reply the content of the reply

    Signal that the job is done. If the status_code is 200 (on_success) reply
    will contain the image data in PNG. If the status code is different the content
    of reply is undefined.
    ***********************************************************/
    void job_finished (int status_code, GLib.ByteArray reply);

    private bool on_finished () override;
};


    Thumbnail_job.Thumbnail_job (string path, AccountPointer account, GLib.Object parent)
        : AbstractNetworkJob (account, QLatin1String ("index.php/apps/files/api/v1/thumbnail/150/150/") + path, parent) {
        set_ignore_credential_failure (true);
    }

    void Thumbnail_job.on_start () {
        send_request ("GET", make_account_url (path ()));
        AbstractNetworkJob.on_start ();
    }

    bool Thumbnail_job.on_finished () {
        emit job_finished (reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int (), reply ().read_all ());
        return true;
    }
    }
    