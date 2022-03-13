/***********************************************************
Copyright (C) 2016 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
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
class PostfixLineEdit : QLineEdit {

    const int HORIZONTAL_MARGIN = 4;
    const int VERTICAL_MARGIN = 4;

    /***********************************************************
    ***********************************************************/
    private string postfix;

    /***********************************************************
    ***********************************************************/
    public PostfixLineEdit (Gtk.Widget parent) {
        base (parent);
    }


    /***********************************************************
    @brief sets an optional postfix shown greyed out
    ***********************************************************/
    public void postfix (string postfix) {
        this.postfix = postfix;
        QFontMetricsF font_metrics = new QFontMetricsF (font ());
        QMargins text_margins_i = text_margins ();
        text_margins_i.right (text_margins_i.right () + q_round (font_metrics.width (this.postfix)) + VERTICAL_MARGIN);
        text_margins (text_margins_i);
    }


    /***********************************************************
    @brief retrives the postfix
    ***********************************************************/
    public string postfix () {
        return this.postfix;
    }


    /***********************************************************
    @brief retrieves combined text () and postfix ()
    ***********************************************************/
    public string full_text () {
        return text () + this.postfix;
    }


    /***********************************************************
    @brief sets text () from full text, discarding prefix ()
    ***********************************************************/
    public void full_text (string text) {
        string prefix_string = text;
        if (prefix_string.ends_with (postfix ())) {
            prefix_string.chop (postfix ().length ());
        }
        on_signal_text (prefix_string);
    }


    /***********************************************************
    ***********************************************************/
    protected void paint_event (QPaintEvent event) {
        QLineEdit.paint_event (event);
        QPainter p = new QPainter (this);

        p.pen (palette ().color (QPalette.Disabled, QPalette.Text));
        QFontMetricsF font_metrics = new QFontMetricsF (font ());
        int on_signal_start = rect ().right () - q_round (font_metrics.width (this.postfix));
        QStyle_option_frame panel;
        init_style_option (panel);
        QRect r = style ().sub_element_rect (QStyle.SE_Line_edit_contents, panel, this);
        r.top (r.top () + HORIZONTAL_MARGIN - 1);
        QRect postfix_rect = new QRect (r);

        postfix_rect.left (on_signal_start - VERTICAL_MARGIN);
        p.draw_text (postfix_rect, this.postfix);
    }

} // class PostfixLineEdit

} // namespace Ui
} // namespace Occ
    