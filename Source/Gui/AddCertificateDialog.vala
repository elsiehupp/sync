/***********************************************************
Copyright (C) 2015 by nocteau
Copyright (C) 2015 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QLineEdit>

// #include <Gtk.Dialog>
// #include <string>

namespace Occ {

namespace Ui {
    class AddCertificateDialog;
}

/***********************************************************
@brief The AddCertificateDialog class
@ingroup gui
***********************************************************/
class AddCertificateDialog : Gtk.Dialog {

public:
    AddCertificateDialog (Gtk.Widget *parent = nullptr);
    ~AddCertificateDialog () override;
    string getCertificatePath ();
    string getCertificatePasswd ();
    void showErrorMessage (string message);
    void reinit ();

private slots:
    void on_pushButtonBrowseCertificate_clicked ();

private:
    Ui.AddCertificateDialog *ui;
};


    AddCertificateDialog.AddCertificateDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.AddCertificateDialog) {
        ui.setupUi (this);
        ui.labelErrorCertif.setText ("");
    }
    
    AddCertificateDialog.~AddCertificateDialog () {
        delete ui;
    }
    
    void AddCertificateDialog.on_pushButtonBrowseCertificate_clicked () {
        string fileName = QFileDialog.getOpenFileName (this, tr ("Select a certificate"), "", tr ("Certificate files (*.p12 *.pfx)"));
        ui.lineEditCertificatePath.setText (fileName);
    }
    
    string AddCertificateDialog.getCertificatePath () {
        return ui.lineEditCertificatePath.text ();
    }
    
    string AddCertificateDialog.getCertificatePasswd () {
        return ui.lineEditPWDCertificate.text ();
    }
    
    void AddCertificateDialog.showErrorMessage (string message) {
        ui.labelErrorCertif.setText (message);
    }
    
    void AddCertificateDialog.reinit () {
        ui.labelErrorCertif.clear ();
        ui.lineEditCertificatePath.clear ();
        ui.lineEditPWDCertificate.clear ();
    }
    }
    