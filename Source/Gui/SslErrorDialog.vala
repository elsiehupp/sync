/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtGui>
// #include <Qt_network>
// #include <Qt_widgets>

// #include <Qt_core>
// #include <Gtk.Dialog>
// #include <QSslCertificate>
// #include <QList>


namespace Occ {

namespace Ui {
    class Ssl_error_dialog;
}

/***********************************************************
@brief The SslDialogErrorHandler class
@ingroup gui
***********************************************************/
class SslDialogErrorHandler : Abstract_sslErrorHandler {
public:
    bool handle_errors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, AccountPtr) override;
};

/***********************************************************
@brief The Ssl_error_dialog class
@ingroup gui
***********************************************************/
class Ssl_error_dialog : Gtk.Dialog {
public:
    Ssl_error_dialog (AccountPtr account, Gtk.Widget *parent = nullptr);
    ~Ssl_error_dialog () override;
    bool check_failing_certs_known (QList<QSslError> &errors);
    bool trust_connection ();
    QList<QSslCertificate> unknown_certs () { return _unknown_certs; }

private:
    string style_sheet ();
    bool _all_trusted;

    string cert_div (QSslCertificate) const;

    QList<QSslCertificate> _unknown_certs;
    string _custom_config_handle;
    Ui.Ssl_error_dialog *_ui;
    AccountPtr _account;
};

    namespace Utility {
        //  Used for QSSLCertificate.subject_info which returns a QStringList in Qt5, but a string in Qt4
        string escape (QStringList &l) { return escape (l.join (';')); }
    }
    
    bool SslDialogErrorHandler.handle_errors (QList<QSslError> errors, QSslConfiguration &conf, QList<QSslCertificate> *certs, AccountPtr account) {
        (void)conf;
        if (!certs) {
            q_c_critical (lc_ssl_error_dialog) << "Certs parameter required but is NULL!";
            return false;
        }
    
        Ssl_error_dialog dlg (account);
        // whether the failing certs have previously been accepted
        if (dlg.check_failing_certs_known (errors)) {
            *certs = dlg.unknown_certs ();
            return true;
        }
        // whether the user accepted the certs
        if (dlg.exec () == Gtk.Dialog.Accepted) {
            if (dlg.trust_connection ()) {
                *certs = dlg.unknown_certs ();
                return true;
            }
        }
        return false;
    }
    
    Ssl_error_dialog.Ssl_error_dialog (AccountPtr account, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _all_trusted (false)
        , _ui (new Ui.Ssl_error_dialog)
        , _account (account) {
        set_window_flags (window_flags () & ~Qt.Window_context_help_button_hint);
        _ui.setup_ui (this);
        set_window_title (tr ("Untrusted Certificate"));
        QPushButton *ok_button =
            _ui._dialog_button_box.button (QDialogButtonBox.Ok);
        QPushButton *cancel_button =
            _ui._dialog_button_box.button (QDialogButtonBox.Cancel);
        ok_button.set_enabled (false);
    
        _ui._cb_trust_connect.set_enabled (!Theme.instance ().forbid_bad_s_sL ());
        connect (_ui._cb_trust_connect, &QAbstractButton.clicked,
            ok_button, &Gtk.Widget.set_enabled);
    
        if (ok_button) {
            ok_button.set_default (true);
            connect (ok_button, &QAbstractButton.clicked, this, &Gtk.Dialog.accept);
            connect (cancel_button, &QAbstractButton.clicked, this, &Gtk.Dialog.reject);
        }
    }
    
    Ssl_error_dialog.~Ssl_error_dialog () {
        delete _ui;
    }
    
    string Ssl_error_dialog.style_sheet () {
        const string style = QLatin1String (
            "#cert {margin-left : 5px;} "
            "#ca_error { color:#a00011; margin-left:5px; margin-right:5px; }"
            "#ca_error p { margin-top : 2px; margin-bottom:2px; }"
            "#ccert { margin-left : 5px; }"
            "#issuer { margin-left : 5px; }"
            "tt { font-size : small; }");
    
        return style;
    }
    const int QL (x) QLatin1String (x)
    
    bool Ssl_error_dialog.check_failing_certs_known (QList<QSslError> &errors) {
        // check if unknown certs caused errors.
        _unknown_certs.clear ();
    
        QStringList error_strings;
    
        QStringList additional_error_strings;
    
        QList<QSslCertificate> trusted_certs = _account.approved_certs ();
    
        for (int i = 0; i < errors.count (); ++i) {
            QSslError error = errors.at (i);
            if (trusted_certs.contains (error.certificate ()) || _unknown_certs.contains (error.certificate ())) {
                continue;
            }
            error_strings += error.error_string ();
            if (!error.certificate ().is_null ()) {
                _unknown_certs.append (error.certificate ());
            } else {
                additional_error_strings.append (error.error_string ());
            }
        }
    
        // if there are no errors left, all Certs were known.
        if (error_strings.is_empty ()) {
            _all_trusted = true;
            return true;
        }
    
        string msg = QL ("<html><head>");
        msg += QL ("<link rel='stylesheet' type='text/css' href='format.css'>");
        msg += QL ("</head><body>");
    
        auto host = _account.url ().host ();
        msg += QL ("<h3>") + tr ("Cannot connect securely to <i>%1</i>:").arg (host) + QL ("</h3>");
        // loop over the unknown certs and line up their errors.
        msg += QL ("<div id=\"ca_errors\">");
        foreach (QSslCertificate &cert, _unknown_certs) {
            msg += QL ("<div id=\"ca_error\">");
            // add the errors for this cert
            foreach (QSslError err, errors) {
                if (err.certificate () == cert) {
                    msg += QL ("<p>") + err.error_string () + QL ("</p>");
                }
            }
            msg += QL ("</div>");
            msg += cert_div (cert);
            if (_unknown_certs.count () > 1) {
                msg += QL ("<hr/>");
            }
        }
    
        if (!additional_error_strings.is_empty ()) {
            msg += QL ("<h4>") + tr ("Additional errors:") + QL ("</h4>");
    
            for (auto &error_string : additional_error_strings) {
                msg += QL ("<div id=\"ca_error\">");
                msg += QL ("<p>") + error_string + QL ("</p>");
                msg += QL ("</div>");
            }
        }
    
        msg += QL ("</div></body></html>");
    
        auto *doc = new QText_document (nullptr);
        string style = style_sheet ();
        doc.add_resource (QText_document.Style_sheet_resource, QUrl (QL ("format.css")), style);
        doc.set_html (msg);
    
        _ui._tb_errors.set_document (doc);
        _ui._tb_errors.show ();
    
        return false;
    }
    
    string Ssl_error_dialog.cert_div (QSslCertificate cert) {
        string msg;
        msg += QL ("<div id=\"cert\">");
        msg += QL ("<h3>") + tr ("with Certificate %1").arg (Utility.escape (cert.subject_info (QSslCertificate.Common_name))) + QL ("</h3>");
    
        msg += QL ("<div id=\"ccert\">");
        QStringList li;
    
        string org = Utility.escape (cert.subject_info (QSslCertificate.Organization));
        string unit = Utility.escape (cert.subject_info (QSslCertificate.Organizational_unit_name));
        string country = Utility.escape (cert.subject_info (QSslCertificate.Country_name));
        if (unit.is_empty ())
            unit = tr ("&lt;not specified&gt;");
        if (org.is_empty ())
            org = tr ("&lt;not specified&gt;");
        if (country.is_empty ())
            country = tr ("&lt;not specified&gt;");
        li << tr ("Organization : %1").arg (org);
        li << tr ("Unit : %1").arg (unit);
        li << tr ("Country : %1").arg (country);
        msg += QL ("<p>") + li.join (QL ("<br/>")) + QL ("</p>");
    
        msg += QL ("<p>");
    
        if (cert.effective_date () < QDateTime (QDate (2016, 1, 1), QTime (), Qt.UTC)) {
        string sha1sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha1).to_hex ());
            msg += tr ("Fingerprint (SHA1) : <tt>%1</tt>").arg (sha1sum) + QL ("<br/>");
        }
    
        string sha256sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha256).to_hex ());
        string sha512sum = Utility.format_fingerprint (cert.digest (QCryptographicHash.Sha512).to_hex ());
        msg += tr ("Fingerprint (SHA-256) : <tt>%1</tt>").arg (sha256sum) + QL ("<br/>");
        msg += tr ("Fingerprint (SHA-512) : <tt>%1</tt>").arg (sha512sum) + QL ("<br/>");
        msg += QL ("<br/>");
        msg += tr ("Effective Date : %1").arg (cert.effective_date ().to_string ()) + QL ("<br/>");
        msg += tr ("Expiration Date : %1").arg (cert.expiry_date ().to_string ()) + QL ("</p>");
    
        msg += QL ("</div>");
    
        msg += QL ("<h3>") + tr ("Issuer : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Common_name))) + QL ("</h3>");
        msg += QL ("<div id=\"issuer\">");
        li.clear ();
        li << tr ("Organization : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Organization)));
        li << tr ("Unit : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Organizational_unit_name)));
        li << tr ("Country : %1").arg (Utility.escape (cert.issuer_info (QSslCertificate.Country_name)));
        msg += QL ("<p>") + li.join (QL ("<br/>")) + QL ("</p>");
        msg += QL ("</div>");
        msg += QL ("</div>");
    
        return msg;
    }
    
    bool Ssl_error_dialog.trust_connection () {
        if (_all_trusted)
            return true;
    
        bool stat = (_ui._cb_trust_connect.check_state () == Qt.Checked);
        q_c_info (lc_ssl_error_dialog) << "SSL-Connection is trusted : " << stat;
    
        return stat;
    }
    
    } // end namespace
    