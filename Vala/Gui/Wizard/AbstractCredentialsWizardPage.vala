/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <accountmanager.h>
//  #include <QWizardPage>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The AbstractCredentialsWizardPage class
@ingroup gui
***********************************************************/
class AbstractCredentialsWizardPage : QWizardPage {

    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        // Reset the credentials when the 'Back' button is used.

        unowned Account account = static_cast<OwncloudWizard> (wizard ()).account ();
        AbstractCredentials creds = account.credentials ();
        if (creds) {
            if (!creds.inherits ("DummyCredentials")) {
                account.credentials (CredentialsFactory.create ("dummy"));
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public virtual AbstractCredentials credentials ();

} // class AbstractCredentialsWizardPage

} // namespace Ui
} // namespace Occ
