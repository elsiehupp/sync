/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public class Flow2AuthWidget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private Account account = null;
    private QScopedPointer<Flow2Auth> async_auth;
    private Ui_Flow2Auth_widget ui;

    /***********************************************************
    ***********************************************************/
    private QProgressIndicator progress_indicator;
    private int status_update_skip_count = 0;

    internal signal void auth_result (Flow2Auth.Result result, string error_string, string user, string app_password);
    internal signal void poll_now ();

    /***********************************************************
    ***********************************************************/
    public Flow2AuthWidget (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.progress_indicator = new QProgressIndicator (this);
        this.ui.setupUi (this);

        WizardCommon.initErrorLabel (this.ui.error_label);
        this.ui.error_label.setTextFormat (Qt.RichText);

        connect (this.ui.open_link_label, LinkLabel.clicked, this, Flow2AuthWidget.on_signal_open_browser);
        connect (this.ui.copy_link_label, LinkLabel.clicked, this, Flow2AuthWidget.on_signal_copy_link_to_clipboard);

        var size_policy = this.progress_indicator.size_policy ();
        size_policy.retain_size_when_hidden (true);
        this.progress_indicator.setSizePolicy (size_policy);

        this.ui.progress_layout.add_widget (this.progress_indicator);
        stop_spinner (false);

        customize_style ();
    }


    ~Flow2AuthWidget () {
        // Forget sensitive data
        this.async_auth.reset ();
    }


    /***********************************************************
    ***********************************************************/
    public void start_auth (Account account) {
        Flow2Auth old_auth = this.async_auth.take ();
        if (old_auth) {
            old_auth.deleteLater ();
        }

        this.status_update_skip_count = 0;

        if (account) {
            this.account = account;

            this.async_auth.reset (new Flow2Auth (this.account, this));
            connect (this.async_auth, Flow2Auth.result, this, Flow2AuthWidget.slotAuthResult, Qt.QueuedConnection);
            connect (this.async_auth, Flow2Auth.status_changed, this, Flow2AuthWidget.slotStatusChanged);
            connect (this, Flow2AuthWidget.poll_now, this.async_auth, Flow2Auth.slotPollNow);
            this.async_auth.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void reauth (Account account) {
        start_auth (account);
    }


    /***********************************************************
    ***********************************************************/
    public void error (string error) {
        if (error == "") {
            this.ui.error_label.hide ();
        } else {
            this.ui.error_label.text (error);
            this.ui.error_label.show ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_auth_result (Flow2Auth.Result r, string error_string, string user, string application_password) {
        stop_spinner (false);

        switch (r) {
        case Flow2Auth.NotSupported:
            /* Flow2Auth can't open browser */
            this.ui.error_label.text (_("Unable to open the Browser, please copy the link to your Browser."));
            this.ui.error_label.show ();
            break;
        case Flow2Auth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            this.ui.error_label.text (error_string);
            this.ui.error_label.show ();
            break;
        case Flow2Auth.LoggedIn: {
            this.ui.error_label.hide ();
            break;
        }
        }

        /* emit */ auth_result (r, error_string, user, application_password);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now () {
        /* emit */ poll_now ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_status_changed (Flow2Auth.PollStatus status, int seconds_left) {
        switch (status) {
        case Flow2Auth.statusPollCountdown:
            if (this.status_update_skip_count > 0) {
                this.status_update_skip_count--;
                break;
            }
            this.ui.status_label.setext (_("Waiting for authorization") + string ("… (%1)").printf (secondsLeft));
            stop_spinner (true);
            break;
        case Flow2Auth.statusPollNow:
            this.status_update_skip_count = 0;
            this.ui.status_label.text (_("Polling for authorization") + "…");
            startSpinner ();
            break;
        case Flow2Auth.statusFetchToken:
            this.status_update_skip_count = 0;
            this.ui.status_label.text (_("Starting authorization") + "…");
            startSpinner ();
            break;
        case Flow2Auth.statusCopyLinkToClipboard:
            this.ui.status_label.text (_("Link copied to clipboard."));
            this.status_update_skip_count = 3;
            stop_spinner (true);
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_browser () {
        if (this.ui.error_label) {
            this.ui.error_label.hide ();
        }

        if (this.async_auth) {
            this.async_auth.openBrowser ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_copy_link_to_clipboard () {
        if (this.ui.error_label) {
            this.ui.error_label.hide ();
        }

        if (this.async_auth) {
            this.async_auth.copy_link_to_clipboard ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_spinner () {
        this.ui.progress_layout.enabled (true);
        this.ui.status_label.visible (true);
        this.progress_indicator.visible (true);
        this.progress_indicator.start_animation ();

        this.ui.open_link_label.enabled (false);
        this.ui.copy_link_label.enabled (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner (bool show_status_label) {
        this.ui.progress_layout.enabled (false);
        this.ui.status_label.visible (show_status_label);
        this.progress_indicator.visible (false);
        this.progress_indicator.stop_animation ();

        this.ui.open_link_label.enabled (this.status_update_skip_count == 0);
        this.ui.copy_link_label.enabled (this.status_update_skip_count == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        logo ();

        if (this.progress_indicator) {
            const bool is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                this.progress_indicator.color (Qt.white);
            } else {
                this.progress_indicator.color (Qt.black);
            }
        }

        this.ui.open_link_label.text (_("Reopen Browser"));
        this.ui.open_link_label.alignment (Qt.AlignCenter);

        this.ui.copy_link_label.text (_("Copy Link"));
        this.ui.copy_link_label.alignment (Qt.AlignCenter);

        WizardCommon.customize_hint_label (this.ui.status_label);
    }


    /***********************************************************
    ***********************************************************/
    private void logo () {
        const var background_color = palette ().window ().color ();
        const var logo_icon_filename = Theme.is_branded
            ? Theme.hidpi_filename ("external.png", background_color)
            : Theme.hidpi_filename (":/client/theme/colored/external.png");
        this.ui.logo_label.pixmap (logo_icon_filename);
    }

}

} // namespace Occ























} // namespace OCC
 