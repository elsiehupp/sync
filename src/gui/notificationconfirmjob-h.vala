/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

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
// #include <QUrl>

namespace Occ {

/**
@brief The NotificationConfirmJob class
@ingroup gui

Class to call an action-link of a notification coming from the server.
All the communication logic is handled in this class.

*/
class NotificationConfirmJob : AbstractNetworkJob {

public:
    NotificationConfirmJob (AccountPtr account);

    /**
     * @brief Set the verb and link for the job
     *
     * @param verb currently supported GET PUT POST DELETE
     */
    void setLinkAndVerb (QUrl &link, QByteArray &verb);

    /**
     * @brief Start the OCS request
     */
    void start () override;

signals:

    /**
     * Result of the OCS request
     *
     * @param reply the reply
     */
    void jobFinished (QString reply, int replyCode);

private slots:
    bool finished () override;

private:
    QByteArray _verb;
    QUrl _link;
};
}

#endif // NotificationConfirmJob_H
