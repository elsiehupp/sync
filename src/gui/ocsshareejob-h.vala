/*
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/


namespace Occ {

/**
@brief The OcsShareeJob class
@ingroup gui

Fetching sharees from the OCS Sharee API
*/
class OcsShareeJob : OcsJob {
public:
    OcsShareeJob (AccountPtr account);

    /**
     * Get a list of sharees
     *
     * @param path Path to request shares for (default all shares)
     */
    void getSharees (QString &search, QString &itemType, int page = 1, int perPage = 50, bool lookup = false);
signals:
    /**
     * Result of the OCS request
     *
     * @param reply The reply
     */
    void shareeJobFinished (QJsonDocument &reply);

private slots:
    void jobDone (QJsonDocument &reply);
};
}
