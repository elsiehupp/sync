/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>


namespace Occ {

/***********************************************************
@brief The OcsShareeJob class
@ingroup gui

Fetching sharees from the OCS Sharee API
***********************************************************/
class OcsShareeJob : OcsJob {
public:
    OcsShareeJob (AccountPtr account);

    /***********************************************************
    Get a list of sharees
    
     * @param path Path to request shares for (default all shares)
    ***********************************************************/
    void getSharees (string &search, string &itemType, int page = 1, int perPage = 50, bool lookup = false);
signals:
    /***********************************************************
    Result of the OCS request
    
     * @param reply The reply
    ***********************************************************/
    void shareeJobFinished (QJsonDocument &reply);

private slots:
    void jobDone (QJsonDocument &reply);
};
}








namespace Occ {

    OcsShareeJob.OcsShareeJob (AccountPtr account)
        : OcsJob (account) {
        setPath ("ocs/v2.php/apps/files_sharing/api/v1/sharees");
        connect (this, &OcsJob.jobFinished, this, &OcsShareeJob.jobDone);
    }
    
    void OcsShareeJob.getSharees (string &search,
        const string &itemType,
        int page,
        int perPage,
        bool lookup) {
        setVerb ("GET");
    
        addParam (string.fromLatin1 ("search"), search);
        addParam (string.fromLatin1 ("itemType"), itemType);
        addParam (string.fromLatin1 ("page"), string.number (page));
        addParam (string.fromLatin1 ("perPage"), string.number (perPage));
        addParam (string.fromLatin1 ("lookup"), QVariant (lookup).toString ());
    
        start ();
    }
    
    void OcsShareeJob.jobDone (QJsonDocument &reply) {
        emit shareeJobFinished (reply);
    }
    }
    