/***********************************************************
@author Roeland Jago Douma <roeland@famdouma.nl>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief Job to fetch a thumbnail for a file
@ingroup gui

Job that allows fetching a preview (of 150x150 for now) of
a given file. Once the job has finished the
signal_job_finished signal will be emitted.
***********************************************************/
public class ThumbnailJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public ThumbnailJob (string path, unowned Account account, GLib.Object parent = new GLib.Object ()) {
        base (account, "index.php/apps/files/api/v1/thumbnail/150/150/" + path, parent);
        ignore_credential_failure (true);
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_start () {
        send_request ("GET", make_account_url (path));
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    @param status_code the HTTP status code
    @param reply the content of the reply

    Signal that the job is done. If the status_code is 200 (on_signal_success) reply
    will contain the image data in PNG. If the status code is different the content
    of reply is undefined.
    ***********************************************************/
    void signal_job_finished (int status_code, string reply);

    /***********************************************************
    ***********************************************************/
    private override bool on_signal_finished () {
        /* emit */ signal_job_finished (this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int (), this.reply.read_all ());
        return true;
    }

} // class ThumbnailJob

} // namespace Ui
} // namespace Occ
    