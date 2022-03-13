/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtGui>
//  #include <QtNetwork>
//  #include <Qt_widgets>
//  #include <QtCore>
//  #include <Gtk.Dialog>
//  #include <QSslCertificate>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SslErrorDialog class
@ingroup gui
***********************************************************/
class SslErrorDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private GLib.List<QSslCertificate> unknown_certificates;
    private string custom_config_handle;
    private Ui.SslErrorDialog ui;
    private AccountPointer account;

    /***********************************************************
    ***********************************************************/
    public SslErrorDialog (AccountPointer account, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.all_trusted = false;
        this.ui = new Ui.SslErrorDialog ();
        this.account = account;
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        this.ui.up_ui (this);
        window_title (_("Untrusted Certificate"));
        QPushButton ok_button =
            this.ui.dialog_button_box.button (QDialogButtonBox.Ok);
        QPushButton cancel_button =
            this.ui.dialog_button_box.button (QDialogButtonBox.Cancel);
        ok_button.enabled (false);

        this.ui.cb_trust_connect.enabled (!Theme.instance ().forbid_bad_ssl ());
        connect (this.ui.cb_trust_connect, QAbstractButton.clicked,
            ok_button, Gtk.Widget.enabled);

        if (ok_button) {
            ok_button.default (true);
            connect (ok_button, QAbstractButton.clicked, this, Gtk.Dialog.accept);
            connect (cancel_button, QAbstractButton.clicked, this, Gtk.Dialog.reject);
        }
    }


    /***********************************************************
    ***********************************************************/
    override ~SslErrorDialog () {
        delete this.ui;
    }


    /***********************************************************
    ***********************************************************/
    public bool check_failing_certificates_known (GLib.List<QSslError> errors) {
        // check if unknown certificates caused errors.
        this.unknown_certificates.clear ();

        string[] error_strings;

        string[] additional_error_strings;

        GLib.List<QSslCertificate> trusted_certificates = this.account.approved_certificates ();

        for (int i = 0; i < errors.count (); ++i) {
            QSslError error = errors.at (i);
            if (trusted_certificates.contains (error.certificate ()) || this.unknown_certificates.contains (error.certificate ())) {
                continue;
            }
            error_strings += error.error_string ();
            if (!error.certificate ().is_null ()) {
                this.unknown_certificates.append (error.certificate ());
            } else {
                additional_error_strings.append (error.error_string ());
            }
        }

        // if there are no errors left, all Certs were known.
        if (error_strings.is_empty ()) {
            this.all_trusted = true;
            return true;
        }

        string message = QL ("<html><head>");
        message += QL ("<link rel='stylesheet' type='text/css' href='format.css'>");
        message += QL ("</head><body>");

        var host = this.account.url ().host ();
        message += QL ("<h3>") + _("Cannot connect securely to <i>%1</i>:").arg (host) + QL ("</h3>");
        // loop over the unknown certificates and line up their errors.
        message += QL ("<div identifier=\"ca_errors\">");
        foreach (QSslCertificate cert, this.unknown_certificates) {
            message += QL ("<div identifier=\"ca_error\">");
            // add the errors for this cert
            foreach (QSslError err, errors) {
                if (err.certificate () == cert) {
                    message += QL ("<p>") + err.error_string () + QL ("</p>");
                }
            }
            message += QL ("</div>");
            message += cert_div (cert);
            if (this.unknown_certificates.count () > 1) {
                message += QL ("<hr/>");
            }
        }

        if (!additional_error_strings.is_empty ()) {
            message += QL ("<h4>") + _("Additional errors:") + QL ("</h4>");

            for (var error_string : additional_error_strings) {
                message += QL ("<div identifier=\"ca_error\">");
                message += QL ("<p>") + error_string + QL ("</p>");
                message += QL ("</div>");
            }
        }

        message += QL ("</div></body></html>");

        var doc = new QText_document (null);
        string style = style_sheet ();
        doc.add_resource (QText_document.Style_sheet_resource, GLib.Uri (QL ("format.css")), style);
        doc.html (message);

        this.ui.tb_errors.document (doc);
        this.ui.tb_errors.show ();

        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool trust_connection () {
        if (this.all_trusted)
            return true;

        bool stat = (this.ui.cb_trust_connect.check_state () == Qt.Checked);
        GLib.info ("SSL-Connection is trusted: " + stat;

        return stat;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<QSslCertificate> unknown_certificates () {
        return this.unknown_certificates;
    }


    /***********************************************************
    ***********************************************************/
    private string style_sheet () {
        return "#cert {margin-left : 5px;} "
            + "#ca_error { color:#a00011; margin-left:5px; margin-right:5px; }"
            + "#ca_error p { margin-top : 2px; margin-bottom:2px; }"
            + "#ccert { margin-left : 5px; }"
            + "#issuer { margin-left : 5px; }"
            + "tt { font-size : small; }";
    }


    /***********************************************************
    ***********************************************************/
    private string cert_div (QSslCertificate cert) {
        string message;
        message += QL ("<div identifier=\"cert\">");
        message += QL ("<h3>") + _("with Certificate %1").arg (Utility.escape (cert.subject_info (QSslCertificate.Common_name))) + QL ("</h3>");

        message += QL ("<div identifier=\"ccert\">");
        string[] li;

        string org = Utility.escape (cert.subject_info (QSslCertificate.Organization));
        string unit = Utility.escape (cert.subject_info (QSslCertificate.Organizational_unit_name));
        string country = Utility.escape (cert.subject_info (QSslCertificate.Country_name));
        if (unit.is_empty ())
            unit = _("&lt;not specified&gt;");
        if (org.is_empty ())
            org = _("&lt;not specified&gt;");
        if (country.is_empty ())
            country = _("&lt;not specified&gt;");
        li + _("Organization : %1").arg (org);
        li + _("Unit : %1").arg (unit);
        li + _("Country : %1").arg (country);
        message += QL ("<p>") + li.join (QL ("<br/>")) + QL ("</p>");

        message += QL ("<p>");

        if (cert.effective_date () < GLib.DateTime (QDate (2016, 1, 1), QTime (), Qt.UTC)) {
        string sha1sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha1).to_hex ());
            message += _("Fingerprint (SHA1) : <tt>%1</tt>").arg (sha1sum) + QL ("<br/>");
        }

        string sha256sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha256).to_hex ());
        string sha512sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha512).to_hex ());
        message += _("Fingerprint (SHA-256) : <tt>%1</tt>").arg (sha256sum) + QL ("<br/>");
        message += _("Fingerprint (SHA-512) : <tt>%1</tt>").arg (sha512sum) + QL ("<br/>");
        message += QL ("<br/>");
        message += _("Effective Date : %1").arg (cert.effective_date ().to_string ()) + QL ("<br/>");
        message += _("Expiration Date : %1").arg (cert.expiry_date ().to_string ()) + QL ("</p>");

        message += QL ("</div>");

        message += QL ("<h3>") + _("Issuer : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Common_name))) + QL ("</h3>");
        message += QL ("<div identifier=\"issuer\">");
        li.clear ();
        li + _("Organization : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Organization)));
        li + _("Unit : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Organizational_unit_name)));
        li + _("Country : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Country_name)));
        message += QL ("<p>") + li.join (QL ("<br/>")) + QL ("</p>");
        message += QL ("</div>");
        message += QL ("</div>");

        return message;
    }


    /***********************************************************
    Used for QSSLCertificate.subject_info which returns a
    string[] in Qt5, but a string in Qt4
    ***********************************************************/
    private static string escape (string[] l) {
        return escape (l.join (';'));
    }


    /***********************************************************
    ***********************************************************/
    private static int QL (int x) {
        return x;
    }

}

}
}
    