/***********************************************************
@author 2016 by Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Style>
//  #include <GLib.Style_option_frame>
//  #include <Gtk.LineEdit>
//  #include <GLib.PaintEvent>
//  #include <GLib.Painter>

namespace Occ {
namespace Ui {

/***********************************************************
@brief A lineedit class with a pre-set postfix.

Useful e.g. for setting a fixed domain name.
***********************************************************/
public class PostfixLineEdit { //: Gtk.LineEdit {

    //  const int HORIZONTAL_MARGIN = 4;
    //  const int VERTICAL_MARGIN = 4;

    //  /***********************************************************
    //  @brief an optional postfix shown greyed out
    //  ***********************************************************/
    //  string postfix {
    //      public get {
    //          return this.postfix;
    //      }
    //      public set {
    //          this.postfix = value;
    //          GLib.FontMetricsF font_options = new GLib.FontMetricsF (font ());
    //          GLib.Margins text_margins_i = text_margins ();
    //          text_margins_i.right (text_margins_i.right () + q_round (font_options.width (this.postfix)) + VERTICAL_MARGIN);
    //          text_margins (text_margins_i);
    //      }
    //  }

    //  string full_text {
    //      /***********************************************************
    //      @brief retrieves combined text () and postfix ()
    //      ***********************************************************/
    //      public get {
    //          return text () + this.postfix;
    //      }
    //      /***********************************************************
    //      @brief sets text () from full text, discarding prefix ()
    //      ***********************************************************/
    //      public set {
    //          string prefix_string = value;
    //          if (prefix_string.has_suffix (postfix ())) {
    //              prefix_string.chop (postfix ().length);
    //          }
    //          on_signal_text (prefix_string);
    //      }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public PostfixLineEdit (Gtk.Widget parent) {
    //      base (parent);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void paint_event (GLib.PaintEvent event) {
    //      Gtk.LineEdit.paint_event (event);
    //      GLib.Painter p = new GLib.Painter (this);

    //      p.pen (palette ().color (Gtk.Palette.Disabled, Gtk.Palette.Text));
    //      GLib.FontMetricsF font_options = new GLib.FontMetricsF (font ());
    //      int on_signal_start = rect ().right () - q_round (font_options.width (this.postfix));
    //      GLib.Style_option_frame panel;
    //      init_style_option (panel);
    //      GLib.Rect r = this.style.sub_element_rect (GLib.Style.SE_Line_edit_contents, panel, this);
    //      r.top (r.top () + HORIZONTAL_MARGIN - 1);
    //      GLib.Rect postfix_rect = new GLib.Rect (r);

    //      postfix_rect.left (on_signal_start - VERTICAL_MARGIN);
    //      p.draw_text (postfix_rect, this.postfix);
    //  }

} // class PostfixLineEdit

} // namespace Ui
} // namespace Occ
    //  