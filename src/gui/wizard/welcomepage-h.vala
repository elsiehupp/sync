/*
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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
