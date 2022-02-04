

//  #include <Gtk.Widget>
//  #include <QWeb_engine_page>
//  #include <QWeb_engine_profile>
//  #include <QWeb_engine_url_request_interceptor>
//  #include <QWeb_engine_url_request_job>
//  #includeVERSION >= 0x051200
//  #include <QWeb_engine_url_scheme>
//  #include
//  #include <QWeb_engine_url_s
//  #include <QWeb_engine_v
//  #include <QDesktopServices>
//  #include <QProgres
//  #include <QLoggingCategory>
//  #include <QLocale>
//  #include <QWeb_engine_certificate_error>
//  #include <QMessageBox>


namespace Occ {


class WebView : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public WebView (Gtk.Widget parent = null);
    ~WebView () override;
    public void set_url (GLib.Uri url);

signals:
    void on_url_catched (string user, string pass, string host);


    /***********************************************************
    ***********************************************************/
    private Ui_Web_view this.ui;

    /***********************************************************
    ***********************************************************/
    private QWeb_engine_view this.webview;
    private QWeb_engine_profile this.profile;
    private Web_engine_page this.page;

    /***********************************************************
    ***********************************************************/
    private Web_view_page_url_request_interceptor this.interceptor;
    private Web_view_page_url_scheme_handler this.scheme_handler;
}





WebView.WebView (Gtk.Widget parent)
    : Gtk.Widget (parent),
      this.ui () {
    this.ui.setup_ui (this);
#if QT_VERSION >= 0x051200
    QWeb_engine_url_scheme this.ncsheme ("nc");
    QWeb_engine_url_scheme.register_scheme (this.ncsheme);
#endif
    this.webview = new QWeb_engine_view (this);
    this.profile = new QWeb_engine_profile (this);
    this.page = new Web_engine_page (this.profile);
    this.interceptor = new Web_view_page_url_request_interceptor (this);
    this.scheme_handler = new Web_view_page_url_scheme_handler (this);

    const string user_agent (Utility.user_agent_"");
    this.profile.set_http_user_agent (user_agent);
    QWeb_engine_profile.default_profile ().set_http_user_agent (user_agent);
    this.profile.set_request_interceptor (this.interceptor);
    this.profile.install_url_scheme_handler ("nc", this.scheme_handler);


    /***********************************************************
    Set a proper accept langauge to the language of the client
    code from : http://code.qt.io/cgit/qt/qtbase.git/tree/src/network/access/qhttpnetworkconnection
    ***********************************************************/ {
        string system_locale = QLocale.system ().name ().replace (char.from_latin1 ('this.'),char.from_latin1 ('-'));
        string accept_language;
        if (system_locale == QLatin1String ("C")) {
            accept_language = string.from_latin1 ("en,*");
        } else if (system_locale.starts_with (QLatin1String ("en-"))) {
            accept_language = system_locale + QLatin1String (",*");
        } else {
            accept_language = system_locale + QLatin1String (",en,*");
        }
        this.profile.set_http_accept_language (accept_language);
    }

    this.webview.set_page (this.page);
    this.ui.vertical_layout.add_widget (this.webview);

    connect (this.webview, &QWeb_engine_view.load_progress, this.ui.progress_bar, &QProgressBar.set_value);
    connect (this.scheme_handler, &Web_view_page_url_scheme_handler.on_url_catched, this, &WebView.on_url_catched);
}

void WebView.set_url (GLib.Uri url) {
    this.page.set_url (url);
}

WebView.~WebView () {
    /***********************************************************
    The Qt implmentation deletes children in the order they are added to the
    object tree, so in this case this.page is deleted after this.profile, which
    violates the assumption that this.profile should exist longer than
    this.page [1]. Here I delete this.page manually so that this.profile can be safely
    deleted later.

    [1] https://doc.qt.io/qt-5/qwebenginepage.html#QWeb_engine_page-1
    ***********************************************************/
    delete this.page;
}


}

#include "webview.moc"
