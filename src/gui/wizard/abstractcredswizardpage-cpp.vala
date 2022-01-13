/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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
