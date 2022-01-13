/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QWizardPage>

namespace Occ {


/***********************************************************
@brief The AbstractCredentialsWizardPage class
@ingroup gui
***********************************************************/
class AbstractCredentialsWizardPage : QWizardPage {
public:
    void cleanupPage () override;
    virtual AbstractCredentials *getCredentials () const = 0;
};

} // namespace Occ

#endif









/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <accountmanager.h>

namespace Occ {

    void AbstractCredentialsWizardPage.cleanupPage () {
        // Reset the credentials when the 'Back' button is used.
    
        AccountPtr account = static_cast<OwncloudWizard> (wizard ()).account ();
        AbstractCredentials *creds = account.credentials ();
        if (creds) {
            if (!creds.inherits ("DummyCredentials")) {
                account.setCredentials (CredentialsFactory.create ("dummy"));
            }
        }
    }
    }
    