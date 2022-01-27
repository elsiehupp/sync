/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QMenu>
// #include <QUrl>
// #include <Qt_network>
// #include <QSslConfiguration>
// #include <QWidget_action>
// #include <QLabel>

// #include <QToolButton>
// #include <QPointer>
// #include <QSsl>


namespace Occ {


/***********************************************************
@brief The Ssl_button class
@ingroup gui
***********************************************************/
class Ssl_button : QToolButton {

    public Ssl_button (Gtk.Widget *parent = nullptr);
    public void update_account_state (AccountState *account_state);


    public void on_update_menu ();


    private QMenu *build_cert_menu (QMenu *parent, QSslCertificate &cert,
        const GLib.List<QSslCertificate> &user_approved, int pos, GLib.List<QSslCertificate> &system_ca_certificates);
    private QPointer<AccountState> _account_state;
    private QMenu _menu;
};


    Ssl_button.Ssl_button (Gtk.Widget *parent)
        : QToolButton (parent) {
        set_popup_mode (QToolButton.Instant_popup);
        set_auto_raise (true);

        _menu = new QMenu (this);
        GLib.Object.connect (_menu, &QMenu.about_to_show,
            this, &Ssl_button.on_update_menu);
        set_menu (_menu);
    }

    static string add_cert_details_field (string key, string value) {
        if (value.is_empty ())
            return string ();

        return QLatin1String ("<tr><td style=\"vertical-align : top;\"><b>") + key
            + QLatin1String ("</b></td><td style=\"vertical-align : bottom;\">") + value
            + QLatin1String ("</td></tr>");
    }

    // necessary indication only, not sufficient for primary validation!
    static bool is_self_signed (QSslCertificate &certificate) {
        return certificate.issuer_info (QSslCertificate.Common_name) == certificate.subject_info (QSslCertificate.Common_name)
            && certificate.issuer_info (QSslCertificate.Organizational_unit_name) == certificate.subject_info (QSslCertificate.Organizational_unit_name);
    }

    QMenu *Ssl_button.build_cert_menu (QMenu *parent, QSslCertificate &cert,
        const GLib.List<QSslCertificate> &user_approved, int pos, GLib.List<QSslCertificate> &system_ca_certificates) {
        string cn = string[] (cert.subject_info (QSslCertificate.Common_name)).join (QChar (';'));
        string ou = string[] (cert.subject_info (QSslCertificate.Organizational_unit_name)).join (QChar (';'));
        string org = string[] (cert.subject_info (QSslCertificate.Organization)).join (QChar (';'));
        string country = string[] (cert.subject_info (QSslCertificate.Country_name)).join (QChar (';'));
        string state = string[] (cert.subject_info (QSslCertificate.State_or_province_name)).join (QChar (';'));
        string issuer = string[] (cert.issuer_info (QSslCertificate.Common_name)).join (QChar (';'));
        if (issuer.is_empty ())
            issuer = string[] (cert.issuer_info (QSslCertificate.Organizational_unit_name)).join (QChar (';'));
        string sha1 = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha1).to_hex (), false);
        GLib.ByteArray sha265hash = cert.digest (QCryptographicHash.Sha256).to_hex ();
        string sha256escaped =
            Utility.escape (Utility.format_fingerprint (sha265hash.left (sha265hash.length () / 2), false))
            + QLatin1String ("<br/>")
            + Utility.escape (Utility.format_fingerprint (sha265hash.mid (sha265hash.length () / 2), false));
        string serial = string.from_utf8 (cert.serial_number ());
        string effective_date = cert.effective_date ().date ().to_string ();
        string expiry_date = cert.expiry_date ().date ().to_string ();
        string sna = string[] (cert.subject_alternative_names ().values ()).join (" ");

        string details;
        QTextStream stream (&details);

        stream << QLatin1String ("<html><body>");

        stream << tr ("<h3>Certificate Details</h3>");

        stream << QLatin1String ("<table>");
        stream << add_cert_details_field (tr ("Common Name (CN):"), Utility.escape (cn));
        stream << add_cert_details_field (tr ("Subject Alternative Names:"), Utility.escape (sna).replace (" ", "<br/>"));
        stream << add_cert_details_field (tr ("Organization (O):"), Utility.escape (org));
        stream << add_cert_details_field (tr ("Organizational Unit (OU):"), Utility.escape (ou));
        stream << add_cert_details_field (tr ("State/Province:"), Utility.escape (state));
        stream << add_cert_details_field (tr ("Country:"), Utility.escape (country));
        stream << add_cert_details_field (tr ("Serial:"), Utility.escape (serial));
        stream << QLatin1String ("</table>");

        stream << tr ("<h3>Issuer</h3>");

        stream << QLatin1String ("<table>");
        stream << add_cert_details_field (tr ("Issuer:"), Utility.escape (issuer));
        stream << add_cert_details_field (tr ("Issued on:"), Utility.escape (effective_date));
        stream << add_cert_details_field (tr ("Expires on:"), Utility.escape (expiry_date));
        stream << QLatin1String ("</table>");

        stream << tr ("<h3>Fingerprints</h3>");

        stream << QLatin1String ("<table>");

        stream << add_cert_details_field (tr ("SHA-256:"), sha256escaped);
        stream << add_cert_details_field (tr ("SHA-1:"), Utility.escape (sha1));
        stream << QLatin1String ("</table>");

        if (user_approved.contains (cert)) {
            stream << tr ("<p><b>Note:</b> This certificate was manually approved</p>");
        }
        stream << QLatin1String ("</body></html>");

        string txt;
        if (pos > 0) {
            txt += string (2 * pos, ' ');
            if (!Utility.is_windows ()) {
                // doesn't seem to work reliably on Windows
                txt += QChar (0x21AA); // nicer '.' symbol
                txt += QChar (' ');
            }
        }

        string cert_id = cn.is_empty () ? ou : cn;

        if (system_ca_certificates.contains (cert)) {
            txt += cert_id;
        } else {
            if (is_self_signed (cert)) {
                txt += tr ("%1 (self-signed)").arg (cert_id);
            } else {
                txt += tr ("%1").arg (cert_id);
            }
        }

        // create label first
        auto *label = new QLabel (parent);
        label.set_style_sheet (QLatin1String ("QLabel { padding : 8px; }"));
        label.set_text_format (Qt.RichText);
        label.on_set_text (details);

        // plug label into widget action
        auto *action = new QWidget_action (parent);
        action.set_default_widget (label);
        // plug action into menu
        auto *menu = new QMenu (parent);
        menu.menu_action ().on_set_text (txt);
        menu.add_action (action);

        return menu;
    }

    void Ssl_button.update_account_state (AccountState *account_state) {
        if (!account_state || !account_state.is_connected ()) {
            set_visible (false);
            return;
        } else {
            set_visible (true);
        }
        _account_state = account_state;

        AccountPtr account = _account_state.account ();
        if (account.url ().scheme () == QLatin1String ("https")) {
            set_icon (QIcon (QLatin1String (":/client/theme/lock-https.svg")));
            QSslCipher cipher = account._session_cipher;
            set_tool_tip (tr ("This connection is encrypted using %1 bit %2.\n").arg (cipher.used_bits ()).arg (cipher.name ()));
        } else {
            set_icon (QIcon (QLatin1String (":/client/theme/lock-http.svg")));
            set_tool_tip (tr ("This connection is NOT secure as it is not encrypted.\n"));
        }
    }

    void Ssl_button.on_update_menu () {
        _menu.clear ();

        if (!_account_state) {
            return;
        }

        AccountPtr account = _account_state.account ();

        _menu.add_action (tr ("Server version : %1").arg (account.server_version ())).set_enabled (false);

        if (account.is_http2Supported ()) {
            _menu.add_action ("HTTP/2").set_enabled (false);
        }

        if (account.url ().scheme () == QLatin1String ("https")) {
            string ssl_version = account._session_cipher.protocol_string ()
                + ", " + account._session_cipher.authentication_method ()
                + ", " + account._session_cipher.key_exchange_method ()
                + ", " + account._session_cipher.encryption_method ();
            _menu.add_action (ssl_version).set_enabled (false);

            if (account._session_ticket.is_empty ()) {
                _menu.add_action (tr ("No support for SSL session tickets/identifiers")).set_enabled (false);
            }

            GLib.List<QSslCertificate> chain = account._peer_certificate_chain;

            if (chain.is_empty ()) {
                q_c_warning (lc_ssl) << "Empty certificate chain";
                return;
            }

            _menu.add_action (tr ("Certificate information:")).set_enabled (false);

            const auto system_certs = QSslConfiguration.system_ca_certificates ();

            GLib.List<QSslCertificate> tmp_chain;
            foreach (QSslCertificate cert, chain) {
                tmp_chain << cert;
                if (system_certs.contains (cert))
                    break;
            }
            chain = tmp_chain;

            // find trust anchor (informational only, verification is done by QSslSocket!)
            for (QSslCertificate &root_cA : system_certs) {
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
                _menu.add_menu (build_cert_menu (_menu, it.previous (), account.approved_certs (), i, system_certs));
                i++;
            }
        } else {
            _menu.add_action (tr ("The connection is not secure")).set_enabled (false);
        }
    }

    } // namespace Occ
    