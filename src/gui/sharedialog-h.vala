/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QSharedPointer>
// #include <QPointer>
// #include <QString>
// #include <QDialog>
// #include <QWidget>


namespace Occ {

namespace Ui {
    class ShareDialog;
}

class ShareUserGroupWidget;
class LinkShare;

class ShareDialog : QDialog {

public:
    ShareDialog (QPointer<AccountState> accountState,
        const QString &sharePath,
        const QString &localPath,
        SharePermissions maxSharingPermissions,
        const QByteArray &numericFileId,
        ShareDialogStartPage startPage,
        QWidget *parent = nullptr);
    ~ShareDialog () override;

private slots:
    void done (int r) override;
    void slotPropfindReceived (QVariantMap &result);
    void slotPropfindError ();
    void slotThumbnailFetched (int &statusCode, QByteArray &reply);
    void slotAccountStateChanged (int state);

    void slotSharesFetched (QList<QSharedPointer<Share>> &shares);
    void slotAddLinkShareWidget (QSharedPointer<LinkShare> &linkShare);
    void slotDeleteShare ();
    void slotCreateLinkShare ();
    void slotCreatePasswordForLinkShare (QString &password);
    void slotCreatePasswordForLinkShareProcessed ();
    void slotLinkShareRequiresPassword ();
    void slotAdjustScrollWidgetSize ();

signals:
    void toggleShareLinkAnimation (bool start);
    void styleChanged ();

protected:
    void changeEvent (QEvent *) override;

private:
    void showSharingUi ();
    ShareLinkWidget *addLinkShareWidget (QSharedPointer<LinkShare> &linkShare);
    void initLinkShareWidget ();

    Ui.ShareDialog *_ui;

    QPointer<AccountState> _accountState;
    QString _sharePath;
    QString _localPath;
    SharePermissions _maxSharingPermissions;
    QByteArray _numericFileId;
    QString _privateLinkUrl;
    ShareDialogStartPage _startPage;
    ShareManager *_manager = nullptr;

    QList<ShareLinkWidget> _linkWidgetList;
    ShareLinkWidget* _emptyShareLinkWidget = nullptr;
    ShareUserGroupWidget *_userGroupWidget = nullptr;
    QProgressIndicator *_progressIndicator = nullptr;
};

} // namespace Occ
