/***********************************************************
Copyright (C) 2015 by nocteau
Copyright (C) 2015 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QLineEdit>

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class AddCertificateDialog;
}

/***********************************************************
@brief The AddCertificateDialog class
@ingroup gui
***********************************************************/
class AddCertificateDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public AddCertificateDialog (Gtk.Widget parent = nullptr);
    ~AddCertificateDialog () override;
    public string get_certificate_path ();


    /***********************************************************
    ***********************************************************/
    public string get_certificate_passwd ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void reinit ();


    /***********************************************************
    ***********************************************************/
    private void on_push_button_browse_certificate_clicked ();

    /***********************************************************
    ***********************************************************/
    private 
    private Ui.AddCertificateDialog ui;
}


    AddCertificateDialog.AddCertificateDialog (Gtk.Widget parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.AddCertificateDialog) {
        ui.setup_ui (this);
        ui.label_error_certif.on_set_text ("");
    }

    AddCertificateDialog.~AddCertificateDialog () {
        delete ui;
    }

    void AddCertificateDialog.on_push_button_browse_certificate_clicked () {
        string filename = QFileDialog.get_open_filename (this, _("Select a certificate"), "", _("Certificate files (*.p12 *.pfx)"));
        ui.line_edit_certificate_path.on_set_text (filename);
    }

    string AddCertificateDialog.get_certificate_path () {
        return ui.line_edit_certificate_path.text ();
    }

    string AddCertificateDialog.get_certificate_passwd () {
        return ui.line_edit_p_wDCertificate.text ();
    }

    void AddCertificateDialog.show_error_message (string message) {
        ui.label_error_certif.on_set_text (message);
    }

    void AddCertificateDialog.reinit () {
        ui.label_error_certif.clear ();
        ui.line_edit_certificate_path.clear ();
        ui.line_edit_p_wDCertificate.clear ();
    }
    }
    