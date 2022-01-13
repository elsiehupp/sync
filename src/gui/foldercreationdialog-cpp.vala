/*
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <limits>

// #include <QDir>
// #include <QMessageBox>
// #include <QLoggingCategory>

namespace Occ {

Q_LOGGING_CATEGORY (lcFolderCreationDialog, "nextcloud.gui.foldercreationdialog", QtInfoMsg)

FolderCreationDialog.FolderCreationDialog (QString &destination, QWidget *parent)
    : QDialog (parent)
    , ui (new Ui.FolderCreationDialog)
    , _destination (destination) {
    ui.setupUi (this);

    ui.labelErrorMessage.setVisible (false);

    setWindowFlags (windowFlags () & ~Qt.WindowContextHelpButtonHint);

    connect (ui.newFolderNameEdit, &QLineEdit.textChanged, this, &FolderCreationDialog.slotNewFolderNameEditTextEdited);

    const QString suggestedFolderNamePrefix = GLib.Object.tr ("New folder");

    const QString newFolderFullPath = _destination + QLatin1Char ('/') + suggestedFolderNamePrefix;
    if (!QDir (newFolderFullPath).exists ()) {
        ui.newFolderNameEdit.setText (suggestedFolderNamePrefix);
    } else {
        for (unsigned int i = 2; i < std.numeric_limits<unsigned int>.max (); ++i) {
            const QString suggestedPostfix = QString (" (%1)").arg (i);

            if (!QDir (newFolderFullPath + suggestedPostfix).exists ()) {
                ui.newFolderNameEdit.setText (suggestedFolderNamePrefix + suggestedPostfix);
                break;
            }
        }
    }

    ui.newFolderNameEdit.setFocus ();
    ui.newFolderNameEdit.selectAll ();
}

FolderCreationDialog.~FolderCreationDialog () {
    delete ui;
}

void FolderCreationDialog.accept () {
    Q_ASSERT (!_destination.endsWith ('/'));

    if (QDir (_destination + "/" + ui.newFolderNameEdit.text ()).exists ()) {
        ui.labelErrorMessage.setVisible (true);
        return;
    }

    if (!QDir (_destination).mkdir (ui.newFolderNameEdit.text ())) {
        QMessageBox.critical (this, tr ("Error"), tr ("Could not create a folder! Check your write permissions."));
    }

    QDialog.accept ();
}

void FolderCreationDialog.slotNewFolderNameEditTextEdited () {
    if (!ui.newFolderNameEdit.text ().isEmpty () && QDir (_destination + "/" + ui.newFolderNameEdit.text ()).exists ()) {
        ui.labelErrorMessage.setVisible (true);
    } else {
        ui.labelErrorMessage.setVisible (false);
    }
}

}
