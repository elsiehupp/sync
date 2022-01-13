/*
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

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

// #include <accountfwd.h>
// #include <account.h>

// #include <memory>

// #include <QDialog>

namespace Occ {


namespace Ui {
    class InvalidFilenameDialog;
}

class InvalidFilenameDialog : QDialog {

public:
    InvalidFilenameDialog (AccountPtr account, Folder *folder, QString filePath, QWidget *parent = nullptr);

    ~InvalidFilenameDialog () override;

    void accept () override;

private:
    std.unique_ptr<Ui.InvalidFilenameDialog> _ui;

    AccountPtr _account;
    Folder *_folder;
    QString _filePath;
    QString _relativeFilePath;
    QString _originalFileName;
    QString _newFilename;

    void onFilenameLineEditTextChanged (QString &text);
    void onMoveJobFinished ();
    void onRemoteFileAlreadyExists (QVariantMap &values);
    void onRemoteFileDoesNotExist (QNetworkReply *reply);
    void checkIfAllowedToRename ();
    void onPropfindPermissionSuccess (QVariantMap &values);
};
}
