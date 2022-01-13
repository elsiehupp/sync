/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QVector>
// #include <QList>
// #include <QPair>


namespace Occ {

/**
@brief The OcsShareJob class
@ingroup gui

Handle talking to the OCS Share API.
For creation, deletion and modification of shares.
*/
class OcsShareJob : OcsJob {
public:
    /**
     * Constructor for new shares or listing of shares
     */
    OcsShareJob (AccountPtr account);

    /**
     * Get all the shares
     *
     * @param path Path to request shares for (default all shares)
     */
    void getShares (QString &path = "");

    /**
     * Delete the current Share
     */
    void deleteShare (QString &shareId);

    /**
     * Set the expiration date of a share
     *
     * @param date The expire date, if this date is invalid the expire date
     * will be removed
     */
    void setExpireDate (QString &shareId, QDate &date);

	 /**
     * Set note a share
     *
     * @param note The note to a share, if the note is empty the
     * share will be removed
     */
    void setNote (QString &shareId, QString &note);

    /**
     * Set the password of a share
     *
     * @param password The password of the share, if the password is empty the
     * share will be removed
     */
    void setPassword (QString &shareId, QString &password);

    /**
     * Set the share to be public upload
     *
     * @param publicUpload Set or remove public upload
     */
    void setPublicUpload (QString &shareId, bool publicUpload);

    /**
     * Change the name of a share
     */
    void setName (QString &shareId, QString &name);

    /**
     * Set the permissions
     *
     * @param permissions
     */
    void setPermissions (QString &shareId,
        const Share.Permissions permissions);

    /**
     * Set share link label
     */
    void setLabel (QString &shareId, QString &label);

    /**
     * Create a new link share
     *
     * @param path The path of the file/folder to share
     * @param password Optionally a password for the share
     */
    void createLinkShare (QString &path, QString &name,
        const QString &password);

    /**
     * Create a new share
     *
     * @param path The path of the file/folder to share
     * @param shareType The type of share (user/group/link/federated)
     * @param shareWith The uid/gid/federated id to share with
     * @param permissions The permissions the share will have
     * @param password The password to protect the share with
     */
    void createShare (QString &path,
        const Share.ShareType shareType,
        const QString &shareWith = "",
        const Share.Permissions permissions = SharePermissionRead,
        const QString &password = "");

    /**
     * Returns information on the items shared with the current user.
     */
    void getSharedWithMe ();

signals:
    /**
     * Result of the OCS request
     * The value parameter is only set if this was a put request.
     * e.g. if we set the password to 'foo' the QVariant will hold a QString with 'foo'.
     * This is needed so we can update the share objects properly
     *
     * @param reply The reply
     * @param value To what did we set a variable (if we set any).
     */
    void shareJobFinished (QJsonDocument reply, QVariant value);

private slots:
    void jobDone (QJsonDocument reply);

private:
    QVariant _value;
};
}
