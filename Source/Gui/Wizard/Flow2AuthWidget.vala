/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
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

    void start_auth (Account *account);
    void reset_auth (Account *account = nullptr);
    void set_error (string &error);

public slots:
    void slot_auth_result (Flow2Auth.Result, string &error_string, string &user, string &app_password);
    void slot_poll_now ();
    void slot_status_changed (Flow2Auth.PollStatus status, int seconds_left);
    void slot_style_changed ();

signals:
    void auth_result (Flow2Auth.Result, string &error_string, string &user, string &app_password);
    void poll_now ();

private:
    Account *_account = nullptr;
    QScopedPointer<Flow2Auth> _async_auth;
    Ui_Flow2Auth_widget _ui;

protected slots:
    void slot_open_browser ();
    void slot_copy_link_to_clipboard ();

private:
    void start_spinner ();
    void stop_spinner (bool show_status_label);
    void customize_style ();
    void set_logo ();

    QProgress_indicator *_progress_indi;
    int _status_update_skip_count = 0;
};

} // namespace Occ
