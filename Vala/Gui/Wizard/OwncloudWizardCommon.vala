/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLabel>
//  #include <QPixmap>
//  #include <QRadio_button>
//  #include <QAbstractButton>
//  #include <QCheckBox>
//  #include <QSpin_box>

namespace Occ {
namespace Ui {

namespace WizardCommon {

    void setup_custom_media (GLib.Variant variant, QLabel label);
    string title_template ();
    string sub_title_template ();
    void init_error_label (QLabel error_label);
    void customize_hint_label (QLabel label);

    enum Sync_mode {
        Selective_mode,
        Box_mode
    }

    enum Pages {
        Page_Welcome,
        Page_Server_setup,
        Page_Http_creds,
        Page_OAuth_creds,
        Page_Flow2Auth_creds,
#ifdef WITH_WEBENGINE
        Page_Web_view,
//  #endif // WITH_WEBENGINE
        Page_Advanced_setup,
    }

    void setup_custom_media (GLib.Variant variant, QLabel label) {
        if (!label)
            return;

        QPixmap pix = variant.value<QPixmap> ();
        if (!pix.is_null ()) {
            label.pixmap (pix);
            label.alignment (Qt.Align_top | Qt.Align_right);
            label.visible (true);
        } else {
            string string_value = variant.to_string ();
            if (!string_value.is_empty ()) {
                label.on_text (string_value);
                label.text_format (Qt.RichText);
                label.visible (true);
                label.open_external_links (true);
            }
        }
    }

    string title_template () {
        return string.from_latin1 (R" (<font color="%1" size="5">)").arg (Theme.instance ().wizard_header_title_color ().name ()) + string.from_latin1 ("%1</font>");
    }

    string sub_title_template () {
        return string.from_latin1 ("<font color=\"%1\">").arg (Theme.instance ().wizard_header_title_color ().name ()) + string.from_latin1 ("%1</font>");
    }

    void init_error_label (QLabel error_label) {
        string style = QLatin1String ("border : 1px solid #eed3d7; border-radius : 5px; padding : 3px;"
                                        "background-color : #f2dede; color : #b94a48;");

        error_label.style_sheet (style);
        error_label.word_wrap (true);
        var size_policy = error_label.size_policy ();
        size_policy.retain_size_when_hidden (true);
        error_label.size_policy (size_policy);
        error_label.visible (false);
    }

    void customize_hint_label (QLabel label) {
        var palette = label.palette ();
        Gtk.Color text_color = palette.color (QPalette.Text);
        text_color.alpha (128);
        palette.on_color (QPalette.Text, text_color);
        label.palette (palette);
    }

} // namespace WizardCommon

} // namespace Occ
