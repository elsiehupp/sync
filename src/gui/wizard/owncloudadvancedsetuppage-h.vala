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


namespace Occ {


/**
@brief The OwncloudAdvancedSetupPage class
@ingroup gui
*/
class OwncloudAdvancedSetupPage : QWizardPage {
public:
    OwncloudAdvancedSetupPage (OwncloudWizard *wizard);

    bool isComplete () const override;
    void initializePage () override;
    int nextId () const override;
    bool validatePage () override;
    QString localFolder ();
    QStringList selectiveSyncBlacklist ();
    bool useVirtualFileSync ();
    bool isConfirmBigFolderChecked ();
    void setRemoteFolder (QString &remoteFolder);
    void setMultipleFoldersExist (bool exist);
    void directoriesCreated ();

signals:
    void createLocalAndRemoteFolders (QString &, QString &);

public slots:
    void setErrorString (QString &);
    void slotStyleChanged ();

private slots:
    void slotSelectFolder ();
    void slotSyncEverythingClicked ();
    void slotSelectiveSyncClicked ();
    void slotVirtualFileSyncClicked ();
    void slotQuotaRetrieved (QVariantMap &result);

private:
    void setRadioChecked (QRadioButton *radio);

    void setupCustomization ();
    void updateStatus ();
    bool dataChanged ();
    void startSpinner ();
    void stopSpinner ();
    QUrl serverUrl ();
    int64 availableLocalSpace ();
    QString checkLocalSpace (int64 remoteSize) const;
    void customizeStyle ();
    void setServerAddressLabelUrl (QUrl &url);
    void setLocalFolderPushButtonPath (QString &path);
    void styleSyncLogo ();
    void styleLocalFolderLabel ();
    void setResolutionGuiVisible (bool value);
    void setupResoultionWidget ();
    void fetchUserAvatar ();
    void setUserInformation ();

    // TODO : remove when UX decision is made
    void refreshVirtualFilesAvailibility (QString &path);

    Ui_OwncloudAdvancedSetupPage _ui;
    bool _checking = false;
    bool _created = false;
    bool _localFolderValid = false;
    QProgressIndicator *_progressIndi;
    QString _remoteFolder;
    QStringList _selectiveSyncBlacklist;
    int64 _rSize = -1;
    int64 _rSelectedSize = -1;
    OwncloudWizard *_ocWizard;
};

} // namespace Occ

#endif
