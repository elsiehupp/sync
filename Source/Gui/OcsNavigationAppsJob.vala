/***********************************************************
Copyright (C) by Camila Ayres <camila@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief The Ocs_apps_job class
@ingroup gui

Fetching enabled apps from the OCS Apps API
***********************************************************/
class OcsNavigationAppsJob : Ocs_job {

    public OcsNavigationAppsJob (AccountPtr account);

    /***********************************************************
    Get a list of enabled apps and external sites
    visible in the Navigation menu
    ***********************************************************/
    public void get_navigation_apps ();

signals:
    /***********************************************************
    Result of the OCS request

    @param reply The reply
    @param status_code the status code of the response
    ***********************************************************/
    void apps_job_finished (QJsonDocument &reply, int status_code);

private slots:
    void job_done (QJsonDocument &reply, int status_code);
};

    OcsNavigationAppsJob.OcsNavigationAppsJob (AccountPtr account)
        : Ocs_job (account) {
        set_path ("ocs/v2.php/core/navigation/apps");
        connect (this, &OcsNavigationAppsJob.job_finished, this, &OcsNavigationAppsJob.job_done);
    }

    void OcsNavigationAppsJob.get_navigation_apps () {
        set_verb ("GET");
        add_param ("absolute", "true");
        start ();
    }

    void OcsNavigationAppsJob.job_done (QJsonDocument &reply, int status_code) {
        emit apps_job_finished (reply, status_code);
    }
    }
    