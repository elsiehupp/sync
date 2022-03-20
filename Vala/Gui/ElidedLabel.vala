/***********************************************************
@author Christian Kamm <mail@ckamm.de>
@copyright GPLv3 or Later
***********************************************************/

//  #include <QResizeEvent>

namespace Occ {
namespace Ui {

/***********************************************************
Label that can elide its text
***********************************************************/
public class ElidedLabel : Gtk.Label {

    /***********************************************************
    ***********************************************************/
    string text {
        public get {
            return this.text;
        }
        public set {
            this.text = value;
            Gtk.Label.on_signal_text (this.text);
            update ();
        }
    }


    Qt.TextElideMode elide_mode {
        public get {
            return this.elide_mode;
        }
        public set {
            this.elide_mode = value;
            update ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public ElidedLabel (string text = "", Qt.TextElideMode elide_mode = Qt.ElideNone, Gtk.Widget parent) {
        base (text, parent);
        this.elide_mode = elide_mode;
        this.text = text;
    }


    /***********************************************************
    ***********************************************************/
    protected override void resize_event (QResizeEvent event) {
        Gtk.Label.resize_event (event);

        QFontMetrics font_metrics = font_metrics ();
        string elided = font_metrics.elided_text (this.text, this.elide_mode, event.size ().width ());
        Gtk.Label.on_signal_text (elided);
    }

} // class ElidedLabel

} // namespace Ui
} // namespace Occ
