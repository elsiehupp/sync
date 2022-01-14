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

    public AddCertificateDialog (Gtk.Widget *parent = nullptr);
    public ~AddCertificateDialog () override;
    public string get_certificate_path ();
    public string get_certificate_passwd ();
    public void show_error_message (string message);
    public void reinit ();

private slots:
    void on_push_button_browse_certificate_clicked ();

private:
    Ui.AddCertificateDialog *ui;
};


    AddCertificateDialog.AddCertificateDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.AddCertificateDialog) {
        ui.setup_ui (this);
        ui.label_error_certif.set_text ("");
    }

    AddCertificateDialog.~AddCertificateDialog () {
        delete ui;
    }

    void AddCertificateDialog.on_push_button_browse_certificate_clicked () {
        string file_name = QFileDialog.get_open_file_name (this, tr ("Select a certificate"), "", tr ("Certificate files (*.p12 *.pfx)"));
        ui.line_edit_certificate_path.set_text (file_name);
    }

    string AddCertificateDialog.get_certificate_path () {
        return ui.line_edit_certificate_path.text ();
    }

    string AddCertificateDialog.get_certificate_passwd () {
        return ui.line_edit_p_wDCertificate.text ();
    }

    void AddCertificateDialog.show_error_message (string message) {
        ui.label_error_certif.set_text (message);
    }

    void AddCertificateDialog.reinit () {
        ui.label_error_certif.clear ();
        ui.line_edit_certificate_path.clear ();
        ui.line_edit_p_wDCertificate.clear ();
    }
    }
    