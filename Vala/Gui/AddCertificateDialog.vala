/***********************************************************
Copyright (C) 2015 by nocteau
Copyright (C) 2015 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QFileDialog>
//  #include <QLineEdit>
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The AddCertificateDialog class
@ingroup gui
***********************************************************/
public class AddCertificateDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private Ui.AddCertificateDialog ui;


    /***********************************************************
    ***********************************************************/
    public AddCertificateDialog (Gtk.Widget parent = null) {
        base (parent);
        this.ui = new Ui.AddCertificateDialog ();
        ui.up_ui (this);
        ui.label_error_certif.on_signal_text ("");
    }


    /***********************************************************
    ***********************************************************/
    override ~AddCertificateDialog () {
        delete ui;
    }


    /***********************************************************
    ***********************************************************/
    public string certificate_path () {
        return ui.line_edit_certificate_path.text ();
    }


    /***********************************************************
    ***********************************************************/
    public string certificate_password () {
        return ui.line_edit_p_wDCertificate.text ();
    }


    /***********************************************************
    ***********************************************************/
    public void show_error_message (string message) {
        ui.label_error_certif.on_signal_text (message);
    }


    /***********************************************************
    ***********************************************************/
    public void reinit () {
        ui.label_error_certif.clear ();
        ui.line_edit_certificate_path.clear ();
        ui.line_edit_p_wDCertificate.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_push_button_browse_certificate_clicked () {
        string filename = QFileDialog.open_filename (this, _("Select a certificate"), "", _("Certificate files (*.p12 *.pfx)"));
        ui.line_edit_certificate_path.on_signal_text (filename);
    }

} // class AddCertificateDialog
    
} // namespace Ui
} // namespace Occ
