/*
 * Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QDialog>
// #include <QWidget>
// #include <QSharedPointer>
// #include <QList>
// #include <QVector>
// #include <QTimer>
// #include <qpushbutton.h>
// #include <qscrollarea.h>

class QAction;
class QCompleter;
class QModelIndex;

namespace OCC {

namespace Ui {
    class ShareUserGroupWidget;
    class ShareUserLine;
}

class AbstractCredentials;
class SyncResult;
class Share;
class ShareManager;

class AvatarEventFilter : public QObject {

public:
    explicit AvatarEventFilter(QObject *parent = nullptr);

signals:
    void clicked();
    void contextMenu(QPoint &globalPosition);

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;
};

/**
 * @brief The ShareDialog (user/group) class
 * @ingroup gui
 */
class ShareUserGroupWidget : public QWidget {

public:
    explicit ShareUserGroupWidget(AccountPtr account,
        const QString &sharePath,
        const QString &localPath,
        SharePermissions maxSharingPermissions,
        const QString &privateLinkUrl,
        QWidget *parent = nullptr);
    ~ShareUserGroupWidget() override;

signals:
    void togglePublicLinkShare(bool);
    void styleChanged();

public slots:
    void getShares();
    void slotShareCreated(QSharedPointer<Share> &share);
    void slotStyleChanged();

private slots:
    void slotSharesFetched(QList<QSharedPointer<Share>> &shares);

    void on_shareeLineEdit_textChanged(QString &text);
    void searchForSharees(ShareeModel::LookupMode lookupMode);
    void slotLineEditTextEdited(QString &text);

    void slotLineEditReturn();
    void slotCompleterActivated(QModelIndex &index);
    void slotCompleterHighlighted(QModelIndex &index);
    void slotShareesReady();
    void slotAdjustScrollWidgetSize();
    void slotPrivateLinkShare();
    void displayError(int code, QString &message);

    void slotPrivateLinkOpenBrowser();
    void slotPrivateLinkCopy();
    void slotPrivateLinkEmail();

private:
    void customizeStyle();

    void activateShareeLineEdit();

    Ui::ShareUserGroupWidget *_ui;
    QScrollArea *_parentScrollArea;
    AccountPtr _account;
    QString _sharePath;
    QString _localPath;
    SharePermissions _maxSharingPermissions;
    QString _privateLinkUrl;

    QCompleter *_completer;
    ShareeModel *_completerModel;
    QTimer _completionTimer;

    bool _isFile;
    bool _disableCompleterActivated; // in order to avoid that we share the contents twice
    ShareManager *_manager;

    QProgressIndicator _pi_sharee;

    QString _lastCreatedShareId;
};

/**
 * The widget displayed for each user/group share
 */
class ShareUserLine : public QWidget {

public:
    explicit ShareUserLine(AccountPtr account,
        QSharedPointer<UserGroupShare> Share,
        SharePermissions maxSharingPermissions,
        bool isFile,
        QWidget *parent = nullptr);
    ~ShareUserLine() override;

    QSharedPointer<Share> share() const;

signals:
    void visualDeletionDone();
    void resizeRequested();

public slots:
    void slotStyleChanged();

    void focusPasswordLineEdit();

private slots:
    void on_deleteShareButton_clicked();
    void slotPermissionsChanged();
    void slotEditPermissionsChanged();
    void slotPasswordCheckboxChanged();
    void slotDeleteAnimationFinished();

    void refreshPasswordOptions();

    void refreshPasswordLineEditPlaceholder();

    void slotPasswordSet();
    void slotPasswordSetError(int statusCode, QString &message);

    void slotShareDeleted();
    void slotPermissionsSet();

    void slotAvatarLoaded(QImage avatar);

    void setPasswordConfirmed();

    void slotLineEditPasswordReturnPressed();

    void slotConfirmPasswordClicked();

    void onAvatarContextMenu(QPoint &globalPosition);

private:
    void displayPermissions();
    void loadAvatar();
    void setDefaultAvatar(int avatarSize);
    void customizeStyle();

    QPixmap pixmapForShareeType(Sharee::Type type, QColor &backgroundColor = QColor()) const;
    QColor backgroundColorForShareeType(Sharee::Type type) const;

  void showNoteOptions(bool show);
  void toggleNoteOptions(bool enable);
  void onNoteConfirmButtonClicked();
  void setNote(QString &note);

  void toggleExpireDateOptions(bool enable);
  void showExpireDateOptions(bool show, QDate &initialDate = QDate());
  void setExpireDate();

  void togglePasswordSetProgressAnimation(bool show);

  void enableProgessIndicatorAnimation(bool enable);
  void disableProgessIndicatorAnimation();

  QDate maxExpirationDateForShare(Share::ShareType type, QDate &fallbackDate) const;
  bool enforceExpirationDateForShare(Share::ShareType type) const;

  Ui::ShareUserLine *_ui;
  AccountPtr _account;
  QSharedPointer<UserGroupShare> _share;
  bool _isFile;

  ProfilePageMenu _profilePageMenu;

  // _permissionEdit is a checkbox
  QAction *_permissionReshare;
  QAction *_deleteShareButton;
  QAction *_permissionCreate;
  QAction *_permissionChange;
  QAction *_permissionDelete;
  QAction *_noteLinkAction;
  QAction *_expirationDateLinkAction;
  QAction *_passwordProtectLinkAction;
};
}

#endif // SHAREUSERGROUPWIDGET_H
