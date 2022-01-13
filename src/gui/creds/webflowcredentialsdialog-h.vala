#ifndef WEBFLOWCREDENTIALSDIALOG_H
const int WEBFLOWCREDENTIALSDIALOG_H

// #include <QDialog>
// #include <QUrl>

class QVBoxLayout;

namespace Occ {

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE
class Flow2AuthWidget;

class WebFlowCredentialsDialog : QDialog {
public:
    WebFlowCredentialsDialog (Account *account, bool useFlow2, QWidget *parent = nullptr);

    void setUrl (QUrl &url);
    void setInfo (QString &msg);
    void setError (QString &error);

    bool isUsingFlow2 () {
        return _useFlow2;
    }

protected:
    void closeEvent (QCloseEvent * e) override;
    void changeEvent (QEvent *) override;

public slots:
    void slotFlow2AuthResult (Flow2Auth.Result, QString &errorString, QString &user, QString &appPassword);
    void slotShowSettingsDialog ();

signals:
    void urlCatched (QString user, QString pass, QString host);
    void styleChanged ();
    void onActivate ();
    void onClose ();

private:
    void customizeStyle ();

    bool _useFlow2;

    Flow2AuthWidget *_flow2AuthWidget;
#ifdef WITH_WEBENGINE
    WebView *_webView;
#endif // WITH_WEBENGINE

    QLabel *_errorLabel;
    QLabel *_infoLabel;
    QVBoxLayout *_layout;
    QVBoxLayout *_containerLayout;
    HeaderBanner *_headerBanner;
};

} // namespace Occ
