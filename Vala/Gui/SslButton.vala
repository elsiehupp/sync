/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QMenu>
//  #include <QtNetwork>
//  #include <QSslConfiguration>
//  #include <QWidgetAction>
//  #include <QToolButt
//  #include <QPointer>
//  #include <QSsl>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SslButton class
@ingroup gui
***********************************************************/
class SslButton : QToolButton {

    /***********************************************************
    ***********************************************************/
    private QPointer<AccountState> account_state;
    private QMenu menu;

    /***********************************************************
    ***********************************************************/
    public SslButton (Gtk.Widget parent = null) {
        base (parent);
        popup_mode (QToolButton.Instant_popup);
        auto_raise (true);

        this.menu = new QMenu (this);
        connect (
            this.menu,
            QMenu.about_to_show,
            this,SslButton.on_signal_update_menu
        );
        menu (this.menu);
    }


    /***********************************************************
    ***********************************************************/
    public void update_account_state (AccountState account_state) {
        if (!account_state || !account_state.is_connected ()) {
            visible (false);
            return;
        } else {
            visible (true);
        }
        this.account_state = account_state;

        AccountPointer account = this.account_state.account ();
        if (account.url ().scheme () == "https") {
            icon (QIcon (":/client/theme/lock-https.svg"));
            QSslCipher cipher = account.session_cipher;
            tool_tip (_("This connection is encrypted using %1 bit %2.\n").arg (cipher.used_bits ()).arg (cipher.name ()));
        } else {
            icon (QIcon (":/client/theme/lock-http.svg"));
            tool_tip (_("This connection is NOT secure as it is not encrypted.\n"));
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_update_menu () {
        this.menu.clear ();

        if (!this.account_state) {
            return;
        }

        AccountPointer account = this.account_state.account ();

        this.menu.add_action (_("Server version : %1").arg (account.server_version ())).enabled (false);

        if (account.is_http2Supported ()) {
            this.menu.add_action ("HTTP/2").enabled (false);
        }

        if (account.url ().scheme () == "https") {
            string ssl_version = account.session_cipher.protocol_""
                + ", " + account.session_cipher.authentication_method ()
                + ", " + account.session_cipher.key_exchange_method ()
                + ", " + account.session_cipher.encryption_method ();
            this.menu.add_action (ssl_version).enabled (false);

            if (account.session_ticket.is_empty ()) {
                this.menu.add_action (_("No support for SSL session tickets/identifiers")).enabled (false);
            }

            GLib.List<QSslCertificate> chain = account.peer_certificate_chain;

            if (chain.is_empty ()) {
                GLib.warning ("Empty certificate chain";
                return;
            }

            this.menu.add_action (_("Certificate information:")).enabled (false);

            const var system_certificates = QSslConfiguration.system_ca_certificates ();

            GLib.List<QSslCertificate> tmp_chain;
            foreach (QSslCertificate cert, chain) {
                tmp_chain + cert;
                if (system_certificates.contains (cert))
                    break;
            }
            chain = tmp_chain;

            // find trust anchor (informational only, verification is done by QSslSocket!)
            for (QSslCertificate root_cA : system_certificates) {
                if (root_cA.issuer_info (QSslCertificate.Common_name) == chain.last ().issuer_info (QSslCertificate.Common_name)
                    && root_cA.issuer_info (QSslCertificate.Organization) == chain.last ().issuer_info (QSslCertificate.Organization)) {
                    chain.append (root_cA);
                    break;
                }
            }

            QList_iterator<QSslCertificate> it (chain);
            it.to_back ();
            int i = 0;
            while (it.has_previous ()) {
                this.menu.add_menu (build_cert_menu (this.menu, it.previous (), account.approved_certificates (), i, system_certificates));
                i++;
            }
        } else {
            this.menu.add_action (_("The connection is not secure")).enabled (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private QMenu build_cert_menu (QMenu parent, QSslCertificate cert,
        GLib.List<QSslCertificate> user_approved, int position, GLib.List<QSslCertificate> system_ca_certificates) {
        string cn = string[] (cert.subject_info (QSslCertificate.Common_name)).join (char (';'));
        string ou = string[] (cert.subject_info (QSslCertificate.Organizational_unit_name)).join (char (';'));
        string org = string[] (cert.subject_info (QSslCertificate.Organization)).join (char (';'));
        string country = string[] (cert.subject_info (QSslCertificate.Country_name)).join (char (';'));
        string state = string[] (cert.subject_info (QSslCertificate.State_or_province_name)).join (char (';'));
        string issuer = string[] (cert.issuer_info (QSslCertificate.Common_name)).join (char (';'));
        if (issuer.is_empty ())
            issuer = string[] (cert.issuer_info (QSslCertificate.Organizational_unit_name)).join (char (';'));
        string sha1 = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha1).to_hex (), false);
        GLib.ByteArray sha265hash = cert.digest (QCryptographicHash.Sha256).to_hex ();
        string sha256escaped =
            Utility.escape (Utility.format_fingerprint (sha265hash.left (sha265hash.length () / 2), false))
            + "<br/>"
            + Utility.escape (Utility.format_fingerprint (sha265hash.mid (sha265hash.length () / 2), false));
        string serial = string.from_utf8 (cert.serial_number ());
        string effective_date = cert.effective_date ().date ().to_string ();
        string expiry_date = cert.expiry_date ().date ().to_string ();
        string sna = string[] (cert.subject_alternative_names ().values ()).join (" ");

        string details;
        QTextStream stream (details);

        stream += "<html><body>";

        stream += _("<h3>Certificate Details</h3>");

        stream += "<table>";
        stream += add_cert_details_field (_("Common Name (CN):"), Utility.escape (cn));
        stream += add_cert_details_field (_("Subject Alternative Names:"), Utility.escape (sna).replace (" ", "<br/>"));
        stream += add_cert_details_field (_("Organization (O):"), Utility.escape (org));
        stream += add_cert_details_field (_("Organizational Unit (OU):"), Utility.escape (ou));
        stream += add_cert_details_field (_("State/Province:"), Utility.escape (state));
        stream += add_cert_details_field (_("Country:"), Utility.escape (country));
        stream += add_cert_details_field (_("Serial:"), Utility.escape (serial));
        stream += "</table>";

        stream += _("<h3>Issuer</h3>");

        stream += "<table>";
        stream += add_cert_details_field (_("Issuer:"), Utility.escape (issuer));
        stream += add_cert_details_field (_("Issued on:"), Utility.escape (effective_date));
        stream += add_cert_details_field (_("Expires on:"), Utility.escape (expiry_date));
        stream += "</table>";

        stream += _("<h3>Fingerprints</h3>");

        stream += "<table>";

        stream += add_cert_details_field (_("SHA-256:"), sha256escaped);
        stream += add_cert_details_field (_("SHA-1:"), Utility.escape (sha1));
        stream += "</table>";

        if (user_approved.contains (cert)) {
            stream += _("<p><b>Note:</b> This certificate was manually approved</p>");
        }
        stream += "</body></html>";

        string txt;
        if (position > 0) {
            txt += string (2 * position, ' ');
            if (!Utility.is_windows ()) {
                // doesn't seem to work reliably on Windows
                txt += char (0x21AA); // nicer '.' symbol
                txt += char (' ');
            }
        }

        string cert_id = cn.is_empty () ? ou : cn;

        if (system_ca_certificates.contains (cert)) {
            txt += cert_id;
        } else {
            if (is_self_signed (cert)) {
                txt += _("%1 (self-signed)").arg (cert_id);
            } else {
                txt += _("%1").arg (cert_id);
            }
        }

        // create label first
        var label = new Gtk.Label (parent);
        label.style_sheet ("Gtk.Label { padding : 8px; }");
        label.text_format (Qt.RichText);
        label.on_signal_text (details);

        // plug label into widget action
        var action = new QWidgetAction (parent);
        action.default_widget (label);
        // plug action into menu
        var menu = new QMenu (parent);
        menu.menu_action ().on_signal_text (txt);
        menu.add_action (action);

        return menu;
    }


    /***********************************************************
    ***********************************************************/
    private static string add_cert_details_field (string key, string value) {
        if (value.is_empty ()) {
            return "";
        }

        return "<tr><td style=\"vertical-align : top;\"><b>" + key
             + "</b></td><td style=\"vertical-align : bottom;\">" + value
             + "</td></tr>";
    }

    /***********************************************************
    Necessary indication only, not sufficient for primary
    validation!
    ***********************************************************/
    private static bool is_self_signed (QSslCertificate certificate) {
        return certificate.issuer_info (QSslCertificate.Common_name) == certificate.subject_info (QSslCertificate.Common_name)
            && certificate.issuer_info (QSslCertificate.Organizational_unit_name) == certificate.subject_info (QSslCertificate.Organizational_unit_name);
    }

} // class SslButton

} // namespace Ui
} // namespace Occ
    