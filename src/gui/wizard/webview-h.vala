#ifndef WEBVIEW_H
const int WEBVIEW_H

// #include <QUrl>
// #include <QWidget>

class QWebEngineProfile;

namespace Occ {

class WebViewPageUrlSchemeHandler;

class WebView : QWidget {
public:
    WebView (QWidget *parent = nullptr);
    ~WebView () override;
    void setUrl (QUrl &url);

signals:
    void urlCatched (QString user, QString pass, QString host);

private:
    Ui_WebView _ui;

    QWebEngineView *_webview;
    QWebEngineProfile *_profile;
    WebEnginePage *_page;

    WebViewPageUrlRequestInterceptor *_interceptor;
    WebViewPageUrlSchemeHandler *_schemeHandler;
};

}
