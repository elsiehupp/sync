

//  #include <Gtk.Widget>
//  #include <QWebEnginePage>
//  #include <QWebEngineProfile>
//  #include <QWebEngineUrlRequestInterceptor>
//  #include <QWebEngineUrlRequestJob>
//  #includeVERSION >= 0x051200
//  #include <QWebEngineUrlScheme>
//  #include <QWeb_engine_url_s
//  #include <QWeb_engine_v
//  #include <QDesktopServices>
//  #include <QProgres
//  #include <QLoggingCategory>
//  #include <QLocale>
//  #include <QWebEngineCertificateError>
//  #include <Gtk.MessageBox>

namespace Occ {
namespace Ui {

public class WebView : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private UiWebView ui;

    /***********************************************************
    ***********************************************************/
    private QWebEngineView webview;
    private QWebEngineProfile profile;
    private WebEnginePage page;

    /***********************************************************
    ***********************************************************/
    private WebViewPageUrlRequestInterceptor interceptor;
    private WebViewPageUrlSchemeHandler scheme_handler;

    internal signal void signal_url_catched (string user, string pass, string host);

    /***********************************************************
    ***********************************************************/
    public WebView (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui;
        this.ui.up_ui (this);
        QWebEngineUrlScheme.register_scheme (new QWebEngineUrlScheme ("nc"));
        this.webview = new QWebEngineView (this);
        this.profile = new QWebEngineProfile (this);
        this.page = new WebEnginePage (this.profile);
        this.interceptor = new WebViewPageUrlRequestInterceptor (this);
        this.scheme_handler = new WebViewPageUrlSchemeHandler (this);

        const string user_agent = Utility.user_agent_string ();
        this.profile.http_user_agent (user_agent);
        QWebEngineProfile.default_profile ().http_user_agent (user_agent);
        this.profile.request_interceptor (this.interceptor);
        this.profile.install_url_scheme_handler ("nc", this.scheme_handler);


        /***********************************************************
        Set a proper accept langauge to the language of the client
        code from : http://code.qt.io/cgit/qt/qtbase.git/tree/src/network/access/qhttpnetworkconnection
        ***********************************************************/ {
            string system_locale = QLocale.system ().name ().replace (char.from_latin1 ('_'),char.from_latin1 ('-'));
            string accept_language;
            if (system_locale == "C") {
                accept_language = "en,*";
            } else if (system_locale.starts_with ("en-")) {
                accept_language = system_locale + ",*";
            } else {
                accept_language = system_locale + ",en,*";
            }
            this.profile.http_accept_language (accept_language);
        }

        this.webview.page (this.page);
        this.ui.vertical_layout.add_widget (this.webview);

        this.webview.load_progress.connect (
            this.ui.progress_bar.value
        );
        this.scheme_handler.signal_url_catched.connect (
            this.on_signal_url_catched
        );
    }


    /***********************************************************
    ***********************************************************/
    ~WebView () {
        /***********************************************************
        The Qt implmentation deletes children in the order they are added to the
        object tree, so in this case this.page is deleted after this.profile, which
        violates the assumption that this.profile should exist longer than
        this.page [1]. Here I delete this.page manually so that this.profile can be safely
        deleted later.

        [1] https://doc.qt.io/qt-5/qwebenginepage.html#QWebEnginePage-1
        ***********************************************************/
        delete this.page;
    }


    /***********************************************************
    ***********************************************************/
    public void url (GLib.Uri url) {
        this.page.url (url);
    }

} // class WebView

} // namespace Ui
} // namespace Occ
