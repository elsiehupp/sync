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

// #include <QDialog>
// #include <QStyledItemDelegate>

class QActionGroup;
class QStandardItemModel;

namespace Occ {


namespace Ui {
    class SettingsDialog;
}
class Application;
class ownCloudGui;

/**
@brief The SettingsDialog class
@ingroup gui
*/
class SettingsDialog : QDialog {
    Q_PROPERTY (QWidget* currentPage READ currentPage)

public:
    SettingsDialog (ownCloudGui *gui, QWidget *parent = nullptr);
    ~SettingsDialog () override;

    QWidget* currentPage ();

public slots:
    void showFirstPage ();
    void showIssuesList (AccountState *account);
    void slotSwitchPage (QAction *action);
    void slotAccountAvatarChanged ();
    void slotAccountDisplayNameChanged ();

signals:
    void styleChanged ();
    void onActivate ();

protected:
    void reject () override;
    void accept () override;
    void changeEvent (QEvent *) override;

private slots:
    void accountAdded (AccountState *);
    void accountRemoved (AccountState *);

private:
    void customizeStyle ();

    QAction *createColorAwareAction (QString &iconName, QString &fileName);
    QAction *createActionWithIcon (QIcon &icon, QString &text, QString &iconPath = QString ());

    Ui.SettingsDialog *const _ui;

    QActionGroup *_actionGroup;
    // Maps the actions from the action group to the corresponding widgets
    QHash<QAction *, QWidget> _actionGroupWidgets;

    // Maps the action in the dialog to their according account. Needed in
    // case the account avatar changes
    QHash<Account *, QAction> _actionForAccount;

    QToolBar *_toolBar;

    ownCloudGui *_gui;
};
}
