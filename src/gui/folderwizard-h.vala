/*
 * Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
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

// #include <QWizard>
// #include <QNetworkReply>
// #include <QTimer>

class QCheckBox;

namespace OCC {

class SelectiveSyncWidget;

class ownCloudInfo;

/**
 * @brief The FormatWarningsWizardPage class
 * @ingroup gui
 */
class FormatWarningsWizardPage : public QWizardPage {
protected:
    QString formatWarnings(QStringList &warnings) const;
};

/**
 * @brief Page to ask for the local source folder
 * @ingroup gui
 */
class FolderWizardLocalPath : public FormatWarningsWizardPage {
public:
    explicit FolderWizardLocalPath(AccountPtr &account);
    ~FolderWizardLocalPath() override;

    bool isComplete() const override;
    void initializePage() override;
    void cleanupPage() override;

    void setFolderMap(Folder::Map &fm) { _folderMap = fm; }
protected slots:
    void slotChooseLocalFolder();

private:
    Ui_FolderWizardSourcePage _ui;
    Folder::Map _folderMap;
    AccountPtr _account;
};

/**
 * @brief page to ask for the target folder
 * @ingroup gui
 */

class FolderWizardRemotePath : public FormatWarningsWizardPage {
public:
    explicit FolderWizardRemotePath(AccountPtr &account);
    ~FolderWizardRemotePath() override;

    bool isComplete() const override;

    void initializePage() override;
    void cleanupPage() override;

protected slots:

    void showWarn(QString & = QString()) const;
    void slotAddRemoteFolder();
    void slotCreateRemoteFolder(QString &);
    void slotCreateRemoteFolderFinished();
    void slotHandleMkdirNetworkError(QNetworkReply *);
    void slotHandleLsColNetworkError(QNetworkReply *);
    void slotUpdateDirectories(QStringList &);
    void slotGatherEncryptedPaths(QString &, QMap<QString, QString> &);
    void slotRefreshFolders();
    void slotItemExpanded(QTreeWidgetItem *);
    void slotCurrentItemChanged(QTreeWidgetItem *);
    void slotFolderEntryEdited(QString &text);
    void slotLsColFolderEntry();
    void slotTypedPathFound(QStringList &subpaths);

private:
    LsColJob *runLsColJob(QString &path);
    void recursiveInsert(QTreeWidgetItem *parent, QStringList pathTrail, QString path);
    bool selectByPath(QString path);
    Ui_FolderWizardTargetPage _ui;
    bool _warnWasVisible;
    AccountPtr _account;
    QTimer _lscolTimer;
    QStringList _encryptedPaths;
};

/**
 * @brief The FolderWizardSelectiveSync class
 * @ingroup gui
 */
class FolderWizardSelectiveSync : public QWizardPage {
public:
    explicit FolderWizardSelectiveSync(AccountPtr &account);
    ~FolderWizardSelectiveSync() override;

    bool validatePage() override;

    void initializePage() override;
    void cleanupPage() override;

private slots:
    void virtualFilesCheckboxClicked();

private:
    SelectiveSyncWidget *_selectiveSync;
    QCheckBox *_virtualFilesCheckBox = nullptr;
};

/**
 * @brief The FolderWizard class
 * @ingroup gui
 */
class FolderWizard : public QWizard {
public:
    enum {
        Page_Source,
        Page_Target,
        Page_SelectiveSync
    };

    explicit FolderWizard(AccountPtr account, QWidget *parent = nullptr);
    ~FolderWizard() override;

    bool eventFilter(QObject *watched, QEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    FolderWizardLocalPath *_folderWizardSourcePage;
    FolderWizardRemotePath *_folderWizardTargetPage;
    FolderWizardSelectiveSync *_folderWizardSelectiveSyncPage;
};

} // namespace OCC

#endif
