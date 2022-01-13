/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>
Copyright (C) 2015 by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QDialog>
// #include <QSharedPointer>
// #include <QList>
// #include <QToolButton>
// #include <QHBoxLayout>
// #include <QLabel>
// #include <QLineEdit>
// #include <QWidgetAction>

class QTableWidgetItem;

namespace Occ {

namespace Ui {
    class ShareLinkWidget;
}

class SyncResult;
class Share;

/**
@brief The ShareDialog class
@ingroup gui
*/
class ShareLinkWidget : QWidget {

public:
    ShareLinkWidget (AccountPtr account,
        const QString &sharePath,
        const QString &localPath,
        SharePermissions maxSharingPermissions,
        QWidget *parent = nullptr);
    ~ShareLinkWidget () override;

    void toggleButton (bool show);
    void setupUiOptions ();

    void setLinkShare (QSharedPointer<LinkShare> linkShare);
    QSharedPointer<LinkShare> getLinkShare ();

    void focusPasswordLineEdit ();

public slots:
    void slotDeleteShareFetched ();
    void slotToggleShareLinkAnimation (bool start);
    void slotServerError (int code, QString &message);
    void slotCreateShareRequiresPassword (QString &message);
    void slotStyleChanged ();

private slots:
    void slotCreateShareLink (bool clicked);
    void slotCopyLinkShare (bool clicked) const;

    void slotCreatePassword ();
    void slotPasswordSet ();
    void slotPasswordSetError (int code, QString &message);

    void slotCreateNote ();
    void slotNoteSet ();

    void slotSetExpireDate ();
    void slotExpireDateSet ();

    void slotContextMenuButtonClicked ();
    void slotLinkContextMenuActionTriggered (QAction *action);

    void slotDeleteAnimationFinished ();
    void slotAnimationFinished ();

    void slotCreateLabel ();
    void slotLabelSet ();

signals:
    void createLinkShare ();
    void deleteLinkShare ();
    void resizeRequested ();
    void visualDeletionDone ();
    void createPassword (QString &password);
    void createPasswordProcessed ();

private:
    void displayError (QString &errMsg);

    void togglePasswordOptions (bool enable = true);
    void toggleNoteOptions (bool enable = true);
    void toggleExpireDateOptions (bool enable = true);
    void toggleButtonAnimation (QToolButton *button, QProgressIndicator *progressIndicator, QAction *checkedAction) const;

    /** Confirm with the user and then delete the share */
    void confirmAndDeleteShare ();

    /** Retrieve a share's name, accounting for _namesSupported */
    QString shareName ();

    void startAnimation (int start, int end);

    void customizeStyle ();

    void displayShareLinkLabel ();

    Ui.ShareLinkWidget *_ui;
    AccountPtr _account;
    QString _sharePath;
    QString _localPath;
    QString _shareUrl;

    QSharedPointer<LinkShare> _linkShare;

    bool _isFile;
    bool _passwordRequired;
    bool _expiryRequired;
    bool _namesSupported;
    bool _noteRequired;

    QMenu *_linkContextMenu;
    QAction *_readOnlyLinkAction;
    QAction *_allowEditingLinkAction;
    QAction *_allowUploadEditingLinkAction;
    QAction *_allowUploadLinkAction;
    QAction *_passwordProtectLinkAction;
    QAction *_expirationDateLinkAction;
    QAction *_unshareLinkAction;
    QAction *_addAnotherLinkAction;
    QAction *_noteLinkAction;
    QHBoxLayout *_shareLinkLayout{};
    QLabel *_shareLinkLabel{};
    ElidedLabel *_shareLinkElidedLabel{};
    QLineEdit *_shareLinkEdit{};
    QToolButton *_shareLinkButton{};
    QProgressIndicator *_shareLinkProgressIndicator{};
    QWidget *_shareLinkDefaultWidget{};
    QWidgetAction *_shareLinkWidgetAction{};
};
}
