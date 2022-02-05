
//  #include <Gtk.Dialog>
//  #include <QVBoxLayout>
//  #include <QLabel>

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE


namespace Occ {

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE

class WebFlowCredentialsDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsDialog (Account account, bool use_flow2, Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public void set_url (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_error (string error);

    public bool is_using_flow2 () {
        return this.use_flow2;
    }


    protected void close_event (QCloseEvent * e) override;
    protected void change_event (QEvent *) override;


    /***********************************************************
    ***********************************************************/
    public void on_flow_2_auth_result (Flow2Auth.Result, string error_string, string user, string app_password);

    /***********************************************************
    ***********************************************************/
    public void on_show_settings_dialog ();

signals:
    void on_url_catched (string user, string pass, string host);
    void style_changed ();
    void on_activate ();
    void on_close ();


    /***********************************************************
    ***********************************************************/
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private bool this.use_flow2;

    Flow2AuthWidget this.flow_2_auth_widget;
#ifdef WITH_WEBENGINE
    private WebView this.web_view;
#endif // WITH_WEBENGINE

    /***********************************************************
    ***********************************************************/
    private QLabel this.error_label;
    private QLabel this.info_label;
    private QVBoxLayout this.layout;
    private QVBoxLayout this.container_layout;
    private HeaderBanner this.header_banner;
}

WebFlowCredentialsDialog.WebFlowCredentialsDialog (Account account, bool use_flow2, Gtk.Widget parent)
    : Gtk.Dialog (parent)
    this.use_flow2 (use_flow2)
    this.flow_2_auth_widget (null)
#ifdef WITH_WEBENGINE
    this.web_view (null)
#endif // WITH_WEBENGINE {
    set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);

    this.layout = new QVBoxLayout (this);
    int spacing = this.layout.spacing ();
    int margin = this.layout.margin ();
    this.layout.set_spacing (0);
    this.layout.set_margin (0);

    this.container_layout = new QVBoxLayout (this);
    this.container_layout.set_spacing (spacing);
    this.container_layout.set_margin (margin);

    this.info_label = new QLabel ();
    this.info_label.set_alignment (Qt.AlignCenter);
    this.container_layout.add_widget (this.info_label);

    if (this.use_flow2) {
        this.flow_2_auth_widget = new Flow2AuthWidget ();
        this.container_layout.add_widget (this.flow_2_auth_widget);

        connect (this.flow_2_auth_widget, &Flow2AuthWidget.auth_result, this, &WebFlowCredentialsDialog.on_flow_2_auth_result);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &WebFlowCredentialsDialog.style_changed, this.flow_2_auth_widget, &Flow2AuthWidget.on_style_changed);

        // allow Flow2 page to poll on window activation
        connect (this, &WebFlowCredentialsDialog.on_activate, this.flow_2_auth_widget, &Flow2AuthWidget.on_poll_now);

        this.flow_2_auth_widget.start_auth (account);
    } else {
#ifdef WITH_WEBENGINE
        this.web_view = new WebView ();
        this.container_layout.add_widget (this.web_view);

        connect (this.web_view, &WebView.on_url_catched, this, &WebFlowCredentialsDialog.on_url_catched);
#endif // WITH_WEBENGINE
    }

    var app = static_cast<Application> (Gtk.Application);
    connect (app, &Application.is_showing_settings_dialog, this, &WebFlowCredentialsDialog.on_show_settings_dialog);

    this.error_label = new QLabel ();
    this.error_label.hide ();
    this.container_layout.add_widget (this.error_label);

    WizardCommon.init_error_label (this.error_label);

    this.layout.add_layout (this.container_layout);
    set_layout (this.layout);

    customize_style ();
}

void WebFlowCredentialsDialog.close_event (QCloseEvent* e) {
    //  Q_UNUSED (e)

#ifdef WITH_WEBENGINE
    if (this.web_view) {
        // Force calling WebView.~WebView () earlier so that this.profile and this.page are
        // deleted in the correct order.
        this.web_view.delete_later ();
        this.web_view = null;
    }
#endif // WITH_WEBENGINE

    if (this.flow_2_auth_widget) {
        this.flow_2_auth_widget.reset_auth ();
        this.flow_2_auth_widget.delete_later ();
        this.flow_2_auth_widget = null;
    }

    /* emit */ close ();
}

void WebFlowCredentialsDialog.set_url (GLib.Uri url) {
#ifdef WITH_WEBENGINE
    if (this.web_view)
        this.web_view.set_url (url);
#else // WITH_WEBENGINE
    //  Q_UNUSED (url);
#endif // WITH_WEBENGINE
}

void WebFlowCredentialsDialog.set_info (string msg) {
    this.info_label.on_set_text (msg);
}

void WebFlowCredentialsDialog.set_error (string error) {
    // bring window to top
    on_show_settings_dialog ();

    if (this.use_flow2 && this.flow_2_auth_widget) {
        this.flow_2_auth_widget.set_error (error);
        return;
    }

    if (error.is_empty ()) {
        this.error_label.hide ();
    } else {
        this.error_label.on_set_text (error);
        this.error_label.show ();
    }
}

void WebFlowCredentialsDialog.change_event (QEvent e) {
    switch (e.type ()) {
    case QEvent.StyleChange:
    case QEvent.PaletteChange:
    case QEvent.ThemeChange:
        customize_style ();

        // Notify the other widgets (Dark-/Light-Mode switching)
        /* emit */ style_changed ();
        break;
    case QEvent.ActivationChange:
        if (is_active_window ())
            /* emit */ activate ();
        break;
    default:
        break;
    }

    Gtk.Dialog.change_event (e);
}

void WebFlowCredentialsDialog.customize_style () {
    // HINT : Customize dialog's own style here, if necessary in the future (Dark-/Light-Mode switching)
}

void WebFlowCredentialsDialog.on_show_settings_dialog () {
    // bring window to top but slightly delay, to avoid being hidden behind the SettingsDialog
    QTimer.single_shot (100, this, [this] {
        OwncloudGui.raise_dialog (this);
    });
}

void WebFlowCredentialsDialog.on_flow_2_auth_result (Flow2Auth.Result r, string error_string, string user, string app_password) {
    //  Q_UNUSED (error_string)
    if (r == Flow2Auth.LoggedIn) {
        /* emit */ url_catched (user, app_password, "");
    } else {
        // bring window to top
        on_show_settings_dialog ();
    }
}

} // namespace Occ
