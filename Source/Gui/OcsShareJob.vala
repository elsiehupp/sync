/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QJsonDocument>

// #include <QVector>
// #include <QList>
// #include <QPair>


namespace Occ {

/***********************************************************
@brief The OcsShareJob class
@ingroup gui

Handle talking to the OCS Share API.
For creation, deletion and modification of shares.
***********************************************************/
class OcsShareJob : OcsJob {
public:
    /***********************************************************
    Constructor for new shares or listing of shares
    ***********************************************************/
    OcsShareJob (AccountPtr account);

    /***********************************************************
    Get all the shares
    
     * @param path Path to request shares for (default all shares)
    ***********************************************************/
    void getShares (string &path = "");

    /***********************************************************
    Delete the current Share
    ***********************************************************/
    void deleteShare (string &shareId);

    /***********************************************************
    Set the expiration date of a share
    
    @param date The expire date, if this date is invalid the expire date
     * will be removed
    ***********************************************************/
    void setExpireDate (string &shareId, QDate &date);

	 /***********************************************************
    Set note a share
    
    @param note The note to a share, if the note is empty the
     * share will be removed
    ***********************************************************/
    void setNote (string &shareId, string &note);

    /***********************************************************
    Set the password of a share
    
    @param password The password of the share, if the password is empty the
     * share will be removed
    ***********************************************************/
    void setPassword (string &shareId, string &password);

    /***********************************************************
    Set the share to be public upload
    
     * @param publicUpload Set or remove public upload
    ***********************************************************/
    void setPublicUpload (string &shareId, bool publicUpload);

    /***********************************************************
    Change the name of a share
    ***********************************************************/
    void setName (string &shareId, string &name);

    /***********************************************************
    Set the permissions
    
     * @param permissions
    ***********************************************************/
    void setPermissions (string &shareId,
        const Share.Permissions permissions);

    /***********************************************************
    Set share link label
    ***********************************************************/
    void setLabel (string &shareId, string &label);

    /***********************************************************
    Create a new link share
    
    @param path The path of the file/folder to share
     * @param password Optionally a password for the share
    ***********************************************************/
    void createLinkShare (string &path, string &name,
        const string &password);

    /***********************************************************
    Create a new share
    
    @param path The path of the file/folder to share
    @param shareType The type of share (user/group/link/fed
    @param shareWith The uid/gid/federated id to share wit
    @param permissions The permissions the share will have
     * @param password The password to protect the share with
    ***********************************************************/
    void createShare (string &path,
        const Share.ShareType shareType,
        const string &shareWith = "",
        const Share.Permissions permissions = SharePermissionRead,
        const string &password = "");

    /***********************************************************
    Returns information on the items shared with the current user.
    ***********************************************************/
    void getSharedWithMe ();

signals:
    /***********************************************************
    Result of the OCS request
    The value parameter is only set if this was a put request.
    e.g. if we set the password to 'foo' the QVariant will hold a string with 'foo'.
    This is needed so we can update the share objects properly
    
    @param reply The reply
     * @param value To what did we set a variable (if we set any).
    ***********************************************************/
    void shareJobFinished (QJsonDocument reply, QVariant value);

private slots:
    void jobDone (QJsonDocument reply);

private:
    QVariant _value;
};
}











namespace Occ {

    OcsShareJob.OcsShareJob (AccountPtr account)
        : OcsJob (account) {
        setPath ("ocs/v2.php/apps/files_sharing/api/v1/shares");
        connect (this, &OcsJob.jobFinished, this, &OcsShareJob.jobDone);
    }
    
    void OcsShareJob.getShares (string &path) {
        setVerb ("GET");
    
        addParam (string.fromLatin1 ("path"), path);
        addParam (string.fromLatin1 ("reshares"), string ("true"));
        addPassStatusCode (404);
    
        start ();
    }
    
    void OcsShareJob.deleteShare (string &shareId) {
        appendPath (shareId);
        setVerb ("DELETE");
    
        start ();
    }
    
    void OcsShareJob.setExpireDate (string &shareId, QDate &date) {
        appendPath (shareId);
        setVerb ("PUT");
    
        if (date.isValid ()) {
            addParam (string.fromLatin1 ("expireDate"), date.toString ("yyyy-MM-dd"));
        } else {
            addParam (string.fromLatin1 ("expireDate"), string ());
        }
        _value = date;
    
        start ();
    }
    
    void OcsShareJob.setPassword (string &shareId, string &password) {
        appendPath (shareId);
        setVerb ("PUT");
    
        addParam (string.fromLatin1 ("password"), password);
        _value = password;
    
        start ();
    }
    
    void OcsShareJob.setNote (string &shareId, string &note) {
        appendPath (shareId);
        setVerb ("PUT");
    
        addParam (string.fromLatin1 ("note"), note);
        _value = note;
    
        start ();
    }
    
    void OcsShareJob.setPublicUpload (string &shareId, bool publicUpload) {
        appendPath (shareId);
        setVerb ("PUT");
    
        const string value = string.fromLatin1 (publicUpload ? "true" : "false");
        addParam (string.fromLatin1 ("publicUpload"), value);
        _value = publicUpload;
    
        start ();
    }
    
    void OcsShareJob.setName (string &shareId, string &name) {
        appendPath (shareId);
        setVerb ("PUT");
        addParam (string.fromLatin1 ("name"), name);
        _value = name;
    
        start ();
    }
    
    void OcsShareJob.setPermissions (string &shareId,
        const Share.Permissions permissions) {
        appendPath (shareId);
        setVerb ("PUT");
    
        addParam (string.fromLatin1 ("permissions"), string.number (permissions));
        _value = (int)permissions;
    
        start ();
    }
    
    void OcsShareJob.setLabel (string &shareId, string &label) {
        appendPath (shareId);
        setVerb ("PUT");
    
        addParam (QStringLiteral ("label"), label);
        _value = label;
    
        start ();
    }
    
    void OcsShareJob.createLinkShare (string &path,
        const string &name,
        const string &password) {
        setVerb ("POST");
    
        addParam (string.fromLatin1 ("path"), path);
        addParam (string.fromLatin1 ("shareType"), string.number (Share.TypeLink));
    
        if (!name.isEmpty ()) {
            addParam (string.fromLatin1 ("name"), name);
        }
        if (!password.isEmpty ()) {
            addParam (string.fromLatin1 ("password"), password);
        }
    
        addPassStatusCode (403);
    
        start ();
    }
    
    void OcsShareJob.createShare (string &path,
        const Share.ShareType shareType,
        const string &shareWith,
        const Share.Permissions permissions,
        const string &password) {
        Q_UNUSED (permissions)
        setVerb ("POST");
    
        addParam (string.fromLatin1 ("path"), path);
        addParam (string.fromLatin1 ("shareType"), string.number (shareType));
        addParam (string.fromLatin1 ("shareWith"), shareWith);
    
        if (!password.isEmpty ()) {
            addParam (string.fromLatin1 ("password"), password);
        }
    
        start ();
    }
    
    void OcsShareJob.getSharedWithMe () {
        setVerb ("GET");
        addParam (QLatin1String ("shared_with_me"), QLatin1String ("true"));
        start ();
    }
    
    void OcsShareJob.jobDone (QJsonDocument reply) {
        emit shareJobFinished (reply, _value);
    }
    }
    