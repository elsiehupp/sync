/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLabel>
// #include <QPixmap>
// #include <QVariant>
// #include <QRadio_button>
// #include <QAbstractButton>
// #include <QCheckBox>
// #include <QSpin_box>

// #include <string>

class QSpin_box;

namespace Occ {

namespace WizardCommon {

    void setup_custom_media (QVariant &variant, QLabel label);
    string title_template ();
    string sub_title_template ();
    void init_error_label (QLabel error_label);
    void customize_hint_label (QLabel label);

    enum Sync_mode {
        Selective_mode,
        Box_mode
    };

    enum Pages {
        Page_Welcome,
        Page_Server_setup,
        Page_Http_creds,
        Page_OAuth_creds,
        Page_Flow2Auth_creds,
#ifdef WITH_WEBENGINE
        Page_Web_view,
#endif // WITH_WEBENGINE
        Page_Advanced_setup,
    };

    void setup_custom_media (QVariant &variant, QLabel label) {
        if (!label)
            return;

        QPixmap pix = variant.value<QPixmap> ();
        if (!pix.is_null ()) {
            label.set_pixmap (pix);
            label.set_alignment (Qt.Align_top | Qt.Align_right);
            label.set_visible (true);
        } else {
            string string_value = variant.to_"";
            if (!string_value.is_empty ()) {
                label.on_set_text (string_value);
                label.set_text_format (Qt.RichText);
                label.set_visible (true);
                label.set_open_external_links (true);
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

        error_label.set_style_sheet (style);
        error_label.set_word_wrap (true);
        var size_policy = error_label.size_policy ();
        size_policy.set_retain_size_when_hidden (true);
        error_label.set_size_policy (size_policy);
        error_label.set_visible (false);
    }

    void customize_hint_label (QLabel label) {
        var palette = label.palette ();
        QColor text_color = palette.color (QPalette.Text);
        text_color.set_alpha (128);
        palette.on_set_color (QPalette.Text, text_color);
        label.set_palette (palette);
    }

} // ns WizardCommon

} // namespace Occ
