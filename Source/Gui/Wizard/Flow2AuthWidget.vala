/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

#ifndef FLOW2AUTHWIDGET_H
const int FLOW2AUTHWIDGET_H

// #include <GLib.Uri>
// #include <Gtk.Widget>


namespace Occ {

class Flow2AuthWidget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public Flow2AuthWidget (Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void reset_auth (Account accoun

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_auth_result (Flow2Auth.Result, string error_string, string user,

    /***********************************************************
    ***********************************************************/
    public 
    public void on_poll_now ();


    public void on_status_changed (Flow2Auth.PollStatus status, int seconds_left);


    public void on_style_changed ();

signals:
    void auth_result (Flow2Auth.Result, string error_string, string user, string app_password);
    void poll_now ();


    /***********************************************************
    ***********************************************************/
    private Account this.account = nullptr;
    private QScopedPointer<Flow2Auth> this.async_auth;
    private Ui_Flow2Auth_widget this.ui;

protected slots:
    void on_open_browser ();
    void on_copy_link_to_clipboard ();


    /***********************************************************
    ***********************************************************/
    private void on_start_spinner ();
    private void on_stop_spinner (bool show_status_label);
    private void customize_style ();
    private void set_logo ();

    /***********************************************************
    ***********************************************************/
    private QProgress_indicator this.progress_indi;
    private int this.status_update_skip_count = 0;
};

} // namespace Occ
