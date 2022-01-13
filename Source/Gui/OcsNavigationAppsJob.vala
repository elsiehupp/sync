/***********************************************************
Copyright (C) by Camila Ayres <camila@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief The OcsAppsJob class
@ingroup gui

Fetching enabled apps from the OCS Apps API
***********************************************************/
class OcsNavigationAppsJob : OcsJob {
public:
    OcsNavigationAppsJob (AccountPtr account);

    /***********************************************************
    Get a list of enabled apps and external sites
    visible in the Navigation menu
    ***********************************************************/
    void getNavigationApps ();

signals:
    /***********************************************************
    Result of the OCS request
    
    @param reply The reply
     * @param statusCode the status code of the response
    ***********************************************************/
    void appsJobFinished (QJsonDocument &reply, int statusCode);

private slots:
    void jobDone (QJsonDocument &reply, int statusCode);
};
}







namespace Occ {

    OcsNavigationAppsJob.OcsNavigationAppsJob (AccountPtr account)
        : OcsJob (account) {
        setPath ("ocs/v2.php/core/navigation/apps");
        connect (this, &OcsNavigationAppsJob.jobFinished, this, &OcsNavigationAppsJob.jobDone);
    }
    
    void OcsNavigationAppsJob.getNavigationApps () {
        setVerb ("GET");
        addParam ("absolute", "true");
        start ();
    }
    
    void OcsNavigationAppsJob.jobDone (QJsonDocument &reply, int statusCode) {
        emit appsJobFinished (reply, statusCode);
    }
    }
    