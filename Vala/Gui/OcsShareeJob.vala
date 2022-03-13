/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonDocument>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OcsShareeJob class
@ingroup gui

Fetching sharees from the OCS Sharee API
***********************************************************/
class OcsShareeJob : OcsJob {

    /***********************************************************
    Result of the OCS request

    @param reply The reply
    ***********************************************************/
    signal void signal_sharee_job_finished (QJsonDocument reply);

    /***********************************************************
    ***********************************************************/
    public OcsShareeJob (AccountPointer account) {
        base (account);
        path ("ocs/v2.php/apps/files_sharing/api/v1/sharees");
        connect (
            this,
            OcsJob.signal_job_finished,
            this,
            OcsShareeJob.on_signal_job_done
        );
    }


    /***********************************************************
    Get a list of sharees

    @param path Path to request shares for (default all shares)
    ***********************************************************/
    public void sharees (string search, string item_type, int page = 1, int per_page = 50, bool lookup = false) {
        verb ("GET");

        add_param (string.from_latin1 ("search"), search);
        add_param (string.from_latin1 ("item_type"), item_type);
        add_param (string.from_latin1 ("page"), string.number (page));
        add_param (string.from_latin1 ("per_page"), string.number (per_page));
        add_param (string.from_latin1 ("lookup"), GLib.Variant (lookup).to_string ());

        on_signal_start ();
    }



    /***********************************************************
    ***********************************************************/
    private void on_signal_job_done (QJsonDocument reply) {
        /* emit */ signal_sharee_job_finished (reply);
    }

} // class OcsShareeJob

} // namespace Ui
} // namespace Occ
