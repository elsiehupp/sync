/*
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #pragma once

// #include <QList>
// #include <QMap>
// #include <QNetworkCookie>
// #include <QUrl>
// #include <QPointer>

class QProgressIndicator;

namespace Occ {

class Flow2AuthWidget;

class Flow2AuthCredsPage : AbstractCredentialsWizardPage {
public:
    Flow2AuthCredsPage ();

    AbstractCredentials *getCredentials () const override;

    void initializePage () override;
    void cleanupPage () override;
    int nextId () const override;
    void setConnected ();
    bool isComplete () const override;

public slots:
    void slotFlow2AuthResult (Flow2Auth.Result, QString &errorString, QString &user, QString &appPassword);
    void slotPollNow ();
    void slotStyleChanged ();

signals:
    void connectToOCUrl (QString &);
    void pollNow ();
    void styleChanged ();

public:
    QString _user;
    QString _appPassword;

private:
    Flow2AuthWidget *_flow2AuthWidget = nullptr;
    QVBoxLayout *_layout = nullptr;
};

} // namespace Occ
