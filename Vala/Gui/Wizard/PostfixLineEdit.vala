/***********************************************************
@author 2016 by Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QStyle>
//  #include <QStyle_option_frame>
//  #include <QLineEdit>
//  #include <QPaintEvent>
//  #include <QPainter>

namespace Occ {
namespace Ui {

/***********************************************************
@brief A lineedit class with a pre-set postfix.

Useful e.g. for setting a fixed domain name.
***********************************************************/
public class PostfixLineEdit : QLineEdit {

    const int HORIZONTAL_MARGIN = 4;
    const int VERTICAL_MARGIN = 4;

    /***********************************************************
    @brief an optional postfix shown greyed out
    ***********************************************************/
    string postfix {
        public get {
            return this.postfix;
        }
        public set {
            this.postfix = value;
            QFontMetricsF font_metrics = new QFontMetricsF (font ());
            QMargins text_margins_i = text_margins ();
            text_margins_i.right (text_margins_i.right () + q_round (font_metrics.width (this.postfix)) + VERTICAL_MARGIN);
            text_margins (text_margins_i);
        }
    }

    string full_text {
        /***********************************************************
        @brief retrieves combined text () and postfix ()
        ***********************************************************/
        public get {
            return text () + this.postfix;
        }
        /***********************************************************
        @brief sets text () from full text, discarding prefix ()
        ***********************************************************/
        public set {
            string prefix_string = value;
            if (prefix_string.ends_with (postfix ())) {
                prefix_string.chop (postfix ().length);
            }
            on_signal_text (prefix_string);
        }
    }

    /***********************************************************
    ***********************************************************/
    public PostfixLineEdit (Gtk.Widget parent) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    protected void paint_event (QPaintEvent event) {
        QLineEdit.paint_event (event);
        QPainter p = new QPainter (this);

        p.pen (palette ().color (Gtk.Palette.Disabled, Gtk.Palette.Text));
        QFontMetricsF font_metrics = new QFontMetricsF (font ());
        int on_signal_start = rect ().right () - q_round (font_metrics.width (this.postfix));
        QStyle_option_frame panel;
        init_style_option (panel);
        QRect r = this.style.sub_element_rect (QStyle.SE_Line_edit_contents, panel, this);
        r.top (r.top () + HORIZONTAL_MARGIN - 1);
        QRect postfix_rect = new QRect (r);

        postfix_rect.left (on_signal_start - VERTICAL_MARGIN);
        p.draw_text (postfix_rect, this.postfix);
    }

} // class PostfixLineEdit

} // namespace Ui
} // namespace Occ
    