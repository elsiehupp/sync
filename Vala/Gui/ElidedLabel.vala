/***********************************************************
@author Christian Kamm <mail@ckamm.de>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.ResizeEvent>

namespace Occ {
namespace Ui {

/***********************************************************
Label that can elide its text
***********************************************************/
public class ElidedLabel { //: Gtk.Label {

    /***********************************************************
    ***********************************************************/
    string text {
        //  public get {
        //      return this.text;
        //  }
        //  public set {
        //      this.text = value;
        //      Gtk.Label.on_signal_text (this.text);
        //      update ();
        //  }
    }


    GLib.TextElideMode elide_mode {
        //  public get {
        //      return this.elide_mode;
        //  }
        //  public set {
        //      this.elide_mode = value;
        //      update ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public ElidedLabel (string text = "", GLib.TextElideMode elide_mode = GLib.ElideNone, Gtk.Widget parent) {
        //  base (text, parent);
        //  this.elide_mode = elide_mode;
        //  this.text = text;
    }


    /***********************************************************
    ***********************************************************/
    protected override void resize_event (GLib.ResizeEvent event) {
        //  Gtk.Label.resize_event (event);

        //  Cairo.FontOptions font_options = font_options ();
        //  string elided = font_options.elided_text (this.text, this.elide_mode, event.size ().width ());
        //  Gtk.Label.on_signal_text (elided);
    }

} // class ElidedLabel

} // namespace Ui
} // namespace Occ
