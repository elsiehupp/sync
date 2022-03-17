/***********************************************************
Copyright (C) by Camila Ayres <camila@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Ocs_apps_job class
@ingroup gui

Fetching enabled apps from the OCS Apps API
***********************************************************/
public class OcsNavigationAppsJob : OcsJob {

    /***********************************************************
    Result of the OCS request

    @param reply The reply
    @param status_code the status code of the response
    ***********************************************************/
    internal signal void signal_apps_job_finished (QJsonDocument reply, int status_code);

    /***********************************************************
    ***********************************************************/
    public OcsNavigationAppsJob (Account account) {
        base (account);
        path ("ocs/v2.php/core/navigation/apps");
        this.signal_job_finished.connect (
            this.on_signal_job_finished
        );
    }


    /***********************************************************
    Get a list of enabled apps and external sites
    visible in the Navigation menu
    ***********************************************************/
    public void navigation_apps () {
        verb ("GET");
        add_param ("absolute", "true");
        on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_job_finished (QJsonDocument reply, int status_code) {
        /* emit */ signal_apps_job_finished (reply, status_code);
    }

} // class OcsNavigationAppsJob

} // namespace Ui
} // namespace Occ
