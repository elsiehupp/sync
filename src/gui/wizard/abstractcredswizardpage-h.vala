/*
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QWizardPage>

namespace Occ {


/**
@brief The AbstractCredentialsWizardPage class
@ingroup gui
*/
class AbstractCredentialsWizardPage : QWizardPage {
public:
    void cleanupPage () override;
    virtual AbstractCredentials *getCredentials () const = 0;
};

} // namespace Occ

#endif
