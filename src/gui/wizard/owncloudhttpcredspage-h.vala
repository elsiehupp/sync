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


namespace Occ {

/**
@brief The OwncloudHttpCredsPage class
*/
class OwncloudHttpCredsPage : AbstractCredentialsWizardPage {
public:
    OwncloudHttpCredsPage (QWidget *parent);

    AbstractCredentials *getCredentials () const override;

    void initializePage () override;
    void cleanupPage () override;
    bool validatePage () override;
    int nextId () const override;
    void setConnected ();
    void setErrorString (QString &err);

signals:
    void connectToOCUrl (QString &);

public slots:
    void slotStyleChanged ();

private:
    void startSpinner ();
    void stopSpinner ();
    void setupCustomization ();
    void customizeStyle ();

    Ui_OwncloudHttpCredsPage _ui;
    bool _connected;
    QProgressIndicator *_progressIndi;
    OwncloudWizard *_ocWizard;
};

} // namespace Occ

#endif
