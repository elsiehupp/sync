/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv???-or-later-Boilerplate>
***********************************************************/

#ifndef FLOW2AUTHWIDGET_H
const int FLOW2AUTHWIDGET_H

// #include <QUrl>
// #include <Gtk.Widget>


namespace Occ {

class Flow2AuthWidget : Gtk.Widget {
public:
    Flow2AuthWidget (Gtk.Widget *parent = nullptr);
    ~Flow2AuthWidget () override;

    void startAuth (Account *account);
    void resetAuth (Account *account = nullptr);
    void setError (string &error);

public slots:
    void slotAuthResult (Flow2Auth.Result, string &errorString, string &user, string &appPassword);
    void slotPollNow ();
    void slotStatusChanged (Flow2Auth.PollStatus status, int secondsLeft);
    void slotStyleChanged ();

signals:
    void authResult (Flow2Auth.Result, string &errorString, string &user, string &appPassword);
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
