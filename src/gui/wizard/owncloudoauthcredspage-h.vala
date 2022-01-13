/*
 * Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #pragma once

// #include <QList>
// #include <QMap>
// #include <QNetworkCookie>
// #include <QUrl>
// #include <QPointer>

namespace OCC {

class OwncloudOAuthCredsPage : public AbstractCredentialsWizardPage {
public:
    OwncloudOAuthCredsPage ();

    AbstractCredentials *getCredentials () const override;

    void initializePage () override;
    void cleanupPage () override;
    int nextId () const override;
    void setConnected ();
    bool isComplete () const override;

public Q_SLOTS:
    void asyncAuthResult (OAuth::Result, QString &user, QString &token,
        const QString &reniewToken);

signals:
    void connectToOCUrl (QString &);

public:
    QString _user;
    QString _token;
    QString _refreshToken;
    QScopedPointer<OAuth> _asyncAuth;
    Ui_OwncloudOAuthCredsPage _ui;

protected slots:
    void slotOpenBrowser ();
    void slotCopyLinkToClipboard ();
};

} // namespace OCC
