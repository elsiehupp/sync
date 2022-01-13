/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
}

class FolderCreationDialog : Gtk.Dialog {

public:
    FolderCreationDialog (string &destination, Gtk.Widget *parent = nullptr);
    ~FolderCreationDialog () override;

private slots:
    void accept () override;

    void slotNewFolderNameEditTextEdited ();

private:
    Ui.FolderCreationDialog *ui;

    string _destination;
};

}







/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <limits>

// #include <QDir>
// #include <QMessageBox>
// #include <QLoggingCategory>

namespace Occ {

    Q_LOGGING_CATEGORY (lcFolderCreationDialog, "nextcloud.gui.foldercreationdialog", QtInfoMsg)
    
    FolderCreationDialog.FolderCreationDialog (string &destination, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.FolderCreationDialog)
        , _destination (destination) {
        ui.setupUi (this);
    
        ui.labelErrorMessage.setVisible (false);
    
        setWindowFlags (windowFlags () & ~Qt.WindowContextHelpButtonHint);
    
        connect (ui.newFolderNameEdit, &QLineEdit.textChanged, this, &FolderCreationDialog.slotNewFolderNameEditTextEdited);
    
        const string suggestedFolderNamePrefix = GLib.Object.tr ("New folder");
    
        const string newFolderFullPath = _destination + QLatin1Char ('/') + suggestedFolderNamePrefix;
        if (!QDir (newFolderFullPath).exists ()) {
            ui.newFolderNameEdit.setText (suggestedFolderNamePrefix);
        } else {
            for (unsigned int i = 2; i < std.numeric_limits<unsigned int>.max (); ++i) {
                const string suggestedPostfix = string (" (%1)").arg (i);
    
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
    
        Gtk.Dialog.accept ();
    }
    
    void FolderCreationDialog.slotNewFolderNameEditTextEdited () {
        if (!ui.newFolderNameEdit.text ().isEmpty () && QDir (_destination + "/" + ui.newFolderNameEdit.text ()).exists ()) {
            ui.labelErrorMessage.setVisible (true);
        } else {
            ui.labelErrorMessage.setVisible (false);
        }
    }
    
    }
    