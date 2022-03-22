/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@author Krzesimir Nowak <krzesimir@endocode.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gdk.Pixbuf>
//  #include <QRadioButton>
//  #include <QAbstractButton>
//  #include <QCheckBox>
//  #include <QSpinBox>

namespace Occ {
namespace Ui {

public class WizardCommon : GLib.Object {

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


    /***********************************************************
    ***********************************************************/
    public static void set_up_custom_media (GLib.Variant variant, Gtk.Label label) {
        if (!label)
            return;

        Gdk.Pixbuf pix = variant.value<Gdk.Pixbuf> ();
        if (!pix == null) {
            label.pixmap (pix);
            label.alignment (Qt.AlignTop | Qt.Align_right);
            label.visible = true;
        } else {
            string string_value = variant.to_string ();
            if (!string_value == "") {
                label.on_signal_text (string_value);
                label.text_format (Qt.RichText);
                label.visible = true;
                label.open_external_links (true);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public static string title_template () {
        return " (<font color=\"%1\" size=\"5\">)".printf (Theme.wizard_header_title_color.name ()) + "%1</font>";
    }


    /***********************************************************
    ***********************************************************/
    public static string sub_title_template () {
        return "<font color=\"%1\">".printf (Theme.wizard_header_title_color.name ()) + "%1</font>";
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
        error_label.visible = false;
    }


    /***********************************************************
    ***********************************************************/
    public static void customize_hint_label (Gtk.Label label) {
        var palette = label.palette ();
        Gtk.Color text_color = palette.color (Gtk.Palette.Text);
        text_color.alpha (128);
        palette.on_signal_color (Gtk.Palette.Text, text_color);
        label.palette (palette);
    }

} // class WizardCommon

} // namespace Ui
} // namespace Occ
