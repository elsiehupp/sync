#ifndef WEBVIEW_H
#define WEBVIEW_H

// #include <QUrl>
// #include <QWidget>

class QWebEngineView;
class QWebEngineProfile;
class QWebEnginePage;

namespace OCC {

class WebViewPageUrlRequestInterceptor;
class WebViewPageUrlSchemeHandler;
class WebEnginePage;

class WebView : public QWidget {
public:
    WebView(QWidget *parent = nullptr);
    ~WebView() override;
    void setUrl(QUrl &url);

signals:
    void urlCatched(QString user, QString pass, QString host);

private:
    Ui_WebView _ui;

    QWebEngineView *_webview;
    QWebEngineProfile *_profile;
    WebEnginePage *_page;

    WebViewPageUrlRequestInterceptor *_interceptor;
    WebViewPageUrlSchemeHandler *_schemeHandler;
};

}

#endif // WEBVIEW_H
