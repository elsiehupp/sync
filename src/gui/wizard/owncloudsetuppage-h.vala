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

// #include <QWizard>

#include "../addcertificatedialog.h"

class QVariant;

namespace Occ {

/**
@brief The OwncloudSetupPage class
@ingroup gui
*/
class OwncloudSetupPage : QWizardPage {
public:
    OwncloudSetupPage (QWidget *parent = nullptr);
    ~OwncloudSetupPage () override;

    bool isComplete () const override;
    void initializePage () override;
    int nextId () const override;
    void setServerUrl (QString &);
    void setAllowPasswordStorage (bool);
    bool validatePage () override;
    QString url ();
    QString localFolder ();
    void setRemoteFolder (QString &remoteFolder);
    void setMultipleFoldersExist (bool exist);
    void setAuthType (DetermineAuthTypeJob.AuthType type);

public slots:
    void setErrorString (QString &, bool retryHTTPonly);
    void startSpinner ();
    void stopSpinner ();
    void slotCertificateAccepted ();
    void slotStyleChanged ();

protected slots:
    void slotUrlChanged (QString &);
    void slotUrlEditFinished ();

    void setupCustomization ();

signals:
    void determineAuthType (QString &);

private:
    void setLogo ();
    void customizeStyle ();
    void setupServerAddressDescriptionLabel ();

    Ui_OwncloudSetupPage _ui;

    QString _oCUrl;
    QString _ocUser;
    bool _authTypeKnown = false;
    bool _checking = false;
    DetermineAuthTypeJob.AuthType _authType = DetermineAuthTypeJob.Basic;

    QProgressIndicator *_progressIndi;
    OwncloudWizard *_ocWizard;
    AddCertificateDialog *addCertDial = nullptr;
};

} // namespace Occ

#endif
