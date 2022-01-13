

// #include <QUrl>
// #include <Gtk.Widget>
// #include <QWebEnginePage>
// #include <QWebEngineProfile>
// #include <QWebEngineUrlRequestInterceptor>
// #include <QWebEngineUrlRequestJob>
#if QT_VERSION >= 0x051200
// #include <QWebEngineUrlScheme>
#endif
// #include <QWebEngineUrlSchemeHandler>
// #include <QWebEngineView>
// #include <QDesktopServices>
// #include <QProgressBar>
// #include <QLoggingCategory>
// #include <QLocale>
// #include <QWebEngineCertificateError>
// #include <QMessageBox>


namespace Occ {


class WebView : Gtk.Widget {
public:
    WebView (Gtk.Widget *parent = nullptr);
    ~WebView () override;
    void setUrl (QUrl &url);

signals:
    void urlCatched (string user, string pass, string host);

private:
    Ui_WebView _ui;

    QWebEngineView *_webview;
    QWebEngineProfile *_profile;
    WebEnginePage *_page;

    WebViewPageUrlRequestInterceptor *_interceptor;
    WebViewPageUrlSchemeHandler *_schemeHandler;
};


class WebViewPageUrlRequestInterceptor : QWebEngineUrlRequestInterceptor {
public:
    WebViewPageUrlRequestInterceptor (GLib.Object *parent = nullptr);
    void interceptRequest (QWebEngineUrlRequestInfo &info) override;
};

class WebViewPageUrlSchemeHandler : QWebEngineUrlSchemeHandler {
public:
    WebViewPageUrlSchemeHandler (GLib.Object *parent = nullptr);
    void requestStarted (QWebEngineUrlRequestJob *request) override;

signals:
    void urlCatched (string user, string pass, string host);
};

class WebEnginePage : QWebEnginePage {
public:
    WebEnginePage (QWebEngineProfile *profile, GLib.Object* parent = nullptr);
    QWebEnginePage * createWindow (QWebEnginePage.WebWindowType type) override;
    void setUrl (QUrl &url);

protected:
    bool certificateError (QWebEngineCertificateError &certificateError) override;

    bool acceptNavigationRequest (QUrl &url, QWebEnginePage.NavigationType type, bool isMainFrame) override;

private:
    bool _enforceHttps = false;
};

// We need a separate class here, since we cannot simply return the same WebEnginePage object
// this leads to a strage segfault somewhere deep inside of the QWebEngine code
class ExternalWebEnginePage : QWebEnginePage {
public:
    ExternalWebEnginePage (QWebEngineProfile *profile, GLib.Object* parent = nullptr);
    bool acceptNavigationRequest (QUrl &url, QWebEnginePage.NavigationType type, bool isMainFrame) override;
};

WebView.WebView (Gtk.Widget *parent)
    : Gtk.Widget (parent),
      _ui () {
    _ui.setupUi (this);
#if QT_VERSION >= 0x051200
    QWebEngineUrlScheme _ncsheme ("nc");
    QWebEngineUrlScheme.registerScheme (_ncsheme);
#endif
    _webview = new QWebEngineView (this);
    _profile = new QWebEngineProfile (this);
    _page = new WebEnginePage (_profile);
    _interceptor = new WebViewPageUrlRequestInterceptor (this);
    _schemeHandler = new WebViewPageUrlSchemeHandler (this);

    const string userAgent (Utility.userAgentString ());
    _profile.setHttpUserAgent (userAgent);
    QWebEngineProfile.defaultProfile ().setHttpUserAgent (userAgent);
    _profile.setRequestInterceptor (_interceptor);
    _profile.installUrlSchemeHandler ("nc", _schemeHandler);

    /***********************************************************
    Set a proper accept langauge to the language of the client
    code from : http://code.qt.io/cgit/qt/qtbase.git/tree/src/network/access/qhttpnetworkconnection.cpp
    ***********************************************************/ {
        string systemLocale = QLocale.system ().name ().replace (QChar.fromLatin1 ('_'),QChar.fromLatin1 ('-'));
        string acceptLanguage;
        if (systemLocale == QLatin1String ("C")) {
            acceptLanguage = string.fromLatin1 ("en,*");
        } else if (systemLocale.startsWith (QLatin1String ("en-"))) {
            acceptLanguage = systemLocale + QLatin1String (",*");
        } else {
            acceptLanguage = systemLocale + QLatin1String (",en,*");
        }
        _profile.setHttpAcceptLanguage (acceptLanguage);
    }

    _webview.setPage (_page);
    _ui.verticalLayout.addWidget (_webview);

    connect (_webview, &QWebEngineView.loadProgress, _ui.progressBar, &QProgressBar.setValue);
    connect (_schemeHandler, &WebViewPageUrlSchemeHandler.urlCatched, this, &WebView.urlCatched);
}

void WebView.setUrl (QUrl &url) {
    _page.setUrl (url);
}

WebView.~WebView () {
    /***********************************************************
    The Qt implmentation deletes children in the order they are added to the
    object tree, so in this case _page is deleted after _profile, which
    violates the assumption that _profile should exist longer than
    _page [1]. Here I delete _page manually so that _profile can be safely
    deleted later.
    
     * [1] https://doc.qt.io/qt-5/qwebenginepage.html#QWebEnginePage-1
    ***********************************************************/
    delete _page;
}

WebViewPageUrlRequestInterceptor.WebViewPageUrlRequestInterceptor (GLib.Object *parent)
    : QWebEngineUrlRequestInterceptor (parent) {

}

void WebViewPageUrlRequestInterceptor.interceptRequest (QWebEngineUrlRequestInfo &info) {
    info.setHttpHeader ("OCS-APIREQUEST", "true");
}

WebViewPageUrlSchemeHandler.WebViewPageUrlSchemeHandler (GLib.Object *parent)
    : QWebEngineUrlSchemeHandler (parent) {

}

void WebViewPageUrlSchemeHandler.requestStarted (QWebEngineUrlRequestJob *request) {
    QUrl url = request.requestUrl ();

    string path = url.path ().mid (1); // get undecoded path
    const QStringList parts = path.split ("&");

    string server;
    string user;
    string password;

    for (string part : parts) {
        if (part.startsWith ("server:")) {
            server = part.mid (7);
        } else if (part.startsWith ("user:")) {
            user = part.mid (5);
        } else if (part.startsWith ("password:")) {
            password = part.mid (9);
        }
    }

    qCDebug (lcWizardWebiew ()) << "Got raw user from request path : " << user;

    user = user.replace (QChar ('+'), QChar (' '));
    password = password.replace (QChar ('+'), QChar (' '));

    user = QUrl.fromPercentEncoding (user.toUtf8 ());
    password = QUrl.fromPercentEncoding (password.toUtf8 ());

    if (!server.startsWith ("http://") && !server.startsWith ("https://")) {
        server = "https://" + server;
    }
    qCInfo (lcWizardWebiew ()) << "Got user : " << user << ", server : " << server;

    emit urlCatched (user, password, server);
}

WebEnginePage.WebEnginePage (QWebEngineProfile *profile, GLib.Object* parent) : QWebEnginePage (profile, parent) {

}

QWebEnginePage * WebEnginePage.createWindow (QWebEnginePage.WebWindowType type) {
    Q_UNUSED (type);
    auto *view = new ExternalWebEnginePage (this.profile ());
    return view;
}

void WebEnginePage.setUrl (QUrl &url) {
    QWebEnginePage.setUrl (url);
    _enforceHttps = url.scheme () == QStringLiteral ("https");
}

bool WebEnginePage.certificateError (QWebEngineCertificateError &certificateError) {
    /***********************************************************
    TODO properly improve this.
    The certificate should be displayed.
    
    Or rather we should do a request with the QNAM and see if it works (then it is in the store).
     * This is just a quick fix for now.
    ***********************************************************/
    QMessageBox messageBox;
    messageBox.setText (tr ("Invalid certificate detected"));
    messageBox.setInformativeText (tr ("The host \"%1\" provided an invalid certificate. Continue?").arg (certificateError.url ().host ()));
    messageBox.setIcon (QMessageBox.Warning);
    messageBox.setStandardButtons (QMessageBox.Yes|QMessageBox.No);
    messageBox.setDefaultButton (QMessageBox.No);

    int ret = messageBox.exec ();

    return ret == QMessageBox.Yes;
}

bool WebEnginePage.acceptNavigationRequest (QUrl &url, QWebEnginePage.NavigationType type, bool isMainFrame) {
    Q_UNUSED (type);
    Q_UNUSED (isMainFrame);

    if (_enforceHttps && url.scheme () != QStringLiteral ("https") && url.scheme () != QStringLiteral ("nc")) {
        QMessageBox.warning (nullptr, "Security warning", "Can not follow non https link on a https website. This might be a security issue. Please contact your administrator");
        return false;
    }
    return true;
}

ExternalWebEnginePage.ExternalWebEnginePage (QWebEngineProfile *profile, GLib.Object* parent) : QWebEnginePage (profile, parent) {

}

bool ExternalWebEnginePage.acceptNavigationRequest (QUrl &url, QWebEnginePage.NavigationType type, bool isMainFrame) {
    Q_UNUSED (type);
    Q_UNUSED (isMainFrame);
    Utility.openBrowser (url);
    return false;
}

}

#include "webview.moc"
