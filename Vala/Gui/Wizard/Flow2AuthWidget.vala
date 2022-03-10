/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

class Flow2AuthWidget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private Account account = null;
    private QScopedPointer<Flow2Auth> async_auth;
    private Ui_Flow2Auth_widget ui;

    /***********************************************************
    ***********************************************************/
    private QProgressIndicator progress_indicator;
    private int status_update_skip_count = 0;

    signal void auth_result (Flow2Auth.Result, string error_string, string user, string app_password);
    signal void poll_now ();

    /***********************************************************
    ***********************************************************/
    public Flow2AuthWidget (Gtk.Widget parent = null);

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
    public void on_signal_auth_result (Flow2Auth.Result, string error_string, string user,


    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now ();


    /***********************************************************
    ***********************************************************/
    public void on_signal_status_changed (Flow2Auth.PollStatus status, int seconds_left);


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed ();


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_browser ();


    /***********************************************************
    ***********************************************************/
    protected void on_signal_copy_link_to_clipboard ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_spinner ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner (bool show_status_label);


    /***********************************************************
    ***********************************************************/
    private void customize_style ();


    /***********************************************************
    ***********************************************************/
    private void logo ();
}

} // namespace Occ
