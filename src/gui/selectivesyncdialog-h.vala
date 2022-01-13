/*
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #pragma once
// #include <QDialog>
// #include <QTreeWidget>

class QTreeWidget;
class QLabel;
namespace Occ {


/**
@brief The SelectiveSyncWidget contains a folder tree with labels
@ingroup gui
*/
class SelectiveSyncWidget : QWidget {
public:
    SelectiveSyncWidget (AccountPtr account, QWidget *parent = nullptr);

    /// Returns a list of blacklisted paths, each including the trailing /
    QStringList createBlackList (QTreeWidgetItem *root = nullptr) const;

    /** Returns the oldBlackList passed into setFolderInfo (), except that
     *  a "/" entry is expanded to all top-level folder names.
     */
    QStringList oldBlackList ();

    // Estimates the total size of checked items (recursively)
    int64 estimatedSize (QTreeWidgetItem *root = nullptr);

    // oldBlackList is a list of excluded paths, each including a trailing /
    void setFolderInfo (QString &folderPath, QString &rootName,
        const QStringList &oldBlackList = QStringList ());

    QSize sizeHint () const override;

private slots:
    void slotUpdateDirectories (QStringList);
    void slotItemExpanded (QTreeWidgetItem *);
    void slotItemChanged (QTreeWidgetItem *, int);
    void slotLscolFinishedWithError (QNetworkReply *);
    void slotGatherEncryptedPaths (QString &, QMap<QString, QString> &);

private:
    void refreshFolders ();
    void recursiveInsert (QTreeWidgetItem *parent, QStringList pathTrail, QString path, int64 size);

    AccountPtr _account;

    QString _folderPath;
    QString _rootName;
    QStringList _oldBlackList;

    bool _inserting; // set to true when we are inserting new items on the list
    QLabel *_loading;

    QTreeWidget *_folderTree;

    // During account setup we want to filter out excluded folders from the
    // view without having a Folder.SyncEngine.ExcludedFiles instance.
    ExcludedFiles _excludedFiles;

    QStringList _encryptedPaths;
};

/**
@brief The SelectiveSyncDialog class
@ingroup gui
*/
class SelectiveSyncDialog : QDialog {
public:
    // Dialog for a specific folder (used from the account settings button)
    SelectiveSyncDialog (AccountPtr account, Folder *folder, QWidget *parent = nullptr, Qt.WindowFlags f = {});

    // Dialog for the whole account (Used from the wizard)
    SelectiveSyncDialog (AccountPtr account, QString &folder, QStringList &blacklist, QWidget *parent = nullptr, Qt.WindowFlags f = {});

    void accept () override;

    QStringList createBlackList ();
    QStringList oldBlackList ();

    // Estimate the size of the total of sync'ed files from the server
    int64 estimatedSize ();

private:
    void init (AccountPtr &account);

    SelectiveSyncWidget *_selectiveSync;

    Folder *_folder;
    QPushButton *_okButton;
};
}
