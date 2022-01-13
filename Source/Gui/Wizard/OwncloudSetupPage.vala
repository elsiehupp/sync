/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QFileDialog>
// #include <QUrl>
// #include <QTimer>
// #include <QPushButton>
// #include <QMessageBox>
// #include <QSsl>
// #include <QSslCertificate>
// #include <QNetworkAccessManager>
// #include <QPropertyAnimation>
// #include <QGraphicsPixmapItem>
// #include <QBuffer>

// #include <QWizard>

#include "../addcertificatedialog.h"


namespace Occ {

/***********************************************************
@brief The OwncloudSetupPage class
@ingroup gui
***********************************************************/
class OwncloudSetupPage : QWizardPage {
public:
    OwncloudSetupPage (Gtk.Widget *parent = nullptr);
    ~OwncloudSetupPage () override;

    bool isComplete () const override;
    void initializePage () override;
    int nextId () const override;
    void setServerUrl (string &);
    void setAllowPasswordStorage (bool);
    bool validatePage () override;
    string url ();
    string localFolder ();
    void setRemoteFolder (string &remoteFolder);
    void setMultipleFoldersExist (bool exist);
    void setAuthType (DetermineAuthTypeJob.AuthType type);

public slots:
    void setErrorString (string &, bool retryHTTPonly);
    void startSpinner ();
    void stopSpinner ();
    void slotCertificateAccepted ();
    void slotStyleChanged ();

protected slots:
    void slotUrlChanged (string &);
    void slotUrlEditFinished ();

    void setupCustomization ();

signals:
    void determineAuthType (string &);

private:
    void setLogo ();
    void customizeStyle ();
    void setupServerAddressDescriptionLabel ();

    Ui_OwncloudSetupPage _ui;

    string _oCUrl;
    string _ocUser;
    bool _authTypeKnown = false;
    bool _checking = false;
    DetermineAuthTypeJob.AuthType _authType = DetermineAuthTypeJob.Basic;

    QProgressIndicator *_progressIndi;
    OwncloudWizard *_ocWizard;
    AddCertificateDialog *addCertDial = nullptr;
};

} // namespace Occ









namespace Occ {

    OwncloudSetupPage.OwncloudSetupPage (Gtk.Widget *parent)
        : QWizardPage ()
        , _progressIndi (new QProgressIndicator (this))
        , _ocWizard (qobject_cast<OwncloudWizard> (parent)) {
        _ui.setupUi (this);
    
        setupServerAddressDescriptionLabel ();
    
        Theme *theme = Theme.instance ();
        if (theme.overrideServerUrl ().isEmpty ()) {
            _ui.leUrl.setPostfix (theme.wizardUrlPostfix ());
            _ui.leUrl.setPlaceholderText (theme.wizardUrlHint ());
        } else if (Theme.instance ().forceOverrideServerUrl ()) {
            _ui.leUrl.setEnabled (false);
        }
    
        registerField (QLatin1String ("OCUrl*"), _ui.leUrl);
    
        auto sizePolicy = _progressIndi.sizePolicy ();
        sizePolicy.setRetainSizeWhenHidden (true);
        _progressIndi.setSizePolicy (sizePolicy);
    
        _ui.progressLayout.addWidget (_progressIndi);
        stopSpinner ();
    
        setupCustomization ();
    
        slotUrlChanged (QLatin1String ("")); // don't jitter UI
        connect (_ui.leUrl, &QLineEdit.textChanged, this, &OwncloudSetupPage.slotUrlChanged);
        connect (_ui.leUrl, &QLineEdit.editingFinished, this, &OwncloudSetupPage.slotUrlEditFinished);
    
        addCertDial = new AddCertificateDialog (this);
        connect (addCertDial, &Gtk.Dialog.accepted, this, &OwncloudSetupPage.slotCertificateAccepted);
    }
    
    void OwncloudSetupPage.setLogo () {
        _ui.logoLabel.setPixmap (Theme.instance ().wizardApplicationLogo ());
    }
    
    void OwncloudSetupPage.setupServerAddressDescriptionLabel () {
        const auto appName = Theme.instance ().appNameGUI ();
        _ui.serverAddressDescriptionLabel.setText (tr ("The link to your %1 web interface when you open it in the browser.", "%1 will be replaced with the application name").arg (appName));
    }
    
    void OwncloudSetupPage.setServerUrl (string &newUrl) {
        _ocWizard.setRegistration (false);
        _oCUrl = newUrl;
        if (_oCUrl.isEmpty ()) {
            _ui.leUrl.clear ();
            return;
        }
    
        _ui.leUrl.setText (_oCUrl);
    }
    
    void OwncloudSetupPage.setupCustomization () {
        // set defaults for the customize labels.
        _ui.topLabel.hide ();
        _ui.bottomLabel.hide ();
    
        Theme *theme = Theme.instance ();
        QVariant variant = theme.customMedia (Theme.oCSetupTop);
        if (!variant.isNull ()) {
            WizardCommon.setupCustomMedia (variant, _ui.topLabel);
        }
    
        variant = theme.customMedia (Theme.oCSetupBottom);
        WizardCommon.setupCustomMedia (variant, _ui.bottomLabel);
    
        auto leUrlPalette = _ui.leUrl.palette ();
        leUrlPalette.setColor (QPalette.Text, Qt.black);
        leUrlPalette.setColor (QPalette.Base, Qt.white);
        _ui.leUrl.setPalette (leUrlPalette);
    }
    
    // slot hit from textChanged of the url entry field.
    void OwncloudSetupPage.slotUrlChanged (string &url) {
        // Need to set next button as default button here because
        // otherwise the on OSX the next button does not stay the default
        // button
        auto nextButton = qobject_cast<QPushButton> (_ocWizard.button (QWizard.NextButton));
        if (nextButton) {
            nextButton.setDefault (true);
        }
    
        _authTypeKnown = false;
    
        string newUrl = url;
        if (url.endsWith ("index.php")) {
            newUrl.chop (9);
        }
        if (_ocWizard && _ocWizard.account ()) {
            string webDavPath = _ocWizard.account ().davPath ();
            if (url.endsWith (webDavPath)) {
                newUrl.chop (webDavPath.length ());
            }
            if (webDavPath.endsWith (QLatin1Char ('/'))) {
                webDavPath.chop (1); // cut off the slash
                if (url.endsWith (webDavPath)) {
                    newUrl.chop (webDavPath.length ());
                }
            }
        }
        if (newUrl != url) {
            _ui.leUrl.setText (newUrl);
        }
    }
    
    void OwncloudSetupPage.slotUrlEditFinished () {
        string url = _ui.leUrl.fullText ();
        if (QUrl (url).isRelative () && !url.isEmpty ()) {
            // no scheme defined, set one
            url.prepend ("https://");
            _ui.leUrl.setFullText (url);
        }
    }
    
    bool OwncloudSetupPage.isComplete () {
        return !_ui.leUrl.text ().isEmpty () && !_checking;
    }
    
    void OwncloudSetupPage.initializePage () {
        customizeStyle ();
    
        WizardCommon.initErrorLabel (_ui.errorLabel);
    
        _authTypeKnown = false;
        _checking = false;
    
        QAbstractButton *nextButton = wizard ().button (QWizard.NextButton);
        auto *pushButton = qobject_cast<QPushButton> (nextButton);
        if (pushButton) {
            pushButton.setDefault (true);
        }
    
        _ui.leUrl.setFocus ();
    
        const auto isServerUrlOverridden = !Theme.instance ().overrideServerUrl ().isEmpty ();
        if (isServerUrlOverridden && !Theme.instance ().forceOverrideServerUrl ()) {
            // If the url is overwritten but we don't force to use that url
            // Just focus the next button to let the user navigate quicker
            if (nextButton) {
                nextButton.setFocus ();
            }
        } else if (isServerUrlOverridden) {
            // If the overwritten url is not empty and we force this overwritten url
            // we just check the server type and switch to next page
            // immediately.
            setCommitPage (true);
            // Hack : setCommitPage () changes caption, but after an error this page could still be visible
            setButtonText (QWizard.CommitButton, tr ("&Next >"));
            validatePage ();
            setVisible (false);
        }
    }
    
    int OwncloudSetupPage.nextId () {
        switch (_authType) {
        case DetermineAuthTypeJob.Basic:
            return WizardCommon.Page_HttpCreds;
        case DetermineAuthTypeJob.OAuth:
            return WizardCommon.Page_OAuthCreds;
        case DetermineAuthTypeJob.LoginFlowV2:
            return WizardCommon.Page_Flow2AuthCreds;
    #ifdef WITH_WEBENGINE
        case DetermineAuthTypeJob.WebViewFlow:
            return WizardCommon.Page_WebView;
    #endif // WITH_WEBENGINE
        case DetermineAuthTypeJob.NoAuthType:
            return WizardCommon.Page_HttpCreds;
        }
        Q_UNREACHABLE ();
    }
    
    string OwncloudSetupPage.url () {
        string url = _ui.leUrl.fullText ().simplified ();
        return url;
    }
    
    bool OwncloudSetupPage.validatePage () {
        if (!_authTypeKnown) {
            slotUrlEditFinished ();
            string u = url ();
            QUrl qurl (u);
            if (!qurl.isValid () || qurl.host ().isEmpty ()) {
                setErrorString (tr ("Server address does not seem to be valid"), false);
                return false;
            }
    
            setErrorString (string (), false);
            _checking = true;
            startSpinner ();
            emit completeChanged ();
    
            emit determineAuthType (u);
            return false;
        } else {
            // connecting is running
            stopSpinner ();
            _checking = false;
            emit completeChanged ();
            return true;
        }
    }
    
    void OwncloudSetupPage.setAuthType (DetermineAuthTypeJob.AuthType type) {
        _authTypeKnown = true;
        _authType = type;
        stopSpinner ();
    }
    
    void OwncloudSetupPage.setErrorString (string &err, bool retryHTTPonly) {
        if (err.isEmpty ()) {
            _ui.errorLabel.setVisible (false);
        } else {
            if (retryHTTPonly) {
                QUrl url (_ui.leUrl.fullText ());
                if (url.scheme () == "https") {
                    // Ask the user how to proceed when connecting to a https:// URL fails.
                    // It is possible that the server is secured with client-side TLS certificates,
                    // but that it has no way of informing the owncloud client that this is the case.
    
                    OwncloudConnectionMethodDialog dialog;
                    dialog.setUrl (url);
                    // FIXME : Synchronous dialogs are not so nice because of event loop recursion
                    int retVal = dialog.exec ();
    
                    switch (retVal) {
                    case OwncloudConnectionMethodDialog.No_TLS : {
                        url.setScheme ("http");
                        _ui.leUrl.setFullText (url.toString ());
                        // skip ahead to next page, since the user would expect us to retry automatically
                        wizard ().next ();
                    } break;
                    case OwncloudConnectionMethodDialog.Client_Side_TLS:
                        addCertDial.show ();
                        break;
                    case OwncloudConnectionMethodDialog.Closed:
                    case OwncloudConnectionMethodDialog.Back:
                    default:
                        // No-op.
                        break;
                    }
                }
            }
    
            _ui.errorLabel.setVisible (true);
            _ui.errorLabel.setText (err);
        }
        _checking = false;
        emit completeChanged ();
        stopSpinner ();
    }
    
    void OwncloudSetupPage.startSpinner () {
        _ui.progressLayout.setEnabled (true);
        _progressIndi.setVisible (true);
        _progressIndi.startAnimation ();
    }
    
    void OwncloudSetupPage.stopSpinner () {
        _ui.progressLayout.setEnabled (false);
        _progressIndi.setVisible (false);
        _progressIndi.stopAnimation ();
    }
    
    string subjectInfoHelper (QSslCertificate &cert, QByteArray &qa) {
        return cert.subjectInfo (qa).join (QLatin1Char ('/'));
    }
    
    //called during the validation of the client certificate.
    void OwncloudSetupPage.slotCertificateAccepted () {
        QFile certFile (addCertDial.getCertificatePath ());
        certFile.open (QFile.ReadOnly);
        QByteArray certData = certFile.readAll ();
        QByteArray certPassword = addCertDial.getCertificatePasswd ().toLocal8Bit ();
    
        QBuffer certDataBuffer (&certData);
        certDataBuffer.open (QIODevice.ReadOnly);
        if (QSslCertificate.importPkcs12 (&certDataBuffer,
                &_ocWizard._clientSslKey, &_ocWizard._clientSslCertificate,
                &_ocWizard._clientSslCaCertificates, certPassword)) {
            _ocWizard._clientCertBundle = certData;
            _ocWizard._clientCertPassword = certPassword;
    
            addCertDial.reinit (); // FIXME : Why not just have this only created on use?
    
            // The extracted SSL key and cert gets added to the QSslConfiguration in checkServer ()
            validatePage ();
        } else {
            addCertDial.showErrorMessage (tr ("Could not load certificate. Maybe wrong password?"));
            addCertDial.show ();
        }
    }
    
    OwncloudSetupPage.~OwncloudSetupPage () = default;
    
    void OwncloudSetupPage.slotStyleChanged () {
        customizeStyle ();
    }
    
    void OwncloudSetupPage.customizeStyle () {
        setLogo ();
    
        if (_progressIndi) {
            const auto isDarkBackground = Theme.isDarkColor (palette ().window ().color ());
            if (isDarkBackground) {
                _progressIndi.setColor (Qt.white);
            } else {
                _progressIndi.setColor (Qt.black);
            }
        }
    
        WizardCommon.customizeHintLabel (_ui.serverAddressDescriptionLabel);
    }
    
    } // namespace Occ
    