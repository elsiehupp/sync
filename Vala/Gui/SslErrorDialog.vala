namespace Occ {
namespace Ui {

/***********************************************************
@class SslErrorDialog

@author Klaas Freitag <freitag@kde.org>

@copyright GPLv3 or Later
***********************************************************/
public class SslErrorDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    GLib.List<GLib.SslCertificate> unknown_certificates { public get; private set; }

    private string custom_config_handle;
    private SslErrorDialog instance;
    private unowned Account account;

    /***********************************************************
    ***********************************************************/
    public SslErrorDialog (unowned Account account, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.all_trusted = false;
        this.instance = new SslErrorDialog ();
        this.account = account;
        window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);
        this.instance.up_ui (this);
        window_title (_("Untrusted Certificate"));
        GLib.PushButton ok_button =
            this.instance.dialog_button_box.button (GLib.DialogButtonBox.Ok);
        GLib.PushButton cancel_button =
            this.instance.dialog_button_box.button (GLib.DialogButtonBox.Cancel);
        ok_button.enabled (false);

        this.instance.cb_trust_connect.enabled (!Theme.forbid_bad_ssl);
        this.instance.cb_trust_connect.clicked.connect (
            ok_button.enabled
        );

        if (ok_button) {
            ok_button.default (true);
            ok_button.clicked.connect (
                this.accept
            );
            cancel_button.clicked.connect (
                this.reject
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    override ~SslErrorDialog () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public bool check_failing_certificates_known (GLib.List<GLib.SslError> errors) {
        // check if unknown certificates caused errors.
        this.unknown_certificates == null;

        GLib.List<string> error_strings;

        GLib.List<string> additional_error_strings = new GLib.List<string> ();

        GLib.List<GLib.SslCertificate> trusted_certificates = this.account.approved_certificates ();

        for (int i = 0; i < errors.length (); ++i) {
            GLib.SslError error = errors.at (i);
            if (trusted_certificates.contains (error.certificate ()) || this.unknown_certificates.contains (error.certificate ())) {
                continue;
            }
            error_strings += error.error_string;
            if (!error.certificate () == null) {
                this.unknown_certificates.append (error.certificate ());
            } else {
                additional_error_strings.append (error.error_string);
            }
        }

        // if there are no errors left, all Certs were known.
        if (error_strings.length () == 0) {
            this.all_trusted = true;
            return true;
        }

        string message = GLib.L ("<html><head>");
        message += GLib.L ("<link rel='stylesheet' type='text/css' href='format.css'>");
        message += GLib.L ("</head><body>");

        var host = this.account.url.host ();
        message += GLib.L ("<h3>") + _("Cannot connect securely to <i>%1</i>:").printf (host) + GLib.L ("</h3>");
        // loop over the unknown certificates and line up their errors.
        message += GLib.L ("<div identifier=\"ca_errors\">");
        foreach (GLib.SslCertificate cert in this.unknown_certificates) {
            message += GLib.L ("<div identifier=\"ca_error\">");
            // add the errors for this cert
            foreach (GLib.SslError err in errors) {
                if (err.certificate () == cert) {
                    message += GLib.L ("<p>") + err.error_string + GLib.L ("</p>");
                }
            }
            message += GLib.L ("</div>");
            message += cert_div (cert);
            if (this.unknown_certificates.length > 1) {
                message += GLib.L ("<hr/>");
            }
        }

        if (additional_error_strings.length () != 0) {
            message += GLib.L ("<h4>") + _("Additional errors:") + GLib.L ("</h4>");

            foreach (var error_string in additional_error_strings) {
                message += GLib.L ("<div identifier=\"ca_error\">");
                message += GLib.L ("<p>") + error_string + GLib.L ("</p>");
                message += GLib.L ("</div>");
            }
        }

        message += GLib.L ("</div></body></html>");

        var doc = new GLib.Text_document (null);
        string style = style_sheet ();
        doc.add_resource (GLib.Text_document.Style_sheet_resource, GLib.Uri (GLib.L ("format.css")), style);
        doc.html (message);

        this.instance.tb_errors.document (doc);
        this.instance.tb_errors.show ();

        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool trust_connection () {
        if (this.all_trusted)
            return true;

        bool stat = (this.instance.cb_trust_connect.check_state () == GLib.Checked);
        GLib.info ("SSL-Connection is trusted: " + stat);

        return stat;
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
    private string cert_div (GLib.SslCertificate cert) {
        string message;
        message += GLib.L ("<div identifier=\"cert\">");
        message += GLib.L ("<h3>") + _("with Certificate %1").printf (Utility.escape (cert.subject_info (GLib.SslCertificate.Common_name))) + GLib.L ("</h3>");

        message += GLib.L ("<div identifier=\"ccert\">");
        GLib.List<string> li;

        string org = Utility.escape (cert.subject_info (GLib.SslCertificate.Organization));
        string unit = Utility.escape (cert.subject_info (GLib.SslCertificate.Organizational_unit_name));
        string country = Utility.escape (cert.subject_info (GLib.SslCertificate.Country_name));
        if (unit == "")
            unit = _("&lt;not specified&gt;");
        if (org == "")
            org = _("&lt;not specified&gt;");
        if (country == "")
            country = _("&lt;not specified&gt;");
        li += _("Organization : %1").printf (org);
        li += _("Unit : %1").printf (unit);
        li += _("Country : %1").printf (country);
        message += GLib.L ("<p>") + li.join (GLib.L ("<br/>")) + GLib.L ("</p>");

        message += GLib.L ("<p>");

        if (cert.effective_date () < new GLib.DateTime (GLib.Date (2016, 1, 1), GLib.Time (), GLib.UTC)) {
        string sha1sum = Utility.format_fingerprint (cert.digest (GLib.ChecksumType.SHA1).to_hex ());
            message += _("Fingerprint (SHA1) : <tt>%1</tt>").printf (sha1sum) + GLib.L ("<br/>");
        }

        string sha256sum = Utility.format_fingerprint (cert.digest (GLib.CryptographicHash.Sha256).to_hex ());
        string sha512sum = Utility.format_fingerprint (cert.digest (GLib.CryptographicHash.Sha512).to_hex ());
        message += _("Fingerprint (SHA-256) : <tt>%1</tt>").printf (sha256sum) + GLib.L ("<br/>");
        message += _("Fingerprint (SHA-512) : <tt>%1</tt>").printf (sha512sum) + GLib.L ("<br/>");
        message += GLib.L ("<br/>");
        message += _("Effective Date : %1").printf (cert.effective_date ().to_string ()) + GLib.L ("<br/>");
        message += _("Expiration Date : %1").printf (cert.expiry_date ().to_string ()) + GLib.L ("</p>");

        message += GLib.L ("</div>");

        message += GLib.L ("<h3>") + _("Issuer : %1").printf (Utility.escape (cert.issuer_info (GLib.SslCertificate.Common_name))) + GLib.L ("</h3>");
        message += GLib.L ("<div identifier=\"issuer\">");
        li == "";
        li += _("Organization : %1").printf (Utility.escape (cert.issuer_info (GLib.SslCertificate.Organization)));
        li += _("Unit : %1").printf (Utility.escape (cert.issuer_info (GLib.SslCertificate.Organizational_unit_name)));
        li += _("Country : %1").printf (Utility.escape (cert.issuer_info (GLib.SslCertificate.Country_name)));
        message += GLib.L ("<p>") + li.join (GLib.L ("<br/>")) + GLib.L ("</p>");
        message += GLib.L ("</div>");
        message += GLib.L ("</div>");

        return message;
    }


    /***********************************************************
    Used for GLib.SSLCertificate.subject_info which returns a
    GLib.List<string> in Qt5, but a string in Qt4
    ***********************************************************/
    private static string escape (GLib.List<string> l) {
        return escape (l.join (';'));
    }


    /***********************************************************
    ***********************************************************/
    private static int GLib.L (int x) {
        return x;
    }

}

}

} // namespace Testing
} // namespace Occ
    