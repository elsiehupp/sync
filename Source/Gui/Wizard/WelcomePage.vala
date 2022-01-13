/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QWizardPage>

namespace Occ {


namespace Ui {
    class WelcomePage;
}

class WelcomePage : QWizardPage {

public:
    WelcomePage (OwncloudWizard *ocWizard);
    ~WelcomePage () override;
    int nextId () const override;
    void initializePage () override;
    void setLoginButtonDefault ();

private:
    void setupUi ();
    void customizeStyle ();
    void styleSlideShow ();
    void setupSlideShow ();
    void setupLoginButton ();
    void setupCreateAccountButton ();
    void setupHostYourOwnServerLabel ();

    QScopedPointer<Ui.WelcomePage> _ui;

    OwncloudWizard *_ocWizard;
    WizardCommon.Pages _nextPage = WizardCommon.Page_ServerSetup;
};
}








namespace Occ {

    WelcomePage.WelcomePage (OwncloudWizard *ocWizard)
        : QWizardPage ()
        , _ui (new Ui.WelcomePage)
        , _ocWizard (ocWizard) {
        setupUi ();
    }
    
    WelcomePage.~WelcomePage () = default;
    
    void WelcomePage.setupUi () {
        _ui.setupUi (this);
        setupSlideShow ();
        setupLoginButton ();
        setupCreateAccountButton ();
        setupHostYourOwnServerLabel ();
    }
    
    void WelcomePage.initializePage () {
        customizeStyle ();
    }
    
    void WelcomePage.setLoginButtonDefault () {
        _ui.loginButton.setDefault (true);
        _ui.loginButton.setFocus ();
    }
    
    void WelcomePage.styleSlideShow () {
        const auto theme = Theme.instance ();
        const auto backgroundColor = palette ().window ().color ();
    
        const auto wizardNextcloudIconFileName = theme.isBranded () ? Theme.hidpiFileName ("wizard-nextcloud.png", backgroundColor)
                                                                    : Theme.hidpiFileName (":/client/theme/colored/wizard-nextcloud.png");
        const auto wizardFilesIconFileName = theme.isBranded () ? Theme.hidpiFileName ("wizard-files.png", backgroundColor)
                                                                : Theme.hidpiFileName (":/client/theme/colored/wizard-files.png");
        const auto wizardGroupwareIconFileName = theme.isBranded () ? Theme.hidpiFileName ("wizard-groupware.png", backgroundColor)
                                                                    : Theme.hidpiFileName (":/client/theme/colored/wizard-groupware.png");
        const auto wizardTalkIconFileName = theme.isBranded () ? Theme.hidpiFileName ("wizard-talk.png", backgroundColor)
                                                               : Theme.hidpiFileName (":/client/theme/colored/wizard-talk.png");
    
        _ui.slideShow.addSlide (wizardNextcloudIconFileName, tr ("Keep your data secure and under your control"));
        _ui.slideShow.addSlide (wizardFilesIconFileName, tr ("Secure collaboration & file exchange"));
        _ui.slideShow.addSlide (wizardGroupwareIconFileName, tr ("Easy-to-use web mail, calendaring & contacts"));
        _ui.slideShow.addSlide (wizardTalkIconFileName, tr ("Screensharing, online meetings & web conferences"));
    
        const auto isDarkBackground = Theme.isDarkColor (backgroundColor);
        _ui.slideShowNextButton.setIcon (theme.uiThemeIcon (string ("control-next.svg"), isDarkBackground));
        _ui.slideShowPreviousButton.setIcon (theme.uiThemeIcon (string ("control-prev.svg"), isDarkBackground));
    }
    
    void WelcomePage.setupSlideShow () {
        connect (_ui.slideShow, &SlideShow.clicked, _ui.slideShow, &SlideShow.stopShow);
        connect (_ui.slideShowNextButton, &QPushButton.clicked, _ui.slideShow, &SlideShow.nextSlide);
        connect (_ui.slideShowPreviousButton, &QPushButton.clicked, _ui.slideShow, &SlideShow.prevSlide);
    }
    
    void WelcomePage.setupLoginButton () {
        const auto appName = Theme.instance ().appNameGUI ();
    
        _ui.loginButton.setText (tr ("Log in to your %1").arg (appName));
        connect (_ui.loginButton, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _nextPage = WizardCommon.Page_ServerSetup;
            _ocWizard.next ();
        });
    }
    
    void WelcomePage.setupCreateAccountButton () {
    #ifdef WITH_WEBENGINE
        connect (_ui.createAccountButton, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _ocWizard.setRegistration (true);
            _nextPage = WizardCommon.Page_WebView;
            _ocWizard.next ();
        });
    #else // WITH_WEBENGINE
        connect (_ui.createAccountButton, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _ocWizard.setRegistration (true);
            Utility.openBrowser (QStringLiteral ("https://nextcloud.com/register"));
        });
    #endif // WITH_WEBENGINE
    }
    
    void WelcomePage.setupHostYourOwnServerLabel () {
        _ui.hostYourOwnServerLabel.setText (tr ("Host your own server"));
        _ui.hostYourOwnServerLabel.setAlignment (Qt.AlignCenter);
        _ui.hostYourOwnServerLabel.setUrl (QUrl ("https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation"));
    }
    
    int WelcomePage.nextId () {
        return _nextPage;
    }
    
    void WelcomePage.customizeStyle () {
        styleSlideShow ();
    }
    }
    