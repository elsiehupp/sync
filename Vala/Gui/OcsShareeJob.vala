/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonDocument>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Ocs_sharee_job class
@ingroup gui

Fetching sharees from the OCS Sharee API
***********************************************************/
class Ocs_sharee_job : Ocs_job {

    /***********************************************************
    ***********************************************************/
    public Ocs_sharee_job (AccountPointer account);


    /***********************************************************
    Get a list of sharees

    @param path Path to request shares for (default all shares)
    ***********************************************************/
    public void get_sharees (string search, string item_type, int page = 1, int per_page = 50, bool lookup = false);

signals:
    /***********************************************************
    Result of the OCS request

    @param reply The reply
    ***********************************************************/
    void sharee_job_finished (QJsonDocument reply);


    /***********************************************************
    ***********************************************************/
    private void on_job_done (QJsonDocument reply);
}

    Ocs_sharee_job.Ocs_sharee_job (AccountPointer account)
        : Ocs_job (account) {
        path ("ocs/v2.php/apps/files_sharing/api/v1/sharees");
        connect (this, &Ocs_job.job_finished, this, &Ocs_sharee_job.on_job_done);
    }

    void Ocs_sharee_job.get_sharees (string search,
        const string item_type,
        int page,
        int per_page,
        bool lookup) {
        verb ("GET");

        add_param (string.from_latin1 ("search"), search);
        add_param (string.from_latin1 ("item_type"), item_type);
        add_param (string.from_latin1 ("page"), string.number (page));
        add_param (string.from_latin1 ("per_page"), string.number (per_page));
        add_param (string.from_latin1 ("lookup"), GLib.Variant (lookup).to_string ());

        on_start ();
    }

    void Ocs_sharee_job.on_job_done (QJsonDocument reply) {
        /* emit */ sharee_job_finished (reply);
    }
    }
    