
// #include <Gtk.Dialog>
// #include <GLib.Uri>
// #include <QVBoxLayout>
// #include <QLabel>

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE


namespace Occ {

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE

class WebFlowCredentialsDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsDialog (Account account, bool use_flow2, Gtk.Widget parent = nullptr);

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
        return _use_flow2;
    }


    protected void close_event (QCloseEvent * e) override;
    protected void change_event (QEvent *) override;


    /***********************************************************
    ***********************************************************/
    public void on_flow_2_auth_result (Flow2Auth.Result, string error_string, string user, string app_password);

    /***********************************************************
    ***********************************************************/
    public 
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
    private bool _use_flow2;

    Flow2AuthWidget _flow_2_auth_widget;
#ifdef WITH_WEBENGINE
    private WebView _web_view;
#endif // WITH_WEBENGINE

    /***********************************************************
    ***********************************************************/
    private QLabel _error_label;
    private QLabel _info_label;
    private QVBoxLayout _layout;
    private QVBoxLayout _container_layout;
    private HeaderBanner _header_banner;
};

WebFlowCredentialsDialog.WebFlowCredentialsDialog (Account account, bool use_flow2, Gtk.Widget parent)
    : Gtk.Dialog (parent)
    , _use_flow2 (use_flow2)
    , _flow_2_auth_widget (nullptr)
#ifdef WITH_WEBENGINE
    , _web_view (nullptr)
#endif // WITH_WEBENGINE {
    set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);

    _layout = new QVBoxLayout (this);
    int spacing = _layout.spacing ();
    int margin = _layout.margin ();
    _layout.set_spacing (0);
    _layout.set_margin (0);

    _container_layout = new QVBoxLayout (this);
    _container_layout.set_spacing (spacing);
    _container_layout.set_margin (margin);

    _info_label = new QLabel ();
    _info_label.set_alignment (Qt.AlignCenter);
    _container_layout.add_widget (_info_label);

    if (_use_flow2) {
        _flow_2_auth_widget = new Flow2AuthWidget ();
        _container_layout.add_widget (_flow_2_auth_widget);

        connect (_flow_2_auth_widget, &Flow2AuthWidget.auth_result, this, &WebFlowCredentialsDialog.on_flow_2_auth_result);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &WebFlowCredentialsDialog.style_changed, _flow_2_auth_widget, &Flow2AuthWidget.on_style_changed);

        // allow Flow2 page to poll on window activation
        connect (this, &WebFlowCredentialsDialog.on_activate, _flow_2_auth_widget, &Flow2AuthWidget.on_poll_now);

        _flow_2_auth_widget.start_auth (account);
    } else {
#ifdef WITH_WEBENGINE
        _web_view = new WebView ();
        _container_layout.add_widget (_web_view);

        connect (_web_view, &WebView.on_url_catched, this, &WebFlowCredentialsDialog.on_url_catched);
#endif // WITH_WEBENGINE
    }

    var app = static_cast<Application> (q_app);
    connect (app, &Application.is_showing_settings_dialog, this, &WebFlowCredentialsDialog.on_show_settings_dialog);

    _error_label = new QLabel ();
    _error_label.hide ();
    _container_layout.add_widget (_error_label);

    WizardCommon.init_error_label (_error_label);

    _layout.add_layout (_container_layout);
    set_layout (_layout);

    customize_style ();
}

void WebFlowCredentialsDialog.close_event (QCloseEvent* e) {
    Q_UNUSED (e)

#ifdef WITH_WEBENGINE
    if (_web_view) {
        // Force calling WebView.~WebView () earlier so that _profile and _page are
        // deleted in the correct order.
        _web_view.delete_later ();
        _web_view = nullptr;
    }
#endif // WITH_WEBENGINE

    if (_flow_2_auth_widget) {
        _flow_2_auth_widget.reset_auth ();
        _flow_2_auth_widget.delete_later ();
        _flow_2_auth_widget = nullptr;
    }

    emit close ();
}

void WebFlowCredentialsDialog.set_url (GLib.Uri url) {
#ifdef WITH_WEBENGINE
    if (_web_view)
        _web_view.set_url (url);
#else // WITH_WEBENGINE
    Q_UNUSED (url);
#endif // WITH_WEBENGINE
}

void WebFlowCredentialsDialog.set_info (string msg) {
    _info_label.on_set_text (msg);
}

void WebFlowCredentialsDialog.set_error (string error) {
    // bring window to top
    on_show_settings_dialog ();

    if (_use_flow2 && _flow_2_auth_widget) {
        _flow_2_auth_widget.set_error (error);
        return;
    }

    if (error.is_empty ()) {
        _error_label.hide ();
    } else {
        _error_label.on_set_text (error);
        _error_label.show ();
    }
}

void WebFlowCredentialsDialog.change_event (QEvent e) {
    switch (e.type ()) {
    case QEvent.StyleChange:
    case QEvent.PaletteChange:
    case QEvent.ThemeChange:
        customize_style ();

        // Notify the other widgets (Dark-/Light-Mode switching)
        emit style_changed ();
        break;
    case QEvent.ActivationChange:
        if (is_active_window ())
            emit activate ();
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
    Q_UNUSED (error_string)
    if (r == Flow2Auth.LoggedIn) {
        emit url_catched (user, app_password, "");
    } else {
        // bring window to top
        on_show_settings_dialog ();
    }
}

} // namespace Occ
