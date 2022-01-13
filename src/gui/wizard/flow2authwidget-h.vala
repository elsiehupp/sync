/*
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

#ifndef FLOW2AUTHWIDGET_H
const int FLOW2AUTHWIDGET_H

// #include <QUrl>
// #include <QWidget>


namespace Occ {

class Flow2AuthWidget : QWidget {
public:
    Flow2AuthWidget (QWidget *parent = nullptr);
    ~Flow2AuthWidget () override;

    void startAuth (Account *account);
    void resetAuth (Account *account = nullptr);
    void setError (QString &error);

public slots:
    void slotAuthResult (Flow2Auth.Result, QString &errorString, QString &user, QString &appPassword);
    void slotPollNow ();
    void slotStatusChanged (Flow2Auth.PollStatus status, int secondsLeft);
    void slotStyleChanged ();

signals:
    void authResult (Flow2Auth.Result, QString &errorString, QString &user, QString &appPassword);
    void pollNow ();

private:
    Account *_account = nullptr;
    QScopedPointer<Flow2Auth> _asyncAuth;
    Ui_Flow2AuthWidget _ui;

protected slots:
    void slotOpenBrowser ();
    void slotCopyLinkToClipboard ();

private:
    void startSpinner ();
    void stopSpinner (bool showStatusLabel);
    void customizeStyle ();
    void setLogo ();

    QProgressIndicator *_progressIndi;
    int _statusUpdateSkipCount = 0;
};

} // namespace Occ
