/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <accountmanager.h>
//  #include <QWizard_page>

namespace Occ {


/***********************************************************
@brief The Abstract_credentials_wizard_page class
@ingroup gui
***********************************************************/
class Abstract_credentials_wizard_page : QWizard_page {

    /***********************************************************
    ***********************************************************/
    public void cleanup_page () override;
    public virtual AbstractCredentials get_credentials ();
}

    void Abstract_credentials_wizard_page.cleanup_page () {
        // Reset the credentials when the 'Back' button is used.

        AccountPointer account = static_cast<OwncloudWizard> (wizard ()).account ();
        AbstractCredentials creds = account.credentials ();
        if (creds) {
            if (!creds.inherits ("DummyCredentials")) {
                account.set_credentials (CredentialsFactory.create ("dummy"));
            }
        }
    }
}
    