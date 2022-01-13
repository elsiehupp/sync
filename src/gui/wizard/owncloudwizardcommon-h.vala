/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
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

// #include <QString>

class QLabel;
class QSpinBox;
class QAbstractButton;

namespace Occ {

namespace WizardCommon {

    void setupCustomMedia (QVariant &variant, QLabel *label);
    QString titleTemplate ();
    QString subTitleTemplate ();
    void initErrorLabel (QLabel *errorLabel);
    void customizeHintLabel (QLabel *label);

    enum SyncMode {
        SelectiveMode,
        BoxMode
    };

    enum Pages {
        Page_Welcome,
        Page_ServerSetup,
        Page_HttpCreds,
        Page_OAuthCreds,
        Page_Flow2AuthCreds,
#ifdef WITH_WEBENGINE
        Page_WebView,
#endif // WITH_WEBENGINE
        Page_AdvancedSetup,
    };

} // ns WizardCommon

} // namespace Occ
