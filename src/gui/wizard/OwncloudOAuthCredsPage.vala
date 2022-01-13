/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QList>
// #include <QMap>
// #include <QNetworkCookie>
// #include <QUrl>
// #include <QPointer>

namespace Occ {

class OwncloudOAuthCredsPage : AbstractCredentialsWizardPage {
public:
    OwncloudOAuthCredsPage ();

    AbstractCredentials *getCredentials () const override;

    void initializePage () override;
    void cleanupPage () override;
    int nextId () const override;
    void setConnected ();
    bool isComplete () const override;

public slots:
    void asyncAuthResult (OAuth.Result, string &user, string &token,
        const string &reniewToken);

signals:
    void connectToOCUrl (string &);

public:
    string _user;
    string _token;
    string _refreshToken;
    QScopedPointer<OAuth> _asyncAuth;
    Ui_OwncloudOAuthCredsPage _ui;

protected slots:
    void slotOpenBrowser ();
    void slotCopyLinkToClipboard ();
};

} // namespace Occ










/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QVariant>
// #include <QMenu>
// #include <QClipboard>

namespace Occ {

    OwncloudOAuthCredsPage.OwncloudOAuthCredsPage ()
        : AbstractCredentialsWizardPage () {
        _ui.setupUi (this);
    
        Theme *theme = Theme.instance ();
        _ui.topLabel.hide ();
        _ui.bottomLabel.hide ();
        QVariant variant = theme.customMedia (Theme.oCSetupTop);
        WizardCommon.setupCustomMedia (variant, _ui.topLabel);
        variant = theme.customMedia (Theme.oCSetupBottom);
        WizardCommon.setupCustomMedia (variant, _ui.bottomLabel);
    
        WizardCommon.initErrorLabel (_ui.errorLabel);
    
        setTitle (WizardCommon.titleTemplate ().arg (tr ("Connect to %1").arg (Theme.instance ().appNameGUI ())));
        setSubTitle (WizardCommon.subTitleTemplate ().arg (tr ("Login in your browser")));
    
        connect (_ui.openLinkButton, &QCommandLinkButton.clicked, this, &OwncloudOAuthCredsPage.slotOpenBrowser);
        connect (_ui.copyLinkButton, &QCommandLinkButton.clicked, this, &OwncloudOAuthCredsPage.slotCopyLinkToClipboard);
    }
    
    void OwncloudOAuthCredsPage.initializePage () {
        auto *ocWizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (ocWizard);
        ocWizard.account ().setCredentials (CredentialsFactory.create ("http"));
        _asyncAuth.reset (new OAuth (ocWizard.account ().data (), this));
        connect (_asyncAuth.data (), &OAuth.result, this, &OwncloudOAuthCredsPage.asyncAuthResult, Qt.QueuedConnection);
        _asyncAuth.start ();
    
        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }
    
    void Occ.OwncloudOAuthCredsPage.cleanupPage () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        _asyncAuth.reset ();
    }
    
    void OwncloudOAuthCredsPage.asyncAuthResult (OAuth.Result r, string &user,
        const string &token, string &refreshToken) {
        switch (r) {
        case OAuth.NotSupported : {
            /* OAuth not supported (can't open browser), fallback to HTTP credentials */
            auto *ocWizard = qobject_cast<OwncloudWizard> (wizard ());
            ocWizard.back ();
            ocWizard.setAuthType (DetermineAuthTypeJob.Basic);
            break;
        }
        case OAuth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            _ui.errorLabel.show ();
            wizard ().show ();
            break;
        case OAuth.LoggedIn : {
            _token = token;
            _user = user;
            _refreshToken = refreshToken;
            auto *ocWizard = qobject_cast<OwncloudWizard> (wizard ());
            Q_ASSERT (ocWizard);
            emit connectToOCUrl (ocWizard.account ().url ().toString ());
            break;
        }
        }
    }
    
    int OwncloudOAuthCredsPage.nextId () {
        return WizardCommon.Page_AdvancedSetup;
    }
    
    void OwncloudOAuthCredsPage.setConnected () {
        wizard ().show ();
    }
    
    AbstractCredentials *OwncloudOAuthCredsPage.getCredentials () {
        auto *ocWizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (ocWizard);
        return new HttpCredentialsGui (_user, _token, _refreshToken,
            ocWizard._clientCertBundle, ocWizard._clientCertPassword);
    }
    
    bool OwncloudOAuthCredsPage.isComplete () {
        return false; /* We can never go forward manually */
    }
    
    void OwncloudOAuthCredsPage.slotOpenBrowser () {
        if (_ui.errorLabel)
            _ui.errorLabel.hide ();
    
        qobject_cast<OwncloudWizard> (wizard ()).account ().clearCookieJar (); // #6574
    
        if (_asyncAuth)
            _asyncAuth.openBrowser ();
    }
    
    void OwncloudOAuthCredsPage.slotCopyLinkToClipboard () {
        if (_asyncAuth)
            QApplication.clipboard ().setText (_asyncAuth.authorisationLink ().toString (QUrl.FullyEncoded));
    }
    
    } // namespace Occ
    