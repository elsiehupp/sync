

// #include <QUrl>
// #include <Gtk.Widget>
// #include <QWeb_engine_page>
// #include <QWeb_engine_profile>
// #include <QWeb_engine_url_request_interceptor>
// #include <QWeb_engine_url_request_job>
#if QT_VERSION >= 0x051200
// #include <QWeb_engine_url_scheme>
#endif
// #include <QWeb_engine_url_scheme_handler>
// #include <QWeb_engine_view>
// #include <QDesktopServices>
// #include <QProgressBar>
// #include <QLoggingCategory>
// #include <QLocale>
// #include <QWeb_engine_certificate_error>
// #include <QMessageBox>


namespace Occ {


class WebView : Gtk.Widget {

    public WebView (Gtk.Widget parent = nullptr);
    ~WebView () override;
    public void set_url (QUrl url);

signals:
    void on_url_catched (string user, string pass, string host);


    private Ui_Web_view _ui;

    private QWeb_engine_view _webview;
    private QWeb_engine_profile _profile;
    private Web_engine_page _page;

    private Web_view_page_url_request_interceptor _interceptor;
    private Web_view_page_url_scheme_handler _scheme_handler;
};


class Web_view_page_url_request_interceptor : QWeb_engine_url_request_interceptor {

    public Web_view_page_url_request_interceptor (GLib.Object parent = nullptr);


    public void intercept_request (QWeb_engine_url_request_info &info) override;
};

class Web_view_page_url_scheme_handler : QWeb_engine_url_scheme_handler {

    public Web_view_page_url_scheme_handler (GLib.Object parent = nullptr);


    public void request_started (QWeb_engine_url_request_job request) override;

signals:
    void on_url_catched (string user, string pass, string host);
};

class Web_engine_page : QWeb_engine_page {

    public Web_engine_page (QWeb_engine_profile profile, GLib.Object* parent = nullptr);


    public QWeb_engine_page * create_window (QWeb_engine_page.Web_window_type type) override;
    public void set_url (QUrl url);


    protected bool certificate_error (QWeb_engine_certificate_error &certificate_error) override;

    protected bool accept_navigation_request (QUrl url, QWeb_engine_page.Navigation_type type, bool is_main_frame) override;


    private bool _enforce_https = false;
};

// We need a separate class here, since we cannot simply return the same Web_engine_page object
// this leads to a strage segfault somewhere deep inside of the QWeb_engine code
class External_web_engine_page : QWeb_engine_page {

    public External_web_engine_page (QWeb_engine_profile profile, GLib.Object* parent = nullptr);


    public bool accept_navigation_request (QUrl url, QWeb_engine_page.Navigation_type type, bool is_main_frame) override;
};

WebView.WebView (Gtk.Widget parent)
    : Gtk.Widget (parent),
      _ui () {
    _ui.setup_ui (this);
#if QT_VERSION >= 0x051200
    QWeb_engine_url_scheme _ncsheme ("nc");
    QWeb_engine_url_scheme.register_scheme (_ncsheme);
#endif
    _webview = new QWeb_engine_view (this);
    _profile = new QWeb_engine_profile (this);
    _page = new Web_engine_page (_profile);
    _interceptor = new Web_view_page_url_request_interceptor (this);
    _scheme_handler = new Web_view_page_url_scheme_handler (this);

    const string user_agent (Utility.user_agent_string ());
    _profile.set_http_user_agent (user_agent);
    QWeb_engine_profile.default_profile ().set_http_user_agent (user_agent);
    _profile.set_request_interceptor (_interceptor);
    _profile.install_url_scheme_handler ("nc", _scheme_handler);


    /***********************************************************
    Set a proper accept langauge to the language of the client
    code from : http://code.qt.io/cgit/qt/qtbase.git/tree/src/network/access/qhttpnetworkconnection
    ***********************************************************/ {
        string system_locale = QLocale.system ().name ().replace (QChar.from_latin1 ('_'),QChar.from_latin1 ('-'));
        string accept_language;
        if (system_locale == QLatin1String ("C")) {
            accept_language = string.from_latin1 ("en,*");
        } else if (system_locale.starts_with (QLatin1String ("en-"))) {
            accept_language = system_locale + QLatin1String (",*");
        } else {
            accept_language = system_locale + QLatin1String (",en,*");
        }
        _profile.set_http_accept_language (accept_language);
    }

    _webview.set_page (_page);
    _ui.vertical_layout.add_widget (_webview);

    connect (_webview, &QWeb_engine_view.load_progress, _ui.progress_bar, &QProgressBar.set_value);
    connect (_scheme_handler, &Web_view_page_url_scheme_handler.on_url_catched, this, &WebView.on_url_catched);
}

void WebView.set_url (QUrl url) {
    _page.set_url (url);
}

WebView.~WebView () {
    /***********************************************************
    The Qt implmentation deletes children in the order they are added to the
    object tree, so in this case _page is deleted after _profile, which
    violates the assumption that _profile should exist longer than
    _page [1]. Here I delete _page manually so that _profile can be safely
    deleted later.

    [1] https://doc.qt.io/qt-5/qwebenginepage.html#QWeb_engine_page-1
    ***********************************************************/
    delete _page;
}

Web_view_page_url_request_interceptor.Web_view_page_url_request_interceptor (GLib.Object parent)
    : QWeb_engine_url_request_interceptor (parent) {

}

void Web_view_page_url_request_interceptor.intercept_request (QWeb_engine_url_request_info &info) {
    info.set_http_header ("OCS-APIREQUEST", "true");
}

Web_view_page_url_scheme_handler.Web_view_page_url_scheme_handler (GLib.Object parent)
    : QWeb_engine_url_scheme_handler (parent) {

}

void Web_view_page_url_scheme_handler.request_started (QWeb_engine_url_request_job request) {
    QUrl url = request.request_url ();

    string path = url.path ().mid (1); // get undecoded path
    const string[] parts = path.split ("&");

    string server;
    string user;
    string password;

    for (string part : parts) {
        if (part.starts_with ("server:")) {
            server = part.mid (7);
        } else if (part.starts_with ("user:")) {
            user = part.mid (5);
        } else if (part.starts_with ("password:")) {
            password = part.mid (9);
        }
    }

    q_c_debug (lc_wizard_webiew ()) << "Got raw user from request path : " << user;

    user = user.replace (QChar ('+'), QChar (' '));
    password = password.replace (QChar ('+'), QChar (' '));

    user = QUrl.from_percent_encoding (user.to_utf8 ());
    password = QUrl.from_percent_encoding (password.to_utf8 ());

    if (!server.starts_with ("http://") && !server.starts_with ("https://")) {
        server = "https://" + server;
    }
    q_c_info (lc_wizard_webiew ()) << "Got user : " << user << ", server : " << server;

    emit url_catched (user, password, server);
}

Web_engine_page.Web_engine_page (QWeb_engine_profile profile, GLib.Object* parent) : QWeb_engine_page (profile, parent) {

}

QWeb_engine_page * Web_engine_page.create_window (QWeb_engine_page.Web_window_type type) {
    Q_UNUSED (type);
    var view = new External_web_engine_page (this.profile ());
    return view;
}

void Web_engine_page.set_url (QUrl url) {
    QWeb_engine_page.set_url (url);
    _enforce_https = url.scheme () == QStringLiteral ("https");
}

bool Web_engine_page.certificate_error (QWeb_engine_certificate_error &certificate_error) {
    /***********************************************************
    TODO properly improve this.
    The certificate should be displayed.

    Or rather we should do a request with the QNAM and see if it works (then it is in the store).
    This is just a quick fix for now.
    ***********************************************************/
    QMessageBox message_box;
    message_box.on_set_text (tr ("Invalid certificate detected"));
    message_box.set_informative_text (tr ("The host \"%1\" provided an invalid certificate. Continue?").arg (certificate_error.url ().host ()));
    message_box.set_icon (QMessageBox.Warning);
    message_box.set_standard_buttons (QMessageBox.Yes|QMessageBox.No);
    message_box.set_default_button (QMessageBox.No);

    int ret = message_box.exec ();

    return ret == QMessageBox.Yes;
}

bool Web_engine_page.accept_navigation_request (QUrl url, QWeb_engine_page.Navigation_type type, bool is_main_frame) {
    Q_UNUSED (type);
    Q_UNUSED (is_main_frame);

    if (_enforce_https && url.scheme () != QStringLiteral ("https") && url.scheme () != QStringLiteral ("nc")) {
        QMessageBox.warning (nullptr, "Security warning", "Can not follow non https link on a https website. This might be a security issue. Please contact your administrator");
        return false;
    }
    return true;
}

External_web_engine_page.External_web_engine_page (QWeb_engine_profile profile, GLib.Object* parent) : QWeb_engine_page (profile, parent) {

}

bool External_web_engine_page.accept_navigation_request (QUrl url, QWeb_engine_page.Navigation_type type, bool is_main_frame) {
    Q_UNUSED (type);
    Q_UNUSED (is_main_frame);
    Utility.open_browser (url);
    return false;
}

}

#include "webview.moc"
