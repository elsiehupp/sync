
// #include <Gtk.Dialog>
// #include <QUrl>
// #include <QVBoxLayout>
// #include <QLabel>

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE


namespace Occ {

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE

class WebFlowCredentialsDialog : Gtk.Dialog {

    public WebFlowCredentialsDialog (Account *account, bool use_flow2, Gtk.Widget *parent = nullptr);

    public void set_url (QUrl &url);
    public void set_info (string &msg);
    public void set_error (string &error);

    public bool is_using_flow2 () {
        return _use_flow2;
    }

protected:
    void close_event (QCloseEvent * e) override;
    void change_event (QEvent *) override;

public slots:
    void slot_flow_2_auth_result (Flow2Auth.Result, string &error_string, string &user, string &app_password);
    void slot_show_settings_dialog ();

signals:
    void url_catched (string user, string pass, string host);
    void style_changed ();
    void on_activate ();
    void on_close ();

private:
    void customize_style ();

    bool _use_flow2;

    Flow2AuthWidget *_flow_2_auth_widget;
#ifdef WITH_WEBENGINE
    WebView *_web_view;
#endif // WITH_WEBENGINE

    QLabel *_error_label;
    QLabel *_info_label;
    QVBoxLayout *_layout;
    QVBoxLayout *_container_layout;
    HeaderBanner *_header_banner;
};

WebFlowCredentialsDialog.WebFlowCredentialsDialog (Account *account, bool use_flow2, Gtk.Widget *parent)
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

        connect (_flow_2_auth_widget, &Flow2AuthWidget.auth_result, this, &WebFlowCredentialsDialog.slot_flow_2_auth_result);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &WebFlowCredentialsDialog.style_changed, _flow_2_auth_widget, &Flow2AuthWidget.slot_style_changed);

        // allow Flow2 page to poll on window activation
        connect (this, &WebFlowCredentialsDialog.on_activate, _flow_2_auth_widget, &Flow2AuthWidget.slot_poll_now);

        _flow_2_auth_widget.start_auth (account);
    } else {
#ifdef WITH_WEBENGINE
        _web_view = new WebView ();
        _container_layout.add_widget (_web_view);

        connect (_web_view, &WebView.url_catched, this, &WebFlowCredentialsDialog.url_catched);
#endif // WITH_WEBENGINE
    }

    auto app = static_cast<Application> (q_app);
    connect (app, &Application.is_showing_settings_dialog, this, &WebFlowCredentialsDialog.slot_show_settings_dialog);

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

    emit on_close ();
}

void WebFlowCredentialsDialog.set_url (QUrl &url) {
#ifdef WITH_WEBENGINE
    if (_web_view)
        _web_view.set_url (url);
#else // WITH_WEBENGINE
    Q_UNUSED (url);
#endif // WITH_WEBENGINE
}

void WebFlowCredentialsDialog.set_info (string &msg) {
    _info_label.set_text (msg);
}

void WebFlowCredentialsDialog.set_error (string &error) {
    // bring window to top
    slot_show_settings_dialog ();

    if (_use_flow2 && _flow_2_auth_widget) {
        _flow_2_auth_widget.set_error (error);
        return;
    }

    if (error.is_empty ()) {
        _error_label.hide ();
    } else {
        _error_label.set_text (error);
        _error_label.show ();
    }
}

void WebFlowCredentialsDialog.change_event (QEvent *e) {
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
            emit on_activate ();
        break;
    default:
        break;
    }

    Gtk.Dialog.change_event (e);
}

void WebFlowCredentialsDialog.customize_style () {
    // HINT : Customize dialog's own style here, if necessary in the future (Dark-/Light-Mode switching)
}

void WebFlowCredentialsDialog.slot_show_settings_dialog () {
    // bring window to top but slightly delay, to avoid being hidden behind the SettingsDialog
    QTimer.single_shot (100, this, [this] {
        OwncloudGui.raise_dialog (this);
    });
}

void WebFlowCredentialsDialog.slot_flow_2_auth_result (Flow2Auth.Result r, string &error_string, string &user, string &app_password) {
    Q_UNUSED (error_string)
    if (r == Flow2Auth.LoggedIn) {
        emit url_catched (user, app_password, string ());
    } else {
        // bring window to top
        slot_show_settings_dialog ();
    }
}

} // namespace Occ
