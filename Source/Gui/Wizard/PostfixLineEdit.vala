/***********************************************************
Copyright (C) 2016 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QStyle>
// #include <QStyle_option_frame>

// #include <QLineEdit>
// #include <QPaint_event>
// #include <QPainter>

namespace Occ {

/***********************************************************
@brief A lineedit class with a pre-set postfix.

Useful e.g. for setting a fixed domain name.
***********************************************************/

class Postfix_line_edit : QLineEdit {

    /***********************************************************
    ***********************************************************/
    public Postfix_line_edit (Gtk.Widget parent);


    /***********************************************************
    @brief sets an optional postfix shown greyed out
    ***********************************************************/
    public set_postfix (string postfix);


    /***********************************************************
    @brief retrives the postfix
    ***********************************************************/
    public string postfix ();


    /***********************************************************
    @brief retrieves combined text () and postfix ()
    ***********************************************************/
    public string full_text ();


    /***********************************************************
    @brief sets text () from full text, discarding prefix ()
    ***********************************************************/
    public void set_full_text (string text);


    protected void paint_event (QPaint_event pe) override;


    /***********************************************************
    ***********************************************************/
    private string this.postfix;
};

    const int horizontal_margin (4);
    const int vertical_margin (4);

    Postfix_line_edit.Postfix_line_edit (Gtk.Widget parent)
        : QLineEdit (parent) {
    }

    void Postfix_line_edit.set_postfix (string postfix) {
        this.postfix = postfix;
        QFont_metrics_f fm (font ());
        QMargins tm = text_margins ();
        tm.set_right (tm.right () + q_round (fm.width (this.postfix)) + vertical_margin);
        set_text_margins (tm);
    }

    string Postfix_line_edit.postfix () {
        return this.postfix;
    }

    string Postfix_line_edit.full_text () {
        return text () + this.postfix;
    }

    void Postfix_line_edit.set_full_text (string text) {
        string prefix_string = text;
        if (prefix_string.ends_with (postfix ())) {
            prefix_string.chop (postfix ().length ());
        }
        on_set_text (prefix_string);
    }

    void Postfix_line_edit.paint_event (QPaint_event pe) {
        QLineEdit.paint_event (pe);
        QPainter p (this);

        //
        p.set_pen (palette ().color (QPalette.Disabled, QPalette.Text));
        QFont_metrics_f fm (font ());
        int on_start = rect ().right () - q_round (fm.width (this.postfix));
        QStyle_option_frame panel;
        init_style_option (&panel);
        QRect r = style ().sub_element_rect (QStyle.SE_Line_edit_contents, panel, this);
        r.set_top (r.top () + horizontal_margin - 1);
        QRect postfix_rect (r);

        postfix_rect.set_left (on_start - vertical_margin);
        p.draw_text (postfix_rect, this.postfix);
    }

    } // namespace Occ
    