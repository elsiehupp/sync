#ifndef WEBVIEWPAGE_H
const int WEBVIEWPAGE_H

namespace Occ {


class WebViewPage : AbstractCredentialsWizardPage {
public:
    WebViewPage (Gtk.Widget *parent = nullptr);
    ~WebViewPage () override;

    void initializePage () override;
    void cleanupPage () override;
    int nextId () const override;
    bool isComplete () const override;

    AbstractCredentials* getCredentials () const override;
    void setConnected ();

signals:
    void connectToOCUrl (string&);

private slots:
    void urlCatched (string user, string pass, string host);

private:
    void resizeWizard ();
    bool tryToSetWizardSize (int width, int height);

    OwncloudWizard *_ocWizard;
    WebView *_webView;

    string _user;
    string _pass;

    bool _useSystemProxy;

    QSize _originalWizardSize;
};

}











// #include <QWebEngineUrlRequestJob>
// #include <QProgressBar>
// #include <QVBoxLayout>
// #include <QNetworkProxyFactory>
// #include <QScreen>

namespace Occ {

    Q_LOGGING_CATEGORY (lcWizardWebiewPage, "nextcloud.gui.wizard.webviewpage", QtInfoMsg)
    
    WebViewPage.WebViewPage (Gtk.Widget *parent)
        : AbstractCredentialsWizardPage () {
        _ocWizard = qobject_cast<OwncloudWizard> (parent);
    
        qCInfo (lcWizardWebiewPage ()) << "Time for a webview!";
        _webView = new WebView (this);
    
        auto *layout = new QVBoxLayout (this);
        layout.setMargin (0);
        layout.addWidget (_webView);
        setLayout (layout);
    
        connect (_webView, &WebView.urlCatched, this, &WebViewPage.urlCatched);
    
        //_useSystemProxy = QNetworkProxyFactory.usesSystemConfiguration ();
    }
    
    WebViewPage.~WebViewPage () = default;
    //{
    //    QNetworkProxyFactory.setUseSystemConfiguration (_useSystemProxy);
    //}
    
    void WebViewPage.initializePage () {
        //QNetworkProxy.setApplicationProxy (QNetworkProxy.applicationProxy ());
    
        string url;
        if (_ocWizard.registration ()) {
            url = "https://nextcloud.com/register";
        } else {
            url = _ocWizard.ocUrl ();
            if (!url.endsWith ('/')) {
                url += "/";
            }
            url += "index.php/login/flow";
        }
        qCInfo (lcWizardWebiewPage ()) << "Url to auth at : " << url;
        _webView.setUrl (QUrl (url));
    
        _originalWizardSize = _ocWizard.size ();
        resizeWizard ();
    }
    
    void WebViewPage.resizeWizard () {
        // The webview needs a little bit more space
        auto wizardSizeChanged = tryToSetWizardSize (_originalWizardSize.width () * 2, _originalWizardSize.height () * 2);
    
        if (!wizardSizeChanged) {
            wizardSizeChanged = tryToSetWizardSize (static_cast<int> (_originalWizardSize.width () * 1.5), static_cast<int> (_originalWizardSize.height () * 1.5));
        }
    
        if (wizardSizeChanged) {
            _ocWizard.centerWindow ();
        }
    }
    
    bool WebViewPage.tryToSetWizardSize (int width, int height) {
        const auto window = _ocWizard.window ();
        const auto screenGeometry = QGuiApplication.screenAt (window.pos ()).geometry ();
        const auto windowWidth = screenGeometry.width ();
        const auto windowHeight = screenGeometry.height ();
    
        if (width < windowWidth && height < windowHeight) {
            _ocWizard.resize (width, height);
            return true;
        }
    
        return false;
    }
    
    void WebViewPage.cleanupPage () {
        _ocWizard.resize (_originalWizardSize);
        _ocWizard.centerWindow ();
    }
    
    int WebViewPage.nextId () {
        return WizardCommon.Page_AdvancedSetup;
    }
    
    bool WebViewPage.isComplete () {
        return false;
    }
    
    AbstractCredentials* WebViewPage.getCredentials () {
        return new WebFlowCredentials (_user, _pass, _ocWizard._clientSslCertificate, _ocWizard._clientSslKey);
    }
    
    void WebViewPage.setConnected () {
        qCInfo (lcWizardWebiewPage ()) << "YAY! we are connected!";
    }
    
    void WebViewPage.urlCatched (string user, string pass, string host) {
        qCInfo (lcWizardWebiewPage ()) << "Got user : " << user << ", server : " << host;
    
        _user = user;
        _pass = pass;
    
        AccountPtr account = _ocWizard.account ();
        account.setUrl (host);
    
        qCInfo (lcWizardWebiewPage ()) << "URL : " << field ("OCUrl").toString ();
        emit connectToOCUrl (host);
    }
    
    }
    