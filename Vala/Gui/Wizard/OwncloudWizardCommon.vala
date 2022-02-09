/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Label>
//  #include <QPixmap>
//  #include <QRadioButton>
//  #include <QAbstractButton>
//  #include <QCheckBox>
//  #include <QSpin_box>

namespace Occ {
namespace Ui {

class WizardCommon {

    /***********************************************************
    ***********************************************************/
    public static void set_up_custom_media (GLib.Variant variant, Gtk.Label label) {
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
                label.on_signal_text (string_value);
                label.text_format (Qt.RichText);
                label.visible (true);
                label.open_external_links (true);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public static string title_template () {
        return " (<font color="%1" size="5">)".arg (Theme.instance ().wizard_header_title_color ().name ()) + "%1</font>";
    }


    /***********************************************************
    ***********************************************************/
    public static string sub_title_template () {
        return "<font color=\"%1\">".arg (Theme.instance ().wizard_header_title_color ().name ()) + "%1</font>";
    }


    /***********************************************************
    ***********************************************************/
    public static void init_error_label (Gtk.Label error_label) {
        string style = "border : 1px solid #eed3d7; border-radius : 5px; padding : 3px;"
                     + "background-color : #f2dede; color : #b94a48;";

        error_label.style_sheet (style);
        error_label.word_wrap (true);
        var size_policy = error_label.size_policy ();
        size_policy.retain_size_when_hidden (true);
        error_label.size_policy (size_policy);
        error_label.visible (false);
    }


    /***********************************************************
    ***********************************************************/
    public static void customize_hint_label (Gtk.Label label) {
        var palette = label.palette ();
        Gtk.Color text_color = palette.color (QPalette.Text);
        text_color.alpha (128);
        palette.on_signal_color (QPalette.Text, text_color);
        label.palette (palette);
    }


    /***********************************************************
    ***********************************************************/
    public enum SyncMode {
        SELECTIVE_MODE,
        BOX_MODE
    }


    /***********************************************************
    ***********************************************************/
    public enum Pages {
        PAGE_WELCOME,
        PAGE_SERVER_SETUP,
        PAGE_HTTP_CREDS,
        PAGE_OAUTH_CREDS,
        PAGE_FLOW2AUTH_CREDS,
//  #ifdef WITH_WEBENGINE
        PAGE_WEB_VIEW,
//  #endif WITH_WEBENGINE
        PAGE_ADVANCED_SETUP,
    }

} // class WizardCommon

} // namespace Ui
} // namespace Occ