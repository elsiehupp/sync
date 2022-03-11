/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QResizeEvent>

namespace Occ {
namespace Ui {

/***********************************************************
Label that can elide its text
***********************************************************/
class ElidedLabel : Gtk.Label {

    /***********************************************************
    ***********************************************************/
    private string text;
    private Qt.TextElideMode elide_mode = Qt.ElideNone;


    /***********************************************************
    ***********************************************************/
    public ElidedLabel (string text = "", Gtk.Widget parent) {
        base (text, parent);
        this.text = text;
    }


    /***********************************************************
    ***********************************************************/
    public void text (string text) {
        this.text = text;
        Gtk.Label.on_signal_text (text);
        update ();
    }


    /***********************************************************
    ***********************************************************/
    public string text () {
        return this.text;
    }


    /***********************************************************
    ***********************************************************/
    public void elide_mode (Qt.TextElideMode elide_mode) {
        this.elide_mode = elide_mode;
        update ();
    }


    /***********************************************************
    ***********************************************************/
    public Qt.TextElideMode elide_mode () {
        return this.elide_mode;
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
