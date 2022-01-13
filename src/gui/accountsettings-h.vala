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

// #include <QWidget>
// #include <QUrl>
// #include <QPointer>
// #include <QHash>
// #include <QTimer>

class QNetworkReply;
class QLabel;

namespace Occ {

namespace Ui {
    class AccountSettings;
}


class AccountState;

/**
@brief The AccountSettings class
@ingroup gui
*/
class AccountSettings : QWidget {
    Q_PROPERTY (AccountState* accountState MEMBER _accountState)

public:
    AccountSettings (AccountState *accountState, QWidget *parent = nullptr);
    ~AccountSettings () override;
    QSize sizeHint () const override { return ownCloudGui.settingsDialogSize (); }
    bool canEncryptOrDecrypt (FolderStatusModel.SubFolderInfo* folderInfo);

signals:
    void folderChanged ();
    void openFolderAlias (QString &);
    void showIssuesList (AccountState *account);
    void requestMnemonic ();
    void removeAccountFolders (AccountState *account);
    void styleChanged ();

public slots:
    void slotOpenOC ();
    void slotUpdateQuota (int64 total, int64 used);
    void slotAccountStateChanged ();
    void slotStyleChanged ();
    AccountState *accountsState () { return _accountState; }
    void slotHideSelectiveSyncWidget ();

protected slots:
    void slotAddFolder ();
    void slotEnableCurrentFolder (bool terminate = false);
    void slotScheduleCurrentFolder ();
    void slotScheduleCurrentFolderForceRemoteDiscovery ();
    void slotForceSyncCurrentFolder ();
    void slotRemoveCurrentFolder ();
    void slotOpenCurrentFolder (); // sync folder
    void slotOpenCurrentLocalSubFolder (); // selected subfolder in sync folder
    void slotEditCurrentIgnoredFiles ();
    void slotOpenMakeFolderDialog ();
    void slotEditCurrentLocalIgnoredFiles ();
    void slotEnableVfsCurrentFolder ();
    void slotDisableVfsCurrentFolder ();
    void slotSetCurrentFolderAvailability (PinState state);
    void slotSetSubFolderAvailability (Folder *folder, QString &path, PinState state);
    void slotFolderWizardAccepted ();
    void slotFolderWizardRejected ();
    void slotDeleteAccount ();
    void slotToggleSignInState ();
    void refreshSelectiveSyncStatus ();
    void slotMarkSubfolderEncrypted (FolderStatusModel.SubFolderInfo *folderInfo);
    void slotSubfolderContextMenuRequested (QModelIndex& idx, QPoint& point);
    void slotCustomContextMenuRequested (QPoint &);
    void slotFolderListClicked (QModelIndex &indx);
    void doExpand ();
    void slotLinkActivated (QString &link);

    // Encryption Related Stuff.
    void slotShowMnemonic (QString &mnemonic);
    void slotNewMnemonicGenerated ();
    void slotEncryptFolderFinished (int status);

    void slotSelectiveSyncChanged (QModelIndex &topLeft, QModelIndex &bottomRight,
                                  const QVector<int> &roles);

private:
    void showConnectionLabel (QString &message,
        QStringList errors = QStringList ());
    bool event (QEvent *) override;
    void createAccountToolbox ();
    void openIgnoredFilesDialog (QString & absFolderPath);
    void customizeStyle ();

    /// Returns the alias of the selected folder, empty string if none
    QString selectedFolderAlias ();

    Ui.AccountSettings *_ui;

    FolderStatusModel *_model;
    QUrl _OCUrl;
    bool _wasDisabledBefore;
    AccountState *_accountState;
    UserInfo _userInfo;
    QAction *_toggleSignInOutAction;
    QAction *_addAccountAction;

    bool _menuShown;
};

} // namespace Occ
